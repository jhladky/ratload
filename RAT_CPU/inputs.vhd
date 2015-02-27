----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity inputs is
   Port( input_port  : out STD_LOGIC_VECTOR(7 downto 0);  -- the input corresponding to the port_id
         clk         : in  STD_LOGIC;
         buttons     : in  STD_LOGIC_VECTOR(2 downto 0);
         switches    : in  STD_LOGIC_VECTOR(7 downto 0);  -- the current value of the switches on the Nexsys board
         uart_in     : in  STD_LOGIC_VECTOR(7 downto 0);  -- input from the serial port
         port_id     : in  STD_LOGIC_VECTOR(7 downto 0)); -- the currently active port_id
end inputs;

architecture Behavioral of inputs is
-- INPUT PORT IDS -------------------------------------------------------------
CONSTANT SWITCHES_ID : STD_LOGIC_VECTOR(7 downto 0) := X"20"; 
CONSTANT SERIAL_ID   : STD_LOGIC_VECTOR(7 downto 0) := x"0F";
CONSTANT RANDOM_ID   : STD_LOGIC_VECTOR(7 downto 0) := x"1B";
CONSTANT BUTTONS_ID  : STD_LOGIC_VECTOR(7 downto 0) := x"21";

component random is
   Port( clk         : in  STD_LOGIC;
         random_num  : out STD_LOGIC_VECTOR(7 downto 0));
end component;

signal rand_i        : STD_LOGIC_VECTOR(7 downto 0);
begin

random1 : random port map(
   clk => clk,
   random_num => rand_i);

-- Mux for selecting what input to read -----------------------------------
process(port_id, switches, uart_in, rand_i, buttons) begin
   case (port_id) is
      when SWITCHES_ID  => input_port <= switches;
      when SERIAL_ID    => input_port <= uart_in;
      when RANDOM_ID    => input_port <= rand_i;
      when BUTTONS_ID   => input_port <= "00000" & buttons;
      when others       => input_port <= x"00";
   end case;
end process;
-------------------------------------------------------------------------------


end Behavioral;
