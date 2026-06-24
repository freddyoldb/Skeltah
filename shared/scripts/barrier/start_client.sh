#!/bin/bash
# ============================================================
# Barrier CLIENT — läuft auf NODE 1 (192.168.178.122)
#                           und NODE 2 (192.168.178.121)
# Usage: bash start_client.sh <node1|node2>
# ============================================================
set -e

NODE="${1:-}"
SERVER_IP="192.168.178.44"
LOG="$HOME/.local/share/barrier/barrier_client.log"
SSL_DIR="$HOME/.local/share/barrier/SSL"

if [ -z "$NODE" ]; then
    echo "Usage: bash start_client.sh <node1|node2>"
    exit 1
fi

if [[ "$NODE" != "node1" && "$NODE" != "node2" ]]; then
    echo "Fehler: Node muss 'node1' oder 'node2' sein."
    exit 1
fi

mkdir -p "$HOME/.local/share/barrier" "$SSL_DIR/Fingerprints"

# Prüfen ob Server-Fingerprint eingetragen ist
TRUSTED="$SSL_DIR/Fingerprints/TrustedServers.txt"
if [ ! -f "$TRUSTED" ] || [ ! -s "$TRUSTED" ]; then
    echo ""
    echo "[WARNUNG] Kein Server-Fingerprint gefunden!"
    echo "Auf dem Master (Laptop) einmal ausführen:"
    echo "  cat ~/.local/share/barrier/SSL/Fingerprints/Local.txt"
    echo ""
    echo "Dann hier eintragen:"
    echo "  echo 'SHA256:<fingerprint>' > $TRUSTED"
    echo ""
    echo "Oder temporär ohne SSL starten (--disable-crypto, nur im Heimnetz!):"
    read -r -p "Ohne SSL fortfahren? (j/N): " ANTWORT
    if [[ "$ANTWORT" =~ ^[jJ]$ ]]; then
        NO_SSL=1
    else
        exit 1
    fi
fi

# Laufenden Client stoppen
pkill -f "barrierc" 2>/dev/null || true
sleep 1

echo "[$NODE] Verbinde mit Server $SERVER_IP:24800..."

if [ "${NO_SSL:-0}" = "1" ]; then
    barrierc \
        --no-tray \
        --disable-crypto \
        --name "$NODE" \
        --log "$LOG" \
        --log-level INFO \
        -f \
        "$SERVER_IP" &
else
    barrierc \
        --no-tray \
        --enable-crypto \
        --name "$NODE" \
        --log "$LOG" \
        --log-level INFO \
        -f \
        "$SERVER_IP" &
fi

CLIENT_PID=$!
echo "[$NODE] PID: $CLIENT_PID"
echo "[$NODE] Log: $LOG"
echo "[$NODE] Verbunden mit Master $SERVER_IP"
wait $CLIENT_PID
