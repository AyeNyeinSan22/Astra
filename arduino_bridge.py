import argparse
import threading
import time
from typing import Optional

from flask import Flask, jsonify, request
import serial
from serial.tools import list_ports


app = Flask(__name__)

serial_lock = threading.Lock()
levels_lock = threading.Lock()

serial_conn: Optional[serial.Serial] = None
latest_levels = {"plastic": 0, "paper": 0, "metal": 0, "raw": ""}


def _find_default_port() -> Optional[str]:
    ports = list(list_ports.comports())
    if not ports:
        return None
    return ports[0].device


def _open_serial(port: str, baudrate: int) -> serial.Serial:
    return serial.Serial(port=port, baudrate=baudrate, timeout=1)


def serial_reader(port: str, baudrate: int) -> None:
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

            if line.startswith("DATA|"):
                parts = line.split("|")
                if len(parts) >= 4:
                    try:
                        plastic = int(parts[1])
                        paper = int(parts[2])
                        metal = int(parts[3])
                    except ValueError:
                        continue
                    with levels_lock:
                        latest_levels["plastic"] = plastic
                        latest_levels["paper"] = paper
                        latest_levels["metal"] = metal
        except Exception:
            with serial_lock:
                if serial_conn is not None and serial_conn.is_open:
                    serial_conn.close()
                serial_conn = None
            time.sleep(1)


@app.get("/api/bin-status")
def get_bin_status():
    with levels_lock:
        return jsonify(dict(latest_levels))


@app.post("/api/command")
def post_command():
    payload = request.get_json(silent=True) or {}
    command = payload.get("command")

    if command not in {"P", "S", "M"}:
        return jsonify({"error": "Invalid command. Use one of: P, S, M"}), 400

    with serial_lock:
        if serial_conn is None or not serial_conn.is_open:
            return jsonify({"error": "Arduino serial connection is not available"}), 503
        serial_conn.write(command.encode("utf-8"))

    return jsonify({"ok": True, "command": command})


def main():
    parser = argparse.ArgumentParser(description="Arduino USB to Wi-Fi bridge")
    parser.add_argument("--port", default=None, help="Arduino serial port (e.g. COM3, /dev/ttyACM0)")
    parser.add_argument("--baudrate", type=int, default=9600, help="Serial baud rate")
    parser.add_argument("--host", default="0.0.0.0", help="Flask bind host")
    parser.add_argument("--api-port", type=int, default=5000, help="Flask API port")
    args = parser.parse_args()

    serial_port = args.port or _find_default_port()
    if not serial_port:
        raise SystemExit("No serial ports detected. Please provide --port.")

    threading.Thread(
        target=serial_reader,
        args=(serial_port, args.baudrate),
        daemon=True,
    ).start()

    app.run(host=args.host, port=args.api_port)


if __name__ == "__main__":
    main()
