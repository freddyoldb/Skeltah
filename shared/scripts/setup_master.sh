#!/bin/bash
# ============================================================
# JARVIS OS — MASTER SETUP (ASUS Laptop, 192.168.178.44)
# Brain, Ollama, Piper TTS, Deskflow Server, Drop-Zone-Daemon
# Ausführen mit: sudo bash setup_master.sh
# ============================================================
set -e
JARVIS_DIR="/home/frederik/jarvis"
SKELTAH_DIR="/home/frederik/Skeltah"
USER_HOME="/home/frederik"
MASTER_USER="frederik"

echo "╔══════════════════════════════════════════╗"
echo "║  JARVIS OS — MASTER SETUP                ║"
echo "╚══════════════════════════════════════════╝"

# ── System Update ──────────────────────────────
echo "[1/10] System update..."
apt update -y && apt upgrade -y

# ── Basis-Tools ────────────────────────────────
echo "[2/10] Base tools..."
apt install -y git curl wget python3 python3-pip python3-venv \
  alsa-utils openssh-server net-tools htop unzip \
  xdotool wmctrl x11-xserver-utils rsync

# ── Python Pakete ──────────────────────────────
echo "[3/10] Python packages..."
pip3 install --break-system-packages \
  requests PyQt6 PyQt6-WebEngine paho-mqtt

# ── Ollama (bereits installiert, sicherstellen) ─
echo "[4/10] Ollama..."
if ! command -v ollama &>/dev/null; then
  curl -fsSL https://ollama.com/install.sh | sh
fi
systemctl enable ollama
systemctl start ollama
sleep 3
# Modell laden falls nicht vorhanden
sudo -u $MASTER_USER ollama pull phi3:mini || true

# ── Piper TTS ──────────────────────────────────
echo "[5/10] Piper TTS..."
if ! command -v piper &>/dev/null; then
  cd /tmp
  wget -q --show-progress \
    "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz" \
    -O piper.tar.gz
  tar -xzf piper.tar.gz
  cp piper/piper /usr/local/bin/
  chmod +x /usr/local/bin/piper
  rm -rf piper piper.tar.gz
fi

# Piper Voice Model
VOICE_DIR="$USER_HOME/jarvis/tts/voices"
mkdir -p "$VOICE_DIR"
if [ ! -f "$VOICE_DIR/en_US-lessac-medium.onnx" ]; then
  wget -q --show-progress \
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx" \
    -O "$VOICE_DIR/en_US-lessac-medium.onnx"
  wget -q --show-progress \
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json" \
    -O "$VOICE_DIR/en_US-lessac-medium.onnx.json"
fi

# ── Deskflow (KVM Server) ──────────────────────
echo "[6/10] Deskflow..."
snap install deskflow 2>/dev/null || apt install -y deskflow || true

# Deskflow Server Config
mkdir -p "$USER_HOME/.config/deskflow"
cat > "$USER_HOME/.config/deskflow/deskflow.conf" << 'EOF'
section: screens
    node1-links:
    ubuntu3:
    node2-rechts:
end

section: aliases
    node1-links:
        192.168.178.122
    node2-rechts:
        192.168.178.121
end

section: links
    node1-links:
        right = ubuntu3
    ubuntu3:
        left = node1-links
        right = node2-rechts
    node2-rechts:
        left = ubuntu3
end

section: options
    clipboardSharing = true
    clipboardSharingSize = 32
end
EOF
chown -R $MASTER_USER:$MASTER_USER "$USER_HOME/.config/deskflow"

# ── Obsidian ───────────────────────────────────
echo "[7/10] Obsidian..."
OBSIDIAN_VER="1.7.7"
mkdir -p "$USER_HOME/Applications"
wget -q --show-progress \
  "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VER}/Obsidian-${OBSIDIAN_VER}.AppImage" \
  -O "$USER_HOME/Applications/Obsidian.AppImage"
chmod +x "$USER_HOME/Applications/Obsidian.AppImage"

# ── Skeltah Repo klonen ────────────────────────
echo "[8/10] Skeltah repo..."
if [ -d "$SKELTAH_DIR" ]; then
  cd "$SKELTAH_DIR" && git pull
else
  git clone https://github.com/freddyoldb/Skeltah.git "$SKELTAH_DIR"
fi
chown -R $MASTER_USER:$MASTER_USER "$SKELTAH_DIR"

# ── Verzeichnisse ──────────────────────────────
echo "[9/10] Directories..."
mkdir -p "$JARVIS_DIR"/{brain,tts/voices,vault,logs,incoming,3d_output}
chown -R $MASTER_USER:$MASTER_USER "$JARVIS_DIR"

# ── Autostart ─────────────────────────────────
echo "[10/10] Autostart..."
mkdir -p "$USER_HOME/.config/autostart"

cat > "$USER_HOME/.config/autostart/deskflow-server.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Deskflow Server
Exec=deskflow --server --config $USER_HOME/.config/deskflow/deskflow.conf
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

cat > "$USER_HOME/.config/autostart/dropzone-daemon.desktop" << EOF
[Desktop Entry]
Type=Application
Name=JARVIS Drop-Zone-Daemon
Exec=python3 $SKELTAH_DIR/master/dropzone/dropzone_daemon.py
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

chown -R $MASTER_USER:$MASTER_USER "$USER_HOME/.config/autostart"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  MASTER SETUP COMPLETE!                  ║"
echo "║                                          ║"
echo "║  JARVIS: python3 $SKELTAH_DIR/master/brain/jarvis.py"
echo "║  TTS Test: echo 'Hello' | piper --model  ║"
echo "║    $VOICE_DIR/en_US-lessac-medium.onnx   ║"
echo "║    --output_file /tmp/t.wav && aplay /tmp/t.wav"
echo "║  Deskflow: startet automatisch           ║"
echo "║  Obsidian: ~/Applications/Obsidian.AppImage"
echo "╚══════════════════════════════════════════╝"
