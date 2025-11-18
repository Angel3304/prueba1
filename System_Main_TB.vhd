library ieee;
use ieee.std_logic_1164.all;

-- Entidad del Testbench (está vacía)
entity System_Main_TB is
end entity System_Main_TB;

architecture Behavioral of System_Main_TB is

  -- Constante para el período del reloj (ej. 50 MHz -> 20 ns)
  constant CLK_PERIOD : time := 20 ns;

  -- MODIFICADO: Declaración del componente actualizada
  component System_Main is
    port (
      sys_reset   : in  std_logic;
      sys_run     : in  std_logic;
      clk_in      : in  std_logic;
      i_eq_select : in  std_logic_vector(1 downto 0); -- NUEVO
      SEG_A       : out std_logic;
      SEG_B       : out std_logic;
      SEG_C       : out std_logic;
      SEG_D       : out std_logic;
      SEG_E       : out std_logic;
      SEG_F       : out std_logic;
      SEG_G       : out std_logic;
      SEG_DP      : out std_logic;
      DIG1        : out std_logic;
      DIG2        : out std_logic;
      DIG3        : out std_logic;
      DIG4        : out std_logic
    );
  end component;

  -- Señales para conectar al componente
  signal s_clk       : std_logic := '0';
  signal s_reset     : std_logic;
  signal s_run       : std_logic;
  signal s_eq_select : std_logic_vector(1 downto 0) := "00"; -- NUEVO

  -- Señales para "atrapar" las salidas
  signal s_seg : std_logic_vector(6 downto 0);
  signal s_dig : std_logic_vector(3 downto 0);
  signal s_dp  : std_logic;

begin

  -- 1. Instanciación del "Design Under Test" (DUT)
  UUT : System_Main
    port map (
      clk_in      => s_clk,
      sys_reset   => s_reset,
      sys_run     => s_run,
      i_eq_select => s_eq_select, -- NUEVO
      SEG_A       => s_seg(6),
      SEG_B       => s_seg(5),
      SEG_C       => s_seg(4),
      SEG_D       => s_seg(3),
      SEG_E       => s_seg(2),
      SEG_F       => s_seg(1),
      SEG_G       => s_seg(0),
      SEG_DP      => s_dp,
      DIG1        => s_dig(0),
      DIG2        => s_dig(1),
      DIG3        => s_dig(2),
      DIG4        => s_dig(3)
    );

  -- 2. Proceso generador de reloj
  CLK_Process : process
  begin
    s_clk <= '0';
    wait for CLK_PERIOD / 2;
    s_clk <= '1';
    wait for CLK_PERIOD / 2;
  end process CLK_Process;

  -- 3. MODIFICADO: Proceso de estímulo para probar las 4 ecuaciones
  Stimulus_Process : process
  begin
    ---------------------------------------------
    -- Prueba 1: Ecuación (b) - "01"
    ---------------------------------------------
    s_eq_select <= "01";
    s_reset <= '0';
    s_run   <= '1'; -- Run detenido
    wait for CLK_PERIOD * 10;
    s_reset <= '1';
    wait for CLK_PERIOD * 10;
    s_run <= '0'; -- Activar Run
    
    wait for 1000 us; -- Correr simulación por 1ms

    ---------------------------------------------
    -- Prueba 2: Ecuación (a) - "00"
    ---------------------------------------------
    s_eq_select <= "00";
    s_reset <= '0';
    wait for CLK_PERIOD * 10;
    s_reset <= '1';
    wait for CLK_PERIOD * 10;
    s_run <= '0';
    
    wait for 1000 us;

    ---------------------------------------------
    -- Prueba 3: Ecuación (c) - "10"
    ---------------------------------------------
    s_eq_select <= "10";
    s_reset <= '0';
    wait for CLK_PERIOD * 10;
    s_reset <= '1';
    wait for CLK_PERIOD * 10;
    s_run <= '0';
    
    wait for 1000 us;

    ---------------------------------------------
    -- Prueba 4: Ecuación (d) - "11"
    ---------------------------------------------
    s_eq_select <= "11";
    s_reset <= '0';
    wait for CLK_PERIOD * 10;
    s_reset <= '1';
    wait for CLK_PERIOD * 10;
    s_run <= '0';
    
    wait for 1000 us;
    
    wait; -- Detener simulación
  end process Stimulus_Process;

end architecture Behavioral;