"""
JARVIS TTS — Piper offline text-to-speech
Requires: piper-tts installed, voice model downloaded
"""

import subprocess
import tempfile
import os
import shutil

PIPER_BIN = shutil.which("piper") or "/usr/local/bin/piper"
VOICE_MODEL = os.path.expanduser("~/jarvis/tts/voices/en_US-lessac-medium.onnx")


def speak(text: str):
    """Convert text to speech via Piper TTS and play through speakers."""
    if not os.path.exists(PIPER_BIN):
        print(f"[TTS] Piper not found at {PIPER_BIN}")
        return

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        wav_path = f.name

    try:
        # Generate WAV with Piper
        proc = subprocess.run(
            [PIPER_BIN, "--model", VOICE_MODEL, "--output_file", wav_path],
            input=text.encode(),
            capture_output=True,
            timeout=30
        )
        if proc.returncode != 0:
            print(f"[TTS] Piper error: {proc.stderr.decode()}")
            return

        # Play via aplay (ALSA)
        subprocess.run(["aplay", "-q", wav_path], timeout=60)

    except FileNotFoundError:
        print("[TTS] aplay not found. Install with: sudo apt install alsa-utils")
    except subprocess.TimeoutExpired:
        print("[TTS] TTS timed out")
    finally:
        if os.path.exists(wav_path):
            os.unlink(wav_path)


if __name__ == "__main__":
    speak("Good evening. J.A.R.V.I.S. is online and fully operational.")
