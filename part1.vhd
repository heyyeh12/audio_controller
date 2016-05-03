LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY part1 IS
   PORT ( CLOCK_50, CLOCK_27, RESET, AUD_DACLRCK   : IN    STD_LOGIC;
          AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT  : IN    STD_LOGIC;
          I2C_SDAT                      : INOUT STD_LOGIC;
          I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT   STD_LOGIC;
          lt_hit, rt_hit : IN STD_LOGIC;
          -- SIMULATION
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
   PORT ( 
          -- CODEC & BOARD SIGNALS
          CLOCK_50, CLOCK_27, AUD_DACLRCK   : IN    STD_LOGIC;
          AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT  : IN    STD_LOGIC;
          RESET                                : IN    STD_LOGIC;
          I2C_SDAT                      : INOUT STD_LOGIC;
          I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT   STD_LOGIC;
          
          -- FIFO SIGNALS
          lt_fifo_dout : IN std_logic_vector(23 downto 0);
          lt_fifo_rd_en : OUT std_logic;
          lt_fifo_empty : IN std_logic;
          rt_fifo_dout : IN std_logic_vector(23 downto 0);
          rt_fifo_rd_en : OUT std_logic;
          rt_fifo_empty : IN std_logic;

          -- SIMULATION SIGNALS
          lt_signal, rt_signal : OUT std_logic_vector(23 downto 0)
          );
END component audio_controller;
   
--***************************************************************************
   
   constant SOUND_BIT_WIDTH : integer := 24;
   constant LEFT_MAX : integer := 255;
   constant RIGHT_MAX : integer := 46;

   type sound_table is array (0 to 255) of std_logic_vector(SOUND_BIT_WIDTH-1 downto 0);
   constant snare_sound : sound_table := (
    X"000000", X"FFFFE7", X"FFFE14", X"FFEE30", X"FFA97F", X"FF16B2", X"FE909B", X"FE888C",
    X"FEEAFF", X"003E5A", X"0241CC", X"01689C", X"FF0F9E", X"FF98A9", X"01714B", X"0626DC",
    X"FCF862", X"E7E4CE", X"E815A1", X"EEB7FF", X"F9949F", X"FE13CB", X"07CD9A", X"156B65",
    X"F674C1", X"ED08C5", X"00A78A", X"16CAFF", X"3004E9", X"3DCCB7", X"300F66", X"09511D",
    X"F6583F", X"FB3C8A", X"0B10DB", X"275DCC", X"5586EB", X"6FBF71", X"5852E6", X"550EA9",
    X"42540C", X"26DA65", X"30C6E6", X"0F04FF", X"F4ABB5", X"DDA566", X"CDFA99", X"C41CD7",
    X"D2B3BC", X"EA42AF", X"F1AE93", X"C87BDE", X"B4D553", X"ABC8A0", X"ADD9D4", X"AAFAD8",
    X"9ECBFC", X"9A0516", X"8FCAEC", X"817733", X"94AD05", X"9F7B4B", X"95D68E", X"9DB187",
    X"8AB26D", X"91FE88", X"B3B796", X"D183FA", X"E9BD52", X"EE070C", X"E07C85", X"D90DAF",
    X"DE017A", X"0C3829", X"1D07C8", X"33E8BB", X"3F9D09", X"4EE48D", X"4D10A0", X"51EF1F",
    X"350481", X"4D8697", X"599BE4", X"58C931", X"5A81EC", X"630F26", X"52C80B", X"4C9E98",
    X"54D401", X"5C6D71", X"689AA9", X"601B31", X"548B96", X"6D83F8", X"682655", X"5F2BFC",
    X"634687", X"5DC970", X"5DA21D", X"590528", X"3D7491", X"2A833C", X"184EF8", X"159FD3",
    X"346737", X"2BCED8", X"2CB8CF", X"33B2AA", X"355EF1", X"32F63F", X"0864B2", X"065C70",
    X"0AE95F", X"FE3EDA", X"DEB0C9", X"C1D0A7", X"AAA067", X"A6E58B", X"B3E8BD", X"BEB7FF",
    X"AA67B7", X"B5143D", X"D027FB", X"D2D720", X"D0BA20", X"E3FFAD", X"E1CE08", X"BC4AB7",
    X"A4C34D", X"ACC34D", X"B448C0", X"B26614", X"A2F2A7", X"A17D6D", X"A6186B", X"ACE4BA",
    X"C77027", X"CF559C", X"B8E466", X"C69597", X"C9F118", X"C32D4E", X"C8E9A4", X"C1BB5B",
    X"B47CDA", X"B587E9", X"C18FC6", X"DCDBE0", X"EF8812", X"F5DFCB", X"FAAD0D", X"E6F1AB",
    X"E673D6", X"D52FC3", X"CD3FD2", X"C14D95", X"B9758F", X"A7F680", X"AB0261", X"CEF8E0",
    X"F6C377", X"267674", X"3CE1C5", X"411D14", X"215864", X"132767", X"18941C", X"0DEFC7",
    X"F25B97", X"F35194", X"FA8CCE", X"04849C", X"224C2F", X"358255", X"3D96A6", X"2CA42A",
    X"2DB22C", X"1A9F6A", X"11F84C", X"1DCBBB", X"030025", X"FD0050", X"1C8700", X"33B740",
    X"392F1A", X"32ADD5", X"383371", X"340E6A", X"3A3736", X"4AB55E", X"429445", X"42F544",
    X"53DD43", X"4CCE1B", X"3D205B", X"27BD26", X"0DB9B6", X"02BF33", X"FEB4D1", X"09673C",
    X"0E5AEE", X"2123A2", X"333F52", X"3D6A15", X"4982FC", X"3C3808", X"379DB1", X"32EBC3",
    X"2001F7", X"EEF7E4", X"F41DB1", X"F734BE", X"01E447", X"0C6822", X"12B55E", X"1FDD97",
    X"2A02C8", X"13A82E", X"10B684", X"2E74D1", X"2E1BB0", X"32CB52", X"3A65BE", X"355F99",
    X"20EBED", X"02F48C", X"13C360", X"23E61C", X"225AEE", X"07C808", X"EE1039", X"E28827",
    X"F1EF74", X"183611", X"0A94DD", X"FF386D", X"03989D", X"01B98C", X"F5BD8C", X"F62165",
    X"E01894", X"CC3EEB", X"B9E5A0", X"C04C5A", X"DECE47", X"04650E", X"1BB549", X"0A4D09",
    X"099BD3", X"17FD0C", X"1ECE99", X"11A122", X"0825E1", X"DA53BA", X"CD566E", X"C598F3"
   );

   
   type snare_table is array (255 downto 0) of std_logic_vector(23 downto 0);

   type sin_table is array (47 downto 0) of std_logic_vector(23 downto 0);
   constant sin_values : sin_table := 
   ( 
     X"000000",  X"0010b4",  X"002120",  X"0030fb",  X"003fff",  X"004deb",  X"005a81",  X"00658b",  X"006ed9",  X"007640",  X"007ba2",
     X"007ee6",  X"007fff",  X"007ee6",  X"007ba2",  X"007640",  X"006ed9",  X"00658b",  X"005a81",  X"004deb",  X"003fff",  X"0030fb",
     X"002120",  X"0010b4",  X"000000",  X"ffef4b",  X"ffdee0",  X"ffcf05",  X"ffc001",  X"ffb215",  X"ffa57e",  X"ff9a74",  X"ff9127", 
     X"ff89bf",  X"ff845d",  X"ff8119",  X"ff8000",  X"ff8119",  X"ff845d",  X"ff89bf",  X"ff9127",  X"ff9a74",  X"ffa57e",  X"ffb215",
     X"ffc000",  X"ffcf05",  X"ffdee0",  X"ffef4b"
   );
 

   constant snare_values : snare_table :=
   (
     X"000000",   X"0000fe",   X"feffff",   X"ff0000",   X"000000",   X"000000",   X"000000",   X"000000",
     X"000000",   X"000000",   X"000000",   X"000000",   X"000000",   X"000000",   X"000000",   X"000000",
     X"000000",   X"000000",   X"000000",   X"0000fe",   X"feffff",   X"ff0000",   X"0000e6",   X"e6ffff",
     X"ff14fe",   X"feff2f",   X"2feeff",   X"ff7fa9",   X"a9ffb2",   X"b216ff",   X"ff9c90",   X"90fe89",
     X"8988fe",   X"feffea",   X"eafe5b",   X"5b3e00",   X"00cc41",   X"41029f",   X"9f6801",   X"019d0f",
     X"0fffa8",   X"a898ff",   X"ff4b71",   X"7101dc",   X"dc2606",   X"0665f8",   X"f8fcee",   X"eee4e7",
     X"e7c115",   X"15e8f0",   X"f0b7ee",   X"eea094",   X"94f9c8",   X"c813fe",   X"fe9ecd",   X"cd0766",
     X"666b15",   X"15c374",   X"74f6d8",   X"d808ed",   X"ed8ba7",   X"a7001e",   X"1ecb16",   X"16d304",
     X"0430c8",   X"c8cc3d",   X"3d8f0f",   X"0f3021",   X"215109",   X"093e58",   X"58f689",   X"893cfb",
     X"fbe010",   X"100bcf",   X"cf5d27",   X"27f386",   X"86555b",   X"5bbf6f",   X"6fe352",   X"5258d0",
     X"d00e55",   X"550454",   X"544288",   X"88da26",   X"260dc7",   X"c730d7",   X"d7040f",   X"0fb5ab",
     X"abf45c",   X"5ca5dd",   X"dd7cfa",   X"facde8",   X"e81cc4",   X"c4c2b3",   X"b3d2ba",   X"ba42ea",
     X"ea75ae",   X"aef1c3",   X"c37bc8",   X"c85fd5",   X"d5b4aa",   X"aac8ab",   X"abafd9",   X"d9adeb",
     X"ebfaaa",   X"aafbcb",   X"cb9e38",   X"38059a",   X"9ac8ca",   X"ca8f17",   X"177781",   X"81dbac",
     X"ac943f",   X"3f7b9f",   X"9f6ad6",   X"d695a7",   X"a7b19d",   X"9d94b2",   X"b28a84",   X"84fe91",
     X"9183b7",   X"b7b3e6",   X"e683d1",   X"d14ebd",   X"bde913",   X"1307ee",   X"ee737c",   X"7ce0a1",
     X"a10dd9",   X"d96101",   X"01de27",   X"27380c",   X"0cc907",   X"071de5",   X"e5e833",   X"33039d",
     X"9d3fa5",   X"a5e44e",   X"4e7b10",   X"104d18",   X"18ef51",   X"517b04",   X"043593",   X"93864d",
     X"4dd79b",   X"9b5958",   X"58c958",   X"58f681",   X"815a0a",   X"0a0f63",   X"6313c8",   X"c852ac",
     X"ac9e4c",   X"4c08d4",   X"d45452",   X"526d5c",   X"5c869a",   X"9a683f",   X"3f1b60",   X"609c8b",
     X"8b54d1",   X"d1836d",   X"6d5c26",   X"2668f9",   X"f92b5f",   X"5f6f46",   X"46637e",   X"7ec95d",
     X"5dfea1",   X"a15d3b",   X"3b0559",   X"597574",   X"743d35",   X"35832a",   X"2ae84e",   X"4e18be",
     X"be9f15",   X"153e67",   X"6734b2",   X"b2ce2b",   X"2be1b8",   X"b82cc6",   X"c6b233",   X"33125f",
     X"5f351d",   X"1df632",   X"32af64",   X"640874",   X"745c06",   X"0662e9",   X"e90ada",   X"da3efe",
     X"feceb0",   X"b0de9f",   X"9fd0c1",   X"c15ba0",   X"a0aa65",   X"65e5a6",   X"a6dbe8",   X"e8b314",
     X"14b8be",   X"bec467",   X"67aa36",   X"3614b5",   X"b51528",   X"28d02a",   X"2ad7d2",   X"d242ba",
     X"bad085",   X"85ffe3",   X"e32ece",   X"cee1d3",   X"d34abc",   X"bc32c3",   X"c3a43e",   X"3ec3ac",
     X"accf48",   X"48b428",   X"2866b2",   X"b2ccf2",   X"f2a273",   X"737da1",   X"a17a18",   X"18a6cd",
     X"cde4ac",   X"ac2c70",   X"70c7c2",   X"c255cf",   X"cf3fe4",   X"e4b8bf",   X"bf95c6",   X"c62ff1",
     X"f1c929",   X"292dc3",   X"c3a9e9",   X"e9c83b",   X"3bbbc1",   X"c1d77c",   X"7cb4be",   X"be87b5",
     X"b5ca8f",   X"8fc1f0",   X"f0dbdc",   X"dc1f88",   X"88efcc",   X"ccdff5",   X"f50bad",   X"adfaa1",
     X"a1f1e6",   X"e6b973",   X"73e699",   X"992fd5",   X"d5ec3f",   X"3fcd7b",   X"7b4dc1",   X"c18b75"
   );
 
 
   signal lt_sin_addr, rt_sin_addr : integer := 0;
   signal left_data_out, right_data_out : std_logic_vector(23 downto 0);
   signal lt_sin_out, rt_sin_out : std_logic_vector(23 downto 0);
   signal left_full, right_full, left_empty, right_empty, lt_wr_en, rt_wr_en, lt_read_en, rt_read_en : std_logic;
 
BEGIN

fifo_left_map : fifo 
           generic map ( FIFO_DATA_WIDTH => 24, 
               FIFO_BUFFER_SIZE => 1024)
           port map   ( rd_clk => CLOCK_50,
               wr_clk => CLOCK_50,
               reset => RESET,
               rd_en => lt_read_en,
               wr_en => lt_wr_en,
               din => lt_sin_out,
               dout => left_data_out,
               full => left_full,
               empty => left_empty);

fifo_right_map : fifo
            generic map ( FIFO_DATA_WIDTH => 24, 
               FIFO_BUFFER_SIZE => 1024)
            port map      ( rd_clk => CLOCK_50,
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

--report "rt_index" & integer'image(rt_sin_addr);
--report "lt_index" & integer'image(lt_sin_addr);
--*************Sin Wave**************************************
--lt_sin_out <= sin_values(lt_sin_addr);
rt_sin_out <= sin_values(rt_sin_addr);                                                   

--*************Snare Wave**************************************
lt_sin_out <= snare_sound(lt_sin_addr);
--rt_sin_out <= snare_sound(rt_sin_addr);  

   if(RESET = '1') then
      lt_wr_en <= '0';
      rt_wr_en <= '0';
      lt_sin_addr <= 0;
      rt_sin_addr <= 0;
   elsif (rising_edge(CLOCK_50)) then
      lt_wr_en <= lt_wr_en;
      rt_wr_en <= rt_wr_en;
      -- WRITE TO FIFO
           
     if (left_full = '0') then
         if(lt_sin_addr >= LEFT_MAX) then
            lt_sin_addr <= 0;
            lt_wr_en <= '0';
         elsif (lt_wr_en = '1') then
            lt_sin_addr <= lt_sin_addr + 1;
         end if;
      end if;
      if (right_full = '0') then
         if (rt_sin_addr >= RIGHT_MAX) then
            rt_sin_addr <= 0;
            rt_wr_en <= '0';
         elsif (rt_wr_en = '1') then
            rt_sin_addr <= rt_sin_addr + 1;
         end if;
      end if;

      -- PLAY FROM START DETECTION
      
      if(lt_hit = '1') then
          lt_wr_en <= '1';
          lt_sin_addr <= 0;
      end if;
      if(rt_hit = '1') then
         rt_wr_en <= '1';
         rt_sin_addr <= 0;
      end if;

   end if;
   end process;



 
                                   
   
END Behavior;
