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
   type table is array (47 downto 0) of std_logic_vector(15 downto 0);
	
	constant sin_values : table := 
	(X"0000", X"10b4", X"2120", X"30fb", X"3fff", X"4deb", X"5a81", X"658b",X"6ed9",X"7640", X"7ba2",
    X"7ee6", X"7fff", X"7ee6", X"7ba2", X"7640", X"6ed9", X"658b", X"5a81", X"4deb", X"3fff", X"30fb",
    X"2120", X"10b4", X"0000", X"ef4b", X"dee0", X"cf05", X"c001", X"b215", X"a57e", X"9a74", X"9127", 
	 X"89bf", X"845d", X"8119", X"8000", X"8119", X"845d", X"89bf", X"9127", X"9a74", X"a57e", X"b215",
    X"c000", X"cf05", X"dee0", X"ef4b", X"0000");
 
 
	signal sin_counter_left, sin_counter_right : std_logic_vector(5 downto 0);
   signal sin_out    : std_logic_vector(15 downto 0);
 
 
	signal lt_sin_addr, rt_sin_addr : integer := 0;
	
 

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
																  

lt_sin_out <= sin_values(lt_sin_addr);
rt_sin_out <= sin_values(rt_sin_addr);																  
																  

process (CLOCK_50, RESET)
begin
	if(RESET = '1') then
		lt_fifo_wr_en <= '0';
		rt_fifo_wr_en <= '0';
		lt_sin_addr <= 0;
		rt_sin_addr <= 0;
	elsif (rising_edge(CLOCK_50)) then
		if (left_full = '0') then
			lt_fifo_wr_en <= '1';
			lt_sin_addr <= lt_sin_addr + 1;
		end if;
		if (right_full = '0') then
			rt_fifo_wr_en <= '1';
			rt_sin_addr <= rt_sin_addr + 1;
		end if;
	end if;
	end process;



 
											  
   
END Behavior;
