-------------------------------------------------------------------------
-- uart.vhd
-------------------------------------------------------------------------
-- Author:  Dan Pederson
--          Copyright 2004 Digilent, Inc.		
-------------------------------------------------------------------------
-- Revision History:
--  	07/30/04 (DanP) Created
--		05/26/05 (DanP) Modified for Pegasus board/Updated commenting style
--		06/07/05	(DanP) LED scancode display added
--    03/04/13 (Jacob Hladky) Edited and customized
-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart is
   Port( TXD		: out std_logic := '1';
         RXD		: in  std_logic := '1';
		  	CLK, RST	: in  std_logic;  
         DATA_IN  : in  std_logic_vector(7 downto 0);
			DATA_OUT	: out std_logic_vector(7 downto 0);        
         INT      : out std_logic); -- signals the data is ready
end uart;

architecture uart_a of uart is

-- the actual Digilent provided UART  
component RS232RefComp
   Port( RXD      : in	   std_logic;
         RST, CLK : in	   std_logic;
			DBIN     : in	   std_logic_vector(7 downto 0);
			RD, WR   : in	   std_logic;			
			RDA      : inout	std_logic;							
			TBE      : inout	std_logic := '1';				
         TXD      : out	   std_logic := '1';
         DBOUT    : out	   std_logic_vector(7 downto 0);
			PE, FE   : out	   std_logic;							
			OE       : out	   std_logic);         
end component;	

-- we have to convert the signals in from ascii to int
component ascii_to_int is
   Port( ascii_in : in  STD_LOGIC_VECTOR(7 downto 0);
         int_out  : out STD_LOGIC_VECTOR(7 downto 0));
end component;

-- on the way out we have to convert them back to acsii
component int_to_ascii is
   Port( int_in   : in  STD_LOGIC_VECTOR(7 downto 0);
         ascii_out: out STD_LOGIC_VECTOR(7 downto 0));
end component;

   signal dbin_i  : std_logic_vector(7 downto 0); -- data into the UART
	signal dbOut_i	: std_logic_vector(7 downto 0); -- data out of the UART
	signal rda_i	: std_logic; -- 1 means read data is available
	signal tbe_i	: std_logic; -- 1 means the transfer bus is empty
	signal rd_i	   : std_logic; -- the read strobe, flash after data read
	signal wr_i	   : std_logic; -- flash to tell the UART to send
	
   type state_type is (st_start, st_receive, st_wait, st_send);
	signal ps	   :	state_type := st_start;
	signal ns	   :	state_type;
   
begin

atoi : ascii_to_int port map (
   ascii_in => dbout_i,
   int_out => data_out); 
   
itoa : int_to_ascii port map(
   int_in => data_in,
   ascii_out => dbin_i);

-- maps the signals and ports  to RS232RefComp
UART: RS232RefComp port map (	
   TXD => TXD,
   RXD => RXD,
   CLK => CLK,
   RST => RST,
   RDA => rda_i,
   TBE => tbe_i,
   DBIN => dbin_i,
   DBOUT => dbout_i,
   RD => rd_i,
   WR => wr_i,
   PE => open, -- we're don't care about errors
   FE => open, -- lol
   OE => open);
   
-- standard state machine controller
process (clk, rst) begin
   if(rst = '1') then
      ps <= st_start;
   elsif(rising_edge(clk)) then
      ps <= ns;
   end if;
end process;

-- the main FSM. Behavior:
-- waits for the start signal, when recieved,
-- sends it back. this behavior is repeated for all
-- other data
process(ps, rda_i, dbout_i, dbin_i, tbe_i) begin
   int <= '0';
   rd_i <= '0';
   wr_i <= '0';
   case ps is 
      -- we start by waiting for the confirm signal from the computer
      -- then we send it back. after that the computer will start sending the data
      when st_start => 
         ns <= st_start;
         if(dbout_i = x"7e" and dbin_i = x"7e") then -- the confirm char
            rd_i <= '1'; -- we have read the data
            wr_i <= '1'; -- and we want to send it back
            ns <= st_send;
         end if;
         
      -- wait for the uart to send the data
      when st_receive =>        
         ns <= st_receive;
         if (rda_i = '1') then
            int <= '1'; -- data is ready, send the interrupt
            ns <= st_wait;
         end if;   
         
      -- wait for the cpu to send the byte back out
      when st_wait =>
         ns <= st_wait;
         if(dbin_i = dbout_i) then
            ns <= st_send;
            wr_i <= '1';
            rd_i <= '1';
         end if;
         
      -- send the byte back
      when st_send =>  
         ns <= st_send;
         if(tbe_i <= '1') then
            ns <= st_receive;
         end if;
   end case;
end process;
end uart_a;