class my_test extends uvm_test;

  `uvm_component_utils(my_test) 

  mst_sequence mst_seq;
  env env0;

  extern function new(string name="my_test",uvm_component parent=null);
  extern task main_phase(uvm_phase phase);


endclass

function my_test::new(string name="my_test",uvm_component parent=null);
  super.new(name,parent);
  `uvm_info("testcase:","-------test_single_cmd_load_mode----------",UVM_LOW);
  env0   = new("env0",this);
  mst_seq = new("mst_seq");
endfunction

task my_test::main_phase(uvm_phase phase);
  super.main_phase(phase);
  
  phase.raise_objection(this); //must raise phase

  `uvm_info("my_test","-----------------gen transaction------------------",UVM_LOW);
  
  //LOAD_MODE command. CL=3, BL=2
 mst_seq.set_mode(1,`MODE_BURST,`CMD_LOAD_MODE,{11'h0,12'h031},256'h0,4'h0,10'd2,4'd8 ); //fix mode
 mst_seq.start(env0.mst_agent0.sqr);
  
 #1us;
 `uvm_info("my_test","-----------------finish------------------",UVM_LOW);
  phase.drop_objection(this);
 

endtask
