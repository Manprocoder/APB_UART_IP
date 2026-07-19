//===============================================================
//Project: Design and Verify APB UART IP
//File: apb_cov_item.sv
//Author: Nguyen Ngoc Man
//Description: 
//===============================================================
import apb_pkg::*;
//
apb_seq_item item;

covergroup apb_group;
    addr_cp: coverpoint item.addr{
        bins ctrl_reg = {`APB_AW'h0};
        bins status_reg = {`APB_AW'h4};
        bins divisor_reg = {`APB_AW'h8};
        bins txd_reg = {`APB_AW'hC};
        bins rxd_reg = {`APB_AW'h10};
    }
    //-status
    status_cp: coverpoint item.data iff (!item.wr_en && item.addr==`APB_AW'h4) {
        bins frame_err = {`APB_DW'h0000_???1};
        bins parity_err = {`APB_DW'h0000_???2};
        bins break_con = {`APB_DW'h0000_???4};
        bins tx_ov = {`APB_DW'h0000_???8};
        bins rx_ov = {`APB_DW'h0000_??1?};
        bins tx_full = {`APB_DW'h0000_??2?};
        bins rx_full = {`APB_DW'h0000_??4?};
        bins rx_not_empty = {`APB_DW'h0000_??8?};
        bins busy = {`APB_DW'h0000_?1??};
        bins rx_ud = {`APB_DW'h0000_?2??};
    }
    //--Control
    control_cp: coverpoint item.data iff (item.wr_en && item.addr==`APB_AW'h0) {
        bins pe_int = {`APB_DW'h0000_?1??};
        bins fe_int = {`APB_DW'h0000_?2??};
        bins tx_ov_int = {`APB_DW'h0000_?4??};
        bins rx_ov_int = {`APB_DW'h0000_?8??};
        bins break_int = {`APB_DW'h0000_1???};
        bins rx_data_int = {`APB_DW'h0000_2???};
   } 
   //
   parity_en_cp: coverpoint item.data iff (item.wr_en && item.addr==`APB_AW'h0) {
        bins parity_en = {`APB_DW'h0000_???2};
   }
   //
   parity_type_cp: coverpoint item.data iff (item.wr_en && item.addr==`APB_AW'h0) {
        bins even_parity = {`APB_DW'h0000_???4};
        bins odd_parity = {`APB_DW'h0000_???B};
   }
    //
    //---cross coverage for parity
    //
    parity_en_x_type: cross parity_en_cp, parity_type_cp;
endgroup
