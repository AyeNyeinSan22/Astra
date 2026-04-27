"""
simulate_firebase.py  –  Astra Smart Bin
=========================================
Simulates the Arduino bridge by pushing random bin-fill percentages to
Firebase Realtime Database every 3 seconds.

Useful for testing the Flutter app without physical hardware.

Usage
-----
  python simulate_firebase.py --firebase-url https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com

Arguments
---------
  --firebase-url   Firebase Realtime Database root URL  (required)
  --interval       Seconds between updates              (default: 3)
"""

import argparse
import datetime
import random
import time

import requests


def main():
    parser = argparse.ArgumentParser(
        description="Simulate Arduino bin-level data in Firebase"
    )
    parser.add_argument(
        "--firebase-url", required=True,
        help="Firebase Realtime Database root URL, e.g. https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com",
    )
    parser.add_argument(
        "--interval", type=float, default=3.0,
        help="Seconds between updates (default: 3)",
    )
    args = parser.parse_args()

    url = args.firebase_url.rstrip("/") + "/bin_status.json"
    print(f"Simulating bin levels → {url}")
    print("Press Ctrl+C to stop.\n")

    try:
        while True:
            plastic = random.randint(5, 95)
            paper   = random.randint(5, 95)
            metal   = random.randint(5, 95)
            payload = {
                "plastic":      plastic,
                "paper":        paper,
                "metal":        metal,
                "last_updated": datetime.datetime.utcnow().isoformat() + "Z",
            }
            try:
                r = requests.put(url, json=payload, timeout=5)
                if r.status_code == 200:
                    print(
                        f"  Pushed → Plastic:{plastic}%  Paper:{paper}%  Metal:{metal}%"
                    )
                else:
                    print(f"  Firebase HTTP {r.status_code}: {r.text[:80]}")
            except Exception as exc:
                print(f"  Error: {exc}")
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nSimulation stopped.")


if __name__ == "__main__":
    main()
