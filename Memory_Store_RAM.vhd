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

  -- Opcodes del CPU
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
  
  -- VALORES DE PRUEBA (Direcciones de datos CORREGIDAS)
  -- Usaremos: X=3, Y=2, Z=80, W=40
  -- Eq A: 17(3) + 25(2) - 40/4 = 51 + 50 - 10 = 91 (T=3s)
  -- Eq B: 10(3^2) + 30(3) - 80/2 = 10(9) + 90 - 40 = 90 + 90 - 40 = 140 (T=2s)
  -- Eq C: -(3^3) - 7(80) + 40/10 = -27 - 560 + 4 = -583 (T=5s)
  
  signal mem_array : t_mem_array := (
    ------------------------------------------------------------------
    -- Parte 1: Selector de Ecuación (Lee los switches)
    ------------------------------------------------------------------
    -- (PC=0)
    0  => OP_LDX   & x"F0" & x"00", -- Leer switches desde MMIO [x"F0"]
    1  => OP_STX   & x"DF" & x"00", -- Guardar valor del switch en RAM[x"DF"]
    
    -- (PC=2) -- Comprobar si es 0 ("00") -> Eq (a)
    2  => OP_LDY   & x"A6" & x"00", -- Y = CONST_0
    3  => OP_CMP   & x"00" & x"00", -- Comparar X (switch) vs 0
    4  => OP_BR_NZ & x"07" & x"00", -- Si no es 0, saltar a PC=7
    5  => OP_JUMP  & x"17" & x"00", -- Es 0, saltar a INICIO_EQ_A (PC=23)
    6  => (others => '0'),         -- NOP (Relleno)

    -- (PC=7) -- Comprobar si es 1 ("01") -> Eq (b)
    7  => OP_LDX   & x"DF" & x"00", -- X = switch_val
    8  => OP_LDY   & x"A5" & x"00", -- Y = CONST_1
    9  => OP_CMP   & x"00" & x"00", -- Comparar X vs 1
    10 => OP_BR_NZ & x"0D" & x"00", -- Si no es 1, saltar a PC=13
    11 => OP_JUMP  & x"2E" & x"00", -- Es 1, saltar a INICIO_EQ_B (PC=46)
    12 => (others => '0'),         -- NOP

    -- (PC=13) -- Comprobar si es 2 ("10") -> Eq (c)
    13 => OP_LDX   & x"DF" & x"00", -- X = switch_val
    14 => OP_LDY   & x"A4" & x"00", -- Y = CONST_2
    15 => OP_CMP   & x"00" & x"00", -- Comparar X vs 2
    16 => OP_BR_NZ & x"14" & x"00", -- Si no es 2, saltar a PC=20 (debe ser 3)
    17 => OP_JUMP  & x"43" & x"00", -- Es 2, saltar a INICIO_EQ_C (PC=67)
    18 => (others => '0'),         -- NOP
    19 => (others => '0'),         -- NOP

    -- (PC=20) -- Caso 3 ("11") -> Eq (d)
    20 => OP_LDX   & x"A6" & x"00", -- X = 0
    21 => OP_DISP  & x"00" & x"00", -- Mostrar 0000
    22 => OP_STOP  & x"00" & x"00", -- Parar
    
    ------------------------------------------------------------------
    -- Parte 2: Bloques de Ecuaciones
    ------------------------------------------------------------------
    
    -- INICIO_EQ_A (PC=23): F = 17X + 25Y - W/4
    23 => OP_LDX   & x"A0" & x"00", -- X = VAL_X (3)
    24 => OP_LDY   & x"AE" & x"00", -- Y = CONST_17
    25 => OP_MUL   & x"00" & x"00", -- X = 17*X (51)
    26 => OP_STX   & x"D0" & x"00", -- Guardar Termino A en RAM[x"D0"]
    27 => OP_LDX   & x"A1" & x"00", -- X = VAL_Y (2)
    28 => OP_LDY   & x"AB" & x"00", -- Y = CONST_25
    29 => OP_MUL   & x"00" & x"00", -- X = 25*Y (50)
    30 => OP_STX   & x"D1" & x"00", -- Guardar Termino B en RAM[x"D1"]
    31 => OP_LDX   & x"A3" & x"00", -- X = VAL_W (40)
    32 => OP_LDY   & x"AC" & x"00", -- Y = CONST_4
    33 => OP_DIV   & x"00" & x"00", -- X = W/4 (10)
    34 => OP_STX   & x"D2" & x"00", -- Guardar Termino C en RAM[x"D2"]
    35 => OP_LDX   & x"D0" & x"00", -- X = Termino A (51)
    36 => OP_LDY   & x"D1" & x"00", -- Y = Termino B (50)
    37 => OP_ADD   & x"00" & x"00", -- X = A + B (101)
    38 => OP_LDY   & x"D2" & x"00", -- Y = Termino C (10)
    39 => OP_SUB   & x"00" & x"00", -- X = (A+B) - C (91)
    40 => OP_STX   & x"D3" & x"00", -- Guardar Resultado F en RAM[x"D3"]
    41 => OP_JUMP  & x"5D" & x"00", -- Saltar a LOGICA_COMUN (PC=93)
    42 => (others => '0'), -- NOP
    43 => (others => '0'), -- NOP
    44 => (others => '0'), -- NOP
    45 => (others => '0'), -- NOP

    -- INICIO_EQ_B (PC=46): F = 10X^2 + 30X - Z/2
    46 => OP_LDX   & x"A0" & x"00", -- X = VAL_X (3)
    47 => OP_LDY   & x"A0" & x"00", -- Y = VAL_X (3)
    48 => OP_MUL   & x"00" & x"00", -- X = X^2 (9)
    49 => OP_LDY   & x"B0" & x"00", -- Y = CONST_10
    50 => OP_MUL   & x"00" & x"00", -- X = 10*X^2 (90)
    51 => OP_STX   & x"D0" & x"00", -- Guardar Termino A en RAM[x"D0"]
    52 => OP_LDX   & x"A0" & x"00", -- X = VAL_X (3)
    53 => OP_LDY   & x"B1" & x"00", -- Y = CONST_30
    54 => OP_MUL   & x"00" & x"00", -- X = 30*X (90)
    55 => OP_STX   & x"D1" & x"00", -- Guardar Termino B en RAM[x"D1"]
    56 => OP_LDX   & x"A2" & x"00", -- X = VAL_Z (80)
    57 => OP_LDY   & x"A4" & x"00", -- Y = CONST_2
    58 => OP_DIV   & x"00" & x"00", -- X = Z/2 (40)
    59 => OP_STX   & x"D2" & x"00", -- Guardar Termino C en RAM[x"D2"]
    60 => OP_LDX   & x"D0" & x"00", -- X = Termino A (90)
    61 => OP_LDY   & x"D1" & x"00", -- Y = Termino B (90)
    62 => OP_ADD   & x"00" & x"00", -- X = A + B (180)
    63 => OP_LDY   & x"D2" & x"00", -- Y = Termino C (40)
    64 => OP_SUB   & x"00" & x"00", -- X = (A+B) - C (140)
    65 => OP_STX   & x"D3" & x"00", -- Guardar Resultado F en RAM[x"D3"]
    66 => OP_JUMP  & x"5D" & x"00", -- Saltar a LOGICA_COMUN (PC=93)

    -- INICIO_EQ_C (PC=67): F = -X^3 - 7Z + W/10
    67 => OP_LDX   & x"A0" & x"00", -- X = VAL_X (3)
    68 => OP_LDY   & x"A0" & x"00", -- Y = VAL_X (3)
    69 => OP_MUL   & x"00" & x"00", -- X = X^2 (9)
    70 => OP_LDY   & x"A0" & x"00", -- Y = VAL_X (3)
    71 => OP_MUL   & x"00" & x"00", -- X = X^3 (27)
    72 => OP_LDY   & x"00" & x"00", -- Y = X (Copia X^3 a Y)
    73 => OP_LDX   & x"A6" & x"00", -- X = 0
    74 => OP_SUB   & x"00" & x"00", -- X = 0 - Y (0 - X^3 = -27)
    75 => OP_STX   & x"D0" & x"00", -- Guardar Termino A en RAM[x"D0"]
    76 => OP_LDX   & x"A2" & x"00", -- X = VAL_Z (80)
    77 => OP_LDY   & x"AF" & x"00", -- Y = CONST_7
    78 => OP_MUL   & x"00" & x"00", -- X = 7*Z (560)
    79 => OP_LDY   & x"00" & x"00", -- Y = X (Copia 7*Z a Y)
    80 => OP_LDX   & x"A6" & x"00", -- X = 0
    81 => OP_SUB   & x"00" & x"00", -- X = 0 - Y (0 - 7*Z = -560)
    82 => OP_STX   & x"D1" & x"00", -- Guardar Termino B en RAM[x"D1"]
    83 => OP_LDX   & x"A3" & x"00", -- X = VAL_W (40)
    84 => OP_LDY   & x"B0" & x"00", -- Y = CONST_10
    85 => OP_DIV   & x"00" & x"00", -- X = W/10 (4)
    86 => OP_STX   & x"D2" & x"00", -- Guardar Termino C en RAM[x"D2"]
    87 => OP_LDX   & x"D0" & x"00", -- X = Termino A (-27)
    88 => OP_LDY   & x"D1" & x"00", -- Y = Termino B (-560)
    89 => OP_ADD   & x"00" & x"00", -- X = A + B (-587)
    90 => OP_LDY   & x"D2" & x"00", -- Y = Termino C (4)
    91 => OP_ADD   & x"00" & x"00", -- X = (A+B) + C (-583)
    92 => OP_STX   & x"D3" & x"00", -- Guardar Resultado F en RAM[x"D3"]

    ------------------------------------------------------------------
    -- Parte 3: Lógica Común (Retardos y Contador)
    ------------------------------------------------------------------
    -- LOGICA_COMUN (PC=93)
    -- Retardo fijo de 10s
    93 => OP_LDX   & x"D3" & x"00", -- X = F (Resultado)
    94 => OP_DISP  & x"00" & x"00", -- Mostrar F
    95 => OP_LDX   & x"A7" & x"00", -- X = CONST_10_SEC
    96 => OP_STX   & x"D6" & x"00", -- TEMP_WAIT_COUNTER = 10
    97 => OP_WAIT  & x"00" & x"00", -- Esperar 1 segundo
    98 => OP_LDX   & x"D6" & x"00", -- X = TEMP_WAIT_COUNTER
    99 => OP_LDY   & x"A5" & x"00", -- Y = CONST_1
    100 => OP_SUB  & x"00" & x"00", -- X = X - 1
    101 => OP_STX  & x"D6" & x"00", -- Guardar TEMP_WAIT_COUNTER
    102 => OP_BR_NZ & x"61" & x"00",-- Si X != 0, saltar a PC=97 (OP_WAIT)
    
    -- Determinar Retardo Variable T
    103 => OP_LDX  & x"D3" & x"00", -- X = F
    104 => OP_LDY  & x"A9" & x"00", -- Y = CONST_100
    105 => OP_CMP  & x"00" & x"00", -- Comparar F vs 100
    106 => OP_BNC  & x"8C" & x"00", -- Si F >= 100, saltar a SET_T_2s (PC=140)
    107 => OP_LDY  & x"AA" & x"00", -- Y = CONST_60
    108 => OP_CMP  & x"00" & x"00", -- Comparar F vs 60
    109 => OP_BNC  & x"8E" & x"00", -- Si F >= 60, saltar a SET_T_3s (PC=142)
    110 => OP_LDY  & x"AB" & x"00", -- Y = CONST_25
    111 => OP_CMP  & x"00" & x"00", -- Comparar F vs 25
    112 => OP_BNC  & x"90" & x"00", -- Si F >= 25, saltar a SET_T_4s (PC=144)
    113 => OP_LDY  & x"A6" & x"00", -- Y = CONST_0
    114 => OP_CMP  & x"00" & x"00", -- Comparar F vs 0
    115 => OP_BNC  & x"92" & x"00", -- Si F >= 0, saltar a SET_T_1s (PC=146)
    
    -- Rango E: F < 0 (T=5s)
    116 => OP_LDX  & x"AD" & x"00", -- X = CONST_5
    117 => OP_JUMP & x"93" & x"00", -- Saltar a STORE_T (PC=147)

    -- Contador 0-30
    -- INICIO_CONTADOR (PC=118)
    118 => OP_LDX  & x"A6" & x"00", -- X = 0
    119 => OP_STX  & x"D4" & x"00", -- COUNTER_N = 0
    
    -- INICIO_BUCLE_CONTADOR (PC=120)
    120 => OP_LDX  & x"D4" & x"00", -- X = COUNTER_N
    121 => OP_DISP & x"00" & x"00", -- Mostrar N (0, 1, 2...)
    122 => OP_LDX  & x"D5" & x"00", -- X = DELAY_T (nuestro T)
    123 => OP_STX  & x"D6" & x"00", -- TEMP_WAIT_COUNTER = T
    
    -- INICIO_BUCLE_T (PC=124)
    124 => OP_WAIT & x"00" & x"00", -- Esperar 1 segundo
    125 => OP_LDX  & x"D6" & x"00", -- X = TEMP_WAIT_COUNTER
    126 => OP_LDY  & x"A5" & x"00", -- Y = CONST_1
    127 => OP_SUB  & x"00" & x"00", -- X = X - 1
    128 => OP_STX  & x"D6" & x"00", -- Guardar TEMP_WAIT_COUNTER
    129 => OP_BR_NZ & x"7C" & x"00",-- Si X != 0, saltar a PC=124 (INICIO_BUCLE_T)
    
    -- Incrementar N y comprobar fin
    130 => OP_LDX  & x"D4" & x"00", -- X = COUNTER_N
    131 => OP_LDY  & x"A5" & x"00", -- Y = CONST_1
    132 => OP_ADD  & x"00" & x"00", -- X = N + 1
    133 => OP_STX  & x"D4" & x"00", -- COUNTER_N = N + 1
    134 => OP_LDY  & x"A8" & x"00", -- Y = CONST_30 (límite)
    135 => OP_CMP  & x"00" & x"00", -- Comparar N+1 vs 30
    136 => OP_BNC  & x"95" & x"00", -- Si N+1 >= 30, saltar a FIN_PROGRAMA (PC=149)
    137 => OP_JUMP & x"78" & x"00", -- Saltar a INICIO_BUCLE_CONTADOR (PC=120)

    -- (PC=138, 139) Relleno
    138 => (others => '0'),
    139 => (others => '0'),
    
    -- Bloques de SET_T (Aquí aterrizan los saltos)
    -- (PC=140)
    140 => OP_LDX  & x"A4" & x"00", -- SET_T_2s: X = CONST_2
    141 => OP_JUMP & x"93" & x"00", -- Saltar a STORE_T (PC=147)
    142 => OP_LDX  & x"B2" & x"00", -- SET_T_3s: X = CONST_3
    143 => OP_JUMP & x"93" & x"00", -- Saltar a STORE_T (PC=147)
    144 => OP_LDX  & x"AC" & x"00", -- SET_T_4s: X = CONST_4
    145 => OP_JUMP & x"93" & x"00", -- Saltar a STORE_T (PC=147)
    146 => OP_LDX  & x"A5" & x"00", -- SET_T_1s: X = CONST_1
    
    -- STORE_T (PC=147)
    147 => OP_STX  & x"D5" & x"00", -- Guardar T en RAM[x"D5"] (DELAY_T)
    148 => OP_JUMP & x"76" & x"00", -- Saltar a INICIO_CONTADOR (PC=118)
    
    -- FIN_PROGRAMA (PC=149)
    149 => OP_STOP & x"00" & x"00", -- Fin

    -- (PC=150 a 159) Relleno
    150 => (others => '0'),
    159 => (others => '0'),

    ------------------------------------------------------------------
    -- SECCIÓN DE DATOS (Inicia en x"A0" = 160)
    ------------------------------------------------------------------
    -- Entradas (x"A0" - x"A3")
    160 => x"00" & std_logic_vector(to_unsigned(3, 16)),    -- x"A0": VAL_X (3)
    161 => x"00" & std_logic_vector(to_unsigned(2, 16)),    -- x"A1": VAL_Y (2)
    162 => x"00" & std_logic_vector(to_unsigned(80, 16)),   -- x"A2": VAL_Z (80)
    163 => x"00" & std_logic_vector(to_unsigned(40, 16)),   -- x"A3": VAL_W (40)
    
    -- Constantes (x"A4" - x"B2")
    164 => x"00" & std_logic_vector(to_unsigned(2, 16)),    -- x"A4": CONST_2
    165 => x"00" & std_logic_vector(to_unsigned(1, 16)),    -- x"A5": CONST_1
    166 => x"00" & std_logic_vector(to_unsigned(0, 16)),    -- x"A6": CONST_0
    167 => x"00" & std_logic_vector(to_unsigned(10, 16)),   -- x"A7": CONST_10_SEC
    168 => x"00" & std_logic_vector(to_unsigned(30, 16)),   -- x"A8": CONST_30 (límite)
    169 => x"00" & std_logic_vector(to_unsigned(100, 16)),  -- x"A9": CONST_100
    170 => x"00" & std_logic_vector(to_unsigned(60, 16)),   -- x"AA": CONST_60
    171 => x"00" & std_logic_vector(to_unsigned(25, 16)),   -- x"AB": CONST_25
    172 => x"00" & std_logic_vector(to_unsigned(4, 16)),    -- x"AC": CONST_4
    173 => x"00" & std_logic_vector(to_unsigned(5, 16)),    -- x"AD": CONST_5
    174 => x"00" & std_logic_vector(to_unsigned(17, 16)),   -- x"AE": CONST_17
    175 => x"00" & std_logic_vector(to_unsigned(7, 16)),    -- x"AF": CONST_7
    176 => x"00" & std_logic_vector(to_unsigned(10, 16)),   -- x"B0": CONST_10
    177 => x"00" & std_logic_vector(to_unsigned(30, 16)),   -- x"B1": CONST_30
    178 => x"00" & std_logic_vector(to_unsigned(3, 16)),    -- x"B2": CONST_3

    -- El resto de las direcciones (incluyendo las variables D0-DF)
    -- se inicializan en 0.
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