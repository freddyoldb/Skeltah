"""
JARVIS Wake Word Daemon — Operation: Local Sovereign
Listens for "Jarvis" via microphone, triggers brain on detection.
Uses pvporcupine (offline) or vosk as fallback.
"""

import subprocess
import sys
import os
import wave
import json
import threading
import queue

KEYWORD = "jarvis"
BRAIN_SCRIPT = os.path.expanduser("~/Skeltah/master/brain/jarvis_voice.py")

# ── Try Vosk (free, offline) ─────────────────────────────────────────────

def listen_vosk():
    try:
        from vosk import Model, KaldiRecognizer
        import pyaudio
    except ImportError:
        print("[Wake] Installing vosk + pyaudio...")
        subprocess.run([sys.executable, "-m", "pip", "install",
                        "vosk", "pyaudio", "--break-system-packages", "-q"])
        from vosk import Model, KaldiRecognizer
        import pyaudio

    MODEL_PATH = os.path.expanduser("~/jarvis/wakeword/vosk-model-small-en-us")
    if not os.path.exists(MODEL_PATH):
        print(f"[Wake] Downloading Vosk model to {MODEL_PATH}...")
        os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
        subprocess.run([
            "wget", "-q", "--show-progress",
            "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip",
            "-O", "/tmp/vosk-model.zip"
        ])
        subprocess.run(["unzip", "-q", "/tmp/vosk-model.zip", "-d",
                        os.path.expanduser("~/jarvis/wakeword/")])
        os.rename(
            os.path.expanduser("~/jarvis/wakeword/vosk-model-small-en-us-0.15"),
            MODEL_PATH
        )

    model = Model(MODEL_PATH)
    rec = KaldiRecognizer(model, 16000)
    p = pyaudio.PyAudio()
    stream = p.open(format=pyaudio.paInt16, channels=1, rate=16000,
                    input=True, frames_per_buffer=8000)

    print(f"[Wake] Listening for '{KEYWORD}'... (Ctrl+C to stop)")
    while True:
        data = stream.read(4000, exception_on_overflow=False)
        if rec.AcceptWaveform(data):
            result = json.loads(rec.Result())
            text = result.get("text", "").lower()
            if KEYWORD in text:
                print(f"[Wake] '{KEYWORD}' detected! → triggering JARVIS")
                on_wake()


def on_wake():
    """Called when wake word is detected."""
    # Play activation sound
    subprocess.run(["aplay", "-q",
                    os.path.expanduser("~/Skeltah/shared/assets/wake.wav")],
                   capture_output=True)
    # Get voice input for 5 seconds
    print("[Wake] Listening for command...")
    # Open interactive JARVIS session (single shot)
    subprocess.Popen([sys.executable, BRAIN_SCRIPT])


if __name__ == "__main__":
    print("J.A.R.V.I.S. Wake Word Daemon starting...")
    try:
        listen_vosk()
    except KeyboardInterrupt:
        print("\n[Wake] Stopped.")
