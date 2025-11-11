library ieee;
use ieee.std_logic_1164.all;

entity System_Main is
  port (
    ------------------------------------------------------------------
    --  Entradas de control
    ------------------------------------------------------------------
    sys_reset : in  std_logic;        -- reset síncrono (activo bajo)
    sys_run   : in  std_logic;        -- run/stop (activo bajo)
    clk_in    : in  std_logic;        -- reloj externo (cristal/osc.)

    ------------------------------------------------------------------
    --  Salidas al display de 4 dígitos 7‑segmentos (ánodo común)
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
      o_dig1       : out std_logic; o_dig2 : out std_logic;
      o_dig3       : out std_logic; o_dig4 : out std_logic
    );
  end component;

  ------------------------------------------------------------------
  --  Señales internas
  ------------------------------------------------------------------
  signal clk_internal : std_logic;   -- señal interna que alimenta al procesador
begin

  ------------------------------------------------------------------
  --  Reloj externo → señal interna
  ------------------------------------------------------------------
  clk_internal <= clk_in;      -- únicamente una asignación. En síntesis no hay
                               -- un driver extra.

  ------------------------------------------------------------------
  --  Instancia del procesador (ALU + FSM + driver de display)
  ------------------------------------------------------------------
  CPU_Inst : Processor_Unit
    port map (
      master_clk   => clk_internal,
      master_reset => sys_reset,
      master_run   => sys_run,
      o_seg_a      => SEG_A,  o_seg_b => SEG_B,  o_seg_c => SEG_C,
      o_seg_d      => SEG_D,  o_seg_e => SEG_E,  o_seg_f => SEG_F,
      o_seg_g      => SEG_G,  o_seg_dp => SEG_DP,
      o_dig1       => DIG1,   o_dig2 => DIG2,
      o_dig3       => DIG3,   o_dig4 => DIG4
    );
end architecture Behavioral;