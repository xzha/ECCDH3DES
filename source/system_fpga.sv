module system_fpga (
  ///////// CLOCKS //////////
  input logic  CLOCK_50,
  
  /////////// KEY ///////////
  input logic [3:0] KEY,

  /////////// HEX ///////////
  output logic [6:0] HEX0,
  output logic [6:0] HEX1,
  output logic [6:0] HEX2,
  output logic [6:0] HEX3,
  output logic [6:0] HEX4,
  output logic [6:0] HEX5,
  output logic [6:0] HEX6,
  output logic [6:0] HEX7,

  ///////// PCIE ////////////
  input logic PCIE_PERST_N,
  input logic PCIE_REFCLK_P,
  input logic PCIE_RX_P,
  output logic PCIE_TX_P,
  output logic PCIE_WAKE_N,
  
  ////////// FAN ////////////
  inout logic FAN_CTRL
);
  // turn off fan
  assign FAN_CTRL = 1'b0;

  // wake up pcie
  assign PCIE_WAKE_N = 1'b1;

  // avalon bus
  avalon_system u0 (
      .clk_clk                     (CLOCK_50),             //               clk.clk
      .reset_reset_n               (KEY[0]),               //             reset.reset_n
      .pcie_ip_refclk_export       (PCIE_REFCLK_P),        //    pcie_ip_refclk.export
      .pcie_ip_pcie_rstn_export    (PCIE_PERST_N),         // pcie_ip_pcie_rstn.export
      .pcie_ip_rx_in_rx_datain_0   (PCIE_RX_P),            //     pcie_ip_rx_in.rx_datain_0
      .pcie_ip_tx_out_tx_dataout_0 (PCIE_TX_P)             //    pcie_ip_tx_out.tx_dataout_0
  );
  
endmodule