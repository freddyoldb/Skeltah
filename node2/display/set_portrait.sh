#!/bin/bash
# ============================================================
# NODE 2 Portrait-Rotation — Monitor rechts, hochkant gedreht
# Erkennt automatisch den richtigen Output
# Usage: bash set_portrait.sh [left|right]  (default: left)
# ============================================================

ROTATION="${1:-left}"

echo "[Portrait] Suche aktiven Monitor-Output..."

# Aktiven Output automatisch erkennen (connected + hat Auflösung)
OUTPUT=$(xrandr --query | awk '/connected/ && /[0-9]+x[0-9]+/ {print $1; exit}')

if [ -z "$OUTPUT" ]; then
    # Fallback: ersten connected Output nehmen
    OUTPUT=$(xrandr --query | awk '/ connected/ {print $1; exit}')
fi

if [ -z "$OUTPUT" ]; then
    echo "[FEHLER] Kein Monitor-Output gefunden!"
    echo "Verfügbare Outputs:"
    xrandr --query | grep " connected"
    exit 1
fi

echo "[Portrait] Output: $OUTPUT  →  Rotation: $ROTATION"
xrandr --output "$OUTPUT" --rotate "$ROTATION"
echo "[Portrait] Fertig."

# Dauerhaft via autostart speichern
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/set-portrait.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Set Portrait Rotation
Exec=xrandr --output $OUTPUT --rotate $ROTATION
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
echo "[Portrait] Autostart eingetragen: $AUTOSTART_DIR/set-portrait.desktop"
