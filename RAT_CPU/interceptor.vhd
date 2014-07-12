----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
---
-- notes
-- when this module determines all instructions have been written, 
-- it forcibly transfers control to the new RAM by 
-- resetting pc and sp (use BRN and WSP)
-- this condition is when ins_cnt = 1024 (i.e. 1024 writes performed)
--
-- expects the instructions to be delivered in the following EXACT
-- format:
-- 1. (03 downto 00)
-- 2. (07 downto 04) 
-- 3. (11 downto 08)
-- 4. (15 downto 12)
-- 5. (17 downto 16)
-- then no more instructions can come in for one clock cycle
--
---
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity interceptor is
   Port( ins_rom_in  : in  STD_LOGIC_VECTOR(17 downto 0);
         ins_ram_in  : in  STD_LOGIC_VECTOR(17 downto 0);
         data_in     : in  STD_LOGIC_VECTOR(7 downto 0);
         clk         : in  STD_LOGIC;
         address_in  : in  STD_LOGIC_VECTOR(9 downto 0);  
         address_out : out STD_LOGIC_VECTOR(9 downto 0);
         ins_out     : out STD_LOGIC_VECTOR(17 downto 0);
         ins_ram_prog: out STD_LOGIC_VECTOR(17 downto 0);
         ram_we      : out STD_LOGIC;
         ram_oe      : out STD_LOGIC);
end interceptor;

architecture interceptor_a of interceptor is

signal cnt_inc_i     : STD_LOGIC := '0';
signal cnt_rst_i     : STD_LOGIC := '0';
signal ins_cnt_inc_i : STD_LOGIC := '0';
signal cnt           : UNSIGNED(2 downto 0) := (others => '0');
signal ins_cnt       : UNSIGNED(10 downto 0) := (others => '0');

type hex_en_arr is array (0 to 4) of std_logic;
signal hex_en_i      : hex_en_arr := (others => '0');

type ins_hex_arr is array (0 to 4) of std_logic_vector(3 downto 0);
signal ins_hex_i     : ins_hex_arr := (others => (others => '0'));

type state_type is (st_int, st_get_input, st_write_ins, st_trans, st_end);
signal ps, ns        : state_type;

begin
process(clk) begin
   if(rising_edge(clk)) then
      for i in 0 to 4 loop
         if(hex_en_i(i) = '1') then
            ins_hex_i(i) <= data_in(3 downto 0);
         end if;
      end loop;
      if(cnt_inc_i = '1') then
         cnt <= cnt + 1;
      elsif(cnt_rst_i = '1') then
         cnt <= "000";
      end if;
      if(ins_cnt_inc_i = '1') then
         ins_cnt <= ins_cnt + 1;
      end if;
      ps <= ns;
   end if;
end process;

process(ps, data_in, ins_rom_in, ins_ram_in, ins_hex_i, cnt, ins_cnt, address_in) begin
   ins_out <= ins_rom_in;
   ram_we <= '0';
   ram_oe <= '0';
   ins_ram_prog <= (others => '0');
   hex_en_i <= "00000";
   cnt_inc_i <= '0';
   cnt_rst_i <= '0';
   ins_cnt_inc_i <= '0';
   address_out <= address_in;
   case ps is
      -- wait until the special instruction is sent
      -- this will happen during the fetch cycle
      when st_int =>
         ns <= st_int;
         if(ins_rom_in(17 downto 13) = "01111") then -- new LDPR special opcode
            ins_out <= "11010" & ins_rom_in(12 downto 0);
            ns <= st_get_input;
         end if;
         if(ins_cnt = "10000000000") then
            ns <= st_trans;
         end if;
         
      -- get the data and put it into the proper place
      when st_get_input =>
         ns <= st_int;
         -- we still need to assert the OUT ins instead of the LDPR
         -- each instruction needs TWO clock cycles
         ins_out <= "11010" & ins_rom_in(12 downto 0);
         if(cnt <= "011") then
            hex_en_i(to_integer(cnt)) <= '1';
            cnt_inc_i <= '1';
         else 
            hex_en_i(4) <= '1';
            cnt_rst_i <= '1';
            ns <= st_write_ins;
         end if;
         
      -- once we have the 3 parts of the ins, write it to the RAM
      -- fetch cycle again (thus we CANNOT have consecutive LDPR instructions)
      -- ideally it'll take a long time for each byte to be ready anyway
      when st_write_ins =>
         ns <= st_int;
         ram_we <= '1';
         ram_oe <= '1';
         address_out <= std_logic_vector(ins_cnt(9 downto 0));
         ins_ram_prog <=   ins_hex_i(4)(1 downto 0) & ins_hex_i(3) & ins_hex_i(2) &
                           ins_hex_i(1) & ins_hex_i(0);
         ins_cnt_inc_i <= '1';
         if(ins_cnt = "10000000000") then --1024 increments
            ns <= st_trans;
         end if;
         
      -- steps necessary to transfer control to RAM:
      -- reset pc and sp to 0
      when st_trans =>
         if((cnt = "000") or (cnt = "001")) then
            -- the WSP ins, to reset sp to 0
            -- we have to hold this for 2 cycles
            ins_out <= "01010" & "10000" & "00000000";
            cnt_inc_i <= '1';
            ns <= st_trans;
         elsif(cnt = "010") then
            -- the BRN ins, to reset pc to 0
            ins_out <= "00100" & "0000000000" & "000";
            cnt_inc_i <= '1';
            ns <= st_trans;
         else
            -- keep asserting BRN 0x00, we need to get to st_end
            ins_out <= "00100" & "0000000000" & "000";
            ns <= st_end;
         end if;
         
      -- we are done. only use prog_ram now. 
      -- note we can't get out of this state
      when st_end =>
         ram_oe <= '1';
         ins_out <= ins_ram_in;
         ns <= st_end;
         
      -- to prevent latches
      when others =>
         ns <= st_int;
         if(ins_cnt = "10000000000") then
            ns <= st_end;
         end if;
   end case; 
end process;
end interceptor_a;
