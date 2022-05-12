-- de0Board.vhd
--------------------------------------------------------------------------------
-- ajm 29-dec-2014
-- -derived from: Terasic System Builder
--------------------------------------------------------------------------------
--
-- entity de0Board -generic wrapper for Terasic DE0-Nano
--     prototyping board
-- architecture	wrapper
--
-- usage:
--     1. I/O setup in entity
--         -comment out all unused ports!!!
--     2. declare in architecture
--         -components to be used, see <myComponent>
--         -local signals
--     3. statements in architecture
--         -component instances
--         -processes
--     4. Quartus in file: de0Board.qsf
--         -add VHDL source files
--         or GUI-setup within quartus
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pllclk;
use work.globalConstants.all;
use work.instructionFetchPkg.all;
use work.instructionDecodePkg.all;
use work.executeAddressCalcPkg.all;
use work.memoryAccessPkg.all;
-- entity ----------------------------------------------------------------------
--------------------------------------------------------------------------------
entity de0Board is
    port (
        clk50 : in std_logic; -- 50 MHz external clock

        -- KEY active LOW ----------------------------------------
        key : in std_logic_vector(1 downto 0);

        -- DIP switch 0-Up / 1-Down ------------------------------
        --  switch : in std_logic_vector( 3 downto 0);

        -- LED active HIGH ---------------------------------------
        led : out std_logic_vector(7 downto 0);

        -- SDRAM 16Mx16 ------------------------------------------
        -- IS42S16160B 4M x 16 x 4 banks
        -- dram-IS42S16160B => page 8ff
        dramCsN : out std_logic; -- L: chip select
        --  dramCke : out std_logic;  -- H: clock enable
        --  dramClk : out std_logic;  -- R: input-regs
        --  dramRasN : out std_logic;  -- L: row-addr. strobe
        --  dramCasN : out std_logic;  -- L: col-addr. strobe
        --  dramWeN : out std_logic;  -- L: write enable
        --  dramBa : out unsigned( 1 downto 0);  -- bank addr.
        --  dramAddr : out unsigned(12 downto 0);  -- address
        --  dramDqm : out unsigned( 1 downto 0);  -- byte dat.mask
        --  dramDq : inout std_logic_vector(15 downto 0);  -- data

        -- EPCS --------------------------------------------------
        -- Spansion S25FL064P: FPGA config. memory; 64M bit Flash
        -- DE0-UserManual + epcs-S25FL064P + Altera Manuals
        epcsCsN : out std_logic; -- L: chip sel. CS#
        --  epcsDClk : out std_logic;  -- clock	SCK
        --  epcsAsd : out std_logic;  -- ser.data out SI/IO0
        --  epcsData : in std_logic;  -- ser.data in SO/IO1

        -- I2C EEPROM --------------------------------------------
        -- Microchip 24LC02B 2K bit
        -- eeprom-24xx02 => page 5ff
        --  i2cSClk : out std_logic;  -- SClock (bus master)
        --  i2cSDat : inout std_logic;  -- SData

        -- I2C Accelerometer -------------------------------------
        -- Analog Devices ADXL345
        -- accel-ADXL345 => page 17ff
        --  i2cSClk : out std_logic;  -- SClock (bus master)
        --  i2cSDat : inout std_logic;  -- SData
        gSensorCs : out std_logic; -- H: chip sel. I2C-mode
        --  gSensorInt : in std_logic;  -- interrupt	INT1

        -- AD converter ------------------------------------------
        -- National Semiconductor ADC128S022
        -- adc-ADC128S022 => page 2+7+16
        adcCsN : out std_logic; -- L: chip select
        --  adcSClk : out std_logic;  -- clock [0,8-3,2MHz]
        --  adcSAddr : out std_logic;  -- command DIN
        --  adcSData : in std_logic;  -- data DOUT

        -- GPIO-0 ------------------------------------------------
        -- top DE0-UserManual => page 18
        gpio00 : inout std_logic;
        gpio01 : inout std_logic;
        gpio0  : out std_logic_vector(31 downto 0);
        --  gpio0In : in std_logic_vector( 1 downto 0);

        -- GPIO-1 ------------------------------------------------
        -- bot DE0-UserManual => page 18
        gpio10 : inout std_logic;
        gpio11 : inout std_logic;
        gpio1  : out std_logic_vector(31 downto 0)
        --  gpio1In : in std_logic_vector(1 downto 0);

        -- 2x13 GPIO ---------------------------------------------
        -- right DE0-UserManual => page 21
        --  gpio2 : inout std_logic_vector(12 downto 0);
        --  gpio2In : in std_logic_vector(2 downto 0));

        -------------------------------------------------------------
        -- Kram von Mäders Platine ----------------------------------
        -------------------------------------------------------------

        -- butWh : in std_logic_vector(1 to 8);  -- [H]  gpio1(24..31)
        -- butBk : in std_logic_vector(1 to 2);  -- [L]  gpio1(16..17)
        -- butRd : in std_logic_vector(1 to 2);  -- [L]  gpio1(19..20)

        -- s_ceN : out std_logic;  -- SPI client ena. [L]
        -- -- 3-SCE = gpio1(0)

        -- s_rstN : out std_logic; -- SPI reset [L]
        -- -- 4-RST = gpio1(1)
        -- s_dNc : out std_logic;  -- SPI data [1]/ctrl [0]
        -- -- 5-D/C = gpio1(2)
        -- s_din : out std_logic;  -- SPI data in
        -- -- 6-DN(MOSI) = gpio1(3)
        -- s_clk : out std_logic;  -- SPI clock
        -- -- 7-SCLK = gpio1(4)
        -- bgLed : out	std_logic  -- background LED
        -- -- 8-LED = gpio1(5)
    );

end entity de0Board;
-- architecture	----------------------------------------------------------------
--------------------------------------------------------------------------------
architecture wrapper of de0Board is
    signal clk, clkN : std_logic;
    signal clk2mhz   : std_logic;

    --------------------------------------------------------------------------
    -- Riscy Core  -----------------------------------------------------------
    --------------------------------------------------------------------------

    signal instructionFetchPcOut          : instructionAddrType;
    signal instructionFetchInstructionOut : instructionWordType;

    signal instructionDecodePcOut       : instructionAddrType;
    signal instructionDecodeAddressOutX : regAddrType;
    signal instructionDecodeDataOutY    : dataWordType;
    signal instructionDecodeDataOutZ    : dataWordType;
    signal instructionDecodeImmediate   : immType;
    signal instructionDecodeOpcOut      : opcType;

    signal executeAddressCalcAddressOutX    : regAddrType;
    signal executeAddressCalcOpcOut         : opcType;
    signal executeAddressCalcAluOut         : dataWordType;
    signal executeAddressCalcDataOutZ       : dataWordType;
    signal executeAddressCalcPcOverrideFlag : std_logic;
    signal executeAddressCalcPcOverride     : instructionAddrType;

    signal memoryAccessWritebackAddrOut : regAddrType;
    signal memoryAccessWritebackDataOut : dataWordType;
    signal memoryAccessWritebackOutFlag : std_logic;

    -- ----------

    signal running  : std_logic := '0';      -- if the programm has been reset and the clock is allowed to run
    signal reset    : std_logic;             -- RESET signal
    signal resetCnt : unsigned(31 downto 0); -- count up while reset is pressed. Only reset if above a threshold
    signal clkCnt   : unsigned(31 downto 0);
begin
    -- reset <= not key(0);
    clk <= clkCnt(CLOCK_INDEX); -- choose your clock wisely

    gpio01 <= clk;
    gpio10 <= running;

    readReset : process (clk2mhz) is
    begin
        if rising_edge(clk2mhz) then
            if key(0) = '0' or gpio00 = '0' then
                if resetCnt = "00000000000111111111111111111111" then
                    reset <= '1';
                else
                    resetCnt <= resetCnt + 1;
                end if;
            else
                reset    <= '0';
                resetCnt <= (others => '0');
            end if;
        end if;
    end process readReset;

    arduino : process (clk) is
    begin
        if rising_edge(clk) then
            gpio0               <= std_logic_vector(memoryAccessWritebackDataOut);
            gpio1(31 downto 24) <= std_logic_vector(memoryAccessWritebackAddrOut);
            gpio1(23 downto 8)  <= std_logic_vector(instructionFetchPcOut);
            gpio1(0)            <= std_logic(memoryAccessWritebackOutFlag);
        end if;
    end process arduino;

    clkDiv : process (clk2mhz) is
    begin
        if rising_edge(clk2mhz) then
            if reset = '1' then -- for some reason reset is '1' for a short period after boot (without pressing the key). Therefore we put it in the fast-clock
                clkCnt  <= (others => '0');
                running <= '1';
            elsif running = '1' then
                if clkCnt = "11111111111111111111111111111111" then
                    clkCnt <= (others => '0');
                else
                    clkCnt <= clkCnt + 1;
                end if;
                if instructionFetchInstructionOut(instructionWordLength - 1 downto instructionWordLength - 8) = opcHalt then
                    running <= '0';
                end if;
            end if;
        end if;
    end process clkDiv;

    de0BoardP : process (clk, reset, instructionFetchPcOut) is
    begin
        if reset = '1' then
            led <= (others => '1');
        else
            led <= clk & instructionFetchPcOut(6 downto 0);
            -- led <= clk & std_logic_vector(DEBUG)(6 downto 0);
            -- led <= std_logic_vector(instructionFetchInstructionOut)(31 downto 24);
        end if;
    end process de0BoardP;

    -- disable unused hardware
    ------------------------------------------------------------------------------
    dramCsN   <= '1';
    epcsCsN   <= '1';
    gSensorCs <= '0';
    adcCsN    <= '1';

    -- component instantitions
    ------------------------------------------------------------------------------
    pllI : pllClk port map(clk50, clk2mhz, clkN, open, open); -- 2 MHz clock
    -- pllI: pllClk port map (clk50, open, open, clk,  clkN);  -- 1 MHz clock

    --------------------------------------------------------------------------
    -- Riscy Core  -----------------------------------------------------------
    --------------------------------------------------------------------------
    instructionFetch_1 : instructionFetch port map(
        clk,                              -- clock          : in std_logic;
        reset,                            -- reset          : in std_logic;
        executeAddressCalcPcOverrideFlag, -- pcOverrideFlag : in std_logic;
        executeAddressCalcPcOverride,     -- pcOverride     : in instructionAddrType;
        instructionFetchPcOut,            -- pcOut          : out instructionAddrType;
        instructionFetchInstructionOut    -- instructionOut : out instructionWordType
    );
    instructionDecode_1 : instructionDecode port map(
        clk,                            -- clock         : in std_logic;
        reset,                          -- reset         : in std_logic;
        instructionFetchPcOut,          -- pcIn          : in instructionAddrType;
        instructionFetchInstructionOut, -- instructionIn : in instructionWordType;
        memoryAccessWritebackAddrOut,   -- writeBackAddr : in regAddrType;
        memoryAccessWritebackDataOut,   -- writeBackData : in dataWordType;
        memoryAccessWritebackOutFlag,   -- writeBackFlag : in std_logic;
        instructionDecodePcOut,         -- pcOut         : out instructionAddrType;
        instructionDecodeAddressOutX,   -- addressOutX   : out regAddrType;
        instructionDecodeDataOutY,      -- dataOutY      : out dataWordType;
        instructionDecodeDataOutZ,      -- dataOutZ      : out dataWordType;
        instructionDecodeImmediate,     -- immediate     : out immType;
        instructionDecodeOpcOut         -- opcOut        : out opcType
    );
    executeAddressCalc_1 : executeAddressCalc port map(
        clk,                              -- clock          : in std_logic;
        reset,                            -- reset          : in std_logic;
        instructionDecodePcOut,           -- pcIn           : in instructionAddrType;
        instructionDecodeAddressOutX,     -- addressInX     : in regAddrType;
        instructionDecodeOpcOut,          -- opcIn          : in opcType;
        instructionDecodeDataOutY,        -- dataInY        : in dataWordType;
        instructionDecodeDataOutZ,        -- dataInZ        : in dataWordType;
        instructionDecodeImmediate,       -- immediate      : in immType;
        executeAddressCalcPcOverrideFlag, -- pcOverrideFlag : out std_logic;
        executeAddressCalcPcOverride,     -- pcOverride     : out instructionAddrType;
        executeAddressCalcAddressOutX,    -- addressOutX    : out regAddrType;
        executeAddressCalcOpcOut,         -- opcOut         : out opcType;
        executeAddressCalcAluOut,         -- aluOut         : out dataWordType;
        executeAddressCalcDataOutZ        -- dataOutZ       : out dataWordType
    );
    memoryAccess_1 : memoryAccess port map(
        clk,                           -- clock         : in std_logic;
        reset,                         -- reset         : in std_logic;
        executeAddressCalcAddressOutX, -- addressInX    : in regAddrType;
        executeAddressCalcOpcOut,      -- opcIn         : in opcType;
        executeAddressCalcAluOut,      -- aluData       : in dataWordType;
        executeAddressCalcDataOutZ,    -- dataInZ       : in dataWordType;
        memoryAccessWritebackAddrOut,  -- writeBackAddr : out regAddrType;
        memoryAccessWritebackDataOut,  -- writeBackData : out dataWordType;
        memoryAccessWritebackOutFlag   -- writeBackFlag : out std_logic
    );
end architecture wrapper;
