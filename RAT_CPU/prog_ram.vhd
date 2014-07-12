----------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.vcomponents.all;

entity prog_ram is
   Port( clk         : in  STD_LOGIC;
         address     : in  STD_LOGIC_VECTOR(9 downto 0);
         instruction : out STD_LOGIC_VECTOR(17 downto 0);
         ins_prog    : in  STD_LOGIC_VECTOR(17 downto 0);
         we, oe      : in  STD_LOGIC);
end prog_ram;

architecture prog_ram_a of prog_ram is
--   type memory is array (0 to 1023) of std_logic_vector(17 downto 0);
--   signal prog_ram_data : memory := (others => (others => '0'));  
component RAMB16_S18 
-- pragma translate_on
  port (
	DI     : in std_logic_vector (15 downto 0);
	DIP    : in std_logic_vector (1 downto 0);
	ADDR   : in std_logic_vector (9 downto 0);
	EN     : in std_logic;
	WE     : in std_logic;
	SSR    : in std_logic;
	CLK    : in std_logic;
	DO     : out std_logic_vector (15 downto 0);
	DOP    : out std_logic_vector (1 downto 0)); 
end component;

begin
--process(clk, address, we) 
--   variable ins_cnt : integer range 0 to 1023 := 0;
--begin
--   if(rising_edge(clk)) then
--      if(we = '1') then
--         prog_ram_data(ins_cnt) <= ins_prog;
--         ins_cnt := ins_cnt + 1;
--      end if;
--   end if;
--end process;
--instruction <= prog_ram_data(conv_integer(address));

-- Block SelectRAM Instantiation
U_RAMB16_S18: RAMB16_S18 port map(
	DI     => ins_prog(15 downto 0),       -- 16 bits data in bus (<15 downto 0>)
	DIP    => ins_prog(17 downto 16),      -- 2 bits parity data in bus (<17 downto 16>)
	ADDR   => address,                     -- 10 bits address bus	
	EN     => oe,                          -- enable signal
	WE     => we,                          -- write enable signal
	SSR    => '0',                         -- set/reset signal
	CLK    => clk,                         -- clock signal
	DO     => instruction(15 downto 0),    -- 16 bits data out bus (<15 downto 0>)
	DOP    => instruction(17 downto 16));  -- 2 bits parity data out bus (<17 downto 16>)
   
end prog_ram_a;
