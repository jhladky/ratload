----------------------------------------------------------------------------------
-- Company: none
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity stack_pointer is
   Port( inc_dec        : in  STD_LOGIC_VECTOR(1 downto 0);
         d_in           : in  STD_LOGIC_VECTOR(7 downto 0);
         we, rst, clk   : in  STD_LOGIC;
         stk_pntr       : out STD_LOGIC_VECTOR(7 downto 0));
end stack_pointer;

architecture stack_pointer_a of stack_pointer is
   signal stk_pntr_i : STD_LOGIC_VECTOR(7 downto 0);
begin
   stk_pntr <= stk_pntr_i;
process(inc_dec, d_in, rst, clk, we) begin
   if(rst = '1') then
      stk_pntr_i <= (others => '0');
   elsif(rising_edge(clk)) then
      if(we = '1') then
         stk_pntr_i <= d_in;
      else 
         if(inc_dec = "01") then
            stk_pntr_i <= stk_pntr_i - 1;
         elsif(inc_dec = "10") then
            stk_pntr_i <= stk_pntr_i + 1;
         end if;
      end if;
   end if;
end process;
end stack_pointer_a;

