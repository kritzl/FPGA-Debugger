library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;

package instructionFetchPkg is
    component instructionFetch is
        port (
            clock          : in std_logic;
            reset          : in std_logic;
            pcOverrideFlag : in std_logic;
            pcOverride     : in instructionAddrType;

            pcOut          : out instructionAddrType;
            instructionOut : out instructionWordType
        );
    end component instructionFetch;
end package instructionFetchPkg;

---------- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globalConstants.all;
use work.instructionFetchPkg.all;

use work.instructionMemory;

entity instructionFetch is
    port (
        clock          : in std_logic;
        reset          : in std_logic;
        pcOverrideFlag : in std_logic;
        pcOverride     : in instructionAddrType;

        pcOut          : out instructionAddrType;
        instructionOut : out instructionWordType
    );
end entity instructionFetch;

architecture instructionFetchModel of instructionFetch is
    signal internalPC             : instructionAddrType;
    signal internalInstructionOut : instructionWordType; -- we need this for the reset
begin

    instructionMemory_1 : instructionMemory port map(internalPC(12 downto 0), clock, internalInstructionOut);

    pcOut <= internalPC;

    instructionOutP : process (reset, internalInstructionOut) is
    begin
        -- Not only checking here for reset = 1, but also that instructionMemory is not reading opcHalt.
        -- This is necessary because if the code completed, then we are reading opcHalt (this fixes the second run).
        -- So after fallingedge(reset) we would still read opcHalt, since there was no clock cycle that changed the output of instructionMemory.
        -- Then in de0board we would halt immediately, because we think that the processor reached halt.
        if reset = '1' or (internalPC = instructionAddressZero and internalInstructionOut(instructionWordLength - 1 downto instructionWordLength - 8) = opcHalt) then
            instructionOut <= noOpInstruction;
        else
            instructionOut <= internalInstructionOut;
        end if;
    end process;

    instructionFetchP : process (clock, reset) is
    begin
        if reset = '1' then
            internalPC <= initInstructionAddress;
        elsif rising_edge(clock) then
            if pcOverrideFlag = '1' then
                internalPC <= pcOverride;
            else
                internalPC <= std_logic_vector(unsigned(internalPC) + unsigned(instructionAddressIncrement));
            end if;
        end if;
    end process;

end architecture instructionFetchModel;
