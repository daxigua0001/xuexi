class mst_sequence extends uvm_sequence #(transaction);

`uvm_object_utils(mst_sequence)

transaction tr;

bit                              flag;
bit                              mode;
bit[ 3:0]                        cmd;
bit[`ASIZE-1:0]                  addr;
bit[7:0][`DSIZE-1:0]             wdat; //one row is 512 address for interface
bit[`DSIZE/8-1:0]                dm;
bit[9:0]                         bl;//burst length:0-3. page mode:for page length.
bit[3:0]                         delay; //transaction delay

function new(string name = "mst_sequence");
  super.new(name);
  flag = 0;
endfunction

function set_mode(bit iflag,bit imode,bit[3:0] icmd,bit[22:0] iaddr,bit[7:0][31:0] iwdat,bit idm,bit[9:0] ibl,bit[3:0] idelay );
   flag         = iflag;
   mode         = imode;
   addr         = iaddr;
   wdat         = iwdat;
   dm           = idm  ;
   bl           = ibl  ;
   delay        = idelay;
endfunction

function set_special();
   if( flag == 1 ) begin
      tr.mode  = mode  ;
      tr.addr  = addr  ;
      tr.wdat  = wdat  ;
      tr.dm    = dm    ;
      tr.bl    = bl    ;
      tr.delay = delay ;
   end
endfunction


virtual task body();

   tr = transaction::type_id::create("tr");
   start_item(tr);
   assert(tr.randomize());
   set_special();
   finish_item(tr);
   

endtask

endclass
