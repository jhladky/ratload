----------------------------------------------------------------------------------
-- Company: CPE 233
-- Engineer: Jacob Hladky and Curtis Jonaitis
---------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity register_file is
   Port( FROM_IN_PORT   : in  STD_LOGIC_VECTOR(7 downto 0);
         FROM_TRI_STATE : in  STD_LOGIC_VECTOR(7 downto 0);
         FROM_ALU       : in  STD_LOGIC_VECTOR(7 downto 0);
         RF_MUX_SEL     : in  STD_LOGIC_VECTOR(1 downto 0);
         ADRX, ADRY     : in  STD_LOGIC_VECTOR(4 downto 0);
         WE, CLK, DX_OE : in  STD_LOGIC;
         DX_OUT, DY_OUT : out STD_LOGIC_VECTOR(7 downto 0));
end register_file;

architecture register_file_a of register_file is
	TYPE memory is array (0 to 31) of std_logic_vector(7 downto 0);
	SIGNAL REG: memory := (others=>(others=>'0'));
   SIGNAL D_IN : STD_LOGIC_VECTOR(7 downto 0);
begin

with RF_MUX_SEL select
   D_IN <=  FROM_IN_PORT      when "00",
            FROM_TRI_STATE    when "01",
            FROM_ALU          when "10",
            (others => 'X')   when others;

process(clk, we, d_in) begin
   if (rising_edge(clk)) then
      if (WE = '1') then
         REG(conv_integer(ADRX)) <= D_IN;
		end if;
   end if;
end process;

	DX_OUT <= REG(conv_integer(ADRX)) when DX_OE='1' else (others=>'Z');
	DY_OUT <= REG(conv_integer(ADRY));
	
end register_file_a;
