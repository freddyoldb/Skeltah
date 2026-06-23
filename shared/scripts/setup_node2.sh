#!/bin/bash
# ============================================================
# JARVIS OS — NODE 2 SETUP (ESPRIMO rechts, 192.168.178.121)
# 3D Printer, Smart Home, ADB, OpenSCAD, Deskflow Client
# Ausführen mit: sudo bash setup_node2.sh
# ============================================================
set -e
JARVIS_DIR="/home/benutzer/jarvis"
SKELTAH_DIR="/home/benutzer/Skeltah"
USER_HOME="/home/benutzer"
NODE_USER="benutzer"

echo "╔══════════════════════════════════════════╗"
echo "║  JARVIS OS — NODE 2 SETUP                ║"
echo "╚══════════════════════════════════════════╝"

# ── System Update ──────────────────────────────
echo "[1/9] System update..."
apt update -y && apt upgrade -y

# ── Basis-Tools ────────────────────────────────
echo "[2/9] Base tools..."
apt install -y git curl wget python3 python3-pip python3-venv \
  openssh-server net-tools htop unzip rsync \
  xdotool wmctrl x11-xserver-utils

# ── Python Pakete ──────────────────────────────
echo "[3/9] Python packages..."
pip3 install --break-system-packages \
  requests paho-mqtt PyQt6

# ── OpenSCAD ───────────────────────────────────
echo "[4/9] OpenSCAD..."
apt install -y openscad

# ── ADB (FireTV) ───────────────────────────────
echo "[5/9] ADB..."
apt install -y adb
# FireTV ADB aktivieren: Einstellungen → Mein Fire TV → Entwickleroptionen → ADB-Debugging ON

# ── MQTT Tools ─────────────────────────────────
echo "[6/9] MQTT..."
apt install -y mosquitto-clients

# ── Deskflow (KVM Client) ──────────────────────
echo "[7/9] Deskflow..."
snap install deskflow 2>/dev/null || apt install -y deskflow || true

# ── Obsidian ───────────────────────────────────
echo "[8/9] Obsidian..."
OBSIDIAN_VER="1.7.7"
mkdir -p "$USER_HOME/Applications"
wget -q --show-progress \
  "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VER}/Obsidian-${OBSIDIAN_VER}.AppImage" \
  -O "$USER_HOME/Applications/Obsidian.AppImage"
chmod +x "$USER_HOME/Applications/Obsidian.AppImage"
chown $NODE_USER:$NODE_USER "$USER_HOME/Applications/Obsidian.AppImage"

# ── Skeltah Repo klonen ────────────────────────
echo "[9/9] Skeltah + Dirs..."
if [ -d "$SKELTAH_DIR" ]; then
  cd "$SKELTAH_DIR" && git pull
else
  git clone https://github.com/freddyoldb/Skeltah.git "$SKELTAH_DIR"
fi
chown -R $NODE_USER:$NODE_USER "$SKELTAH_DIR"

mkdir -p "$JARVIS_DIR"/{3d_output,logs,incoming}
chown -R $NODE_USER:$NODE_USER "$JARVIS_DIR"

# ── Autostart ──────────────────────────────────
mkdir -p "$USER_HOME/.config/autostart"

cat > "$USER_HOME/.config/autostart/deskflow-client.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Deskflow Client
Exec=deskflow --client 192.168.178.44
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
chown $NODE_USER:$NODE_USER "$USER_HOME/.config/autostart/deskflow-client.desktop"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  NODE 2 SETUP COMPLETE!                  ║"
echo "║                                          ║"
echo "║  OpenSCAD: openscad                      ║"
echo "║  3D Engine: python3 $SKELTAH_DIR/node2/printer/openscad_engine.py"
echo "║  SmartHome: python3 $SKELTAH_DIR/node2/smarthome/smarthome.py"
echo "║  ADB: adb connect <firetv-ip>:5555       ║"
echo "║  Obsidian: ~/Applications/Obsidian.AppImage"
echo "║  Deskflow: startet automatisch           ║"
echo "╚══════════════════════════════════════════╝"
