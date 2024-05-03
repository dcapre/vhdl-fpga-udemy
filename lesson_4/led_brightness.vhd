------------------------------------------------------------------------------
-- File:        led_brightness.vhd
-- Author:      Diego Capre (dcapre@live.com)
-- Description: This design uses a COUNTER to change the duty cycle of a PWM
--				signal. These PWM signals are used to change the brightness
-- 				of the LED. The higher the duty cycle the brighter the LED
--				becomes. A signal with 100% duty cycle would make the LED the
--				brightest possible, this is the same as driving the line high.
-- 
-- Comment: 	 Changing the LED_MAX_COUNT and RGB_MAX_COUNT determine how
--				 long it takes the LED's to reach maximum brightness.
------------------------------------------------------------------------------

-- Libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.math_real.ALL;

-- Entity
entity LED_BRIGHTNESS is
	Generic (
		INPUT_CLK		: integer := 1250000000; -- 125 MHz default
		NUM_RGB_LEDS	: integer := 2;
		NUM_LEDS 		: integer := 4);		
	Port (
		LED_OUT			: out std_logic_vector(NUM_LEDS - 1 downto 0);
		RGB_R_OUT		: out std_logic_vector(NUM_RGB_LEDS - 1 downto 0);
		RGB_G_OUT		: out std_logic_vector(NUM_RGB_LEDS - 1 downto 0);
		RGB_B_OUT		: out std_logic_vector(NUM_RGB_LEDS - 1 downto 0);
		CLK				: in  std_logic;
		LED_ENABLE		: in  std_logic;
		RGB_ENABLE		: in  std_logic);	-- Active Low
end LED_BRIGHTNESS;

-- Architecture
architecture behavior of LED_BRIGHTNESS is

-- Components
-- Pulse Width Modulation Design
component PWM
	generic (
		BIT_DEPTH	: integer := 8;
		INPUT_CLK	: integer := 1250000000; -- 125MHz
		FREQ		: integer := 50); 		 -- 50Hz
	port (
		PWM_OUT 	: out std_logic;
		DUTY_CYCLE	: in std_logic_vector(BIT_DEPTH - 1 downto 0);
		CLK			: in std_logic;
		ENABLE		: in std_logic);
end component PWM;

-- COUNTER
component COUNTER
	generic (
		MAX_VAL 		: integer := 2**30;
		SYNCH_RST		: boolean := true);
	port (
		MAX_COUNT 		: out std_logic;
		CLK 			: in std_logic;
		RST 			: in std_logic);
end component COUNTER;

-- Signals and Constants
-- 85 is from taking 255, the max PWM value, and dividing by 3 seconds
constant LED_MAX_COUNT	: integer := INPUT_CLK/85;   -- Used to step up Duty Cycle gradually
constant RGB_MAX_COUNT	: integer := INPUT_CLK/1365;
constant SYNC_RESET		: boolean := true;
constant MAX_LED_DUTY	: integer := 255;
constant MAX_RGB_DUTY	: integer := 4095;

signal led_max_cnt		: std_logic := '0';
signal rgb_max_cnt		: std_logic := '0';
signal led_pwm_reg		: std_logic := '0';
signal red_pwm_reg		: std_logic := '0';
signal grn_pwm_reg		: std_logic := '0';
signal blu_pwm_reg		: std_logic := '0';

signal rgb_counter_rst	: std_logic := '0';
signal led_counter_rst	: std_logic := '0';

signal led_duty_cycle	: unsigned(7 downto 0)  := (others => '0');
signal rgb_duty_cycle	: unsigned(11 downto 0) := (others => '0');

begin
	-- Assign Outputs
	LED_OUT   <= (others => led_pwm_reg);
	RGB_R_OUT <= (others => red_pwm_reg);
	RGB_G_OUT <= (others => grn_pwm_reg);
	RGB_B_OUT <= (others => blu_pwm_reg);
	
	-- Invert enable signal for counter
	rgb_counter_rst <= not RGB_ENABLE;
	led_counter_rst <= not LED_ENABLE;

	-- LED Counter
	LED_COUNTER: COUNTER 
		generic map(LED_MAX_COUNT, SYNC_RESET) 
		port map(MAX_COUNT => led_max_cnt, CLK => CLK, RST => led_counter_rst);
	
	-- RGB Counter
	RGB_COUNTER: COUNTER 
		generic map(RGB_MAX_COUNT, SYNC_RESET) 
		port map(MAX_COUNT => rgb_max_cnt, CLK => CLK, RST => rgb_counter_rst);
		
	-- LED PWM Signal Generator (8 bit, 50Hz)
	LED_PWM: PWM
		generic map(8, INPUT_CLK, 100)
		port map(led_pwm_reg, std_logic_vector(led_duty_cycle), CLK, LED_ENABLE);
	
	-- Note: If all RGB lights have the same duty cycle you'll only see a white light vary in brightness.
	--       That's why we use different duty cycle bits, to avoid them being the same. 
	-- RGB LED PWM Signal Generator [RED] (4 bit, 50Hz)
	RGB_RED_PWM: PWM
		generic map(4, INPUT_CLK, 100)
		port map(red_pwm_reg, std_logic_vector(rgb_duty_cycle(3 downto 0)), CLK, RGB_ENABLE);
	
	-- RGB LED PWM Signal Generator [GREEN] (4 bit, 50Hz)
	RGB_GRN_PWM: PWM
		generic map(4, INPUT_CLK, 100)
		port map(grn_pwm_reg, std_logic_vector(rgb_duty_cycle(7 downto 4)), CLK, RGB_ENABLE);
	
	-- RGB LED PWM Signal Generator [BLUE] (4 bit, 50Hz)
	RGB_BLU_PWM: PWM
		generic map(4, INPUT_CLK, 100)
		port map(blu_pwm_reg, std_logic_vector(rgb_duty_cycle(11 downto 8)), CLK, RGB_ENABLE);
	
	-- LED PWM Count update Process
	Led_Count_Proc: process(CLK)
	begin
		if rising_edge(CLK) then
			if (led_duty_cycle = MAX_LED_DUTY) then
				led_duty_cycle <= (others => '0');
			elsif (led_max_cnt = '1') then
				led_duty_cycle <= led_duty_cycle + 1;
			end if;
		end if;
	end process Led_Count_Proc;
	
	-- RGB PWM Count Update Process
	Rgb_Count_Proc: process(CLK)
	begin
		if rising_edge(CLK) then
			if (rgb_duty_cycle = MAX_RGB_DUTY) then
				rgb_duty_cycle <= (others => '0');
			elsif (rgb_max_cnt = '1') then
				rgb_duty_cycle <= rgb_duty_cycle + 1;
			end if;
		end if;
	end process Rgb_Count_Proc;
	
end behavior;