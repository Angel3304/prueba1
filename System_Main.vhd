library ieee;
use ieee.std_logic_1164.all;

entity System_Main is
  port(
    sys_reset : in  std_logic;
    sys_run   : in  std_logic;
    
    SEG_A     : out std_logic; SEG_B     : out std_logic; SEG_C     : out std_logic;
    SEG_D     : out std_logic; SEG_E     : out std_logic; SEG_F     : out std_logic;
    SEG_G     : out std_logic; SEG_DP    : out std_logic; DIG1      : out std_logic;
    DIG2      : out std_logic; DIG3      : out std_logic; DIG4      : out std_logic
  );
end entity;

architecture Behavioral of System_Main is
  component OSCH
    generic (NOM_FREQ : string := "53.20");
    port( STDBY: in std_logic; OSC: out std_logic; SEDSTDBY: out std_logic );
  end component;
  
  component Processor_Unit is
    port(
      master_clk      : in  std_logic;
      master_reset    : in  std_logic;
      master_run      : in  std_logic;
      o_seg_a         : out std_logic; o_seg_b : out std_logic; o_seg_c : out std_logic;
      o_seg_d         : out std_logic; o_seg_e : out std_logic; o_seg_f : out std_logic;
      o_seg_g         : out std_logic; o_seg_dp: out std_logic; o_dig1  : out std_logic;
      o_dig2          : out std_logic; o_dig3  : out std_logic; o_dig4  : out std_logic
    );
  end component;
  
  signal clk_signal, clk_dummy : std_logic;
  
begin

  Oscillator_Inst: OSCH 
    generic map (NOM_FREQ => "53.20") 
    port map (STDBY=>'0', OSC=>clk_signal, SEDSTDBY=>clk_dummy);
    
  CPU_Inst: Processor_Unit port map(
    master_clk   => clk_signal,
    master_reset => sys_reset,
    master_run   => sys_run,
    o_seg_a => SEG_A, o_seg_b => SEG_B, o_seg_c => SEG_C,
    o_seg_d => SEG_D, o_seg_e => SEG_E, o_seg_f => SEG_F,
    o_seg_g => SEG_G, o_seg_dp => SEG_DP, o_dig1 => DIG1,
    o_dig2  => DIG2,  o_dig3 => DIG3,  o_dig4 => DIG4
  );
  
end architecture;