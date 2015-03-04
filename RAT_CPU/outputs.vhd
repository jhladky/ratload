----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity outputs is
   Port( leds, seg   : out STD_LOGIC_VECTOR(7 downto 0); -- output to the board leds // 7-seg segments
         sel         : out STD_LOGIC_VECTOR(3 downto 0); -- output to the 7-seg enables
         uart_out    : out STD_LOGIC_VECTOR(7 downto 0); -- output to the serial port
         port_id     : in  STD_LOGIC_VECTOR(7 downto 0); -- id of the currently active port
         output_port : in  STD_LOGIC_VECTOR(7 downto 0); -- current value of the output
         io_oe, clk  : in  STD_LOGIC);                   -- no output unless io_oe is 1
end outputs;

architecture outputs_a of outputs is

-- OUTPUT PORT IDS ------------------------------------------------------------
CONSTANT LEDS_ID     : STD_LOGIC_VECTOR(7 downto 0) := x"40";
CONSTANT SSEG_ID     : STD_LOGIC_VECTOR(7 downto 0) := x"81";
CONSTANT SERIAL_ID   : STD_LOGIC_VECTOR(7 downto 0) := x"0E";
-------------------------------------------------------------------------------

component sseg_dec is
   Port( alu_val           : in  std_logic_vector(7 downto 0); 
         sign, valid, clk  : in  std_logic;
         disp_en           : out std_logic_vector(3 downto 0);
         segments          : out std_logic_vector(7 downto 0));
end component;

component clk_div_sseg is
   Port( clk   : in  std_logic;
         sclk  : out std_logic);
end component;

signal sseg_in_i           : STD_LOGIC_VECTOR(7 downto 0);
signal sseg_valid_i        : STD_LOGIC := '0';
signal sclk_i              : STD_LOGIC;

begin

sseg_dec1 : sseg_dec port map(
   alu_val => sseg_in_i,
   sign => '0',
   valid => sseg_valid_i,
   clk => sclk_i,
   disp_en => sel,
   segments => seg);
 
clk_div1 : clk_div_sseg port map(
   clk => clk,
   sclk => sclk_i);

-- Mux for updating outputs -----------------------------------------------
-- Note that outputs are updated on the rising edge of the clock, when
-- the io_oe signal is asserted
OUTPUTS: process(clk) begin
   if (rising_edge(clk)) then
      if (io_oe = '1') then
         case (port_id) is
            when LEDS_ID => 
               LEDS <= output_port;
            when SSEG_ID =>
               sseg_valid_i <= '1';
               sseg_in_i <= output_port;
            when SERIAL_ID =>
               uart_out <= output_port;
            when others  =>
               -- sseg_valid_i <= '0';
               -- sseg_in_i <= (others => '0');
         end case;
      end if;
   end if;
end process OUTPUTS;
-------------------------------------------------------------------------------
end outputs_a;
