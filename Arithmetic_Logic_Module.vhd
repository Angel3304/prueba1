library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Arithmetic_Logic_Module is
  port (
    -- Entradas de 16 bits
    op_A   : in  std_logic_vector(15 downto 0);
    op_B   : in  std_logic_vector(15 downto 0);
    op_Sel : in  std_logic_vector(3 downto 0);
    
    -- Salida de 17 bits (Resultado + Carry)
    Result : out std_logic_vector(16 downto 0);
    
    -- Salidas de Banderas (Flags)
    z_out  : out std_logic; -- Zero Flag
    s_out  : out std_logic; -- Sign Flag
    c_out  : out std_logic; -- Carry Flag
    ov_out : out std_logic  -- Overflow Flag
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

  signal b_modified   : std_logic_vector(15 downto 0);
  signal opB_inv_vec  : std_logic_vector(15 downto 0);
  signal c_internal   : std_logic_vector(16 downto 0); -- Aumentado a 16+1
  signal s_internal   : std_logic_vector(15 downto 0);
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
      when "0111" =>                     -- SUB (B invertido + carry-in = 1)
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
  --  Carry-in inicial
  ----------------------------------------------------------------
  c_internal(0) <= cin_bit;
  
  ----------------------------------------------------------------
  --  Ripple-carry adder de 16-bits
  ----------------------------------------------------------------
  RCA_Generate : for i in 0 to 15 generate -- Cambiado de 11 a 15
    Adder_Instance : bit_adder
      port map ( a_in  => op_A(i),
                 b_in  => b_modified(i),
                 c_in  => c_internal(i),
                 s_out => s_internal(i),
                 c_out => c_internal(i+1) );
  end generate;
  
  ----------------------------------------------------------------
  --  Resultado (carry final + 16 bits de suma)
  ----------------------------------------------------------------
  Result <= c_internal(16) & s_internal;
  
  ----------------------------------------------------------------
  --  Cálculo de Banderas (Flags)
  ----------------------------------------------------------------
  
  -- Zero-flag (Z): '1' si los 16 bits del resultado son 0
  z_out <= '1' when unsigned(s_internal) = 0 else '0';
  
  -- Sign-flag (S): Es el bit más significativo (MSB) del resultado
  s_out <= s_internal(15);
  
  -- Carry-flag (C): Es el acarreo final del sumador
  c_out <= c_internal(16);
  
  -- Overflow-flag (OV): XOR del carry-in al bit de signo y el carry-out
  ov_out <= c_internal(15) xor c_internal(16);

end architecture Behavioral;