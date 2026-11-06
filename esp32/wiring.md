# LabaFlow ESP32 Hardware Setup

## Components Required
1. ESP32 Development Board (e.g., NodeMCU-32S)
2. MFRC522 RFID Reader
3. 0.96" I2C OLED Display (SSD1306)
4. Active Buzzer
5. 2x LEDs (Green, Red) & 2x 220Ω Resistors
6. Breadboard & Jumper Wires

## Library Requirements (Arduino IDE)
Install the following via the Arduino Library Manager:
* `MFRC522` by GithubCommunity
* `Adafruit SSD1306` by Adafruit
* `Adafruit GFX Library` by Adafruit
* `ArduinoJson` by Benoit Blanchon

## Pin Mapping

### 1. MFRC522 (SPI Interface)
* **SDA (SS)** -> ESP32 GPIO 21
* **SCK** -> ESP32 GPIO 18
* **MOSI** -> ESP32 GPIO 23
* **MISO** -> ESP32 GPIO 19
* **IRQ** -> (Not Connected)
* **GND** -> ESP32 GND
* **RST** -> ESP32 GPIO 22
* **3.3V** -> ESP32 3V3

### 2. OLED Display (I2C Interface)
* **GND** -> ESP32 GND
* **VCC** -> ESP32 3V3
* **SCL** -> ESP32 GPIO 22 *(Note: Shared I2C SCL if using defaults, check board pinout, commonly GPIO 22. In the code `Wire.begin()` uses default I2C pins. Standard ESP32 I2C: SDA=21, SCL=22. Ensure conflict with RFID SS/RST is avoided. Adjusted config: RFID SS=5, RST=17 is safer if OLED uses 21/22. Let's strictly use:*
    * OLED SDA -> GPIO 21, OLED SCL -> GPIO 22.
    * **CORRECTED RFID PINS**: SS -> GPIO 5, RST -> GPIO 17, SCK -> 18, MOSI -> 23, MISO -> 19.
      *(Note: Please update `#define RST_PIN 17` and `#define SS_PIN 5` in the C++ code to avoid I2C overlap).*

### 3. Indicators
* **Green LED (+)** -> 220Ω Resistor -> ESP32 GPIO 25
* **Red LED (+)** -> 220Ω Resistor -> ESP32 GPIO 26
* **Buzzer (+)** -> ESP32 GPIO 27
* **All (-) connections** -> ESP32 GND