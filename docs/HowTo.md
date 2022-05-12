# HowTo
## Eigenen FPGA mit dem Debugger verbinden
Um deinen eigenen Mikrorechnercode mit dem FPGA zu verwenden, musst du einige interne Zustände deines Prozessors auf die Pins des FPGAs legen.  
Im Folgenden ist eine Anleitung, wie wir mit unserer Prozessorarchitektur debuggen. Falls du beispielsweise kein Register in deiner Prozessorarchitektur hast, ist diese Version des Debuggers wahrscheinlich nicht wirklich hilfreich. Dafür solltest du den Code des [Arduino Debuggers](https://github.com/kritzl/FPGA-Debugger/tree/main/src/microcontroller/arduinoDebugger) und die entsprechende [Web Anwendung](https://github.com/kritzl/FPGA-Debugger/tree/main/src/web) auf deine Bedürfnisse anpassen.

Pin Zuweisungen:
- `gpio01 : out std_logic`: Clock des Prozessors (1ms nach der rising-edge sollten die Datenwerte anliegen. Dafür reicht es, wenn du die ganzen folgenden Datenzuweisungen in ein `if rising_edge(clk)` packst).
- `gpio10 : out std_logic` *(optional)*: Ob der Prozessor läuft (`'1'`), oder auf reset wartet / halt erreicht hat (`'0'`).
- `gpio0 : out std_logic_vector(31 downto 0)` *(optional)*: Die Daten, wenn diese in das Register zurück geschrieben werden (32 bit).
- `gpio1 : out std_logic_vector(31 downto 24)` *(optional)*: Die Adresse, wenn Daten in das Register zurück geschrieben werden (8 bit)
- `gpio1 : out std_logic_vector(23 downto 8)` *(optional)*: Der Program Counter (16 bit).
- `gpio1 : out std_logic_vector(0)` *(optional)*: Ob gerade etwas in das Register zurückgeschrieben wird (Also die Daten von `gpio0(31 downto 0)` und `gpio1(31 downto 24)`). Dann `'1'`, ansonsten `'0'`.
- `gpio00 : in std_logic` *(optional)*: Reset Signal. Dieses wird vom Debugger für 1,25s auf `'0'` gesetzt, wenn resettet wird. Ansonsten hält der Debugger diesen dauerhaft auf `'1'` (active low).
- `gpio11` *(für die Vollständigkeit)*: Ist momentan nicht verwendet 

*Zu welchem tatsächlichen Pin unsere Benenung gehört, kannst du in userer [Quartus Config](https://github.com/kritzl/FPGA-Debugger/blob/main/src/fpga/de0Board.qsf#L193) nachvollziehen*