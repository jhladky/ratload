-- 
-- The interface to the VGA driver module. Extended to both read and write
-- to the framebuffer (to check the color values of a particular pixel).
--
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vgaDriverBuffer is
   Port( CLK, we     : in  std_logic;
         wa          : in  std_logic_vector(10 downto 0);
         wd          : in  std_logic_vector(7 downto 0);
         rout, gout  : out std_logic_vector(2 downto 0);
         Bout        : out std_logic_vector(1 downto 0);
         HS, vs      : out std_logic;
         pixelData   : out std_logic_vector(7 downto 0));
end vgaDriverBuffer;

architecture Behavioral of vgaDriverBuffer is

-- vga driver signals
signal ra            : std_logic_vector(10 downto 0);
signal vgaData       : std_logic_vector(7 downto 0);
signal fb_wr, vgaclk : std_logic;
signal red, green    : std_logic_vector(2 downto 0);
signal blue          : std_logic_vector(1 downto 0);
signal row, column   : std_logic_vector(9 downto 0);
-- Added to read the pixel data at address 'wa' -- pfh, 3/1/2012
signal pixelVal      : std_logic_vector(7 downto 0);

-- Declare VGA driver components
component VGAdrive is
   Port( clock       : in std_logic;  -- 25.175 Mhz clock
         red, green  : in std_logic_vector(2 downto 0);
         blue        : in std_logic_vector(1 downto 0);
         row, column : out std_logic_vector(9 downto 0); -- for current pixel
         Rout, Gout  : out std_logic_vector(2 downto 0);
         Bout        : out std_logic_vector(1 downto 0);
         H, V        : out std_logic); -- VGA drive signals
end component;

component ram2k_8 is
   Port( clk, we     : in  STD_LOGIC;
         ra, wa      : in  STD_LOGIC_VECTOR(10 downto 0);
         wd          : in  STD_LOGIC_VECTOR(7 downto 0);
         rd, pixelval: out STD_LOGIC_VECTOR(7 downto 0));
end component; 

component vga_clk_div is
   Port( clk         : in  std_logic;
         clkout      : out std_logic);
end component;

begin

frameBuffer : ram2k_8 port map(  
   clk => clk,       --CLK
   we => we,
   ra => ra,
   wa => wa,
   wd => wd,
   rd => vgaData,
   pixelVal => pixelVal);
                                       
vga_out : VGAdrive port map(  
   clock => vgaclk,
   red => red,
   green => green,
   blue => blue,
   row => row,
   column => column,
   Rout => Rout,
   Gout => Gout,
   Bout => Bout,
   H => HS,
   V => VS);    
   
vga_clk : vga_clk_div port map(  
   clk => CLK, 
   clkout => vgaclk);
                                  
-- read signals from fb
ra <= row (8 downto 4) & column(9 downto 4); 
red <= vgaData(7 downto 5);      
green <= vgaData(4 downto 2);
blue <= vgaData(1 downto 0);
pixelData <= pixelVal; -- returns the pixel data in the framebuffer at address 'wa'

end Behavioral;
