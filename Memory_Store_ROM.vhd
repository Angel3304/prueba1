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
  -- Opcodes (sin cambios)
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
  
  -- MODIFICADO: Nuevo programa y datos de 16 bits
  constant Program_Data : t_mem_array := (
    ------------------------------------------------------------------
    -- Programa de Prueba (16 bits)
    ------------------------------------------------------------------
    -- Propósito: Probar LDX, LDY, ADD, SUB, DISP, WAIT, BNZ
    
    0  => OP_LDX   & x"80" & x"00", -- Cargar en X el valor en [x"80"] (500)
    1  => OP_DISP  & x"00" & x"00", -- Mostrar X (500)
    2  => OP_WAIT  & x"00" & x"00", -- Esperar 1 segundo
    
    3  => OP_LDY   & x"81" & x"00", -- Cargar en Y el valor en [x"81"] (250)
    4  => OP_ADD   & x"00" & x"00", -- X = X + Y (500 + 250 = 750)
    5  => OP_DISP  & x"00" & x"00", -- Mostrar X (750)
    6  => OP_WAIT  & x"00" & x"00", -- Esperar 1 segundo
    
    7  => OP_LDY   & x"82" & x"00", -- Cargar en Y el valor en [x"82"] (1)
    
    -- Inicio del bucle (Dirección 8)
    8  => OP_SUB   & x"00" & x"00", -- X = X - Y (X = X - 1)
    9  => OP_DISP  & x"00" & x"00", -- Mostrar X (749, 748, ...)
    10 => OP_BR_NZ & x"08" & x"00", -- Si X no es Cero (Z=0), saltar a dir. 8
    
    -- Fin del programa
    11 => OP_DISP  & x"00" & x"00", -- Mostrar X (que ahora es 0)
    12 => OP_STOP  & x"00" & x"00", -- Parar CPU

    ------------------------------------------------------------------
    -- Datos (16 bits)
    ------------------------------------------------------------------
    -- Los datos se almacenan en los 16 bits inferiores (15 downto 0)
    -- Los 8 bits superiores (23 downto 16) se rellenan con '0'
    
    128 => x"00" & std_logic_vector(to_unsigned(500, 16)), -- [x"80"] = 500
    129 => x"00" & std_logic_vector(to_unsigned(250, 16)), -- [x"81"] = 250
    130 => x"00" & std_logic_vector(to_unsigned(1, 16)),   -- [x"82"] = 1
   
    -- (Resto de direcciones)
    others => (others => '0')
  );
begin
  Data_bus <= Program_Data(to_integer(unsigned(Addr_in)));
end architecture;