import requests
import time
import random

# PASTE YOUR FIREBASE URL HERE
FIREBASE_URL = "YOUR_FIREBASE_URL_HERE"

def simulate():
    if "YOUR_FIREBASE_URL" in FIREBASE_URL:
        print("Error: Please paste your Firebase URL in the script first!")
        return

    print("Starting Simulation... Check your Flutter app!")

    while True:
        # Generate random percentages to simulate trash being added
        plastic = random.randint(10, 90)
        paper = random.randint(10, 90)

        data = {
            "plastic": plastic,
            "paper": paper,
            "timestamp": int(time.time())
        }

        try:
            # We add .json to the end of the URL for the REST API
            requests.put(FIREBASE_URL, json=data)
            print(f"Simulated Upload: Plastic {plastic}% | Paper {paper}%")
        except Exception as e:
            print(f"Upload failed: {e}")

        time.sleep(3) # Update every 3 seconds

if __name__ == "__main__":
    simulate()
