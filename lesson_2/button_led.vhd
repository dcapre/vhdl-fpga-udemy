------------------------------------------------------------------------------
-- File:        button_led.vhd
-- Author:      Diego Capre (dcapre@live.com)
-- Description: This is an implementation of a simple LED toggle using 
--              the Arty-Z7 board. 
------------------------------------------------------------------------------
-- Library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity Declaration
entity button_led is 
    generic(
        NUM_BUTTONS : integer := 4 -- The Arty-Z7 board has available 4 push buttons  
        );
    port(
        LED_OUT   : out std_logic_vector(NUM_BUTTONS - 1 downto 0); -- We are using 4 of the 6 LEDs available in the board
        BUTTON_IN : in  std_logic_vector(NUM_BUTTONS - 1 downto 0);
        ENABLE_N  : in  std_logic
    );
end button_led;

-- Architecture
architecture behavioral of button_led is 

-- Begin Architecture
begin 
    -- Set the output of the LED accordingly to the Button pressed
    -- Enable must be asserted otherwise LEDs are set to 'Low'
    LED_OUT <= BUTTON_IN when ENABLE_N = '0' else (others => '0');

end behavioral;