interface slv_if(input clk, input rst_n );

   logic  [ 1:0]    cs_n;
   logic  [ 1:0]    ba;
   logic  [11:0]    sa;
   logic            cke;
   logic            ras_n;
   logic            cas_n;
   logic            we_n ;
   logic  [3:0]     dqm;
   logic  [31:0]    dq;

clocking mon_cb @(posedge clk );
     default input #1 output #1;
     input   cs_n;
     input   ba;
     input   sa;
     input   cke;
     input   ras_n;
     input   cas_n;
     input   we_n ;
     input   dqm;
     input   dq;
   endclocking

modport slv_monitor( clocking mon_cb);



endinterface
