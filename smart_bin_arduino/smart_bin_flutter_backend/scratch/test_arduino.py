import serial
import time
import serial.tools.list_ports

def find_arduino_port():
    ports = list(serial.tools.list_ports.comports())
    for p in ports:
        if "Arduino" in p.description or "USB Serial" in p.description or "CH340" in p.description:
            return p.device
    return 'COM4'

port = find_arduino_port()
print(f"Connecting to {port}...")
try:
    ser = serial.Serial(port, 9600, timeout=1)
    time.sleep(2) # Wait for Arduino reset
    
    print("Sending 'P' (Plastic bin)...")
    ser.write(b'P')
    time.sleep(2)
    
    print("Sending 'S' (Paper bin)...")
    ser.write(b'S')
    time.sleep(2)
    
    print("Test complete.")
    ser.close()
except Exception as e:
    print(f"Error: {e}")
