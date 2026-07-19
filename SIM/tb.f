//===========================================================================
//--Project: Design and Verify APB UART IP
//--File: tb.f
//--Author: Nguyen Ngoc Man
//--Description: includes APB VIP, UART VIP, UART RAL, environment and testbench 
//===========================================================================

+incdir+${APB_UART_VIP_VERIF_PATH}/testcases
+incdir+${APB_UART_VIP_VERIF_PATH}/sequences
+incdir+${APB_UART_VIP_VERIF_PATH}/tb
+incdir+${APB_UART_VIP_VERIF_PATH}/uart_ral

// Compilation VIP design (agent) list
-f ${APB_VIP_ROOT}/apb_vip.f
-f ${UART_VIP_ROOT}/uart_vip.f

// APB Protocol Checker 
${APB_UART_VIP_VERIF_PATH}/tb/apb_checker.sv
${APB_UART_VIP_VERIF_PATH}/tb/apb_checker_top.sv
${APB_UART_VIP_VERIF_PATH}/tb/baud_rate_sva.sv

// Compilation Environment
${APB_UART_VIP_VERIF_PATH}/uart_ral/uart_ral_pkg.sv
${APB_UART_VIP_VERIF_PATH}/tb/env_pkg.sv
${APB_UART_VIP_VERIF_PATH}/sequences/seq_pkg.sv
${APB_UART_VIP_VERIF_PATH}/testcases/test_pkg.sv
${APB_UART_VIP_VERIF_PATH}/tb/testbench.sv
