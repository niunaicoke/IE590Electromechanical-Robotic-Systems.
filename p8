from telemetrix import telemetrix
import time
import pywhatkit as pwk

# Constants for temperature thresholds
TEMP_HIGH = 23  # Temperature considered too high (in degrees Celsius)

RGB_LED_RED_PIN = 6
RGB_LED_GREEN_PIN = 3
RGB_LED_BLUE_PIN = 5
DHT_SENSOR_PIN = 2  # This pin will be used for DHT data signal
DC_MOTOR_PIN = 13



temp=0




def the_callback(data):
    global temp
    if data[1]:
        # error message
        date = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(data[4]))
        print(f'DHT Error Report: Pin: {data[2]} DHT Type: {data[3]} Error: {data[1]} Time: {date}')
    else:
        # valid data
        temp = data[5]  # Update the global temperature variable
        humidity = data[4]
        date = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(data[6]))
        print(f'DHT Valid Data Report: Pin: {data[2]} DHT Type: {data[3]} Humidity: {humidity} Temperature: {temp} Time: {date}')




def dht(board, DHT_SENSOR_PIN, callback, dht_type):
    # noinspection GrazieInspection
    """
        Set the pin mode for a DHT 22 device. Results will appear via the
        callback.

        :param my_board: an telemetrix instance
        :param pin: Arduino pin number
        :param callback: The callback function
        :param dht_type: 22 or 11
        """

    # set the pin mode for the DHT device
    board.set_pin_mode_dht(DHT_SENSOR_PIN, callback, dht_type)








board = telemetrix.Telemetrix()

board.set_pin_mode_digital_output(RGB_LED_RED_PIN)
board.set_pin_mode_digital_output(RGB_LED_GREEN_PIN)
board.set_pin_mode_digital_output(RGB_LED_BLUE_PIN)

# Set up the DC Motor pin as a digital output
board.set_pin_mode_digital_output(DC_MOTOR_PIN)

# Define a function to send a WhatsApp message (this is a placeholder)
def send_whatsapp_message():
    # You will need to use an API like Twilio to send WhatsApp messages.
    # Replace this placeholder function with the actual code to send a message.
    pwk.sendwhatmsg_instantly("+16263622884", "Whatsapp message will be sent to the responsible of the machine.", 10, tab_close=True)
    print("WhatsApp message sent to the responsible of the machine.")

# Define a function to update the RGB LED color
def set_rgb_led_color(red, green, blue):
    # Set the RGB LED color
    board.digital_write(RGB_LED_RED_PIN, red)
    board.digital_write(RGB_LED_GREEN_PIN, green)
    board.digital_write(RGB_LED_BLUE_PIN, blue)

# Define a function to control the DC motor
def set_dc_motor(state):
    # Set the DC motor state (ON/OFF)
    board.digital_write(DC_MOTOR_PIN, state)

try:
    dht(board, DHT_SENSOR_PIN, the_callback, 11)  
    while True:
        print(temp)
        if temp is not None:
            # Check if the temperature is too high
            if temp >= TEMP_HIGH:
                set_rgb_led_color(255, 0, 0)  # RED
                set_dc_motor(1)  # Turn on the DC motor
                send_whatsapp_message()  # Send a WhatsApp message
            else:
                set_rgb_led_color(0, 255, 0)  # GREEN
                set_dc_motor(0)  # Turn off the DC motor

        time.sleep(1)  # Wait for a second before checking the temperature again

except KeyboardInterrupt:
    # Turn off the RGB LED and DC motor before closing the program
    set_rgb_led_color(0, 0, 0)
    set_dc_motor(0)

    # Close the Telemetrix connection
    board.shutdown()

