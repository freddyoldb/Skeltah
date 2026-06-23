#!/bin/bash
# Deskflow (Synergy/Barrier) KVM Setup
# Layout: [ESPRIMO(links)] [LAPTOP/MASTER(mitte)] [PC2(rechts)]
#
# Server: Laptop (hat Maus+Tastatur, 192.168.178.44)
# Client links: ESPRIMO (192.168.178.122)
# Client rechts: PC2 (192.168.178.121)
#
# Ausführen auf dem LAPTOP (Master)

SERVER_NAME="ubuntu3"   # hostname des Laptops
CONFIG_DIR="$HOME/.config/deskflow"
CONFIG_FILE="$CONFIG_DIR/deskflow.conf"

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" << 'EOF'
section: screens
    esprimo-links:
        halfDuplexCapsLock = false
        halfDuplexNumLock = false
        halfDuplexScrollLock = false
        xtestIsXineramaUnaware = false
        switchCorners = none +top-left +top-right +bottom-left +bottom-right
        switchCornerSize = 0
    ubuntu3:
        halfDuplexCapsLock = false
        halfDuplexNumLock = false
        halfDuplexScrollLock = false
        xtestIsXineramaUnaware = false
        switchCorners = none +top-left +top-right +bottom-left +bottom-right
        switchCornerSize = 0
    pc2-rechts:
        halfDuplexCapsLock = false
        halfDuplexNumLock = false
        halfDuplexScrollLock = false
        xtestIsXineramaUnaware = false
        switchCorners = none +top-left +top-right +bottom-left +bottom-right
        switchCornerSize = 0
end

section: aliases
    esprimo-links:
        192.168.178.122
    pc2-rechts:
        192.168.178.121
end

section: links
    esprimo-links:
        right = ubuntu3
    ubuntu3:
        left = esprimo-links
        right = pc2-rechts
    pc2-rechts:
        left = ubuntu3
end

section: options
    relativeMouseMoves = false
    screenSaverSync = true
    win32KeepForeground = false
    clipboardSharing = true
    clipboardSharingSize = 32
    switchCorners = none +top-left +top-right +bottom-left +bottom-right
    switchCornerSize = 0
end
EOF

echo "=== Deskflow Server-Konfiguration erstellt ==="
echo "Config: $CONFIG_FILE"
echo ""
echo "Server starten (auf Laptop):"
echo "  deskflow --server --config $CONFIG_FILE"
echo ""
echo "Client auf ESPRIMO (links) starten:"
echo "  ssh user@192.168.178.122 'deskflow --client 192.168.178.44'"
echo ""
echo "Client auf PC2 (rechts) starten:"
echo "  ssh benutzer@192.168.178.121 'deskflow --client 192.168.178.44'"
