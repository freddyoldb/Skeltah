#!/bin/bash
# Install all Node2 tools: OpenSCAD, ADB, Obsidian, MQTT
# Run on PC2 (benutzer@192.168.178.121)

set -e
echo "=== JARVIS Node2 Setup ==="

# OpenSCAD
echo "[1/4] Installing OpenSCAD..."
sudo apt install -y openscad

# ADB (for FireTV)
echo "[2/4] Installing ADB..."
sudo apt install -y adb

# MQTT client
echo "[3/4] Installing MQTT tools..."
sudo apt install -y mosquitto-clients python3-paho-mqtt

# Obsidian (AppImage)
echo "[4/4] Installing Obsidian..."
OBSIDIAN_VER="1.7.7"
mkdir -p ~/Applications
wget -q --show-progress \
  "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VER}/Obsidian-${OBSIDIAN_VER}.AppImage" \
  -O ~/Applications/Obsidian.AppImage
chmod +x ~/Applications/Obsidian.AppImage

# Create incoming dir for Drop-Zone-Daemon
mkdir -p ~/incoming

echo ""
echo "=== Node2 setup complete! ==="
echo "OpenSCAD: openscad"
echo "ADB:      adb connect <firetv-ip>:5555"
echo "Obsidian: ~/Applications/Obsidian.AppImage"
