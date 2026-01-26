use evdev::{Device, InputEventKind, Key};
use std::process::Command;
use std::thread;
use std::time::{Duration, Instant};

// CONFIGURATION
const TARGET_DEVICE_NAME: &str = "AT Translated Set 2 keyboard";
const HOLD_DURATION: Duration = Duration::from_secs(2);
const RESTART_COOLDOWN: Duration = Duration::from_secs(10);

fn main() {
    println!(">>> [Legion Go Reset] Service Started");
    println!(">>> Target Device: '{}'", TARGET_DEVICE_NAME);

    // Main Service Loop
    loop {
        let mut device = wait_for_device();

        if let Err(e) = monitor_input_loop(&mut device) {
            eprintln!(">>> Critical Input Loop Error: {}. Restarting monitor...", e);
            thread::sleep(Duration::from_secs(3));
        }
    }
}

fn wait_for_device() -> Device {
    loop {
        match find_device_by_name(TARGET_DEVICE_NAME) {
            Some(dev) => {
                println!(">>> Device Connected: {}", dev.name().unwrap_or("Unknown"));
                return dev;
            }
            None => {
                thread::sleep(Duration::from_secs(5));
            }
        }
    }
}

fn find_device_by_name(name: &str) -> Option<Device> {
    for (_, device) in evdev::enumerate() {
        if let Some(dev_name) = device.name() {
            if dev_name == name {
                return Some(device);
            }
        }
    }
    None
}

fn monitor_input_loop(device: &mut Device) -> std::io::Result<()> {
    let mut vol_up = false;
    let mut vol_down = false;
    let mut combo_start: Option<Instant> = None;

    loop {
        // Flag to track if we need to handle a restart AFTER the loop finishes
        let mut trigger_restart = false;

        // Inner scope for the event iterator (borrowing the device)
        for event in device.fetch_events()? {
            // Check if it is a Key event and extract the Key
            if let InputEventKind::Key(key) = event.kind() {
                let value = event.value(); // 0 = Up, 1 = Down, 2 = Hold

                match key {
                    Key::KEY_VOLUMEUP => vol_up = value > 0,
                    Key::KEY_VOLUMEDOWN => vol_down = value > 0,
                    _ => {}
                }

                // Combo Logic
                if vol_up && vol_down {
                    if combo_start.is_none() {
                        println!("-> Combo detected (Vol+ & Vol-). Holding...");
                        combo_start = Some(Instant::now());
                    } else {
                        if let Some(start) = combo_start {
                            if start.elapsed() >= HOLD_DURATION {
                                // Mark to restart and BREAK the loop to release the borrow
                                trigger_restart = true;
                                break; 
                            }
                        }
                    }
                } else {
                    if combo_start.is_some() {
                        println!("-> Combo interrupted.");
                        combo_start = None;
                    }
                }
            }
        }

        // Now we are outside the 'for' loop, so 'device' is free to be used again!
        if trigger_restart {
            perform_emergency_restart();
            
            // Reset state
            combo_start = None;
            vol_up = false;
            vol_down = false;
            
            // Wait
            thread::sleep(RESTART_COOLDOWN);
            
            // Clear queue (Safe now because we are not inside fetch_events loop)
            while device.fetch_events().is_ok() {} 
        }
    }
}

fn perform_emergency_restart() {
    println!("!!! EMERGENCY UI RESTART INITIATED !!!");
    
    let result = Command::new("systemctl")
        .arg("restart")
        .arg("sddm")
        .output();

    match result {
        Ok(_) => println!(">>> Restart command sent successfully."),
        Err(e) => eprintln!("!!! RESTART EXECUTION ERROR: {} !!!", e),
    }
}