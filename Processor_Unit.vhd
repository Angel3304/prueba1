library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Seven_Segment_Pkg.all;

entity Processor_Unit is
  port(
    master_clk   : in  std_logic;
    master_reset : in  std_logic;
    master_run   : in  std_logic;
    o_seg_a      : out std_logic; o_seg_b : out std_logic; o_seg_c : out std_logic;
    o_seg_d      : out std_logic; o_seg_e : out std_logic; o_seg_f : out std_logic;
    o_seg_g      : out std_logic; o_seg_dp: out std_logic;
    o_dig1       : out std_logic; o_dig2 : out std_logic;
    o_dig3       : out std_logic; o_dig4 : out std_logic
  );
end entity Processor_Unit;

architecture Behavioral of Processor_Unit is
  
  component Memory_Store is
    port(
      clk      : in  std_logic;
      we       : in  std_logic;
      Addr_in  : in  std_logic_vector(7 downto 0);
      Data_in  : in  std_logic_vector(23 downto 0);
      Data_out : out std_logic_vector(23 downto 0)
    );
  end component;

  component Arithmetic_Logic_Module is
    port (
      op_A   : in  std_logic_vector(15 downto 0);
      op_B   : in  std_logic_vector(15 downto 0);
      op_Sel : in  std_logic_vector(3 downto 0);
      Result : out std_logic_vector(16 downto 0);
      z_out  : out std_logic;
      s_out  : out std_logic;
      c_out  : out std_logic;
      ov_out : out std_logic
    );
  end component;

  component Clock_Divider_Unit is
    port ( clk_in         : in  std_logic;
           rst_in         : in  std_logic;
           pulse_1khz_out : out std_logic;
           pulse_1hz_out  : out std_logic );
  end component;
  
  component Divider_8bit is
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      start : in  std_logic;
      A_in  : in  std_logic_vector(7 downto 0);
      B_in  : in  std_logic_vector(7 downto 0);
      Q_out : out std_logic_vector(7 downto 0);
      R_out : out std_logic_vector(7 downto 0);
      done  : out std_logic
    );
  end component;
  constant OP_STX : std_logic_vector(7 downto 0) := x"11";
  
  type t_fsm_state is (s_fetch_1, s_fetch_2, s_decode, s_execute,
                       s_alu_writeback, s_load_x_1, s_load_x_2,
                       s_load_y_1, s_load_y_2, s_wait_pulse,
                       s_idle, s_go_to,
                       s_div_start, s_div_wait, s_div_read,
                       s_store_1); -- <-- NUEVO
                       
  signal fsm_state : t_fsm_state := s_fetch_1;
  
  signal prog_counter  : unsigned(7 downto 0) := (others => '0');
  signal instr_reg     : std_logic_vector(23 downto 0);
  
  signal mem_addr_reg     : std_logic_vector(7 downto 0); -- (Ya existía)
  signal mem_data_from_ram : std_logic_vector(23 downto 0); -- (Antes 'mem_data_bus')
  signal mem_data_to_ram   : std_logic_vector(23 downto 0); -- NUEVO
  signal mem_we           : std_logic := '0';              -- NUEVO

  signal op_code   : std_logic_vector(7 downto 0);
  signal operand_1,
         operand_2 : std_logic_vector(7 downto 0);
         
  signal reg_X, reg_Y : std_logic_vector(15 downto 0) := (others => '0');
  signal arith_in_A, arith_in_B : std_logic_vector(15 downto 0);
  signal arith_op_sel           : std_logic_vector(3 downto 0);
  signal arith_out              : std_logic_vector(16 downto 0);
  
  signal z_flag_alu, s_flag_alu, c_flag_alu, ov_flag_alu : std_logic;
  
  -- Mapeo: 3=Z, 2=S, 1=C, 0=OV
  signal status_register       : std_logic_vector(3 downto 0) := "0000";
  
  signal output_buffer : std_logic_vector(15 downto 0) := (others => '0');
  
  signal pulse_1hz,  pulse_1hz_last  : std_logic;
  signal pulse_1khz, pulse_1khz_last : std_logic;
  signal digit_selector : unsigned(1 downto 0);
  signal bcd_value, display_data : std_logic_vector(15 downto 0);
  signal anode_enable    : std_logic_vector(3 downto 0);
  signal cathode_segments: std_logic_vector(6 downto 0);
  
  -- Señales para controlar el divisor
  signal div_start      : std_logic := '0';
  signal div_done       : std_logic;
  signal div_quotient   : std_logic_vector(7 downto 0);
  signal div_remainder  : std_logic_vector(7 downto 0);
begin

  U_Mem : Memory_Store
    port map (
      clk      => master_clk,
      we       => mem_we,
      Addr_in  => mem_addr_reg,
      Data_in  => mem_data_to_ram,
      Data_out => mem_data_from_ram
    );
               
  U_ALM : Arithmetic_Logic_Module
    port map ( op_A   => arith_in_A,
               op_B   => arith_in_B,
               op_Sel => arith_op_sel,
               Result => arith_out,
               z_out  => z_flag_alu,
               s_out  => s_flag_alu,
               c_out  => c_flag_alu,
               ov_out => ov_flag_alu );
               
  U_Clk_Div : Clock_Divider_Unit
    port map ( clk_in         => master_clk,
               rst_in         => master_reset,
               pulse_1khz_out => pulse_1khz,
               pulse_1hz_out  => pulse_1hz );
	
	U_Div : Divider_8bit
    port map (
      clk   => master_clk,
      rst   => master_reset,
      start => div_start,
      A_in  => reg_X(7 downto 0), -- Toma el dividendo de reg_X
      B_in  => reg_Y(7 downto 0), -- Toma el divisor de reg_Y
      Q_out => div_quotient,
      R_out => div_remainder,
      done  => div_done
    );

  op_code   <= instr_reg(23 downto 16);
  operand_1 <= instr_reg(15 downto 8);
  operand_2 <= instr_reg(7 downto 0);

FSM_Process : process(master_clk)
  begin
    if rising_edge(master_clk) then
      pulse_1hz_last <= pulse_1hz;
		
		div_start <= '0';
		
		mem_we <= '0';
      
      if master_reset = '0' then
        prog_counter      <= (others => '0');
        fsm_state         <= s_fetch_1;
        reg_X             <= (others => '0');
        reg_Y             <= (others => '0');
        output_buffer     <= (others => '0');
        status_register   <= (others => '0');
        pulse_1hz_last    <= '0';
		  div_start <= '0';
		  mem_we <= '0';
        
      elsif master_run = '1' then
        null;
        
      else
        case fsm_state is

          ----------------------------------------------
          --  FETCH 1: Apuntar PC a la memoria
          ----------------------------------------------
          when s_fetch_1 =>
            mem_addr_reg <= std_logic_vector(prog_counter);
            fsm_state    <= s_fetch_2;

          ----------------------------------------------
          --  FETCH 2: Leer instrucción
          ----------------------------------------------
          when s_fetch_2 =>
            instr_reg    <= mem_data_from_ram;
            -- MODIFICADO: El incremento del PC se mueve a s_decode
            fsm_state    <= s_decode;
            
          ----------------------------------------------
          --  DECODE: Decodificar y decidir incremento de PC
          ----------------------------------------------
          when s_decode =>
            arith_op_sel <= (others => '0');
            prog_counter <= prog_counter + 1;
            
            case op_code is
              when x"01" => fsm_state <= s_load_x_1;
              when x"02" => fsm_state <= s_load_y_1;
              when x"03" | x"04" | x"05" |
                   x"06" | x"09" | x"0E"
                         => fsm_state <= s_execute;
                         
              -- MODIFICADO: Si es un salto, NO incrementa el PC
              when x"07" | x"08" | x"0B" | x"0C" | x"0D" =>
                prog_counter <= prog_counter; -- Mantiene el PC
                fsm_state    <= s_execute;
                
              when x"0A" => fsm_state <= s_wait_pulse;
              when x"0F" => fsm_state <= s_idle;
				  when x"10" => 
						prog_counter <= prog_counter; -- para no incrementar nuevamente
						fsm_state <= s_div_start;
					when OP_STX => -- x"11"
                fsm_state <= s_store_1;
						
              when others => fsm_state <= s_fetch_1;
            end case;

          ----------------------------------------------
          --  EXECUTE: Ejecutar la instrucción
          ----------------------------------------------
          when s_execute =>
            -- Por defecto, avanza al siguiente fetch
            fsm_state <= s_fetch_1;
            
            case op_code is
              when x"03" =>                                 -- ADD  (X+Y)
                arith_in_A   <= reg_X;
                arith_in_B   <= reg_Y;
                arith_op_sel <= "0110";
                fsm_state    <= s_alu_writeback;
                
              when x"04" =>                                 -- ADDI (X+inmediato)
                arith_in_A   <= reg_X;
                arith_in_B   <= x"00" & operand_2;
                arith_op_sel <= "0110";
                fsm_state    <= s_alu_writeback;
                
              -- NUEVO: Lógica para CMP (X-Y)
              when x"05" =>                                 -- CMP (X-Y)
                arith_in_A   <= reg_X;
                arith_in_B   <= reg_Y;
                arith_op_sel <= "0111";                    -- SUB
                fsm_state    <= s_alu_writeback;           -- Va a guardar banderas
                
              when x"06" =>                                 -- DISP
                output_buffer <= reg_X;
                fsm_state     <= s_fetch_1;
                
              when x"09" =>                                 -- SUB  (X-Y)
                arith_in_A   <= reg_X;
                arith_in_B   <= reg_Y;
                arith_op_sel <= "0111";
                fsm_state    <= s_alu_writeback;
				  when x"0E" =>                                 -- MUL (8x8)
                arith_in_A   <= reg_X;
                arith_in_B   <= reg_Y;
                arith_op_sel <= "1000";
                fsm_state    <= s_alu_writeback;
            
              -- MODIFICADO: Lógica de saltos
              -- Ahora el PC se actualiza a PC+1 o a la dirección de salto
              
              when x"07" => -- JUMP (no usado)
                prog_counter <= unsigned(operand_1);

              when x"08" => -- BNZ (Branch if NOT zero)
                if status_register(3) = '0' then
                  prog_counter <= unsigned(operand_1); -- Salta
                else
                  prog_counter <= prog_counter + 1; -- No salta (va a PC+1)
                end if;

              when x"0B" => -- BS (Branch on Sign)
                if status_register(2) = '1' then
                  prog_counter <= unsigned(operand_1); -- Salta
                else
                  prog_counter <= prog_counter + 1; -- No salta (va a PC+1)
                end if;

              when x"0C" => -- BNC (Branch on Not Carry)
                if status_register(1) = '0' then
                  prog_counter <= unsigned(operand_1); -- Salta
                else
                  prog_counter <= prog_counter + 1; -- No salta (va a PC+1)
                end if;

              when x"0D" => -- BNV (Branch on Not Overflow)
                if status_register(0) = '0' then
                  prog_counter <= unsigned(operand_1); -- Salta
                else
                  prog_counter <= prog_counter + 1; -- No salta (va a PC+1)
                end if;
                
              when others =>
                null; -- No hace nada más
            end case;

          ----------------------------------------------
          --  (El resto de estados: s_alu_writeback, 
          --   s_load_x, s_load_y, s_wait_pulse, s_idle
          --   NO TIENEN CAMBIOS)
          ----------------------------------------------

          when s_alu_writeback =>
            if op_code = x"03" or op_code = x"04" or op_code = x"09" or
               op_code = x"0E" then
              reg_X <= arith_out(15 downto 0); -- Guarda el resultado de 16b
            end if;
				
            status_register(3) <= z_flag_alu;
            status_register(2) <= s_flag_alu;
            status_register(1) <= c_flag_alu;
            status_register(0) <= ov_flag_alu;
            fsm_state       <= s_fetch_1;
            
          when s_load_x_1 =>
            mem_addr_reg <= operand_1;
            fsm_state    <= s_load_x_2;
          when s_load_x_2 =>
            reg_X   <= mem_data_from_ram(15 downto 0);
            fsm_state <= s_fetch_1;

          when s_load_y_1 =>
            mem_addr_reg <= operand_1;
            fsm_state    <= s_load_y_2;
          when s_load_y_2 =>
            reg_Y   <= mem_data_from_ram(15 downto 0);
            fsm_state <= s_fetch_1;

          when s_wait_pulse =>
            if pulse_1hz = '1' and pulse_1hz_last = '0' then
              fsm_state <= s_fetch_1;
            end if;

          when s_idle =>
            null;
			 when s_div_start =>
            div_start <= '1'; -- Activar el divisor por 1 ciclo
            fsm_state <= s_div_wait; -- Moverse a esperar
            
          when s_div_wait =>
            if div_done = '1' then
              fsm_state <= s_div_read; -- Terminado, ir a leer
            else
              fsm_state <= s_div_wait; -- No terminado, seguir esperando
            end if;
            
          when s_div_read =>
            -- Guardar resultado (Cociente 8 bits) en los 8 bits bajos de reg_X
            reg_X <= x"00" & div_quotient;
            
            -- Guardar Residuo en los 8 bits bajos de reg_Y (opcional, pero útil)
            reg_Y <= x"00" & div_remainder; 
            
            -- Actualizar banderas Z y S (C y OV se quedan en 0)
            status_register <= "0000"; -- Resetear
            if unsigned(div_quotient) = 0 then
              status_register(3) <= '1'; -- Z-flag
            end if;
            status_register(2) <= div_quotient(7); -- S-flag
            
            prog_counter <= prog_counter + 1; -- Incrementar PC
            fsm_state    <= s_fetch_1;        -- Volver a fetch
			 when s_store_1 =>
            mem_addr_reg    <= operand_1; -- Poner la dirección
            mem_data_to_ram <= x"00" & reg_X; -- Poner los datos (16 bits)
            mem_we          <= '1';        -- Activar escritura
            fsm_state       <= s_fetch_1;

          when others => fsm_state <= s_idle;
        end case;
      end if;
    end if;
  end process FSM_Process;

  -- (El resto del archivo: Mux_Tick_Gen, Bin_to_BCD_Convert, Display_Driver)
  -- (No necesitan cambios)

  Mux_Tick_Gen : process(master_clk)
  begin
    if rising_edge(master_clk) then
      pulse_1khz_last <= pulse_1khz;
      if master_reset = '0' then
        digit_selector  <= "00";
        pulse_1khz_last <= '0';
      else
        if pulse_1khz = '1' and pulse_1khz_last = '0' then
          digit_selector <= digit_selector + 1;
        end if;
      end if;
    end if;
  end process Mux_Tick_Gen;

  display_data <= bcd_value;
  Bin_to_BCD_Convert : process(output_buffer)
    variable bcd_temp : std_logic_vector(15 downto 0);
    variable bin_temp : std_logic_vector(15 downto 0);
  begin
    bcd_temp := (others => '0');
    bin_temp := output_buffer;
    for i in 0 to 15 loop
      if bcd_temp(3  downto 0)  > "0100" then
        bcd_temp(3  downto 0)  := std_logic_vector(unsigned(bcd_temp(3  downto 0)) + 3);
      end if;
      if bcd_temp(7  downto 4)  > "0100" then
        bcd_temp(7  downto 4)  := std_logic_vector(unsigned(bcd_temp(7  downto 4)) + 3);
      end if;
      if bcd_temp(11 downto 8)  > "0100" then
        bcd_temp(11 downto 8)  := std_logic_vector(unsigned(bcd_temp(11 downto 8)) + 3);
      end if;
      if bcd_temp(15 downto 12) > "0100" then
        bcd_temp(15 downto 12) := std_logic_vector(unsigned(bcd_temp(15 downto 12)) + 3);
      end if;

      bcd_temp(15 downto 1) := bcd_temp(14 downto 0);
      bcd_temp(0)            := bin_temp(15);
      bin_temp(15 downto 0)  := bin_temp(14 downto 0) & '0';
    end loop;
    bcd_value <= bcd_temp;
  end process Bin_to_BCD_Convert;

  Display_Driver : process(digit_selector, display_data)
    variable current_digit_data : std_logic_vector(3 downto 0);
  begin
    case to_integer(digit_selector) is
      when 0 =>
        anode_enable     <= "1110";
        current_digit_data := display_data(3 downto 0);
      when 1 =>
        anode_enable     <= "1101";
        current_digit_data := display_data(7 downto 4);
      when 2 =>
        anode_enable     <= "1011";
        current_digit_data := display_data(11 downto 8);
      when others =>
        anode_enable     <= "0111";
        current_digit_data := display_data(15 downto 12);
    end case;
    cathode_segments <= decode_to_segments(current_digit_data);
  end process Display_Driver;

  o_seg_dp <= '1';
  o_seg_a <= cathode_segments(6);
  o_seg_b <= cathode_segments(5);
  o_seg_c <= cathode_segments(4);
  o_seg_d <= cathode_segments(3);
  o_seg_e <= cathode_segments(2);
  o_seg_f <= cathode_segments(1);
  o_seg_g <= cathode_segments(0);
  
  o_dig1 <= anode_enable(0);
  o_dig2 <= anode_enable(1);
  o_dig3 <= anode_enable(2);
  o_dig4 <= anode_enable(3);

end architecture Behavioral;