#!/bin/bash
# Piper von Skeltah-Repo auf Laptop installieren (kein Internet nötig)
# Ausführen auf Node1: bash deploy_piper.sh

LAPTOP="frederik@192.168.178.44"
PIPER_DIR="/home/user/Skeltah/shared/piper"

echo "=== Deploying Piper TTS to Laptop ==="
ssh $LAPTOP "mkdir -p /tmp/piper-deploy"
scp $PIPER_DIR/piper $LAPTOP:/tmp/piper-deploy/
scp $PIPER_DIR/lib*.so* $LAPTOP:/tmp/piper-deploy/ 2>/dev/null || true
ssh $LAPTOP "
  sudo cp /tmp/piper-deploy/piper /usr/local/bin/
  sudo chmod +x /usr/local/bin/piper
  sudo cp /tmp/piper-deploy/lib*.so* /usr/local/lib/ 2>/dev/null || true
  sudo ldconfig
  piper --version 2>&1 && echo 'PIPER INSTALLED OK'
"
