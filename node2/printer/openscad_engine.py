"""
JARVIS OpenSCAD Automation Engine — Node 2
Generates .scad from text prompt via Jarvis/Ollama,
compiles to .stl, ready for slicing & printing.
"""

import subprocess
import os
import requests
import json
import datetime

OLLAMA_URL = "http://192.168.178.44:11434/api/chat"
MODEL = "phi3:mini"
OUTPUT_DIR = os.path.expanduser("~/jarvis/3d_output")
OPENSCAD_BIN = "/usr/bin/openscad"


SCAD_SYSTEM_PROMPT = """You are a parametric 3D modeling expert using OpenSCAD.
When given a description, output ONLY valid OpenSCAD code — no explanation, no markdown, no backticks.
Use simple primitives (cube, cylinder, sphere) and boolean operations (union, difference, intersection).
Always add a comment at the top describing what the object is.
Output must be compilable with openscad -o output.stl input.scad"""


def prompt_to_scad(description: str) -> str:
    """Ask Ollama to generate OpenSCAD code from text description."""
    print(f"[OpenSCAD] Generating .scad for: {description}")
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SCAD_SYSTEM_PROMPT},
            {"role": "user", "content": f"Create an OpenSCAD model: {description}"}
        ],
        "stream": False
    }
    r = requests.post(OLLAMA_URL, json=payload, timeout=120)
    r.raise_for_status()
    return r.json()["message"]["content"].strip()


def compile_scad(scad_code: str, name: str) -> str:
    """Write .scad file and compile to .stl. Returns .stl path."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_name = name.replace(" ", "_")[:30]

    scad_path = os.path.join(OUTPUT_DIR, f"{safe_name}_{timestamp}.scad")
    stl_path = os.path.join(OUTPUT_DIR, f"{safe_name}_{timestamp}.stl")

    with open(scad_path, "w") as f:
        f.write(scad_code)
    print(f"[OpenSCAD] Saved .scad: {scad_path}")

    print(f"[OpenSCAD] Compiling to .stl...")
    result = subprocess.run(
        [OPENSCAD_BIN, "-o", stl_path, scad_path],
        capture_output=True, text=True, timeout=120
    )
    if result.returncode == 0:
        size = os.path.getsize(stl_path) // 1024
        print(f"[OpenSCAD] .stl ready: {stl_path} ({size} KB)")
        return stl_path
    else:
        print(f"[OpenSCAD] Compile error:\n{result.stderr}")
        return ""


def generate(description: str) -> str:
    """Full pipeline: text → .scad → .stl"""
    scad_code = prompt_to_scad(description)
    print(f"\n--- Generated SCAD ---\n{scad_code}\n---\n")
    return compile_scad(scad_code, description)


if __name__ == "__main__":
    import sys
    desc = " ".join(sys.argv[1:]) or "a small phone stand with 30 degree angle"
    stl = generate(desc)
    if stl:
        print(f"\nReady to slice: {stl}")
