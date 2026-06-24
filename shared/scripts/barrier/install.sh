#!/bin/bash
# ============================================================
# Barrier Install — läuft auf ALLEN 3 Maschinen
# Usage: bash install.sh
# ============================================================
set -e

echo "[Barrier] Installiere barrier..."
sudo apt update -qq
sudo apt install -y barrier

echo "[Barrier] Version:"
barrier --version 2>/dev/null || barriers --version 2>/dev/null || echo "Installiert (Version nicht abrufbar)"

echo "[Barrier] SSL-Verzeichnis vorbereiten..."
mkdir -p ~/.local/share/barrier/SSL/Fingerprints

echo "[Barrier] Fertig. Nächste Schritte:"
echo "  Master (Laptop .44):  bash start_server.sh"
echo "  NODE 1 (.122):        bash start_client.sh node1"
echo "  NODE 2 (.121):        bash start_client.sh node2"
