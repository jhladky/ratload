--------------------------------------------------------------------------------
-- Company: CPE233
-- Engineer: Jacob Hladky
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
 
ENTITY rat_sim_tb IS
END rat_sim_tb;
 
ARCHITECTURE behavior OF rat_sim_tb IS 
 
   -- Component Declaration for the Unit Under Test (UUT)
   COMPONENT rat_wrapper
      PORT( leds, seg   : OUT std_logic_vector(7 downto 0);
            sel         : OUT std_logic_vector(3 downto 0);
            tx          : OUT std_logic;
            switches    : IN  std_logic_vector(7 downto 0);
            rst, clk    : IN  std_logic;
            int, rx     : IN  std_logic);
  END COMPONENT;
    
   --Inputs
   signal switches   : std_logic_vector(7 downto 0) := (others => '0');
   signal rst        : std_logic := '0';
   signal clk        : std_logic := '0';
   signal int        : std_logic := '0';
   signal rx         : std_logic := '0';

 	--Outputs
   signal leds       : std_logic_vector(7 downto 0);
   signal seg        : std_logic_vector(7 downto 0);
   signal sel        : std_logic_vector(3 downto 0);
   signal tx         : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: RAT_wrapper PORT MAP (
          leds => leds,
          switches => switches,
          seg => seg,
          rx => rx,
          tx => tx,
          sel => sel,
          int => int,
          rst => rst,
          clk => clk);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
       -- hold reset state for 20 ns
      rst <= '1';
      wait for 20 ns;
      rst <= '0';
      wait for 50 ns; -- let the loop start
      for i in 0 to 19 loop   
         switches <= x"FF"; -- send the first data
         int <= '1';
         wait for 20 ns; 
         int <= '0';
         wait for 120 ns; -- wait for it to be processed
         
         switches <= x"aa"; -- send the first data
         int <= '1';
         wait for 20 ns; 
         int <= '0';
         wait for 120 ns; -- wait for it to be processed
         
      end loop;          
--      wait for clk_period*5;
--      switches <= x"aa";
--      int <= '1';
--      wait for clk_period*12;
      -- switches <= x"00";
      -- wait for clk_period*10;
      -- switches <= x"FC";
      wait;
   end process;
END;
