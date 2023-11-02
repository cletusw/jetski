library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity JetSki is
	port (
		clk : in  std_logic;
		rst : in  std_logic;
		RsRx : in  std_logic;
		vgaRed : out  std_logic_vector (2 downto 0);
		vgaGreen : out  std_logic_vector (2 downto 0);
		vgaBlue : out  std_logic_vector (1 downto 0);
		Hsync : out  std_logic;
		Vsync : out  std_logic;
		seg : out  STD_LOGIC_VECTOR (6 downto 0);
		dp : out  STD_LOGIC;
		an : out  STD_LOGIC_VECTOR (3 downto 0);
		Led : out std_logic_vector (2 downto 0)
	);
end JetSki;

architecture Behavioral of JetSki is
	-- FSM
	type state_type is (forward, down, up);
	signal state_reg, state_next : state_type;
	signal upKey, downKey : std_logic;
	
	-- Timer
	constant TIMER_SIZE : natural := 23;
	signal timer_reg, timer_next : unsigned(TIMER_SIZE-1 downto 0);
	signal pulse, timer_reset : std_logic;
	
	-- UART Receiver
	signal key : std_logic_vector(7 downto 0);
	signal data_strobe : std_logic;
	signal rx_buf1, rx_buf2: std_logic;
	constant ASCII_a : std_logic_vector(7 downto 0) := "01100001";
	constant ASCII_z : std_logic_vector(7 downto 0) := "01111010";

	-- Frame counter
	signal frame, frame_next : unsigned(15 downto 0) := "0000000000000000";

	-- Display Timer
	constant DISPLAY_TIMER_SIZE : natural := 20;
	signal display_timer_reg, display_timer_next : unsigned(DISPLAY_TIMER_SIZE-1 downto 0);
	signal display_pulse : std_logic;

	-- VGA Rendering
	signal pixel_x, pixel_y : unsigned(9 downto 0);
	signal x, y : std_logic_vector(9 downto 0);
	signal rgb_out, border_rgb, jetski_rgb, rock_rgb : std_logic_vector(7 downto 0);
	signal border_on, jetski_on, rock_on, blank: std_logic;
	signal jetski_y, jetski_next : unsigned(9 downto 0) := "0110000000";
	signal rock_x, rock_next : unsigned(9 downto 0) := "0111111111";
begin
	----------------------------------------
	-- FSM
	----------------------------------------
	process(clk, rst)
	begin
		if (rst = '1') then
			state_reg <= forward;
		elsif (clk'event and clk = '1') then
			state_reg <= state_next;
		end if;
	end process;
	
	process(state_reg, upKey, downKey, pulse)
	begin
		-- Defaults
		state_next <= state_reg;
		timer_reset <= '0';
		
		case state_reg is
			when forward =>
				if upKey = '1' then
					state_next <= up;
				elsif downKey = '1' then
					state_next <= down;
				end if;
				timer_reset <= '1';
			when down =>
				if downKey = '1' then
					state_next <= down;
					timer_reset <= '1';
				elsif pulse = '1' then
					state_next <= forward;
				end if;
			when up =>
				if upKey = '1' then
					state_next <= up;
					timer_reset <= '1';
				elsif pulse = '1' then
					state_next <= forward;
				end if;
		end case;
	end process;
	
	upKey <= '1' when (data_strobe = '1' and key = ASCII_a) else
		'0';
	downKey <= '1' when (data_strobe = '1' and key = ASCII_z) else
		'0';
	
	----------------------------------------
	-- Timer
	----------------------------------------
	process(clk, rst)
	begin
		if (rst = '1') then
			timer_reg <= (others => '0');
		elsif (clk'event and clk = '1') then
			timer_reg <= timer_next;
		end if;
	end process;
	
	timer_next <= timer_reg - 1 when (timer_reg > 0 and timer_reset = '0') else
		(others => '1');
	pulse <= '1' when (timer_reg = 0) else
		'0';
	
	
	----------------------------------------
	-- UART Receiver
	----------------------------------------
	uart : entity work.rx
		port map(
			clk => clk,
			rst => rst,
			rx_in => rx_buf1,
			data_out => key,
			data_strobe => data_strobe
		);
	
	process(clk, rst)
	begin 
		if (rst = '1') then
			rx_buf1 <= '0';
			rx_buf2 <= '0';
		elsif (clk'event and clk = '1') then
			rx_buf1 <= rx_buf2;
			rx_buf2 <= RsRx;
		end if;
	end process;
	
	----------------------------------------
	-- Frame Counter
	----------------------------------------
	Seven : entity work.seven_segment_display
		port map(
			clk => clk,
			data_in => std_logic_vector(frame),
			dp_in => "0000",
			blank => "0000",
			seg => seg,
			dp => dp,
			an => an
		);
	
	process(clk)
	begin
		if(clk'event and clk = '1') then
			jetski_y <= jetski_next;
			rock_x <= rock_next;
			frame <= frame_next;
		end if;
	end process;
	
	frame_next <= frame + 1 when display_pulse = '1' else
		frame;
	
	
	----------------------------------------
	-- Display Timer
	----------------------------------------
	process(clk, rst)
	begin
		if (rst = '1') then
			display_timer_reg <= (others => '0');
		elsif (clk'event and clk = '1') then
			display_timer_reg <= display_timer_next;
		end if;
	end process;
	
	display_timer_next <= display_timer_reg - 1 when (display_timer_reg > 0) else
		(others => '1');
	display_pulse <= '1' when (display_timer_reg = 0) else
		'0';
	
	
	----------------------------------------
	-- VGA Rendering
	----------------------------------------
	Timing : entity work.vga_timing
		port map(
			clk => clk,
			rst => '0',
			HS => Hsync,
			VS => Vsync,
			pixel_x => x,
			pixel_y => y,
			blank => blank
		);
	
	pixel_x <= unsigned(x);
	pixel_y <= unsigned(y);

	jetski_next <= --jetski_y +2 when (display_pulse = '1' and jetski_y < 420) else
		--jetski_y -2 when (display_pulse = '1' and jetski_y >= 10) else
		jetski_y;

	rock_next <= rock_x -2 when (display_pulse = '1' and rock_x < 680) else
		rock_x;

	--banks
	border_on <= '1' when (pixel_y >= 0 and pixel_y < 60) or (pixel_y >= 420 and pixel_y <480)
		else '0';
	border_rgb <= "000" & "110" & "00"; -- color?

	--squares
	jetski_on <= '1' when pixel_x >= 20 and 
			pixel_x < 41 and
			pixel_y >= jetski_y and 
			pixel_y < jetski_y + 20 else
		'0';
	jetski_rgb <= "111"  & "111" & "00";

	rock_on <= '1' when pixel_x >= rock_x-20 and 
			pixel_x < rock_x and
			pixel_y >= 140 and 
			pixel_y < 210 else
		'0';
	rock_rgb <= "000"  & "000" & "00";

	rgb_out <= border_rgb when border_on = '1' else
		jetski_rgb when jetski_on = '1' else
		rock_rgb when rock_on = '1' else
		--ball_rgb when ball_on = '1' else
		"00000011";

	vgaRed <= "000" when blank = '1' else 
		rgb_out(7 downto 5);
	vgaGreen <= "000" when blank = '1' else
		rgb_out(4 downto 2);
	vgaBlue <= "00" when blank = '1' else
		rgb_out(1 downto 0);
	
	
	----------------------------------------
	-- Debugging
	----------------------------------------
	Led(2) <= '1' when (state_reg = down) else
		'0';
	Led(1) <= '1' when (state_reg = forward) else
		'0';
	Led(0) <= '1' when (state_reg = up) else
		'0';

end Behavioral;

