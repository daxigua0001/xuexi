class transaction extends uvm_sequence_item;

//define member
  rand bit[ 3:0]                        cmd;
  rand bit[`ASIZE-1:0]                  addr;
  rand bit[`ROW_RANGE-1:0][`DSIZE-1:0]  wdat; //one row is 512 address for interface
  rand bit[`ROW_RANGE-1:0][`DSIZE-1:0]  rdat; //one row is 512 address for interface
  rand bit[`DSIZE/8-1:0]                dm;
  rand bit                              mode;//0:burst 1:page
  rand bit[9:0]                         bl;//burst length:0-3. page mode:for page length.
  rand bit[3:0]                         delay; //transaction delay
  bit[63:0]                             timestamp;   //for refresh use
  bit                                   ref_flag;//for refresh use
  bit[31:0]                             id;//for debug use  

 //---register to factory ----//
  `uvm_object_utils_begin( transaction )
     
     `uvm_field_int(  cmd        ,  UVM_ALL_ON )
     `uvm_field_int(  addr       ,  UVM_ALL_ON )
     `uvm_field_int(  dm         ,  UVM_ALL_ON )
     `uvm_field_int(  timestamp  ,  UVM_ALL_ON )
     `uvm_field_int(  ref_flag   ,  UVM_ALL_ON )
     `uvm_field_int(  mode       ,  UVM_ALL_ON )
     `uvm_field_int(  bl         ,  UVM_ALL_ON )
     `uvm_field_int(  delay      ,  UVM_ALL_ON )
     `uvm_field_sarray_int( wdat ,  UVM_ALL_ON )
     `uvm_field_sarray_int( rdat ,  UVM_ALL_ON )


  `uvm_object_utils_end
//add constraint
constraint c_mode{
  mode dist { 0:/70 , 1:/30 };
}

constraint c_cmd{
   cmd dist{  1:/35, 2:/35, 3:/12, 4:/13, 5:/5  };
}

constraint c_dm{
   solve mode before dm;
   if( mode == 0 )
       dm dist{  0:/60, [1 : 15]:/40  };
   else
       dm == 0;
}

constraint c_bl{
  solve mode before bl; 
  solve cmd  before bl;
  if( mode == 0 )
      bl  inside { 1,2,4,8};
  else if( cmd == 1 )
      bl  dist { [9:32]:/70,  [33 : 255]:/30, 256:/10 };
  else if( cmd == 2 )
      bl  dist { [3:32]:/70,  [33 : 255]:/30, 256:/10 };
  else 
      bl == 0;
}

function new(string name="transaction");
    super.new(name);
endfunction

endclass
