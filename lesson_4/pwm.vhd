------------------------------------------------------------------------------
-- File:        pwm.vhd
-- Author:      Diego Capre (dcapre@live.com)
-- Description: Takes a desired Duty_Cyle and generates a PWM signal.
-- 
------------------------------------------------------------------------------

-- Libraries
library IEEE;
use IEEE.STD_LOGIC_1164.all; -- std_logic, std_logic_vector
use IEEE.numeric_std.all;	 -- unsigned and signed data types

-- Entity
entity PWM is
	generic (
		BIT_DEPTH	: integer := 8;		    -- 2^8 = 256 values of resolution
		INPUT_CLK	: integer := 125000000; -- 125MHz
		FREQ		: integer := 50); 		-- 50Hz, Max Pulse Frequency
	port (
		PWM_OUT 	: out std_logic;
		DUTY_CYCLE	: in  std_logic_vector(BIT_DEPTH - 1 downto 0);
		CLK			: in  std_logic;
		ENABLE		: in  std_logic);
end PWM;

-- Architecture
architecture rtl of PWM is

-- Constants
constant max_freq_count	: integer := INPUT_CLK / FREQ;
constant pwm_step		: integer := max_freq_count / (2**BIT_DEPTH);

-- Signals
signal pwm_value		: std_logic := '0';
signal freq_count		: integer range 0 to max_freq_count := 0;
signal pwm_count		: integer range 0 to 2**BIT_DEPTH := 0;
signal max_pwm_count	: integer range 0 to 2**BIT_DEPTH := 0;
signal pwm_step_count	: integer range 0 to max_freq_count := 0;

begin
	-- Convert DUTY_CYCLE to max_pwm_count
	max_pwm_count <= to_integer(unsigned(DUTY_CYCLE));
	PWM_OUT <= pwm_value;
	
	-- Process that runs signal out at the correct frequency
	freq_counter : process(CLK)
	begin
		if (rising_edge(CLK)) then
			if (ENABLE = '0') then
				if (freq_count < max_freq_count) then  	-- Controls how frequently to change the cycles (aka PWM "Clock Cycles")
					freq_count <= freq_count + 1;
					if (pwm_count < max_pwm_count) then -- Controls the PWM Duty Cycle
						pwm_value <= '1';				-- High Cycle
						if (pwm_step_count < pwm_step) then
							pwm_step_count <= pwm_step_count + 1;
						else
							pwm_step_count <= 0;
							pwm_count <= pwm_count + 1;
						end if;
					else
						pwm_value <= '0';				-- Low Cycle
					end if;
				else -- Reset Count
					freq_count <= 0;
					pwm_count  <= 0;
				end if;
			else
				pwm_value <= '0';
			end if;
		end if;	
	end process freq_counter;

end rtl;