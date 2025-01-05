class mst_agent extends uvm_agent;
  mst_sequencer  sqr;
  mst_driver     drv;

  uvm_analysis_port #(transaction ) ap; // connect to reference

  extern function new( string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  
 `uvm_component_utils_begin( mst_agent )
    `uvm_field_object( sqr, UVM_ALL_ON )
    `uvm_field_object( drv, UVM_ALL_ON )
  `uvm_component_utils_end


endclass

function mst_agent::new(string name,uvm_component parent);
  super.new(name,parent);
endfunction

function void mst_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
  sqr = mst_sequencer::type_id::create("sqr",this);
  drv = mst_driver::type_id::create("drv",this);
endfunction

function void mst_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  drv.seq_item_port.connect(sqr.seq_item_export);
  this.ap = drv.ap;
  `uvm_info("mst_agent","connect ok",UVM_LOW);

endfunction

