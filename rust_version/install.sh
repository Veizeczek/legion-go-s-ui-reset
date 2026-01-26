#!/bin/bash

# --- CONFIGURATION ---
BINARY_NAME="legion_go_reset"
INSTALL_PATH="/usr/local/bin/$BINARY_NAME"
SERVICE_NAME="legion-reset.service"

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo!"
    exit 1
fi

# --- MODE: UNINSTALL ---
# If the user runs "./install.sh uninstall", we go here
if [ "$1" == "uninstall" ]; then
    echo ">>> [UNINSTALL] Stopping and removing service..."
    systemctl stop $SERVICE_NAME 2>/dev/null
    systemctl disable $SERVICE_NAME 2>/dev/null
    rm -f /etc/systemd/system/$SERVICE_NAME
    systemctl daemon-reload

    echo ">>> [UNINSTALL] Unlocking filesystem..."
    steamos-readonly disable 2>/dev/null

    echo ">>> [UNINSTALL] Removing binary..."
    rm -f "$INSTALL_PATH"

    echo ">>> [UNINSTALL] Securing filesystem..."
    steamos-readonly enable 2>/dev/null

    echo ">>> SUCCESS. Uninstalled completely."
    exit 0
fi

# --- MODE: INSTALL (Default) ---

# Verify Binary Existence (Only needed for installation)
if [ ! -f "./$BINARY_NAME" ]; then
    echo "ERROR: Binary file './$BINARY_NAME' not found in current directory."
    echo "Make sure you copied the compiled file from 'target/...' to this folder."
    exit 1
fi

echo ">>> [1/5] Stopping running service (to release file lock)..."
systemctl stop $SERVICE_NAME 2>/dev/null

echo ">>> [2/5] Unlocking filesystem (SteamOS)..."
steamos-readonly disable 2>/dev/null

echo ">>> [3/5] Installing binary..."
cp -f "./$BINARY_NAME" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
chown root:root "$INSTALL_PATH"

echo ">>> [4/5] Creating Hardened Systemd Service..."
cat <<EOF > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=Legion Go Emergency Reset Service (Rust)
After=graphical.target

[Service]
Type=simple
ExecStart=$INSTALL_PATH
Restart=always
RestartSec=5
User=root

# --- SECURITY HARDENING ---
ProtectHome=true
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=graphical.target
EOF

echo ">>> [5/5] Activating service..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

echo ">>> Securing filesystem..."
steamos-readonly enable 2>/dev/null

echo ">>> SUCCESS. Rust service installed and running."