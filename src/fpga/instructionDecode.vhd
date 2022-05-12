library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;
use work.registerbank;

package instructionDecodePkg is
    component instructionDecode is
        port (
            clock         : in std_logic;
            reset         : in std_logic;
            pcIn          : in instructionAddrType;
            instructionIn : in instructionWordType;
            writeBackAddr : in regAddrType;
            writeBackData : in dataWordType;
            writeBackFlag : in std_logic;

            pcOut       : out instructionAddrType;
            addressOutX : out regAddrType;
            dataOutY    : out dataWordType;
            dataOutZ    : out dataWordType;
            immediate   : out immType;
            opcOut      : out opcType
        );
    end component instructionDecode;
end package instructionDecodePkg;

---------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;
use work.registerbank;
use work.instructionDecodePkg.all;

entity instructionDecode is
    port (
        clock         : in std_logic;
        reset         : in std_logic;
        pcIn          : in instructionAddrType;
        instructionIn : in instructionWordType;
        writeBackAddr : in regAddrType;
        writeBackData : in dataWordType;
        writeBackFlag : in std_logic;

        pcOut       : out instructionAddrType;
        addressOutX : out regAddrType;
        dataOutY    : out dataWordType;
        dataOutZ    : out dataWordType;
        immediate   : out immType;
        opcOut      : out opcType
    );
end entity instructionDecode;

architecture instructionDecodeModel of instructionDecode is
    signal bankAddrY    : regAddrType;
    signal bankAddrZ    : regAddrType;
    signal bankDataOutY : dataWordType;
    signal bankDataOutZ : dataWordType;

    signal opcTemp    : opcType; -- firstByte
    signal secondByte : byteType;
    signal thirdByte  : byteType;
    signal fourthByte : byteType;

begin
    regBank : registerbank port map
    (
        clock,         -- clock         : in std_logic;
        bankAddrY,     -- addrY         : in regAddrType;
        bankAddrZ,     -- addrZ         : in regAddrType;
        writeBackAddr, -- writeBackAddr : in regAddrType;
        writeBackData, -- writeBackData : in dataWordType;
        writeBackFlag, -- writeBackFlag : in std_logic;

        bankDataOutY, -- dataY : out dataWordType;
        bankDataOutZ  -- dataZ : out dataWordType
    );

    -- splitting the incoming instruction into 4 bytes
    opcTemp    <= instructionIn(instructionWordLength - 1 downto instructionWordLength - 8);
    secondByte <= instructionIn(instructionWordLength - 9 downto instructionWordLength - 16);
    thirdByte  <= instructionIn(instructionWordLength - 17 downto instructionWordLength - 24);
    fourthByte <= instructionIn(instructionWordLength - 25 downto 0);

    instructionDecodeP : process (clock, reset) is
    begin
        if reset = '1' then
            opcOut <= opcNoOp;
        elsif rising_edge(clock) then
            pcOut       <= pcIn;
            addressOutX <= secondByte;
            dataOutY    <= bankDataOutY;
            dataOutZ    <= bankDataOutZ;

            opcOut <= opcTemp;

            if opcTemp(7) = '1' then -- alle mit 2 byte immediate
                immediate(7 downto 0)   <= signed(fourthByte);
                immediate(15 downto 8)  <= signed(thirdByte);
                immediate(31 downto 16) <= (others => '0');
            else -- alle mit einem Byte immediate und beim rest ist es egal
                immediate(7 downto 0)  <= signed(thirdByte);
                immediate(31 downto 8) <= (others => '0');
            end if;
        end if;
    end process;

    setRegisterAdresses : process (opcTemp, secondByte, thirdByte, fourthByte) is
    begin
        -- set the new bank adresses
        -- we set the addresses sometimes wrongly, if they are not needed. Thats okay, because that's dont care data
        -- we abuse the Y for the X in the cases that there is no Y in the data (because we have immediate)
        if opcTemp(4) = '1' then -- immediate existiert
            bankAddrY <= secondByte;
        else
            bankAddrY <= thirdByte;
        end if;

        bankAddrZ <= fourthByte; -- andere Bits
    end process;

end architecture instructionDecodeModel;
