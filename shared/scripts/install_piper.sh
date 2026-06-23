#!/bin/bash
# Install Piper TTS on Master (ASUS Laptop)
# Run on the laptop itself or via: ssh frederik@192.168.178.44 'bash -s' < install_piper.sh

set -e

PIPER_VERSION="1.2.0"
PIPER_DIR="$HOME/jarvis/tts"
VOICE_DIR="$PIPER_DIR/voices"

mkdir -p "$VOICE_DIR"

echo "=== Downloading Piper TTS ==="
cd /tmp
wget -q --show-progress "https://github.com/rhasspy/piper/releases/download/${PIPER_VERSION}/piper_linux_x86_64.tar.gz"
tar -xzf piper_linux_x86_64.tar.gz
sudo cp piper/piper /usr/local/bin/piper
sudo chmod +x /usr/local/bin/piper
rm -rf piper piper_linux_x86_64.tar.gz

echo "=== Downloading English voice (lessac-medium) ==="
cd "$VOICE_DIR"
wget -q --show-progress "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx"
wget -q --show-progress "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json"

echo "=== Installing alsa-utils for audio playback ==="
sudo apt install -y alsa-utils

echo "=== Piper TTS ready! Test with: ==="
echo "echo 'Hello, I am JARVIS' | piper --model $VOICE_DIR/en_US-lessac-medium.onnx --output_file /tmp/test.wav && aplay /tmp/test.wav"
