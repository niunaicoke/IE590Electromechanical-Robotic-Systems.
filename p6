#include <Servo.h>

int VRxPin = A3;
int VRyPin = A4;
int SWPin = 13; 
int motorPin1 = 11;
int motorPin2 = 12;
int servoPin = 5;
int potPin = A5;

int motorSpeed = 0;
int servoTilt = 90;
int lastMotorSpeed = -1;
int lastServoTilt = -1;

Servo myServo;

void setup() {
  pinMode(motorPin1, OUTPUT);
  pinMode(motorPin2, OUTPUT);
  pinMode(SWPin, INPUT_PULLUP);
  myServo.attach(servoPin);
  myServo.write(servoTilt);
  Serial.begin(9600);
}

void loop() {
  motorSpeed = map(analogRead(potPin), 0, 1023, 0, 255);
  analogWrite(motorPin1, motorSpeed);
  digitalWrite(motorPin2, LOW);
  int xPosition = analogRead(VRxPin);
  servoTilt = map(xPosition, 0, 1023, 0, 180);
  myServo.write(servoTilt);
  if (abs(motorSpeed - lastMotorSpeed) > 3) {
    Serial.print("Speed= ");
    Serial.println(motorSpeed);
    lastMotorSpeed = motorSpeed;
  }

  if (abs(servoTilt - lastServoTilt) > 2) {
    Serial.print("Tilt= ");
    Serial.println(servoTilt);
    lastServoTilt = servoTilt;
  }
  delay(100);
}
