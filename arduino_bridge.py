"""
arduino_bridge.py  –  Astra Smart Bin
======================================
Reads sensor data from the Arduino over USB serial and:
  1. Serves it via a local REST API (for the Wi-Fi monitor widget).
  2. Pushes it to Firebase Realtime Database (for the main Flutter app).

Usage
-----
  python arduino_bridge.py [--port /dev/ttyACM0] [--firebase-url https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com]

Arguments
---------
  --port          Arduino serial port  (auto-detected if omitted)
  --baudrate      Serial baud rate     (default: 9600)
  --host          Flask bind address   (default: 0.0.0.0)
  --api-port      Flask HTTP port      (default: 5000)
  --firebase-url  Firebase Realtime Database root URL
                  e.g. https://my-project-default-rtdb.firebaseio.com
                  If omitted, Firebase push is skipped.

Arduino serial protocol
------------------------
Every 3 seconds the Arduino sends:
    DATA|<plastic%>|<paper%>|<metal%>
e.g. DATA|45|72|10

The bridge accepts single-char commands to open a bin lid:
    P  → open plastic bin
    S  → open paper (stationery) bin
    M  → open metal bin

REST endpoints (local use / WifiBinMonitor widget)
---------------------------------------------------
  GET  /api/bin-status   →  {"plastic":45,"paper":72,"metal":10,"raw":"..."}
  POST /api/command      ←  {"command": "P"|"S"|"M"}
"""

import argparse
import datetime
import threading
import time
from typing import Optional

import requests
from flask import Flask, jsonify, request
import serial
from serial.tools import list_ports


app = Flask(__name__)

# Thread-safety locks
serial_lock = threading.Lock()
levels_lock = threading.Lock()

serial_conn: Optional[serial.Serial] = None
latest_levels = {"plastic": 0, "paper": 0, "metal": 0, "raw": ""}

# Firebase Realtime Database URL (set via --firebase-url argument).
_firebase_url: Optional[str] = None


# ── Serial helpers ────────────────────────────────────────────────────────────

def _find_default_port() -> Optional[str]:
    """Return the first available serial port, or None."""
    ports = list(list_ports.comports())
    return ports[0].device if ports else None


def _open_serial(port: str, baudrate: int) -> serial.Serial:
    return serial.Serial(port=port, baudrate=baudrate, timeout=1)


# ── Firebase push ─────────────────────────────────────────────────────────────

def _push_to_firebase(plastic: int, paper: int, metal: int) -> None:
    """Push the latest bin levels to Firebase Realtime Database via REST API.

    Uses a fire-and-forget approach: failures are logged but never crash
    the bridge.  Firebase REST API requires no SDK – just an HTTPS PUT.

    Firebase node written:
        bin_status/
            plastic:      <int>
            paper:        <int>
            metal:        <int>
            last_updated: <ISO-8601 string>
    """
    if not _firebase_url:
        return

    url = _firebase_url.rstrip("/") + "/bin_status.json"
    payload = {
        "plastic":      plastic,
        "paper":        paper,
        "metal":        metal,
        "last_updated": datetime.datetime.utcnow().isoformat() + "Z",
    }
    try:
        response = requests.put(url, json=payload, timeout=5)
        if response.status_code == 200:
            print(f"[Firebase] Updated → P:{plastic}% S:{paper}% M:{metal}%")
        else:
            print(f"[Firebase] HTTP {response.status_code}: {response.text[:80]}")
    except Exception as exc:
        print(f"[Firebase] Push failed: {exc}")


# ── Serial reader thread ──────────────────────────────────────────────────────

def serial_reader(port: str, baudrate: int) -> None:
    """Background thread that continuously reads lines from the Arduino.

    Reconnects automatically if the serial port is lost (e.g. USB replug).
    """
    global serial_conn

    while True:
        try:
            with serial_lock:
                if serial_conn is None or not serial_conn.is_open:
                    serial_conn = _open_serial(port, baudrate)

            line = serial_conn.readline().decode("utf-8", errors="ignore").strip()
            if not line:
                continue

            with levels_lock:
                latest_levels["raw"] = line

            # Parse the structured data packet: DATA|<plastic>|<paper>|<metal>
            if line.startswith("DATA|"):
                parts = line.split("|")
                if len(parts) >= 4:
                    try:
                        plastic = int(parts[1])
                        paper   = int(parts[2])
                        metal   = int(parts[3])
                    except ValueError:
                        continue

                    with levels_lock:
                        latest_levels["plastic"] = plastic
                        latest_levels["paper"]   = paper
                        latest_levels["metal"]   = metal

                    # Push to Firebase in a separate thread to avoid blocking
                    # the serial reader while waiting for network I/O.
                    threading.Thread(
                        target=_push_to_firebase,
                        args=(plastic, paper, metal),
                        daemon=True,
                    ).start()

        except Exception:
            with serial_lock:
                if serial_conn is not None and serial_conn.is_open:
                    serial_conn.close()
                serial_conn = None
            time.sleep(1)  # brief pause before reconnect attempt


# ── REST API ──────────────────────────────────────────────────────────────────

@app.get("/api/bin-status")
def get_bin_status():
    """Return the most recently received bin fill levels as JSON."""
    with levels_lock:
        return jsonify(dict(latest_levels))


@app.post("/api/command")
def post_command():
    """Send a one-character open command to the Arduino.

    Body (JSON):  {"command": "P" | "S" | "M"}
    P = open Plastic bin lid
    S = open Paper (Stationery) bin lid
    M = open Metal bin lid
    """
    payload = request.get_json(silent=True) or {}
    command = payload.get("command")

    if command not in {"P", "S", "M"}:
        return jsonify({"error": "Invalid command. Use one of: P, S, M"}), 400

    with serial_lock:
        if serial_conn is None or not serial_conn.is_open:
            return jsonify({"error": "Arduino serial connection is not available"}), 503
        serial_conn.write(command.encode("utf-8"))

    return jsonify({"ok": True, "command": command})


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    global _firebase_url

    parser = argparse.ArgumentParser(
        description="Arduino USB → Wi-Fi bridge with Firebase push",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--port", default=None,
        help="Arduino serial port (e.g. COM3, /dev/ttyACM0). Auto-detected if omitted.",
    )
    parser.add_argument(
        "--baudrate", type=int, default=9600,
        help="Serial baud rate (default: 9600).",
    )
    parser.add_argument(
        "--host", default="0.0.0.0",
        help="Flask bind address (default: 0.0.0.0).",
    )
    parser.add_argument(
        "--api-port", type=int, default=5000,
        help="Flask HTTP port (default: 5000).",
    )
    parser.add_argument(
        "--firebase-url", default=None,
        help=(
            "Firebase Realtime Database root URL, e.g. "
            "https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com  "
            "If omitted, Firebase push is disabled."
        ),
    )
    args = parser.parse_args()

    _firebase_url = args.firebase_url

    serial_port = args.port or _find_default_port()
    if not serial_port:
        raise SystemExit(
            "No serial ports detected. Please provide --port /dev/ttyACM0 (Linux/Mac) "
            "or --port COM3 (Windows)."
        )

    print(f"[Bridge] Connecting to Arduino on {serial_port} @ {args.baudrate} baud")
    if _firebase_url:
        print(f"[Bridge] Firebase push enabled → {_firebase_url}")
    else:
        print("[Bridge] Firebase push disabled (use --firebase-url to enable)")

    threading.Thread(
        target=serial_reader,
        args=(serial_port, args.baudrate),
        daemon=True,
    ).start()

    print(f"[Bridge] REST API listening on http://{args.host}:{args.api_port}")
    app.run(host=args.host, port=args.api_port)


if __name__ == "__main__":
    main()
