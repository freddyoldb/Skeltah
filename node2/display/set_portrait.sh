#!/bin/bash
# Portrait-Rotation für PC2 Monitor (HDMI-1)
# Ausführen direkt am PC2 als benutzer im Terminal

# Methode 1: GNOME Display Config (Wayland-nativ)
gdbus call --session \
  --dest org.gnome.Mutter.DisplayConfig \
  --object-path /org/gnome/Mutter/DisplayConfig \
  --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null | \
  python3 -c "
import sys, json
data = sys.stdin.read()
print('Display state erhalten')
" || true

# Methode 2: Über GNOME Settings GUI
echo ""
echo "Falls obiges nicht klappt:"
echo "1. Einstellungen → Bildschirme → HDMI-1 → Ausrichtung: Links"
echo ""
echo "Methode 3: gnome-randr (falls installiert)"
which gnome-randr 2>/dev/null && gnome-randr modify HDMI-1 --rotate 90 || true
