#!/bin/bash
# Deploy alle JARVIS systemd-Services auf alle Maschinen
SKELTAH="/home/user/Skeltah"
SD="$SKELTAH/shared/systemd"

echo "=== Deploying JARVIS Services ==="

# Master: Deskflow Server + Brain
ssh frederik@192.168.178.44 "
  sudo cp /dev/stdin /etc/systemd/system/jarvis-deskflow-server.service
  sudo systemctl daemon-reload
  sudo systemctl enable jarvis-deskflow-server
  sudo systemctl start jarvis-deskflow-server
" < "$SD/jarvis-deskflow-server.service"

# Node1 (diese Maschine): Deskflow Client + UI
sudo cp "$SD/jarvis-deskflow-client.service" /etc/systemd/system/
sudo sed -i 's/%i/user/' /etc/systemd/system/jarvis-deskflow-client.service
sudo cp "$SD/jarvis-ui.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable jarvis-deskflow-client jarvis-ui

# Node2: Deskflow Client
ssh benutzer@192.168.178.121 "
  sudo bash -c 'cat > /etc/systemd/system/jarvis-deskflow-client.service' << 'SEOF'
$(sed 's/%i/benutzer/' "$SD/jarvis-deskflow-client.service")
SEOF
  sudo systemctl daemon-reload
  sudo systemctl enable jarvis-deskflow-client
  sudo systemctl start jarvis-deskflow-client
"

echo "=== Done ==="
