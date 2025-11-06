library ieee;
use ieee.std_logic_1164.all;

entity bit_adder is
  port (
    a_in  : in  std_logic;
    b_in  : in  std_logic;
    c_in  : in  std_logic;
    s_out : out std_logic;
    c_out : out std_logic
  );
end entity;

architecture Behavioral of bit_adder is
begin
  s_out <= a_in xor b_in xor c_in;
  c_out <= (a_in and b_in) or (a_in and c_in) or (b_in and c_in);
end architecture;