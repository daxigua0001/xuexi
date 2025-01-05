`uvm_analysis_imp_decl(_mst_cmd_ch)
`uvm_analysis_imp_decl(_mst_ref_ch)
`uvm_analysis_imp_decl(_slv_cmd_ch)
`uvm_analysis_imp_decl(_slv_ref_ch)

class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)

uvm_analysis_imp_mst_cmd_ch #(transaction,scoreboard) mst_cmd_ch; 
uvm_analysis_imp_mst_ref_ch #(transaction,scoreboard) mst_ref_ch; 
uvm_analysis_imp_slv_cmd_ch #(transaction,scoreboard) slv_cmd_ch; 
uvm_analysis_imp_slv_ref_ch #(transaction,scoreboard) slv_ref_ch; 

uvm_tlm_analysis_fifo #(transaction) mst_cmd_fifo;
uvm_tlm_analysis_fifo #(transaction) mst_ref_fifo;
uvm_tlm_analysis_fifo #(transaction) slv_cmd_fifo;
uvm_tlm_analysis_fifo #(transaction) slv_ref_fifo;

bit[63:0]  timestamp_pre;
bit[63:0]  timestamp_range;
bit[`MEM_RANGE-1:0][`DSIZE-1:0] sdram_mem;

extern function new(string name, uvm_component parent);
extern function write_mst_cmd_ch(transaction tr);
extern function write_mst_ref_ch(transaction tr);
extern function write_slv_cmd_ch(transaction tr);
extern function write_slv_ref_ch(transaction tr);
extern task compare_cmd();
extern task compare_ref();
extern task run_phase(uvm_phase phase);
extern function void debug_info_cmd( transaction tr );
extern function void debug_info_ref( transaction tr );
extern function void write_mem( transaction tr );
extern function void compare_mem( transaction tr );

endclass

function scoreboard::new(string name,uvm_component parent);
  super.new(name,parent);
  mst_cmd_ch = new("mst_cmd_ch",this);
  mst_ref_ch = new("mst_ref_ch",this);
  slv_cmd_ch = new("slv_cmd_ch",this);
  slv_ref_ch = new("slv_ref_ch",this);

  mst_cmd_fifo = new("mst_cmd_fifo",this);
  mst_ref_fifo = new("mst_ref_fifo",this);
  slv_cmd_fifo = new("slv_cmd_fifo",this);
  slv_ref_fifo = new("slv_ref_fifo",this);

  timestamp_pre    = 0;
  timestamp_range  = 30ns;
  
endfunction

function scoreboard:: write_mst_cmd_ch(transaction tr);
  mst_cmd_fifo.write(tr);
  `uvm_info(get_type_name(),"write tr to mst cmd fifo",UVM_LOW);
   debug_info_cmd( tr );
endfunction

function scoreboard:: write_mst_ref_ch(transaction tr);
  
  if( tr.timestamp - timestamp_pre < timestamp_range )  tr.ref_flag = 1;
  timestamp_pre = tr.timestamp; 
  mst_ref_fifo.write(tr);
  `uvm_info(get_type_name(),"write tr to ref cmd fifo",UVM_LOW);
   debug_info_ref( tr );
endfunction

function scoreboard:: write_slv_cmd_ch(transaction tr);
  slv_cmd_fifo.write(tr);
  `uvm_info(get_type_name(),"write tr to slv cmd fifo",UVM_LOW);
   debug_info_cmd( tr );
endfunction

function scoreboard:: write_slv_ref_ch(transaction tr);
  slv_cmd_fifo.write(tr);
  `uvm_info(get_type_name(),"write tr to slv ref fifo",UVM_LOW);
   debug_info_ref( tr );
endfunction

task scoreboard::run_phase(uvm_phase phase);
  fork
     compare_cmd();
     compare_ref();
  join
endtask

task scoreboard::compare_cmd();
  transaction tr1;
  transaction tr2;
  bit result;
  int i;
  while(1) begin
     //tr1 = new();
	 //tr2 = new();
	 mst_cmd_fifo.get(tr1);
	 slv_cmd_fifo.get(tr2);

    if( tr1.cmd == tr2.cmd ) begin
        if( tr1.cmd == `CMD_REFRESH ) begin
             `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
        end
        else if( tr1.cmd == `CMD_WRITE ) begin
            //write memory
            write_mem( tr1 );
    
            //1. timestamp/ref_flag/delay/some data do not compare
            tr2.timestamp = tr1.timestamp; 
            tr2.ref_flag  = tr1.ref_flag ; 
            tr2.delay     = tr1.delay;
            for( i=tr1.bl;i<`ROW_RANGE;i++ )   tr2.wdat[i] = tr1.wdat[i];
            for( i=0     ;i<`ROW_RANGE;i++ )   tr2.rdat[i] = tr1.rdat[i];
	        for( i=0;i<tr1.bl;i++ ) begin
               if( tr1.dm[0] == 1'b1 ) tr2.wdat[i][ 7: 0] = tr1.wdat[i][ 7: 0];
               if( tr1.dm[1] == 1'b1 ) tr2.wdat[i][15: 8] = tr1.wdat[i][15: 8];
               if( tr1.dm[2] == 1'b1 ) tr2.wdat[i][23:16] = tr1.wdat[i][23:16];
               if( tr1.dm[3] == 1'b1 ) tr2.wdat[i][31:24] = tr1.wdat[i][31:24];
            end
            //2. compare
            result = tr1.compare(tr2);
            if( result ) begin
                `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
	        end
	        else begin
                `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
	        end
         end//write
         else if( tr1.cmd == `CMD_READ ) begin
            compare_mem( tr1 );  //compare memory

            //1. timestamp/ref_flag/delay/dm/some data do not compare
            tr2.timestamp = tr1.timestamp; 
            tr2.ref_flag  = tr1.ref_flag ; 
            tr2.delay     = tr1.delay;
            tr2.dm        = tr1.dm       ;
            for( i=tr1.bl;i<`ROW_RANGE;i++ )   tr2.rdat[i] = tr1.rdat[i];
            for( i=0     ;i<`ROW_RANGE;i++ )   tr2.wdat[i] = tr1.wdat[i];
	         //2. compare
            result = tr1.compare(tr2);
            if( result ) begin
                `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
	        end
	        else begin
                `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
	        end
         
         end
         else if(tr1.cmd == `CMD_PRECHARGE ) begin
            if( tr1.addr[10] == 1 && tr2.addr[10] == 1 ) begin
               `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
            end
            else if( tr1.addr[10]==0 && tr2.addr[10] == 0 && tr1.addr[22:21] == tr2.addr[22:21] ) begin
               `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
            end
            else begin
                `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
            end
         end
         else if(tr1.cmd == `CMD_LOAD_MODE ) begin
            if( tr1.mode == tr2.mode && tr1.bl == tr2.bl ) begin
                `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
            end
            else begin
                `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
            end
         end
   end//tr1.cmd=tr2.cmd
   else begin
     `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
   end
   debug_info_cmd(tr1);
   debug_info_cmd(tr2);
 end //while
endtask

task scoreboard::compare_ref();
  transaction tr1;
  transaction tr2;
  bit result;
  int i;
 while(1) begin
     //tr1 = new();
	 //tr2 = new();
	 mst_ref_fifo.get(tr1);
	 slv_ref_fifo.get(tr2);

     if( tr2.timestamp - tr1.timestamp < timestamp_range ) begin
        `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
     end
     else begin 
         if( tr1.ref_flag == 1 ) begin //special 
            //debug info
            `uvm_info(get_type_name(),"Drop special xact",UVM_LOW);
            debug_info_ref(tr1);
            tr1 = new();
	        mst_ref_fifo.get(tr1); //get next xact.
            if( tr2.timestamp - tr1.timestamp < timestamp_range ) begin 
               `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
            end
            else begin 
               `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
            end
         end
         else begin //is not special
            `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
         end
     end
     debug_info_ref(tr1);
     debug_info_ref(tr2);
  end
endtask

function void scoreboard::write_mem( transaction tr );
   int i;
   bit[31:0] addr;
   if( tr.mode == 0 ) begin //burst mode
      addr = tr.addr;
      for( i=0; i<tr.bl;i++ ) begin
         if( tr.dm[0] == 1'b0 ) sdram_mem[addr][ 7: 0] = tr.wdat[i][ 7: 0];
         if( tr.dm[1] == 1'b0 ) sdram_mem[addr][15: 8] = tr.wdat[i][15: 8];
         if( tr.dm[2] == 1'b0 ) sdram_mem[addr][23:16] = tr.wdat[i][23:16];
         if( tr.dm[3] == 1'b0 ) sdram_mem[addr][31:24] = tr.wdat[i][31:24];
         
         if(      tr.bl == 2 ) addr[  0]++; 
         else if( tr.bl == 4 ) addr[1:0]++; 
         else if( tr.bl == 8 ) addr[2:0]++; 
      end //for
   end //mode=0
   else begin  //page mode
      addr = tr.addr;
      for( i=0; i<tr.bl;i++ ) begin
         sdram_mem[addr] = tr.wdat[i];
         addr[7:0]++; 
      end
   end
endfunction

function void scoreboard::compare_mem( transaction tr );
   int i;
   bit[31:0] addr;
   bit result = 1;

   if( tr.mode == 0 ) begin //burst mode
      addr = tr.addr;
      for( i=0; i<tr.bl;i++ ) begin
         if(  sdram_mem[addr] != tr.wdat[i] )  result = 0;
         if(      tr.bl == 2 ) addr[  0]++; 
         else if( tr.bl == 4 ) addr[1:0]++; 
         else if( tr.bl == 8 ) addr[2:0]++; 
      end //for
   end //mode=0
   else begin  //page mode
      addr = tr.addr;
      for( i=0; i<tr.bl;i++ ) begin
         if( sdram_mem[addr] != tr.wdat[i] ) result =0;
         addr[7:0]++; 
      end
   end
   if( result ) begin
       `uvm_info(get_type_name(),"compare SUCCESS",UVM_LOW);
   end
   else begin
       `uvm_info(get_type_name(),"compare FAIL",UVM_LOW);
   end


endfunction

function void scoreboard::debug_info_cmd( transaction tr );
  `uvm_info("scoreboard","send a transaction",UVM_LOW);
  `uvm_info("scoreboard",$sformatf("id=%d"   ,tr.id),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("page=%b" ,tr.mode),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("cmd=%3b" ,tr.cmd),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("addr=%h" ,tr.addr),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat0=%h",tr.wdat[0]),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat1=%h",tr.wdat[1]),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat2=%h",tr.wdat[2]),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat3=%h",tr.wdat[3]),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat0=%h",tr.rdat[0]),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat1=%h",tr.rdat[1]),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat2=%h",tr.rdat[2]),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("wdat3=%h",tr.rdat[3]),UVM_LOW);
endfunction

function void scoreboard::debug_info_ref( transaction tr );
  `uvm_info("scoreboard",$sformatf("id=%d"        ,tr.id       ),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("page=%b"      ,tr.mode     ),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("cmd=%3b"      ,tr.cmd      ),UVM_LOW);
  `uvm_info("scoreboard",$sformatf("timestamp=%h" ,tr.timestamp),UVM_LOW);
endfunction


