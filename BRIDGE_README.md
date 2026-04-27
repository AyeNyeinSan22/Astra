# arduino_bridge.py – USB to Wi-Fi + Firebase Bridge

Runs on the **same PC** as the Arduino USB connection.
Reads sensor data from the Arduino and:
- Pushes it to **Firebase Realtime Database** (Flutter app reads this).
- Serves it over a local **REST API** (Wi-Fi monitor widget).

## Requirements

```bash
pip install flask pyserial requests
```

## Usage

```bash
# With Firebase push (recommended):
python arduino_bridge.py \
  --firebase-url https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com

# Local REST only (no Firebase):
python arduino_bridge.py

# Custom serial port:
python arduino_bridge.py \
  --port /dev/ttyACM0 \
  --firebase-url https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com
```

## REST Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/bin-status` | Current bin fill levels as JSON |
| `POST` | `/api/command` | Send open command to Arduino |

### POST /api/command

Body: `{"command": "P" | "S" | "M"}`

| Command | Action |
|---------|--------|
| `P` | Open plastic bin lid (4 s) |
| `S` | Open paper bin lid (4 s) |
| `M` | Open metal bin lid (4 s) |

## Firebase Data Written

Path: `bin_status/`

```json
{
  "plastic":      45,
  "paper":        72,
  "metal":        10,
  "last_updated": "2026-04-27T03:50:00.000Z"
}
```
