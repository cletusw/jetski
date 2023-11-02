library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx is
	generic(
		CLK_RATE: natural := 50_000_000;
		BAUD_RATE : natural := 19_200
	);
	port (
		clk : in  std_logic;
		rst : in  std_logic;
		rx_in : in  std_logic;
		data_out : out  std_logic_vector (7 downto 0);
		data_strobe : out  std_logic;
		rx_busy : out  std_logic
	);
end rx;

architecture Behavioral of rx is
	function log2c(n : integer) return integer is 
		variable m, p : integer;
	begin
		m := 0;
		p := 1;
		while p < n loop
			m := m+1;
			p:= p*2;
		end loop;
		return m;
	end log2c;

	constant BIT_COUNTER_MAX_VAL : natural := CLK_RATE / BAUD_RATE - 1;
	constant BIT_COUNTER_BITS : natural := log2c(BIT_COUNTER_MAX_VAL);
	constant HALF_BIT_COUNTER_MAX_VAL : natural := (CLK_RATE / BAUD_RATE - 1)/2;
	constant HALF_BIT_COUNTER_BITS : natural := log2c(HALF_BIT_COUNTER_MAX_VAL);

	--FSM
	type state_type is (power_up, idle, half_wait, start, b0, b1, b2, b3, b4, b5, b6, b7, stop, error);
	signal state_reg : state_type := power_up;
	
	--bit timer
	signal bit_count, bit_count_next : unsigned (BIT_COUNTER_BITS - 1 downto 0) := (others => '0');
	signal half_bit_count, half_bit_count_next : unsigned (HALF_BIT_COUNTER_BITS - 1 downto 0) := (others => '0');
	signal bit_rst, half_bit_rst : std_logic;
	signal rx_bit, rx_half_bit: std_logic := '0';
	
	--shift register
	signal load : std_logic; 
	signal shift_reg, shift_reg_next : std_logic_vector(7 downto 0) := (others => '1');


begin
	----------------------------------------
	-- UART FSM
	----------------------------------------
	process(clk,rst)
		begin 
			if rst = '1' then
				state_reg <= power_up;
			elsif clk'event and clk = '1' then
				rx_busy <= '1';  --    DEFAULTS
				load <= '0';
				bit_rst <= '0';
				half_bit_rst <= '0';
				data_strobe <= '0';
				
				case state_reg is
					when power_up =>
						if rx_in = '1' then
							state_reg <= idle;
						end if;
					when idle =>
						if rx_in = '0' then
							state_reg <= half_wait;  
						end if;
						rx_busy <= '0';
						half_bit_rst <= '1';
						bit_rst <= '1';
					when half_wait =>
						if rx_half_bit = '1' then
							state_reg <= start;
						end if;
						bit_rst <= '1';
					when start =>
						if rx_bit = '1' then
							state_reg <= b0;
							load <= '1';
						end if;
					when b0 =>
						if rx_bit = '1' then
							state_reg <= b1;
							load <= '1';
						end if;
					when b1 =>
						if rx_bit = '1' then
							state_reg <= b2;
							load <= '1';
						end if;
					when b2 =>
						if rx_bit = '1' then
							state_reg <= b3;
							load <= '1';
						end if;
					when b3 =>
						if rx_bit = '1' then
							state_reg <= b4;
							load <= '1';
						end if;
					when b4 =>
						if rx_bit = '1' then
							state_reg <= b5;
							load <= '1';
						end if;
					when b5 =>
						if rx_bit = '1' then
							state_reg <= b6;
							load <= '1';
						end if;
					when b6 =>
						if rx_bit = '1' then
							state_reg <= b7;
							load <= '1';
						end if;
					when b7 =>
						if rx_bit = '1' then
							state_reg <= stop;
						end if;
					when stop =>
						if rx_in = '0' then
							state_reg <= error;
						else --if rx_half_bit = '1' then
							state_reg <= idle;
							data_strobe <= '1';
						end if;
					when error =>
						if rx_in = '1' then
							state_reg <= idle;
						end if;
				end case;
			end if;
	end process;


	----------------------------------------
	-- Bit Timers
	----------------------------------------
	process(clk,rst)
		begin 
			if rst = '1' then
				bit_count <= (others => '0');
				half_bit_count <= (others => '0');
			elsif clk'event and clk = '1' then
				bit_count <= bit_count_next;
				half_bit_count <= half_bit_count_next;
			end if;
		end process;

	bit_count_next <= (others => '0') when (bit_rst = '1') or (bit_count >= BIT_COUNTER_MAX_VAL) else
		bit_count +1;
	half_bit_count_next <= (others => '0') when (half_bit_rst = '1') or (half_bit_count >= HALF_BIT_COUNTER_MAX_VAL) else
		half_bit_count +1;
	rx_bit <= '1' when bit_count = BIT_COUNTER_MAX_VAL else 
		'0';
	rx_half_bit <= '1' when half_bit_count = HALF_BIT_COUNTER_MAX_VAL else 
		'0';


	----------------------------------------
	-- Shift Register
	----------------------------------------
	process(clk,rst)
		begin 
			if rst = '1' then
				shift_reg <= (others => '1');
			elsif clk'event and clk = '1' then
				shift_reg <= shift_reg_next;
			end if;
	end process;
		
	shift_reg_next <= rx_in & shift_reg(7 downto 1) when (load = '1') else
		shift_reg;
		
	data_out <= shift_reg;
end Behavioral;

