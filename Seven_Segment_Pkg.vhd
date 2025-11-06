library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Seven_Segment_Pkg is
  function decode_to_segments (nibble : std_logic_vector(3 downto 0)) 
    return std_logic_vector(6 downto 0);
end package Seven_Segment_Pkg;

package body Seven_Segment_Pkg is

  function decode_to_segments (nibble : std_logic_vector(3 downto 0)) 
    return std_logic_vector(6 downto 0) is
    variable segments : std_logic_vector(6 downto 0);
  begin
    case nibble is
      when x"0"   => segments := "0000001";
      when x"1"   => segments := "1001111";
      when x"2"   => segments := "0010010";
      when x"3"   => segments := "0000110";
      when x"4"   => segments := "1001100";
      when x"5"   => segments := "0100100";
      when x"6"   => segments := "0100000";
      when x"7"   => segments := "0001111";
      when x"8"   => segments := "0000000";
      when x"9"   => segments := "0000100";
      when others => segments := "1111111";
    end case;
    return segments;
  end function decode_to_segments;
  
end package body Seven_Segment_Pkg;