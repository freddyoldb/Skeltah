#!/bin/bash
# ============================================================
# Barrier Autostart via systemd user-service
# Usage: bash setup_autostart.sh <server|node1|node2>
# ============================================================
set -e

ROLE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSTEMD_DIR="$HOME/.config/systemd/user"

mkdir -p "$SYSTEMD_DIR"

case "$ROLE" in
  server)
    cat > "$SYSTEMD_DIR/barrier-server.service" << EOF
[Unit]
Description=Barrier KVM Server (master)
After=graphical-session.target network.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT_DIR/start_server.sh
Restart=on-failure
RestartSec=5
Environment=DISPLAY=:0
Environment=XAUTHORITY=%h/.Xauthority

[Install]
WantedBy=graphical-session.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable barrier-server.service
    systemctl --user start  barrier-server.service
    echo "[Autostart] Barrier SERVER aktiviert."
    systemctl --user status barrier-server.service --no-pager
    ;;

  node1|node2)
    cat > "$SYSTEMD_DIR/barrier-client.service" << EOF
[Unit]
Description=Barrier KVM Client ($ROLE)
After=graphical-session.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash $SCRIPT_DIR/start_client.sh $ROLE
Restart=on-failure
RestartSec=5
Environment=DISPLAY=:0
Environment=XAUTHORITY=%h/.Xauthority

[Install]
WantedBy=graphical-session.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable barrier-client.service
    systemctl --user start  barrier-client.service
    echo "[Autostart] Barrier CLIENT ($ROLE) aktiviert."
    systemctl --user status barrier-client.service --no-pager
    ;;

  *)
    echo "Usage: bash setup_autostart.sh <server|node1|node2>"
    exit 1
    ;;
esac
