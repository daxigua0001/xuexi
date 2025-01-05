class slv_monitor extends uvm_monitor;

  virtual slv_if vif; //connect to simtop/interface
  uvm_analysis_port #(transaction ) ap; // connect to scoreboard
  
  transaction req; // transaction 

  int rcd;   //active to read delay
  int cl;    //read cmd to read data
  bit page;  //page mode or burst mode;
  int bl;
  bit[31:0] id;//for debug use 

`uvm_component_utils( slv_monitor )

  extern function new(string name,uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task main_phase( uvm_phase phase);
  extern         task monitor_bus();
  extern         task debug_info();
  extern         function void set_param_manual(int rcd1,int cl1,bit page1,int bl1);

endclass

function slv_monitor::new(string name,uvm_component parent);
  super.new(name,parent);
  rcd = 3;//default value
  cl  = 3;
  page = 0;
  bl   = 1;
  id   = 0;
endfunction

function void slv_monitor::set_param_manual(int rcd1,int cl1,bit page1,int bl1);
   rcd = rcd1;
   cl  = cl1 ;
   page= page1;
   bl = bl1;
endfunction

function void slv_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  //get virutal interface
  if( !uvm_config_db #(virtual slv_if) :: get(this,"","slv_if",vif))
     `uvm_fatal("slv_monitor","Error in gettting interface");

  ap = new("ap",this);
  req = new();

endfunction

task slv_monitor::main_phase(uvm_phase phase);
  super.main_phase(phase);

  while(1) begin
    `uvm_info("slv_driver",$sformatf("main phase get a xact,id=%d",req.id),UVM_LOW);
    monitor_bus();
	debug_info();
	ap.write(req);
  end

endtask

task slv_monitor::debug_info();
  `uvm_info("slv_driver","send a transaction",UVM_LOW);
  `uvm_info("slv_driver",$sformatf("id=%d",req.id),UVM_LOW);
  `uvm_info("slv_driver",$sformatf("page=%b",page),UVM_LOW);
  `uvm_info("slv_driver",$sformatf("cmd=%3b",req.cmd),UVM_LOW);
  `uvm_info("slv_driver",$sformatf("addr=%h",req.addr),UVM_LOW);
  `uvm_info("slv_driver",$sformatf("wdat0=%h",req.wdat[0]),UVM_LOW);
  `uvm_info("slv_driver",$sformatf("wdat1=%h",req.wdat[1]),UVM_LOW);
  `uvm_info("slv_driver",$sformatf("wdat2=%h",req.wdat[2]),UVM_LOW);
  `uvm_info("slv_driver",$sformatf("wdat3=%h",req.wdat[3]),UVM_LOW);
endtask

task slv_monitor::monitor_bus();
  int i;
  //1. wait for command effective.
   while(1) begin
      @vif.mon_cb;
      if( vif.mon_cb.cs_n != 2'b11 ) break;
   end
   req.id  = id;
  if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_LOAD_MODE ) begin
      cl   = vif.mon_cb.sa[6:4];
      page = 0;
      if(      vif.mon_cb.sa[2:0] == 0 ) bl     = 1;
      else if( vif.mon_cb.sa[2:0] == 1 ) bl     = 2;
      else if( vif.mon_cb.sa[2:0] == 2 ) bl     = 4;
      else if( vif.mon_cb.sa[2:0] == 3 ) bl     = 8;
      else if( vif.mon_cb.sa[2:0] == 7 ) page   = 1;
      else `uvm_info("slv_monitor",$sformatf("error, bl=%d",vif.mon_cb.sa[2:0] ),UVM_LOW);
      req.mode = page;
      req.bl   = bl;
      req.cmd  = `CMD_LOAD_MODE;
      //when load mode,other memeber in transaction is do not care
  end
  else if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_PRECHARGE ) begin
      req.addr[`BANKSTART+`BANKSIZE-1:`BANKSTART] = vif.mon_cb.ba;
      req.addr[10] = vif.mon_cb.sa[10]; // all bank or one bank
      req.cmd  = `CMD_PRECHARGE;
      //when precharge,other memeber in transaction is do not care
  end
  else if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_REFRESH ) begin
      req.cmd  = `CMD_REFRESH;
      if( vif.mon_cb.cs_n == 2'b00 ) begin
        `uvm_info("slv_monitor",$sformatf("cs_n check OK when refresh, cs_n=%d",vif.mon_cb.cs_n ),UVM_LOW);
      end
      else begin
        `uvm_info("slv_monitor",$sformatf("cs_n check error when refresh, cs_n=%d",vif.mon_cb.cs_n ),UVM_LOW);
      end
      //when refresh,other memeber in transaction is do not care
      
      //!!!!add two clock delay to make sure: driver trans enter socreboard early. 
      repeat(2) @vif.mon_cb;
   end
   else if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_ACTIVE ) begin
      //1.1 the address msb 
      if( vif.mon_cb.cs_n[0] == 0 ) req.addr[`ASIZE-1] = 1'b0;
      if( vif.mon_cb.cs_n[1] == 0 ) req.addr[`ASIZE-1] = 1'b1;
      //1.2 row address
      req.addr[`ROWSTART+`ROWSIZE-1:`ROWSTART] =vif.mon_cb.sa;
      //1.3 bank address
      req.addr[`BANKSTART+`BANKSIZE-1:`BANKSTART] = vif.mon_cb.ba;
      //2.delay to next command
      repeat( rcd ) @vif.mon_cb;
      if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_WRITE ) begin
         if( page == 0 ) begin //burst transfer mode
            //3.1 coloum address
            req.addr[`COLSTART+`COLSIZE-1:`COLSTART] =vif.mon_cb.sa;
            req.bl = bl;
            req.mode = 0;
            //3.2 write data
            for( i=0;i<bl;i++) begin
               if( vif.mon_cb.dqm[0] == 1'b0 )  req.wdat[i][ 7: 0] = vif.mon_cb.dq[ 7: 0];
               if( vif.mon_cb.dqm[1] == 1'b0 )  req.wdat[i][15: 8] = vif.mon_cb.dq[15: 8];
               if( vif.mon_cb.dqm[2] == 1'b0 )  req.wdat[i][23:16] = vif.mon_cb.dq[23:16];
               if( vif.mon_cb.dqm[3] == 1'b0 )  req.wdat[i][31:24] = vif.mon_cb.dq[31:24];
               @vif.mon_cb;
            end
         end
         else begin //page transfer mode
            //3.1 coloumn adress
            req.addr[`COLSTART+`COLSIZE-1:`COLSTART] =vif.mon_cb.sa;
            req.mode = 1;
            //3.2 write data store
            while(1) begin
               //3.3 if meet the precharge, end the while cycle.
               if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_PRECHARGE )  break;
               //3.4 or save the data 
               if( vif.mon_cb.dqm[0] == 1'b0 )  req.wdat[i][ 7: 0] = vif.mon_cb.dq[ 7: 0];
               if( vif.mon_cb.dqm[1] == 1'b0 )  req.wdat[i][15: 8] = vif.mon_cb.dq[15: 8];
               if( vif.mon_cb.dqm[2] == 1'b0 )  req.wdat[i][23:16] = vif.mon_cb.dq[23:16];
               if( vif.mon_cb.dqm[3] == 1'b0 )  req.wdat[i][31:24] = vif.mon_cb.dq[31:24];
               @vif.mon_cb;
               //3.5 set bl 
               i++;
               req.bl = i;
               //3.6 prevent error
               if( i>256) begin    
                   `uvm_info("slv_monitor",$sformatf("bl>512 error when write, id=%d",id ),UVM_LOW);
                   break;
               end
            end//while
         end//page
     end//write
     else if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_READ ) begin
        if( page == 0 ) begin //burst transfer mode
            //3.1 coloum address
            req.addr[`COLSTART+`COLSIZE-1:`COLSTART] =vif.mon_cb.sa;
            req.bl = bl;
            req.mode = 0;
            //3.2 delay to read timing postion
            repeat( cl ) @vif.mon_cb;
            //3.2 read data
            for( i=0;i<bl;i++) begin
               req.rdat[i][31: 0] = vif.mon_cb.dq[31:0];
               @vif.mon_cb;
            end
         end
         else begin
            //3.1 coloum address
            req.addr[`COLSTART+`COLSIZE-1:`COLSTART] =vif.mon_cb.sa;
            req.mode = 1;
            //3.2 delay to read timing postion
            repeat( cl ) @vif.mon_cb;
            //
            i=0;
            while(1) begin
               //3.3 get data
               req.rdat[i] = vif.mon_cb.dq;
               if( {vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} == `SCMD_PRECHARGE )  begin
                  //3.4 get the last two data 
                  @vif.mon_cb; i++; req.rdat[i] = vif.mon_cb.dq;
                  @vif.mon_cb; i++; req.rdat[i] = vif.mon_cb.dq;
                  //3.5 set bl
                  req.bl = i;
                  break; //quit while
               end
               i++;
               @vif.mon_cb;
               //3.6 prevent error
               if( i>256 ) begin
                   `uvm_info("slv_monitor",$sformatf("bl>512 error when read, id=%d",id ),UVM_LOW);
                   break;
               end
            end//while
         end//page
      end//read
      else begin
        `uvm_info("slv_monitor",$sformatf("cmd error when after active, cmd=%d",{vif.mon_cb.ras_n,vif.mon_cb.cas_n,vif.mon_cb.we_n} ),UVM_LOW);
      end
   end
   id++;
endtask
	     

