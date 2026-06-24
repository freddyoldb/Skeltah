# JARVIS OS — Morgen früh Checkliste
*Was du tun musst bevor alles läuft*

## ⚡ Priorität 1: FritzBox Kindersicherung deaktivieren
> Blockiert Laptop UND PC2 vom Internet (Issues #8, #5)

1. Browser öffnen → http://192.168.178.1
2. **Internet → Filter → Kindersicherung**
3. `ubuntu3` (Laptop) → **Keine Einschränkung**
4. `benutzer-ESPRIMO` (PC2) → **Keine Einschränkung**

Danach auf Laptop und PC2 im Terminal:
```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🖥️ Priorität 2: Barrier/Deskflow KVM
> Maus & Tastatur über alle 3 Bildschirme

**Auf dem Laptop (Master, Mitte):**
```bash
sudo apt install -y barrier
barrierc --no-restart --name ubuntu3 --config ~/.config/deskflow/deskflow.conf
# ODER GUI: barrier starten → Server-Modus → Layout wie unten
```

**Layout:** `[ESPRIMO links] ←→ [Laptop Mitte] ←→ [PC2 rechts]`

**Auf Node1 (ESPRIMO links) im Terminal:**
```bash
sudo apt install -y barrier
barrierc --no-restart 192.168.178.44
```

**Auf PC2 (rechts) im Terminal:**
```bash
sudo apt install -y barrier  
barrierc --no-restart 192.168.178.44
```

---

## 🔊 Priorität 3: Piper TTS Voice Model
> Nach FritzBox-Fix auf dem Laptop:

```bash
mkdir -p ~/jarvis/tts/voices && cd ~/jarvis/tts/voices
wget "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx"
wget "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json"
# Test:
echo "Good morning, I am JARVIS" | piper --model ~/jarvis/tts/voices/en_US-lessac-medium.onnx --output_file /tmp/test.wav && aplay /tmp/test.wav
```

---

## 🤖 Priorität 4: JARVIS starten
**Auf dem Laptop:**
```bash
# Brain mit Voice:
python3 ~/Skeltah/master/brain/jarvis_voice.py

# Nur Text (ohne TTS):
python3 ~/Skeltah/master/brain/jarvis_voice.py --no-voice
```

---

## 🖼️ Priorität 5: Portrait-Rotation PC2
> Einstellungen → Bildschirme → HDMI-1 → Ausrichtung: Links (90°)

---

## 📦 Priorität 6: Skeltah auf PC2 updaten
> Solange kein Internet auf PC2, von Node1 syncen:
```bash
# Auf Node1 (ESPRIMO links) ausführen:
rsync -av /home/user/Skeltah/ benutzer@192.168.178.121:~/Skeltah/
```

---

## ✅ Was bereits fertig ist
- [x] JARVIS Wallpaper auf allen 3 Maschinen
- [x] GNOME Dark Theme
- [x] Ollama + phi3:mini auf Laptop
- [x] Brain Core (jarvis_voice.py)
- [x] TTS (tts.py) — wartet auf Voice Model
- [x] Drop-Zone-Daemon (dropzone_daemon.py)
- [x] JARVIS UI für Node1 (jarvis_ui.py)
- [x] Knowledge Graph Builder
- [x] Wake Word Daemon (wake_daemon.py)
- [x] OpenSCAD Engine (node2)
- [x] SmartHome Controller (node2)
- [x] Alle systemd Services
- [x] Autostart-Einträge auf allen Maschinen
- [x] GitHub Issues für alle Blocker (#1-#9)

## 🐛 Offene Issues
- #1: PC2 kein Internet (FritzBox)
- #2: Deskflow/Barrier manueller Install
- #3: PyQt6 Node1 manueller Install
- #4: OpenSCAD/ADB PC2 Abhängigkeiten
- #5: PC2 FritzBox blockiert
- #7: Portrait-Rotation Wayland
- #8: Laptop FritzBox blockiert
- #9: Laptop Schlafmodus SSH-Disconnect

Alle Issues: https://github.com/freddyoldb/Skeltah/issues
