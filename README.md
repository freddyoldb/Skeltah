# JARVIS OS — Operation: Local Sovereign

Autarkic, fully local AI assistant distributed across 3 Ubuntu nodes.
No paid APIs. No token limits. Everything runs on-premise.

## Cluster Topology

| Node | Machine | Role | Display |
|------|---------|------|---------|
| MASTER | ASUS F515JA (i7, 16GB) | Brain, Voice, KVM | Monitor 1 (AOC, horizontal) |
| NODE 1 | Komposter 1 | UI/HUD | Monitor 2 (ProLite, PORTRAIT) |
| NODE 2 | Komposter 2 | Peripherals, Smart Home | Monitor 3 (horizontal) |

## Components

### MASTER
- `brain/` — Ollama (Phi-3-mini / Llama-3-8B) + Jarvis personality core
- `tts/` — Piper TTS offline voice output
- `wakeword/` — Wake word detection daemon
- `dropzone/` — Drop-Zone-Daemon (file transfer between nodes via screen zones)
- `hud/` — Transparent overlay HUD for Master display

### NODE 1
- `ui/` — Full-screen JARVIS OS interface (portrait monitor)
  - Zone 1: Knowledge graph (vis.js) fed by Obsidian vault
  - Zone 2: Chat + SearXNG local search
  - Zone 3: Email (IMAP) + Calendar

### NODE 2
- `printer/` — OpenSCAD automation → .stl → Anycubic Kobra 3
- `smarthome/` — Zigbee2MQTT (lamps) + ADB (FireTV)
- `display/` — xrandr control daemon

### SHARED
- `config/` — Cluster-wide configuration
- `scripts/` — Deployment & setup scripts
- `docs/` — Architecture documentation

## Stack
- LLM: Ollama (local, offline)
- TTS: Piper TTS (offline)
- UI: PyQt6 + vis.js
- Search: SearXNG (self-hosted)
- KVM: Deskflow/Barrier
- File sync: scp/rsync via Drop-Zone-Daemon
- Smart Home: Zigbee2MQTT + MQTT + ADB
- 3D Print: OpenSCAD + Anycubic Kobra 3
