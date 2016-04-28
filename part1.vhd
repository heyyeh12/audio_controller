LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY part1 IS
   PORT ( CLOCK_50, CLOCK_27, RESET, AUD_DACLRCK   : IN    STD_LOGIC;
          AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT  : IN    STD_LOGIC;
          KEY                                : IN    STD_LOGIC;
          I2C_SDAT                      : INOUT STD_LOGIC;
          I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT   STD_LOGIC
          
         
          
          );
END part1;

ARCHITECTURE Behavior OF part1 IS
   
	
--*********** FIFO Component *******************
component fifo is
generic
(
	constant FIFO_DATA_WIDTH : integer := 16;
	constant FIFO_BUFFER_SIZE : integer := 1024
);
port
(
	signal rd_clk : in std_logic;
	signal wr_clk : in std_logic;
	signal reset : in std_logic;
	signal rd_en : in std_logic;
	signal wr_en : in std_logic;
	signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
	signal full : out std_logic;
	signal empty : out std_logic
);
end component fifo;

--************* Audio Controller *********************************
component audio_controller IS
   PORT ( CLOCK_50, CLOCK_27, AUD_DACLRCK   : IN    STD_LOGIC;
          AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT  : IN    STD_LOGIC;
          RESET                                : IN    STD_LOGIC;
          I2C_SDAT                      : INOUT STD_LOGIC;
          I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT   STD_LOGIC;
          
          -- add fifo signals for LT / RT channels
          lt_fifo_dout : IN std_logic_vector(15 downto 0);
          lt_fifo_rd_en : OUT std_logic;
			 lt_fifo_empty : IN std_logic;
          rt_fifo_dout : IN std_logic_vector(15 downto 0);
          rt_fifo_rd_en : OUT std_logic;
			 rt_fifo_empty : IN std_logic
          );
END component audio_controller;
	
--***************************************************************************
 
	signal sin_counter_left, sin_counter_right : std_logic_vector(5 downto 0);
   signal sin_out    : std_logic_vector(15 downto 0);
 

	signal left_full, left_empty, lt_read_en, rt_read_en : std_logic;
   signal left_data_out : std_logic_vector(15 downto 0);
 
 
BEGIN

fifo_left_map : fifo generic map ( FIFO_DATA_WIDTH => 16, 
											  FIFO_BUFFER_SIZE => 1024)
							port map 	( rd_clk => CLOCK_50,
											  wr_clk => CLOCK_50,
											  reset => RESET,
											  rd_en => lt_read_en,
											  wr_en => lt_wr_en,
											  din => lt_sin_out,
											  dout => left_data_out,
											  full => left_full,
											  empty => left_empty);

fifo_right_map : fifo generic map ( FIFO_DATA_WIDTH => 16, 
											  FIFO_BUFFER_SIZE => 1024)
							port map 	( rd_clk => CLOCK_50,
											  wr_clk => CLOCK_50,
											  reset => RESET,
											  rd_en => rt_read_en,
											  wr_en => rt_wr_en,
											  din => rt_sin_out,
											  dout => right_data_out,
											  full => right_full,
											  empty => right_empty);											  
											  
											  


audio_controller_map : audio_controller port map (CLOCK_50 => CLOCK_50,
																  CLOCK_27 => CLOCK_27,
																  AUD_DACLRCK => AUD_DACLRCK,
																  AUD_ADCLRCK => AUD_ADCLRCK,
																  AUD_BCLK => AUD_BCLK,
																  AUD_ADCDAT => AUD_ADCDAT,
																  RESET => RESET,
																  I2C_SDAT => I2C_SDAT,
																  I2C_SCLK => I2C_SCLK,
																  AUD_DACDAT => AUD_DACDAT,
																  AUD_XCK => AUD_XCK,
																  lt_fifo_dout => left_data_out,
																  lt_fifo_rd_en => lt_read_en,
																  lt_fifo_empty => left_empty,
																  rt_fifo_dout => rt_data_out,
																  rt_fifo_rd_en => rt_read_en,
																  rt_fifo_empty => right_empty);
																  



	process(CLOCK_50, RESET)
 begin
	if ( RESET = '0' ) then
		sin_counter_left <= (others => '0');
	elsif ( rising_edge(CLOCK_50) AND left_full = '0' and right_full = '0') then
		--if ( lrck_lat = '1' and lrck = '0') then
			if (sin_counter_left = "101111") then
				sin_counter_left <= "000000";
			else
				sin_counter_left <= sin_counter_left + '1';
			end if;
		--end if;
	end if;
 end process;

 lt_fifo

 


process ( sin_counter_left )
 begin
	case sin_counter_left is
		when "000000" => sin_out <= X"0000";
		when "000001" => sin_out <= X"10b4";
		when "000010" => sin_out <= X"2120";
		when "000011" => sin_out <= X"30fb";
		when "000100" => sin_out <= X"3fff";
		when "000101" => sin_out <= X"4deb";
		when "000110" => sin_out <= X"5a81";
		when "000111" => sin_out <= X"658b";
		when "001000" => sin_out <= X"6ed9";
		when "001001" => sin_out <= X"7640";
		when "001010" => sin_out <= X"7ba2";
 when "001011" => sin_out <= X"7ee6";
 when "001100" => sin_out <= X"7fff";
 when "001101" => sin_out <= X"7ee6";
 when "001110" => sin_out <= X"7ba2";
 when "001111" => sin_out <= X"7640";
 when "010000" => sin_out <= X"6ed9";
 when "010001" => sin_out <= X"658b";
 when "010010" => sin_out <= X"5a81";
 when "010011" => sin_out <= X"4deb";
 when "010100" => sin_out <= X"3fff";
 when "010101" => sin_out <= X"30fb";
 when "010110" => sin_out <= X"2120";
 when "010111" => sin_out <= X"10b4";
 when "011000" => sin_out <= X"0000";
 when "011001" => sin_out <= X"ef4b";
 when "011010" => sin_out <= X"dee0";
 when "011011" => sin_out <= X"cf05";
 when "011100" => sin_out <= X"c001";
 when "011101" => sin_out <= X"b215";
 when "011110" => sin_out <= X"a57e";
 when "011111" => sin_out <= X"9a74";
 when "100000" => sin_out <= X"9127";
 when "100001" => sin_out <= X"89bf";
 when "100010" => sin_out <= X"845d";
 when "100011" => sin_out <= X"8119";
 when "100100" => sin_out <= X"8000";
 when "100101" => sin_out <= X"8119";
 when "100110" => sin_out <= X"845d";
 when "100111" => sin_out <= X"89bf";
 when "101000" => sin_out <= X"9127";
 when "101001" => sin_out <= X"9a74";
 when "101010" => sin_out <= X"a57e";
 when "101011" => sin_out <= X"b215";
 when "101100" => sin_out <= X"c000"; 
 when "101101" => sin_out <= X"cf05";
 when "101110" => sin_out <= X"dee0";
 when "101111" => sin_out <= X"ef4b";
 when others => sin_out <= X"0000";
 end case;
 end process;

 
											  
   
END Behavior;
