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
         rx       : in  STD_LOGIC;
         buttons  : in  STD_LOGIC_VECTOR(2 downto 0);
         tx       : out STD_LOGIC;
         hs       : out STD_LOGIC;
         vs       : out STD_LOGIC;
         rout     : out STD_LOGIC_VECTOR(2 downto 0);
         gout     : out STD_LOGIC_VECTOR(2 downto 0);
         bout     : out STD_LOGIC_VECTOR(1 downto 0);
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
         vga_in      : in  STD_LOGIC_VECTOR(7 downto 0);
         uart_in     : in  STD_LOGIC_VECTOR(7 downto 0);
         port_id     : in  STD_LOGIC_VECTOR(7 downto 0));
end component;

component outputs is
   Port( leds, seg   : out STD_LOGIC_VECTOR(7 downto 0); 
         sel         : out STD_LOGIC_VECTOR(3 downto 0);
         vga_we      : out STD_LOGIC;
         vga_wa      : out STD_LOGIC_VECTOR(10 downto 0);
         vga_wd      : out STD_LOGIC_VECTOR(7 downto 0); 
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

component vgaDriverBuffer is
   Port( clk, we     : in  STD_LOGIC;
         wa          : in  STD_LOGIC_VECTOR(10 downto 0);
         wd          : in  STD_LOGIC_VECTOR(7 downto 0);
         rout, gout  : out STD_LOGIC_VECTOR(2 downto 0);
         bout        : out STD_LOGIC_VECTOR(1 downto 0);
         hs, vs      : out STD_LOGIC;
         pixelData   : out STD_LOGIC_VECTOR(7 downto 0));
end component;

-- Signals for connecting RAT_CPU to RAT_wrapper -----------------------------
signal in_port_i     : std_logic_vector(7 downto 0);
signal out_port_i    : std_logic_vector(7 downto 0);
signal uart_in_i     : std_logic_vector(7 downto 0);
signal uart_out_i    : std_logic_vector(7 downto 0);
signal port_id_i     : std_logic_vector(7 downto 0);
signal io_oe_i       : std_logic;
signal int_i         : std_logic;

signal wa_i          : std_logic_vector(10 downto 0);
signal wd_i          : std_logic_vector(7 downto 0);
signal we_i          : std_logic;
signal pixel_data_i  : std_logic_vector(7 downto 0);

begin

-- Instantiate RAT_CPU --------------------------------------------------------
rat_cpu1 : rat_cpu port map(
   in_port  => in_port_i,     -- int sig  to int in 
   out_port => out_port_i,    -- int sig  to int sig
	port_id  => port_id_i,     -- int sig  to int sig
   rst      => rst,           -- ext in   to int in
   io_oe    => io_oe_i,       -- int sig  to int sig
   int_in   => int_i,         -- int sig  to int in
   clk      => clk);          -- ext in   to int in

-- Instantiate Inputs --------------------------------------------------------
inputs1 : inputs port map(
   input_port => in_port_i,   -- int out  to int sig
   clk        => clk,
   buttons    => buttons,
   switches   => switches,    -- ext in   to int in
   vga_in     => pixel_data_i,
   uart_in    => uart_in_i,   -- int sig  to int in
	port_id    => port_id_i);  -- int sig  to int inp

-- Instantiate Outputs --------------------------------------------------------
outputs1 : outputs port map(
   leds        => leds,       -- int out  to ext out
   seg         => seg,        -- int out  to ext out
   sel         => sel,        -- int out  to ext out
   vga_wa      => wa_i,
   vga_wd      => wd_i,
   vga_we      => we_i,
   uart_out    => uart_out_i, -- int out  to int sig
   port_id     => port_id_i,  -- int out  to int sig
 	output_port => out_port_i, -- int sig  to int in
	io_oe       => io_oe_i,    -- int sig  to int in
	clk         => clk);	      -- ext in   to int in
	
-- Instantiate UART -----------------------------------------------------------
uart1 : uart port map(
   txd => tx, 
   rxd => rx,
   clk => clk,
   rst => rst,
   int => int_i,
   data_in => uart_out_i,     -- data going OUT OF The board
   data_out => uart_in_i);    -- data going INTO the board

-- Instantiate VGA ------------------------------------------------------------
vga1 : vgaDriverBuffer port map(
   clk => clk,
   we => we_i,
   wa => wa_i,
   wd => wd_i,
   rout => rout,
   gout => gout,
   bout => bout,
   hs => hs,
   vs => vs,
   pixeldata => pixel_data_i);

end rat_wrapper_a;
