----------------------------------------------------------------------------------
-- Company: none
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity scratch_pad is
   Port( from_immed, from_sp  : in     STD_LOGIC_VECTOR(7 downto 0);
         from_sp_dec, from_rf : in     STD_LOGIC_VECTOR(7 downto 0);
         scr_addr_sel         : in     STD_LOGIC_VECTOR(1 downto 0);
         scr_we, scr_oe, clk  : in     STD_LOGIC;
         sp_data              : inout  STD_LOGIC_VECTOR(9 downto 0));
end scratch_pad;

architecture scratch_pad_a of scratch_pad is
   type memory is array (0 to 255) of std_logic_vector(9 downto 0);
   signal sp_data_int: memory := (others => (others => '0'));
   
   signal scr_addr_i : STD_LOGIC_VECTOR(7 downto 0);
   signal from_sp_dec_i : STD_LOGIC_VECTOR(7 downto 0);
begin
   from_sp_dec_i <= from_sp_dec - 1;
   with scr_addr_sel select
      scr_addr_i <=  from_immed     when "00",
                     from_sp        when "01",
                     from_sp_dec_i  when "10",
                     from_rf        when others;
                     
   process(clk, scr_we, scr_addr_i) begin                         
      if(rising_edge(clk)) then 
         if(scr_we = '1') then
            sp_data_int(conv_integer(scr_addr_i)) <= sp_data;
         end if;
      end if;
   end process;

   --Note that reads are asyncronous
   sp_data <= sp_data_int(conv_integer(scr_addr_i)) when scr_oe = '1' else (others => 'Z');
end scratch_pad_a;
