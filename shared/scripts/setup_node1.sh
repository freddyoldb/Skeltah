#!/bin/bash
# ============================================================
# JARVIS OS — NODE 1 SETUP (ESPRIMO links, 192.168.178.122)
# Portrait Monitor, JARVIS UI, Deskflow Client, SearXNG
# Ausführen mit: sudo bash setup_node1.sh
# ============================================================
set -e
JARVIS_DIR="/home/user/jarvis"
SKELTAH_DIR="/home/user/Skeltah"
USER_HOME="/home/user"

echo "╔══════════════════════════════════════════╗"
echo "║  JARVIS OS — NODE 1 SETUP                ║"
echo "╚══════════════════════════════════════════╝"

# ── System Update ──────────────────────────────
echo "[1/9] System update..."
apt update -y && apt upgrade -y

# ── Basis-Tools ────────────────────────────────
echo "[2/9] Base tools..."
apt install -y git curl wget python3 python3-pip python3-venv \
  alsa-utils adb openssh-server net-tools htop unzip \
  xdotool wmctrl x11-xserver-utils

# ── Python Pakete ──────────────────────────────
echo "[3/9] Python packages..."
pip3 install --break-system-packages \
  requests PyQt6 PyQt6-WebEngine paho-mqtt

# ── Deskflow (KVM Client) ──────────────────────
echo "[4/9] Deskflow..."
snap install deskflow 2>/dev/null || apt install -y deskflow || true

# ── Docker (für SearXNG) ───────────────────────
echo "[5/9] Docker..."
apt install -y docker.io docker-compose
systemctl enable docker
systemctl start docker
usermod -aG docker user

# ── SearXNG (lokale Suchmaschine) ─────────────
echo "[6/9] SearXNG..."
mkdir -p /opt/searxng
cat > /opt/searxng/docker-compose.yml << 'EOF'
version: "3"
services:
  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    ports:
      - "8080:8080"
    volumes:
      - /opt/searxng/config:/etc/searxng
    restart: unless-stopped
    environment:
      - BASE_URL=http://localhost:8080
      - INSTANCE_NAME=JARVIS Search
EOF
docker compose -f /opt/searxng/docker-compose.yml up -d || true

# ── Obsidian ───────────────────────────────────
echo "[7/9] Obsidian..."
OBSIDIAN_VER="1.7.7"
mkdir -p "$USER_HOME/Applications"
wget -q --show-progress \
  "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VER}/Obsidian-${OBSIDIAN_VER}.AppImage" \
  -O "$USER_HOME/Applications/Obsidian.AppImage"
chmod +x "$USER_HOME/Applications/Obsidian.AppImage"
chown user:user "$USER_HOME/Applications/Obsidian.AppImage"

# ── Skeltah Repo klonen ────────────────────────
echo "[8/9] Skeltah repo..."
if [ -d "$SKELTAH_DIR" ]; then
  cd "$SKELTAH_DIR" && git pull
else
  git clone https://github.com/freddyoldb/Skeltah.git "$SKELTAH_DIR"
fi
chown -R user:user "$SKELTAH_DIR"

# ── Verzeichnisse ──────────────────────────────
echo "[9/9] Directories..."
mkdir -p "$JARVIS_DIR"/{vault,logs,incoming}
chown -R user:user "$JARVIS_DIR"

# ── Deskflow Client Autostart ──────────────────
cat > "$USER_HOME/.config/autostart/deskflow-client.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Deskflow Client
Exec=deskflow --client 192.168.178.44
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
chown user:user "$USER_HOME/.config/autostart/deskflow-client.desktop"

# ── JARVIS UI Autostart ────────────────────────
cat > "$USER_HOME/.config/autostart/jarvis-ui.desktop" << EOF
[Desktop Entry]
Type=Application
Name=JARVIS UI
Exec=python3 $SKELTAH_DIR/node1/ui/jarvis_ui.py
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
chown user:user "$USER_HOME/.config/autostart/jarvis-ui.desktop"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  NODE 1 SETUP COMPLETE!                  ║"
echo "║                                          ║"
echo "║  Deskflow: deskflow --client 192.168.178.44"
echo "║  JARVIS UI: python3 $SKELTAH_DIR/node1/ui/jarvis_ui.py"
echo "║  SearXNG: http://localhost:8080          ║"
echo "║  Obsidian: ~/Applications/Obsidian.AppImage"
echo "╚══════════════════════════════════════════╝"
