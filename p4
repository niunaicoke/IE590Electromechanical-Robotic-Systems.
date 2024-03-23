#include <DHT.h>
#include <NewPing.h>

// temperature thres
const float TEMP_MIN = 20.0; 
const float TEMP_MAX = 22.0; 
const float HUM_MIN = 40.0;  
const float HUM_MAX = 60.0;  
const int LIGHT_MIN = 200;   
const int LIGHT_MAX = 500;   

//flag
unsigned int lastDistance = 0;
bool alarmState = false;
bool manualColorSet = false;

// Pin 
const int LIGHT_SENSOR_PIN = A5;
const int DHT_SENSOR_PIN = 4;
const int BUZZER_PIN = 3;
const int BUTTON_PIN = 5;
const int ULTRASONIC_ECHO_PIN = 8;
const int ULTRASONIC_TRIG_PIN = 7;
const int RGB_LED_RED_PIN = 11;
const int RGB_LED_BLUE_PIN = 9;
const int RGB_LED_GREEN_PIN = 10;
const int alarm_led_PIN = 2;



String last_humidity_State = "";
String last_temp_State = "";
String last_light_State = "";



int mal_temp;
float temperature;


// Initialize DHT sensor
DHT dht(DHT_SENSOR_PIN, DHT11); // Change DHT11 to whatever DHT type you're using

// Initialize ultrasonic sensor
NewPing sonar(ULTRASONIC_TRIG_PIN, ULTRASONIC_ECHO_PIN, 200); // 200 cm max distance

void setup() {
  // Start the serial communication
  Serial.begin(9600);
  
  // Set pin modes for the RGB LED
  pinMode(RGB_LED_RED_PIN, OUTPUT);
  pinMode(RGB_LED_BLUE_PIN, OUTPUT);
  pinMode(RGB_LED_GREEN_PIN, OUTPUT);

  // Set pin modes for the buzzer and button
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP); // Using internal pull-up resistor

  // Initialize the DHT sensor
  dht.begin();

  pinMode(alarm_led_PIN, OUTPUT);

  Serial.println("Change temp manually with temp input:");
}

void loop() {
  if (alarmState==true) {
    unsigned long buzzerStartTime = millis();
    while (millis() - buzzerStartTime < 10) { // Buzz for 10 milliseconds
      digitalWrite(BUZZER_PIN, HIGH);
      delayMicroseconds(500); // This is half the period for a 1000 Hz tone
      digitalWrite(BUZZER_PIN, LOW);
      delayMicroseconds(500); // This is half the period for a 1000 Hz tone
      digitalWrite(alarm_led_PIN,HIGH);

        // Check if button is pressed
      if (digitalRead(BUTTON_PIN) == LOW) {
        alarmState = false;
        digitalWrite(alarm_led_PIN,LOW);
        digitalWrite(BUZZER_PIN, LOW); // Also turn off the buzzer immediately
        break; // Exit the while loop immediately
      }
    }
    delay(10);
  }






  if (alarmState==false) {
    // Read the light level
    int lightLevel = analogRead(LIGHT_SENSOR_PIN);

    // Read the temperature and humidity from the DHT sensor
    float humidity = dht.readHumidity();
    temperature = dht.readTemperature(); // Read temperature as Celsius (the default)

    // Check if any reads failed and exit early (to try again).
    if (isnan(humidity) || isnan(temperature)) {
      Serial.println("Failed to read from DHT sensor!");
      return;
    }

    // Check the temperature and humidity against the constants and print the state
    if (manualColorSet==false){
      checkTemperature(temperature);
    }
    checkHumidity(humidity);
    checkLightLevel(lightLevel);

    // Check for ultrasonic sensor changes
    checkUltrasonicSensor();
  
    // Small delay to avoid spamming the serial output
    delay(100);
  }
  delay(100);
  setMalTempFromSerial();
}

void checkTemperature(float temperature) {
  if (temperature < TEMP_MIN) {
    setRGBColor(255, 0, 0); // Red
    if (last_temp_State != "Heating") {
      Serial.println("Heating");
      last_temp_State = "Heating";
    }
  } 
  else if (temperature > TEMP_MAX){
    setRGBColor(0, 0, 255); // Blue
    if (last_temp_State != "Cooling") {
      Serial.println("Cooling");
      last_temp_State = "Cooling";
    }
  }
}

void checkHumidity(float humidity) {
  if (humidity < HUM_MIN) {
    if (last_humidity_State != "Watering") {
      Serial.println("Watering");
      last_humidity_State = "Watering";
    }
  } else if (humidity > HUM_MAX) {
    if (last_humidity_State != "Drying") {
      Serial.println("Drying");
      last_humidity_State = "Drying";
    }
  }
}

void checkLightLevel(int lightLevel) {
  if (lightLevel < LIGHT_MIN) {
    if (last_light_State != "turn on light") {
      Serial.println("turn on light");
      last_light_State = "turn on light";
    }
  } else if (lightLevel > LIGHT_MAX) {
    if (last_light_State != "Blocking light") {
      Serial.println("Blocking light");
      last_light_State = "Blocking light";
    }
  }
}

/**void checkUltrasonicSensor() {
  unsigned int distance = sonar.ping_cm();
  if (distance != lastDistance && distance-lastDistance>1000) {
    Serial.println("Alarm triggered!");
    alarmState=true;
  }
  else{
    alarmState=false;
  }
  lastDistance = distance;
}**/

void checkUltrasonicSensor() {
  const int NUM_READINGS = 5; // Number of readings to take for the average
  const int MAX_CHANGE = 100000; // Maximum allowed change in distance
  unsigned int total = 0; // Total of the readings
  
  // Take NUM_READINGS readings and add them to total
  for (int i = 0; i < NUM_READINGS; i++) {
    total += sonar.ping_cm();
    delay(10); // Small delay between readings
  }
  
  // Calculate the average of the readings
  unsigned int distance = total / NUM_READINGS;
  
  // Check if the distance has changed more than MAX_CHANGE
  if (abs(distance - lastDistance) > MAX_CHANGE) {
    Serial.println("Alarm triggered!");
    alarmState = true;
  } else {
    alarmState = false;
  }
  
  // Update lastDistance
  lastDistance = distance;
}





void setRGBColor(int redValue, int greenValue, int blueValue) {
  analogWrite(RGB_LED_RED_PIN, redValue);
  analogWrite(RGB_LED_GREEN_PIN, greenValue);
  analogWrite(RGB_LED_BLUE_PIN, blueValue);
}



void setMalTempFromSerial() {
  if (Serial.available() > 0) {
    // Read the number from the serial input
    mal_temp = Serial.parseInt(); // This will read the first valid integer from the serial buffer
    // Clear the serial buffer to prevent reading stale data next time
    while (Serial.available() > 0) {
      Serial.read();
    }

    manualColorSet=true;

    // Print the received temperature to the serial monitor
    Serial.print("Set temperature manually to: ");
    Serial.println(mal_temp);


    // temp_system_change
    if (temperature < mal_temp) {
      setRGBColor(255, 0, 0); // Red
      if (last_temp_State != "Heating") {
        Serial.println("Heating");
        last_temp_State = "Heating";
      }
    } 
    else if (temperature > mal_temp){
      setRGBColor(0, 0, 255); // Blue
      if (last_temp_State != "Cooling") {
        Serial.println("Cooling");
        last_temp_State = "Cooling";
      }
    }
  }
}
