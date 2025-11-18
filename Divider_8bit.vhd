library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider_8bit is
  port (
    -- Control
    clk   : in  std_logic;
    rst   : in  std_logic; -- Reset (activo bajo)
    start : in  std_logic; -- Pulso de 1 ciclo para iniciar
    
    -- Entradas (8 bits)
    A_in  : in  std_logic_vector(7 downto 0); -- Dividendo
    B_in  : in  std_logic_vector(7 downto 0); -- Divisor
    
    -- Salidas
    Q_out : out std_logic_vector(7 downto 0); -- Cociente
    R_out : out std_logic_vector(7 downto 0); -- Residuo
    done  : out std_logic                     -- '1' cuando termina
  );
end entity Divider_8bit;

architecture Behavioral of Divider_8bit is
  
  type t_div_state is (s_idle, s_busy, s_done);
  signal state       : t_div_state := s_idle;
  
  -- Registros internos
  signal A_reg     : unsigned(7 downto 0) := (others => '0'); -- Cociente
  signal R_reg     : unsigned(8 downto 0) := (others => '0'); -- Residuo (necesita 1 bit extra)
  signal B_reg     : unsigned(7 downto 0) := (others => '0');
  signal count     : integer range 0 to 8 := 0;
  
begin

  -- Proceso secuencial (la máquina de estados del divisor)
  Divider_Process : process(clk, rst)
    -- Variables para el cálculo interno (se actualizan inmediatamente)
    variable R_var : unsigned(8 downto 0);
    variable A_var : unsigned(7 downto 0);
  begin
    if rst = '0' then
      state   <= s_idle;
      A_reg   <= (others => '0');
      R_reg   <= (others => '0');
      B_reg   <= (others => '0');
      count   <= 0;
      done    <= '0';
      
    elsif rising_edge(clk) then
      
      case state is
        
        -- ESTADO 1: Esperando la señal de 'start'
        when s_idle =>
          done <= '0';
          if start = '1' then
            -- Cargar valores iniciales en los REGISTROS
            A_reg   <= unsigned(A_in);
            B_reg   <= unsigned(B_in);
            R_reg   <= (others => '0'); -- Residuo empieza en 0
            count   <= 8;               -- 8 bits = 8 ciclos
            state   <= s_busy;
          end if;
          
        -- ESTADO 2: Ocupado, procesando
        when s_busy =>
          -- Cargar las variables desde los registros del ciclo anterior
          R_var := R_reg;
          A_var := A_reg;
          
          -- 1. Desplazar (Shift-Left) R_var y A_var
          -- El bit más alto de A_var entra en R_var
          R_var := (R_var(7 downto 0) & A_var(7));
          A_var := (A_var(6 downto 0) & '0'); -- (El LSB se llenará con el bit del cociente)
          
          -- 2. Comparar y restar (Algoritmo de Restauración)
          if R_var >= ("0" & B_reg) then
            -- Resta es posible
            R_var := R_var - ("0" & B_reg);
            A_var(0) := '1'; -- Bit del cociente es 1
          else
            -- Resta no es posible
            -- R_var no cambia (se "restaura")
            A_var(0) := '0'; -- Bit del cociente es 0
          end if;
          
          -- Guardar los nuevos valores de las variables en los registros
          A_reg <= A_var;
          R_reg <= R_var;
          
          -- Decrementar contador
          count <= count - 1;
          
          -- Comprobar si terminamos
          if (count = 1) then -- (Este es el último ciclo, después de esto count será 0)
            state <= s_done;
          end if;

        -- ESTADO 3: Terminado
        when s_done =>
          done  <= '1';
          state <= s_idle;
          
      end case;
    end if;
  end process Divider_Process;

  -- Asignar salidas
  Q_out <= std_logic_vector(A_reg); -- Cociente
  R_out <= std_logic_vector(R_reg(7 downto 0)); -- Residuo

end architecture Behavioral;