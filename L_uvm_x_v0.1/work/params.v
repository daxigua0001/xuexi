/******************************************************************************
*
*  LOGIC CORE:          SDR SDRAM Controller - Global Constants			
*  MODULE NAME:         params()
*  COMPANY:             Northwest Logic, Inc.
*
*  REVISION HISTORY:  
*
*    Revision 1.0  03/24/2000
*    Description: Initial Release.
*
*
*  FUNCTIONAL DESCRIPTION:
*
*  This file defines a number of global constants used throughout
*  the SDR SDRAM Controller.
*
*
******************************************************************************/


// Address Space Parameters

`define ROWSTART        8           
`define ROWSIZE         12
`define COLSTART        0
`define COLSIZE         8
`define BANKSTART       20
`define BANKSIZE        2

// Address and Data Bus Sizes

`define  ASIZE           23      // total address width of the SDRAM
`define  DSIZE           32      // Width of data bus to SDRAMS

`define  ROW_RANGE       256       // one row has 256 address

//command for master side
`define  CMD_NOP         3'd0
`define  CMD_READ        3'd1
`define  CMD_WRITE       3'd2
`define  CMD_REFRESH     3'd3
`define  CMD_PRECHARGE   3'd4
`define  CMD_LOAD_MODE   3'd5
`define  CMD_LOAD_REG1   3'd6
`define  CMD_LOAD_REG2   3'd7

`define  MODE_BURST      1'b0
`define  MODE_PAGE       1'b1
//command for slave side
`define  SCMD_NOP        3'd7
`define  SCMD_ACTIVE     3'd3
`define  SCMD_READ       3'd5
`define  SCMD_WRITE      3'd4
`define  SCMD_TERMINATE  3'd6
`define  SCMD_PRECHARGE  3'd2
`define  SCMD_REFRESH    3'd1
`define  SCMD_LOAD_MODE  3'd0

`define  MEM_RANGE       8388608   //8M

