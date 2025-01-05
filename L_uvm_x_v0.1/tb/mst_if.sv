
interface mst_if( input clk, input rst_n);
 //for io port
   logic  [ 2:0]    cmd;
   logic            cmdack;
   logic  [22:0]    addr; 
   logic  [ 3:0]    dm;
   logic  [31:0]    wdat;
   logic  [31:0]    rdat;
   //for debug 
   logic  [31:0]    id;

clocking drv_cb @(posedge clk );
     default input #1 output #1;
     output   cmd;
     input    cmdack;
     output   addr;
     output   dm;
     output   wdat;
     input    rdat;

   endclocking

modport mst_driver( clocking drv_cb);


endinterface

