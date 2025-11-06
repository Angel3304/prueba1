library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_Store is
  port(
    Addr_in  : in  std_logic_vector(7 downto 0);
    Data_bus : out std_logic_vector(23 downto 0)
  );
end entity;

architecture Behavioral of Memory_Store is

  constant OP_LDX   : std_logic_vector(7 downto 0) := x"01";
  constant OP_LDY   : std_logic_vector(7 downto 0) := x"02";
  constant OP_ADD   : std_logic_vector(7 downto 0) := x"03";
  constant OP_ADDI  : std_logic_vector(7 downto 0) := x"04";
  constant OP_DISP  : std_logic_vector(7 downto 0) := x"06";
  constant OP_JUMP  : std_logic_vector(7 downto 0) := x"07";
  constant OP_BR_NZ : std_logic_vector(7 downto 0) := x"08";
  constant OP_SUB   : std_logic_vector(7 downto 0) := x"09";
  constant OP_WAIT  : std_logic_vector(7 downto 0) := x"0A";
  constant OP_STOP  : std_logic_vector(7 downto 0) := x"0F";

  type t_mem_array is array (0 to 255) of std_logic_vector(23 downto 0);

  constant Program_Data : t_mem_array := (
    0  => OP_LDX   & x"80" & x"00",
    1  => OP_ADDI  & x"00" & x"05",
    2  => OP_DISP  & x"00" & x"00",
    3  => OP_LDX   & x"8A" & x"00",
    4  => OP_LDY   & x"8B" & x"00",
    5  => OP_WAIT  & x"00" & x"00",
    6  => OP_SUB   & x"00" & x"00",
    7  => OP_BR_NZ & x"05" & x"00",
    
    8  => OP_LDX   & x"81" & x"00",
    9  => OP_ADDI  & x"00" & x"06",
    10 => OP_DISP  & x"00" & x"00",
    11 => OP_LDX   & x"8A" & x"00",
    12 => OP_LDY   & x"8B" & x"00",
    13 => OP_WAIT  & x"00" & x"00",
    14 => OP_SUB   & x"00" & x"00",
    15 => OP_BR_NZ & x"0D" & x"00",
    
    16 => OP_LDX   & x"82" & x"00",
    17 => OP_ADDI  & x"00" & x"07",
    18 => OP_DISP  & x"00" & x"00",
    19 => OP_LDX   & x"8A" & x"00",
    20 => OP_LDY   & x"8B" & x"00",
    21 => OP_WAIT  & x"00" & x"00",
    22 => OP_SUB   & x"00" & x"00",
    23 => OP_BR_NZ & x"15" & x"00",

    24 => OP_LDX   & x"83" & x"00",
    25 => OP_ADDI  & x"00" & x"08",
    26 => OP_DISP  & x"00" & x"00",
    27 => OP_LDX   & x"8A" & x"00",
    28 => OP_LDY   & x"8B" & x"00",
    29 => OP_WAIT  & x"00" & x"00",
    30 => OP_SUB   & x"00" & x"00",
    31 => OP_BR_NZ & x"1D" & x"00",

    32 => OP_LDX   & x"84" & x"00",
    33 => OP_ADDI  & x"00" & x"09",
    34 => OP_DISP  & x"00" & x"00",
    35 => OP_LDX   & x"8A" & x"00",
    36 => OP_LDY   & x"8B" & x"00",
    37 => OP_WAIT  & x"00" & x"00",
    38 => OP_SUB   & x"00" & x"00",
    39 => OP_BR_NZ & x"25" & x"00",

    40 => OP_LDX   & x"85" & x"00",
    41 => OP_ADDI  & x"00" & x"0A",
    42 => OP_DISP  & x"00" & x"00",
    43 => OP_LDX   & x"8A" & x"00",
    44 => OP_LDY   & x"8B" & x"00",
    45 => OP_WAIT  & x"00" & x"00",
    46 => OP_SUB   & x"00" & x"00",
    47 => OP_BR_NZ & x"2D" & x"00",

    48 => OP_LDX   & x"86" & x"00",
    49 => OP_ADDI  & x"00" & x"0B",
    50 => OP_DISP  & x"00" & x"00",
    51 => OP_LDX   & x"8A" & x"00",
    52 => OP_LDY   & x"8B" & x"00",
    53 => OP_WAIT  & x"00" & x"00",
    54 => OP_SUB   & x"00" & x"00",
    55 => OP_BR_NZ & x"35" & x"00",

    56 => OP_LDX   & x"87" & x"00",
    57 => OP_ADDI  & x"00" & x"0C",
    58 => OP_DISP  & x"00" & x"00",
    59 => OP_LDX   & x"8A" & x"00",
    60 => OP_LDY   & x"8B" & x"00",
    61 => OP_WAIT  & x"00" & x"00",
    62 => OP_SUB   & x"00" & x"00",
    63 => OP_BR_NZ & x"3D" & x"00",

    64 => OP_LDX   & x"88" & x"00",
    65 => OP_ADDI  & x"00" & x"0D",
    66 => OP_DISP  & x"00" & x"00",
    67 => OP_LDX   & x"8A" & x"00",
    68 => OP_LDY   & x"8B" & x"00",
    69 => OP_WAIT  & x"00" & x"00",
    70 => OP_SUB   & x"00" & x"00",
    71 => OP_BR_NZ & x"45" & x"00",
    
    72 => OP_LDX   & x"89" & x"00",
    73 => OP_ADDI  & x"00" & x"0E",
    74 => OP_DISP  & x"00" & x"00",
    75 => OP_LDX   & x"8A" & x"00",
    76 => OP_LDY   & x"8B" & x"00",
    77 => OP_WAIT  & x"00" & x"00",
    78 => OP_SUB   & x"00" & x"00",
    79 => OP_BR_NZ & x"4D" & x"00",
    80 => OP_JUMP  & x"48" & x"00",
    
    81 => OP_STOP  & x"00" & x"00",

    128 => std_logic_vector(to_unsigned(105, 24)),
    129 => std_logic_vector(to_unsigned(10, 24)),
    130 => std_logic_vector(to_unsigned(65, 24)),
    131 => std_logic_vector(to_unsigned(50, 24)),
    132 => std_logic_vector(to_unsigned(129, 24)),
    133 => std_logic_vector(to_unsigned(400, 24)),
    134 => std_logic_vector(to_unsigned(783, 24)),
    135 => std_logic_vector(to_unsigned(15, 24)),
    136 => std_logic_vector(to_unsigned(230, 24)),
    137 => std_logic_vector(to_unsigned(3230, 24)),
    
    138 => std_logic_vector(to_unsigned(5, 24)),
    139 => std_logic_vector(to_unsigned(1, 24)),

    others => (others => '0')
  );

begin
  Data_bus <= Program_Data(to_integer(unsigned(Addr_in)));
end architecture;