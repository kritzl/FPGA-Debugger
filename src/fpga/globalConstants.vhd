library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package globalConstants is
    -- region === Hardware ===
    -- 13 is the fastest our arduino debugger (with direct serial output) can do
    constant CLOCK_INDEX : integer := 15; -- für de0Board.vhd die Position im Counter -> Stellt ein, wie schnell der Prozessor läuft
    -- endregion --- Hardware ---

    -- region === lengths ===
    constant dataWordLength        : integer := 32;
    constant opcLength             : integer := 8;
    constant immLength             : integer := dataWordLength;
    constant regAddrLength         : integer := 8;
    constant regBankSize           : integer := 256;
    constant instructionAddrLength : integer := 16;
    constant instructionWordLength : integer := 32;
    constant ramAddrLength         : integer := 32;
    -- endregion --- lengths ---

    -- region === subtypes ===
    subtype dataWordType is signed(dataWordLength - 1 downto 0);
    subtype opcType is std_logic_vector(opcLength - 1 downto 0);
    subtype immType is signed(immLength - 1 downto 0);
    subtype regAddrType is std_logic_vector(regAddrLength - 1 downto 0);
    subtype instructionAddrType is std_logic_vector(instructionAddrLength - 1 downto 0);
    subtype instructionWordType is std_logic_vector(instructionWordLength - 1 downto 0);
    subtype byteType is std_logic_vector(7 downto 0);
    subtype ramAddrType is std_logic_vector(ramAddrLength - 1 downto 0);
    -- endregion --- subtypes ---   

    -- region === instructionFetch ---
    constant instructionAddressIncrement : instructionAddrType := std_logic_vector(to_unsigned(1, instructionAddrLength));
    -- endregion --- instructionFetch ---

    -- region === opc ===
    constant opcNoOp : opcType := "00000000";
    constant opcMov  : opcType := "01000000";
    constant opcAdd  : opcType := "01000001";
    constant opcSub  : opcType := "01000010";
    constant opcAnd  : opcType := "01000011";
    constant opcOr   : opcType := "01000100";
    constant opcXor  : opcType := "01000101";
    constant opcNot  : opcType := "01000110";
    constant opcLsl  : opcType := "01010000";
    constant opcLsr  : opcType := "01010001";
    constant opcAsr  : opcType := "01010010";

    constant opcCmpe   : opcType := "01100000";
    constant opcCmpne  : opcType := "01100001";
    constant opcCmplt  : opcType := "01100010";
    constant opcCmplte : opcType := "01100011";

    constant opcMovI  : opcType := "11001100";
    constant opcMovHI : opcType := "11001101";
    constant opcMovcI : opcType := "11001110";
    constant opcAddI  : opcType := "01001100";
    constant opcAddSI : opcType := "11001111";
    constant opcSubI  : opcType := "01001101";
    constant opcSubSI : opcType := "11011100";
    constant opcAndI  : opcType := "01001110";
    constant opcAndSI : opcType := "11011101";
    constant opcOrI  : opcType := "01011110";
    constant opcOrSI : opcType := "11011110";
    constant opcLslI  : opcType := "01001111";
    constant opcLsrI  : opcType := "01011100";
    constant opcAsrI  : opcType := "01011101";

    constant opcLdw : opcType := "01011111";
    constant opcStw : opcType := "00011100";

    constant opcJmp   : opcType := "10110000";
    constant opcJmpI  : opcType := "10111000";
    constant opcJsr   : opcType := "11111000";
    constant opcJmpt  : opcType := "10111001";
    constant opcJmptF : opcType := "10111010";
    constant opcJmpf  : opcType := "10111011";
    constant opcJmpfF : opcType := "10111100";

    constant opcHalt : opcType := "11111111";
    -- endregion --- opc ---

    -- fixed data word values (because we don't know how to generate them inplace)
    constant instructionAddressZero : instructionAddrType := "0000000000000000";
    constant dataWordZero           : dataWordType        := "00000000000000000000000000000000";
    constant dataWordOne            : dataWordType        := "00000000000000000000000000000001";
    constant sixteenZeros           : signed(15 downto 0) := "0000000000000000";
    -- highest Adress in Register
    constant jsrRegAddr : regAddrType := "11111111";

    -- initial values
    constant initInstructionAddress : instructionAddrType := std_logic_vector(to_unsigned(0, instructionAddrLength));

    constant nullRegAddr : regAddrType := std_logic_vector(to_unsigned(0, regAddrLength));

    constant noOpInstruction : instructionWordType := std_logic_vector(to_unsigned(0, instructionWordLength));

end package globalConstants;
