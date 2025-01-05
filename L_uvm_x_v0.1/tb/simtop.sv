`include "uvm_pkg.sv"

`timescale 1ps / 1ps

module simtop();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

logic clk,rst_n;  //reg

 initial begin
     clk = 0;
     rst_n = 0;
     #200ns;
     rst_n = 1;
  end

always #3750 clk = ~clk;

  mst_if mst_sigs0(clk,rst_n);
  slv_if slv_sigs0(clk,rst_n);


  wire    [11:0]                  sa;
  wire    [1:0]                   ba;
  wire    [1:0]                   cs_n;
  wire                            cke;
  wire                            ras_n;
  wire                            cas_n;
  wire                            we_n;
  wire    [`DSIZE-1:0]            dq;
  wire    [`DSIZE/8-1:0]          dqm;

  always@(*) begin
    slv_sigs0.cs_n = cs_n;
    slv_sigs0.ba   = ba  ;
    slv_sigs0.sa   = sa  ;
    slv_sigs0.cke  = cke ;
    slv_sigs0.ras_n= ras_n;
    slv_sigs0.cas_n= cas_n;
    slv_sigs0.we_n = we_n ;
    slv_sigs0.dqm  = dqm  ;
    slv_sigs0.dq   = dq   ;
  end


// SDR SDRAM controller
  sdr_sdram sdr_sdram1 (
                  .CLK              (clk              ),
                  .RESET_N          (rst_n            ),
                  .ADDR             (mst_sigs0.addr    ),
                  .CMD              (mst_sigs0.cmd     ),
                  .CMDACK           (mst_sigs0.cmdack  ),
                  .DATAIN           (mst_sigs0.wdat    ),
                  .DATAOUT          (mst_sigs0.rdat    ),
                  .DM               (mst_sigs0.dm      ),
                  .SA               (sa               ),
                  .BA               (ba               ),
                  .CS_N             (cs_n             ),
                  .CKE              (cke              ),
                  .RAS_N            (ras_n            ),
                  .CAS_N            (cas_n            ),
                  .WE_N             (we_n             ),
                  .DQ               (dq               ),
                  .DQM              (dqm              )
                  );


 // micron memory models
  mt48lc4m16a2 mem00      (.Dq                (dq[15:0]),
                          .Addr               (sa[11:0]),
                          .Ba                 (ba      ),
                          .Clk                (clk     ),
                          .Cke                (cke     ),
                          .Cs_n               (cs_n[0] ),
                          .Cas_n              (cas_n   ),
                          .Ras_n              (ras_n   ),
                          .We_n               (we_n    ),
                          .Dqm                (dqm[1:0]));


 mt48lc4m16a2 mem01      (.Dq                (dq[31:16]),
                          .Addr               (sa[11:0] ),
                          .Ba                 (ba       ),
                          .Clk                (clk      ),
                          .Cke                (cke      ),
                          .Cs_n               (cs_n[0]  ),
                          .Cas_n              (cas_n    ),
                          .Ras_n              (ras_n    ),
                          .We_n               (we_n     ),
                          .Dqm                (dqm[3:2]));
                          

 mt48lc4m16a2 mem10      (.Dq                (dq[15:0]),
                          .Addr               (sa[11:0]),
                          .Ba                 (ba      ),
                          .Clk                (clk     ),
                          .Cke                (cke     ),
                          .Cs_n               (cs_n[1] ),
                          .Cas_n              (cas_n   ),
                          .Ras_n              (ras_n   ),
                          .We_n               (we_n    ),
                          .Dqm                (dqm[1:0]));
  
mt48lc4m16a2 mem11      (.Dq                (dq[31:16]),
                          .Addr               (sa[11: 0]),
                          .Ba                 (ba       ),
                          .Clk                (clk      ),
                          .Cke                (cke      ),
                          .Cs_n               (cs_n[1]  ),
                          .Cas_n              (cas_n    ),
                          .Ras_n              (ras_n    ),
                          .We_n               (we_n     ),
                          .Dqm                (dqm[3:2]));


//23bit  =8M *32bit  = 256 Mbit
//mt48lc4m16a2:64 Mbit, 
//256/64 = 4 module

 initial begin
    uvm_config_db#(virtual mst_if)::set(null,"uvm_test_top.env0.mst_agent0.drv","mst_if",mst_sigs0);
    uvm_config_db#(virtual slv_if)::set(null,"uvm_test_top.env0.slv_agent0.mon","slv_if",slv_sigs0);

    run_test();//start uvm 
    #100;
  end

initial begin
   $fsdbDumpfile("simtop.fsdb");
   $fsdbDumpvars;
end


endmodule
