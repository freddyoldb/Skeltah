"""
Drop-Zone-Daemon — JARVIS OS
Runs on Master. Monitors screen-edge zones for file drops.
Files dropped in left zone → Node1, right zone → Node2.
Uses PyQt6 for transparent overlay windows.
"""

import sys
import os
import subprocess
import threading
from PyQt6.QtWidgets import QApplication, QWidget, QLabel
from PyQt6.QtCore import Qt, QTimer, QPoint
from PyQt6.QtGui import QColor, QPalette, QFont

# Config
NODES = {
    "left": {
        "user": "user",
        "host": "192.168.178.121",  # Node1 (Komposter 1)
        "dest": "/home/user/incoming/"
    },
    "right": {
        "user": "benutzer",
        "host": "192.168.178.121",  # Node2 (Komposter 2) — update IP
        "dest": "/home/benutzer/incoming/"
    }
}

ZONE_WIDTH = 40   # px from screen edge
ZONE_OPACITY = 0.3


class DropZone(QWidget):
    def __init__(self, side: str, screen_geometry):
        super().__init__()
        self.side = side
        self.node = NODES[side]

        sg = screen_geometry
        if side == "left":
            self.setGeometry(sg.x(), sg.y(), ZONE_WIDTH, sg.height())
        else:
            self.setGeometry(sg.x() + sg.width() - ZONE_WIDTH, sg.y(), ZONE_WIDTH, sg.height())

        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.Tool
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setAcceptDrops(True)

        label = QLabel("◀ NODE 1" if side == "left" else "NODE 2 ▶", self)
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        label.setFont(QFont("monospace", 8))
        label.setStyleSheet("color: rgba(0, 200, 255, 180); background: transparent;")
        label.setGeometry(0, 0, ZONE_WIDTH, self.height())

        self.setStyleSheet(f"background: rgba(0, 100, 200, {int(ZONE_OPACITY * 255)});")
        self.show()

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
            self.setStyleSheet("background: rgba(0, 200, 100, 180);")

    def dragLeaveEvent(self, event):
        self.setStyleSheet(f"background: rgba(0, 100, 200, {int(ZONE_OPACITY * 255)});")

    def dropEvent(self, event):
        self.setStyleSheet(f"background: rgba(0, 100, 200, {int(ZONE_OPACITY * 255)});")
        for url in event.mimeData().urls():
            filepath = url.toLocalFile()
            if filepath:
                threading.Thread(
                    target=self.transfer_file,
                    args=(filepath,),
                    daemon=True
                ).start()

    def transfer_file(self, filepath: str):
        node = self.node
        dest = f"{node['user']}@{node['host']}:{node['dest']}"
        print(f"[DropZone] Transferring {filepath} → {dest}")

        # Ensure remote dir exists
        subprocess.run(
            ["ssh", f"{node['user']}@{node['host']}", f"mkdir -p {node['dest']}"],
            capture_output=True
        )
        # Transfer file
        result = subprocess.run(
            ["rsync", "-av", "--progress", filepath, dest],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"[DropZone] Transfer complete: {os.path.basename(filepath)}")
        else:
            print(f"[DropZone] Transfer failed: {result.stderr}")


def main():
    app = QApplication(sys.argv)
    screen = app.primaryScreen().geometry()

    zones = [
        DropZone("left", screen),
        DropZone("right", screen),
    ]

    print("[DropZone Daemon] Running. Drop files on screen edges to transfer.")
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
