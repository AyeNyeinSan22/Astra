from flask import Flask, request, jsonify
from flask_cors import CORS
import serial
import time
import logging
import threading

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)

# Global storage for the latest bin levels
latest_levels = {"plastic": 0, "paper": 0}
bin_lock = threading.Lock()
serial_lock = threading.Lock()

import serial.tools.list_ports

# ==========================================
# AUTO-DETECT ARDUINO PORT
# ==========================================
def find_arduino_port():
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        # Look for "Arduino" or "CH340" or "USB Serial"
        if "Arduino" in p.description or "USB Serial" in p.description or "CH340" in p.description:
            print(f"Auto-detected Arduino on port {p.device}")
            return p.device
    return 'COM4' # Fallback to COM4

SERIAL_PORT = find_arduino_port()
BAUD_RATE = 9600
# ==========================================

try:
    arduino = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    time.sleep(2)
    logging.info(f"Connected to Arduino on {SERIAL_PORT}")
except Exception as e:
    logging.error(f"Failed to connect to Arduino on {SERIAL_PORT}: {e}")
    arduino = None


# ==========================================
# BACKGROUND THREAD: Reads Arduino serial
# continuously without stopping on errors
# ==========================================
def monitor_arduino():
    while True:
        if arduino and arduino.is_open:
            try:
                with serial_lock:
                    raw_line = arduino.readline()
                
                if not raw_line:
                    continue
                    
                line = raw_line.decode('utf-8', errors='ignore').strip()
                # Print everything so we can see what's happening
                logging.info(f"Received: {line}")

                if line.startswith("DATA|"):
                    parts = line.split("|")
                    if len(parts) >= 3:
                        plastic = int(parts[1])
                        paper   = int(parts[2])
                        with bin_lock:
                            latest_levels["plastic"] = plastic
                            latest_levels["paper"]   = paper
                        logging.info(f"Updated Levels -> Plastic: {plastic}% | Paper: {paper}%")
                else:
                    logging.info(f"Arduino Debug: {line}")

            except Exception as e:
                logging.error(f"Monitor error: {e}")
                time.sleep(1)  # Wait and retry instead of dying
                continue
        else:
            time.sleep(1)  # Wait if Arduino is disconnected


# Start monitoring thread
threading.Thread(target=monitor_arduino, daemon=True).start()


# ==========================================
# ROUTES
# ==========================================

@app.route('/')
def index():
    return "<h1>Smart Bin Connector is Running</h1><p>POST to <b>/open_bin</b> | GET <b>/get_levels</b> | GET <b>/status</b></p>"


# --- CONNECTION STATUS ---
@app.route('/status', methods=['GET'])
def status():
    return jsonify({
        "arduino_connected": arduino is not None and arduino.is_open,
        "port":              SERIAL_PORT,
        "baud_rate":         BAUD_RATE
    }), 200


# --- GET BIN LEVELS ---
@app.route('/get_levels', methods=['GET'])
def get_levels():
    with bin_lock:
        levels = dict(latest_levels)

    warnings = []
    if levels["plastic"] >= 90:
        warnings.append("Plastic bin is FULL! Please empty it.")
    elif levels["plastic"] >= 60:
        warnings.append("Plastic bin is getting full.")

    if levels["paper"] >= 90:
        warnings.append("Paper bin is FULL! Please empty it.")
    elif levels["paper"] >= 60:
        warnings.append("Paper bin is getting full.")

    levels["warnings"] = warnings
    return jsonify(levels), 200


# --- INTERNAL COMMAND HANDLER ---
def open_bin_internal(bin_name):
    bin_name = bin_name.lower()
    logging.info(f"Attempting to open bin: '{bin_name}'")

    command = None
    if "yellow" in bin_name or "plastic" in bin_name:
        command = b'P'
    elif "blue" in bin_name or "paper" in bin_name:
        command = b'S'

    if not command:
        logging.warning(f"Invalid bin name received: '{bin_name}'")
        return jsonify({"error": f"Unknown bin: {bin_name}"}), 400

    if arduino and arduino.is_open:
        try:
            with serial_lock:
                arduino.write(command)
            logging.info(f"Successfully sent command {command} to Arduino")
            return jsonify({"status": "success", "message": f"Opened {bin_name}"}), 200
        except Exception as e:
            logging.error(f"Serial write error: {e}")
            return jsonify({"error": str(e)}), 500
    else:
        logging.error("Arduino NOT connected! Returning simulated success.")
        return jsonify({"status": "simulated", "message": "Arduino not connected"}), 200


# --- QUICK TEST ROUTES ---
@app.route('/test_plastic')
def test_p():
    return open_bin_internal("plastic")

@app.route('/test_paper')
def test_s():
    return open_bin_internal("paper")


# --- OPEN BIN ---
@app.route('/open_bin', methods=['POST'])
def open_bin():
    data = request.get_json()
    if not data or 'bin' not in data:
        return jsonify({"error": "Missing 'bin'"}), 400
    
    return open_bin_internal(data['bin'])


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)