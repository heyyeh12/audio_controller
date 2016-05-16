LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE work.altera_drums.all;
USE work.sounds.all;

ENTITY sound_selector IS
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

  --CONSTANTS - set to match sounds
  constant LT_MAX : integer := sin_values'length-1;
  constant LT_LOOP : integer := 5000;
  constant RT_MAX : integer := sin_values'length-1;
  constant RT_LOOP : integer := 5000;

  -- SIGNALS
  signal lt_idx, rt_idx : integer := 0;
  signal lt_play, rt_play : std_logic;
  signal lt_loop_cnt, rt_loop_cnt : integer := 0;

BEGIN



sound_select : PROCESS (CLOCK_50, RESET, lt_hit, rt_hit, lt_idx, rt_idx)

  BEGIN

  -- SIN WAV
  lt_sound <= sin_values(lt_idx);
  rt_sound <= sin_values(rt_idx);

  -- SNARE WAV
  --lt_sound <= snare_sound(lt_idx);
  --rt_sound <= snare_sound(rt_idx);
  
  --Snare Wave full
  --lt_sound <= sound(lt_idx);
  --rt_sound <= sound(rt_idx);

  if(RESET = '1') then
      lt_wr_en <= '0';
      rt_wr_en <= '0';
      lt_idx <= 0;
      rt_idx <= 0;
      lt_play <= '0';
      rt_play <= '0';
      lt_loop_cnt <= LT_LOOP;
      rt_loop_cnt <= RT_LOOP;
   elsif(rising_edge(CLOCK_50)) then

	
	--Right now, if not hit, always automatically increments through the sin table, with no regards to whether or not you 
	--have actually hit it
		--actually this is only a first time through problem
	
      -- LEFT FIFO CONTROL
		if (lt_hit = '1') then
			lt_idx <= 0;
			lt_loop_cnt <= 0;
      elsif ( lt_loop_cnt < LT_LOOP ) then
			if ( lt_idx < LT_MAX and lt_full = '0') then
				lt_wr_en <= '1';
				rt_wr_en <= '1';		
				lt_idx <= lt_idx + 1;
			elsif ( lt_idx >= LT_MAX ) then
				lt_loop_cnt <= lt_loop_cnt + 1;
				lt_idx <= 0;
			end if;
		end if;
				
				
				
				
--          if(lt_idx >= LT_MAX) then
--            lt_idx <= 0;
--            if (lt_loop_cnt >= LT_LOOP) then
--              lt_play <= '1';
--              lt_loop_cnt <= 0;
--              lt_wr_en <= '1';
--            else
--              lt_loop_cnt <= lt_loop_cnt + 1;
--            end if;
--          else
--            lt_idx <= lt_idx + 1;
--          end if;
--      end if;

      -- RIGHT FIFO CONTROL
		if (rt_hit = '1') then
			rt_idx <= 0;
			rt_loop_cnt <= 0;
      elsif ( rt_loop_cnt < rt_LOOP ) then
			if ( rt_idx < rt_MAX and rt_full = '0') then
				rt_wr_en <= '1';
				rt_wr_en <= '1';		
				rt_idx <= rt_idx + 1;
			elsif ( rt_idx >= rt_MAX ) then
				rt_loop_cnt <= rt_loop_cnt + 1;
				rt_idx <= 0;
			end if;
		end if;
		
		
		
		
		
		
--      if (rt_hit = '1') then
--      rt_idx <= 0;
--      rt_play <= '1';
--      rt_loop_cnt <= 0;
--		elsif (rt_full = '0' and rt_play = '1') then
--          rt_wr_en <= '1';
--	  lt_wr_en <= '1';
--          if(rt_idx >= RT_MAX) then
--            rt_idx  <= 0;
--            if (rt_loop_cnt >= RT_LOOP) then
--              rt_play <= '1';
--              rt_loop_cnt <= 0;
--              rt_wr_en <= '1';
--            else
--              rt_loop_cnt <= rt_loop_cnt + 1;
--            end if;
--          else
--            rt_idx  <= rt_idx  + 1;
--          end if;
--      end if;
--   end if;

	end if;



END PROCESS;

END ARCHITECTURE behavioral;