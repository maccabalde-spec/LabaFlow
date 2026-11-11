/**
 * LabaFlow ESP32 Firmware v7.0
 *
 * Simple and reliable — ESP32 sends UID to edge function.
 * Edge function handles ALL logic (find order, assign, advance status).
 * ESP32 just reacts to the response with LED + buzzer.
 *
 * LED SEQUENCE:
 *   Yellow ON    → card detected
 *   Yellow blink → sending to server
 *   Green flash  → SUCCESS
 *   Red flash    → ERROR
 *
 * WIRING:
 *   RFID SDA → D5   SCK → D18   MOSI → D23   MISO → D19   RST → D4
 *   Green LED → D32   Yellow LED → D33   Red LED → D25   Buzzer → D12
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <ArduinoJson.h>

// =============================================
// CONFIGURATION
// =============================================
const char* WIFI_SSID   = "Macoyshit";
const char* WIFI_PASS   = "tintinganda";
const char* FUNCTION_URL = "https://sesiygonrbthnwjlpggf.supabase.co/functions/v1/rfid-scan";
const char* ANON_KEY    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlc2l5Z29ucmJ0aG53amxwZ2dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM5NTI0NDQsImV4cCI6MjEwOTUyODQ0NH0.YjpCWOqMbp9lZISkx0gZnF-TFF7rHAnnEFSN_JJJkWA";

// =============================================
// PINS
// =============================================
#define RST_PIN     4
#define SS_PIN      5
#define LED_GREEN  32
#define LED_YELLOW 33
#define LED_RED    25
#define BUZZER_PIN 12

MFRC522 rfid(SS_PIN, RST_PIN);

// =============================================
// LED + BUZZER
// =============================================
void allOff() {
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_YELLOW, LOW);
  digitalWrite(LED_RED, LOW);
  noTone(BUZZER_PIN);
}

void ledYellow() { allOff(); digitalWrite(LED_YELLOW, HIGH); }

void ledYellowBlink() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_YELLOW, HIGH); delay(150);
    digitalWrite(LED_YELLOW, LOW);  delay(150);
  }
}

void ledGreen(bool isReady) {
  allOff();
  int times = isReady ? 3 : 2;
  int freq  = isReady ? 1500 : 1200;
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_GREEN, HIGH);
    tone(BUZZER_PIN, freq, 150);
    delay(250);
    digitalWrite(LED_GREEN, LOW);
    delay(100);
  }
}

void ledRed() {
  allOff();
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_RED, HIGH); delay(200);
    digitalWrite(LED_RED, LOW);  delay(150);
  }
  tone(BUZZER_PIN, 300, 400);
  delay(500);
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
// PROCESS SCAN — send to edge function
// =============================================
void processScan(String tagUID) {
  // Build simple JSON body
  String body = "{\"tag_uid\":\"" + tagUID + "\"}";

  Serial.println("Sending to function...");
  HTTPClient http;
  http.begin(FUNCTION_URL);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + String(ANON_KEY));
  http.addHeader("apikey", ANON_KEY);
  http.setTimeout(15000);

  int code = http.POST(body);
  String response = http.getString();
  http.end();

  Serial.println("HTTP: " + String(code));
  Serial.println("Response: " + response);

  if (code == 200) {
    // Parse response
    StaticJsonDocument<512> doc;
    DeserializationError err = deserializeJson(doc, response);

    if (err) {
      Serial.println("JSON parse error");
      ledRed();
      return;
    }

    bool success = doc["success"] | false;

    if (success) {
      String action  = doc["action"] | "UNKNOWN";
      String orderNum = doc["order_num"] | "";
      String customer = doc["customer"] | "";
      String status   = doc["status"] | "";

      Serial.println("SUCCESS! " + action + ": " + orderNum + " → " + status + " (" + customer + ")");
      ledGreen(status == "READY");

    } else {
      String code2  = doc["code"] | "";
      String msg    = doc["message"] | "Unknown error";
      Serial.println("FAILED: " + code2 + " — " + msg);
      ledRed();
    }

  } else if (code == 404) {
    Serial.println("No pending orders to assign!");
    ledRed();
  } else if (code == 402) {
    Serial.println("Order not paid yet — collect payment first!");
    // Special pattern for unpaid: slow red blink
    for (int i = 0; i < 4; i++) {
      digitalWrite(LED_RED, HIGH); delay(400);
      digitalWrite(LED_RED, LOW);  delay(300);
    }
  } else if (code == 429) {
    Serial.println("Rate limited — scan too fast, please wait.");
    // Short yellow blink — not an error, just slow down
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_YELLOW, HIGH); delay(300);
      digitalWrite(LED_YELLOW, LOW);  delay(200);
    }
  } else {
    Serial.println("HTTP Error: " + String(code));
    Serial.println(response);
    ledRed();
  }
}

// =============================================
// SETUP
// =============================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("============================");
  Serial.println("  LabaFlow ESP32 v7.0");
  Serial.println("============================");

  pinMode(LED_GREEN,  OUTPUT);
  pinMode(LED_YELLOW, OUTPUT);
  pinMode(LED_RED,    OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  allOff();

  // Init RFID
  SPI.begin(18, 19, 23, SS_PIN);
  rfid.PCD_Init();
  delay(100);

  byte ver = rfid.PCD_ReadRegister(rfid.VersionReg);
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
  WiFi.setAutoReconnect(true);    // auto-reconnect on drop
  WiFi.persistent(true);          // persist credentials across reboots
  Serial.print("WiFi: connecting");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    digitalWrite(LED_YELLOW, HIGH); delay(200);
    digitalWrite(LED_YELLOW, LOW);  delay(200);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(" OK! " + WiFi.localIP().toString());
    for (int i = 0; i < 2; i++) {
      digitalWrite(LED_GREEN, HIGH); delay(150);
      digitalWrite(LED_GREEN, LOW);  delay(150);
    }
  } else {
    Serial.println(" FAILED!");
    ledRed();
  }

  Serial.println("Ready. Tap RFID card.");
  Serial.println("============================");
}

// =============================================
// LOOP
// =============================================
String lastUID = "";
unsigned long lastScanMs = 0;
unsigned long lastReconnectMs = 0;

void loop() {
  // ── Auto-reconnect WiFi if dropped ──────────
  if (WiFi.status() != WL_CONNECTED) {
    unsigned long now = millis();
    if (now - lastReconnectMs > 10000) {   // try every 10 seconds
      lastReconnectMs = now;
      Serial.println("[WiFi] Lost connection — reconnecting...");
      WiFi.disconnect();
      WiFi.begin(WIFI_SSID, WIFI_PASS);
      // Brief yellow blink to signal reconnect attempt
      for (int i = 0; i < 2; i++) {
        digitalWrite(LED_YELLOW, HIGH); delay(200);
        digitalWrite(LED_YELLOW, LOW);  delay(200);
      }
    }
    delay(50);
    return;
  }
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) {
    delay(50);
    return;
  }

  String tagUID = uidToString(rfid.uid.uidByte, rfid.uid.size);
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();

  // Ignore incomplete UIDs
  if (rfid.uid.size < 4 || tagUID.length() < 8) {
    Serial.println("Incomplete UID: " + tagUID + " — hold card closer!");
    ledRed();
    delay(500);
    allOff();
    return;
  }

  // Prevent double scan of same card within 2 seconds
  if (tagUID == lastUID && millis() - lastScanMs < 2000) {
    delay(50);
    return;
  }

  lastUID    = tagUID;
  lastScanMs = millis();

  Serial.println("\n--- Card: " + tagUID + " ---");

  // Step 1: Yellow ON
  ledYellow();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("No WiFi!");
    ledRed();
    allOff();
    return;
  }

  // Step 2: Yellow blink (sending)
  ledYellowBlink();

  // Step 3: Process and react
  processScan(tagUID);

  allOff();
  Serial.println("Ready. Tap next card.");
}
