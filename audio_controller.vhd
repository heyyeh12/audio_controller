LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY audio_controller IS
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
			 rt_fifo_empty : IN std_logic;

	  -- simulation
          lt_signal : OUT std_logic_vector(23 downto 0);
	  rt_signal : OUT std_logic_vector(23 downto 0)
          );
END audio_controller;

ARCHITECTURE Behavior OF audio_controller IS
   COMPONENT clock_generator
      PORT( CLOCK_27 : IN STD_LOGIC;
            reset    : IN STD_LOGIC;
            AUD_XCK  : OUT STD_LOGIC);
   END COMPONENT;

   COMPONENT audio_and_video_config
      PORT( CLOCK_50, reset : IN    STD_LOGIC;
            I2C_SDAT        : INOUT STD_LOGIC;
            I2C_SCLK        : OUT   STD_LOGIC);
   END COMPONENT;   

   COMPONENT audio_codec
      PORT( CLOCK_50, reset, read_s, write_s               : IN  STD_LOGIC;
            writedata_left, writedata_right                : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
            AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK : IN  STD_LOGIC;
            read_ready, write_ready                        : OUT STD_LOGIC;
            readdata_left, readdata_right                  : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
            AUD_DACDAT                                     : OUT STD_LOGIC);
   END COMPONENT;

   SIGNAL read_ready, write_ready, read_s, write_s : STD_LOGIC;
   SIGNAL readdata_left, readdata_right            : STD_LOGIC_VECTOR(23 DOWNTO 0);
   SIGNAL writedata_left, writedata_right          : STD_LOGIC_VECTOR(23 DOWNTO 0);   
   
BEGIN

   read_s <= '0';
    writedata_left <= std_logic_vector(resize(signed(lt_fifo_dout), writedata_left'length));
    writedata_right <= std_logic_vector(resize(signed(rt_fifo_dout), writedata_right'length));

    lt_signal <= writedata_left;
    rt_signal <= writedata_right;
    audio_write_process : process ( reset, CLOCK_50 )
    begin
        if ( reset = '1' ) then
            write_s <= '0';
            lt_fifo_rd_en <= '0';
            rt_fifo_rd_en <= '0';
       elsif ( rising_edge( CLOCK_50 ) ) then
            write_s <= '0';
            lt_fifo_rd_en <= '0';
            rt_fifo_rd_en <= '0';
            if ( (write_ready = '1') AND (lt_fifo_empty = '0') AND (rt_fifo_empty = '0') ) then
                write_s <= '1';
                lt_fifo_rd_en <= '1';
                rt_fifo_rd_en <= '1';
            end if;                            
       end if;
   end process audio_write_process;
      
   my_clock_gen: clock_generator PORT MAP (CLOCK_27, reset, AUD_XCK);
   cfg: audio_and_video_config PORT MAP (CLOCK_50, reset, I2C_SDAT, I2C_SCLK);
   codec: audio_codec PORT MAP (CLOCK_50, reset, read_s, write_s, writedata_left, 
	                             writedata_right, AUD_ADCDAT, AUD_BCLK, AUD_ADCLRCK,
										  AUD_DACLRCK, read_ready, write_ready, readdata_left, 
										  readdata_right, AUD_DACDAT);
END Behavior;
