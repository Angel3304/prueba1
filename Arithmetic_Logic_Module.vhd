--------------------------------------------------------------------
--  Arithmetic_Logic_Module
--  (versión corregida para Quartus II / Cyclone IV)
--  ---------------------------------------------------------------
--  Operaciones soportadas:
--    * "0110" = ADD  (opB sin invertir, cin = 0)
--    * "0111" = ADDI (opB invertido,   cin = 1)
--    * cualquier otro código = operación nula (cin = 0, sin invertir)
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- para la conversión unsigned()

entity Arithmetic_Logic_Module is
  port (
    op_A   : in  std_logic_vector(11 downto 0);
    op_B   : in  std_logic_vector(11 downto 0);
    op_Sel : in  std_logic_vector(3 downto 0);
    Result : out std_logic_vector(12 downto 0);
    z_out  : out std_logic
  );
end entity Arithmetic_Logic_Module;

--------------------------------------------------------------------
architecture Behavioral of Arithmetic_Logic_Module is

  ------------------------------------------------------------------
  --  Componente del sumador de un bit (ripple‑carry adder)
  ------------------------------------------------------------------
  component bit_adder is
    port (
      a_in  : in  std_logic;
      b_in  : in  std_logic;
      c_in  : in  std_logic;
      s_out : out std_logic;
      c_out : out std_logic
    );
  end component;

  ------------------------------------------------------------------
  --  Señales internas
  ------------------------------------------------------------------
  signal b_modified   : std_logic_vector(11 downto 0);  -- op_B (posiblemente invertido)
  signal opB_inv_vec  : std_logic_vector(11 downto 0);  -- vector de 12 bits con el mismo valor opB_inv_bit
  signal c_internal   : std_logic_vector(12 downto 0);  -- carry en cadena
  signal s_internal   : std_logic_vector(11 downto 0);  -- suma de 12 bits
  signal opB_inv_bit, cin_bit : std_logic;            -- control de inversión y carry‑in

begin

  ------------------------------------------------------------------
  --  Decoder: a partir de op_Sel decide si se invierte op_B y cuál es el cin
  ------------------------------------------------------------------
  Decoder : process (op_Sel)
  begin
    case op_Sel is
      when "0110" =>                     -- ADD
        opB_inv_bit <= '0';
        cin_bit     <= '0';
      when "0111" =>                     -- ADDI (operación con complemento a 1 + carry‑in = 1)
        opB_inv_bit <= '1';
        cin_bit     <= '1';
      when others =>                     -- caso por defecto: nada de inversión
        opB_inv_bit <= '0';
        cin_bit     <= '0';
    end case;
  end process Decoder;

  ------------------------------------------------------------------
  --  Replicar opB_inv_bit a lo largo de 12 bits y aplicar XOR
  ------------------------------------------------------------------
  opB_inv_vec <= (others => opB_inv_bit);   -- 12 veces el mismo bit
  b_modified  <= op_B xor opB_inv_vec;      -- op_B ^ opB_inv_vec (bit‑a‑bit)

  ------------------------------------------------------------------
  --  Carry‑in inicial del sumador en cascada
  ------------------------------------------------------------------
  c_internal(0) <= cin_bit;

  ------------------------------------------------------------------
  --  Generador de los 12 bit_adder (ripple‑carry adder)
  ------------------------------------------------------------------
  RCA_Generate : for i in 0 to 11 generate
    Adder_Instance : bit_adder
      port map (
        a_in  => op_A(i),
        b_in  => b_modified(i),
        c_in  => c_internal(i),
        s_out => s_internal(i),
        c_out => c_internal(i+1)
      );
  end generate RCA_Generate;

  ------------------------------------------------------------------
  --  Resultado final (carry final + suma de 12 bits)
  ------------------------------------------------------------------
  Result <= c_internal(12) & s_internal;  -- 13‑bits: C12·S11…S0

  ------------------------------------------------------------------
  --  Zero‑flag: se activa cuando la suma (sin el carry final) es cero
  ------------------------------------------------------------------
  z_out <= '1' when unsigned(s_internal) = 0 else '0';

end architecture Behavioral;
