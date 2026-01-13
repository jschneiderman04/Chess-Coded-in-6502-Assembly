const uint8_t dataPins[8] = {38, 40, 42, 44, 46, 48, 50, 52};

const uint8_t PIN_S   = 24;
const uint8_t PIN_L   = 30;
const uint8_t PIN_RDY = 26;
const uint8_t PIN_RDX = 28;

void setDataPinsInput() {
  for (uint8_t i = 0; i < 8; i++) {
    pinMode(dataPins[i], INPUT);
  }
}

void setDataPinsOutput() {
  for (uint8_t i = 0; i < 8; i++) {
    pinMode(dataPins[i], OUTPUT);
  }
}

void setup() {
  Serial.begin(57600);

  pinMode(PIN_S, INPUT);
  pinMode(PIN_L, INPUT);

  pinMode(PIN_RDY, OUTPUT);
  pinMode(PIN_RDX, OUTPUT);

  digitalWrite(PIN_RDY, LOW);
  digitalWrite(PIN_RDX, LOW);

  setDataPinsInput();
}

void loop() {


  if (digitalRead(PIN_S) == HIGH) {

    setDataPinsInput();

    char outBits[9];  


    for (int i = 0; i < 8; i++) {
      uint8_t pinIndex = 7 - i;  
      outBits[i] = digitalRead(dataPins[pinIndex]) ? '1' : '0';
    }
    outBits[8] = '\0';

  
    Serial.print(outBits);
    Serial.print('\n');

    delayMicroseconds(10);

    digitalWrite(PIN_RDY, HIGH);

  
    while (digitalRead(PIN_S) == HIGH) {
      
    }

    digitalWrite(PIN_RDY, LOW);
  }

  
  if (digitalRead(PIN_L) == HIGH) {

    setDataPinsOutput();

    char inBits[9];
    uint8_t count = 0;

   
    while (count < 8) {
      if (Serial.available() > 0) {
        char c = Serial.read();
        if (c == '0' || c == '1') {
          inBits[count++] = c;
        }
      }
    }
    inBits[8] = '\0';

  
    for (int i = 0; i < 8; i++) {
      uint8_t pinIndex = 7 - i;
      digitalWrite(dataPins[pinIndex],
                   (inBits[i] == '1') ? HIGH : LOW);
    }

    delayMicroseconds(10);

    digitalWrite(PIN_RDX, HIGH);

   
    while (digitalRead(PIN_L) == HIGH) {
      
    }

    setDataPinsInput();
    digitalWrite(PIN_RDX, LOW);
  }
}
