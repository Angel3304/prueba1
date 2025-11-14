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
  -- Opcodes (incluyendo el nuevo OP_MUL)
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
  constant OP_MUL   : std_logic_vector(7 downto 0) := x"0E"; -- NUEVO
  constant OP_STOP  : std_logic_vector(7 downto 0) := x"0F";

  type t_mem_array is array (0 to 255) of std_logic_vector(23 downto 0);
  
  -- MODIFICADO: Nuevo programa para probar MUL
  constant Program_Data : t_mem_array := (
    ------------------------------------------------------------------
    -- Programa de Prueba (Multiplicación 8x8)
    ------------------------------------------------------------------
    -- Propósito: Probar X = 12 * 10
    
    0  => OP_LDX   & x"80" & x"00", -- Cargar X = 12 (desde dir x"80")
    1  => OP_LDY   & x"81" & x"00", -- Cargar Y = 10 (desde dir x"81")
    2  => OP_MUL   & x"00" & x"00", -- Multiplicar X = X * Y (12 * 10)
                                   -- Resultado (120) se guarda en X
                                   -- Banderas Z=0, S=0 se actualizan
    3  => OP_DISP  & x"00" & x"00", -- Mostrar resultado (120)
    4  => OP_STOP  & x"00" & x"00", -- Parar CPU

    ------------------------------------------------------------------
    -- Datos (16 bits)
    ------------------------------------------------------------------
    128 => x"00" & std_logic_vector(to_unsigned(12, 16)),   -- [x"80"] = 12
    129 => x"00" & std_logic_vector(to_unsigned(10, 16)),   -- [x"81"] = 10
   
    others => (others => '0')
  );
begin
  Data_bus <= Program_Data(to_integer(unsigned(Addr_in)));
end architecture;