----------------------------------------------------------------------------------
-- Company: CPE 233
-- Engineer: Jacob Hladky and Curtis Jonaitis
-- -------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity control_unit is
   port( CLK           : in   STD_LOGIC;
         C             : in   STD_LOGIC;
         Z             : in   STD_LOGIC;
         INT           : in   STD_LOGIC;
         RST           : in   STD_LOGIC;
           --From the instruction register:
         OPCODE_HI_5   : in   STD_LOGIC_VECTOR (4 downto 0);
         OPCODE_LO_2   : in   STD_LOGIC_VECTOR (1 downto 0);
			  
         --Program counter
         PC_LD         : out  STD_LOGIC; --Load program counter
         PC_MUX_SEL    : out  STD_LOGIC_VECTOR (1 downto 0); --Program counter mux
         PC_OE         : out  STD_LOGIC; --Program counter output enable

         --Stack Pointer 
         SP_LD         : out  STD_LOGIC; --stack pointer load
         INC_DEC       : out  STD_LOGIC_VECTOR (1 downto 0); --SP input mux

         --Reset to program counter and stack pointer
         RESET         : out  STD_LOGIC; --Reset program counter and stack pointer

         --Register File
         RF_WR         : out  STD_LOGIC; --Reg File Write Enable
         RF_WR_SEL     : out  STD_LOGIC_VECTOR (1 downto 0); --Reg File Mux
         RF_OE         : out  STD_LOGIC; --Register File Tristate Ooutput

         --ALU
         ALU_MUX_SEL   : out  STD_LOGIC;
         ALU_SEL       : out  STD_LOGIC_VECTOR (3 downto 0);

         --Scratchpad RAM
         SCR_WR        : out  STD_LOGIC; --scratchpad write enable
         SCR_OE        : out  STD_LOGIC; --sp output enable
         SCR_ADDR_SEL  : out  STD_LOGIC_VECTOR (1 downto 0); --sp mux sel

         --C Flag
         C_FLAG_RESTORE: out  STD_LOGIC;
         C_FLAG_SAVE   : out  STD_LOGIC;
         C_FLAG_LD     : out  STD_LOGIC;
         C_FLAG_SET    : out  STD_LOGIC;
         C_FLAG_CLR    : out  STD_LOGIC;

         --Z Flag
         Z_FLAG_RESTORE: out  STD_LOGIC;
         Z_FLAG_SAVE   : out  STD_LOGIC;
         Z_FLAG_LD     : out  STD_LOGIC; --Load Z
         Z_FLAG_SET    : out  STD_LOGIC; --Set Z
         Z_FLAG_CLR    : out  STD_LOGIC; --Clear Z

         --Interrupt Flag 
         I_FLAG_SET    : out  STD_LOGIC; --Set Interrupt
         I_FLAG_CLR    : out  STD_LOGIC; --Clear Interrupt

         --I/O Output Enable
         IO_OE  : out  STD_LOGIC);
end control_unit;

architecture control_unit_a of control_unit is
   type state_type is (ST_init, ST_fet, ST_exec, ST_int);
   signal PS,NS : state_type;
   
   signal int_ast_i : std_logic := '0';
   signal int_set_i : std_logic := '0';
   signal int_clr_i : std_logic := '0';

begin

   --synchronous process of statemachine
   --intializes present state to ST_init
   --on clock edge, PS updates to NS
   sync_p: process (CLK, RST) begin
      if (RST = '1') then
         PS <= ST_init;
      elsif (rising_edge(CLK)) then 
         PS <= NS;
         if(int_set_i = '1') then
            int_ast_i <= '1';
         elsif(int_clr_i = '1') then
            int_ast_i <= '0';
         end if;
      end if;
   end process sync_p;
   
   -- asynchronous process to determine NS and set all output signals
   comb_p: process (opcode_hi_5, opcode_lo_2, PS, NS, z, c, int, int_set_i, int_clr_i, int_ast_i) begin
      int_set_i <= '0';
      int_clr_i <= '0';
      case PS is
      -- STATE: the init cycle ------------------------------------
      -- Initialize all control outputs to non-active states and reset the PC and SP to all zeros.
      when ST_init => 
         NS <= ST_fet;
         int_clr_i <= '1';
         RESET          <= '1';
         PC_LD          <= '0';  PC_MUX_SEL  <= "00";    PC_OE          <= '0';  				
         SP_LD          <= '0';  INC_DEC     <= "00";   
         RF_WR          <= '0';  RF_WR_SEL   <= "00";    RF_OE          <= '0';  
         ALU_MUX_SEL    <= '0';  ALU_SEL     <= "0000";      
         SCR_WR         <= '0';  SCR_OE      <= '0';     SCR_ADDR_SEL   <= "00";    C_FLAG_SAVE <= '0'; 					
         C_FLAG_RESTORE <= '0';  C_FLAG_LD   <= '0';     C_FLAG_SET     <= '0';     C_FLAG_CLR  <= '1';   
         Z_FLAG_RESTORE <= '0';  Z_FLAG_LD   <= '0';     Z_FLAG_SET     <= '0';     Z_FLAG_CLR  <= '1';    
         I_FLAG_SET     <= '0';  I_FLAG_CLR  <= '1';     Z_FLAG_SAVE    <= '0';     IO_OE       <= '0';   		 	
				
      -- STATE: the fetch cycle -----------------------------------
      -- Set all control outputs to the values needed for fetch
      when ST_fet => 
         NS <= ST_exec;
         if(INT = '1') then
            int_set_i <= '1';
         end if;
         RESET          <= '0';
         PC_LD          <= '1';  PC_MUX_SEL  <= "00";    PC_OE          <= '0';  				
         SP_LD          <= '0';  INC_DEC     <= "00";   
         RF_WR          <= '0';  RF_WR_SEL   <= "00";    RF_OE          <= '0';  
         ALU_MUX_SEL    <= '0';  ALU_SEL     <= "0000";      
         SCR_WR         <= '0';  SCR_OE      <= '0';     SCR_ADDR_SEL   <= "00";    C_FLAG_SAVE <= '0'; 					
         C_FLAG_RESTORE <= '0';  C_FLAG_LD   <= '0';     C_FLAG_SET     <= '0';     C_FLAG_CLR  <= '0';   
         Z_FLAG_RESTORE <= '0';  Z_FLAG_LD   <= '0';     Z_FLAG_SET     <= '0';     Z_FLAG_CLR  <= '0';    
         I_FLAG_SET     <= '0';  I_FLAG_CLR  <= '0';     Z_FLAG_SAVE    <= '0';     IO_OE       <= '0';                   

      -- STATE: the execute cycle ---------------------------------
      when ST_exec => 
         if(INT = '1' or int_ast_i = '1') then
            NS <= ST_int;
            int_clr_i <= '1';
         else 
            NS <= ST_fet;	
         end if;
         
         -- Repeat the init block for all variables here, noting that any output values desired to be different
         -- from init values shown below will be assigned in the following case statements for each opcode.
         RESET          <= '0';
         PC_LD          <= '0';  PC_MUX_SEL  <= "00";    PC_OE          <= '0';  				
         SP_LD          <= '0';  INC_DEC     <= "00";   
         RF_WR          <= '0';  RF_WR_SEL   <= "00";    RF_OE          <= '0';  
         ALU_MUX_SEL    <= '0';  ALU_SEL     <= "0000";      
         SCR_WR         <= '0';  SCR_OE      <= '0';     SCR_ADDR_SEL   <= "00";    C_FLAG_SAVE <= '0'; 					
         C_FLAG_RESTORE <= '0';  C_FLAG_LD   <= '0';     C_FLAG_SET     <= '0';     C_FLAG_CLR  <= '0';   
         Z_FLAG_RESTORE <= '0';  Z_FLAG_LD   <= '0';     Z_FLAG_SET     <= '0';     Z_FLAG_CLR  <= '0';    
         I_FLAG_SET     <= '0';  I_FLAG_CLR  <= '0';     Z_FLAG_SAVE    <= '0';     IO_OE       <= '0';    		 	

         case OPCODE_HI_5 is	
            -- Could be AND, OR, EXOR, or TEST
            when "00000" =>
               -- AND (reg/reg)
               if(OPCODE_LO_2 = "00") then
                  ALU_SEL <= x"5";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
               
               -- OR (reg/reg)
               elsif(OPCODE_LO_2 = "01") then
                  ALU_SEL <= x"a";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
               
               -- EXOR (reg/reg)
               elsif(OPCODE_LO_2 = "10") then
                  ALU_SEL <= x"7";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
               
               -- TEST (reg/reg)
               else 
                  ALU_SEL <= x"d";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                         
               end if;
               
            -- Could be ADD, ADDC, SUB, or SUBC
            when "00001" =>                 
               -- ADD (reg/reg)
               if(OPCODE_LO_2 = "00") then
                  ALU_SEL <= x"0";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                  C_FLAG_LD <= '1';
               
               -- ADDC (reg/reg)
               elsif(OPCODE_LO_2 = "01") then
                  ALU_SEL <= x"1";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                  C_FLAG_LD <= '1';
               
               -- SUB (reg/reg)
               elsif(OPCODE_LO_2 = "10") then
                  ALU_SEL <= x"3";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                  C_FLAG_LD <= '1';
               
               -- SUBC (reg/reg)
               else
                  ALU_SEL <= x"4";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                  C_FLAG_LD <= '1';
                         
               end if;
                              
            -- Could be CMP, MOV, LD, or ST (all reg/reg)
            when "00010" =>
               -- CMP (reg/reg)
               if(OPCODE_LO_2 = "00") then
                  ALU_SEL <= x"2";     Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_OE <= '1';     --RF_WR <= '1'; --do NOT write back to REG!!!!!!
                  C_FLAG_LD <= '1';
               
               -- MOV (reg/reg)
               elsif(OPCODE_LO_2 = "01") then
                  ALU_SEL <= x"e";     
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
               
               -- LD (reg/reg)
               elsif(OPCODE_LO_2 = "10") then
                  SCR_ADDR_SEL <= "11";   SCR_OE <= '1'; RF_WR <= '1';
                  RF_WR_SEL <= "01";  
                  
               -- ST (reg/reg)
               else
                  SCR_ADDR_SEL <= "11";   SCR_WR <= '1'; RF_OE <= '1';                 
               end if;
            
            -- Could be BRN, CALL, BREQ, or BRNE 
            when "00100" =>  
               -- BRN (no other form)
               -- Unditional branch. Add only the signals that will change FROM THE INIT BLOCK
               if(OPCODE_LO_2 = "00") then
                  PC_MUX_SEL <= "01";  PC_LD <= '1';
                      
               -- CALL (no other form)
               -- Call a function
               elsif(OPCODE_LO_2 = "01") then
               PC_MUX_SEL <= "01";  PC_OE <= '1';  SCR_WR <= '1';
               SCR_ADDR_SEL <= "10";   INC_DEC <= "01";  PC_LD <= '1';
               
               -- BREQ (no other form)
               -- Branch if zero set
               elsif(OPCODE_LO_2 = "10") then
                  if(z = '1') then
                     PC_MUX_SEL <= "01";
                     PC_LD <= '1';
                  end if;
               
               -- BRNE (no other form)
               -- Branch if zero cleared
               else 
                  if(z = '0') then
                     PC_MUX_SEL <= "01";
                     PC_LD <= '1';
                  end if;       
               end if;
            
            -- Could be BRCS or BRCC
            when "00101" =>
               -- BRCS (no other form)
               -- Branch if carry set
               if(OPCODE_LO_2 = "00") then
                  if(c = '1') then
                     PC_MUX_SEL <= "01";
                     PC_LD <= '1';
                  end if;
                  
               -- BRCC (no other form)
               -- Branch if carry cleared
               else
                  if(c = '0') then
                     PC_MUX_SEL <= "01";
                     PC_LD <= '1';
                  end if;
               end if;
            
            -- Could be LSL, LSR, ROL, or ROR
            when "01000" =>
               -- LSL (no other form)
               if(OPCODE_LO_2 = "00") then
                  ALU_SEL <= x"8";     C_FLAG_LD <= '1'; Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                  
               -- LSR (no other form)
               elsif(OPCODE_LO_2 = "01") then
                  ALU_SEL <= x"9";     C_FLAG_LD <= '1'; Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                  
               -- ROL (no other form)
               elsif(OPCODE_LO_2 = "10") then
                  ALU_SEL <= x"b";     C_FLAG_LD <= '1'; Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                             
               -- ROR (no other form)
               else
                  ALU_SEL <= x"c";     C_FLAG_LD <= '1'; Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';           
               end if;
            
            -- Could be ASR, PUSH, or POP
            when "01001" =>
               -- ASR (no other form)
               -- Arithmetic shift right
               if(OPCODE_LO_2 = "00") then
                  ALU_SEL <= x"6";     C_FLAG_LD <= '1'; Z_FLAG_LD <= '1';
                  RF_WR_SEL <= "10";   RF_WR <= '1';     RF_OE <= '1';
                  
               -- PUSH (no other form)
               -- Push a value onto the stack
               elsif(OPCODE_LO_2 = "01") then
                  RF_OE <= '1';     SCR_ADDR_SEL <= "10"; SCR_WR <= '1';
                  INC_DEC <= "01";  
                  
               -- POP (no other form)
               -- Pop a value from the stack
               elsif(OPCODE_LO_2 = "10") then
                  SCR_OE <= '1';    RF_WR <= '1';  RF_WR_SEL <= "01";
                  INC_DEC <= "10";  SCR_ADDR_SEL <= "01";
               
               end if;
                       
            -- Could be CLC, SEC, RET, or RETI
            when "01100" =>
               -- CLC (no other form)
               -- Clear the carry flag
               if(OPCODE_LO_2 = "00") then
                  C_FLAG_CLR <= '1';
                  
               -- SEC (no other form)
               -- Set the carry flag
               elsif(OPCODE_LO_2 = "01") then
                  C_FLAG_SET <= '1';
                  
               -- RET (no other form)
               -- Return from a function
               elsif(OPCODE_LO_2 = "10") then
                  SCR_OE <= '1';    PC_MUX_SEL <= "10";  PC_LD <= '1';
                  INC_DEC <= "10";  SCR_ADDR_SEL <= "01";
               
               -- RETI (no other form)
               else 
                  -- unclear if this is actually a command being used
               end if;
             
            -- Could be SEI, CLI, RETID, or RETIE
            when "01101" =>
               -- SEI (no other form)
               -- Set the interrupt flag
               if(OPCODE_LO_2 = "00") then
                  I_FLAG_SET <= '1';
               
               -- CLI (no other form)
               -- Clear the interrupt clag
               elsif(OPCODE_LO_2 = "01") then
                  I_FLAG_CLR <= '1'; 
                  
               -- RETID (no other form)
               -- Return with interrupts disabled
               elsif(OPCODE_LO_2 = "10") then
                  SCR_OE <= '1';    PC_MUX_SEL <= "10";     PC_LD <= '1';
                  INC_DEC <= "10";  SCR_ADDR_SEL <= "01";   I_FLAG_CLR <= '1';
                  C_FLAG_RESTORE <= '1';  Z_FLAG_RESTORE <= '1';
                  
               -- RETIE (no other form)
               -- Return with interrupts enabled
               else
                  SCR_OE <= '1';    PC_MUX_SEL <= "10";     PC_LD <= '1';
                  INC_DEC <= "10";  SCR_ADDR_SEL <= "01";   I_FLAG_SET <= '1';
                  C_FLAG_RESTORE <= '1';  Z_FLAG_RESTORE <= '1';   
               end if; 
               
            -- AND (reg/immed)
            when "10000" =>
               ALU_SEL <= x"5";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
            
            -- OR (reg/immed)
            when "10001" =>
               ALU_SEL <= x"a";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
            
            -- EXOR (reg/immed)
            when "10010" =>
               ALU_SEL <= x"7";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
            
            -- TEST (reg/immed)
            when "10011" =>
               ALU_SEL <= x"d";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
            
            -- ADD (reg/immed)
            when "10100" =>
               ALU_SEL <= x"0";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
               C_FLAG_LD <= '1';
            
            -- ADDC (reg/immed)
            when "10101" =>
               ALU_SEL <= x"1";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
               C_FLAG_LD <= '1';
            
            -- SUB (reg/immed)
            when "10110" =>
               ALU_SEL <= x"3";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
               C_FLAG_LD <= '1';
            
            -- SUBC (reg/immed)
            when "10111" =>
               ALU_SEL <= x"4";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_WR <= '1';        RF_OE <= '1';
               C_FLAG_LD <= '1';
            
            -- CMP (reg/immed)
            when "11000" =>
               ALU_SEL <= x"2";     ALU_MUX_SEL <= '1';  Z_FLAG_LD <= '1';
               RF_WR_SEL <= "10";   RF_OE <= '1';       -- RF_WR<= '1'; DO NOT WRITE BACK TO REG!!!
               C_FLAG_LD <= '1';
            
            -- IN (no other form)
            when "11001" =>
               RF_WR <= '1';  
             
            -- OUT (no other form)
            when "11010" =>
               RF_OE <= '1';  IO_OE <= '1';  
  
            -- MOV (reg/immed)
            when "11011" =>
               RF_WR <= '1';        RF_WR_SEL <= "10";   RF_OE <= '1';
               ALU_MUX_SEL <= '1';  ALU_SEL <= x"e";
        
            -- LD (reg/immed)
            when "11100" =>
               SCR_ADDR_SEL <= "00";   SCR_OE <= '1'; RF_WR <= '1';
               RF_WR_SEL <= "01";
            
            -- ST (reg/immed)
            when "11101" =>
               SCR_ADDR_SEL <= "00";   SCR_WR <= '1'; RF_OE <= '1';
               
        
            -- WSP (no other form)
            when "01010" =>
               RF_OE <= '1';  SP_LD <= '1';  
            
            when others =>		
               -- repeat the init block here to avoid incompletely specified outputs and hence avoid
               -- the problem of inadvertently created latches within the synthesized system.						
               RESET          <= '0';
               PC_LD          <= '0';  PC_MUX_SEL  <= "00";    PC_OE          <= '0';  				
               SP_LD          <= '0';  INC_DEC     <= "00";   
               RF_WR          <= '0';  RF_WR_SEL   <= "00";    RF_OE          <= '0';  
               ALU_MUX_SEL    <= '0';  ALU_SEL     <= "0000";      
               SCR_WR         <= '0';  SCR_OE      <= '0';     SCR_ADDR_SEL   <= "00";    C_FLAG_SAVE <= '0'; 					
               C_FLAG_RESTORE <= '0';  C_FLAG_LD   <= '0';     C_FLAG_SET     <= '0';     C_FLAG_CLR  <= '0';   
               Z_FLAG_RESTORE <= '0';  Z_FLAG_LD   <= '0';     Z_FLAG_SET     <= '0';     Z_FLAG_CLR  <= '0';    
               I_FLAG_SET     <= '0';  I_FLAG_CLR  <= '0';     Z_FLAG_SAVE    <= '0';     IO_OE       <= '0';    		 	
         end case;
      -- STATE: the interrupt cycle -----------------------------------
      -- Do interrupt shit here @ the 3FF, yo
      when ST_int =>
         NS <= ST_fet;
         RESET          <= '0';
         PC_LD          <= '1';  PC_MUX_SEL  <= "11";    PC_OE          <= '1';                          -- ok				
         SP_LD          <= '0';  INC_DEC     <= "01";                                                    -- ok
         RF_WR          <= '0';  RF_WR_SEL   <= "00";    RF_OE          <= '0';                          -- ok
         ALU_MUX_SEL    <= '0';  ALU_SEL     <= "0000";                                                  -- ok
         SCR_WR         <= '1';  SCR_OE      <= '0';     SCR_ADDR_SEL   <= "10";    C_FLAG_SAVE <= '1';  -- ok				
         C_FLAG_RESTORE <= '0';  C_FLAG_LD   <= '0';     C_FLAG_SET     <= '0';     C_FLAG_CLR  <= '0';  -- ok
         Z_FLAG_RESTORE <= '0';  Z_FLAG_LD   <= '0';     Z_FLAG_SET     <= '0';     Z_FLAG_CLR  <= '0';  -- ok  
         I_FLAG_SET     <= '0';  I_FLAG_CLR  <= '0';     Z_FLAG_SAVE    <= '1';     IO_OE       <= '0';  -- ok
      when others => 
         NS <= ST_fet;    
         -- repeat the init block here to avoid incompletely specified outputs and hence avoid
         -- the problem of inadvertently created latches within the synthesized system.
         RESET          <= '0';
         PC_LD          <= '0';  PC_MUX_SEL  <= "00";    PC_OE          <= '0';  				
         SP_LD          <= '0';  INC_DEC     <= "00";   
         RF_WR          <= '0';  RF_WR_SEL   <= "00";    RF_OE          <= '0';  
         ALU_MUX_SEL    <= '0';  ALU_SEL     <= "0000";      
         SCR_WR         <= '0';  SCR_OE      <= '0';     SCR_ADDR_SEL   <= "00";    C_FLAG_SAVE <= '0'; 					
         C_FLAG_RESTORE <= '0';  C_FLAG_LD   <= '0';     C_FLAG_SET     <= '0';     C_FLAG_CLR  <= '0';   
         Z_FLAG_RESTORE <= '0';  Z_FLAG_LD   <= '0';     Z_FLAG_SET     <= '0';     Z_FLAG_CLR  <= '0';    
         I_FLAG_SET     <= '0';  I_FLAG_CLR  <= '0';     Z_FLAG_SAVE    <= '0';     IO_OE       <= '0';    		 	
      end case;
   end process comb_p;
end control_unit_a;
