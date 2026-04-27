"""
vision_detector.py  –  Astra Smart Bin
=======================================
PC-side webcam detector that identifies trash type in real time and tells
the Arduino bridge to open the correct bin lid.

How it works:
  1. Captures frames from the webcam.
  2. Runs TFLite inference on each frame (MobileNetV2 model).
  3. When the same class is detected with high confidence for N consecutive
     frames, sends a POST request to the Arduino bridge:
         POST http://localhost:5000/api/command  {"command": "P"|"S"|"M"}
     The bridge then relays the single-char command to the Arduino via serial.

Usage
-----
  python vision_detector.py [options]

  --model        Path to model.tflite
                 (default: ../smart_bin_flutter_backend/exports/model.tflite)
  --labels       Path to labels.txt
                 (default: ../smart_bin_flutter_backend/exports/labels.txt)
  --bridge-url   Arduino bridge base URL
                 (default: http://127.0.0.1:5000)
  --confidence   Minimum confidence to trigger (default: 0.9)
  --frames       Consecutive frames required before triggering (default: 3)
  --cooldown     Seconds between triggers (default: 5)
"""

import argparse
import os
import sys
import time

import cv2
import numpy as np
import requests


# ── TFLite backend ──────────────────────────────────────────────────────────

def _load_tflite():
    """Return a tflite module (tflite_runtime preferred, tensorflow fallback)."""
    try:
        import tflite_runtime.interpreter as tflite
        print("[Vision] Using tflite_runtime")
        return tflite, True
    except ImportError:
        pass
    try:
        import tensorflow.lite as tflite
        print("[Vision] Using tensorflow.lite")
        return tflite, True
    except ImportError:
        print("[Vision] No TFLite library found – falling back to OpenCV DNN.")
        return None, False


# ── Helpers ──────────────────────────────────────────────────────────────────

def _responsive_sleep(seconds: float) -> bool:
    """Sleep while keeping the OpenCV window responsive.
    Returns True if the user pressed 'q' (quit)."""
    start = time.time()
    while (time.time() - start) < seconds:
        if cv2.waitKey(1) & 0xFF == ord('q'):
            return True
    return False


def _label_to_command(label: str) -> str | None:
    """Map a detected class label to the Arduino command character."""
    label = label.lower()
    if "plastic" in label:
        return "P"
    if "paper" in label:
        return "S"
    if "metal" in label:
        return "M"
    return None


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    # Default model/label paths relative to this script's directory.
    _here = os.path.dirname(os.path.abspath(__file__))
    _default_exports = os.path.join(
        _here, "..", "smart_bin_flutter_backend", "exports"
    )

    parser = argparse.ArgumentParser(
        description="PC webcam trash detector for Astra Smart Bin",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--model",
        default=os.path.join(_default_exports, "model.tflite"),
        help="Path to model.tflite (default: ../smart_bin_flutter_backend/exports/model.tflite)",
    )
    parser.add_argument(
        "--labels",
        default=os.path.join(_default_exports, "labels.txt"),
        help="Path to labels.txt (default: ../smart_bin_flutter_backend/exports/labels.txt)",
    )
    parser.add_argument(
        "--bridge-url",
        default="http://127.0.0.1:5000",
        help="Arduino bridge base URL (default: http://127.0.0.1:5000)",
    )
    parser.add_argument(
        "--confidence", type=float, default=0.9,
        help="Minimum confidence threshold to trigger (default: 0.9)",
    )
    parser.add_argument(
        "--frames", type=int, default=3,
        help="Consecutive frames required before triggering (default: 3)",
    )
    parser.add_argument(
        "--cooldown", type=float, default=5.0,
        help="Seconds between triggers (default: 5)",
    )
    args = parser.parse_args()

    command_url = args.bridge_url.rstrip("/") + "/api/command"

    # Load labels
    try:
        with open(args.labels) as f:
            labels = [line.strip() for line in f if line.strip()]
        print(f"[Vision] Labels: {labels}")
    except FileNotFoundError:
        sys.exit(f"[Vision] ERROR: labels file not found at {args.labels}")

    # Load model
    tflite, has_tf = _load_tflite()
    interpreter = net = None
    try:
        if has_tf:
            interpreter = tflite.Interpreter(model_path=args.model)
            interpreter.allocate_tensors()
            input_details  = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            print("[Vision] TFLite model loaded.")
        else:
            net = cv2.dnn.readNetFromTFLite(args.model)
            print("[Vision] OpenCV DNN model loaded.")
    except Exception as e:
        sys.exit(f"[Vision] ERROR loading model: {e}")

    # Open camera
    cap = None
    for idx in range(3):
        test = cv2.VideoCapture(idx, cv2.CAP_DSHOW)
        if not test.isOpened():
            test = cv2.VideoCapture(idx)
        if test.isOpened():
            ret, _ = test.read()
            if ret:
                print(f"[Vision] Camera found at index {idx}")
                cap = test
                break
        test.release()
    if cap is None:
        sys.exit("[Vision] ERROR: No accessible camera found.")

    print("[Vision] Starting detection loop. Press 'q' to quit.")
    last_trigger   = 0.0
    consec_count   = 0
    last_label     = ""
    scan_delay     = 0.2  # seconds between inference calls

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("[Vision] Lost camera connection.")
                break

            # Prepare input
            if has_tf:
                img = cv2.resize(frame, (224, 224))
                img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                img = img.astype(np.float32) / 255.0
                inp = np.expand_dims(img, axis=0)
                interpreter.set_tensor(input_details[0]["index"], inp)
                interpreter.invoke()
                output = interpreter.get_tensor(output_details[0]["index"])
            else:
                blob = cv2.dnn.blobFromImage(
                    frame, 1 / 255.0, (224, 224), (0, 0, 0), swapRB=True, crop=False
                )
                net.setInput(blob)
                output = net.forward()

            idx_max    = int(np.argmax(output[0]))
            label      = labels[idx_max]
            confidence = float(output[0][idx_max])

            # Overlay on frame
            color = (0, 255, 0) if confidence >= args.confidence else (0, 0, 255)
            cv2.putText(
                frame, f"{label} {confidence:.2f}",
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2,
            )
            cv2.imshow("Astra Vision Detector  (press q to quit)", frame)

            # Consecutive-frame logic
            cooldown_left = max(0.0, args.cooldown - (time.time() - last_trigger))
            print(
                f"[Vision] {label:8s} | conf: {confidence:.2f} | "
                f"streak: {consec_count} | cooldown: {cooldown_left:.1f}s   ",
                end="\r",
            )

            if confidence >= args.confidence:
                if label == last_label:
                    consec_count += 1
                else:
                    consec_count  = 1
                    last_label    = label
            else:
                consec_count = 0
                last_label   = ""

            now = time.time()
            if (
                consec_count >= args.frames
                and (now - last_trigger) > args.cooldown
            ):
                command = _label_to_command(label)
                if command:
                    print(
                        f"\n[Vision] Confirmed {label.upper()} "
                        f"({consec_count} frames) – sending command '{command}'"
                    )
                    consec_count = 0
                    if _responsive_sleep(1.0):
                        break
                    try:
                        r = requests.post(
                            command_url,
                            json={"command": command},
                            timeout=5,
                        )
                        print(f"[Vision] Bridge response: {r.json()}")
                    except Exception as exc:
                        print(f"[Vision] Bridge error: {exc}")
                    last_trigger = time.time()

            if _responsive_sleep(scan_delay):
                break

    except KeyboardInterrupt:
        pass
    finally:
        cap.release()
        cv2.destroyAllWindows()
        print("\n[Vision] Stopped.")


if __name__ == "__main__":
    main()
