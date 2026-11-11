#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ArduinoJson.h>

// --- Configuration ---
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASS = "YOUR_WIFI_PASSWORD";
const char* API_URL   = "https://ooycccupvxdfpnmqeims.supabase.co/functions/v1/rfid-scan";
const char* API_KEY   = "YOUR_IOT_DEVICE_API_KEY";
const char* DEVICE_ID = "ESP32-LF-001";

// --- Pin Definitions ---
// RFID MFRC522 (SPI)
#define RST_PIN          4   // RFID RST -> GPIO 4
#define SS_PIN           5   // RFID SS  -> GPIO 5
// ESP32 default SPI: SCK=18, MOSI=23, MISO=19 (hardware default, no need to define)
// LEDs & Buzzer
#define LED_GREEN       25
#define LED_RED         26
#define BUZZER_PIN      27
// OLED SSD1306 (I2C) - Using default ESP32 I2C: SDA=21, SCL=22
#define SCREEN_WIDTH    128
#define SCREEN_HEIGHT   64

// --- Objects ---
MFRC522 mfrc522(SS_PIN, RST_PIN);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

void setupDisplay() {
    Wire.begin(21, 22); // SDA=D21, SCL=D22 — explicit para sigurado
    if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println(F("SSD1306 allocation failed"));
        for(;;);
    }
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 10);
    display.println("LabaFlow IoT");
    display.println("Booting up...");
    display.display();
}

void updateDisplay(String line1, String line2, String line3 = "") {
    display.clearDisplay();
    display.setCursor(0, 10);
    display.println(line1);
    display.setTextSize(2);
    display.println(line2);
    display.setTextSize(1);
    display.println(line3);
    display.display();
}

void triggerFeedback(bool success) {
    if (success) {
        digitalWrite(LED_GREEN, HIGH);
        tone(BUZZER_PIN, 1000, 200); // Short high beep
        delay(200);
        digitalWrite(LED_GREEN, LOW);
    } else {
        digitalWrite(LED_RED, HIGH);
        tone(BUZZER_PIN, 300, 500); // Long low error beep
        delay(500);
        digitalWrite(LED_RED, LOW);
    }
}

void setup() {
    Serial.begin(115200);
    SPI.begin(18, 19, 23, SS_PIN); // SCK=D18, MISO=D19, MOSI=D23, SS=D5
    mfrc522.PCD_Init();

    pinMode(LED_GREEN, OUTPUT);
    pinMode(LED_RED, OUTPUT);
    pinMode(BUZZER_PIN, OUTPUT);

    setupDisplay();

    // --- RFID Self-Check ---
    byte rfidVersion = mfrc522.PCD_ReadRegister(mfrc522.VersionReg);
    Serial.print("MFRC522 Version: 0x");
    Serial.println(rfidVersion, HEX);
    if (rfidVersion == 0x00 || rfidVersion == 0xFF) {
        Serial.println("ERROR: RFID not detected! Check wiring on GPIO 5 (SS) and GPIO 17 (RST).");
        updateDisplay("RFID ERROR", "Check Wiring", "SS=5 RST=17");
        // Blink red LED indefinitely to signal error
        while (true) {
            digitalWrite(LED_RED, HIGH); delay(300);
            digitalWrite(LED_RED, LOW);  delay(300);
        }
    } else {
        Serial.println("RFID OK!");
        updateDisplay("RFID OK", "v" + String(rfidVersion, HEX), "Connecting WiFi");
    }

    WiFi.begin(WIFI_SSID, WIFI_PASS);
    updateDisplay("Connecting Wi-Fi...", WIFI_SSID);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    updateDisplay("Wi-Fi Connected!", "Ready to", "Scan Laundry");
}

String getUIDString(byte *buffer, byte bufferSize) {
    String uid = "";
    for (byte i = 0; i < bufferSize; i++) {
        uid += String(buffer[i] < 0x10 ? "0" : "");
        uid += String(buffer[i], HEX);
    }
    uid.toUpperCase();
    return uid;
}

void loop() {
    // Look for new cards
    if ( ! mfrc522.PICC_IsNewCardPresent() || ! mfrc522.PICC_ReadCardSerial() ) {
        delay(50);
        return;
    }

    String tagUID = getUIDString(mfrc522.uid.uidByte, mfrc522.uid.size);
    Serial.println("Scanned UID: " + tagUID);
    updateDisplay("Processing...", tagUID, "Please wait");

    if(WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin(API_URL);
        http.addHeader("Content-Type", "application/json");
        http.addHeader("x-device-key", API_KEY);

        // Generate pseudo-unique event ID using millis and tag for idempotency
        String eventId = String(millis()) + "-" + tagUID;

        // Create JSON Payload
        StaticJsonDocument<200> doc;
        doc["device_id"] = DEVICE_ID;
        doc["tag_uid"] = tagUID;
        doc["event_id"] = eventId;

        String requestBody;
        serializeJson(doc, requestBody);

        int httpResponseCode = http.POST(requestBody);

        if(httpResponseCode > 0) {
            String responseStr = http.getString();
            StaticJsonDocument<500> responseDoc;
            deserializeJson(responseDoc, responseStr);

            bool success = responseDoc["success"];
            if (success) {
                String ref = responseDoc["order_reference"].as<String>();
                String status = responseDoc["status"].as<String>();
                updateDisplay("Success:", ref, status);
                triggerFeedback(true);
            } else {
                String msg = responseDoc["message"].as<String>();
                updateDisplay("Error:", "Failed", msg);
                triggerFeedback(false);
            }
        } else {
            updateDisplay("Network Error", String(httpResponseCode));
            triggerFeedback(false);
        }
        http.end();
    } else {
        updateDisplay("Error", "Offline", "Check Wi-Fi");
        triggerFeedback(false);
    }

    // Halt PICC to prevent multiple scans of the same tap
    mfrc522.PICC_HaltA();
    delay(2000); // Wait before allowing next scan
    updateDisplay("Ready", "Scan Next", "Laundry Bag");
}