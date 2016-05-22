LIBRARY ieee;
USE ieee.std_logic_1164.all;
--USE ieee.std_logic_signed.all;
USE ieee.numeric_std.all;

ENTITY flash_reader IS
  PORT ( 
          CLOCK_50 : IN STD_LOGIC;
			 RESET : in std_logic;
			 
			 
			 --for debugging--------------------------
			 press_for_next : in std_logic;
			 
			 
			 --Address
			 FL_addr : out std_logic_vector(22 downto 0);
			 
			 --Data
			 FL_dq : in std_logic_vector(7 downto 0);
			 
			 --Chip Enable
			 FL_ce : out std_logic;
			 
			 --output enable
			 FL_oe : out std_logic;
			 
			 --ready/busy
			 FL_ready : in std_logic;
			 
			 --write enable
			 FL_wr_en : out std_logic; -- set always high because we never want to write over it
			 
			 --address from sound_selector 
			 
			 --stuff for LED
			 segment0_out_to_LED : out std_logic_vector(6 downto 0);
			 segment1_out_to_LED : out std_logic_vector(6 downto 0)
			 
			 
        );
END ENTITY flash_reader;

ARCHITECTURE behavioral OF flash_reader IS

component leddcd is
	port(
		 data_in : in std_logic_vector(3 downto 0);
		 segments_out : out std_logic_vector(6 downto 0)
		);
end component leddcd;

signal data : std_logic_vector(7 downto 0);


begin

led0_map : leddcd port map (data_in => data(3 downto 0),
									 segments_out => segment0_out_to_LED);
									 
led1_map : leddcd port map (data_in => data(7 downto 4),
									 segments_out => segment1_out_to_LED);
									 
									 
flash : process(CLOCK_50, FL_ready, press_for_next)

variable	addr_inc : integer := 0;
variable first_time : std_logic := '1';
	begin
	
	
	if(RESET = '1') then
		FL_addr <= (others => '0');
		FL_wr_en <= '1';
		FL_ce <= '1';
		FL_oe <= '0';
	
		addr_inc := 0;
	
	elsif(rising_edge(CLOCK_50)) then
	
		--if(FL_ready = '1') then
			--data <= FL_dq;
		--end if;
		
		
		
		if(press_for_next = '0') then
			if(first_time = '1') then
				--FL_ce <= '0';
				addr_inc := addr_inc + 1;
				FL_addr <= std_logic_vector(to_unsigned(addr_inc, FL_addr'length));
				first_time := '0';	
			end if;
			
			if(FL_ready = '1') then
					data <= FL_dq;
			end if;
			
			
			FL_ce <= '0';
			
		else
			first_time := '1';
			FL_ce <= '1';
			
			
			
		end if;
	
		
		
		
		
		end if;
		
end process;

end architecture behavioral;
