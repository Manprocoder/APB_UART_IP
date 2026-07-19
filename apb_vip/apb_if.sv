//=====================================================
//--Project: Design and Verify APB UART IP
//--File: apb_intf.sv
//--Author: Nguyen Ngoc Man
//=====================================================
interface apb_if (input logic pclk);
//apb channel
  logic presetn;
  logic  psel;
  logic penable;
  logic pwrite;
  logic [2:0] pprot;
  logic [`APB_DW/8-1:0] pstrb;
  logic [`APB_AW-1:0] paddr;
  logic [`APB_DW-1:0] pwdata;
  logic [`APB_DW-1:0] prdata;
  logic  pready;
  logic  pslverr;
  //other signals
  logic en_o;
  logic wr_en_o;
  logic [`APB_AW-1:0] addr_o;
  logic [`APB_DW-1:0] rdata_i;
  logic [`APB_DW-1:0] wdata_o;
  logic pready_i;
  logic [`APB_DW/8-1:0] be_o;
  logic err_i;
  // =====================================
  // SVA Protocol Checks
  // =====================================
      //reset all signals
      //DEFINE
      property reset_all_signals;
        @(posedge pclk) disable iff (!presetn)
        (presetn == 0) |=> (psel == 0 && penable == 0 && paddr == 0);
      endproperty
      //DO
      assert property (reset_all_signals)
      else begin
        $error("[RESEL_ALL_SIGNALS]: all APB signals are not properly reset!!!");
      end
      //
      //(2)
      // access_phase: if psel and !penable, then penable must go high next cycle
      property access_phase;
        @(posedge pclk) disable iff (!presetn)
          (psel && !penable) |=> penable;
      endproperty
      assert property(access_phase)
      else begin
        $error("APB: penable not asserted in ACCESS phase");
      end
      //
      //(3)
      // Transfer Completion only when pready is asserted
      //DEFINE
      property complete_with_pready;
        @(posedge pclk) disable iff (!presetn)
          (psel && penable && ~pready) |=> penable;
      endproperty
      //DO
      assert property(complete_with_pready)
      else begin
        $error("APB_SVA: Transfer ended without pready");
      end
      //
      //(4)
      //
      //DEFINE
      property penable_deassert;
        @(posedge pclk) disable iff (!presetn)
          (psel && penable && pready) |=> !penable;
      endproperty
      //DO
      assert property(penable_deassert)
      else begin
        $error("APB: Penable also ASSERT as pready is high");
      end
  //================================================================
  //---------------CLOCKING BLOCKs
  //================================================================
  //-----NOTICE: Having used both m_drv_cb and s_drv_cb causes WARNING: multiply driven
  //
  clocking m_drv_cb @(posedge pclk);
      input prdata, pready, pslverr;
      output psel, penable, pwrite, pstrb, paddr, pwdata, pprot;
  endclocking
  //
  clocking s_drv_cb @(posedge pclk);
      input psel, penable, pwrite, pstrb, paddr, pwdata, pprot;
      output prdata, pready, pslverr;
  endclocking
  //
  clocking mon_cb @(posedge pclk);
      input psel, penable, pwrite, paddr, pwdata, pstrb, prdata, pready, pslverr, pprot;
  endclocking
  //
  clocking other_mon_cb @(posedge pclk);
      input en_o, wr_en_o, addr_o, wdata_o, rdata_i, pready_i, err_i, be_o;
  endclocking
endinterface


