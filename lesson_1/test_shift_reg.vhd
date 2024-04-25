library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity test_shift_reg is
end;

architecture test of test_shift_reg is 

component shift_reg
    port ( 
        A       : out std_logic;
        B       : out std_logic;
        C       : out std_logic;
        D       : out std_logic;
        DATA_IN : in  std_logic;
        RST     : in  std_logic;
        CLK     : in  std_logic
    ) ;
end component;

signal DATA_IN    : std_logic := '0';
signal RST        : std_logic := '0'; 
signal CLK        : std_logic := '1'; 
signal A, B, C, D : std_logic;

begin 
    dev_to_test: shift_reg
        port map(A, B, C, D, DATA_IN, RST, CLK);

    clk_stimulus: process
    begin 
        wait for 10 ns;
        CLK <= not CLK;
    end process clk_stimulus;

    data_stimulus: process
    begin 
        wait for 40 ns;
        DATA_IN <= not DATA_IN; 
        wait for 150 ns; 
    end process data_stimulus;

end test;