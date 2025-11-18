library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_Store is
  port(
    clk      : in  std_logic; -- NUEVO: Reloj para escritura síncrona
    we       : in  std_logic; -- NUEVO: Write Enable (Habilitar escritura)
    Addr_in  : in  std_logic_vector(7 downto 0);
    Data_in  : in  std_logic_vector(23 downto 0); -- NUEVO: Datos que entran
    Data_out : out std_logic_vector(23 downto 0)  -- (Antes 'Data_bus')
  );
end entity;

architecture Behavioral of Memory_Store is

  -- Opcodes (para la inicialización)
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
  -- (OP_STX x"11" se usará en la FSM, no aquí)

  type t_mem_array is array (0 to 255) of std_logic_vector(23 downto 0);
  
  -- MODIFICADO: De 'constant' a 'signal'
  -- Esto crea una RAM que se INICIALIZA con el programa de prueba.
  signal mem_array : t_mem_array := (
    -- Programa de prueba (usaremos el de DIV por ahora)
    0  => OP_LDX   & x"80" & x"00", -- Cargar X = 27 (Dividendo)
    1  => OP_LDY   & x"81" & x"00", -- Cargar Y = 5 (Divisor)
    2  => OP_DIV   & x"00" & x"00", -- Dividir X = X / Y (27 / 5)
    3  => OP_DISP  & x"00" & x"00", -- Mostrar resultado (Cociente 5)
    4  => OP_STOP  & x"00" & x"00", -- Parar CPU

    -- Datos (16 bits)
    128 => x"00" & std_logic_vector(to_unsigned(27, 16)),   -- [x"80"] = 27
    129 => x"00" & std_logic_vector(to_unsigned(5, 16)),    -- [x"81"] = 5
   
    others => (others => '0')
  );

begin

  -- Bloque 1: Lógica de LECTURA (Combinacional)
  -- La lectura siempre está activa.
  Data_out <= mem_array(to_integer(unsigned(Addr_in)));

  -- Bloque 2: Lógica de ESCRITURA (Síncrona)
  -- Solo escribimos en el flanco de reloj si 'we' está activado.
  Write_Process : process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem_array(to_integer(unsigned(Addr_in))) <= Data_in;
      end if;
    end if;
  end process Write_Process;

end architecture;