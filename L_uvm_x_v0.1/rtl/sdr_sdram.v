/******************************************************************************
*
*  LOGIC CORE:          SDR SDRAM Controller			
*  MODULE NAME:         sdr_sdram()
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
*  This module is the top level module for the SDR SDRAM controller.
*
*  Copyright Northwest Logic, Inc., 2000.  All rights reserved.  
******************************************************************************/
module sdr_sdram(
        CLK,
        RESET_N,
        ADDR,
        CMD,
        CMDACK,
        DATAIN,
        DATAOUT,
        DM,
        SA,
        BA,
        CS_N,
        CKE,
        RAS_N,
        CAS_N,
        WE_N,
        DQ,
        DQM
        );


`include        "params.v"

input                           CLK;                    //System Clock
input                           RESET_N;                //System Reset
input   [`ASIZE-1:0]            ADDR;                   //Address for controller requests
input   [2:0]                   CMD;                    //Controller command 
output                          CMDACK;                 //Controller command acknowledgement
input   [`DSIZE-1:0]            DATAIN;                 //Data input
output  [`DSIZE-1:0]            DATAOUT;                //Data output
input   [`DSIZE/8-1:0]          DM;                     //Data mask input
output  [11:0]                  SA;                     //SDRAM address output
output  [1:0]                   BA;                     //SDRAM bank address
output  [1:0]                   CS_N;                   //SDRAM Chip Selects
output                          CKE;                    //SDRAM clock enable
output                          RAS_N;                  //SDRAM Row address Strobe
output                          CAS_N;                  //SDRAM Column address Strobe
output                          WE_N;                   //SDRAM write enable
inout   [`DSIZE-1:0]            DQ;                     //SDRAM data bus
output  [`DSIZE/8-1:0]          DQM;                    //SDRAM data mask lines

reg     [11:0]                  SA;                     //SDRAM address output
reg     [1:0]                   BA;                     //SDRAM bank address
reg     [1:0]                   CS_N;                   //SDRAM Chip Selects
reg                             CKE;                    //SDRAM clock enable
reg                             RAS_N;                  //SDRAM Row address Strobe
reg                             CAS_N;                  //SDRAM Column address Strobe
reg                             WE_N;                   //SDRAM write enable

reg     [`DSIZE-1:0]            DQIN;
wire    [`DSIZE-1:0]            DQOUT;
wire    [`DSIZE-1:0]            IDATAOUT;                //Data output
reg     [`DSIZE-1:0]            DATAOUT;                 //Data output

wire    [11:0]                  ISA;                     //SDRAM address output
wire    [1:0]                   IBA;                     //SDRAM bank address
wire    [1:0]                   ICS_N;                   //SDRAM Chip Selects
wire                            ICKE;                    //SDRAM clock enable
wire                            IRAS_N;                  //SDRAM Row address Strobe
wire                            ICAS_N;                  //SDRAM Column address Strobe
wire                            IWE_N;                   //SDRAM write enable

wire    [`ASIZE-1:0]            saddr;
wire    [1:0]                   sc_cl;
wire    [1:0]                   sc_rc;
wire    [3:0]                   sc_rrd;
wire                            sc_pm;
wire    [3:0]                   sc_bl;
wire                            load_mode;
wire                            nop;
wire                            reada;
wire                            writea;
wire                            refresh;
wire                            precharge;
wire                            oe;

wire                            CLK133;
wire                            CLK133B;
wire			             CLK;



pll1 PLL1(
                .inclock(CLK),
                .clock0(CLK133),
                .clock1(CLK133B),
                .locked(locked)
                );



control_interface control1 (
                .CLK(CLK133),
                .RESET_N(RESET_N),
                .CMD(CMD),
                .ADDR(ADDR),
                .REF_ACK(ref_ack),
                .CM_ACK(cm_ack),
                .NOP(nop),
                .READA(reada),
                .WRITEA(writea),
                .REFRESH(refresh),
                .PRECHARGE(precharge),
                .LOAD_MODE(load_mode),
                .SADDR(saddr),
                .SC_CL(sc_cl),
                .SC_RC(sc_rc),
                .SC_RRD(sc_rrd),
                .SC_PM(sc_pm),
                .SC_BL(sc_bl),
                .REF_REQ(ref_req),
                .CMD_ACK(CMDACK)
                );

command command1(
                .CLK(CLK133),
                .RESET_N(RESET_N),
                .SADDR(saddr),
                .NOP(nop),
                .READA(reada),
                .WRITEA(writea),
                .REFRESH(refresh),
                .PRECHARGE(precharge),
                .LOAD_MODE(load_mode),
                .SC_CL(sc_cl),
                .SC_RC(sc_rc),
                .SC_RRD(sc_rrd),
                .SC_PM(sc_pm),
                .SC_BL(sc_bl),
                .REF_REQ(ref_req),
                .REF_ACK(ref_ack),
                .CM_ACK(cm_ack),
                .OE(oe),
                .SA(ISA),
                .BA(IBA),
                .CS_N(ICS_N),
                .CKE(ICKE),
                .RAS_N(IRAS_N),
                .CAS_N(ICAS_N),
                .WE_N(IWE_N)
                );
                
sdr_data_path data_path1(
                .CLK(CLK133),
                .RESET_N(RESET_N),
                .OE(oe),
                .DATAIN(DATAIN),
                .DM(DM),
                .DATAOUT(IDATAOUT),
                .DQIN(DQIN),
                .DQOUT(DQOUT),
                .DQM(DQM)
                );


always @(posedge CLK133)
begin
                SA      <= ISA;
                BA      <= IBA;
                CS_N    <= ICS_N;
                CKE     <= ICKE;
                RAS_N   <= IRAS_N;
                CAS_N   <= ICAS_N;
                WE_N    <= IWE_N;
                DQIN    <= DQ;
                DATAOUT <= IDATAOUT;
end

assign  DQ = oe ? DQOUT : 32'bz;                     

endmodule

