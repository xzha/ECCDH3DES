module system_fpga (
  ///////// CLOCKS //////////
  CLOCK_50,
  
  /////////// SW ////////////
  SW,

  /////////// KEY ///////////
  KEY,

  /////////// LED ///////////
  LEDG,
  LEDR,

  ////////// DRAM ///////////
  DRAM_CLK, 
  DRAM_CKE, 
  DRAM_ADDR,
  DRAM_BA,
  DRAM_CS_N,
  DRAM_CAS_N,
  DRAM_RAS_N,
  DRAM_WE_N,
  DRAM_DQ,
  DRAM_DQM,

  /////////// HEX ///////////
  HEX0,
  HEX1,
  HEX2,
  HEX3,
  HEX4,
  HEX5,
  HEX6,
  HEX7,
  
  ///////// PCIE ////////////
  PCIE_PERST_N,
  PCIE_REFCLK_P,
  PCIE_RX_P,
  PCIE_TX_P,
  PCIE_WAKE_N,
  
  ////////// FAN ////////////
  FAN_CTRL
);

  ///////// CLOCKS //////////
  input logic  CLOCK_50;

  /////////// SW ////////////
  input logic [17:0] SW;

  /////////// KEY ///////////
  input logic [3:0] KEY ;

  /////////// LED ///////////
  output logic [8:0] LEDG; 
  output logic [17:0]LEDR;

  ////////// DRAM ///////////
  output logic DRAM_CLK;
  output wire DRAM_CKE;
  output wire [11:0]DRAM_ADDR;
  output wire [1:0]DRAM_BA;
  output wire DRAM_CS_N;
  output wire DRAM_CAS_N;
  output wire DRAM_RAS_N;
  output wire DRAM_WE_N;
  inout  wire [31:0] DRAM_DQ;
  output wire [3:0] DRAM_DQM;

  /////////// HEX ///////////
  output logic [6:0] HEX0;
  output logic [6:0] HEX1;
  output logic [6:0] HEX2;
  output logic [6:0] HEX3;
  output logic [6:0] HEX4;
  output logic [6:0] HEX5;
  output logic [6:0] HEX6;
  output logic [6:0] HEX7;

  ///////// PCIE ////////////
  input logic PCIE_PERST_N;
  input logic PCIE_REFCLK_P;
  input logic PCIE_RX_P;
  output logic PCIE_TX_P;
  output logic PCIE_WAKE_N;

  ////////// FAN ////////////
  inout logic FAN_CTRL;

  logic soc_clk;
  parameter ADDRESSWIDTH = 28;
  parameter DATAWIDTH = 32;
  
  // turn off fan
  assign FAN_CTRL = 1'b0;
  
  // wake up pcie
  assign PCIE_WAKE_N = 1'b1;
  
  // assign clocks clock
  assign soc_clk = CLOCK_50;
  assign DRAM_CLK = CLOCK_50;

  // avalon bus
  avalon_system u0 (
      .clk_clk                     (soc_clk),              //               clk.clk
      .reset_reset_n               (KEY[0]),               //             reset.reset_n
      .sdram_addr                  (DRAM_ADDR),            //             sdram.addr
      .sdram_ba                    (DRAM_BA),              //                  .ba
      .sdram_cas_n                 (DRAM_CAS_N),           //                  .cas_n
      .sdram_cke                   (DRAM_CKE),             //                  .cke
      .sdram_cs_n                  (DRAM_CS_N),            //                  .cs_n
      .sdram_dq                    (DRAM_DQ),              //                  .dq
      .sdram_dqm                   (DRAM_DQM),             //                  .dqm
      .sdram_ras_n                 (DRAM_RAS_N),           //                  .ras_n
      .sdram_we_n                  (DRAM_WE_N),            //                  .we_n
      .pcie_ip_refclk_export       (PCIE_REFCLK_P),        //    pcie_ip_refclk.export
      .pcie_ip_pcie_rstn_export    (PCIE_PERST_N),         // pcie_ip_pcie_rstn.export
      .pcie_ip_rx_in_rx_datain_0   (PCIE_RX_P),            //     pcie_ip_rx_in.rx_datain_0
      .pcie_ip_tx_out_tx_dataout_0 (PCIE_TX_P)             //    pcie_ip_tx_out.tx_dataout_0
  );
  
endmodule