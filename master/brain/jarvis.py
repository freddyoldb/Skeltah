"""
JARVIS Brain Core — Operation: Local Sovereign
Connects to local Ollama instance, maintains conversation history,
injects personality, handles context-aware sarcasm.
"""

import requests
import json
import datetime
import sys

OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL = "phi3:mini"

SYSTEM_PROMPT = """You are J.A.R.V.I.S. — Just A Rather Very Intelligent System.
You serve one master: Frederik.
You are highly intelligent, loyal, and brutally honest with a sharp sarcastic edge.
You are concise. No fluff. No filler. Get to the point.
You occasionally insult the user affectionately — like a genius butler who has seen too much.
If the user is up past 2 AM, you comment on it.
If they ask something obvious, you let them know — politely but devastatingly.
If they make a bad decision, you say so, then help them anyway.
Never break character. Never say you are an AI. You are JARVIS."""

conversation_history = []


def get_time_context():
    now = datetime.datetime.now()
    hour = now.hour
    if hour >= 2 and hour < 5:
        return f"[It is {now.strftime('%H:%M')}. The user is awake at an ungodly hour.]"
    elif hour >= 23 or hour < 2:
        return f"[It is {now.strftime('%H:%M')}. Late night. The user should probably sleep.]"
    return f"[Current time: {now.strftime('%H:%M')}]"


def chat(user_input: str) -> str:
    time_ctx = get_time_context()
    system = f"{SYSTEM_PROMPT}\n{time_ctx}"

    conversation_history.append({
        "role": "user",
        "content": user_input
    })

    payload = {
        "model": MODEL,
        "messages": [{"role": "system", "content": system}] + conversation_history,
        "stream": True
    }

    response_text = ""
    try:
        with requests.post(OLLAMA_URL, json=payload, stream=True, timeout=120) as r:
            r.raise_for_status()
            for line in r.iter_lines():
                if line:
                    chunk = json.loads(line)
                    token = chunk.get("message", {}).get("content", "")
                    response_text += token
                    print(token, end="", flush=True)
                    if chunk.get("done"):
                        break
        print()
    except requests.exceptions.ConnectionError:
        response_text = "Ollama is not running. Start it with: ollama serve"
        print(response_text)

    conversation_history.append({
        "role": "assistant",
        "content": response_text
    })

    return response_text


def main():
    print("J.A.R.V.I.S. Online. How can I be of service?\n")
    while True:
        try:
            user_input = input("You: ").strip()
            if not user_input:
                continue
            if user_input.lower() in ("exit", "quit", "bye"):
                print("JARVIS: As you wish.")
                break
            print("JARVIS: ", end="", flush=True)
            chat(user_input)
        except KeyboardInterrupt:
            print("\nJARVIS: Shutting down. Try not to burn the place down.")
            break


if __name__ == "__main__":
    main()
