"""
JARVIS Knowledge Graph Builder
Reads Obsidian Vault (Markdown files) and builds a vis.js graph.
Serves as HTML for embedding in JARVIS UI Zone 1.
"""

import os
import re
import json
from pathlib import Path

VAULT_PATH = os.path.expanduser("~/jarvis/vault")


def parse_vault(vault_path: str) -> tuple[list, list]:
    """Parse Obsidian vault into nodes and edges for vis.js."""
    nodes = []
    edges = []
    node_map = {}
    node_id = 1

    vault = Path(vault_path)
    if not vault.exists():
        return [], []

    md_files = list(vault.rglob("*.md"))

    # Create nodes
    for md_file in md_files:
        name = md_file.stem
        rel_path = str(md_file.relative_to(vault))
        folder = md_file.parent.name if md_file.parent != vault else "root"

        color_map = {
            "root": "#00c8ff",
            "Tage": "#004488",
            "Wochen": "#003366",
            "Projekte": "#006644",
            "Ideen": "#664400",
            "Gaps": "#440066",
        }
        color = color_map.get(folder, "#002244")

        nodes.append({
            "id": node_id,
            "label": name,
            "title": rel_path,
            "color": color,
            "font": {"color": "#00e5ff", "size": 11}
        })
        node_map[name] = node_id
        node_id += 1

    # Create edges from [[wikilinks]]
    edge_id = 1
    for md_file in md_files:
        source_name = md_file.stem
        try:
            content = md_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        links = re.findall(r'\[\[([^\]|#]+)(?:[|#][^\]]*)?\]\]', content)
        for link in links:
            link = link.strip()
            if link in node_map and source_name in node_map:
                edges.append({
                    "id": edge_id,
                    "from": node_map[source_name],
                    "to": node_map[link],
                    "color": {"color": "#004466", "opacity": 0.6}
                })
                edge_id += 1

    return nodes, edges


def build_graph_html(vault_path: str = VAULT_PATH) -> str:
    """Build full HTML page with vis.js knowledge graph."""
    nodes, edges = parse_vault(vault_path)

    if not nodes:
        nodes = [{"id": 1, "label": "JARVIS OS", "color": "#00c8ff",
                  "font": {"color": "#fff"}}]

    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body, html {{ margin:0; padding:0; background:#000810; overflow:hidden; }}
  #graph {{ width:100vw; height:100vh; }}
  #info {{ position:fixed; top:8px; right:8px; color:#00c8ff;
           font:11px monospace; background:rgba(0,8,16,0.8);
           padding:4px 8px; border:1px solid #004466; }}
</style>
<script src="https://unpkg.com/vis-network@9.1.9/standalone/umd/vis-network.min.js"></script>
</head>
<body>
<div id="graph"></div>
<div id="info">{len(nodes)} nodes · {len(edges)} edges</div>
<script>
const nodes = new vis.DataSet({json.dumps(nodes)});
const edges = new vis.DataSet({json.dumps(edges)});
const options = {{
  physics: {{
    stabilization: {{ iterations: 100 }},
    barnesHut: {{ gravitationalConstant: -8000, springLength: 120 }}
  }},
  edges: {{ smooth: {{ type: "curvedCW", roundness: 0.2 }} }},
  interaction: {{ hover: true, tooltipDelay: 200 }},
  nodes: {{ borderWidth: 0, size: 16 }}
}};
const network = new vis.Network(
  document.getElementById("graph"),
  {{ nodes, edges }},
  options
);
network.on("click", params => {{
  if (params.nodes.length > 0) {{
    const node = nodes.get(params.nodes[0]);
    window.parent?.postMessage({{ type:"node_click", label: node.label }}, "*");
  }}
}});
</script>
</body>
</html>"""


if __name__ == "__main__":
    html = build_graph_html()
    out = "/tmp/jarvis_graph.html"
    with open(out, "w") as f:
        f.write(html)
    print(f"Graph saved: {out}")
    print(f"Open: xdg-open {out}")
