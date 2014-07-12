----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity int_to_ascii is
    Port ( int_in : in  STD_LOGIC_VECTOR (7 downto 0);
           ascii_out : out  STD_LOGIC_VECTOR (7 downto 0));
end int_to_ascii;

architecture int_to_ascii_a of int_to_ascii is begin
process(int_in) begin
   if(int_in >= x"00" and int_in <= x"09") then
      ascii_out <= int_in + x"30";
   elsif(int_in >= x"0a" and int_in <= x"0f") then
      ascii_out <= int_in + x"41" - x"0a";
   else 
      ascii_out <= int_in;
   end if;
end process;
end int_to_ascii_a;

