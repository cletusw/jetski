library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_segment_display is
	generic(
		counter_bits: natural := 15
	);
	port (
		clk : in  STD_LOGIC;
		data_in : in  STD_LOGIC_VECTOR (15 downto 0);
		dp_in : in  STD_LOGIC_VECTOR (3 downto 0);
		blank : in  STD_LOGIC_VECTOR (3 downto 0);
		seg : out  STD_LOGIC_VECTOR (6 downto 0);
		dp : out  STD_LOGIC;
		an : out  STD_LOGIC_VECTOR (3 downto 0)
	);
end seven_segment_display;

architecture Behavioral of seven_segment_display is
	signal count : unsigned(counter_bits-1 downto 0) := (others => '0');
	signal anode_select : unsigned(1 downto 0);
	signal value_to_display : std_logic_vector (3 downto 0);
	signal notan : std_logic_vector (3 downto 0); 
begin
	anode_select <= count(counter_bits-1 downto counter_bits-2);
	process(anode_select,dp_in,data_in)
	 begin
		case anode_select is
			when "00" =>
				dp <= (not dp_in(0));
				value_to_display <= data_in(3 downto 0);
				notan <= "1110";
			when "01" =>
				dp <= (not dp_in(1));
				value_to_display <= data_in(7 downto 4);
				notan <= "1101";
			when "10" =>
				dp <= (not dp_in(2));
				value_to_display <= data_in(11 downto 8);
				notan <= "1011";
			when others =>
				dp <= (not dp_in(3));
				value_to_display <= data_in(15 downto 12);
				notan <= "0111";
		end case;
	 end process;
	an <= notan or blank;
	with value_to_display select		
		seg <= "1000000" when"0000",
			"1111001" when "0001",
			"0100100" when "0010",
			"0110000" when "0011",
			"0011001" when "0100",
			"0010010" when "0101",
			"0000010" when "0110",
			"1111000" when "0111",
			"0000000" when "1000",
			"0010000" when "1001",
			"0001000" when "1010",
			"0000011" when "1011",
			"1000110" when "1100",
			"0100001" when "1101",
			"0000110" when "1110",
			"0001110" when others;
		process(clk)
		begin
			if (clk' event and clk = '1') then
			count <= count +1;
			end if;
		end process;

end Behavioral;

