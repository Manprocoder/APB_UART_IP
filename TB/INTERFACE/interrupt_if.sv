//==================================================================================
//Project: Design UART IP
//File name: interrupt_if.sv
//Description:
//--TB  
//--interrupt_interface
//==================================================================================
interface interrupt_if();
	logic pe_int;
	logic fe_int;
	logic break_int;
	logic tx_ov_int;
	logic rx_ov_int;
	logic rx_data_int;
endinterface
