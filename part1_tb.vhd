library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity part1_tb is
end entity;

architecture tb of part1_tb is

component part1 IS
   PORT ( CLOCK_50, CLOCK_27, RESET, AUD_DACLRCK   : IN    STD_LOGIC;
          AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT  : IN    STD_LOGIC;
          I2C_SDAT                      : INOUT STD_LOGIC;
          I2C_SCLK, AUD_DACDAT, AUD_XCK : OUT   STD_LOGIC;
          lt_sin_values, rt_sin_values : out std_logic_vector(15 downto 0);
			 lt_signal, rt_signal : OUT std_logic_vector(23 downto 0)  
          );
end component part1;

signal CLOCK_50, CLOCK_27, RESET, AUD_DACLRCK   :  STD_LOGIC;
signal AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT  : STD_LOGIC;
signal I2C_SDAT                      :  STD_LOGIC;
signal I2C_SCLK, AUD_DACDAT, AUD_XCK :  STD_LOGIC;
signal lt_sin_values, rt_sin_values : std_logic_vector(15 downto 0);
signal lt_signal, rt_signal : std_logic_vector(23 downto 0);

begin
    
part1_map : part1 port map (
			CLOCK_50 => CLOCK_50, CLOCK_27 => CLOCK_27, RESET => RESET, AUD_DACLRCK => AUD_DACLRCK,
         AUD_ADCLRCK => AUD_ADCLRCK, AUD_BCLK => AUD_BCLK, AUD_ADCDAT => AUD_ADCDAT,
          I2C_SDAT => I2C_SDAT,
          I2C_SCLK => I2C_SCLK, AUD_DACDAT => AUD_DACDAT, AUD_XCK => AUD_XCK,
			 lt_signal => lt_signal, rt_signal => rt_signal 
          );

	clocked : process is
		begin
		CLOCK_50 <= '0';
		CLOCK_27 <= '0';
		wait for 5 ns;
		CLOCK_50 <= '1';
		CLOCK_27 <= '1';
		wait for 5 ns;
	end process;
    
   process is
       begin
			AUD_DACLRCK <= '1';
         		AUD_ADCLRCK <= '1';
			AUD_ADCDAT <= '1';
         		I2C_SDAT <= '1';
			
			-----
			
			RESET <= '1';
			wait for 10 ns;
			RESET <= '0';
			wait for 500 ns;
        wait;
    end process;
    
   
end architecture tb;