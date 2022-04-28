/*
  DigitalReadSerial

  Reads a digital input on pin 2, prints the result to the Serial Monitor

  This example code is in the public domain.

  https://www.arduino.cc/en/Tutorial/BuiltInExamples/DigitalReadSerial
*/

/* PISO CHIPS (ParallelInSerialOut) */
#define SERIALIN 5
#define SHLD 15
#define CLK 4
#define CLK_INH 2

#define FPGA_CLK 26 // GPIO0_1
#define FPGA_RST 25 // GPIO0_0
#define FPGA_RUN 32 // GPIO1_0
#define FPGA_G11 33 // GPIO1_1

// Serial Message types
#define MSG_DEBUG 0x0
#define MSG_FPGA_0 0x1
#define MSG_FPGA_1 0x2
#define MSG_SYNC 0xFF

/* SPI DISPLAY */
#define SPI_MOSI 23
#define SPI_CS 22
#define SPI_DC 21
#define SPI_CLK 18
#define SPI_RST 17
#define BACKLIGHT 19

#define shift 1
#define load 0

struct ClockState
{
    bool active;
};

bool running = false;

ClockState clock_state = {false};

void ARDUINO_ISR_ATTR clockInterrupt()
{
    clock_state.active = true;
}

// the setup routine runs once when you press reset:
void setup()
{
    // initialize serial communication at 9600 bits per second:
    Serial.begin(115200);
    // make the pushbutton's pin an input:
    pinMode(SERIALIN, INPUT_PULLDOWN);
    pinMode(SHLD, OUTPUT);
    pinMode(CLK, OUTPUT);

    // RST
    pinMode(FPGA_RST, OUTPUT);

    // is Running
    pinMode(FPGA_RUN, INPUT);

    // CLK
    pinMode(FPGA_CLK, INPUT);
    attachInterrupt(FPGA_CLK, clockInterrupt, FALLING);
}

// the loop routine runs over and over again forever:
void loop()
{
    if (clock_state.active)
    {
        clock_state.active = false;
        // load from parallel
        digitalWrite(SHLD, load);
        digitalWrite(CLK, HIGH);
        delay(1);
        digitalWrite(CLK, LOW);

        delay(1);

        // switch to shift-mode
        digitalWrite(SHLD, shift);

        byte piso0 = shiftIn(SERIALIN, CLK, MSBFIRST);
        byte piso1 = shiftIn(SERIALIN, CLK, MSBFIRST);
        byte piso2 = shiftIn(SERIALIN, CLK, MSBFIRST);
        byte piso3 = shiftIn(SERIALIN, CLK, MSBFIRST);
        byte piso4 = shiftIn(SERIALIN, CLK, MSBFIRST);
        byte piso5 = shiftIn(SERIALIN, CLK, MSBFIRST);
        byte piso6 = shiftIn(SERIALIN, CLK, MSBFIRST);
        byte piso7 = shiftIn(SERIALIN, CLK, MSBFIRST);

        uint32_t gpio0 = parseGPIO0(piso4, piso5, piso6, piso7);
        uint32_t gpio1 = parseGPIO1(piso0, piso1, piso2, piso3);

        // Serial.print("PC: ");
        // printHex((gpio1 >> 8) & 0xFFFF, 4);
        // if (bitRead(gpio1, 0))
        // {
        //     Serial.print(" - Schreibe an Adresse ");
        //     printHex(gpio1 >> 24, 2);
        //     Serial.print(": ");
        //     printHex(gpio0, 8);
        //     Serial.println("\n ");
        // }
        // else
        // {
        //     Serial.println("\n ");
        // }

        send(MSG_FPGA_0, gpio0);
        send(MSG_FPGA_1, gpio1);
    }

    bool isRunning = digitalRead(FPGA_RUN);
    if (isRunning != running)
    {
        running = isRunning;
        if (running)
        {
            sendDebug("Running");
        }
        else
        {
            sendDebug("Stopped");
        }
    }
}

void serialEvent()
{
    String command = "";

    while (Serial.available())
    {
        char inChar = (char)Serial.read();

        if (inChar == '\n')
        {
            if (command == "reset")
            {
                digitalWrite(FPGA_RST, 1);
                delay(1);
                digitalWrite(FPGA_RST, 0);

                sendDebug("OK");
            }
            else if (command == "moin")
            {
                send(MSG_SYNC, 0xFFFFFFFF);
                Serial.write(0);
                sendDebug("Moin");

                if (running)
                {
                    sendDebug("Running");
                }
                else
                {
                    sendDebug("Stopped");
                }
            }
            else if (command == "help")
            {
                sendDebug("Available Commands: 'reset', 'moin', 'help'");
            }
            else
            {
                sendDebug("Unknown Command");
            }
            command = "";
        }
        else
        {
            command += inChar;
        }
    }
}

void sendDebug(String message)
{
    Serial.write(MSG_DEBUG);
    Serial.print(message);
    Serial.write('\n');
}

void send(char type, uint32_t data)
{
    Serial.write(type);
    Serial.write((data >> 24) & 0xFF);
    Serial.write((data >> 16) & 0xFF);
    Serial.write((data >> 8) & 0xFF);
    Serial.write((data >> 0) & 0xFF);
}

uint32_t parseGPIO0(byte piso4, byte piso5, byte piso6, byte piso7)
{

    uint32_t gpio0 = 0;

    // Byte 1 - GPIO1 02-09
    gpio0 |= bitRead(piso5, 3) << 0; // PIN 02
    gpio0 |= bitRead(piso6, 4) << 1; // PIN 03
    gpio0 |= bitRead(piso5, 4) << 2; // PIN 04
    gpio0 |= bitRead(piso6, 3) << 3; // PIN 05
    gpio0 |= bitRead(piso5, 2) << 4; // PIN 06
    gpio0 |= bitRead(piso6, 5) << 5; // PIN 07
    gpio0 |= bitRead(piso5, 5) << 6; // PIN 08
    gpio0 |= bitRead(piso6, 2) << 7; // PIN 09

    // Byte 2 - GPIO1 10-17
    gpio0 |= bitRead(piso5, 1) << 8;  // PIN 10
    gpio0 |= bitRead(piso6, 6) << 9;  // PIN 11
    gpio0 |= bitRead(piso5, 6) << 10; // PIN 12
    gpio0 |= bitRead(piso6, 1) << 11; // PIN 13
    gpio0 |= bitRead(piso5, 0) << 12; // PIN 14
    gpio0 |= bitRead(piso6, 7) << 13; // PIN 15
    gpio0 |= bitRead(piso5, 7) << 14; // PIN 16
    gpio0 |= bitRead(piso6, 0) << 15; // PIN 17

    // Byte 3 - GPIO1 18-25
    gpio0 |= bitRead(piso4, 3) << 16; // PIN 18
    gpio0 |= bitRead(piso7, 3) << 17; // PIN 19
    gpio0 |= bitRead(piso4, 4) << 18; // PIN 20
    gpio0 |= bitRead(piso7, 4) << 19; // PIN 21
    gpio0 |= bitRead(piso4, 2) << 20; // PIN 22
    gpio0 |= bitRead(piso7, 2) << 21; // PIN 23
    gpio0 |= bitRead(piso4, 5) << 22; // PIN 24
    gpio0 |= bitRead(piso7, 5) << 23; // PIN 25

    // Byte 4 - GPIO1 26-33
    gpio0 |= bitRead(piso4, 1) << 24; // PIN 26
    gpio0 |= bitRead(piso7, 1) << 25; // PIN 27
    gpio0 |= bitRead(piso4, 6) << 26; // PIN 28
    gpio0 |= bitRead(piso7, 6) << 27; // PIN 29
    gpio0 |= bitRead(piso4, 0) << 28; // PIN 30
    gpio0 |= bitRead(piso7, 0) << 29; // PIN 31
    gpio0 |= bitRead(piso4, 7) << 30; // PIN 32
    gpio0 |= bitRead(piso7, 7) << 31; // PIN 33

    return gpio0;
}

uint32_t parseGPIO1(byte piso0, byte piso1, byte piso2, byte piso3)
{

    uint32_t gpio1 = 0;

    // Byte 5 - GPIO1 02-09
    gpio1 |= bitRead(piso3, 7) << 0; // PIN 02
    gpio1 |= bitRead(piso0, 0) << 1; // PIN 03
    gpio1 |= bitRead(piso3, 0) << 2; // PIN 04
    gpio1 |= bitRead(piso0, 7) << 3; // PIN 05
    gpio1 |= bitRead(piso3, 6) << 4; // PIN 06
    gpio1 |= bitRead(piso0, 1) << 5; // PIN 07
    gpio1 |= bitRead(piso3, 1) << 6; // PIN 08
    gpio1 |= bitRead(piso0, 6) << 7; // PIN 09

    // Byte 6 - GPIO1 10-17
    gpio1 |= bitRead(piso3, 5) << 8;  // PIN 10
    gpio1 |= bitRead(piso0, 2) << 9;  // PIN 11
    gpio1 |= bitRead(piso3, 2) << 10; // PIN 12
    gpio1 |= bitRead(piso0, 5) << 11; // PIN 13
    gpio1 |= bitRead(piso3, 4) << 12; // PIN 14
    gpio1 |= bitRead(piso0, 3) << 13; // PIN 15
    gpio1 |= bitRead(piso3, 3) << 14; // PIN 16
    gpio1 |= bitRead(piso0, 4) << 15; // PIN 17

    // Byte 7 - GPIO1 18-25
    gpio1 |= bitRead(piso2, 7) << 16; // PIN 18
    gpio1 |= bitRead(piso1, 0) << 17; // PIN 19
    gpio1 |= bitRead(piso2, 0) << 18; // PIN 20
    gpio1 |= bitRead(piso1, 7) << 19; // PIN 21
    gpio1 |= bitRead(piso2, 6) << 20; // PIN 22
    gpio1 |= bitRead(piso1, 1) << 21; // PIN 23
    gpio1 |= bitRead(piso2, 1) << 22; // PIN 24
    gpio1 |= bitRead(piso1, 6) << 23; // PIN 25

    // Byte 8 - GPIO1 26-33
    gpio1 |= bitRead(piso2, 5) << 24; // PIN 26
    gpio1 |= bitRead(piso1, 2) << 25; // PIN 27
    gpio1 |= bitRead(piso2, 2) << 26; // PIN 28
    gpio1 |= bitRead(piso1, 5) << 27; // PIN 29
    gpio1 |= bitRead(piso2, 4) << 28; // PIN 30
    gpio1 |= bitRead(piso1, 3) << 29; // PIN 31
    gpio1 |= bitRead(piso2, 3) << 30; // PIN 32
    gpio1 |= bitRead(piso1, 4) << 31; // PIN 33

    return gpio1;
}

void printHex(int num, int len)
{
    char tmp[16];
    char format[128];

    sprintf(format, "0x%%.%dX ", len);

    sprintf(tmp, format, num);
    Serial.print(tmp);
}