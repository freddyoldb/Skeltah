#!/bin/bash
# Install all Master tools: Piper TTS, PyQt6, Deskflow, Obsidian
# Run on ASUS Laptop (frederik@192.168.178.44)

set -e
echo "=== JARVIS Master Setup ==="

# Python deps
echo "[1/5] Python packages..."
sudo apt install -y python3-pip python3-pyqt6 python3-requests alsa-utils

# PyQt6 WebEngine
echo "[2/5] PyQt6 WebEngine..."
pip3 install PyQt6-WebEngine --break-system-packages

# Piper TTS
echo "[3/5] Piper TTS..."
cd /tmp
wget -q --show-progress "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz" -O piper.tar.gz
tar -xzf piper.tar.gz
sudo cp piper/piper /usr/local/bin/
rm -rf piper piper.tar.gz

# Piper voice model
echo "[4/5] Downloading voice model (en_US-lessac-medium)..."
mkdir -p ~/jarvis/tts/voices
cd ~/jarvis/tts/voices
wget -q --show-progress \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx"
wget -q --show-progress \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json"

# Obsidian
echo "[5/5] Obsidian..."
OBSIDIAN_VER="1.7.7"
mkdir -p ~/Applications
wget -q --show-progress \
  "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VER}/Obsidian-${OBSIDIAN_VER}.AppImage" \
  -O ~/Applications/Obsidian.AppImage
chmod +x ~/Applications/Obsidian.AppImage

mkdir -p ~/incoming ~/jarvis/vault

echo ""
echo "=== Master setup complete! ==="
echo "Test TTS: echo 'Hello JARVIS' | piper --model ~/jarvis/tts/voices/en_US-lessac-medium.onnx --output_file /tmp/test.wav && aplay /tmp/test.wav"
echo "Obsidian: ~/Applications/Obsidian.AppImage"
