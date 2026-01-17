#==========================================================
#Project: Design APB-UART IP core
#File name: run.do 
#Description: compile and run simulation
#==========================================================
set UVM_HOME "C:/questasim64_10.7c/uvm-1.2"
set UVM_HOME_1_1d "C:/questasim64_10.7c/uvm-1.1d"
set test_case full_frame_test
#set SVA folder
set sva_dir ../TB/SVA_CHECK
set sva_file $sva_dir/sva_log.log
#
if {![file exists $sva_dir]} {
	file delete -force $sva_dir	
}
#
set fh [open $sva_file w]
close $fh
#
#compile files
#+define+BACK_DOOR \
#+define+INTERRUPT \
vlib work
vlog +define+AGENT_CNT=1 \
+define+APB_MASTER \
+define+UVM_CMDLINE_NO_DPI \
+define+UVM_REGEX_NO_DPI \
+define+PRINT_TO_APB_SVA_FILE \
+define+CLK_CYCLE=20 \
+define+SIM_TIME=1ms \
+define+UVM_NO_DPI \
+define+UVM_HDL_NO_DPI \
+incdir+$UVM_HOME/src \
+incdir+$UVM_HOME_1_1d \
-f list_file.f \
-timescale 1ns/1ns \
-l vlog.log \
+cover
vsim -voptargs=+acc work.tb -cover -classdebug -uvmcontrol=all \
+UVM_TESTNAME=$test_case \
+UVM_VERBOSITY=UVM_HIGH \
+UVM_NO_PHASE_TRACE \
-l vsim.log
#
#run 0 is used for adding signals of class into waveform
#
run 0
do add_wave.do
run -all
