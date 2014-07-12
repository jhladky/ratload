----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ascii_to_int is
   Port( ascii_in : in  STD_LOGIC_VECTOR (7 downto 0);
         int_out  : out STD_LOGIC_VECTOR (7 downto 0));
end ascii_to_int;

architecture ascii_to_int_a of ascii_to_int is begin
process(ascii_in) begin
   if(ascii_in >= x"30" and ascii_in <= x"39") then
      int_out <= ascii_in - x"30";
   elsif(ascii_in >= x"41" and ascii_in <= x"46") then
      int_out <= ascii_in - x"41" + 10;
   else
      int_out <= ascii_in;
   end if;
end process;
end ascii_to_int_a;

