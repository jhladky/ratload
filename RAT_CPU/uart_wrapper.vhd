-------------------------------------------------------------------------
-- Class: CPE233
-- Engineer: Jacob Hladky
-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart_wrapper is
   Port( TX		   : out std_logic;                       -- Transmit pin.
         RX		   : in  std_logic;                       -- Receive pin.
		  	CLK, RST	: in  std_logic;                       -- Clock and reset.
         DATA_IN  : in  std_logic_vector(7 downto 0);    -- Data from the RAT into the UART
			DATA_OUT	: out std_logic_vector(7 downto 0);    -- Data from the UART to the RAT
         INT      : out std_logic);                      -- Interrupt to the RAT to signal the data is ready.
end uart_wrapper;

architecture uart_wrapper_a of uart_wrapper is

   constant BAUD_RATE         : positive := 115200;
   constant CLOCK_FREQUENCY   : positive := 50000000;

-- The actual UART.
component UART is
generic (
       BAUD_RATE           : positive;
       CLOCK_FREQUENCY     : positive
   );
port (  -- General
       CLOCK               :   in      std_logic;
       RESET               :   in      std_logic;    
       DATA_STREAM_IN      :   in      std_logic_vector(7 downto 0);
       DATA_STREAM_IN_STB  :   in      std_logic;
       DATA_STREAM_IN_ACK  :   out     std_logic;
       DATA_STREAM_OUT     :   out     std_logic_vector(7 downto 0);
       DATA_STREAM_OUT_STB :   out     std_logic;
       DATA_STREAM_OUT_ACK :   in      std_logic;
       TX                  :   out     std_logic;
       RX                  :   in      std_logic
    );
end component UART;

-- Convert data from the UART from ASCII.
component ascii_to_int is
   Port( ascii_in : in  STD_LOGIC_VECTOR(7 downto 0);
         int_out  : out STD_LOGIC_VECTOR(7 downto 0));
end component;

-- Convert data going to the UART to ASCII.
component int_to_ascii is
   Port( int_in   : in  STD_LOGIC_VECTOR(7 downto 0);
         ascii_out: out STD_LOGIC_VECTOR(7 downto 0));
end component;

   -- Signals to interface with the UART.
   signal s_conv_to_uart   : std_logic_vector(7 downto 0);
   signal s_uart_to_conv   : std_logic_vector(7 downto 0);
   signal s_in_stb         : std_logic;
   signal s_in_ack         : std_logic;
   signal s_out_stb        : std_logic;
   signal s_out_ack        : std_logic;
   
   -- Register for storing the data we're expecting.
   signal s_expect         : std_logic_vector(7 downto 0);
   signal s_expect_new     : std_logic_vector(7 downto 0);
   signal s_expect_strb    : std_logic;
	
   type state_type is (
      st_wait_receive,  -- Wait for the UART to receive data.
      st_assert_int,    -- State to assert the interrupt for an extra tick.
      st_wait_rat,      -- Wait for the RAT CPU to proces the data.
      st_wait_send      -- Wait for the UART to send the data.
   );
   
	signal ps	   :	state_type := st_wait_receive;
	signal ns	   :	state_type;
   
begin

atoi : ascii_to_int port map (
   ascii_in => s_uart_to_conv,
   int_out => data_out); 
   
itoa : int_to_ascii port map(
   int_in => data_in,
   ascii_out => s_conv_to_uart);

uart1: uart 
generic map(
   BAUD_RATE            => BAUD_RATE,
   CLOCK_FREQUENCY      => CLOCK_FREQUENCY
)
port map(
   clock                => clk,
   reset                => rst,
   data_stream_in       => s_conv_to_uart,   -- Transmit data bus.
   data_stream_in_stb   => s_in_stb,         -- Transmit strobe.
   data_stream_in_ack   => s_in_ack,         -- Transmit acknowledgement.
   data_stream_out      => s_uart_to_conv,   -- Receive data bus.
   data_stream_out_stb  => s_out_stb,        -- Receive strobe.
   data_stream_out_ack  => s_out_ack,        -- Receive acknowledgement.
   tx                   => tx,
   rx                   => rx
);

-- State machine controller.
process (clk, rst) begin
   if(rst = '1') then
      ps <= st_wait_receive;
      s_expect <= x"00";
   elsif(rising_edge(clk)) then
      ps <= ns;
      if (s_expect_strb = '1') then
         s_expect <= s_expect_new;
      end if;
   end if;
end process;

-- We're listening to s_in_ack, to know when we've successfully sent data,
-- and s_out_stb, to know when there is data available to us.
process(ps, s_conv_to_uart, s_uart_to_conv, s_in_ack, s_out_stb, data_in, s_expect) begin
   int <= '0';
   s_in_stb <= '0';
   s_out_ack <= '0';
   s_expect_strb <= '0';
   s_expect_new <= x"00";
   case ps is
      when st_wait_receive =>
         ns <= st_wait_receive;
         if (s_out_stb = '1') then
            s_out_ack <= '1';
            int <= '1';
            s_expect_strb <= '1';
            s_expect_new <= s_uart_to_conv;
            ns <= st_assert_int;
         end if;
      when st_assert_int =>
         int <= '1';
         ns <= st_wait_rat;
      when st_wait_rat =>
         ns <= st_wait_rat;
         if (s_conv_to_uart = s_expect) then
            s_in_stb <= '1';
            ns <= st_wait_send;
         end if;
      when st_wait_send =>
         ns <= st_wait_send;
         s_in_stb <= '1';
         if (s_in_ack = '1') then
            ns <= st_wait_receive;
         end if;
      when others =>
         ns <= st_wait_receive;
   end case;
end process;
end uart_wrapper_a;