library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;

package registerbankPkg is
    component registerbank is
        port (
            clock         : in std_logic;
            addrY         : in regAddrType;
            addrZ         : in regAddrType;
            writeBackAddr : in regAddrType;
            writeBackData : in dataWordType;
            writeBackFlag : in std_logic;

            dataY : out dataWordType;
            dataZ : out dataWordType
        );
    end component registerbank;
end package registerbankPkg;

---------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;
use work.registerbankPkg.all;

entity registerbank is
    port (
        clock         : in std_logic;
        addrY         : in regAddrType;
        addrZ         : in regAddrType;
        writeBackAddr : in regAddrType;
        writeBackData : in dataWordType;
        writeBackFlag : in std_logic;

        dataY : out dataWordType;
        dataZ : out dataWordType
    );
end entity registerbank;

architecture registerbankModel of registerbank is
    type regBankType is array (regBankSize downto 0) of dataWordType;
    signal regBank : regBankType;
begin
    dataY <= regBank(to_integer(unsigned(addrY)));
    dataZ <= regBank(to_integer(unsigned(addrZ)));

    registerbankP : process (clock) is
    begin
        if falling_edge(clock) then
            if writeBackFlag = '1' then
                regBank(to_integer(unsigned(writeBackAddr))) <= writeBackData;
            end if;
        end if;
    end process;

end architecture registerbankModel;
