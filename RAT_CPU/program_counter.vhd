----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity program_counter is
    Port ( clk, rst, oe, load : in  STD_LOGIC;
           sel                : in STD_LOGIC_VECTOR(1 downto 0);
           from_immed, from_stack : in  STD_LOGIC_VECTOR (9 downto 0);
           pc_count           : out  STD_LOGIC_VECTOR (9 downto 0);
           pc_tri             : inout STD_LOGIC_VECTOR(9 downto 0));
end program_counter;

architecture program_counter_a of program_counter is
   signal pc_count_i     : STD_LOGIC_VECTOR(9 downto 0);
   signal pc_from_mux_i  : STD_LOGIC_VECTOR(9 downto 0);
  
begin

with sel select 
   pc_from_mux_i <=  
      pc_count_i + 1 when "00",
      from_immed     when "01",
      from_stack     when "10",
      "1111111111"   when "11",
      "0000000000"   when others;

pc_count <= pc_count_i;   
pc_tri <= pc_count_i when (oe = '1') else (others => 'Z');	
		
process(clk, rst) begin
   if(rst = '1') then
      pc_count_i <= (others => '0');
   elsif(rising_edge(clk)) then
      if(load = '1') then
         pc_count_i <= pc_from_mux_i;
      end if;  
    end if;
  end process;
end program_counter_a;
