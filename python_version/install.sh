#!/bin/bash

# --- LEGION GO S UI RESET ---
SCRIPT_PATH="/usr/local/bin/steam-vol-reset.py"
SERVICE_NAME="steam-vol-reset.service"
# Specific device name for Legion Go S
TARGET_DEVICE="AT Translated Set 2 keyboard"

# Root check
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo!"
    exit 1
fi

echo ">>> [1/5] Installing dependencies..."
# Unlocking filesystem specifically for installation
steamos-readonly disable 2>/dev/null

pacman -S --needed --noconfirm python-evdev

echo ">>> [2/5] Generating Python script..."
cat << EOF > $SCRIPT_PATH
#!/usr/bin/env python3
import evdev
from evdev import InputDevice, ecodes, list_devices
import time
import subprocess
import sys
import os

# Configuration
TARGET = "$TARGET_DEVICE"
HOLD_TIME = 2.0  # Seconds to hold

def find_device():
    try:
        devices = [InputDevice(path) for path in list_devices()]
        for dev in devices:
            if TARGET in dev.name:
                return dev
    except Exception:
        pass
    return None

def restart_ui():
    print("!!! RESTARTING UI !!!")
    # SECURITY FIX: Avoid shell=True. Use list format.
    try:
        subprocess.run(["systemctl", "restart", "sddm"], check=False)
    except Exception as e:
        print(f"Error executing restart: {e}")
    
    # Cooldown to prevent loop restarts
    time.sleep(10)

def monitor_loop():
    dev = find_device()
    if not dev:
        print(f"Waiting for device: {TARGET}...")
        return

    print(f"Connected to: {dev.name}")
    print(f"Ready. Hold Vol+ and Vol- for {HOLD_TIME}s to restart UI.")
    
    # 115 = Vol Up, 114 = Vol Down
    vol_up = False
    vol_down = False
    combo_start_time = 0

    try:
        # Passive, blocking read_loop (Efficient C implementation)
        for event in dev.read_loop():
            if event.type == ecodes.EV_KEY:
                # Update key states (1=Down, 2=Hold, 0=Up)
                if event.code == ecodes.KEY_VOLUMEUP:
                    vol_up = (event.value > 0)
                elif event.code == ecodes.KEY_VOLUMEDOWN:
                    vol_down = (event.value > 0)
                
                # Logic Check
                if vol_up and vol_down:
                    if combo_start_time == 0:
                        combo_start_time = time.time()
                        print("-> Combo detected... holding...")
                    else:
                        # Check duration
                        if (time.time() - combo_start_time) >= HOLD_TIME:
                            restart_ui()
                            # Reset states after restart
                            combo_start_time = 0
                            vol_up = False
                            vol_down = False
                else:
                    # Reset timer if any button is released
                    combo_start_time = 0

    except Exception as e:
        print(f"Device connection lost or error: {e}")

if __name__ == "__main__":
    # Main Keep-Alive Loop
    while True:
        try:
            monitor_loop()
        except KeyboardInterrupt:
            sys.exit(0)
        except Exception as e:
            print(f"Critical Loop Error: {e}")
        
        # Wait before trying to reconnect device
        time.sleep(3)
EOF

echo ">>> [3/5] Setting permissions..."
chmod +x $SCRIPT_PATH

echo ">>> [4/5] Configuring systemd service..."
cat <<EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=Legion Go UI Reset Service
# Wait for graphics to be ready, as this service manages UI
After=graphical.target

[Service]
Type=simple
ExecStart=$SCRIPT_PATH
Restart=always
RestartSec=5
User=root

# --- SECURITY HARDENING ---
# Service cannot acquire new privileges
NoNewPrivileges=true
# Protect system directories
ProtectSystem=full
# Private /tmp directory
PrivateTmp=true

[Install]
# Start with graphical interface
WantedBy=graphical.target
EOF

echo ">>> [5/5] Starting service..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

steamos-readonly enable

echo ">>> DONE. Service running for: $TARGET_DEVICE"