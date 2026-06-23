#!/bin/bash
# Deploy JARVIS Brain to Master (ASUS Laptop)
# Run from ESPRIMO: ./deploy_master.sh

MASTER="frederik@192.168.178.44"
REMOTE_DIR="/home/frederik/jarvis"

echo "=== Deploying JARVIS Brain to Master ==="

# Create remote directory
ssh $MASTER "mkdir -p $REMOTE_DIR/brain"

# Copy brain files
scp /home/user/Skeltah/master/brain/jarvis.py $MASTER:$REMOTE_DIR/brain/
scp /home/user/Skeltah/master/brain/requirements.txt $MASTER:$REMOTE_DIR/brain/

# Install dependencies
ssh $MASTER "cd $REMOTE_DIR/brain && pip3 install -r requirements.txt --break-system-packages"

echo "=== Done! Start JARVIS on Master with: ==="
echo "ssh $MASTER 'python3 $REMOTE_DIR/brain/jarvis.py'"
