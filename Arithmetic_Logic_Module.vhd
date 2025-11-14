library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Arithmetic_Logic_Module is
  port (
    op_A   : in  std_logic_vector(15 downto 0);
    op_B   : in  std_logic_vector(15 downto 0);
    op_Sel : in  std_logic_vector(3 downto 0);
    Result : out std_logic_vector(16 downto 0); -- [Carry(16), Suma(15..0)]
    z_out  : out std_logic;
    s_out  : out std_logic;
    c_out  : out std_logic;
    ov_out : out std_logic
  );
end entity Arithmetic_Logic_Module;

architecture Behavioral of Arithmetic_Logic_Module is

  -- Componente 1: Sumador completo de 1 bit (de tu proyecto)
  component bit_adder is
    port ( a_in  : in  std_logic;
           b_in  : in  std_logic;
           c_in  : in  std_logic;
           s_out : out std_logic;
           c_out : out std_logic );
  end component;
  
  -- Componente 2: Multiplicador 8x8 (el nuevo componente)
  component Multiplier_8x8 is
    port (
      A_in : in  std_logic_vector(7 downto 0);
      B_in : in  std_logic_vector(7 downto 0);
      P_out : out std_logic_vector(15 downto 0)
    );
  end component;
  
  -- Señales para el Sumador/Restador
  signal b_modified     : std_logic_vector(15 downto 0);
  signal opB_inv_vec    : std_logic_vector(15 downto 0);
  signal c_internal     : std_logic_vector(16 downto 0); -- [16..0]
  signal s_internal     : std_logic_vector(15 downto 0);
  signal opB_inv_bit, cin_bit : std_logic;
  signal alu_carry_out  : std_logic; -- Carry "real" del sumador (bit 16)

  -- Señales para los resultados
  signal addsub_result  : std_logic_vector(15 downto 0);
  signal mul_result     : std_logic_vector(15 downto 0);
  
  -- Señal para el resultado final de 16 bits
  signal final_result_16b : std_logic_vector(15 downto 0);

begin

  ----------------------------------------------------------------
  -- Bloque 1: Sumador / Restador (ADD, SUB, CMP)
  ----------------------------------------------------------------
  -- Decide la operación del sumador basado en op_Sel
  opB_inv_bit <= '1' when op_Sel = "0111" else '0'; -- Invertir B para SUB/CMP
  cin_bit     <= '1' when op_Sel = "0111" else '0'; -- Carry In para SUB/CMP
  
  opB_inv_vec <= (others => opB_inv_bit);
  b_modified  <= op_B xor opB_inv_vec;
  c_internal(0) <= cin_bit;
  
  RCA_Generate : for i in 0 to 15 generate
    Adder_Instance : bit_adder
      port map ( a_in  => op_A(i),
                 b_in  => b_modified(i),
                 c_in  => c_internal(i),
                 s_out => s_internal(i),
                 c_out => c_internal(i+1) );
  end generate;
  
  addsub_result <= s_internal;
  alu_carry_out <= c_internal(16); -- Captura el carry "real"

  ----------------------------------------------------------------
  -- Bloque 2: Multiplicador (8x8)
  ----------------------------------------------------------------
  U_Multiplier : Multiplier_8x8
    port map (
      A_in  => op_A(7 downto 0), -- Toma los 8 bits inferiores
      B_in  => op_B(7 downto 0), -- Toma los 8 bits inferiores
      P_out => mul_result       -- Devuelve 16 bits
    );
                
  ----------------------------------------------------------------
  -- Bloque 3: MUX de Resultado Final y Banderas
  ----------------------------------------------------------------
  MUX_Process : process(op_Sel, addsub_result, mul_result, alu_carry_out, c_internal, final_result_16b)
  begin
    -- Por defecto, banderas en 0
    z_out  <= '0';
    s_out  <= '0';
    c_out  <= '0';
    ov_out <= '0';
    
    case op_Sel is
      when "0110" =>                     -- ADD
        final_result_16b <= addsub_result;
        c_out            <= alu_carry_out; -- C = Carry
        ov_out           <= c_internal(15) xor c_internal(16);

      when "0111" =>                     -- SUB (o CMP)
        final_result_16b <= addsub_result;
        c_out            <= not alu_carry_out; -- C = not(Borrow)
        ov_out           <= c_internal(15) xor c_internal(16);

      when "1000" =>                     -- MUL (8x8)
        final_result_16b <= mul_result;
        -- C y OV se quedan en '0'

      when others =>
        final_result_16b <= (others => '0');
    end case;
	 
	 if unsigned(final_result_16b) = 0 then
        z_out <= '1';
    else
        z_out <= '0';
    end if;
    
    s_out <= final_result_16b(15);
	 
  end process MUX_Process;
  
  -- Salida final (Resultado + Carry)
  -- El "carry" de la ALU (bit 16) solo es válido para ADD/SUB.
  Result <= alu_carry_out & final_result_16b;

end architecture Behavioral;