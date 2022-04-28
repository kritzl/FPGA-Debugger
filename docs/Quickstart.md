# Quickstart

Wenn du den Debugger ohne weitere Entwicklung zum laufen bringen möchtest, bist du hier richtig. Die Anleitung hier bezieht sich spezifisch auf die Verwendung mit unserer Implementierung eines Befehlssatzes für den FPGA.  
Wenn du den Debugger für deinen eigenen Code verwenden möchtest, solltest du in das detaillierte [HowTo](/docs/HowTo) schauen.

## Schritt 1: FPGA mit Quartus flashen
- Projekt in [bla](/src/fpga)
Um unseren Prozessor und FPGA Code 

## Schritt 2: Mikrocontroller (ESP32) mit Arduino IDE flashen
 - Projekt in `/src/microcontroller` mit der Arduino IDE öffnen.

## Schritt 3: Debugging-Software starten
Da wir mithilfe der Serial-API eine Website als Debugging-Software nutzen können, muss lediglich der Inhalt des Verzeichnisses `/src/web` mit einem simplen Webserver zur Verfügung gestellt werden. Alternativ ist die Website über GitHub Pages unter [fpga.kritzl.dev](https://fpga.kritzl.dev) bereitgestellt.

## Schritt 4: Verwendung des Debuggers
- FPGA mit dem Debugger-Board verbinden
- Mikrocontroller auf Board stecken
- Mikrocontroller mit Computer verbinden (USB)
- Debugger Software öffnen

Die Debugger Website ist ähnlich wie ein terminal aufgebaut.
Im rechten Bereich kannst du Befehle eintippen, während du auf der Linken Seite die Ausgabe des Mikrocontrollers siehst.
Um eine Verbindung zwischen der Website und dem Mikrocontroller herzustellen, muss der Befehl `connect` eingegeben und mit <kbd>Enter</kbd> bestätigt werden.
Anschließend sollte der Browser dich auffordern ein Serielles Gerät auszuwählen. Nachdem die Verbindugn erfolgreich hergestellt wurde, wird die Ausgabe zunächst automatisch synchronisiert. Dies kann auch manuell mit dem Befehl `moin` erzwungen werden.  
Um den FPGA über den Pin `GPIO0-0` zurückzusetzen, kannst du den Befehl `reset` eingeben. Nun sollte der FPGA die Ausführung des Programms starten und auf der linken Seite jede Aktualisierung des Programmzählers erscheinen. Falls bei einem Schritt des Programms etwas in ein Register geschrieben wird, wir die entsprechende Adresse und der zu schreibende Inhalt angezeigt.  
Du solltest beachten, dass durch 

## (optional) Debugger-Board herstellen
Insgesamt sind 68 Pins des FPGA an den Mikrocontroller angeschlossen. Damit das möglich ist, benutzen wir sog. "Parallel-In-Serial-Out" Shiftregister.
Um diese einfach zwischen den FPGA und den Mikrocontroller zu schalten, haben wir eine Platine entworfen. Der Pinout der Platine ist auf die Verwendung eines `ESP-32 Dev Kit C` von `Espressif` ausgelegt.

Die Projektdateien dazu befinden sich unter `/src/board`. In dem Ordner befindet sich auch eine Datei im Gerber-Format, sodass PCBs einfach bei Herstellern nachbestellt werden können.

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