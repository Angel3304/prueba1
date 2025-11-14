library ieee;
use ieee.std_logic_1164.all;

entity Clock_Divider_Unit is
  port (
    clk_in         : in  std_logic;
    rst_in         : in  std_logic;
    pulse_1khz_out : out std_logic;
    pulse_1hz_out  : out std_logic
  );
end entity;

architecture Behavioral of Clock_Divider_Unit is
  constant COUNT_1HZ  : integer := 500;   -- 53,200,000 ciclos = 1 s
  constant COUNT_1KHZ : integer := 53199;     -- 53,200 ciclos = 1 ms

  signal counter_1hz  : integer range 0 to COUNT_1HZ  := 0;
  signal counter_1khz : integer range 0 to COUNT_1KHZ := 0;
  signal tick_1hz_reg, tick_1khz_reg : std_logic := '0';
begin
  pulse_1hz_out  <= tick_1hz_reg;
  pulse_1khz_out <= tick_1khz_reg;

  Divider_Process : process(clk_in, rst_in)
  begin
    if rst_in = '0' then                         -- reset activo bajo
      counter_1hz   <= 0;
      counter_1khz  <= 0;
      tick_1hz_reg  <= '0';
      tick_1khz_reg <= '0';
    elsif rising_edge(clk_in) then
      -- 1 Hz
      if counter_1hz = COUNT_1HZ then
        counter_1hz  <= 0;
        tick_1hz_reg <= '1';
      else
        counter_1hz  <= counter_1hz + 1;
        tick_1hz_reg <= '0';
      end if;
      -- 1 kHz
      if counter_1khz = COUNT_1KHZ then
        counter_1khz  <= 0;
        tick_1khz_reg <= '1';
      else
        counter_1khz  <= counter_1khz + 1;
        tick_1khz_reg <= '0';
      end if;
    end if;
  end process Divider_Process;
end architecture;
