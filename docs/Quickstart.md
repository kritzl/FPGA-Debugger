# Quickstart

## Schritt 1: FPGA mit Quartus flashen


## Schritt 2: Mikrocontroller (ESP32) mit Arduino IDE flashen
 - Projekt in `/src/microcontroller` mit der Arduino IDE öffnen.

## Schritt 3: Debugging-Software starten
Da wir mithilfe der Serial-API eine Website als Debugging-Software nutzen können, muss lediglich der Inhalt des Verzeichnisses `/src/web` mit einem simplen Webserver zur Verfügung gestellt werden. Alternativ ist die Website über GitHub Pages unter [fpga.kritzl.dev](https://fpga.kritzl.dev) bereitgestellt.

## (optional) Debugger-Board herstellen
Insgesamt sind 68 Pins des FPGA an den Mikrocontroller angeschlossen. Damit das möglich ist, benutzen wir sog. "Parallel-In-Serial-Out" Shiftregister.
Um diese einfach zwischen den FPGA und den Mikrocontroller zu schalten, haben wir eine Platine entworfen. Die Projektdateien dazu befinden sich unter `/src/board`. Der Pinout der Platine ist auf die Verwendung eines `ESP-32 Dev Kit C` von `Espressif` ausgelegt.

Folgende Bauteile werden zum Bestücken der Platine benötigt:
- 8x `SN74HC165N` Shiftregister
- *bei Bedarf: 8x 16-Pin IC-Sockel für die Shiftregister*
- 2x 40-Pin IDE P-ATA Header
- 1x ESP32 Dev Kit C
- 3x 19-Pin Buchsenleisten
- 1x 20-Pin Buchsenleiste
- Ggf. 1x 8-Pin Buchsenleiste  
  *Für den Anschluss eines SPI LC-Displays an des ESP-32*
- Ggf. LC-Display mit Display-Controller `ILI9341`  
  z.B. https://www.waveshare.com/wiki/2.4inch_LCD_Module
- 2x 40-Pin ATA-Kabel