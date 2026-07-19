//===================================================================
//Project: Design and Verify APB UART IP
//File: apb_seq_item.sv
//Author: Nguyen Ngoc Man
//Description:
//===================================================================
class apb_seq_item extends uvm_sequence_item;
    typedef apb_seq_item this_type_t;
    `uvm_object_utils(this_type_t)
    //
    `ifdef MASTER_ROLE
        rand logic [`APB_AW-1:0] addr; 
        rand logic [`APB_DW-1:0] data; 
        rand logic wr_en;
        rand logic [`APB_DW/8-1:0] be;
        bit err;
        bit pready;
        int preadyDelay;
        bit resetn_req;
    `else 
        //===================================
        // Randomized Slave Response Fields
        //===================================
        rand bit  pready;
        rand bit  err;
        rand int preadyDelay;
        //===================================
        // Transaction Request Fields
        //===================================
        logic [`APB_AW-1:0]  addr;
        logic [`APB_DW-1:0]  data;
        logic [`APB_DW/8-1:0] be;
        logic           wr_en;
        //constraint to pready and err
        //constraint for 7:3 ratio
        constraint c_pready {
            pready dist {1 := 8, 0 := 2};
        }
        //
        constraint c_err {
            err dist {0 := 7, 1 := 3};
        }
        //
        constraint c_preadyDelay {
            preadyDelay inside {[1:4]};
        }
    `endif 
    //===================================
    // Constructor
    //===================================
    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

    //===================================
    // UVM built-in overrides
    //===================================
    extern function void   do_print(uvm_printer printer);
    extern function string convert2string();
    extern function bit    do_compare(uvm_object rhs, uvm_comparer comparer);
    extern function void   do_copy(uvm_object rhs);

endclass : apb_seq_item

//=======================================
// do_print
//=======================================
function void apb_seq_item::do_print(uvm_printer printer);
   // super.do_print(printer);
    `ifdef MASTER_ROLE
        printer.print_field("ADDR",       addr,       $bits(addr),       UVM_HEX);
        printer.print_field("PWRITE",     wr_en,      $bits(wr_en),      UVM_BIN);
        printer.print_field("DATA",     data,      $bits(data),      UVM_HEX);
        printer.print_field("PSTRB",      be,       $bits(be),       UVM_HEX);
        printer.print_field("PSLVERR",    err,       $bits(err),       UVM_BIN);
    `else
    printer.print_field("ADDR",       addr,       $bits(addr),       UVM_HEX);
    printer.print_field("PWRITE",     wr_en,      $bits(wr_en),      UVM_BIN);
    printer.print_field("PDATA",     wdata,      $bits(wdata),      UVM_HEX);
    printer.print_field("PSTRB",      be,       $bits(be),       UVM_HEX);
    printer.print_field("PREADY",     pready,      $bits(pready),      UVM_BIN);
    printer.print_field("PSLVERR",    err,     $bits(err),     UVM_BIN);
    printer.print_field("PREADY_DELAY", preadyDelay, $bits(preadyDelay), UVM_DEC);
    `endif
endfunction

//=======================================
// convert2string
//=======================================
function string apb_seq_item::convert2string();
    string s;
    `ifdef MASTER_ROLE
    s = {s, $sformatf("ADDR    : 0x%08h\n", addr)};
    s = {s, $sformatf("DATA   : 0x%08h\n", data)};
    s = {s, $sformatf("PWRITE  : %0b\n", wr_en)};
    s = {s, $sformatf("PWSTRB  : 0x%0h\n", be)};
    s = {s, $sformatf("PSLVERR : 0x%0h\n", err)};
    `else
    s = {s, $sformatf("ADDR    : 0x%08h\n", addr)};
    s = {s, $sformatf("DATA   : 0x%08h\n", wdata)};
    s = {s, $sformatf("PWRITE  : %0b\n", wr_en)};
    s = {s, $sformatf("PWSTRB  : 0x%0h\n", be)};
    s = {s, $sformatf("PREADY  : 0x%0h\n", pready)};
    s = {s, $sformatf("PSLVERR : 0x%0h\n", err)};
    s = {s, $sformatf("DELAY   : %0d\n", preadyDelay)};
    `endif
    return s;
endfunction

//=======================================
// do_compare
//=======================================
function bit apb_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
    this_type_t rhs_;
    bit match;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("APB_SEQ_ITEM", "Object is not of type apb_seq_item")
        return 0;
    end

    match = 1'b1;
    `ifdef MASTER_ROLE
    match &= (this.addr     == rhs_.addr);
    match &= (this.data     == rhs_.data);
    match &= (this.wr_en    == rhs_.wr_en);
    `ifdef SUPPORT_BE
    match &= (this.be       == rhs_.be);
    `endif
    `else
    match &= (this.addr       == rhs_.addr);
    match &= (this.data      == rhs_.data);
    match &= (this.wr_en      == rhs_.wr_en);
    match &= (this.be       == rhs_.be);
    match &= (this.pready      == rhs_.pready);
    match &= (this.err     == rhs_.err);
    `endif
    return match;
endfunction

//=======================================
// do_copy
//=======================================
function void apb_seq_item::do_copy(uvm_object rhs);
    this_type_t rhs_;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("apb_SEQ_ITEM", "Object is not of type apb_seq_item")
        return;
    end
    //
    `ifdef MASTER_ROLE
    this.addr     = rhs_.addr;
    this.data     = rhs_.data;
    this.wr_en    = rhs_.wr_en;
    this.be       = rhs_.be;
    `else
    this.addr       = rhs_.addr;
    this.wdata      = rhs_.wdata;
    this.wr_en      = rhs_.wr_en;
    this.be       = rhs_.be;
    this.pready      = rhs_.pready;
    this.err     = rhs_.err;
    `endif
endfunction
