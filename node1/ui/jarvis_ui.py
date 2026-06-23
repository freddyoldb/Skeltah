"""
JARVIS OS UI — Node 1 (Portrait Monitor)
Full-screen HUD with 3 zones:
  Zone 1 (top):    Knowledge Graph (vis.js via WebEngine)
  Zone 2 (middle): Chat + SearXNG local search
  Zone 3 (bottom): Email (IMAP) + Calendar
"""

import sys
import os
import requests
import imaplib
import email
from email.header import decode_header
from datetime import datetime
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout,
    QHBoxLayout, QLineEdit, QPushButton, QLabel, QSplitter,
    QTextEdit, QScrollArea, QFrame
)
from PyQt6.QtWebEngineWidgets import QWebEngineView
from PyQt6.QtCore import Qt, QUrl, QTimer, QThread, pyqtSignal
from PyQt6.QtGui import QFont, QColor, QPalette

OLLAMA_URL = "http://192.168.178.44:11434/api/chat"
MODEL = "phi3:mini"
SEARXNG_URL = "http://localhost:8080/search"

JARVIS_STYLE = """
QMainWindow, QWidget {
    background-color: #000810;
    color: #00c8ff;
    font-family: 'Courier New', monospace;
}
QLineEdit {
    background: #001525;
    border: 1px solid #00c8ff;
    color: #00c8ff;
    padding: 6px;
    font-size: 13px;
}
QPushButton {
    background: #001f3f;
    border: 1px solid #00c8ff;
    color: #00c8ff;
    padding: 6px 12px;
    font-size: 12px;
}
QPushButton:hover { background: #003060; }
QTextEdit {
    background: #000d1a;
    border: 1px solid #004466;
    color: #00e5ff;
    font-size: 12px;
}
QLabel { color: #00c8ff; }
QSplitter::handle { background: #003355; }
"""

KNOWLEDGE_GRAPH_HTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  body { margin:0; background:#000810; }
  #graph { width:100%; height:100vh; }
</style>
<script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
</head>
<body>
<div id="graph"></div>
<script>
const nodes = new vis.DataSet([
  {id:1, label:"JARVIS OS", color:"#00c8ff", font:{color:"#fff"}},
  {id:2, label:"Brain", color:"#0066aa"},
  {id:3, label:"Node1 UI", color:"#0066aa"},
  {id:4, label:"Node2 Peripherals", color:"#0066aa"},
  {id:5, label:"Obsidian Vault", color:"#004488"},
  {id:6, label:"3D Printer", color:"#004488"},
  {id:7, label:"Smart Home", color:"#004488"},
]);
const edges = new vis.DataSet([
  {from:1,to:2},{from:1,to:3},{from:1,to:4},
  {from:3,to:5},{from:4,to:6},{from:4,to:7},
]);
const options = {
  background:{color:"#000810"},
  edges:{color:{color:"#00c8ff"},smooth:{type:"curvedCW"}},
  physics:{stabilization:false},
};
new vis.Network(document.getElementById("graph"),{nodes,edges},options);
</script>
</body>
</html>
"""


class ChatWorker(QThread):
    response_chunk = pyqtSignal(str)
    done = pyqtSignal()

    def __init__(self, message, history):
        super().__init__()
        self.message = message
        self.history = history

    def run(self):
        import json
        messages = [{"role": "system", "content": "You are J.A.R.V.I.S. Concise, sharp, sarcastic."}]
        messages += self.history
        messages.append({"role": "user", "content": self.message})
        try:
            with requests.post(OLLAMA_URL, json={"model": MODEL, "messages": messages, "stream": True},
                               stream=True, timeout=120) as r:
                for line in r.iter_lines():
                    if line:
                        chunk = json.loads(line)
                        token = chunk.get("message", {}).get("content", "")
                        if token:
                            self.response_chunk.emit(token)
                        if chunk.get("done"):
                            break
        except Exception as e:
            self.response_chunk.emit(f"\n[Error: {e}]")
        self.done.emit()


class JarvisUI(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("J.A.R.V.I.S. OS")
        self.showFullScreen()
        self.setStyleSheet(JARVIS_STYLE)
        self.chat_history = []
        self._build_ui()
        self._start_email_timer()

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setSpacing(2)
        layout.setContentsMargins(4, 4, 4, 4)

        splitter = QSplitter(Qt.Orientation.Vertical)

        # Zone 1: Knowledge Graph
        self.graph_view = QWebEngineView()
        self.graph_view.setHtml(KNOWLEDGE_GRAPH_HTML)
        self.graph_view.setMinimumHeight(300)
        splitter.addWidget(self.graph_view)

        # Zone 2: Chat
        chat_widget = QWidget()
        chat_layout = QVBoxLayout(chat_widget)
        chat_layout.setSpacing(4)

        header = QLabel("◈ J.A.R.V.I.S. INTERFACE")
        header.setFont(QFont("Courier New", 11, QFont.Weight.Bold))
        header.setAlignment(Qt.AlignmentFlag.AlignCenter)
        chat_layout.addWidget(header)

        self.chat_display = QTextEdit()
        self.chat_display.setReadOnly(True)
        self.chat_display.setMinimumHeight(200)
        chat_layout.addWidget(self.chat_display)

        input_row = QHBoxLayout()
        self.chat_input = QLineEdit()
        self.chat_input.setPlaceholderText("Speak to JARVIS...")
        self.chat_input.returnPressed.connect(self.send_message)
        send_btn = QPushButton("SEND")
        send_btn.clicked.connect(self.send_message)
        search_btn = QPushButton("SEARCH")
        search_btn.clicked.connect(self.open_search)
        input_row.addWidget(self.chat_input)
        input_row.addWidget(send_btn)
        input_row.addWidget(search_btn)
        chat_layout.addLayout(input_row)
        splitter.addWidget(chat_widget)

        # Zone 3: Email + Calendar
        bottom = QWidget()
        bottom_layout = QHBoxLayout(bottom)

        self.email_display = QTextEdit()
        self.email_display.setReadOnly(True)
        self.email_display.setMaximumHeight(150)
        self.email_display.setPlaceholderText("📧 Email ticker loading...")

        self.calendar_display = QTextEdit()
        self.calendar_display.setReadOnly(True)
        self.calendar_display.setMaximumHeight(150)
        self.calendar_display.setPlaceholderText("📅 Calendar events loading...")

        bottom_layout.addWidget(self.email_display)
        bottom_layout.addWidget(self.calendar_display)
        splitter.addWidget(bottom)

        splitter.setSizes([350, 450, 150])
        layout.addWidget(splitter)

    def send_message(self):
        text = self.chat_input.text().strip()
        if not text:
            return
        self.chat_input.clear()
        self.chat_display.append(f"\n[YOU] {text}")
        self.chat_display.append("[JARVIS] ")

        self.worker = ChatWorker(text, self.chat_history)
        self.worker.response_chunk.connect(self._append_token)
        self.worker.done.connect(lambda: self.chat_history.append(
            {"role": "assistant", "content": self._current_response}
        ))
        self._current_response = ""
        self.chat_history.append({"role": "user", "content": text})
        self.worker.start()

    def _append_token(self, token):
        self._current_response += token
        cursor = self.chat_display.textCursor()
        cursor.movePosition(cursor.MoveOperation.End)
        cursor.insertText(token)
        self.chat_display.setTextCursor(cursor)

    def open_search(self):
        query = self.chat_input.text().strip()
        if query:
            url = f"{SEARXNG_URL}?q={query}&format=html"
            self.graph_view.setUrl(QUrl(url))

    def _start_email_timer(self):
        self.email_display.setText("📧 Configure IMAP in config/cluster.yaml")
        self.calendar_display.setText(f"📅 {datetime.now().strftime('%A, %d. %B %Y')}\n\nCalendar integration coming soon.")

    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_Escape:
            self.showNormal()


def main():
    app = QApplication(sys.argv)
    win = JarvisUI()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
