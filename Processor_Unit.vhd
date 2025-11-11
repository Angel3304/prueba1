--------------------------------------------------------------------
--  Processor_Unit.vhd
--  FSM + datapath + driver de display de 4 dígitos 7‑segmentos
--------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Seven_Segment_Pkg.all;           -- decode_to_segments

entity Processor_Unit is
  port(
    master_clk   : in  std_logic;
    master_reset : in  std_logic;          -- activo bajo
    master_run   : in  std_logic;          -- activo bajo

    ----------------------------------------------------------------
    --  Salidas del display (ánodo‑común, segmentos y dígitos activos‑bajo)
    ----------------------------------------------------------------
    o_seg_a      : out std_logic; o_seg_b : out std_logic; o_seg_c : out std_logic;
    o_seg_d      : out std_logic; o_seg_e : out std_logic; o_seg_f : out std_logic;
    o_seg_g      : out std_logic; o_seg_dp: out std_logic;
    o_dig1       : out std_logic; o_dig2 : out std_logic;
    o_dig3       : out std_logic; o_dig4 : out std_logic
  );
end entity Processor_Unit;

architecture Behavioral of Processor_Unit is
  ----------------------------------------------------------------
  --  Componentes internos
  ----------------------------------------------------------------
  component Memory_Store is
    port( Addr_in : in  std_logic_vector(7 downto 0);
          Data_bus: out std_logic_vector(23 downto 0) );
  end component;

  component Arithmetic_Logic_Module is
    port( op_A   : in  std_logic_vector(11 downto 0);
          op_B   : in  std_logic_vector(11 downto 0);
          op_Sel : in  std_logic_vector(3 downto 0);
          Result : out std_logic_vector(12 downto 0);
          z_out  : out std_logic );
  end component;

  component Clock_Divider_Unit is
    port ( clk_in         : in  std_logic;
           rst_in         : in  std_logic;
           pulse_1khz_out : out std_logic;
           pulse_1hz_out  : out std_logic );
  end component;

  ----------------------------------------------------------------
  --  FSM y registros de datapath
  ----------------------------------------------------------------
  type t_fsm_state is (s_fetch_1, s_fetch_2, s_decode, s_execute,
                       s_alu_writeback, s_load_x_1, s_load_x_2,
                       s_load_y_1, s_load_y_2, s_wait_pulse,
                       s_idle, s_go_to);
  signal fsm_state : t_fsm_state := s_fetch_1;

  signal prog_counter  : unsigned(7 downto 0) := (others => '0');
  signal instr_reg     : std_logic_vector(23 downto 0);
  signal mem_addr_reg  : std_logic_vector(7 downto 0);
  signal mem_data_bus  : std_logic_vector(23 downto 0);

  signal op_code   : std_logic_vector(7 downto 0);
  signal operand_1,
         operand_2 : std_logic_vector(7 downto 0);

  signal reg_X, reg_Y : std_logic_vector(11 downto 0) := (others => '0');

  signal arith_in_A, arith_in_B : std_logic_vector(11 downto 0);
  signal arith_op_sel           : std_logic_vector(3 downto 0);
  signal arith_out              : std_logic_vector(12 downto 0);
  signal zero_status_flag      : std_logic;
  signal z_flag_register       : std_logic := '0';

  signal output_buffer : std_logic_vector(11 downto 0) := (others => '0');

  -- Pulsos del divisor de reloj
  signal pulse_1hz,  pulse_1hz_last  : std_logic;
  signal pulse_1khz, pulse_1khz_last : std_logic;

  -- Selector del dígito que se muestra (0‑3)
  signal digit_selector : unsigned(1 downto 0);

  -- Conversor bin → BCD
  signal bcd_value, display_data : std_logic_vector(15 downto 0);

  -- Señales del driver del display
  signal anode_enable    : std_logic_vector(3 downto 0);
  signal cathode_segments: std_logic_vector(6 downto 0);
begin

  ----------------------------------------------------------------
  --  Instanciación de bloques
  ----------------------------------------------------------------
  U_Mem : Memory_Store
    port map ( Addr_in => mem_addr_reg,
               Data_bus=> mem_data_bus );

  U_ALM : Arithmetic_Logic_Module
    port map ( op_A   => arith_in_A,
               op_B   => arith_in_B,
               op_Sel => arith_op_sel,
               Result => arith_out,
               z_out  => zero_status_flag );

  U_Clk_Div : Clock_Divider_Unit
    port map ( clk_in         => master_clk,
               rst_in         => master_reset,
               pulse_1khz_out => pulse_1khz,
               pulse_1hz_out  => pulse_1hz );

  ----------------------------------------------------------------
  --  Descomposición de la instrucción
  ----------------------------------------------------------------
  op_code   <= instr_reg(23 downto 16);
  operand_1 <= instr_reg(15 downto 8);
  operand_2 <= instr_reg(7 downto 0);

  ----------------------------------------------------------------
  --  Máquina de estados (FSM)
  ----------------------------------------------------------------
  FSM_Process : process(master_clk)
  begin
    if rising_edge(master_clk) then
      ------------------------------------------------------------
      --  Registramos el flanco de 1 Hz (para detectar el borde)
      ------------------------------------------------------------
      pulse_1hz_last <= pulse_1hz;

      ------------------------------------------------------------
      --  Reset (activo bajo)
      ------------------------------------------------------------
      if master_reset = '0' then
        prog_counter      <= (others => '0');
        fsm_state         <= s_fetch_1;
        reg_X             <= (others => '0');
        reg_Y             <= (others => '0');
        output_buffer     <= (others => '0');
        z_flag_register   <= '0';
        pulse_1hz_last    <= '0';

      ------------------------------------------------------------
      --  Run desactivado (master_run = '0' → CPU parada)
      ------------------------------------------------------------
      elsif master_run = '1' then
        null;                                             -- mantiene el estado

      ------------------------------------------------------------
      --  Operación normal (run = '1')
      ------------------------------------------------------------
      else
        case fsm_state is

          ----------------------------------------------
          --  FETCH 1
          ----------------------------------------------
          when s_fetch_1 =>
            mem_addr_reg <= std_logic_vector(prog_counter);
            fsm_state    <= s_fetch_2;

          ----------------------------------------------
          --  FETCH 2
          ----------------------------------------------
          when s_fetch_2 =>
            instr_reg    <= mem_data_bus;
            prog_counter <= prog_counter + 1;
            fsm_state    <= s_decode;

          ----------------------------------------------
          --  DECODE
          ----------------------------------------------
          when s_decode =>
            arith_op_sel <= (others => '0');
            case op_code is
              when x"01" => fsm_state <= s_load_x_1;            -- LDX
              when x"02" => fsm_state <= s_load_y_1;            -- LDY
              when x"03" | x"04" | x"06" | x"08" | x"09"
                         => fsm_state <= s_execute;            -- ADD, ADDI, DISP, BNZ, SUB
              when x"07" => fsm_state <= s_go_to;               -- JUMP (no usado)
              when x"0A" => fsm_state <= s_wait_pulse;          -- WAIT
              when x"0F" => fsm_state <= s_idle;                -- STOP
              when others => fsm_state <= s_fetch_1;
            end case;

          ----------------------------------------------
          --  EXECUTE
          ----------------------------------------------
          when s_execute =>
            case op_code is

              when x"03" =>                                 -- ADD  (X+Y)
                arith_in_A   <= reg_X;
                arith_in_B   <= reg_Y;
                arith_op_sel <= "0110";                    -- ADD
                fsm_state    <= s_alu_writeback;

              when x"04" =>                                 -- ADDI (X+inmediato)
                arith_in_A   <= reg_X;
                arith_in_B   <= "0000" & operand_2;        -- inmediato 8 bits → 12 bits
                arith_op_sel <= "0110";                    -- ADD (igual que 03)
                fsm_state    <= s_alu_writeback;

              when x"09" =>                                 -- SUB  (X‑Y)
                arith_in_A   <= reg_X;
                arith_in_B   <= reg_Y;
                arith_op_sel <= "0111";                    -- SUB (B invertido + carry‑in = 1)
                fsm_state    <= s_alu_writeback;

              when x"06" =>                                 -- DISP
                output_buffer <= reg_X;
                fsm_state     <= s_fetch_1;

              when x"08" =>                                 -- BNZ (branch if NOT zero)
                if z_flag_register = '0' then
                  prog_counter <= unsigned(operand_1);
                end if;
                fsm_state <= s_fetch_1;

              when others =>
                fsm_state <= s_fetch_1;
            end case;

          ----------------------------------------------
          --  ALU WRITE‑BACK
          ----------------------------------------------
          when s_alu_writeback =>
            reg_X           <= arith_out(11 downto 0);
            z_flag_register <= zero_status_flag;
            fsm_state       <= s_fetch_1;

          ----------------------------------------------
          --  LOAD X (dos ciclos)
          ----------------------------------------------
          when s_load_x_1 =>
            mem_addr_reg <= operand_1;
            fsm_state    <= s_load_x_2;
          when s_load_x_2 =>
            reg_X   <= mem_data_bus(11 downto 0);
            fsm_state <= s_fetch_1;

          ----------------------------------------------
          --  LOAD Y (dos ciclos)
          ----------------------------------------------
          when s_load_y_1 =>
            mem_addr_reg <= operand_1;
            fsm_state    <= s_load_y_2;
          when s_load_y_2 =>
            reg_Y   <= mem_data_bus(11 downto 0);
            fsm_state <= s_fetch_1;

          ----------------------------------------------
          --  JUMP (no usado en este programa)
          ----------------------------------------------
          when s_go_to =>
            prog_counter <= unsigned(operand_1);
            fsm_state    <= s_fetch_1;

          ----------------------------------------------
          --  WAIT (retardo de 1 s)
          ----------------------------------------------
          when s_wait_pulse =>
            if pulse_1hz = '1' and pulse_1hz_last = '0' then
              fsm_state <= s_fetch_1;
            end if;

          ----------------------------------------------
          --  IDLE (después del STOP)
          ----------------------------------------------
          when s_idle =>
            null;                                         -- CPU detenido

          when others => fsm_state <= s_idle;
        end case;
      end if;
    end if;
  end process FSM_Process;

  ----------------------------------------------------------------
  --  Multiplexado 1 kHz (cambio de dígito)
  ----------------------------------------------------------------
  Mux_Tick_Gen : process(master_clk)
  begin
    if rising_edge(master_clk) then
      ------------------------------------------------------------
      --  Registramos el flanco de 1 kHz (para detectar el borde)
      ------------------------------------------------------------
      pulse_1khz_last <= pulse_1khz;

      ------------------------------------------------------------
      --  Reset
      ------------------------------------------------------------
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

  ----------------------------------------------------------------
  --  Conversor binario → BCD (double‑dabble)
  ----------------------------------------------------------------
  display_data <= bcd_value;
  Bin_to_BCD_Convert : process(output_buffer)
    variable bcd_temp : std_logic_vector(15 downto 0);
    variable bin_temp : std_logic_vector(11 downto 0);
  begin
    bcd_temp := (others => '0');
    bin_temp := output_buffer;
    for i in 0 to 11 loop
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
      bcd_temp(0)            := bin_temp(11);
      bin_temp(11 downto 0)  := bin_temp(10 downto 0) & '0';
    end loop;
    bcd_value <= bcd_temp;
  end process Bin_to_BCD_Convert;

  ----------------------------------------------------------------
  --  Driver del display (multiplexado)
  ----------------------------------------------------------------
  Display_Driver : process(digit_selector, display_data)
    variable current_digit_data : std_logic_vector(3 downto 0);
    -- Ya no se necesita is_blank
  begin
    
    case to_integer(digit_selector) is
      when 0 =>  -- UNIDADES (Activa o_dig1)
        anode_enable     <= "1110";  -- [dig4, dig3, dig2, dig1]
        current_digit_data := display_data(3 downto 0);
  
      when 1 =>  -- DECENAS (Activa o_dig2)
        anode_enable     <= "1101";  -- [dig4, dig3, dig2, dig1]
        current_digit_data := display_data(7 downto 4);
  
      when 2 =>  -- CENTENAS (Activa o_dig3)
        anode_enable     <= "1011";  -- [dig4, dig3, dig2, dig1]
        current_digit_data := display_data(11 downto 8);
  
      when others => -- MILLARES (Activa o_dig4)
        anode_enable     <= "0111";  -- [dig4, dig3, dig2, dig1]
        current_digit_data := display_data(15 downto 12);
    end case;

    ------------------------------------------------------------------
    --  CORRECCIÓN: Se elimina la lógica 'is_blank'
    --  Ahora siempre se decodifica y muestra el dígito.
    ------------------------------------------------------------------
    cathode_segments <= decode_to_segments(current_digit_data);

  end process Display_Driver;

  ----------------------------------------------------------------
  --  Salidas del display
  ----------------------------------------------------------------
  o_seg_dp <= '1';                                 -- punto decimal apagado

  -- El paquete devuelve g‑f‑e‑d‑c‑b‑a → asignamos a a‑b‑c‑d‑e‑f‑g
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
