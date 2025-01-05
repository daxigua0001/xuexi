
class mst_sequencer extends uvm_sequencer #(transaction);
  extern function new( string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
 
  `uvm_component_utils( mst_sequencer )



endclass

function mst_sequencer::new(string name,uvm_component parent);
  super.new(name,parent);
endfunction

function void mst_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction
