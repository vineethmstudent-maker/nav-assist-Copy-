/*
 * NavAssist Arduino Sensor Module
 * Reads 3 HC-SR04 ultrasonic sensors and outputs CSV data
 * Format: Left_cm,Center_cm,Right_cm
 * Baud rate: 9600
 * Update rate: ~10Hz
 * 
 * Wiring:
 * Left sensor:   TRIG=D2, ECHO=D3
 * Center sensor: TRIG=D4, ECHO=D5
 * Right sensor:  TRIG=D6, ECHO=D7
 */

const int LEFT_TRIG = 2;
const int LEFT_ECHO = 3;
const int CENTER_TRIG = 4;
const int CENTER_ECHO = 5;
const int RIGHT_TRIG = 6;
const int RIGHT_ECHO = 7;

const int MAX_DISTANCE = 400;  // Maximum reading distance in cm
const int TIMEOUT_US = 23200; // Timeout for pulseIn (400cm * 58us/cm)

void setup() {
  Serial.begin(9600);
  
  pinMode(LEFT_TRIG, OUTPUT);
  pinMode(LEFT_ECHO, INPUT);
  pinMode(CENTER_TRIG, OUTPUT);
  pinMode(CENTER_ECHO, INPUT);
  pinMode(RIGHT_TRIG, OUTPUT);
  pinMode(RIGHT_ECHO, INPUT);
  
  // Initialize trigger pins to LOW
  digitalWrite(LEFT_TRIG, LOW);
  digitalWrite(CENTER_TRIG, LOW);
  digitalWrite(RIGHT_TRIG, LOW);
  
  delay(100);  // Wait for sensors to stabilize
}

void loop() {
  // Read all three sensors
  float leftDist = readSensor(LEFT_TRIG, LEFT_ECHO);
  float centerDist = readSensor(CENTER_TRIG, CENTER_ECHO);
  float rightDist = readSensor(RIGHT_TRIG, RIGHT_ECHO);
  
  // Output as CSV: Left,Center,Right
  Serial.print(leftDist, 1);
  Serial.print(',');
  Serial.print(centerDist, 1);
  Serial.print(',');
  Serial.println(rightDist, 1);
  
  delay(100);  // ~10Hz update rate
}

float readSensor(int trigPin, int echoPin) {
  // Send 10us pulse to trigger
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  // Read echo pulse duration
  long duration = pulseIn(echoPin, HIGH, TIMEOUT_US);
  
  // Convert to distance in cm (speed of sound = 340 m/s)
  // Distance = (duration * 0.034) / 2
  float distance = duration * 0.017;
  
  // Clamp to valid range
  if (distance == 0 || distance > MAX_DISTANCE) {
    distance = MAX_DISTANCE;
  }
  
  return distance;
}
