/**
 * LabaFlow ESP32 Firmware v4.0
 *
 * LED SEQUENCE:
 *   1. Card detected   → Yellow ON (processing...)
 *   2. Sending to API  → Yellow blink
 *   3. SUCCESS         → Yellow OFF → Green flash + beep
 *   4. ERROR/DUPLICATE → Yellow OFF → Red flash + long beep
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
#define RST_PIN     4
#define SS_PIN      5
#define LED_GREEN  32
#define LED_YELLOW 33
#define LED_RED    25
#define BUZZER_PIN 12

MFRC522 rfid(SS_PIN, RST_PIN);

// =============================================
// LED HELPERS
// =============================================
void allLedsOff() {
  digitalWrite(LED_GREEN,  LOW);
  digitalWrite(LED_YELLOW, LOW);
  digitalWrite(LED_RED,    LOW);
}

// Step 1: Yellow ON → card detected, processing
void ledProcessing() {
  allLedsOff();
  digitalWrite(LED_YELLOW, HIGH);
}

// Step 2: Yellow blink → waiting for API response
void ledWaiting() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_YELLOW, HIGH); delay(150);
    digitalWrite(LED_YELLOW, LOW);  delay(150);
  }
}

// Step 3a: Green flash + beep → SUCCESS
void ledSuccess(String status) {
  allLedsOff();
  if (status == "Ready for Pick-up") {
    // Triple green flash for READY — most important event
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_GREEN, HIGH);
      tone(BUZZER_PIN, 1500, 200);
      delay(300);
      digitalWrite(LED_GREEN, LOW);
      delay(100);
    }
  } else if (status == "ASSIGNED") {
    // 1 long green + 1 short yellow = new assignment confirmed
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
    // Double green flash = stage advanced
    for (int i = 0; i < 2; i++) {
      digitalWrite(LED_GREEN, HIGH);
      tone(BUZZER_PIN, 1200, 150);
      delay(200);
      digitalWrite(LED_GREEN, LOW);
      delay(100);
    }
  }
}

// Step 3b: Red flash + long beep → ERROR or DUPLICATE
void ledError(bool isDuplicate) {
  allLedsOff();
  if (isDuplicate) {
    // Fast triple red blink = DUPLICATE tag warning
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_RED, HIGH); delay(150);
      digitalWrite(LED_RED, LOW);  delay(150);
    }
    tone(BUZZER_PIN, 400, 300);
    delay(400);
  } else {
    // Single long red = general error
    digitalWrite(LED_RED, HIGH);
    tone(BUZZER_PIN, 300, 600);
    delay(700);
    digitalWrite(LED_RED, LOW);
  }
}

void ledWifiConnecting() {
  digitalWrite(LED_YELLOW, HIGH); delay(100);
  digitalWrite(LED_YELLOW, LOW);  delay(100);
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
  Serial.println("  LabaFlow ESP32 v4.0");
  Serial.println("=============================");

  pinMode(LED_GREEN,  OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);
  pinMode(LED_RED,    OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  allLedsOff();

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
    // Fast red blink forever
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
    ledWifiConnecting();
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi: OK — IP: " + WiFi.localIP().toString());
    // Double green blink = ready
    for (int i = 0; i < 2; i++) {
      digitalWrite(LED_GREEN, HIGH); delay(150);
      digitalWrite(LED_GREEN, LOW);  delay(150);
    }
  } else {
    Serial.println("\nWiFi: FAILED");
    ledError(false);
  }

  Serial.println("-----------------------------");
  Serial.println("Ready. Tap RFID card.");
  Serial.println("=============================");
}

// =============================================
// LOOP
// =============================================
void loop() {
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

  // ── STEP 1: Yellow ON immediately (card detected)
  ledProcessing();

  // Check WiFi
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("ERROR: No WiFi");
    ledError(false);
    delay(2000);
    allLedsOff();
    return;
  }

  // ── STEP 2: Yellow blink while sending to API
  ledWaiting();

  // Build request
  String eventId = String(millis()) + "-" + tagUID;
  StaticJsonDocument<256> reqDoc;
  reqDoc["device_id"] = DEVICE_ID;
  reqDoc["tag_uid"]   = tagUID;
  reqDoc["event_id"]  = eventId;
  String reqBody;
  serializeJson(reqDoc, reqBody);

  Serial.println("Sending to Supabase...");

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

  // ── STEP 3: React to response
  if (httpCode == 200) {
    StaticJsonDocument<512> resDoc;
    DeserializationError err = deserializeJson(resDoc, responseStr);

    if (err) {
      Serial.println("ERROR: JSON parse failed");
      ledError(false);
    } else {
      bool success = resDoc["success"].as<bool>();

      if (success) {
        String action   = resDoc["action"].as<String>();
        String status   = resDoc["status"].as<String>();
        String orderRef = resDoc["order_reference"].as<String>();
        String message  = resDoc["message"].as<String>();

        Serial.println("SUCCESS! Action: " + action);
        Serial.println("Order: " + orderRef + " → " + status);

        if (action == "ASSIGNED") {
          String customer = resDoc["customer_name"].as<String>();
          Serial.println("Assigned to: " + customer);
          ledSuccess("ASSIGNED");
        } else {
          Serial.println("Advanced to: " + status);
          ledSuccess(status);
        }

      } else {
        // API returned error
        String code = resDoc["code"].as<String>();
        String msg  = resDoc["message"].as<String>();
        Serial.println("FAILED: " + code + " — " + msg);

        bool isDuplicate = (code == "DUPLICATE_TAG");
        ledError(isDuplicate);

        if (isDuplicate) {
          Serial.println(">>> DUPLICATE: Use a different tag for this customer!");
        } else if (code == "NO_PENDING_ORDER") {
          Serial.println(">>> No pending orders. Customer must book first.");
        } else if (code == "INVALID_STATE") {
          Serial.println(">>> Order already in final state: " + msg);
        }
      }
    }

  } else if (httpCode == 401) {
    Serial.println("ERROR 401: Check API_KEY in Supabase secrets");
    ledError(false);
  } else {
    Serial.println("ERROR: HTTP " + String(httpCode));
    ledError(false);
  }

  allLedsOff();
  delay(2000); // Cooldown before next scan
  Serial.println("Ready. Tap RFID card.");
}
