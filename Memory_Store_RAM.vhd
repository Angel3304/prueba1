library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_Store is
  port(
    clk      : in  std_logic;
    we       : in  std_logic;
    Addr_in  : in  std_logic_vector(7 downto 0);
    Data_in  : in  std_logic_vector(23 downto 0);
    Data_out : out std_logic_vector(23 downto 0)
  );
end entity;

architecture Behavioral of Memory_Store is

  -- Opcodes
  constant OP_LDX   : std_logic_vector(7 downto 0) := x"01";
  constant OP_LDY   : std_logic_vector(7 downto 0) := x"02";
  constant OP_ADD   : std_logic_vector(7 downto 0) := x"03";
  constant OP_ADDI  : std_logic_vector(7 downto 0) := x"04";
  constant OP_CMP   : std_logic_vector(7 downto 0) := x"05";
  constant OP_DISP  : std_logic_vector(7 downto 0) := x"06";
  constant OP_JUMP  : std_logic_vector(7 downto 0) := x"07";
  constant OP_BR_NZ : std_logic_vector(7 downto 0) := x"08";
  constant OP_SUB   : std_logic_vector(7 downto 0) := x"09";
  constant OP_WAIT  : std_logic_vector(7 downto 0) := x"0A";
  constant OP_BS    : std_logic_vector(7 downto 0) := x"0B";
  constant OP_BNC   : std_logic_vector(7 downto 0) := x"0C";
  constant OP_BNV   : std_logic_vector(7 downto 0) := x"0D";
  constant OP_MUL   : std_logic_vector(7 downto 0) := x"0E";
  constant OP_STOP  : std_logic_vector(7 downto 0) := x"0F";
  constant OP_DIV   : std_logic_vector(7 downto 0) := x"10";
  constant OP_STX   : std_logic_vector(7 downto 0) := x"11";

  type t_mem_array is array (0 to 255) of std_logic_vector(23 downto 0);
  
  signal mem_array : t_mem_array := (
    -- (PC=0) Selector
    0  => OP_LDX   & x"F0" & x"00", -- Leer switches
    1  => OP_STX   & x"BF" & x"00", -- Guardar switch
    2  => OP_LDY   & x"A6" & x"00", -- Y = 0
    3  => OP_CMP   & x"00" & x"00", -- X vs 0
    4  => OP_BR_NZ & x"07" & x"00", 
    5  => OP_JUMP  & x"17" & x"00", -- Ir a A (PC 23)
    6  => (others => '0'),

    -- (PC=7) Check 1
    7  => OP_LDX   & x"BF" & x"00", 
    8  => OP_LDY   & x"A5" & x"00", -- Y = 1
    9  => OP_CMP   & x"00" & x"00", 
    10 => OP_BR_NZ & x"0D" & x"00", 
    11 => OP_JUMP  & x"2E" & x"00", -- Ir a B (PC 46)
    12 => (others => '0'),

    -- (PC=13) Check 2
    13 => OP_LDX   & x"BF" & x"00", 
    14 => OP_LDY   & x"A4" & x"00", -- Y = 2
    15 => OP_CMP   & x"00" & x"00", 
    16 => OP_BR_NZ & x"14" & x"00", 
    17 => OP_JUMP  & x"43" & x"00", -- Ir a C (PC 67)
    18 => (others => '0'),
    19 => (others => '0'),

    -- (PC=20) Eq D
    20 => OP_LDX   & x"A6" & x"00", 
    21 => OP_DISP  & x"00" & x"00", 
    22 => OP_STOP  & x"00" & x"00", 
    
    -- INICIO_EQ_A (PC=23)
    23 => OP_LDX   & x"A0" & x"00", -- X=3
    24 => OP_LDY   & x"AE" & x"00", -- Y=17
    25 => OP_MUL   & x"00" & x"00", 
    26 => OP_STX   & x"D0" & x"00", 
    27 => OP_LDX   & x"A1" & x"00", -- X=2
    28 => OP_LDY   & x"AB" & x"00", -- Y=25
    29 => OP_MUL   & x"00" & x"00", 
    30 => OP_STX   & x"D1" & x"00", 
    31 => OP_LDX   & x"A3" & x"00", -- X=40
    32 => OP_LDY   & x"AC" & x"00", -- Y=4
    33 => OP_DIV   & x"00" & x"00", 
    34 => OP_STX   & x"D2" & x"00", 
    35 => OP_LDX   & x"D0" & x"00", 
    36 => OP_LDY   & x"D1" & x"00", 
    37 => OP_ADD   & x"00" & x"00", 
    38 => OP_LDY   & x"D2" & x"00", 
    39 => OP_SUB   & x"00" & x"00", 
    40 => OP_STX   & x"D3" & x"00", 
    41 => OP_JUMP  & x"61" & x"00", -- Ir a COMUN (PC 97 - CORREGIDO)
    42 => (others => '0'),
    43 => (others => '0'),
    44 => (others => '0'),
    45 => (others => '0'),

    -- INICIO_EQ_B (PC=46)
    46 => OP_LDX   & x"A0" & x"00", -- X=3
    47 => OP_LDY   & x"A0" & x"00", 
    48 => OP_MUL   & x"00" & x"00", -- X^2
    49 => OP_LDY   & x"B0" & x"00", -- Y=10
    50 => OP_MUL   & x"00" & x"00", 
    51 => OP_STX   & x"D0" & x"00", 
    52 => OP_LDX   & x"A0" & x"00", 
    53 => OP_LDY   & x"B1" & x"00", -- Y=30
    54 => OP_MUL   & x"00" & x"00", 
    55 => OP_STX   & x"D1" & x"00", 
    56 => OP_LDX   & x"A2" & x"00", -- Z=80
    57 => OP_LDY   & x"A4" & x"00", -- Y=2
    58 => OP_DIV   & x"00" & x"00", 
    59 => OP_STX   & x"D2" & x"00", 
    60 => OP_LDX   & x"D0" & x"00", 
    61 => OP_LDY   & x"D1" & x"00", 
    62 => OP_ADD   & x"00" & x"00", 
    63 => OP_LDY   & x"D2" & x"00", 
    64 => OP_SUB   & x"00" & x"00", 
    65 => OP_STX   & x"D3" & x"00", 
    66 => OP_JUMP  & x"61" & x"00", -- Ir a COMUN (PC 97 - CORREGIDO)

    -- INICIO_EQ_C (PC=67) - ¡CORREGIDO!
    67 => OP_LDX   & x"A0" & x"00", -- X=3
    68 => OP_LDY   & x"A0" & x"00", 
    69 => OP_MUL   & x"00" & x"00", -- X^2
    70 => OP_LDY   & x"A0" & x"00", 
    71 => OP_MUL   & x"00" & x"00", -- X^3
    
    -- (Aquí estaba el error. Ahora usamos un puente)
    72 => OP_STX   & x"B3" & x"00", -- Guardar X^3 en TEMP
    73 => OP_LDY   & x"B3" & x"00", -- Cargar Y desde TEMP (Y = X^3)
    
    74 => OP_LDX   & x"A6" & x"00", -- X=0
    75 => OP_SUB   & x"00" & x"00", -- 0 - X^3 = -27
    76 => OP_STX   & x"D0" & x"00", 
    77 => OP_LDX   & x"A2" & x"00", -- Z=80
    78 => OP_LDY   & x"AF" & x"00", -- Y=7
    79 => OP_MUL   & x"00" & x"00", -- 7*Z
    
    -- (Puente para 7*Z)
    80 => OP_STX   & x"B3" & x"00", -- Guardar 7Z en TEMP
    81 => OP_LDY   & x"B3" & x"00", -- Cargar Y desde TEMP
    
    82 => OP_LDX   & x"A6" & x"00", -- X=0
    83 => OP_SUB   & x"00" & x"00", -- 0 - 7Z
    84 => OP_STX   & x"D1" & x"00", 
    85 => OP_LDX   & x"A3" & x"00", -- W=40
    86 => OP_LDY   & x"B0" & x"00", -- Y=10
    87 => OP_DIV   & x"00" & x"00", -- W/10
    88 => OP_STX   & x"D2" & x"00", 
    89 => OP_LDX   & x"D0" & x"00", 
    90 => OP_LDY   & x"D1" & x"00", 
    91 => OP_ADD   & x"00" & x"00", 
    92 => OP_LDY   & x"D2" & x"00", 
    93 => OP_ADD   & x"00" & x"00", 
    94 => OP_STX   & x"D3" & x"00", 
    95 => (others => '0'), -- NOP
    96 => (others => '0'), -- NOP

    -- LOGICA_COMUN (PC=97) - (Desplazado por la corrección)
    97 => OP_LDX   & x"D3" & x"00", -- X = F
    98 => OP_DISP  & x"00" & x"00", 
    99 => OP_LDX   & x"A7" & x"00", -- 10s
    100 => OP_STX  & x"D6" & x"00", 
    101 => OP_LDX  & x"D6" & x"00", 
    102 => OP_STX  & x"E0" & x"00", -- LEDs
    103 => OP_WAIT & x"00" & x"00", 
    104 => OP_LDX  & x"D6" & x"00", 
    105 => OP_LDY  & x"A5" & x"00", 
    106 => OP_SUB  & x"00" & x"00", 
    107 => OP_STX  & x"D6" & x"00", 
    108 => OP_BR_NZ & x"65" & x"00",-- Ir a PC 101
    
    -- Determinar T
    109 => OP_LDX  & x"D3" & x"00", 
    110 => OP_LDY  & x"A9" & x"00", -- 100
    111 => OP_CMP  & x"00" & x"00", 
    112 => OP_BNC  & x"92" & x"00", -- Ir a 146
    113 => OP_LDY  & x"AA" & x"00", -- 60
    114 => OP_CMP  & x"00" & x"00", 
    115 => OP_BNC  & x"94" & x"00", -- Ir a 148
    116 => OP_LDY  & x"AB" & x"00", -- 25
    117 => OP_CMP  & x"00" & x"00", 
    118 => OP_BNC  & x"96" & x"00", -- Ir a 150
    119 => OP_LDY  & x"A6" & x"00", -- 0
    120 => OP_CMP  & x"00" & x"00", 
    121 => OP_BNC  & x"98" & x"00", -- Ir a 152
    122 => OP_LDX  & x"AD" & x"00", -- 5
    123 => OP_JUMP & x"99" & x"00", -- Ir a 153

    -- Contador (PC=124)
    124 => OP_LDX  & x"A6" & x"00", -- 0
    125 => OP_STX  & x"D4" & x"00", 
    
    -- Bucle N (PC=126)
    126 => OP_LDX  & x"D4" & x"00", 
    127 => OP_DISP & x"00" & x"00", 
    128 => OP_LDX  & x"D5" & x"00", -- T
    129 => OP_STX  & x"D6" & x"00", 
    
    -- Bucle T (PC=130)
    130 => OP_LDX  & x"D6" & x"00", 
    131 => OP_STX  & x"E0" & x"00", -- LEDs
    132 => OP_WAIT & x"00" & x"00", 
    133 => OP_LDX  & x"D6" & x"00", 
    134 => OP_LDY  & x"A5" & x"00", 
    135 => OP_SUB  & x"00" & x"00", 
    136 => OP_STX  & x"D6" & x"00", 
    137 => OP_BR_NZ & x"82" & x"00",-- Ir a PC 130
    
    138 => OP_LDX  & x"D4" & x"00", 
    139 => OP_LDY  & x"A5" & x"00", 
    140 => OP_ADD  & x"00" & x"00", 
    141 => OP_STX  & x"D4" & x"00", 
    142 => OP_LDY  & x"A8" & x"00", -- 30
    143 => OP_CMP  & x"00" & x"00", 
    144 => OP_BNC  & x"9B" & x"00", -- Ir a 155
    145 => OP_JUMP & x"7E" & x"00", -- Ir a PC 126
    
    -- SET_T
    146 => OP_LDX  & x"A4" & x"00", -- 2s
    147 => OP_JUMP & x"99" & x"00", 
    148 => OP_LDX  & x"B2" & x"00", -- 3s
    149 => OP_JUMP & x"99" & x"00", 
    150 => OP_LDX  & x"AC" & x"00", -- 4s
    151 => OP_JUMP & x"99" & x"00", 
    152 => OP_LDX  & x"A5" & x"00", -- 1s
    
    -- Store T (PC=153)
    153 => OP_STX  & x"D5" & x"00", 
    154 => OP_JUMP & x"7C" & x"00", -- Ir a PC 124
    
    -- Fin (PC=155)
    155 => OP_STOP & x"00" & x"00",

    -- (Datos a partir de 160... sin cambios)
    160 => x"00" & std_logic_vector(to_unsigned(3, 16)),
    -- ... (Copiar la sección de datos del código anterior, no cambió)
    161 => x"00" & std_logic_vector(to_unsigned(2, 16)),
    162 => x"00" & std_logic_vector(to_unsigned(80, 16)),
    163 => x"00" & std_logic_vector(to_unsigned(40, 16)),
    164 => x"00" & std_logic_vector(to_unsigned(2, 16)),
    165 => x"00" & std_logic_vector(to_unsigned(1, 16)),
    166 => x"00" & std_logic_vector(to_unsigned(0, 16)),
    167 => x"00" & std_logic_vector(to_unsigned(10, 16)),
    168 => x"00" & std_logic_vector(to_unsigned(31, 16)),
    169 => x"00" & std_logic_vector(to_unsigned(100, 16)),
    170 => x"00" & std_logic_vector(to_unsigned(60, 16)),
    171 => x"00" & std_logic_vector(to_unsigned(25, 16)),
    172 => x"00" & std_logic_vector(to_unsigned(4, 16)),
    173 => x"00" & std_logic_vector(to_unsigned(5, 16)),
    174 => x"00" & std_logic_vector(to_unsigned(17, 16)),
    175 => x"00" & std_logic_vector(to_unsigned(7, 16)),
    176 => x"00" & std_logic_vector(to_unsigned(10, 16)),
    177 => x"00" & std_logic_vector(to_unsigned(30, 16)),
    178 => x"00" & std_logic_vector(to_unsigned(3, 16)),

    others => (others => '0')
  );

begin

  -- Lógica de Lectura/Escritura de RAM (sin cambios)
  Data_out <= mem_array(to_integer(unsigned(Addr_in)));

  Write_Process : process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem_array(to_integer(unsigned(Addr_in))) <= Data_in;
      end if;
    end if;
  end process Write_Process;

end architecture;