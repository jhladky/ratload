----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity prog_rom is
   Port( address     : in  STD_LOGIC_VECTOR(9 downto 0);
         clk         : in  STD_LOGIC;
         instruction : out STD_LOGIC_VECTOR(17 downto 0);
         tristate_in : in  STD_LOGIC_VECTOR(7 downto 0));
end prog_rom;

architecture prog_rom_a of prog_rom is

component real_prog_rom is
   Port( address     : in  STD_LOGIC_VECTOR(9 downto 0);
         clk         : in  STD_LOGIC;
         instruction : out STD_LOGIC_VECTOR(17 downto 0));
end component;

component prog_ram is 
   Port( address     : in  STD_LOGIC_VECTOR(9 downto 0);
         clk, we, oe : in  STD_LOGIC;
         ins_prog    : in  STD_LOGIC_VECTOR(17 downto 0);
         instruction : out STD_LOGIC_VECTOR(17 downto 0));
end component;

component interceptor is 
   Port( ins_rom_in  : in  STD_LOGIC_VECTOR(17 downto 0); 
         ins_ram_in  : in  STD_LOGIC_VECTOR(17 downto 0);
         clk         : in  STD_LOGIC;
         address_in  : in  STD_LOGIC_VECTOR(9 downto 0); 
         data_in     : in  STD_LOGIC_VECTOR(7 downto 0);
         address_out : out STD_LOGIC_VECTOR(9 downto 0);
         ins_ram_prog: out STD_LOGIC_VECTOR(17 downto 0);
         ins_out     : out STD_LOGIC_VECTOR(17 downto 0);
         ram_we      : out STD_LOGIC;
         ram_oe      : out STD_LOGIC);
end component;

signal ram_we_i      : STD_LOGIC;
signal ram_oe_i      : STD_LOGIC;
signal address_out_i : STD_LOGIC_VECTOR(9 downto 0);
signal ins_ram_i     : STD_LOGIC_VECTOR(17 downto 0);
signal ins_rom_i     : STD_LOGIC_VECTOR(17 downto 0);
signal ins_prog_i    : STD_LOGIC_VECTOR(17 downto 0);
         
begin

rpr1 : real_prog_rom port map(
   address     => address,
   clk         => clk,
   instruction => ins_rom_i);

prog_ram1 : prog_ram port map(
   address     => address_out_i,
   clk         => clk,
   we          => ram_we_i,
   oe          => ram_oe_i,
   instruction => ins_ram_i,
   ins_prog    => ins_prog_i);

int1 : interceptor port map(
   ins_rom_in  => ins_rom_i,
   ins_ram_in  => ins_ram_i,
   ins_ram_prog => ins_prog_i,
   clk         => clk, 
   address_in  => address,
   address_out => address_out_i,
   data_in     => tristate_in,
   ins_out     => instruction,
   ram_we      => ram_we_i,
   ram_oe      => ram_oe_i);

end prog_rom_a;
