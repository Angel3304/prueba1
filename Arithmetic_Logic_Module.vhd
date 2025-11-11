library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Arithmetic_Logic_Module is
  port (
    op_A   : in  std_logic_vector(11 downto 0);
    op_B   : in  std_logic_vector(11 downto 0);
    op_Sel : in  std_logic_vector(3 downto 0);
    Result : out std_logic_vector(12 downto 0);
    z_out  : out std_logic
  );
end entity Arithmetic_Logic_Module;

architecture Behavioral of Arithmetic_Logic_Module is
  component bit_adder is
    port ( a_in  : in  std_logic;
           b_in  : in  std_logic;
           c_in  : in  std_logic;
           s_out : out std_logic;
           c_out : out std_logic );
  end component;

  signal b_modified   : std_logic_vector(11 downto 0);
  signal opB_inv_vec  : std_logic_vector(11 downto 0);
  signal c_internal   : std_logic_vector(12 downto 0);
  signal s_internal   : std_logic_vector(11 downto 0);
  signal opB_inv_bit, cin_bit : std_logic;
begin

  ----------------------------------------------------------------
  --  Decoder (selectores de operación)
  ----------------------------------------------------------------
  Decoder : process(op_Sel)
  begin
    case op_Sel is
      when "0110" =>                     -- ADD
        opB_inv_bit <= '0';
        cin_bit     <= '0';
      when "0111" =>                     -- SUB (B invertido + carry‑in = 1)
        opB_inv_bit <= '1';
        cin_bit     <= '1';
      when others =>                     -- NOP / operación nula
        opB_inv_bit <= '0';
        cin_bit     <= '0';
    end case;
  end process Decoder;

  ----------------------------------------------------------------
  --  Preparación de B (posible complemento a 1)
  ----------------------------------------------------------------
  opB_inv_vec <= (others => opB_inv_bit);
  b_modified  <= op_B xor opB_inv_vec;

  ----------------------------------------------------------------
  --  Carry‑in inicial
  ----------------------------------------------------------------
  c_internal(0) <= cin_bit;

  ----------------------------------------------------------------
  --  Ripple‑carry adder de 12 bits
  ----------------------------------------------------------------
  RCA_Generate : for i in 0 to 11 generate
    Adder_Instance : bit_adder
      port map ( a_in  => op_A(i),
                 b_in  => b_modified(i),
                 c_in  => c_internal(i),
                 s_out => s_internal(i),
                 c_out => c_internal(i+1) );
  end generate;

  ----------------------------------------------------------------
  --  Resultado (carry final + 12 bits de suma)
  ----------------------------------------------------------------
  Result <= c_internal(12) & s_internal;

  ----------------------------------------------------------------
  --  Zero‑flag (sin contar el carry final)
  ----------------------------------------------------------------
  z_out <= '1' when unsigned(s_internal) = 0 else '0';

end architecture Behavioral;
