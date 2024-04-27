------------------------------------------------------------------------------
-- File:        button_led.vhd
-- Author:      Diego Capre (dcapre@live.com)
-- Description: This is an implementation of a simple LED blinker. This is
--              done by using a counter to blink at a set interval.
-- 
------------------------------------------------------------------------------

-- Libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- Vectors, and Gates
use IEEE.math_real.all;		 -- Math functions and constants
use IEEE.numeric_std.all;	 -- Unsigned data type

-- Entity
entity blinky_led is
	Generic (
		NUM_LEDS		: integer := 4;			-- 8 LEDs default
		CLK_RATE		: integer := 125000000; -- 50 MHz default
		BLINK_RATE 	    : integer := 2);		-- 2 Hz default
	Port (
		LED_OUT			: out std_logic_vector(NUM_LEDS - 1 downto 0);
		CLK				: in std_logic;
		RESET		    : in std_logic);		-- Active Low
end blinky_led;

-- Architecture
architecture design of blinky_led is

-- Calculate count value to achieve 'BLINK_RATE' from generic
constant MAX_VAL	: integer := CLK_RATE / BLINK_RATE;

-- Calculate number of bits required to count to 'MAX_VAL'
constant BIT_DEPTH 	: integer := integer(ceil(log2(real(MAX_VAL))));

-- Register to hold the current count value
signal count_reg   	: unsigned(BIT_DEPTH - 1 downto 0) := (others => '0');

-- Register to hold the value of output LEDs
signal led_reg	   	: std_logic_vector(NUM_LEDS - 1 downto 0) := "0000";
	
	begin
		-- Assign output LED values
		LED_OUT <= led_reg; -- intantenous, in the order of picoseconds
	
		-- Process that increments the counter every rising clock edge
		count_proc: process(CLK)
		begin
			if rising_edge(CLK) then
				if((reset = '0') or (count_reg = MAX_VAL)) then
					count_reg <= (others => '0');
				else
					count_reg <= count_reg + 1;
				end if;
			end if;
		end process;

		-- Process that will toggle the LED output every time the counter
		-- reaches the calculated 'MAX_VAL'
		output_proc: process(CLK)
		begin
		  if rising_edge(CLK) then
			if (count_reg = MAX_VAL) then
				led_reg <= NOT led_reg;
			end if;
		end if;
	end process;
end design;
