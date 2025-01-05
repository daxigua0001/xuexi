/******************************************************************************
*
*  LOGIC CORE:          Control Interface - Top level module			
*  MODULE NAME:         control_interface()
*  COMPANY:             Northwest Logic, Inc.
*                       www.nwlogic.com
*
*  REVISION HISTORY:  
*
*    Revision 1.0  05/11/2000     Description: Initial Release.
*             1.1  07/10/2000     Description: change precharge to terminate
*                                              for full page accesses.
*
*  FUNCTIONAL DESCRIPTION:
*
*  This module is the command interface module for the SDR SDRAM controller.
*
*  Copyright Northwest Logic, Inc., 2000.  All rights reserved.  
******************************************************************************/
module control_interface(
        CLK,
        RESET_N,
        CMD,
        ADDR,
        REF_ACK,
        CM_ACK,
        NOP,
        READA,
        WRITEA,
        REFRESH,
        PRECHARGE,
        LOAD_MODE,
        SADDR,
        SC_CL,
        SC_RC,
        SC_RRD,
        SC_PM,
        SC_BL,
        REF_REQ,
        CMD_ACK
        );

`include        "params.v"

input                           CLK;                    // System Clock
input                           RESET_N;                // System Reset
input   [2:0]                   CMD;                    // Command input
input   [`ASIZE-1:0]            ADDR;                   // Address
input                           REF_ACK;                // Refresh request acknowledge
input                           CM_ACK;                 // Command acknowledge
output                          NOP;                    // Decoded NOP command
output                          READA;                  // Decoded READA command
output                          WRITEA;                 // Decoded WRITEA command
output                          REFRESH;                // Decoded REFRESH command
output                          PRECHARGE;              // Decoded PRECHARGE command
output                          LOAD_MODE;              // Decoded LOAD_MODE command
output  [`ASIZE-1:0]            SADDR;                  // Registered version of ADDR
output  [1:0]                   SC_CL;                  // Programmed CAS latency
output  [1:0]                   SC_RC;                  // Programmed RC delay
output  [3:0]                   SC_RRD;                 // Programmed RRD delay
output                          SC_PM;                  // programmed Page Mode
output  [3:0]                   SC_BL;                  // Programmed burst length
output                          REF_REQ;                // Hidden refresh request
output                          CMD_ACK;                // Command acknowledge


            
reg                             NOP;
reg                             READA;
reg                             WRITEA;
reg                             REFRESH;
reg                             PRECHARGE;
reg                             LOAD_MODE;
reg     [`ASIZE-1:0]            SADDR;
reg     [1:0]                   SC_CL;
reg     [1:0]                   SC_RC;
reg     [3:0]                   SC_RRD;
reg     [3:0]                   SC_BL;
reg                             SC_PM;
reg                             REF_REQ;
reg                             CMD_ACK;

// Internal signals
reg                             LOAD_REG1;
reg                             LOAD_REG2;
reg     [15:0]                  REF_PER;
reg     [15:0]                  timer;
reg                             timer_zero;



// Command decode and ADDR register
always @(posedge CLK or negedge RESET_N)
begin
        if (RESET_N == 0) 
        begin
                NOP             <= 0;
                READA           <= 0;
                WRITEA          <= 0;
                REFRESH         <= 0;
                PRECHARGE       <= 0;
                LOAD_MODE       <= 0;
                SADDR           <= 0;
        end
        
        else
        begin
        
                SADDR <= ADDR;                                  // register the address to keep proper
                                                                // alignment with the command
                                                             
                if (CMD == 3'b000)                              // NOP command
                        NOP <= 1;
                else
                        NOP <= 0;
                        
                if (CMD == 3'b001)                              // READA command
                        READA <= 1;
                else
                        READA <= 0;
                 
                if (CMD == 3'b010)                              // WRITEA command
                        WRITEA <= 1;
                else
                        WRITEA <= 0;
                        
                if (CMD == 3'b011)                              // REFRESH command
                        REFRESH <= 1;
                else
                        REFRESH <= 0;
                        
                if (CMD == 3'b100)                              // PRECHARGE command
                        PRECHARGE <= 1;
                else
                        PRECHARGE <= 0;
                        
                if (CMD == 3'b101)                              // LOAD_MODE command
                        LOAD_MODE <= 1;
                else
                        LOAD_MODE <= 0;
                        
                if ((CMD == 3'b110) & (LOAD_REG1 == 0) & (CMD_ACK == 0))                              //LOAD_REG1 command
                        LOAD_REG1 <= 1;
                else   
                        LOAD_REG1 <= 0;
                
                if ((CMD == 3'b111) & (LOAD_REG2 == 0) & (CMD_ACK == 0))                              //LOAD_REG2 command
                        LOAD_REG2 <= 1;
                else
                        LOAD_REG2 <= 0;
                        
        end
end



// register configuration information if LOAD_REG1 or LOAD_REG2 is
// asserted.
always @(posedge CLK or negedge RESET_N)
begin

        if (RESET_N == 0)
        begin
                SC_CL   <= 0;
                SC_RC   <= 0;
                SC_RRD  <= 0;
                SC_PM   <= 0;
                SC_BL   <= 0;
                REF_PER <= 0;
        end
        
        else
        begin
                if (LOAD_REG1 == 1)
                begin
                        SC_CL   <= SADDR[1:0];                   // CAS Latency
                        SC_RC   <= SADDR[3:2];                   // RC delay
                        SC_RRD  <= SADDR[7:4];                   // RRD delay
                        SC_PM   <= SADDR[8];                     // Page Mode
                        SC_BL   <= SADDR[12:9];                  // Burst length
                end
                
                if (LOAD_REG2 == 1)
                        REF_PER <= SADDR[15:0];                  // REFRESH Period
                                                          
        end
end


//  Generate CMD_ACK
always @(posedge CLK or negedge RESET_N)
begin
        if (RESET_N == 0)
                CMD_ACK <= 0;
        else
                if (((CM_ACK == 1) | (LOAD_REG1 == 1) | (LOAD_REG2 == 1)) & (CMD_ACK == 0))
                        CMD_ACK <= 1;
                else
                        CMD_ACK <= 0;
end


 
// refresh timer


always @(posedge CLK or negedge RESET_N) begin
        if (RESET_N == 0) 
        begin
                timer           <= 0;
                timer_zero      <= 0;
                REF_REQ         <= 0;
        end
        
        else 
        begin
                if (timer_zero == 1)
                        timer <= REF_PER;
                else if (SC_BL != 0)
                        timer <= timer - 1;
                if ((timer==0) & (SC_BL != 0))
                begin
                        timer_zero <= 1;
                        REF_REQ    <= 1;
                end
                
                else 
                if (REF_ACK == 1)
                begin
                        timer_zero <= 0;
                        REF_REQ    <= 0;
                end
        end
end

endmodule

