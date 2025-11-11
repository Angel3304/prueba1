--------------------------------------------------------------------
--  System_Main.vhd
--  Top‑level de la práctica (Cyclone IV)
--  ---------------------------------------------------------------
--  Cambios respecto a la versión original:
--    • Se elimina el componente OSCH (osc. interno Lattice).
--    • Se añade el puerto de reloj externo   clk_in : in std_logic;
--    • clk_signal se conecta directamente a clk_in.
--    • Para la simulación se incluye un bloque de generación de
--      reloj que será ignorado en la síntesis.
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity System_Main is
  port (
    ------------------------------------------------------------------
    --  Entradas de control
    ------------------------------------------------------------------
    sys_reset : in  std_logic;        -- reset síncrono del CPU
    sys_run   : in  std_logic;        -- señal de “run / stop”
    clk_in    : in  std_logic;        -- **RELOJ EXTERNO** (cristal/osc.)

    ------------------------------------------------------------------
    --  Salidas al display de 4 dígitos 7‑segmentos (ánodo/cátodo común)
    ------------------------------------------------------------------
    SEG_A  : out std_logic;  SEG_B  : out std_logic;  SEG_C  : out std_logic;
    SEG_D  : out std_logic;  SEG_E  : out std_logic;  SEG_F  : out std_logic;
    SEG_G  : out std_logic;  SEG_DP : out std_logic;
    DIG1   : out std_logic;  DIG2   : out std_logic;
    DIG3   : out std_logic;  DIG4   : out std_logic
  );
end entity System_Main;

--------------------------------------------------------------------
architecture Behavioral of System_Main is

  ------------------------------------------------------------------
  --  Declaración del procesador (ALU + FSM + datapath)
  ------------------------------------------------------------------
  component Processor_Unit is
    port (
      master_clk   : in  std_logic;
      master_reset : in  std_logic;
      master_run   : in  std_logic;
      ----------------------------------------------------------------
      --  Salidas de segmento y dígitos
      ----------------------------------------------------------------
      o_seg_a      : out std_logic; o_seg_b : out std_logic; o_seg_c : out std_logic;
      o_seg_d      : out std_logic; o_seg_e : out std_logic; o_seg_f : out std_logic;
      o_seg_g      : out std_logic; o_seg_dp: out std_logic;
      o_dig1       : out std_logic; o_dig2  : out std_logic;
      o_dig3       : out std_logic; o_dig4  : out std_logic
    );
  end component;

  ------------------------------------------------------------------
  --  Señales internas
  ------------------------------------------------------------------
  signal clk_signal : std_logic;   -- copia interna del reloj externo
  signal clk_dummy  : std_logic;   -- (se mantiene para compatibilidad)
begin

  ------------------------------------------------------------------
  --  Reloj externo → señal interna
  ------------------------------------------------------------------
  clk_signal <= clk_in;   -- nada de lógica adicional, sólo una asignación

  ------------------------------------------------------------------
  --  Instancia del procesador (ALU + FSM)
  ------------------------------------------------------------------
  CPU_Inst : Processor_Unit
    port map (
      master_clk   => clk_signal,
      master_reset => sys_reset,
      master_run   => sys_run,
      o_seg_a      => SEG_A,  o_seg_b => SEG_B,  o_seg_c => SEG_C,
      o_seg_d      => SEG_D,  o_seg_e => SEG_E,  o_seg_f => SEG_F,
      o_seg_g      => SEG_G,  o_seg_dp => SEG_DP,
      o_dig1       => DIG1,   o_dig2  => DIG2,
      o_dig3       => DIG3,   o_dig4  => DIG4
    );

  ------------------------------------------------------------------
  --  (Opcional) Generador de reloj solo para simulación.
  --  Se incluye dentro de los pragmas synthesis translate_off/on
  --  para que el sintetizador lo ignore.
  ------------------------------------------------------------------
  -- synthesis translate_off
  clk_gen_proc : process
  begin
    -- Genera un reloj de 50 MHz (20 ns periodo) solo en la simulación.
    clk_signal <= '0';
    wait for 10 ns;
    clk_signal <= '1';
    wait for 10 ns;
  end process;
  -- synthesis translate_on

end architecture Behavioral;
