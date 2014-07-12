----------------------------------------------------------------------------------
-- Company: none
-- Engineer: Jacob Hladky and Curtis Jonaitis
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rat_cpu is
   Port( IN_PORT        : in  STD_LOGIC_VECTOR(7 downto 0);
         INT_IN, RST    : in  STD_LOGIC;
         CLK            : in  STD_LOGIC;
         OUT_PORT       : out STD_LOGIC_VECTOR(7 downto 0);
         PORT_ID        : out STD_LOGIC_VECTOR(7 downto 0);
         IO_OE          : out STD_LOGIC);
end rat_cpu;

architecture rat_cpu_a of rat_cpu is

component prog_rom is
   Port( ADDRESS        : in  STD_LOGIC_VECTOR(9 downto 0); 
         CLK            : in  STD_LOGIC; 
         TRISTATE_IN    : in  STD_LOGIC_VECTOR(7 downto 0);
         INSTRUCTION    : out STD_LOGIC_VECTOR(17 downto 0));
end component;

component flag_reg is
   Port( IN_FLAG, SAVE  : in  STD_LOGIC; --flag input // save the flag value (?)
         LD, SET, CLR   : in  STD_LOGIC; --load the out_flag with the in_flag value // set the flag to '1' // clear the flag to '0'
         CLK, RESTORE   : in  STD_LOGIC; --system clock // restore the flag value (?)
         OUT_FLAG       : out STD_LOGIC); --flag output
end component;

component program_counter is
   Port( CLK, RST, OE   : in     STD_LOGIC;
         LOAD           : in     STD_LOGIC;
         SEL            : in     STD_LOGIC_VECTOR(1 downto 0);
         FROM_IMMED     : in     STD_LOGIC_VECTOR(9 downto 0);
         FROM_STACK     : in     STD_LOGIC_VECTOR(9 downto 0);
         PC_COUNT       : out    STD_LOGIC_VECTOR(9 downto 0);
         PC_TRI         : inout  STD_LOGIC_VECTOR(9 downto 0));
end component;

component stack_pointer is
   Port( INC_DEC        : in  STD_LOGIC_VECTOR (1 downto 0);
         D_IN           : in  STD_LOGIC_VECTOR (7 downto 0);
         WE, RST, CLK   : in  STD_LOGIC;
         STK_PNTR       : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component scratch_pad is
   Port( FROM_IMMED     : in     STD_LOGIC_VECTOR(7 downto 0);
         FROM_SP        : in     STD_LOGIC_VECTOR(7 downto 0);
         FROM_RF        : in     STD_LOGIC_VECTOR(7 downto 0);
         FROM_SP_DEC    : in     STD_LOGIC_VECTOR(7 downto 0);
         SCR_ADDR_SEL   : in     STD_LOGIC_VECTOR(1 downto 0);
         SCR_WE, SCR_OE : in     STD_LOGIC;
         CLK            : in     STD_LOGIC;
         SP_DATA        : inout  STD_LOGIC_VECTOR(9 downto 0));
end component;

component alu 
   Port( SEL            : in  STD_LOGIC_VECTOR(3 downto 0);
         A, B_FROM_REG  : in  STD_LOGIC_VECTOR(7 downto 0);
         B_FROM_INSTR   : in  STD_LOGIC_VECTOR(7 downto 0);
         C_IN, MUX_SEL  : in  STD_LOGIC;
         SUM            : out STD_LOGIC_VECTOR(7 downto 0);
         C_FLAG, Z_FLAG : out STD_LOGIC);
end component;

component register_file 
   Port( FROM_IN_PORT   : in  STD_LOGIC_VECTOR(7 downto 0);
         FROM_TRI_STATE : in  STD_LOGIC_VECTOR(7 downto 0);
         FROM_ALU       : in  STD_LOGIC_VECTOR(7 downto 0);
         RF_MUX_SEL     : in  STD_LOGIC_VECTOR(1 downto 0);
         ADRX, ADRY     : in  STD_LOGIC_VECTOR(4 downto 0);
         WE, CLK, DX_OE : in  STD_LOGIC;
         DX_OUT, DY_OUT : out STD_LOGIC_VECTOR(7 downto 0));
end component;

component control_unit 
   Port( CLK, C, Z, INT, RST                 : in  STD_LOGIC;         
         OPCODE_HI_5                         : in  STD_LOGIC_VECTOR (4 downto 0); --From the instruction register
         OPCODE_LO_2                         : in  STD_LOGIC_VECTOR (1 downto 0);			  
         PC_LD,       PC_OE, SP_LD, RESET    : out STD_LOGIC; --Load PC EN // PC output enable // stack pointer load // Reset PC and SP
         PC_MUX_SEL,  INC_DEC                : out STD_LOGIC_VECTOR (1 downto 0); --PC mux sel// SP input mux sel
         ALU_MUX_SEL                         : out STD_LOGIC; --alu mux sel
         RF_WR,       RF_OE, SCR_WR, SCR_OE  : out STD_LOGIC; --RF Write EN // RF Tristate Output // SP write EN // SP output EN
         RF_WR_SEL,   SCR_ADDR_SEL           : out STD_LOGIC_VECTOR (1 downto 0); -- Reg File Mux // sp mux sel 
         ALU_SEL                             : out STD_LOGIC_VECTOR (3 downto 0);
         C_FLAG_SAVE, C_FLAG_RESTORE         : out STD_LOGIC;  -- C flag save and restore
         Z_FLAG_SAVE, Z_FLAG_RESTORE         : out STD_LOGIC;  -- Z flag save and restore
         C_FLAG_LD,   C_FLAG_SET, C_FLAG_CLR : out STD_LOGIC;  -- C flag set, clear, and load
         Z_FLAG_LD,   Z_FLAG_SET, Z_FLAG_CLR : out STD_LOGIC;  -- Z flag set, clear, and load
         I_FLAG_SET,  I_FLAG_CLR, IO_OE      : out STD_LOGIC); -- Set Interrupt // clear interrupt // I/O enable
end component;

   signal CU_RESET_i, I_COMB_i               : STD_LOGIC;
   signal C_IN_i, Z_IN_i, C_OUT_i, Z_OUT_i   : STD_LOGIC;
   signal C_LD_i, Z_LD_i, C_SET_i, Z_SET_i   : STD_LOGIC;
   signal C_CLR_i, Z_CLR_i, I_SET_i, I_CLR_i : STD_LOGIC;
   signal PC_LD_i, PC_OE_i, RF_OE_i, RF_WR_i : STD_LOGIC;
   signal ALU_MUX_SEL_i, I_OUT_i, SP_LD_i    : STD_LOGIC;
   signal SCR_WR_i, SCR_OE_i, Z_SAVE_i       : STD_LOGIC; 
   signal C_RESTORE_i, Z_RESTORE_i, C_SAVE_i : STD_LOGIC; 
   signal INC_DEC_i, RF_WR_SEL_i             : STD_LOGIC_VECTOR(1 downto 0);
   signal SCR_ADDR_SEL_i, PC_MUX_SEL_i       : STD_LOGIC_VECTOR(1 downto 0); 
   signal ALU_SEL_i                          : STD_LOGIC_VECTOR(3 downto 0);
   signal ALU_OUT_i, ADRY_OUT_i              : STD_LOGIC_VECTOR(7 downto 0);
   signal STK_PNTR_OUT_i                     : STD_LOGIC_VECTOR(7 downto 0);
   signal TRISTATE_BUS_i, PC_COUNT_i         : STD_LOGIC_VECTOR(9 downto 0);
   signal INSTRUCTION_i                      : STD_LOGIC_VECTOR(17 downto 0);
   
begin

out_port <= tristate_bus_i(7 downto 0);
port_id <= instruction_i(7 downto 0);
i_comb_i <= int_in and i_out_i;

prog_rom1 : prog_rom port map(
   address => pc_count_i,
   instruction => instruction_i,
   tristate_in => tristate_bus_i(7 downto 0),
   clk => clk);

c_flag : flag_reg port map(
   in_flag => c_in_i,
   ld => c_ld_i,
   set => c_set_i,
   clr => c_clr_i,
   clk => clk,
   restore => c_restore_i,
   save => c_save_i,
   out_flag => c_out_i);

z_flag : flag_reg port map(
   in_flag => z_in_i,
   ld => z_ld_i,
   set => z_set_i,
   clr => z_clr_i,
   clk => clk,
   restore => z_restore_i,
   save => z_save_i,
   out_flag => z_out_i);
	
i_flag : flag_reg port map( 
   in_flag => '0',
   ld => '0',
   set => i_set_i,
   clr => i_clr_i,
   clk => clk,
   restore => '0',
   save => '0',
   out_flag => i_out_i); 
   
program_counter1 : program_counter port map(
   clk => clk,
   rst => cu_reset_i,
   load => pc_ld_i,
   oe => pc_oe_i,
   sel => pc_mux_sel_i, 
   from_immed => instruction_i(12 downto 3),
   from_stack => tristate_bus_i,
   pc_count => pc_count_i,
   pc_tri => tristate_bus_i);

stack_pointer1 : stack_pointer port map(
   inc_dec =>  inc_dec_i,      
   d_in => tristate_bus_i(7 downto 0),       
   we => sp_ld_i,
   rst => cu_reset_i,
   clk => clk,
   stk_pntr => stk_pntr_out_i);
   
scratch_pad1: scratch_pad port map(
   clk => clk,
   scr_we => scr_wr_i,
   scr_oe => scr_oe_i,
   scr_addr_sel => scr_addr_sel_i,
   from_immed => instruction_i(7 downto 0),
   from_sp => stk_pntr_out_i,
   from_sp_dec => stk_pntr_out_i, --This is correct, deincrement is done INTERNALLY
   from_rf => adry_out_i,
   sp_data => tristate_bus_i);

alu1 : alu port map(
   sel => alu_sel_i,
   a => tristate_bus_i(7 downto 0),
   b_from_reg => adry_out_i,
   b_from_instr => instruction_i(7 downto 0),
   c_in => c_out_i,
   mux_sel => alu_mux_sel_i,
   sum => alu_out_i,
   c_flag => c_in_i,
   z_flag => z_in_i);
   
register_file1 : register_file port map( 
   from_in_port => in_port,
   from_tri_state => tristate_bus_i(7 downto 0),
   from_alu => alu_out_i,
   rf_mux_sel => rf_wr_sel_i,
   adrx => instruction_i(12 downto 8),
   adry => instruction_i(7 downto 3),
   we => rf_wr_i,
   clk => clk,
   dx_oe => rf_oe_i,
   dx_out => tristate_bus_i(7 downto 0),
   dy_out => adry_out_i);
   
control_unit1 : control_unit port map( 
   clk => clk,
   c => c_out_i,
   z => z_out_i,
   int => i_comb_i,  
   rst => rst,
   opcode_hi_5 => instruction_i(17 downto 13), 
   opcode_lo_2 => instruction_i(1 downto 0), 
   reset => cu_reset_i,
   pc_ld => pc_ld_i,
   pc_oe => pc_oe_i,
   pc_mux_sel => pc_mux_sel_i,
   sp_ld => sp_ld_i, 
   inc_dec => inc_dec_i, 
   rf_wr => rf_wr_i,
   rf_oe => rf_oe_i,
   rf_wr_sel => rf_wr_sel_i,
   scr_wr => scr_wr_i,
   scr_oe => scr_oe_i, 
   scr_addr_sel => scr_addr_sel_i,
   alu_mux_sel => alu_mux_sel_i,
   alu_sel => alu_sel_i,
   c_flag_restore => c_restore_i,
   c_flag_save => c_save_i,
   c_flag_ld => c_ld_i,
   c_flag_set => c_set_i,
   c_flag_clr => c_clr_i,
   z_flag_restore => z_restore_i,
   z_flag_save => z_save_i,
   z_flag_ld => z_ld_i,
   z_flag_set => z_set_i,
   z_flag_clr => z_clr_i,
   i_flag_set => i_set_i, 
   i_flag_clr => i_clr_i,
   io_oe => io_oe);

end rat_cpu_a;