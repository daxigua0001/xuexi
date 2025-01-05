`uvm_analysis_imp_decl(_mst_ch)
`uvm_analysis_imp_decl(_slv_ch)
class sdram_reference extends uvm_component;
  `uvm_component_utils(sdram_reference);

  //master driver channel
  uvm_analysis_imp_mst_ch #(transaction,sdram_reference) mst_drv_ch;
  //slave monitor channel
  uvm_analysis_imp_slv_ch #(transaction,sdram_reference) slv_mon_ch;

  //ap to scoreboard
  uvm_analysis_port #(transaction) mst_ref_ch;
  uvm_analysis_port #(transaction) mst_cmd_ch;
  uvm_analysis_port #(transaction) slv_ref_ch;
  uvm_analysis_port #(transaction) slv_cmd_ch;

  //fifo 
  uvm_tlm_analysis_fifo #(transaction) mst_fifo;
  uvm_tlm_analysis_fifo #(transaction) slv_fifo;

  //transaction
  transaction mst_tr;
  transaction slv_tr;
  transaction mst_tr2;

  bit[15:0]  ref_counter;
  bit[15:0]  ref_counter_run;
  bit        ref_counter_ena;
  
  event      evt_gen_ref_inside;
  
  extern function new (string name,uvm_component parent);
  extern function void build_phase (uvm_phase phase);
  extern virtual task main_phase (uvm_phase phase);

  extern task process_mst_xact();
  extern task process_slv_xact();
  extern task process_counter();
  extern function void set_param(bit[15:0] counter);
  extern function void set_enable();
  extern function void set_disable();
 
 function write_mst_ch(transaction tr );
     mst_fifo.write(tr);
     $display("refernce:write mst ch one tr");
  endfunction

  function write_slv_ch(transaction tr );
     slv_fifo.write(tr);
     $display("refernce:write slv ch one tr");
  endfunction

endclass

function void sdram_reference::set_param(bit[15:0] counter);
  ref_counter = counter;
  ref_counter_run = counter;
endfunction

function void sdram_reference::set_enable();
  ref_counter_ena = 1;
endfunction

function void sdram_reference::set_disable();
  ref_counter_ena = 0;
endfunction

function sdram_reference::new(string name,uvm_component parent);
  super.new(name,parent);
endfunction

function void sdram_reference::build_phase(uvm_phase phase);
  super.build_phase(phase);
 
  mst_drv_ch = new("mst_drv_ch",this);
  slv_mon_ch = new("slv_mon_ch",this);

  mst_ref_ch = new("mst_ref_ch",this);
  mst_cmd_ch = new("mst_cmd_ch",this);
  slv_ref_ch = new("slv_ref_ch",this);
  slv_cmd_ch = new("slv_cmd_ch",this);

  mst_fifo   = new("mst_fifo",this);
  slv_fifo   = new("slv_fifo",this);
  
  ref_counter   = 1562;
  ref_counter_run = 1562;
  ref_counter_ena = 0;
endfunction

task sdram_reference::main_phase(uvm_phase phase);
  super.main_phase(phase);
  $display("----------sdram_reference main_phase---------");

  fork
     process_mst_xact();
     process_slv_xact();
     process_counter();
  join

endtask

task sdram_reference::process_mst_xact();
  while(1) begin
      mst_tr  = new();
      mst_fifo.get(mst_tr);
      if( mst_tr.cmd == `CMD_REFRESH ) begin
        mst_tr.timestamp = $time; 
        mst_tr.ref_flag = 0;
        mst_ref_ch.write( mst_tr );
      end
      else begin //other command write to soreboard directly
        mst_cmd_ch.write( mst_tr );
      end
  end
endtask

task sdram_reference::process_slv_xact();
  while(1) begin
    slv_tr  = new();
    slv_fifo.get(mst_tr);
    if( slv_tr.cmd == `CMD_REFRESH ) begin
      slv_tr.timestamp = $time; 
      slv_tr.ref_flag = 0;
      slv_ref_ch.write( mst_tr );
    end
    else begin
      slv_cmd_ch.write( mst_tr );
    end
  end
endtask

task sdram_reference::process_counter();
  while(1) begin
     //@(posedge simtop.clk);
     #100; 
     if( ref_counter_ena == 1 ) begin
        ref_counter_run--;
        if( ref_counter_run == 0 ) begin
            //->evt_gen_ref_inside;
            mst_tr2  = new();
            mst_tr2.cmd = `CMD_REFRESH; 
            mst_tr2.timestamp = $time; 
            mst_tr2.ref_flag = 0;
            mst_ref_ch.write( mst_tr2 );
            ref_counter_run = ref_counter;
        end
     end

  end
endtask


