class mst_driver extends uvm_driver #( transaction) ;

  virtual mst_if vif; //connect to simtop/interface
  uvm_analysis_port #(transaction ) ap; // connect to scoreboard
  
  transaction req; // transaction 
  int rcd;   //active to read delay
  int cl;    //read cmd to read data
  bit page;  //page mode or burst mode;

 `uvm_component_utils( mst_driver )

  extern function new(string name,uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task configure_phase(uvm_phase phase);
  extern virtual task main_phase( uvm_phase phase);
  extern         task driver_bus();
  extern         task debug_info();
  extern         task wait_for_cmdack();
  extern         function void set_param_manual(int rcd1,int cl1,bit page1);
 


endclass

function mst_driver::new(string name,uvm_component parent);
  super.new(name,parent);
  rcd = 3;//default value
  cl  = 3;
  page = 0;
endfunction

//---if testcase do not use transaction to set param,also can use this function to set param----//
function void mst_driver::set_param_manual(int rcd1,int cl1,bit page1);
   rcd = rcd1;
   cl  = cl1 ;
   page= page1;
endfunction

function void mst_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  //get virutal interface
  if( !uvm_config_db #(virtual mst_if) :: get(this,"","mst_if",vif))
     `uvm_fatal("mst_driver","Error in gettting interface");

  ap = new("ap",this);
  
endfunction

task mst_driver::configure_phase( uvm_phase phase );
  super.configure_phase(phase);
  vif.drv_cb.cmd        <=  3'd0;  //if = , compile error
  vif.drv_cb.addr       <= 23'd0;
  vif.drv_cb.dm         <=  4'd0;
  vif.drv_cb.wdat       <= 32'd0;
endtask

task mst_driver::main_phase(uvm_phase phase);
  super.main_phase(phase);

  while(1) begin
    seq_item_port.get_next_item( req );
    `uvm_info("mst_driver",$sformatf("main phase get a xact,id=%d",req.id),UVM_LOW);
    driver_bus();
	debug_info();
	ap.write(req);
    seq_item_port.item_done();
  end

endtask

task mst_driver::debug_info();
  `uvm_info("mst_driver","send a transaction",UVM_LOW);
  `uvm_info("mst_driver",$sformatf("id=%d",req.id),UVM_LOW);
  `uvm_info("mst_driver",$sformatf("page=%b",page),UVM_LOW);
  `uvm_info("mst_driver",$sformatf("cmd=%3b",req.cmd),UVM_LOW);
  `uvm_info("mst_driver",$sformatf("addr=%h",req.addr),UVM_LOW);
  `uvm_info("mst_driver",$sformatf("wdat0=%h",req.wdat[0]),UVM_LOW);
  `uvm_info("mst_driver",$sformatf("wdat1=%h",req.wdat[1]),UVM_LOW);
  `uvm_info("mst_driver",$sformatf("wdat2=%h",req.wdat[2]),UVM_LOW);
  `uvm_info("mst_driver",$sformatf("wdat3=%h",req.wdat[3]),UVM_LOW);
endtask

task mst_driver::wait_for_cmdack();
  while(1) begin
    @vif.drv_cb;
	if( vif.drv_cb.cmdack == 1'b1 );
	  break;
  end
endtask

task mst_driver::driver_bus();
  int i;
  if( req.cmd == `CMD_LOAD_REG1 ) begin
    //1.refresh the delay parameter
     rcd  = req.addr[3:2];
     cl   = req.addr[1:0];
     page = req.addr[  8];
     //2.set to io port
     @vif.drv_cb;  //align to clock
     vif.drv_cb.cmd   <= req.cmd;
     vif.drv_cb.addr  <= req.addr;
     vif.drv_cb.wdat  <= 32'hx;
     vif.drv_cb.dm    <= 4'hx;
     wait_for_cmdack();
     vif.drv_cb.cmd   <= `CMD_NOP;
  end
  else if( req.cmd == `CMD_LOAD_REG2 || req.cmd == `CMD_LOAD_MODE ||
           req.cmd == `CMD_REFRESH || req.cmd == `CMD_PRECHARGE ) begin
     //1.set to io port
     @vif.drv_cb;  //align to clock
     vif.drv_cb.cmd   <= req.cmd;
     vif.drv_cb.addr  <= req.addr;
     vif.drv_cb.wdat  <= 32'hx;
     vif.drv_cb.dm    <= 4'hx;
     wait_for_cmdack();
     vif.drv_cb.cmd   <= `CMD_NOP;
  end
  else if( req.cmd == `CMD_WRITE ) begin
      if( page == 0 ) begin  //burst
         @vif.drv_cb;  //align to clock
         vif.drv_cb.cmd   <= req.cmd;
         vif.drv_cb.addr  <= req.addr;  //row address
         vif.drv_cb.wdat  <= req.wdat[0];
         vif.drv_cb.dm    <= req.dm;
         wait_for_cmdack();
         vif.drv_cb.cmd   <= `CMD_NOP;
         repeat(rcd-2) @vif.drv_cb;  //delay clock for data change point
         for( i = 1; i<req.bl; i++ ) begin 
           vif.drv_cb.wdat  <= req.wdat[i];
           @vif.drv_cb;  //delay 1 clock
         end
	  end
	  else begin
        //1. first data and command
        @vif.drv_cb;  //align to clock
        vif.drv_cb.cmd   <= req.cmd;
        vif.drv_cb.addr  <= req.addr;  //row address
        vif.drv_cb.wdat  <= req.wdat[0];
        vif.drv_cb.dm    <= 4'd0;//data mask is no use
        wait_for_cmdack();
        vif.drv_cb.cmd   <= `CMD_NOP;

        //2. delay for data burst point
        repeat(rcd-2) @vif.drv_cb;  //delay clock for data change point
        //3. the n-1 data 
        if( req.bl <3 ) begin
          `uvm_info("mst_driver",$sformatf(" get a bl error xact in page mode,id=%d,bl=%d",req.id,req.bl),UVM_LOW);
        end
        else begin
            //3.1 transfer second data package,number=n-2
            for( i=1; i<=req.bl-2;i++) begin
               vif.drv_cb.wdat  <= req.wdat[i];
               @vif.drv_cb;  //delay 1 clock
            end
            //3.2 issue one precharge command to terminate the burst,at the same time out the last data
            vif.drv_cb.wdat  <= req.wdat[req.bl-1];//the last data
            vif.drv_cb.cmd   <= `CMD_PRECHARGE;//use this cmd to end transfer
            @vif.drv_cb;  //delay 1 clock
            //3.3 wait for page write finish,also the precharge in step3.2 finish
            wait_for_cmdack();
            vif.drv_cb.cmd   <= `CMD_NOP;
            @vif.drv_cb;  //delay 1 clock
            //testcase do precharge command
        end
	 end
  end//write end
  else if( req.cmd == `CMD_READ ) begin
     if( page == 0 ) begin
        @vif.drv_cb;  //align to clock
        vif.drv_cb.cmd   <= req.cmd;
        vif.drv_cb.addr  <= req.addr;  //row address
        vif.drv_cb.wdat  <= 32'hx;
        vif.drv_cb.dm    <= 32'hx;
        wait_for_cmdack();
        vif.drv_cb.cmd   <= `CMD_NOP;
        repeat(rcd+cl) @vif.drv_cb;  //delay for sdram side
        repeat(   2  ) @vif.drv_cb;  //delay from sdram to master side
        for( i = 0; i<req.bl; i++ ) begin 
          req.rdat[i]  <= vif.drv_cb.rdat;
          @vif.drv_cb;  //delay 1 clock
        end
	 end
	 else begin
        //1. set the command
        @vif.drv_cb;  //align to clock
        vif.drv_cb.cmd   <= req.cmd;
        vif.drv_cb.addr  <= req.addr;  //row address
        vif.drv_cb.wdat  <= 32'hx;
        vif.drv_cb.dm    <= 32'hx;
        wait_for_cmdack();
        vif.drv_cb.cmd   <= `CMD_NOP;
        repeat(rcd+cl) @vif.drv_cb;  //delay for sdram side
        repeat(   1  ) @vif.drv_cb;  //delay from sdram to master side
        //2. read data 
        if( req.bl < 9 ) begin 
          `uvm_info("mst_driver",$sformatf(" get a bl error xact in page mode,id=%d,bl=%d",req.id,req.bl),UVM_LOW);
        end
        else begin
           //2.1 read and issue precharge at the right timing. 
           for(i=0;i<req.bl;i++) begin
              if( i==(req.bl-8) )  vif.drv_cb.cmd   <= `CMD_PRECHARGE;//use this cmd to end transfer
              @vif.drv_cb;  //delay 1 clock
              req.rdat[i] = vif.drv_cb.rdat;
              if( vif.drv_cb.cmdack == 1'b1 )  vif.drv_cb.cmd <= `CMD_NOP;
           end
        end
	 end
  end
  else begin
    `uvm_info("mst_driver",$sformatf(" get a invliad xact,id=%d,cmd=%d",req.id,req.cmd),UVM_LOW);
  end
  repeat(req.delay) @vif.drv_cb;  //delay 

endtask
