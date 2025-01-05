class env extends uvm_env;
  `uvm_component_utils(env);
 
  mst_agent mst_agent0;
  slv_agent slv_agent0;
  scoreboard scb0;
  sdram_reference ref0;

extern function new(string name, uvm_component parent=null );
extern function void build_phase(uvm_phase phase);
extern function void connect_phase(uvm_phase phase);

endclass

function env::new(string name, uvm_component parent=null );
  super.new(name,parent);
endfunction

function void env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  mst_agent0 = mst_agent::type_id::create("mst_agent0",this);
  slv_agent0 = slv_agent::type_id::create("slv_agent0",this);
  scb0 = scoreboard::type_id::create("scb0",this);
  ref0 = sdram_reference::type_id::create("ref0",this);
endfunction

function void env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  mst_agent0.ap.connect(ref0.mst_drv_ch);
  slv_agent0.ap.connect(ref0.slv_mon_ch);
 
  ref0.mst_cmd_ch.connect(scb0.mst_cmd_ch);
  ref0.mst_ref_ch.connect(scb0.mst_ref_ch);
  ref0.slv_cmd_ch.connect(scb0.slv_cmd_ch);
  ref0.slv_ref_ch.connect(scb0.slv_ref_ch);


  `uvm_info(get_type_name(),"connect ok",UVM_LOW);
endfunction

