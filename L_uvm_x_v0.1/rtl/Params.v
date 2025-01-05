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

`define ROWSTART        9           
`define ROWSIZE         12
`define COLSTART        0
`define COLSIZE         9
`define BANKSTART       20
`define BANKSIZE        2

// Address and Data Bus Sizes

`define  ASIZE           23      // total address width of the SDRAM
`define  DSIZE           32      // Width of data bus to SDRAMS


