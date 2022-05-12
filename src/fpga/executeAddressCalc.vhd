library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;
use work.aluPkg.all;

package executeAddressCalcPkg is
    component executeAddressCalc is
        port (
            clock      : in std_logic;
            reset      : in std_logic;
            pcIn       : in instructionAddrType;
            addressInX : in regAddrType;
            opcIn      : in opcType;
            dataInY    : in dataWordType;
            dataInZ    : in dataWordType;
            immediate  : in immType;

            pcOverrideFlag : out std_logic;
            pcOverride     : out instructionAddrType;
            addressOutX    : out regAddrType;
            opcOut         : out opcType;
            aluOut         : out dataWordType;
            dataOutZ       : out dataWordType
        );
    end component executeAddressCalc;
end package executeAddressCalcPkg;

---------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;
use work.aluPkg.all;
use work.executeAddressCalcPkg.all;

entity executeAddressCalc is
    port (
        clock      : in std_logic;
        reset      : in std_logic;
        pcIn       : in instructionAddrType;
        addressInX : in regAddrType;
        opcIn      : in opcType;
        dataInY    : in dataWordType;
        dataInZ    : in dataWordType;
        immediate  : in immType;

        pcOverrideFlag : out std_logic;
        pcOverride     : out instructionAddrType;
        addressOutX    : out regAddrType;
        opcOut         : out opcType;
        aluOut         : out dataWordType;
        dataOutZ       : out dataWordType
    );
end entity executeAddressCalc;

architecture executeAddressCalcModel of executeAddressCalc is
    signal aluOutInternal : dataWordType;
    signal aluFlag        : std_logic;

begin
    alu_1 : alu port map(opcIn, dataInY, dataInZ, immediate, pcIn, aluFlag, aluOutInternal);

    executeAddressCalcP : process (clock, reset) is
    begin
        if reset = '1' then
            aluFlag        <= '0';
            opcOut         <= opcNoOp;
            pcOverrideFlag <= '0';
        elsif rising_edge(clock) then
            opcOut <= opcIn;

            if (opcIn(5 downto 4) = "11") then -- Jump befehl
                pcOverrideFlag <= '1';
            else
                pcOverrideFlag <= '0';
            end if;
            pcOverride <= std_logic_vector(aluOutInternal(instructionAddrLength - 1 downto 0));

            aluOut <= aluOutInternal;

            if (opcIn = opcJsr) then
                dataOutZ    <= sixteenZeros & signed(pcIn);
                addressOutX <= jsrRegAddr;
            else
                dataOutZ    <= dataInZ;
                addressOutX <= addressInX;
            end if;

            if (opcIn(opcLength - 3 downto opcLength - 4) = "10") then -- compare
                aluFlag <= aluOutInternal(0);
            end if;
        end if;
    end process;
end architecture executeAddressCalcModel;
