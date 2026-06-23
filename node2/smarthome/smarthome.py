"""
JARVIS Smart Home Controller — Node 2
Controls Zigbee lamps via Zigbee2MQTT and FireTV via ADB.
"""

import subprocess
import requests
import json
import time

# Zigbee2MQTT REST API (running on Node2 or separate host)
Z2M_URL = "http://localhost:8080/api"

# FireTV ADB
FIRETV_IP = "192.168.178.XXX"  # Set your FireTV IP here
ADB_BIN = "adb"

# ADB Key codes
ADB_KEYS = {
    "home": 3,
    "back": 4,
    "menu": 82,
    "play_pause": 85,
    "next": 87,
    "prev": 88,
    "volume_up": 24,
    "volume_down": 25,
    "mute": 164,
    "up": 19,
    "down": 20,
    "left": 21,
    "right": 22,
    "select": 23,
    "power": 26,
}


# ─── Zigbee Lamp Control ───────────────────────────────────────────────────

def lamp_on(device: str = "Zimmer Lampe"):
    """Turn a Zigbee lamp on."""
    _z2m_set(device, {"state": "ON"})

def lamp_off(device: str = "Zimmer Lampe"):
    """Turn a Zigbee lamp off."""
    _z2m_set(device, {"state": "OFF"})

def lamp_brightness(device: str, brightness: int):
    """Set lamp brightness (0-254)."""
    _z2m_set(device, {"brightness": max(0, min(254, brightness))})

def lamp_color_temp(device: str, temp: int):
    """Set color temperature (153=cool, 500=warm)."""
    _z2m_set(device, {"color_temp": temp})

def lamp_scene(scene: str):
    """Predefined scenes."""
    scenes = {
        "work":    {"state": "ON", "brightness": 254, "color_temp": 200},
        "relax":   {"state": "ON", "brightness": 128, "color_temp": 400},
        "night":   {"state": "ON", "brightness": 30,  "color_temp": 500},
        "cinema":  {"state": "OFF"},
    }
    if scene in scenes:
        _z2m_set("Zimmer Lampe", scenes[scene])
        print(f"[SmartHome] Scene: {scene}")
    else:
        print(f"[SmartHome] Unknown scene: {scene}. Options: {list(scenes.keys())}")

def _z2m_set(device: str, payload: dict):
    try:
        url = f"{Z2M_URL}/devices/{device}/set"
        r = requests.post(url, json=payload, timeout=5)
        print(f"[SmartHome] {device} → {payload} ({r.status_code})")
    except Exception as e:
        print(f"[SmartHome] Zigbee error: {e}")


# ─── FireTV ADB Control ────────────────────────────────────────────────────

def adb_connect():
    result = subprocess.run([ADB_BIN, "connect", f"{FIRETV_IP}:5555"],
                            capture_output=True, text=True)
    print(f"[ADB] {result.stdout.strip()}")

def adb_key(action: str):
    """Send key press to FireTV."""
    keycode = ADB_KEYS.get(action.lower())
    if keycode is None:
        print(f"[ADB] Unknown action: {action}. Options: {list(ADB_KEYS.keys())}")
        return
    subprocess.run([ADB_BIN, "-s", f"{FIRETV_IP}:5555",
                    "shell", "input", "keyevent", str(keycode)],
                   capture_output=True)
    print(f"[ADB] FireTV ← {action} (keycode {keycode})")

def adb_launch_app(package: str):
    """Launch an app by package name."""
    subprocess.run([ADB_BIN, "-s", f"{FIRETV_IP}:5555",
                    "shell", "monkey", "-p", package, "1"],
                   capture_output=True)
    print(f"[ADB] Launched: {package}")

def firetv_netflix():
    adb_launch_app("com.netflix.ninja")

def firetv_youtube():
    adb_launch_app("com.amazon.youtube")


# ─── xrandr Display Control ───────────────────────────────────────────────

def display_rotate(output: str, rotation: str = "normal"):
    """Rotate display. rotation: normal, left, right, inverted"""
    subprocess.run(["xrandr", "--output", output, "--rotate", rotation])
    print(f"[Display] {output} → {rotation}")

def display_off(output: str):
    subprocess.run(["xrandr", "--output", output, "--off"])
    print(f"[Display] {output} OFF")

def display_on(output: str, mode: str = "1920x1080"):
    subprocess.run(["xrandr", "--output", output, "--auto"])
    print(f"[Display] {output} ON")

def display_list():
    result = subprocess.run(["xrandr"], capture_output=True, text=True)
    print(result.stdout)


if __name__ == "__main__":
    print("JARVIS Smart Home Controller")
    print("Commands: lamp_on(), lamp_off(), lamp_scene('work'), adb_key('play_pause'), display_list()")
