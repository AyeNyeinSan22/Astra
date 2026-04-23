from flask import Flask, request, jsonify
from flask_cors import CORS
import serial
import serial.tools.list_ports
import time
import threading
import requests

app = Flask(__name__)
CORS(app)

# --- CONFIGURATION ---
# 1. Replace with your Firebase URL (must end with /bin_status.json)
FIREBASE_URL = "https://YOUR-PROJECT-ID.firebaseio.com/bin_status.json"

def find_arduino_port():
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        desc = p.description.lower()
        dev = p.device.lower()
        if "arduino" in desc or "usb serial" in desc or "ch340" in desc or "usbmodem" in dev or "usbserial" in dev:
            print(f"Auto-detected Arduino on port {p.device}")
            return p.device
    return None

SERIAL_PORT = find_arduino_port()
arduino = None
if SERIAL_PORT:
    try:
        arduino = serial.Serial(SERIAL_PORT, 9600, timeout=1)
        time.sleep(2)
        print(f"Connected to Arduino on {SERIAL_PORT}")
    except Exception as e:
        print(f"Serial error: {e}")

# --- BACKGROUND THREAD: READS ARDUINO -> SENDS TO FIREBASE ---
def monitor_arduino():
    while True:
        if arduino and arduino.is_open:
            try:
                line = arduino.readline().decode('utf-8', errors='ignore').strip()
                if line.startswith("DATA|"):
                    parts = line.split("|")
                    if len(parts) >= 3:
                        plastic = int(parts[1])
                        paper = int(parts[2])

                        # Data for Firebase
                        data = {"plastic": plastic, "paper": paper, "timestamp": int(time.time())}

                        # Upload to Cloud
                        try:
                            requests.put(FIREBASE_URL, json=data, timeout=2)
                            print(f"Cloud Updated: P: {plastic}% | S: {paper}%")
                        except:
                            print("Firebase upload failed (check internet)")
            except:
                pass
        time.sleep(1)

threading.Thread(target=monitor_arduino, daemon=True).start()

# --- ROUTE FOR WEBCAM (vision_detector.py) ---
@app.route('/open_bin', methods=['POST'])
def open_bin():
    data = request.get_json()
    bin_type = data.get('bin', '').lower()

    command = None
    if "plastic" in bin_type: command = b'P'
    elif "paper" in bin_type: command = b'S'

    if command and arduino and arduino.is_open:
        arduino.write(command)
        print(f"AI COMMAND: Opened {bin_type}")
        return jsonify({"message": f"Opened {bin_type}"}), 200
    return jsonify({"error": "Failed"}), 400

if __name__ == '__main__':
    # Runs on 5001 to avoid Mac AirPlay conflict
    app.run(host='0.0.0.0', port=5001)
