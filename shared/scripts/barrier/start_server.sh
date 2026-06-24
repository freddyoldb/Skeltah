#!/bin/bash
# ============================================================
# Barrier SERVER — läuft auf dem MASTER (Laptop 192.168.178.44)
# Maus & Tastatur sind hier angeschlossen
# Usage: bash start_server.sh
# ============================================================
set -e

CONF_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$CONF_DIR/barrier.conf"
LOG="$HOME/.local/share/barrier/barrier_server.log"
SSL_DIR="$HOME/.local/share/barrier/SSL"

mkdir -p "$HOME/.local/share/barrier" "$SSL_DIR/Fingerprints"

# SSL-Zertifikat generieren falls noch nicht vorhanden
if [ ! -f "$SSL_DIR/Barrier.pem" ]; then
    echo "[Server] Generiere SSL-Zertifikat..."
    openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 \
        -keyout "$SSL_DIR/Barrier.pem" \
        -out    "$SSL_DIR/Barrier.pem" \
        -subj "/CN=barrier" 2>/dev/null
    # Fingerprint speichern damit Clients ihn kennen
    openssl x509 -noout -fingerprint -sha256 \
        -in "$SSL_DIR/Barrier.pem" \
        | cut -d= -f2 \
        > "$SSL_DIR/Fingerprints/Local.txt"
    echo "[Server] Zertifikat erstellt:"
    cat "$SSL_DIR/Fingerprints/Local.txt"
    echo ""
    echo "[WICHTIG] Diesen Fingerprint auf NODE1 + NODE2 eintragen:"
    echo "  Datei: ~/.local/share/barrier/SSL/Fingerprints/TrustedServers.txt"
fi

# Laufenden Server stoppen falls vorhanden
pkill -f "barriers" 2>/dev/null || true
sleep 1

echo "[Server] Starte Barrier Server (master, SSL, Port 24800)..."
barriers \
    --no-tray \
    --enable-crypto \
    --name master \
    -c "$CONF" \
    --log "$LOG" \
    --log-level INFO \
    -f &

SERVER_PID=$!
echo "[Server] PID: $SERVER_PID"
echo "[Server] Log: $LOG"
echo ""
echo "[Server] Layout:"
echo "  [node1 - Links] <---> [master - Mitte] <---> [node2 - Rechts]"
echo ""
echo "Clients jetzt starten:"
echo "  NODE 1 (192.168.178.122): bash start_client.sh node1"
echo "  NODE 2 (192.168.178.121): bash start_client.sh node2"

wait $SERVER_PID
