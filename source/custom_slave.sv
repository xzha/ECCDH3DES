// File name : custom_slave.sv
// Author : Ishaan Biswas
// Created : 03/29/2015
// Version 1.0 
// Description : Demo example to illustrate slave interface usage


module custom_slave #(
    parameter MASTER_ADDRESSWIDTH = 26 ,    // ADDRESSWIDTH specifies how many addresses the Master can address 
    parameter SLAVE_ADDRESSWIDTH = 8 ,      // ADDRESSWIDTH specifies how many addresses the slave needs to be mapped to. log(NUMREGS)
    parameter DATAWIDTH = 32,          // DATAWIDTH specifies the data width. Default 32 bits
    parameter NUMREGS = 256,              // Number of Internal Registers for Custom Logic
    parameter REGWIDTH = 32,            // Data Width for the Internal Registers. Default 32 bits
    parameter NUMCOUNT = 10
)  
(   
    input logic  clk,
    input logic  reset_n,
    
    // Interface to Top Level
    input logic rdwr_cntl,                  // Control Read or Write to a slave module.
    input logic n_action,                   // Trigger the Read or Write. Additional control to avoid continuous transactions. Not a required signal. Can and should be removed for actual application.
    input logic add_data_sel,               // Interfaced to switch. Selects either Data or Address to be displayed on the Seven Segment Displays.
    input logic [MASTER_ADDRESSWIDTH-1:0] rdwr_address, // read_address if required to be sent from another block. Can be unused if consecutive reads are required.

    // Bus Slave Interface
    input logic [SLAVE_ADDRESSWIDTH-1:0] slave_address,
    input logic [DATAWIDTH-1:0] slave_writedata,
    input logic  slave_write,
    input logic  slave_read,
    input logic  slave_chipselect,
    // input logic  slave_readdatavalid,            // These signals are for variable latency reads. 
    // output logic slave_waitrequest,              // See the Avalon Specifications for details  on how to use them.
    output logic [DATAWIDTH-1:0] slave_readdata,

    // Bus Master Interface
    output logic [MASTER_ADDRESSWIDTH-1:0] master_address,
    output logic [DATAWIDTH-1:0] master_writedata,
    output logic  master_write,
    output logic  master_read,
    input logic [DATAWIDTH-1:0] master_readdata,
    input logic  master_readdatavalid,
    input logic  master_waitrequest
);

// CONSTANTS
parameter START_BYTE = 32'hF00BF00B;
parameter STOP_BYTE = 32'hDEADF00B;

// GIVEN
logic [NUMREGS-1:0][REGWIDTH-1:0] csr_registers;        // Command and Status Registers (CSR) for custom logic

// ECC
logic [163:0] PuX;
logic [163:0] PuY;

logic ecc1_done;
logic ecc2_done; 
logic des_done; 
logic data_valid_out;

logic next_ecc1_done;
logic next_ecc2_done; 
logic next_des_done; 

logic [63:0] encrypted_data;

logic [NUMCOUNT: 0] count;


logic [31:0] partial_data;
logic [31:0] next_raw_data;
logic [63:0] raw_data;

logic [63:0] next_actual_data;
logic [63:0] actual_data;
logic count2;

// Slave side 
always_ff @ ( posedge clk ) begin 
  if(!reset_n)
    begin
        slave_readdata <= 32'h0;
        csr_registers <= '0;

        count <=10'd0;
        count2 <= '0;
    end else begin

        // OUTPUT SIGNAL
        ecc1_done <= next_ecc1_done;
        ecc2_done <= next_ecc2_done;
        des_done <= next_des_done;


        csr_registers[0][31] <= next_ecc1_done;
        csr_registers[0][30] <= next_ecc2_done;
        csr_registers[0][29] <= next_des_done;


        // BUFFER FOR DES
        partial_data <= csr_registers[19];
        next_raw_data <= partial_data;
        raw_data <= {next_raw_data, partial_data};
        actual_data <= next_actual_data;

        // OUTPUT KEY
        if(ecc1_done)
        begin
            csr_registers[26]        <= PuY[163:132];
            csr_registers[27]        <= PuY[131:100];
            csr_registers[28]        <= PuY[99:68];
            csr_registers[29]        <= PuY[67:36];
            csr_registers[30]        <= PuY[35:4];
            csr_registers[31][31:28] <= PuY[3:0];

            csr_registers[20]        <= PuX[163:132];
            csr_registers[21]        <= PuX[131:100];
            csr_registers[22]        <= PuX[99:68];
            csr_registers[23]        <= PuX[67:36];
            csr_registers[24]        <= PuX[35:4];
            csr_registers[25][31:28] <= PuX[3:0];
        end

        // OUTPUT DES
        if (des_done) 
        begin
            count2 <= count2 + 1;
            case(count)
                6'd0:
                begin
                    csr_registers[32] <= encrypted_data[63:32];
                    csr_registers[33] <= encrypted_data[31:0];
                end
                6'd1:
                begin
                    csr_registers[34] <= encrypted_data[63:32];
                    csr_registers[35] <= encrypted_data[31:0];
                end
                6'd2:
                begin
                    csr_registers[36] <= encrypted_data[63:32];
                    csr_registers[37] <= encrypted_data[31:0];
                end
                6'd3:
                begin
                    csr_registers[38] <= encrypted_data[63:32];
                    csr_registers[39] <= encrypted_data[31:0];
                end
                6'd4:
                begin
                    csr_registers[40] <= encrypted_data[63:32];
                    csr_registers[41] <= encrypted_data[31:0];
                end
                6'd5:
                begin
                    csr_registers[42] <= encrypted_data[63:32];
                    csr_registers[43] <= encrypted_data[31:0];
                end
                6'd6:
                begin
                    csr_registers[44] <= encrypted_data[63:32];
                    csr_registers[45] <= encrypted_data[31:0];
                end
                6'd7:
                begin
                    csr_registers[46] <= encrypted_data[63:32];
                    csr_registers[47] <= encrypted_data[31:0];
                end
                6'd8:
                begin
                    csr_registers[48] <= encrypted_data[63:32];
                    csr_registers[49] <= encrypted_data[31:0];
                end
                6'd9:
                begin
                    csr_registers[50] <= encrypted_data[63:32];
                    csr_registers[51] <= encrypted_data[31:0];
                end
                6'd10:
                begin
                    csr_registers[52] <= encrypted_data[63:32];
                    csr_registers[53] <= encrypted_data[31:0];
                end
                6'd11:
                begin
                    csr_registers[54] <= encrypted_data[63:32];
                    csr_registers[55] <= encrypted_data[31:0];
                end
                6'd12:
                begin
                    csr_registers[56] <= encrypted_data[63:32];
                    csr_registers[57] <= encrypted_data[31:0];
                end
                6'd13:
                begin
                    csr_registers[58] <= encrypted_data[63:32];
                    csr_registers[59] <= encrypted_data[31:0];
                end
                6'd14:
                begin
                    csr_registers[60] <= encrypted_data[63:32];
                    csr_registers[61] <= encrypted_data[31:0];
                end
                6'd15:
                begin
                    csr_registers[62] <= encrypted_data[63:32];
                    csr_registers[63] <= encrypted_data[31:0];
                end
                6'd16:
                begin
                    csr_registers[64] <= encrypted_data[63:32];
                    csr_registers[65] <= encrypted_data[31:0];
                end
                6'd17:
                begin
                    csr_registers[66] <= encrypted_data[63:32];
                    csr_registers[67] <= encrypted_data[31:0];
                end
                6'd18:
                begin
                    csr_registers[68] <= encrypted_data[63:32];
                    csr_registers[69] <= encrypted_data[31:0];
                end
                6'd19:
                begin
                    csr_registers[70] <= encrypted_data[63:32];
                    csr_registers[71] <= encrypted_data[31:0];
                end
                6'd20:
                begin
                    csr_registers[72] <= encrypted_data[63:32];
                    csr_registers[73] <= encrypted_data[31:0];
                end
                6'd21:
                begin
                    csr_registers[74] <= encrypted_data[63:32];
                    csr_registers[75] <= encrypted_data[31:0];
                end
                6'd22:
                begin
                    csr_registers[76] <= encrypted_data[63:32];
                    csr_registers[77] <= encrypted_data[31:0];
                end
                6'd23:
                begin
                    csr_registers[78] <= encrypted_data[63:32];
                    csr_registers[79] <= encrypted_data[31:0];
                end
                6'd24:
                begin
                    csr_registers[80] <= encrypted_data[63:32];
                    csr_registers[81] <= encrypted_data[31:0];
                end
                6'd25:
                begin
                    csr_registers[82] <= encrypted_data[63:32];
                    csr_registers[83] <= encrypted_data[31:0];
                end
                6'd26:
                begin
                    csr_registers[84] <= encrypted_data[63:32];
                    csr_registers[85] <= encrypted_data[31:0];
                end
                6'd27:
                begin
                    csr_registers[86] <= encrypted_data[63:32];
                    csr_registers[87] <= encrypted_data[31:0];
                end
                6'd28:
                begin
                    csr_registers[88] <= encrypted_data[63:32];
                    csr_registers[89] <= encrypted_data[31:0];
                end
                6'd29:
                begin
                    csr_registers[90] <= encrypted_data[63:32];
                    csr_registers[91] <= encrypted_data[31:0];
                end
                6'd30:
                begin
                    csr_registers[92] <= encrypted_data[63:32];
                    csr_registers[93] <= encrypted_data[31:0];
                end
                6'd31:
                begin
                    csr_registers[94] <= encrypted_data[63:32];
                    csr_registers[95] <= encrypted_data[31:0];
                end
                6'd32:
                begin
                    csr_registers[96] <= encrypted_data[63:32];
                    csr_registers[97] <= encrypted_data[31:0];
                end
                6'd33:
                begin
                    csr_registers[98] <= encrypted_data[63:32];
                    csr_registers[99] <= encrypted_data[31:0];
                end
                6'd34:
                begin
                    csr_registers[100] <= encrypted_data[63:32];
                    csr_registers[101] <= encrypted_data[31:0];
                end
                6'd35:
                begin
                    csr_registers[102] <= encrypted_data[63:32];
                    csr_registers[103] <= encrypted_data[31:0];
                end
                6'd36:
                begin
                    csr_registers[104] <= encrypted_data[63:32];
                    csr_registers[105] <= encrypted_data[31:0];
                end
                6'd37:
                begin
                    csr_registers[106] <= encrypted_data[63:32];
                    csr_registers[107] <= encrypted_data[31:0];
                end
                6'd38:
                begin
                    csr_registers[108] <= encrypted_data[63:32];
                    csr_registers[109] <= encrypted_data[31:0];
                end
                6'd39:
                begin
                    csr_registers[110] <= encrypted_data[63:32];
                    csr_registers[111] <= encrypted_data[31:0];
                end
                6'd40:
                begin
                    csr_registers[112] <= encrypted_data[63:32];
                    csr_registers[113] <= encrypted_data[31:0];
                end
                6'd41:
                begin
                    csr_registers[114] <= encrypted_data[63:32];
                    csr_registers[115] <= encrypted_data[31:0];
                end
                6'd42:
                begin
                    csr_registers[116] <= encrypted_data[63:32];
                    csr_registers[117] <= encrypted_data[31:0];
                end
                6'd43:
                begin
                    csr_registers[118] <= encrypted_data[63:32];
                    csr_registers[119] <= encrypted_data[31:0];
                end
                6'd44:
                begin
                    csr_registers[120] <= encrypted_data[63:32];
                    csr_registers[121] <= encrypted_data[31:0];
                end
                6'd45:
                begin
                    csr_registers[122] <= encrypted_data[63:32];
                    csr_registers[123] <= encrypted_data[31:0];
                end
                6'd46:
                begin
                    csr_registers[124] <= encrypted_data[63:32];
                    csr_registers[125] <= encrypted_data[31:0];
                end
                6'd47:
                begin
                    csr_registers[126] <= encrypted_data[63:32];
                    csr_registers[127] <= encrypted_data[31:0];
                end
                6'd48:
                begin
                    csr_registers[128] <= encrypted_data[63:32];
                    csr_registers[129] <= encrypted_data[31:0];
                end
                6'd49:
                begin
                    csr_registers[130] <= encrypted_data[63:32];
                    csr_registers[131] <= encrypted_data[31:0];
                end
            endcase

            count <= count + 1;
        end
        else if(csr_registers[0][2])
        begin         
            count <= 10'd0;
        end

        // READ/WRITE
        if(slave_write && slave_chipselect && (slave_address >= 0) && (slave_address < NUMREGS))
        begin
           csr_registers[slave_address] <= slave_writedata;  // Write a value to a CSR register
        end
        else if(slave_read && slave_chipselect  && (slave_address >= 0) && (slave_address < NUMREGS)) // reading a CSR Register
        begin
            // Send a value being requested by a master. 
            // If the computation is small you may compute directly and send it out to the master directly from here.
            slave_readdata <= csr_registers[slave_address];
        end
    end
end

always_comb 
begin
    next_actual_data = actual_data;
    if (count2)
    begin
        next_actual_data = raw_data;
    end 
end

// DUT
ECCDH3DES ECC
(
    .clk(clk),
    .n_rst(reset_n),

    // INPUT
    .raw_data(actual_data),
    .encrypted_data(encrypted_data),
    .PX({csr_registers[13], csr_registers[14], csr_registers[15], csr_registers[16], csr_registers[17], csr_registers[18][31:28]}),
    .PY({csr_registers[7], csr_registers[8], csr_registers[9], csr_registers[10], csr_registers[11], csr_registers[12][31:28]}),
    .k({csr_registers[1], csr_registers[2], csr_registers[3], csr_registers[4], csr_registers[5], csr_registers[6][31:28]}),
    .ecc1_start(csr_registers[0][0]),
    .ecc2_start(csr_registers[0][1]),
    .des_start(csr_registers[0][2]),

    // OUTPUT
    .ecc1_done(next_ecc1_done),
    .ecc2_done(next_ecc2_done),
    //.des_done(next_des_done),
    
    .data_valid_in(csr_registers[0][0]),
    .data_valid_out(next_des_done),
    .PuX(PuX),
    .PuY(PuY)
);

endmodule 