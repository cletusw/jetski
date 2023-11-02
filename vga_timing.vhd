library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_timing is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           HS : out  STD_LOGIC;
           VS : out  STD_LOGIC;
           pixel_x : out  STD_LOGIC_VECTOR (9 downto 0);
           pixel_y : out  STD_LOGIC_VECTOR (9 downto 0);
           last_column : out  STD_LOGIC;
           last_row : out  STD_LOGIC;
           blank : out  STD_LOGIC);
end vga_timing;

architecture Behavioral of vga_timing is
	signal pixel_en: std_logic := '0';
	signal x, y: unsigned (9 downto 0) := "0000000000";
begin
	-- Generate 25MHz pixel_en
	process(clk,rst)
	begin
		if rst='1' then
			pixel_en <= '0';
		elsif (clk'event and clk='1') then
			pixel_en <= not pixel_en;
		end if;
	end process;
	
	-- Horizontal Pixel Counter
	process(clk,pixel_en,rst,x)
	begin
		if (rst = '1') then
			x <= (others => '0');
		elsif (clk'event and clk = '1' and pixel_en = '1') then
			x <= x + 1;
		end if;
		
		if (x = to_unsigned(800, 10)) then
			x <= (others => '0');
		end if;
	end process;
	pixel_x <= std_logic_vector(x);
	
	-- Horizontal Sync
	process(x)
	begin
		if (x > to_unsigned(655, 10) and x < to_unsigned(752, 10)) then
			HS <= '0';
		else
			HS <= '1';
		end if;
	end process;
	
	last_column <= '1' when x = to_unsigned(639, 10) else '0';

	--Line Counter
	process(clk,x,rst,y)
	begin
		if (rst = '1') then
			y <= (others => '0');
		elsif (clk'event and clk = '1' and x = to_unsigned(639, 10) and pixel_en = '1') then
			y <= y + 1;
		end if;
		
		if (y = to_unsigned(521, 10)) then
			y <= (others => '0');
		end if;
	end process;
	pixel_y <= std_logic_vector(y);
	
	-- Vertical Sync
	process(y)
	begin
		if (y > to_unsigned(489, 10) and y < to_unsigned(492, 10)) then
			VS <= '0';
		else
			VS <= '1';
		end if;
	end process;
	
	last_row <= '1' when y = to_unsigned(479, 10) else '0';
	
	blank <= '1' when (x > to_unsigned(639, 10) or y > to_unsigned(479, 10)) else '0';
end Behavioral;

