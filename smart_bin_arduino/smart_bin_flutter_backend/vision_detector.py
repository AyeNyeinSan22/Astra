print("--- STEP 1: Starting Script ---")
import cv2
import numpy as np
import requests
import time
import os
import sys

# Helper function to sleep while keeping the OpenCV window responsive
def responsive_sleep(seconds):
    start_time = time.time()
    while (time.time() - start_time) < seconds:
        if cv2.waitKey(1) & 0xFF == ord('q'):
            return True # Signal to quit
    return False

print("--- STEP 2: Imports complete ---")

# Try to import tflite_runtime or tensorflow for reliable inference
try:
    print("Checking for TFLite Runtime...")
    import tflite_runtime.interpreter as tflite
    HAS_TF = True
    print("TFLite Runtime found!")
except ImportError:
    try:
        print("TFLite Runtime not found. Checking for TensorFlow...")
        import tensorflow.lite as tflite
        HAS_TF = True
        print("TensorFlow found!")
    except ImportError:
        HAS_TF = False
        print("No specialized TFLite libraries found. Falling back to OpenCV (might crash).")

# Get the directory where this script is located
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(os.path.dirname(BASE_DIR), "smart_bin_recognition", "assets")

# --- CONFIGURATION ---
MODEL_PATH = os.path.join(ASSETS_DIR, "model.tflite")
LABELS_PATH = os.path.join(ASSETS_DIR, "labels.txt")
SERVER_URL = "http://127.0.0.1:5000/open_bin"
CONFIDENCE_THRESHOLD = 0.9      # Increased from 0.6 to avoid false triggers
COOLDOWN_SECONDS = 5 
SCAN_DELAY = 0.2        # Delay between each scan (seconds)
PRE_MOTOR_DELAY = 1.0   # Delay after detection before motor moves (seconds)
REQUIRED_FRAMES = 3     # Must see the item for 3 consecutive frames to trigger

print(f"--- STEP 3: Configuration set ---")
print(f"Model Path: {MODEL_PATH}")
print(f"Labels Path: {LABELS_PATH}")

# Load Labels
try:
    with open(LABELS_PATH, "r") as f:
        labels = [line.strip() for line in f.readlines()]
    print(f"Labels loaded: {labels}")
except Exception as e:
    print(f"ERROR loading labels: {e}")
    sys.exit(1)

# Load TFLite Model
print(f"--- STEP 4: Loading Model ---")
try:
    if HAS_TF:
        print("Using TensorFlow Lite Interpreter...")
        interpreter = tflite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
    else:
        print("Using OpenCV DNN...")
        net = cv2.dnn.readNetFromTFLite(MODEL_PATH)
    print("Model loaded successfully!")
except Exception as e:
    print(f"ERROR loading model: {e}")
    sys.exit(1)

# Setup Camera
print("--- STEP 5: Initializing Camera ---")
cap = None
# Try indices 0, 1, 2
for index in [0, 1, 2]:
    print(f"Probing camera index {index}...")
    
    # Try with CAP_DSHOW first (Windows)
    test_cap = cv2.VideoCapture(index, cv2.CAP_DSHOW)
    if not test_cap.isOpened():
        # Fallback to default backend
        print(f"  CAP_DSHOW failed for index {index}, trying default backend...")
        test_cap = cv2.VideoCapture(index)
        
    if test_cap.isOpened():
        print(f"  Camera found at index {index}, testing frame read...")
        ret, frame = test_cap.read()
        if ret:
            print(f"  SUCCESS: Camera working at index {index}!")
            cap = test_cap
            break
        else:
            print(f"  FAILED: Could not read frame from index {index}.")
    else:
        print(f"  FAILED: Could not open camera at index {index}.")
    test_cap.release()

if cap is None:
    print("\n!!! CRITICAL ERROR: NO CAMERA ACCESSIBLE !!!")
    print("Please check:")
    print("1. Is another app (Zoom, Teams, Camera app) open?")
    print("2. Is your webcam plugged in?")
    print("3. Check Windows Privacy Settings -> Camera -> Allow desktop apps to access.")
    sys.exit(1)

print("--- STEP 6: Entering Main Loop ---")
print("====================================")
print("   VISION DETECTOR IS NOW ACTIVE    ")
print("====================================")
print("Opening display window... (Press 'q' to quit)")

last_trigger_time = 0
consecutive_count = 0
last_detected_label = ""

try:
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Error: Lost camera connection.")
            break

        # Prepare Image for the model (224x224, normalized to 0-1)
        if HAS_TF:
            img = cv2.resize(frame, (224, 224))
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            img = img.astype(np.float32) / 255.0
            input_data = np.expand_dims(img, axis=0)

            # Run Inference
            interpreter.set_tensor(input_details[0]['index'], input_data)
            interpreter.invoke()
            output = interpreter.get_tensor(output_details[0]['index'])
        else:
            blob = cv2.dnn.blobFromImage(frame, 1/255.0, (224, 224), (0,0,0), swapRB=True, crop=False)
            net.setInput(blob)
            output = net.forward()
        
        # Get Prediction
        idx = np.argmax(output[0])
        label = labels[idx]
        confidence = output[0][idx]

        # Print current status in console (overwrites same line)
        print(f"Status: {label:8} | Conf: {confidence:.2f} | Cooldown: {max(0, COOLDOWN_SECONDS - (time.time() - last_trigger_time)):.1f}s   ", end='\r')

        # Draw Info on Frame
        color = (0, 255, 0) if confidence > CONFIDENCE_THRESHOLD else (0, 0, 255)
        text = f"{label} ({confidence:.2f})"
        cv2.putText(frame, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)
        cv2.imshow("Smart Bin Vision", frame)

        # Trigger Bin
        current_time = time.time()
        
        # Check if we are seeing the same thing with high confidence
        if confidence > CONFIDENCE_THRESHOLD:
            if label == last_detected_label:
                consecutive_count += 1
            else:
                consecutive_count = 1
                last_detected_label = label
        else:
            consecutive_count = 0
            last_detected_label = ""

        # Only trigger if threshold is met AND we have seen it enough times AND cooldown passed
        if consecutive_count >= REQUIRED_FRAMES and (current_time - last_trigger_time) > COOLDOWN_SECONDS:
            detected = label.lower()
            if "paper" in detected or "plastic" in detected:
                print(f"\n>>> CONFIRMED {detected.upper()} ({consecutive_count} frames)! (Waiting {PRE_MOTOR_DELAY}s before opening...)")
                
                # Reset counter so it doesn't trigger again immediately
                consecutive_count = 0
                
                # Wait a bit so user can see the detection on screen
                if responsive_sleep(PRE_MOTOR_DELAY):
                    break # Quit if 'q' pressed
                
                print(f"--- Sending signal now ---")
                try:
                    response = requests.post(SERVER_URL, json={"bin": detected}, timeout=5)
                    print(f"  Server Response: {response.json().get('message')}")
                    last_trigger_time = time.time() # Update time AFTER action
                except Exception as e:
                    print(f"  Error: Connection to connector.py failed: {e}")

        # Small delay between scans while keeping window responsive
        if responsive_sleep(SCAN_DELAY):
            break

except Exception as e:
    print(f"\n\n!!! CRITICAL RUNTIME ERROR: {e}")
    import traceback
    traceback.print_exc()

finally:
    if cap:
        cap.release()
    cv2.destroyAllWindows()
    print("\n--- SCRIPT FINISHED ---")
