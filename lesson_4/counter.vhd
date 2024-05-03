------------------------------------------------------------------------------
-- File:        counter.vhd
-- Author:      Diego Capre (dcapre@live.com)
-- Description: This is an implementation of a modular counter. This is 
-- 				a simple Up Counter with a sync/async RST.
-- 
------------------------------------------------------------------------------

-- Libraries
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.math_real.all;
use IEEE.numeric_std.all;

entity COUNTER is
	generic ( 
		MAX_VAL 		: integer := 2**30; -- 2^30 = 1,073,741,824 values
		SYNCH_RST		: boolean := true); -- Generate Synchronous RST Counter
	port (
		MAX_COUNT 		: out std_logic;
		CLK 			: in std_logic;
		RST 			: in std_logic);
end COUNTER;

architecture behavior of COUNTER is

	constant bit_depth	: integer := integer(ceil(log2(real(MAX_VAL))));	-- This equates to 30 
	signal Count_reg	: unsigned(bit_depth - 1 downto 0) := (others => '0');
	
	begin
	
	synch_rst_label : if SYNCH_RST = true generate
		Count_proc: process(CLK)
		begin
			if rising_edge(CLK) then
				if((RST = '0') or (Count_reg = MAX_VAL)) then
					Count_reg <= (others => '0');
				else
					Count_reg <= Count_reg + 1;
				end if;
			end if;
		end process;
	end generate;

	asynch_rst_label : if SYNCH_RST = false generate
		Count_proc: process(CLK, RST)
		begin
			if(RST = '0') then
				Count_reg <= (others => '0');
			elsif rising_edge(CLK) then
				if(Count_reg = MAX_VAL) then
					Count_reg <= (others => '0');
				else
					Count_reg <= Count_reg + 1;
				end if;
			end if;
		end process;
	end generate;
	
	-- Produce a 8 ns pulse when MAX count
	output_proc: process(Count_reg)
		begin
		MAX_COUNT <= '0';
		if(Count_reg = MAX_VAL) then
			MAX_COUNT <= '1';
		end if;
	end process;
end behavior;