----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port(   sel            : in  STD_LOGIC_VECTOR (3 downto 0);
            a, b_from_reg  : in  STD_LOGIC_VECTOR(7 downto 0);
            b_from_instr   : in  STD_LOGIC_VECTOR(7 downto 0);
            c_in, mux_sel  : in  STD_LOGIC;
            sum            : out STD_LOGIC_VECTOR (7 downto 0);
            c_flag, z_flag : out STD_LOGIC);
end alu;

architecture alu_a of alu is
   signal sum_i, a_i, b_i  : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
   signal b_mux_i          : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
begin
   a_i <= '0' & a;
   b_i <= '0' & b_mux_i;
   sum <= sum_i(7 downto 0);
   with mux_sel select
      b_mux_i <=  b_from_reg        when '0',
                  b_from_instr      when '1',
                  (others => 'X')   when others;     
                  
process(a, b_mux_i, a_i, b_i, sum_i, sel, c_in) begin
c_flag <= '0';
z_flag <= '0';
sum_i <= (others => '0');
   case sel is 
      --ADD
      when x"0" =>
         sum_i <= a_i + b_i;
         if(sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         c_flag <= sum_i(8);
         
      --ADDC
      when x"1" =>
         sum_i <= a_i + b_i + c_in;
         if(sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         c_flag <= sum_i(8);
         
      --CMP
      when x"2" =>
         if(a = b_mux_i) then
            z_flag <= '1';
            c_flag <= '0';
         elsif(a < b_mux_i) then
            c_flag <= '1';
            z_flag <= '0';
         else 
            z_flag <= '0';
            c_flag <= '0';
         end if;
         
      --SUB --possible error here???
      when x"3" =>
         sum_i <= a_i - b_i;
         if(sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         c_flag <= sum_i(8);
         
      --SUBC
      when x"4" =>
         sum_i <= a_i - b_i - c_in;
         if(sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         c_flag <= sum_i(8);
         
      --AND
      when x"5" =>
      sum_i(7 downto 0) <= a and b_mux_i;
         if(sum_i(7 downto 0) = x"0") then
            z_flag <= '1';
         end if;
         
      --ASR
      when x"6" =>
         sum_i(7 downto 0) <= a(7) & a(7 downto 1);
         c_flag <= a(0);
         if(sum_i = x"00") then
            z_flag <= '1';
         end if;
         
      --EXOR
      when x"7" =>
         sum_i(7 downto 0) <= a xor b_mux_i;
         if(sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         
      --LSL
      when x"8" =>
         sum_i <= a & c_in;
         c_flag <= sum_i(8);
         if( sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         
      --LSR
      when x"9" =>
         sum_i(7 downto 0) <= c_in & a(7 downto 1);
         c_flag <= a(0);
         if( sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         
      --OR
      when x"a" =>
         sum_i(7 downto 0) <= a or b_mux_i;
         if( sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         
      --ROL
      when x"b" =>
         sum_i <= a(7 downto 0) & a(7);
         c_flag <= sum_i(8);
         if( sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         
      --ROR
      when x"c" =>
         sum_i(7 downto 0) <= a(0) & a(7 downto 1);
         c_flag <= a(0);
         if( sum_i(7 downto 0) = x"00") then
            z_flag <= '1';
         end if;
         
      --TEST
      when x"d" =>
         if((a and b_mux_i) = x"00") then
            z_flag <= '1';
         end if;
         
      --MOV
      when x"e" =>
         sum_i(7 downto 0) <= b_mux_i;
         
      when others =>
         sum_i <= '0' & x"00";
         z_flag <= '0';
         c_flag <= '0';
   end case;  
end process;
end alu_a;
