#!/bin/bash

SERVICE_NAME="steam-vol-reset.service"
SCRIPT_PATH="/usr/local/bin/steam-vol-reset.py"

if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo (root privileges)."
  exit 1
fi

echo ">>> Stopping service..."
systemctl stop $SERVICE_NAME
systemctl disable $SERVICE_NAME 2>/dev/null

echo ">>> Removing system files..."
rm -f /etc/systemd/system/$SERVICE_NAME
rm -f $SCRIPT_PATH

echo ">>> Reloading systemd configuration..."
systemctl daemon-reload

echo ">>> Removing installation folder..."
rm -rf "$PWD"

echo ">>> DONE. Service has been completely uninstalled."