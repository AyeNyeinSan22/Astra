#include <Servo.h>

// --- BIN 1: PLASTIC ---
const int pTrig = 2;
const int pEcho = 4;
const int pServoPin = 3;

// --- BIN 2: PAPER ---
const int sTrig = 7;
const int sEcho = 9;
const int sServoPin = 5;

// --- BIN 3: METAL ---
const int mTrig = 8;
const int mEcho = 10;
const int mServoPin = 6;

// --- CONFIGURATION ---
const int binDepth = 30;
const int fullThreshold = 5;
const int openAngle = 90;
const int closeAngle = 0;

Servo servoPlastic;
Servo servoPaper;
Servo servoMetal;

void setup() {
  Serial.begin(9600);

  pinMode(pTrig, OUTPUT); pinMode(pEcho, INPUT);
  pinMode(sTrig, OUTPUT); pinMode(sEcho, INPUT);
  pinMode(mTrig, OUTPUT); pinMode(mEcho, INPUT);

  servoPlastic.attach(pServoPin);
  servoPaper.attach(sServoPin);
  servoMetal.attach(mServoPin);

  servoPlastic.write(closeAngle);
  servoPaper.write(closeAngle);
  servoMetal.write(closeAngle);

  Serial.println("================================");
  Serial.println("   SmartBin System Starting..  ");
  Serial.println("================================");

  delay(500);
}

void loop() {
  // 1. LISTEN: Receive commands from AI
  if (Serial.available() > 0) {
    char aiSignal = Serial.read();

    if (aiSignal == 'P') {
      Serial.println(">> AI Signal: PLASTIC detected");
      Serial.println(">> Opening Plastic bin lid...");
      openLid(servoPlastic);
      Serial.println(">> Plastic bin lid closed.");
    }
    else if (aiSignal == 'S') {
      Serial.println(">> AI Signal: PAPER detected");
      Serial.println(">> Opening Paper bin lid...");
      openLid(servoPaper);
      Serial.println(">> Paper bin lid closed.");
    }
    else if (aiSignal == 'M') {
      Serial.println(">> AI Signal: METAL detected");
      Serial.println(">> Opening Metal bin lid...");
      openLid(servoMetal);
      Serial.println(">> Metal bin lid closed.");
    }
  }

  // 2. MONITOR: Report fill levels every 3 seconds
  static unsigned long lastReportingTime = 0;
  if (millis() - lastReportingTime > 3000) {
    int plasticDist = getDistance(pTrig, pEcho);
    int paperDist   = getDistance(sTrig, sEcho);
    int metalDist   = getDistance(mTrig, mEcho);

    int plasticPercent = calculatePercent(plasticDist);
    int paperPercent   = calculatePercent(paperDist);
    int metalPercent   = calculatePercent(metalDist);

    // --- SERIAL MONITOR DISPLAY ---
    Serial.println("--------------------------------");
    Serial.print("Plastic Bin : ");
    Serial.print(plasticPercent);
    Serial.print("% ("); Serial.print(plasticDist); Serial.print("cm) ");
    Serial.println(getBar(plasticPercent));

    Serial.print("Paper Bin   : ");
    Serial.print(paperPercent);
    Serial.print("% ("); Serial.print(paperDist); Serial.print("cm) ");
    Serial.println(getBar(paperPercent));

    Serial.print("Metal Bin   : ");
    Serial.print(metalPercent);
    Serial.print("% ("); Serial.print(metalDist); Serial.print("cm) ");
    Serial.println(getBar(metalPercent));

    // Warning messages
    if (plasticPercent >= 90) Serial.println("!! WARNING: Plastic bin is FULL !!");
    if (paperPercent >= 90)   Serial.println("!! WARNING: Paper bin is FULL !!");
    if (metalPercent >= 90)   Serial.println("!! WARNING: Metal bin is FULL !!");

    Serial.println("--------------------------------");

    // Data packet for Python/database
    Serial.print("DATA|");
    Serial.print(plasticPercent);
    Serial.print("|");
    Serial.print(paperPercent);
    Serial.print("|");
    Serial.println(metalPercent);

    lastReportingTime = millis();
  }
}

// --- Visual bar graph in Serial Monitor ---
String getBar(int percent) {
  String bar = "[";
  int filled = percent / 10; // 10 blocks max
  for (int i = 0; i < 10; i++) {
    if (i < filled) bar += "#";
    else bar += "-";
  }
  bar += "]";
  return bar;
}

// --- Open and close lid ---
void openLid(Servo &targetServo) {
  targetServo.write(openAngle);
  delay(4000);
  targetServo.write(closeAngle);
  Serial.println("DONE");
}

// --- Calculate distance in cm ---
int getDistance(int trig, int echo) {
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);

  long duration = pulseIn(echo, HIGH, 25000);
  if (duration == 0) return 999; // 999 means no reading/timeout

  return duration * 0.034 / 2;
}

// --- Convert distance to percent ---
int calculatePercent(int distance) {
  if (distance > binDepth) return 0;
  int percent = map(distance, binDepth, fullThreshold, 0, 100);
  return constrain(percent, 0, 100);
}