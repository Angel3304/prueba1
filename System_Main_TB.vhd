library ieee;
use ieee.std_logic_1164.all;

-- Entidad del Testbench (está vacía)
entity System_Main_TB is
end entity System_Main_TB;

architecture Behavioral of System_Main_TB is

  -- Constante para el período del reloj (ej. 50 MHz -> 20 ns)
  constant CLK_PERIOD : time := 20 ns;

  -- Declaración del componente que vamos a probar (tu diseño)
  component System_Main is
    port (
      sys_reset : in  std_logic;
      sys_run   : in  std_logic;
      clk_in    : in  std_logic;
      SEG_A     : out std_logic;
      SEG_B     : out std_logic;
      SEG_C     : out std_logic;
      SEG_D     : out std_logic;
      SEG_E     : out std_logic;
      SEG_F     : out std_logic;
      SEG_G     : out std_logic;
      SEG_DP    : out std_logic;
      DIG1      : out std_logic;
      DIG2      : out std_logic;
      DIG3      : out std_logic;
      DIG4      : out std_logic
    );
  end component;

  -- Señales para conectar al componente
  signal s_clk   : std_logic := '0';
  signal s_reset : std_logic;
  signal s_run   : std_logic;

  -- Señales para "atrapar" las salidas (opcional, pero buena práctica)
  signal s_seg : std_logic_vector(6 downto 0);
  signal s_dig : std_logic_vector(3 downto 0);
  signal s_dp  : std_logic;

begin

  -- 1. Instanciación del "Design Under Test" (DUT)
  UUT : System_Main
    port map (
      clk_in    => s_clk,
      sys_reset => s_reset,
      sys_run   => s_run,
      SEG_A     => s_seg(6),
      SEG_B     => s_seg(5),
      SEG_C     => s_seg(4),
      SEG_D     => s_seg(3),
      SEG_E     => s_seg(2),
      SEG_F     => s_seg(1),
      SEG_G     => s_seg(0),
      SEG_DP    => s_dp,
      DIG1      => s_dig(0),
      DIG2      => s_dig(1),
      DIG3      => s_dig(2),
      DIG4      => s_dig(3)
    );

  -- 2. Proceso generador de reloj
  CLK_Process : process
  begin
    s_clk <= '0';
    wait for CLK_PERIOD / 2;
    s_clk <= '1';
    wait for CLK_PERIOD / 2;
  end process CLK_Process;

  -- 3. Proceso de estímulo (Reset y Run)
  Stimulus_Process : process
  begin
    -- Aplicar Reset (activo bajo)
    s_reset <= '0';
    s_run   <= '1'; -- Run detenido
    wait for CLK_PERIOD * 10; -- Esperar 10 ciclos de reloj

    -- Quitar Reset
    s_reset <= '1';
    wait for CLK_PERIOD * 10;

    -- Activar Run (activo bajo)
    s_run <= '0';
    
    -- Dejar la simulación corriendo
    wait;
  end process Stimulus_Process;

end architecture Behavioral;