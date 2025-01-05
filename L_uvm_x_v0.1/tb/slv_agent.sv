class slv_agent extends uvm_agent;

  slv_monitor     mon;

  uvm_analysis_port #(transaction ) ap; // connect to scoreboard
 
  extern function new( string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

  `uvm_component_utils_begin( slv_agent )
    `uvm_field_object( mon, UVM_ALL_ON )
  `uvm_component_utils_end


endclass

function slv_agent::new(string name,uvm_component parent);
  super.new(name,parent);
endfunction

function void slv_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
  mon = slv_monitor::type_id::create("mon",this);
endfunction

function void slv_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  this.ap = mon.ap;
  `uvm_info("slv_agent","connect ok",UVM_LOW);

endfunction

