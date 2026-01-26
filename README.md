# Legion Go S - UI Reset Service

A lightweight, passive system service designed for Legion Go S running SteamOS/Linux.
It allows you to force-restart the graphical interface (Gamescope/SDDM) when it freezes by holding both volume buttons.

> [!CAUTION]
> ## Disclaimer
> This software is provided "as is", without warranty of any kind. Use at your own risk. This tool interacts with low-level input devices and system services.

## 📂 Project Structure

This repository contains two implementations of the service:

| Version | Path | Status | Memory Usage | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Rust** | `/rust_version` | **Recommended** | **~140 KB** | Ultra-lightweight, zero CPU usage, hardened systemd service. |
| **Python** | `/python_version` | Legacy | ~20 MB | Original prototype using Python `evdev`. |

---

## 🚀 Rust Version (Recommended)

### Features
* **Zero-Overhead:** Consumes less than 1MB of RAM and 0% CPU when idle.
* **Safe Passive Mode:** Does not block other applications from using volume buttons.
* **Systemd Hardening:** Runs in a restricted sandbox for security.
* **Smart Management:** Single script for installation, updates, and uninstallation.

### Installation

## ⚡ Quick Install (One-Liner)

You don't need to clone the repository manually. Just open the terminal (Konsole) and paste this single command:

```bash
mkdir -p /tmp/legion_install && cd /tmp/legion_install && wget -O legion_go_reset https://github.com/Veizeczek/LegionGoS-UI-Reset/releases/download/v1.0/legion_go_reset && wget -O install.sh https://raw.githubusercontent.com/Veizeczek/LegionGoS-UI-Reset/main/rust_version/install.sh && chmod +x install.sh && sudo ./install.sh && cd ~ && rm -rf /tmp/legion_install
```
(This command downloads the binary release and the installer script to a temporary folder, installs the service, and cleans up afterwards.)

## Uninstall
To completely remove the service and configuration:
```bash
curl -sL https://raw.githubusercontent.com/Veizeczek/LegionGoS-UI-Reset/main/rust_version/install.sh | sudo bash -s uninstall
```

## 🛠️ Manual

**Prerequisites:** You need `cargo` (Rust compiler) installed to build the binary.

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/Veizeczek/LegionGoS-UI-Reset.git](https://github.com/Veizeczek/LegionGoS-UI-Reset.git)
    cd LegionGoS-UI-Reset/rust_version
    ```

2.  **Build the binary:**
    ```bash
    cargo build --release --target x86_64-unknown-linux-musl
    ```
    *(Note: If building directly on SteamOS, standard `cargo build --release` is usually sufficient).*

3.  **Install the service:**
    ```bash
    chmod +x install.sh
    sudo ./install.sh
    ```

### Uninstallation
To remove the service and clean up all files:
```bash
cd rust_version
sudo ./install.sh uninstall
```
## Usage

1.  Press and hold **Volume Up (+)**.
2.  While holding Vol+, press and hold **Volume Down (-)**.
3.  Keep **BOTH** buttons held together for **2 seconds**.
4.  The screen will go black momentarily as the UI session (SDDM) restarts.

*Note: The order of pressing buttons does not matter, as long as both are held down simultaneously for the required duration.*

## ✅ Compatibility
Tested and confirmed working on:
- **Device:** Lenovo Legion Go S
- **OS:** SteamOS 3.x (Stable)
- **Kernel:** 6.x

---

## Python Version (Legacy)

If you prefer the Python implementation or cannot compile Rust, navigate to the `/python_version` directory.

(Note: The Python version is kept for archival purposes and is no longer actively developed.)
