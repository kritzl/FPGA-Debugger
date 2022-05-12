library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;

package memoryAccessPkg is
    component memoryAccess is
        port (
            clock      : in std_logic;
            reset      : in std_logic;
            addressInX : in regAddrType;
            opcIn      : in opcType;
            aluData    : in dataWordType;
            dataInZ    : in dataWordType;

            writeBackAddr : out regAddrType;
            writeBackData : out dataWordType;
            writeBackFlag : out std_logic
        );
    end component memoryAccess;
end package memoryAccessPkg;

---------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;
use work.memoryAccessPkg.all;

use work.ram;

entity memoryAccess is
    port (
        clock      : in std_logic;
        reset      : in std_logic;
        addressInX : in regAddrType;
        opcIn      : in opcType;
        aluData    : in dataWordType;
        dataInZ    : in dataWordType;

        writeBackAddr : out regAddrType;
        writeBackData : out dataWordType;
        writeBackFlag : out std_logic
    );
end entity memoryAccess;

architecture memoryAccessModel of memoryAccess is
    signal writeEnable        : std_logic;
    signal memDataOutInternal : std_logic_vector(dataWordLength - 1 downto 0);

begin
    ram_1 : ram port map(
        std_logic_vector(aluData)(12 downto 0), -- address  : IN  STD_LOGIC_VECTOR (12 DOWNTO 0);
        not clock,                              -- clock    : IN  STD_LOGIC  := '1';  -- have to use not clock because it would otherwise need 2 cycles. Its not bad here, because there is a register before the RAM module
        std_logic_vector(dataInZ),              -- data     : IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
        writeEnable,                            -- wren     : IN  STD_LOGIC ;
        memDataOutInternal                      -- q        : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
    );

    memoryAccessP : process (clock, reset) is
    begin
        if reset = '1' then
            writeBackFlag <= '0';
        elsif rising_edge(clock) then
            writeBackAddr <= addressInX;

            case opcIn is
                when opcLdw => writeBackData <= signed(memDataOutInternal);
                when opcJsr => writeBackData <= dataInZ;
                when others => writeBackData <= aluData;
            end case;

            writeBackFlag <= opcIn(6);
        end if;
    end process;

    setWriteEnable : process (reset, opcIn) is
    begin
        if reset = '1' then
            writeEnable <= '0';
        elsif opcIn = opcStw then
            writeEnable <= '1';
        else
            writeEnable <= '0';
        end if;
    end process;
end architecture memoryAccessModel;
