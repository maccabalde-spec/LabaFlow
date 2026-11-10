/**
 * LabaFlow ESP32 Firmware v3.0
 * 
 * BEHAVIOR:
 *   - Scan RFID card → buzzer beep + LED feedback
 *   - POST to Supabase rfid-scan edge function
 *   - On SUCCESS: Green LED double beep
 *   - On ERROR:   Red LED long beep
 *   - Status changes reflected on website customer dashboard
 * 
 * WIRING:
 *   RFID SDA  → D5    RFID SCK   → D18
 *   RFID MOSI → D23   RFID MISO  → D19
 *   RFID RST  → D4    RFID 3.3V  → 3V3 rail
 *   Green LED → D32   Yellow LED → D33
 *   Red LED   → D25   Buzzer     → D12
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <ArduinoJson.h>

// =============================================
// CONFIGURATION
// =============================================
const char* WIFI_SSID    = "Macoyshit";
const char* WIFI_PASS    = "tintinganda";
const char* SUPABASE_URL = "https://sesiygonrbthnwjlpggf.supabase.co";
const char* API_KEY      = "labaflow-iot-esp32-key-001";
const char* DEVICE_ID    = "ESP32-LF-001";

// =============================================
// PIN DEFINITIONS
// =============================================
#define RST_PIN     4   // D4
#define SS_PIN      5   // D5
#define LED_GREEN  32   // D32
#define LED_YELLOW 33   // D33
#define LED_RED    25   // D25
#define BUZZER_PIN 12   // D12

MFRC522 rfid(SS_PIN, RST_PIN);

// =============================================
// LED + BUZZER FEEDBACK
// =============================================
void beepScan() {
  // Single short beep when card is detected
  digitalWrite(LED_YELLOW, HIGH);
  tone(BUZZER_PIN, 800, 100);
  delay(150);
  digitalWrite(LED_YELLOW, LOW);
}

void beepSuccess(String status) {
  if (status == "Ready for Pick-up" || status == "READY") {
    // Triple loud beep for READY
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_GREEN, HIGH);
      tone(BUZZER_PIN, 1500, 200);
      delay(300);
      digitalWrite(LED_GREEN, LOW);
      delay(100);
    }
  } else if (status == "ASSIGNED") {
    // 1 long + 1 short for new assignment
    digitalWrite(LED_GREEN, HIGH);
    tone(BUZZER_PIN, 1000, 400);
    delay(500);
    digitalWrite(LED_GREEN, LOW);
    delay(100);
    digitalWrite(LED_YELLOW, HIGH);
    tone(BUZZER_PIN, 1400, 150);
    delay(200);
    digitalWrite(LED_YELLOW, LOW);
  } else {
    // Double beep for other successful stage changes
    for (int i = 0; i < 2; i++) {
      digitalWrite(LED_GREEN, HIGH);
      tone(BUZZER_PIN, 1200, 150);
      delay(200);
      digitalWrite(LED_GREEN, LOW);
      delay(100);
    }
  }
}

void beepError() {
  digitalWrite(LED_RED, HIGH);
  tone(BUZZER_PIN, 300, 600);
  delay(700);
  digitalWrite(LED_RED, LOW);
}

void beepWifi() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_YELLOW, HIGH); delay(100);
    digitalWrite(LED_YELLOW, LOW);  delay(100);
  }
}

// =============================================
// HELPERS
// =============================================
String uidToString(byte *buf, byte size) {
  String s = "";
  for (byte i = 0; i < size; i++) {
    if (buf[i] < 0x10) s += "0";
    s += String(buf[i], HEX);
  }
  s.toUpperCase();
  return s;
}

// =============================================
// SETUP
// =============================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=============================");
  Serial.println("  LabaFlow ESP32 v3.0");
  Serial.println("=============================");

  pinMode(LED_GREEN,  OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);
  pinMode(LED_RED,    OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Init RFID
  SPI.begin(18, 19, 23, SS_PIN);
  rfid.PCD_Init();
  delay(100);

  byte ver = rfid.PCD_ReadRegister(rfid.VersionReg);
  Serial.print("RFID Version: 0x");
  Serial.println(ver, HEX);

  if (ver == 0x91 || ver == 0x92) {
    rfid.PCD_SetAntennaGain(rfid.RxGain_max);
    Serial.println("RFID: OK");
  } else {
    Serial.println("RFID: ERROR — check wiring!");
    while (true) {
      digitalWrite(LED_RED, HIGH); delay(300);
      digitalWrite(LED_RED, LOW);  delay(300);
    }
  }

  // Connect WiFi
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    beepWifi();
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi: OK — IP: " + WiFi.localIP().toString());
    // Success startup beep
    for (int i = 0; i < 2; i++) {
      digitalWrite(LED_GREEN, HIGH); delay(100);
      digitalWrite(LED_GREEN, LOW);  delay(100);
    }
  } else {
    Serial.println("\nWiFi: FAILED — running offline");
    beepError();
  }

  Serial.println("-----------------------------");
  Serial.println("Ready. Tap RFID card to scan.");
  Serial.println("=============================");
}

// =============================================
// LOOP
// =============================================
void loop() {
  // Wait for card
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) {
    delay(50);
    return;
  }

  // Card detected
  String tagUID = uidToString(rfid.uid.uidByte, rfid.uid.size);
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();

  Serial.println("\n--- Card Detected ---");
  Serial.println("UID: " + tagUID);

  // Immediate beep feedback on scan
  beepScan();

  // Check WiFi
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("ERROR: No WiFi connection");
    beepError();
    delay(2000);
    return;
  }

  // Build request
  String eventId = String(millis()) + "-" + tagUID;
  StaticJsonDocument<256> reqDoc;
  reqDoc["device_id"] = DEVICE_ID;
  reqDoc["tag_uid"]   = tagUID;
  reqDoc["event_id"]  = eventId;
  String reqBody;
  serializeJson(reqDoc, reqBody);

  Serial.println("Sending to Supabase...");

  // POST to Supabase
  HTTPClient http;
  http.begin(String(SUPABASE_URL) + "/functions/v1/rfid-scan");
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-device-key", API_KEY);
  http.setTimeout(10000);

  int httpCode = http.POST(reqBody);
  String responseStr = http.getString();
  http.end();

  Serial.print("HTTP: "); Serial.println(httpCode);
  Serial.println("Response: " + responseStr);

  if (httpCode == 200) {
    StaticJsonDocument<512> resDoc;
    DeserializationError err = deserializeJson(resDoc, responseStr);

    if (err) {
      Serial.println("ERROR: JSON parse failed");
      beepError();
    } else {
      bool success = resDoc["success"].as<bool>();

      if (success) {
        String action   = resDoc["action"].as<String>();
        String status   = resDoc["status"].as<String>();
        String orderRef = resDoc["order_reference"].as<String>();
        String message  = resDoc["message"].as<String>();

        Serial.println("SUCCESS!");
        Serial.println("Action:  " + action);
        Serial.println("Order:   " + orderRef);
        Serial.println("Status:  " + status);
        Serial.println("Message: " + message);

        if (action == "ASSIGNED") {
          String customer = resDoc["customer_name"].as<String>();
          Serial.println("Customer: " + customer);
          Serial.println(">>> TAG ASSIGNED to " + orderRef + " (" + customer + ")");
          beepSuccess("ASSIGNED");
        } else {
          Serial.println(">>> STATUS ADVANCED to: " + status);
          beepSuccess(status);
        }

        // Customer is automatically notified via Supabase Realtime on the website

      } else {
        String code = resDoc["code"].as<String>();
        String msg  = resDoc["message"].as<String>();
        Serial.println("FAILED: " + code + " — " + msg);

        if (code == "DUPLICATE_TAG") {
          Serial.println(">>> ERROR: Tag already assigned to another order!");
          Serial.println(">>> Use a DIFFERENT physical tag for this customer.");
          // Fast triple red blink for duplicate error
          for (int i = 0; i < 3; i++) {
            digitalWrite(LED_RED, HIGH); delay(150);
            digitalWrite(LED_RED, LOW);  delay(150);
          }
        } else if (code == "NO_PENDING_ORDER") {
          Serial.println(">>> No pending orders. Customer must book first.");
          beepError();
        } else {
          beepError();
        }
      }
    }

  } else if (httpCode == 401) {
    Serial.println("ERROR 401: Unauthorized — check API_KEY in Supabase secrets");
    beepError();
  } else if (httpCode < 0) {
    Serial.println("ERROR: Connection failed (" + String(httpCode) + ")");
    beepError();
  } else {
    Serial.println("ERROR: HTTP " + String(httpCode));
    beepError();
  }

  // Wait before allowing next scan
  delay(2000);
  Serial.println("Ready. Tap RFID card to scan.");
}
