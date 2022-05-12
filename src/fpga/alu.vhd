library ieee;
use ieee.std_logic_1164.all;
use work.globalConstants.all;
use ieee.numeric_std.all;

package aluPkg is
    component alu is
        port (
            opc       : in opcType;      -- ALU.OPC ausm decoder	
            y         : in dataWordType; -- Y ausm Register	
            z         : in dataWordType; -- Z ausm Register
            immediate : in immType;      -- Immediate ausm decoder
            pc        : in instructionAddrType;
            flag      : in std_logic;

            dataOut : out dataWordType -- output auf bus
        );
    end component alu;
end package aluPkg;

--------

library ieee;
use ieee.std_logic_1164.all;
use work.globalConstants.all;
use ieee.numeric_std.all;

entity alu is
    port (
        opc       : in opcType;      -- ALU.OPC ausm decoder	
        y         : in dataWordType; -- Y ausm Register	
        z         : in dataWordType; -- Z ausm Register
        immediate : in immType;      -- Immediate ausm decoder
        pc        : in instructionAddrType;
        flag      : in std_logic;

        dataOut : out dataWordType -- output auf bus
    );
end entity alu;

architecture aluModel of alu is

    function compareF (compare : boolean) return dataWordType is
    begin
        if (compare) then
            return to_signed(1, dataWordLength);
        else
            return to_signed(0, dataWordLength);
        end if;
    end compareF;

begin
    aluP : process (opc, y, z, immediate, pc, flag) is
    begin
        dataOut <= (others => '-'); -- zunächst auf don't care setzen. Dann ist es egal, ob wir in ein "when" reinlaufen. VHDL nimmt immer die "<="-Zuweisung, die zuletzt kam
        -- achtung, wenn hier kein neuer wert gesetzt wird bricht das Programm ab
        case opc is
            when opcNoOp => dataOut <= dataWordZero;
            when opcMov  => dataOut  <= y;
            when opcAdd  => dataOut  <= y + z;
            when opcSub  => dataOut  <= y - z;
            when opcAnd  => dataOut  <= y and z;
            when opcOr   => dataOut   <= y or z;
            when opcXor  => dataOut  <= y xor z;
            when opcNot  => dataOut  <= not y;
            when opcLsl  =>
                case z(0) is
                    when '0'    => dataOut <= y(dataWordLength - 2 downto 0) & '0';
                    when '1'    => dataOut <= y(dataWordLength - 17 downto 0) & sixteenZeros;
                    when others =>
                        report "ALU - Illegal shift parameter"
                            severity error;
                end case;
            when opcLsr =>
                case z(0) is
                    when '0'    => dataOut <= '0' & y(dataWordLength - 1 downto 1);
                    when '1'    => dataOut <= sixteenZeros & y(dataWordLength - 1 downto 16);
                    when others =>
                        report "ALU - Illegal shift parameter"
                            severity error;
                end case;
            when opcAsr =>
                case z(0) is
                    when '0'    => dataOut <= y(dataWordLength - 1) & y(dataWordLength - 1 downto 1);
                    when '1' => dataOut <= (15 downto 0 => y(dataWordLength - 1)) & y(dataWordLength - 1 downto 16);
                    when others =>
                        report "ALU - Illegal shift parameter"
                            severity error;
                end case;

            when opcCmpe   => dataOut   <= compareF(y = z);
            when opcCmpne  => dataOut  <= compareF(y /= z);
            when opcCmplt  => dataOut  <= compareF(y < z);
            when opcCmplte => dataOut <= compareF(y <= z);

            when opcMovI  => dataOut  <= immediate;
            when opcMovHI => dataOut <= not immediate;
                -- TODO: Implement this
                report "ALU - MOV_H_I is not implemented correctly, yet! It just negates"
                    severity warning;
            when opcMovcI => dataOut <= not immediate;
                -- TODO: Implement this. Maybe `-immediate` just works?
                report "ALU - MOVC_I is not implemented correctly, yet! It just negates"
                    severity warning;
            when opcAddI  => dataOut  <= z + immediate;
            when opcAddSI => dataOut <= y + immediate;
            when opcSubI  => dataOut  <= z - immediate;
            when opcSubSI => dataOut <= y - immediate;
            when opcAndI  => dataOut  <= z and immediate;
            when opcAndSI => dataOut <= y and immediate;
            when opcOrI  => dataOut  <= z or immediate;
            when opcOrSI => dataOut <= y or immediate;
                -- TODO redundante teile auslagern
            when opcLslI =>
                case immediate(0) is
                    when '0'    => dataOut <= z(dataWordLength - 2 downto 0) & '0';
                    when '1'    => dataOut <= z(dataWordLength - 17 downto 0) & sixteenZeros;
                    when others =>
                        report "ALU - Illegal shift parameter"
                            severity error;
                end case;
            when opcLsrI =>
                case immediate(0) is
                    when '0'    => dataOut <= '0' & z(dataWordLength - 1 downto 1);
                    when '1'    => dataOut <= sixteenZeros & z(dataWordLength - 1 downto 16);
                    when others =>
                        report "ALU - Illegal shift parameter"
                            severity error;
                end case;
            when opcAsrI =>
                case immediate(0) is
                    when '0'    => dataOut <= z(dataWordLength - 1) & z(dataWordLength - 1 downto 1);
                    when '1' => dataOut <= (15 downto 0 => z(dataWordLength - 1)) & z(dataWordLength - 1 downto 16);
                    when others =>
                        report "ALU - Illegal shift parameter"
                            severity error;
                end case;

            when opcLdw => dataOut <= z + immediate;
            when opcStw => dataOut <= y + immediate;

                -- write remaining op Codes
                -- TODO and check all other because of jahob changes
            when opcJmp  => dataOut  <= y;
            when opcJmpI => dataOut <= immediate;
            when opcJsr  => dataOut  <= immediate;
            when opcJmpt =>
                if (y(0) = '1') then
                    dataOut <= immediate;
                else
                    dataOut <= sixteenZeros & signed(pc);
                end if;
            when opcJmptF =>
                if (flag = '1') then
                    dataOut <= immediate;
                else
                    dataOut <= sixteenZeros & signed(pc);
                end if;
            when opcJmpf =>
                if (y(0) = '0') then
                    dataOut <= immediate;
                else
                    dataOut <= sixteenZeros & signed(pc);
                end if;
            when opcJmpfF =>
                if (flag = '0') then
                    dataOut <= immediate;
                else
                    dataOut <= sixteenZeros & signed(pc);
                end if;
            when opcHalt =>
                dataOut <= "01010101010101111101010101010101";
                report "ALU - halt"
                    severity warning;

            when others =>
                dataOut <= dataWordZero;
                report "ALU - unknown OPCode"
                    severity error;
        end case;
    end process;
end architecture aluModel;
