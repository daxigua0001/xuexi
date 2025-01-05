/******************************************************************************
*
*  LOGIC CORE:          SDR Data Path Module			
*  MODULE NAME:         sdr_data_path()
*  COMPANY:             Northwest Logic, Inc.
*                       www.nwlogic.com
*
*  REVISION HISTORY:  
*
*    Revision 1.0  05/11/2000     Description: Initial Release.
*             1.1  07/10/2000     Description: change precharge to terminate
*                                              for full page accesses.
*  FUNCTIONAL DESCRIPTION:
*
*  This module is the data path module for the SDR SDRAM controller.
*
*  Copyright Northwest Logic, Inc., 2000.  All rights reserved.  
******************************************************************************/
module sdr_data_path(
        CLK,
        RESET_N,
        OE,
        DATAIN,
        DM,
        DATAOUT,
        DQIN,
        DQOUT,
        DQM
        );

`include        "params.v"

input                           CLK;                    // System Clock
input                           RESET_N;                // System Reset
input                           OE;                     // Data output(to the SDRAM) enable
input   [`DSIZE-1:0]            DATAIN;                 // Data input from the host
input   [`DSIZE/8-1:0]          DM;                     // byte data masks
output  [`DSIZE-1:0]            DATAOUT;                // Read data output to host
input   [`DSIZE-1:0]            DQIN;                   // SDRAM data bus
output  [`DSIZE-1:0]            DQOUT;
output  [`DSIZE/8-1:0]          DQM;                    // SDRAM data mask ouputs
//reg     [`DSIZE-1:0]            DATAOUT;
reg     [`DSIZE/8-1:0]          DQM;
            
// internal 
reg     [`DSIZE-1:0]            DIN1;
reg     [`DSIZE-1:0]            DIN2;

reg     [`DSIZE/8-1:0]          DM1;


reg     [`DSIZE-1:0]            DOUT1;
reg     [`DSIZE-1:0]            DOUT2;



// Allign the input and output data to the SDRAM control path
always @(posedge CLK or negedge RESET_N)
begin
        if (RESET_N == 0) 
        begin
                DIN1    <= 0;
                DIN2    <= 0;
                DM1     <= 0;
                DOUT1   <= 0;
                DOUT2   <= 0;
        end
        
        else
        begin
                DIN1      <= DATAIN;
                DIN2      <= DIN1;
                
                DM1       <= DM;
                DQM       <= DM1;

                
//                DOUT1     <= DQIN;
//                DATAOUT   <= DQIN;

                       
        end
end

//assign  DQ = OE ? DIN2 : 32'bz;                     
assign DQOUT = DIN2;
assign DATAOUT = DQIN;

endmodule

