## 
## -------------------------------------------------------------
##    Copyright 2010-2011 Synopsys, Inc.
##    All Rights Reserved Worldwide
## 
##    Licensed under the Apache License, Version 2.0 (the
##    "License"); you may not use this file except in
##    compliance with the License.  You may obtain a copy of
##    the License at
## 
##        http://www.apache.org/licenses/LICENSE-2.0
## 
##    Unless required by applicable law or agreed to in
##    writing, software distributed under the License is
##    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
##    CONDITIONS OF ANY KIND, either express or implied.  See
##    the License for the specific language governing
##    permissions and limitations under the License.
## -------------------------------------------------------------
## 

UVM_HOME	    =  $(VCS_HOME)/etc/uvm-1.1
PAT_DIR_BASE    =  ../tb/pat
CHK_RESULT	    =  ../bin/check_result.pl
#OPT		= +define+RATE_9p8G
#VIP_DIR         =  $(PROJ_ROOT)/vip_include
include ../bin/Makefile.vcs

PAT_DIR = $(PAT_DIR_BASE)/$(PAT_NAME)

#COV
CM = -cm line+cond+fsm+branch+tgl
CM_NAME = -cm_name simv
CM_DIR = -cm_dir ./cov/$(PAT_NAME).vdb
#CM_DIR = -cm_dir ./cov/$(PAT_NAME)/covdir.vdb
#urg -full64 -dir tc1.vdb tc2.vdb -dbname merged.vdb -report urgReport

#ASSERTION
ASS_ON  = +define+SVA+ASSERT_ON
ASS_RUN = +sva_success 

	#rm  -rf  *~  core  csrc  simv*  vc_hdrs.h  ucli.key  urg* *.log  novas.* *.fsdb* verdiLog  64* DVEfiles *.vpd

all: pre_clean set comp run save

pre_clean:
	@rm -fr my*
	rm  -rf  *~  core  csrc  simv*  vc_hdrs.h  ucli.key  urg* *.log  novas.* *.fsdb*  64* DVEfiles *.vpd
set:
  	    
	@echo "pat >> $(PAT_DIR)"
    
    ## link sim files
	@ln -s $(PAT_DIR)/my_test.sv ./
	@ln -s $(PAT_DIR)/my_seq.sv ./

comp:
	$(VCS)	-f filelist.f -l comp.log $(CM) $(CM_NAME) $(CM_DIR) $(ASS_ON) 

run:
	$(SIMV) +UVM_TESTNAME=my_test  $(CM) $(CM_NAME) $(CM_DIR) $(ASS_RUN) 
	echo "***PAT_NAME = $(PAT_NAME) ***" >> vcs.log 
	$(CHK_RESULT) $(PAT_NAME)

save:
	@cp *.fsdb wave/$(PAT_NAME).fsdb
	@cp vcs.log  log/$(PAT_NAME).log

############ setup ############
#setup:
#	$(DESIGNWARE_HOME)/bin/dw_vip_setup -svtb -path $(VIP_DIR) -add ethernet_txrx_rvm_vera_vmt
