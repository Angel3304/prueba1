library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Multiplier_8x8 is
  port (
    A_in : in  std_logic_vector(7 downto 0);
    B_in : in  std_logic_vector(7 downto 0);
    -- El resultado de 8x8 bits es de 16 bits
    P_out : out std_logic_vector(15 downto 0)
  );
end entity Multiplier_8x8;

architecture Behavioral of Multiplier_8x8 is

  -- Usamos un tipo para almacenar los 8 productos parciales
  -- Cada producto parcial se alinea a 16 bits
  type t_partial_products is array (0 to 7) of unsigned(15 downto 0);
  signal partial_products : t_partial_products;

  -- Señal para el resultado final
  signal result : unsigned(15 downto 0);
  
begin

  -- 1. Generar los 8 productos parciales (Shift-and-AND)
  -- Esto es puramente combinacional
  Gen_Partial_Products : process(A_in, B_in)
    variable A_unsigned : unsigned(15 downto 0);
  begin
    A_unsigned := unsigned(x"00" & A_in); -- Convertir A a 16 bits

    for i in 0 to 7 loop
      if B_in(i) = '1' then
        -- Si B(i) es '1', el producto es A desplazado 'i' lugares
        partial_products(i) <= shift_left(A_unsigned, i);
      else
        -- Si B(i) es '0', el producto es 0
        partial_products(i) <= (others => '0');
      end if;
    end loop;
  end process Gen_Partial_Products;


  -- 2. Sumar todos los productos parciales
  -- Esto también es combinacional
  Sum_Products : process(partial_products)
    variable temp_sum : unsigned(15 downto 0);
  begin
    temp_sum := (others => '0');
    
    for i in 0 to 7 loop
      temp_sum := temp_sum + partial_products(i);
    end loop;
    
    result <= temp_sum;
  end process Sum_Products;

  -- 3. Asignar la salida
  P_out <= std_logic_vector(result);

end architecture Behavioral;