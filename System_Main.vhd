library ieee;
use ieee.std_logic_1164.all;

entity System_Main is
  port (
    -- Entradas de control
    sys_reset : in  std_logic;
    sys_run   : in  std_logic;
    clk_in    : in  std_logic;
    
    -- NUEVO: Entrada de 2 bits para los switches
    i_eq_select : in  std_logic_vector(1 downto 0); -- [Switch_1, Switch_0]

    -- Salidas al display
    SEG_A  : out std_logic;  SEG_B  : out std_logic;  SEG_C  : out std_logic;
    SEG_D  : out std_logic;  SEG_E  : out std_logic;  SEG_F  : out std_logic;
    SEG_G  : out std_logic;  SEG_DP : out std_logic;
    DIG1   : out std_logic;  DIG2   : out std_logic;
    DIG3   : out std_logic;  DIG4   : out std_logic
  );
end entity System_Main;

architecture Behavioral of System_Main is

  -- MODIFICADO: Declaración del procesador actualizada
  component Processor_Unit is
    port (
      master_clk     : in  std_logic;
      master_reset   : in  std_logic;
      master_run     : in  std_logic;
      eq_select_in   : in  std_logic_vector(1 downto 0); -- NUEVO
      
      -- Salidas de segmento y dígitos
      o_seg_a      : out std_logic; o_seg_b : out std_logic; o_seg_c : out std_logic;
      o_seg_d      : out std_logic; o_seg_e : out std_logic; o_seg_f : out std_logic;
      o_seg_g      : out std_logic; o_seg_dp: out std_logic;
      o_dig1       : out std_logic; o_dig2 : out std_logic;
      o_dig3       : out std_logic; o_dig4 : out std_logic
    );
  end component;

  signal clk_internal : std_logic;

begin

  clk_internal <= clk_in;

  -- MODIFICADO: Instancia del procesador actualizada
  CPU_Inst : Processor_Unit
    port map (
      master_clk     => clk_internal,
      master_reset   => sys_reset,
      master_run     => sys_run,
      eq_select_in   => i_eq_select, -- NUEVO: Pasar los switches
      
      o_seg_a      => SEG_A,  o_seg_b => SEG_B,  o_seg_c => SEG_C,
      o_seg_d      => SEG_D,  o_seg_e => SEG_E,  o_seg_f => SEG_F,
      o_seg_g      => SEG_G,  o_seg_dp => SEG_DP,
      o_dig1       => DIG1,   o_dig2 => DIG2,
      o_dig3       => DIG3,   o_dig4 => DIG4
    );

end architecture Behavioral;