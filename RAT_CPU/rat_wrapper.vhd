------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rat_wrapper is
   Port( switches : in  STD_LOGIC_VECTOR(7 downto 0);
         buttons  : in  STD_LOGIC_VECTOR(2 downto 0);
         rx       : in  STD_LOGIC;
         tx       : out STD_LOGIC;
         clk      : in  STD_LOGIC;
         rst      : in  STD_LOGIC;
         sel      : out STD_LOGIC_VECTOR(3 downto 0);
         seg      : out STD_LOGIC_VECTOR(7 downto 0);
         leds     : out STD_LOGIC_VECTOR(7 downto 0));
end rat_wrapper;

architecture rat_wrapper_a of rat_wrapper is

-- Declare RAT_CPU and I/O components ----------------------------------------
component rat_cpu 
   Port( in_port     : in  STD_LOGIC_VECTOR(7 downto 0);
         rst         : in  STD_LOGIC;
         int_in, clk : in  STD_LOGIC;
         out_port    : out STD_LOGIC_VECTOR(7 downto 0);
         port_id     : out STD_LOGIC_VECTOR(7 downto 0);
         io_oe       : out STD_LOGIC);
end component;

component inputs is
   Port( input_port  : out STD_LOGIC_VECTOR(7 downto 0);
         clk         : in  STD_LOGIC;
         buttons     : in  STD_LOGIC_VECTOR(2 downto 0);
         switches    : in  STD_LOGIC_VECTOR(7 downto 0);
         uart_in     : in  STD_LOGIC_VECTOR(7 downto 0);
         port_id     : in  STD_LOGIC_VECTOR(7 downto 0));
end component;

component outputs is
   Port( leds, seg   : out STD_LOGIC_VECTOR(7 downto 0); 
         sel         : out STD_LOGIC_VECTOR(3 downto 0); 
         uart_out    : out STD_LOGIC_VECTOR(7 downto 0);
         port_id     : in  STD_LOGIC_VECTOR(7 downto 0); 
         output_port : in  STD_LOGIC_VECTOR(7 downto 0); 
         io_oe, clk  : in  STD_LOGIC);
end component;

component uart is
   Port( txd		   : out STD_LOGIC := '1';
         rxd		   : in  STD_LOGIC := '1';
         clk, rst    : in  STD_LOGIC;
         int         : out STD_LOGIC;
			data_out	   : out STD_LOGIC_VECTOR(7 downto 0); 
         data_in     : in  STD_LOGIC_VECTOR(7 downto 0)); -- data going INTO the UART
end component;

-- Signals for connecting RAT_CPU to RAT_wrapper -----------------------------
signal in_port_i     : std_logic_vector(7 downto 0);
signal out_port_i    : std_logic_vector(7 downto 0);
signal uart_in_i     : std_logic_vector(7 downto 0);
signal uart_out_i    : std_logic_vector(7 downto 0);
signal port_id_i     : std_logic_vector(7 downto 0);
signal io_oe_i       : std_logic;
signal int_i         : std_logic;

begin

-- Instantiate RAT_CPU --------------------------------------------------------
rat_cpu1 : rat_cpu port map(
   in_port     => in_port_i,
   out_port    => out_port_i,
	port_id     => port_id_i,
   rst         => rst,
   io_oe       => io_oe_i,
   int_in      => int_i,
   clk         => clk);

-- Instantiate Inputs --------------------------------------------------------
inputs1 : inputs port map(
   input_port  => in_port_i,
   clk         => clk,
   buttons     => buttons,
   switches    => switches,
   uart_in     => uart_in_i,
	port_id     => port_id_i);

-- Instantiate Outputs --------------------------------------------------------
outputs1 : outputs port map(
   leds        => leds,
   seg         => seg,
   sel         => sel,
   uart_out    => uart_out_i,
   port_id     => port_id_i,
 	output_port => out_port_i,
	io_oe       => io_oe_i,
	clk         => clk);
	
-- Instantiate UART -----------------------------------------------------------
uart1 : uart port map(
   txd         => tx, 
   rxd         => rx,
   clk         => clk,
   rst         => rst,
   int         => int_i,
   data_in     => uart_out_i,    -- data going OUT OF The board
   data_out    => uart_in_i);    -- data going INTO the board
   
end rat_wrapper_a;