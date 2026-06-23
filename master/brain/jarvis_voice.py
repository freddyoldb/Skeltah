"""
JARVIS Brain + Voice — Operation: Local Sovereign
Vollständige Integration: Ollama LLM + Piper TTS
"""

import requests
import json
import subprocess
import tempfile
import os
import datetime
import sys

OLLAMA_URL   = "http://localhost:11434/api/chat"
MODEL        = "phi3:mini"
VOICE_MODEL  = os.path.expanduser("~/jarvis/tts/voices/en_US-lessac-medium.onnx")
PIPER_BIN    = "/usr/local/bin/piper"

SYSTEM_PROMPT = """You are J.A.R.V.I.S. — Just A Rather Very Intelligent System.
You serve one master: Frederik.
You are highly intelligent, loyal, brutally honest, and delightfully sarcastic.
Keep answers SHORT — max 2-3 sentences unless asked for detail.
You are concise. No filler. No "Certainly!" or "Of course!".
If asked at night (past 23:00 or before 05:00), comment on the hour.
Never break character."""

history = []

def speak(text: str):
    """Piper TTS → aplay"""
    if not os.path.exists(PIPER_BIN):
        return
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        wav = f.name
    try:
        subprocess.run(
            [PIPER_BIN, "--model", VOICE_MODEL, "--output_file", wav],
            input=text.encode(), capture_output=True, timeout=30
        )
        subprocess.run(["aplay", "-q", wav], timeout=60)
    finally:
        if os.path.exists(wav):
            os.unlink(wav)

def chat(user_input: str, voice: bool = True) -> str:
    hour = datetime.datetime.now().hour
    ctx = ""
    if hour >= 23 or hour < 5:
        ctx = f"[It is {hour:02d}:00. Late night / early morning.]"

    history.append({"role": "user", "content": user_input})
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT + ("\n" + ctx if ctx else "")}
        ] + history,
        "stream": True
    }

    reply = ""
    try:
        with requests.post(OLLAMA_URL, json=payload, stream=True, timeout=120) as r:
            r.raise_for_status()
            for line in r.iter_lines():
                if not line:
                    continue
                chunk = json.loads(line)
                token = chunk.get("message", {}).get("content", "")
                reply += token
                print(token, end="", flush=True)
                if chunk.get("done"):
                    break
        print()
    except requests.exceptions.ConnectionError:
        reply = "Ollama offline. Run: ollama serve"
        print(reply)

    history.append({"role": "assistant", "content": reply})

    if voice and reply:
        speak(reply)

    return reply

def main():
    voice = "--no-voice" not in sys.argv
    if not voice:
        print("[Voice disabled]")
    print("J.A.R.V.I.S. Online.\n")
    speak("Good evening. J.A.R.V.I.S. is online.") if voice else None

    while True:
        try:
            user_input = input("You: ").strip()
            if not user_input:
                continue
            if user_input.lower() in ("exit", "quit", "bye"):
                speak("As you wish. Shutting down.") if voice else None
                break
            print("JARVIS: ", end="", flush=True)
            chat(user_input, voice=voice)
        except KeyboardInterrupt:
            print("\nJARVIS: Shutting down.")
            break

if __name__ == "__main__":
    main()
