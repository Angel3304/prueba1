--------------------------------------------------------------------
--  Seven‑Segment display package
--  Author : <tu nombre>
--  Fecha  : <fecha>
--  Descripción:  Convierte un nibble (4‑bits) en los 7 bits que
--                controlan un display de 7 segmentos (a‑g).
--                El vector de salida está ordenado como
--                "gfedcba" (bit 6 = g, bit 0 = a). Cambia el orden
--                si tu hardware necesita otra convención.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;        -- to_integer(unsigned(...))

package Seven_Segment_Pkg is

  ----------------------------------------------------------------
  -- Sub‑tipo para el patrón de 7 segmentos.
  ----------------------------------------------------------------
  subtype seg7_t is std_logic_vector(6 downto 0);

  ----------------------------------------------------------------
  -- Función de decodificación.
  -- Si tu proyecto está compilado como VHDL‑87 elimina la palabra
  -- "pure". En VHDL‑93 o superiores se puede dejar.
  ----------------------------------------------------------------
  function decode_to_segments (
        nibble : std_logic_vector(3 downto 0)
    ) return seg7_t;   -- <-- ya no hay índice en la declaración

end Seven_Segment_Pkg;

--------------------------------------------------------------------
--  Cuerpo del paquete
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package body Seven_Segment_Pkg is

  ----------------------------------------------------------------
  -- Constantes con los patrones de segmentos.
  -- Formato: "gfedcba"
  ----------------------------------------------------------------
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
  constant SEG_ERR : seg7_t := "1111111";   -- para valores 10‑15

  ----------------------------------------------------------------
  -- Implementación de la función.
  ----------------------------------------------------------------
  function decode_to_segments (
        nibble : std_logic_vector(3 downto 0)
    ) return seg7_t is
    variable seg : seg7_t;
  begin
    -- Convertimos el vector a entero (0 … 15) y usamos CASE.
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
      when others => seg := SEG_ERR;      -- 10‑15
    end case;
    return seg;
  end decode_to_segments;

end Seven_Segment_Pkg;
