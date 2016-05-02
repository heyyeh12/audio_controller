LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY part1 IS
   PORT ( CLOCK_50, CLOCK_27, RESET, AUD_DACLRCK   : IN    STD_LOGIC;
          AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT  : IN    STD_LOGIC;
          I2C_SDAT                      : INOUT STD_LOGIC;
          I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT   STD_LOGIC;
          
	  lt_sin_values, rt_sin_values : out std_logic_vector(15 downto 0);
	  lt_signal, rt_signal : OUT std_logic_vector(23 downto 0)
          
          );
END part1;

ARCHITECTURE Behavior OF part1 IS
   
	
--*********** FIFO Component *******************
component fifo is
generic
(
	constant FIFO_DATA_WIDTH : integer := 24;
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
          lt_fifo_dout : IN std_logic_vector(23 downto 0);
          lt_fifo_rd_en : OUT std_logic;
	  lt_fifo_empty : IN std_logic;
          rt_fifo_dout : IN std_logic_vector(23 downto 0);
          rt_fifo_rd_en : OUT std_logic;
	  rt_fifo_empty : IN std_logic;
	  lt_signal, rt_signal : OUT std_logic_vector(23 downto 0)
          );
END component audio_controller;
	
--***************************************************************************
   type sin_table is array (47 downto 0) of std_logic_vector(23 downto 0);
   type snare_table is array (255 downto 0) of std_logic_vector(23 downto 0);

	constant sin_values : sin_table := 
	( X"000000", X"0010b4", X"002120", X"0030fb", X"003fff", X"004deb", X"005a81", X"00658b",X"006ed9",X"007640", X"007ba2",
    X"007ee6", X"007fff", X"007ee6", X"007ba2", X"007640", X"006ed9", X"00658b", X"005a81", X"004deb", X"003fff", X"0030fb",
    X"002120", X"0010b4", X"000000", X"ffef4b", X"ffdee0", X"ffcf05", X"ffc001", X"ffb215", X"ffa57e", X"ff9a74", X"ff9127", 
	 X"ff89bf", X"ff845d", X"ff8119", X"ff8000", X"ff8119", X"ff845d", X"ff89bf", X"ff9127", X"ff9a74", X"ffa57e", X"ffb215",
   X"ffc000", X"ffcf05", X"ffdee0", X"ffef4b");
 

	constant snare_values : snare_table :=
	(
 x"000000",  x"0000fe",  x"feffff",  x"ff0000",  x"000000",  x"000000",  x"000000",  x"000000",
 x"000000",  x"000000",  x"000000",  x"000000",  x"000000",  x"000000",  x"000000",  x"000000",
 x"000000",  x"000000",  x"000000",  x"0000fe",  x"feffff",  x"ff0000",  x"0000e6",  x"e6ffff",
 x"ff14fe",  x"feff2f",  x"2feeff",  x"ff7fa9",  x"a9ffb2",  x"b216ff",  x"ff9c90",  x"90fe89",
 x"8988fe",  x"feffea",  x"eafe5b",  x"5b3e00",  x"00cc41",  x"41029f",  x"9f6801",  x"019d0f",
 x"0fffa8",  x"a898ff",  x"ff4b71",  x"7101dc",  x"dc2606",  x"0665f8",  x"f8fcee",  x"eee4e7",
 x"e7c115",  x"15e8f0",  x"f0b7ee",  x"eea094",  x"94f9c8",  x"c813fe",  x"fe9ecd",  x"cd0766",
 x"666b15",  x"15c374",  x"74f6d8",  x"d808ed",  x"ed8ba7",  x"a7001e",  x"1ecb16",  x"16d304",
 x"0430c8",  x"c8cc3d",  x"3d8f0f",  x"0f3021",  x"215109",  x"093e58",  x"58f689",  x"893cfb",
 x"fbe010",  x"100bcf",  x"cf5d27",  x"27f386",  x"86555b",  x"5bbf6f",  x"6fe352",  x"5258d0",
 x"d00e55",  x"550454",  x"544288",  x"88da26",  x"260dc7",  x"c730d7",  x"d7040f",  x"0fb5ab",
 x"abf45c",  x"5ca5dd",  x"dd7cfa",  x"facde8",  x"e81cc4",  x"c4c2b3",  x"b3d2ba",  x"ba42ea",
 x"ea75ae",  x"aef1c3",  x"c37bc8",  x"c85fd5",  x"d5b4aa",  x"aac8ab",  x"abafd9",  x"d9adeb",
 x"ebfaaa",  x"aafbcb",  x"cb9e38",  x"38059a",  x"9ac8ca",  x"ca8f17",  x"177781",  x"81dbac",
 x"ac943f",  x"3f7b9f",  x"9f6ad6",  x"d695a7",  x"a7b19d",  x"9d94b2",  x"b28a84",  x"84fe91",
 x"9183b7",  x"b7b3e6",  x"e683d1",  x"d14ebd",  x"bde913",  x"1307ee",  x"ee737c",  x"7ce0a1",
 x"a10dd9",  x"d96101",  x"01de27",  x"27380c",  x"0cc907",  x"071de5",  x"e5e833",  x"33039d",
 x"9d3fa5",  x"a5e44e",  x"4e7b10",  x"104d18",  x"18ef51",  x"517b04",  x"043593",  x"93864d",
 x"4dd79b",  x"9b5958",  x"58c958",  x"58f681",  x"815a0a",  x"0a0f63",  x"6313c8",  x"c852ac",
 x"ac9e4c",  x"4c08d4",  x"d45452",  x"526d5c",  x"5c869a",  x"9a683f",  x"3f1b60",  x"609c8b",
 x"8b54d1",  x"d1836d",  x"6d5c26",  x"2668f9",  x"f92b5f",  x"5f6f46",  x"46637e",  x"7ec95d",
 x"5dfea1",  x"a15d3b",  x"3b0559",  x"597574",  x"743d35",  x"35832a",  x"2ae84e",  x"4e18be",
 x"be9f15",  x"153e67",  x"6734b2",  x"b2ce2b",  x"2be1b8",  x"b82cc6",  x"c6b233",  x"33125f",
 x"5f351d",  x"1df632",  x"32af64",  x"640874",  x"745c06",  x"0662e9",  x"e90ada",  x"da3efe",
 x"feceb0",  x"b0de9f",  x"9fd0c1",  x"c15ba0",  x"a0aa65",  x"65e5a6",  x"a6dbe8",  x"e8b314",
 x"14b8be",  x"bec467",  x"67aa36",  x"3614b5",  x"b51528",  x"28d02a",  x"2ad7d2",  x"d242ba",
 x"bad085",  x"85ffe3",  x"e32ece",  x"cee1d3",  x"d34abc",  x"bc32c3",  x"c3a43e",  x"3ec3ac",
 x"accf48",  x"48b428",  x"2866b2",  x"b2ccf2",  x"f2a273",  x"737da1",  x"a17a18",  x"18a6cd",
 x"cde4ac",  x"ac2c70",  x"70c7c2",  x"c255cf",  x"cf3fe4",  x"e4b8bf",  x"bf95c6",  x"c62ff1",
 x"f1c929",  x"292dc3",  x"c3a9e9",  x"e9c83b",  x"3bbbc1",  x"c1d77c",  x"7cb4be",  x"be87b5",
 x"b5ca8f",  x"8fc1f0",  x"f0dbdc",  x"dc1f88",  x"88efcc",  x"ccdff5",  x"f50bad",  x"adfaa1",
 x"a1f1e6",  x"e6b973",  x"73e699",  x"992fd5",  x"d5ec3f",  x"3fcd7b",  x"7b4dc1",  x"c18b75"
);

constant table_size : integer := 48;


 
	--signal sin_counter_left, sin_counter_right : std_logic_vector(5 downto 0);
  	--signal sin_out    : std_logic_vector(15 downto 0);
 
 
	signal lt_sin_addr, rt_sin_addr : integer := 0;
	
        signal left_data_out, right_data_out : std_logic_vector(23 downto 0);
	signal lt_sin_out, rt_sin_out : std_logic_vector(23 downto 0);
	signal left_full, right_full, left_empty, right_empty, lt_wr_en, rt_wr_en, lt_read_en, rt_read_en : std_logic;
 
 
BEGIN

fifo_left_map : fifo generic map ( FIFO_DATA_WIDTH => 24, 
				   FIFO_BUFFER_SIZE => 1024)
		     port map 	 ( rd_clk => CLOCK_50,
				   wr_clk => CLOCK_50,
				   reset => RESET,
				   rd_en => lt_read_en,
				   wr_en => lt_wr_en,
				   din => lt_sin_out,
				   dout => left_data_out,
				   full => left_full,
				   empty => left_empty);

fifo_right_map : fifo generic map ( FIFO_DATA_WIDTH => 24, 
				   FIFO_BUFFER_SIZE => 1024)
		      port map 	  ( rd_clk => CLOCK_50,
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
						rt_fifo_dout => right_data_out,
						rt_fifo_rd_en => rt_read_en,
						rt_fifo_empty => right_empty,
						lt_signal => lt_signal,
						rt_signal => rt_signal);


														  
																  

process (CLOCK_50, RESET)
begin
	
	if(RESET = '1') then
		lt_wr_en <= '0';
		rt_wr_en <= '0';
		lt_sin_addr <= 0;
		rt_sin_addr <= 0;
	elsif (rising_edge(CLOCK_50)) then

		--report "lt_fifo_enable is " &std_logic'image(lt_read_en);
		--report  "rt_fifo_enable is " &std_logic'image(rt_read_en);

--*************Sin Wave**************************************
		lt_sin_out <= sin_values(lt_sin_addr);
		rt_sin_out <= sin_values(rt_sin_addr);																	  

--*************Snare Wave**************************************
		--lt_sin_out <= snare_values(lt_sin_addr);
		--rt_sin_out <= snare_values(rt_sin_addr);


		

		if (left_full = '0') then
			lt_wr_en <= '1';
			if (lt_sin_addr >= table_size - 1) then
				lt_sin_addr <= 0;
			elsif (lt_wr_en = '1') then
				lt_sin_addr <= lt_sin_addr + 1;
				--report "Incrementing Left " & integer'image(lt_sin_addr);
			end if;
		end if;
		if (right_full = '0') then
			rt_wr_en <= '1';
			if (rt_sin_addr >= table_size - 1) then
				rt_sin_addr <= 0;
			elsif(rt_wr_en = '1') then
				rt_sin_addr <= lt_sin_addr + 1;
				--report "Incrementing Right " & integer'image(rt_sin_addr);
			end if;
		end if;
	end if;
	end process;



 
											  
   
END Behavior;
