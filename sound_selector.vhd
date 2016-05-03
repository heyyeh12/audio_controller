LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY sound_selector IS
  GENERIC (
          SOUND_BIT_WIDTH : INTEGER := 24
  );
  PORT ( 
          CLOCK_50 : IN STD_LOGIC;
          RESET : IN STD_LOGIC;

          -- SPIKE DETECTOR
          lt_hit, rt_hit : IN STD_LOGIC;
          --lt_vol, rt_vol : IN STD_LOGIC_VECTOR(1 downto 0);

          -- FIFOS
          lt_full : IN STD_LOGIC;
          lt_sound : OUT STD_LOGIC_VECTOR( SOUND_BIT_WIDTH-1 downto 0 );
          lt_wr_en : OUT STD_LOGIC;
          
          rt_full : IN STD_LOGIC;
          rt_sound : OUT STD_LOGIC_VECTOR( SOUND_BIT_WIDTH-1 downto 0 );
          rt_wr_en : OUT STD_LOGIC
        );
END ENTITY sound_selector;

ARCHITECTURE behavioral OF sound_selector IS

-------------------------------------------------------------
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
------------------------------------------------------------- 
  type sin_table is array (47 downto 0) of std_logic_vector(23 downto 0);
  constant sin_values : sin_table := 
   ( 
     X"000000",  X"0010b4",  X"002120",  X"0030fb",  X"003fff",  X"004deb",  X"005a81",  X"00658b",  X"006ed9",  X"007640",  X"007ba2",
     X"007ee6",  X"007fff",  X"007ee6",  X"007ba2",  X"007640",  X"006ed9",  X"00658b",  X"005a81",  X"004deb",  X"003fff",  X"0030fb",
     X"002120",  X"0010b4",  X"000000",  X"ffef4b",  X"ffdee0",  X"ffcf05",  X"ffc001",  X"ffb215",  X"ffa57e",  X"ff9a74",  X"ff9127", 
     X"ff89bf",  X"ff845d",  X"ff8119",  X"ff8000",  X"ff8119",  X"ff845d",  X"ff89bf",  X"ff9127",  X"ff9a74",  X"ffa57e",  X"ffb215",
     X"ffc000",  X"ffcf05",  X"ffdee0",  X"ffef4b"
   );
-------------------------------------------------------------  

  -- CONSTANTS - set to match sounds
  constant LT_MAX : integer := 255;
  constant LT_LOOP : integer := 0;
  constant RT_MAX : integer := 46;
  constant RT_LOOP : integer := 100;

  -- SIGNALS
  signal lt_idx, rt_idx : integer := 0;
  signal lt_play, rt_play : std_logic;
  signal lt_loop_cnt, rt_loop_cnt : integer := 0;

BEGIN



sound_select : PROCESS (CLOCK_50, RESET, lt_hit, rt_hit)

  BEGIN

  -- SIN WAV
  --lt_sound <= sin_values(lt_idx);
  rt_sound <= sin_values(rt_idx);

  -- SNARE WAV
  lt_sound <= snare_sound(lt_idx);
  --rt_sound <= snare_sound(rt_idx);

  if(RESET = '1') then
      lt_wr_en <= '0';
      rt_wr_en <= '0';
      lt_idx <= 0;
      rt_idx <= 0;
      lt_play <= '0';
      rt_play <= '0';
      lt_loop_cnt <= 0;
      rt_loop_cnt <= 0;
   elsif (lt_hit = '1') then
      lt_idx <= 0;
      lt_play <= '1';
      lt_loop_cnt <= 0;
   elsif (rt_hit = '1') then
      rt_idx <= 0;
      rt_play <= '1';
      rt_loop_cnt <= 0;
   elsif(rising_edge(CLOCK_50)) then

      -- LEFT FIFO CONTROL
      if (lt_full = '0' and lt_play = '1') then
          lt_wr_en <= '1';
          if(lt_idx >= LT_MAX) then
            lt_idx <= 0;
            if (lt_loop_cnt >= LT_LOOP) then
              lt_play <= '0';
              lt_loop_cnt <= 0;
              lt_wr_en <= '0';
            else
              lt_loop_cnt <= lt_loop_cnt + 1;
            end if;
          else
            lt_idx <= lt_idx + 1;
          end if;
      end if;

      -- RIGHT FIFO CONTROL
      if (rt_full = '0' and rt_play = '1') then
          rt_wr_en <= '1';
          if(rt_idx >= RT_MAX) then
            rt_idx  <= 0;
            if (rt_loop_cnt >= RT_LOOP) then
              rt_play <= '0';
              rt_loop_cnt <= 0;
              rt_wr_en <= '0';
            else
              rt_loop_cnt <= rt_loop_cnt + 1;
            end if;
          else
            rt_idx  <= rt_idx  + 1;
          end if;
      end if;
   end if;

END PROCESS;

END ARCHITECTURE behavioral;