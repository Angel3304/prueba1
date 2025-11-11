library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- para to_integer(unsigned(...))

package Seven_Segment_Pkg is
  ----------------------------------------------------------------
  -- Sub‑tipo para el patrón de 7 segmentos.
  ----------------------------------------------------------------
  subtype seg7_t is std_logic_vector(6 downto 0);

  ----------------------------------------------------------------
  -- Función de decodificación.
  ----------------------------------------------------------------
  function decode_to_segments (
        nibble : std_logic_vector(3 downto 0)
    ) return seg7_t;
end package Seven_Segment_Pkg;

--------------------------------------------------------------------
package body Seven_Segment_Pkg is

  -- Constantes con los patrones (gfedcba)
  constant SEG_0 : seg7_t := "0000001";
  constant SEG_1 : seg7_t := "1001111";
  constant SEG_2 : seg7_t := "0010010";
  constant SEG_3 : seg7_t := "0000110";
  constant SEG_4 : seg7_t := "1001100";
  constant SEG_5 : seg7_t := "0100100";
  constant SEG_6 : seg7_t := "0100000";
  constant SEG_7 : seg7_t := "0001111";
  constant SEG_8 : seg7_t := "0000000";
  constant SEG_9 : seg7_t := "0000100";
  constant SEG_ERR : seg7_t := "1111111";

  function decode_to_segments (
        nibble : std_logic_vector(3 downto 0)
    ) return seg7_t is
    variable seg : seg7_t;
  begin
    case to_integer(unsigned(nibble)) is
      when 0  => seg := SEG_0;
      when 1  => seg := SEG_1;
      when 2  => seg := SEG_2;
      when 3  => seg := SEG_3;
      when 4  => seg := SEG_4;
      when 5  => seg := SEG_5;
      when 6  => seg := SEG_6;
      when 7  => seg := SEG_7;
      when 8  => seg := SEG_8;
      when 9  => seg := SEG_9;
      when others => seg := SEG_ERR;
    end case;
    return seg;
  end decode_to_segments;

end package body Seven_Segment_Pkg;