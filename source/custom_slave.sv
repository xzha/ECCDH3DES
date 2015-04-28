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
    parameter NUMCOUNT = 10,
    parameter QUEUESIZE = 50,
    parameter ADDRSIZE = 14,
    parameter SRAMWIDTH = 64
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


typedef enum {IDLE, WRITE_INPUT, READ_INPUT_START, READ_INPUT, WRITE_OUTPUT, READ_OUTPUT_START, READ_OUTPUT } state_t;
state_t state, nextState;


// CONSTANTS
parameter START_BYTE = 32'hF00BF00B;
parameter STOP_BYTE = 32'hDEADF00B;
parameter SRAM_ADDR = 32'h0;
parameter SRAM_ADDR2 = 32'h0;

// GIVEN
logic [NUMREGS-1:0][REGWIDTH-1:0] csr_registers;        // Command and Status Registers (CSR) for custom logic

// ECC
logic [163:0] PuX;
logic [163:0] PuY;

logic ecc1_done;
logic ecc2_done; 
logic des_done; 
logic data_valid_out, data_valid_in;

logic next_ecc1_done;
logic next_ecc2_done; 
logic next_des_done; 
logic next_des_done_old; 
logic masterReadSRAM;

logic [63:0] encrypted_data;

logic [NUMCOUNT: 0] count;

//logic [ADDRESSWIDTH-1:0] read_address1, write_address1, read_address2, write_address2, next_read_address1, next_write_address1, next_read_address2, next_write_address2;
logic [ADDRSIZE-1:0] sram_Addr1, sram_Addr2, next_sram_Addr2, next_sram_Addr1;
logic [SRAMWIDTH-1:0] input_data1, output_data1, next_input_data2, input_data2, output_data2;
logic sramRE1, sramWE1, sramRE2, sramWE2;

logic [31:0] partial_data;
logic [31:0] next_raw_data;
logic [63:0] raw_data;

logic [63:0] next_actual_data;
logic [63:0] actual_data;
logic count2;
logic next_data_written, data_written, next_data_encrypted, data_encrypted, copyData;

logic [7:0] fifo_used;
logic next_fifo_full, fifo_full, next_fifo_empty, fifo_empty, next_fifo_almost_full, fifo_almost_full;
logic [31:0] next_fifo_output, fifo_output;

// Slave side 
always_ff @ ( posedge clk ) begin 
  if(!reset_n)
    begin
        slave_readdata <= 32'h0;
        csr_registers <= '0;

        //head_count <= 10'd0;
        //tail_count <= 10'd0;
        //next_head_count <= 10'd1;
        count2 <= '0;
        /*read_address1 <= SRAM_ADDR;
        write_address1 <= SRAM_ADDR;
        read_address2 <= SRAM_ADDR2;
        write_address2 <= SRAM_ADDR2;*/
        sram_Addr1 <= SRAM_ADDR;
        sram_Addr2 <= SRAM_ADDR2;
        input_data2 <= 0;
        data_written <= 0;
        data_encrypted <= 0;

    end else begin


        // OUTPUT SIGNAL
        ecc1_done <= next_ecc1_done;
        ecc2_done <= next_ecc2_done;
        des_done <= next_des_done;
        fifo_full <= next_fifo_full;
        fifo_empty <= next_fifo_empty;
        fifo_almost_full <= next_fifo_almost_full;
        fifo_output <= next_fifo_output;

        csr_registers[0][31] <= next_ecc1_done;
        csr_registers[0][30] <= next_ecc2_done;
        csr_registers[0][29] <= next_des_done;

        csr_registers[0][28] <= fifo_full ; //queue_full;
        csr_registers[0][27] <= fifo_empty; //queue_empty;
        csr_registers[0][26] <= fifo_almost_full;
        csr_registers[100] <= fifo_output;
        sram_Addr1 <= next_sram_Addr1;
        sram_Addr2 <= next_sram_Addr2;
        input_data2 <= next_input_data2;



        /*read_address1 <= next_read_address1;
        write_address1 <= next_write_address1;
        read_address2 <= next_read_address1;
        write_address2 <= next_write_address2;*/

        sram_Addr1 <= next_sram_Addr1;
        sram_Addr2 <= next_sram_Addr2;
        //data_encrypted <= next_data_encrypted;
        //data_written <= next_data_written;
        csr_registers[38][31] <= next_data_encrypted;
        csr_registers[38][0] <= masterReadSRAM;

        if(copyData)
        begin
            csr_registers[39] <= output_data2[31:0];
            csr_registers[40] <= output_data2[63:32];
        end

        // BUFFER FOR DES
        //partial_data <= csr_registers[19];
        //next_raw_data <= partial_data;
        //raw_data <= {next_raw_data, partial_data};
        actual_data <= output_data1;// next_actual_data;

        if(next_data_written)
        begin
            csr_registers[35][0] <= 0;
            csr_registers[35][31] <= 1;
        end
       
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
    /*next_actual_data = actual_data;
    if (count2)
    begin
        next_actual_data = raw_data;
    end  
*/
    if (des_done) 
    begin
    end
end



// Next State Logic 
// If user wants to input data and addresses using a state machine instead of signals/conditions,
// the following code has commented lines for how this could be done.
always_comb begin 
    nextState = state;
    next_sram_Addr1 = sram_Addr1;
    next_sram_Addr2 = sram_Addr2;
    //nextData = wr_data;
    next_data_written = 0;
    sramWE1 = 0;
    sramRE1 = 0;
    data_valid_in = 0;
    next_input_data2 = input_data2;
    next_data_encrypted = data_encrypted;
    masterReadSRAM = 0;
    copyData = 0;
    case( state ) 
        IDLE : begin 
            if ( csr_registers[35][0]) begin 
                input_data1 = {csr_registers[37], csr_registers[36]};
                nextState = WRITE_INPUT;
                //nextData = wr_data;
            end else if ( csr_registers[0][2]) begin 
                nextState = READ_INPUT_START;               
                //next_input_data2 = encrypted_data;
            
            //end else if ((sram_Addr2 - SRAM_ADDR2) == csr_registers[41] && des_start) begin
            end else if(data_encrypted && (csr_registers[31][0] == 0)) begin
                masterReadSRAM = 1;
                nextState = READ_OUTPUT;

            end else if ( data_valid_out ) begin 
                nextState = WRITE_OUTPUT;
                next_input_data2 = encrypted_data;              
                //next_input_data2 = encrypted_data;
            //end else if ( des_start) begin 
                //nextState = READ_START;               
                //next_input_data2 = encrypted_data;
            end
        end 
        READ_INPUT_START: begin
                nextState = READ_INPUT;
                sramRE1 = 1;
                //next_sram_Addr1 = sram_Addr1 - 1;
        end 
        READ_INPUT: begin
                if(next_sram_Addr1 == SRAM_ADDR)
                begin
                    next_sram_Addr1 = SRAM_ADDR;
                    nextState = IDLE;
                end 
                else
                begin
                    nextState = READ_INPUT;
                    sramRE1 = 1;
                    data_valid_in = 1;
                    next_sram_Addr1 = sram_Addr1 - 1;
                end
        end 
        WRITE_INPUT: begin
                next_sram_Addr1 = sram_Addr1 + 1;
                nextState = IDLE;
                sramWE1 = 1;
                next_data_written = 1;
            end
        WRITE_OUTPUT: begin
            next_sram_Addr2 = sram_Addr2 + 1;
            next_input_data2 = encrypted_data;
            sramWE2 = 1;
            if ( data_valid_out )  
                nextState = WRITE_OUTPUT;   
            else
            begin
                nextState = IDLE;
                if ((sram_Addr2 - SRAM_ADDR2) >= csr_registers[41]) 
                begin
                    nextState = READ_OUTPUT_START;
                end
            end        
        end
        READ_OUTPUT_START: begin
            copyData = 1;
            sramRE2 = 1;
            next_sram_Addr2 = sram_Addr2 - 1;
            next_data_encrypted = 1;
            nextState = READ_OUTPUT;
            masterReadSRAM = 1;
        end
        READ_OUTPUT: begin
            if(csr_registers[38][0] == 1)
            begin
                nextState = READ_OUTPUT;
            end
            else
            begin
                next_sram_Addr2 = sram_Addr2 - 1;
                next_data_encrypted = 1;
                sramRE2 = 1;
                copyData = 1;
                masterReadSRAM = 1;
                nextState = READ_OUTPUT;
                if(next_sram_Addr2 == SRAM_ADDR2)
                    nextState = IDLE;
                //masterReadSRAM = 1;
            end
        end
        
    endcase
end

//Current change to test code
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
    .des_done(next_des_done_old),
    
    .data_valid_in(data_valid_in),
    .data_valid_out(next_des_done),
    .PuX(PuX),
    .PuY(PuY)
);

sram    sram_inst1 (
    .clock ( clk ),
    .data ( input_data1 ),
    .rdaddress ( sram_Addr1 ),
    .rden ( sramRE1 ),
    .wraddress ( sram_Addr1 ),
    .wren ( sramWE1 ),
    .q ( output_data1 )
    );

sram    sram_inst2 (
    .clock ( clk ),
    .data ( input_data2 ),
    .rdaddress ( sram_Addr2 ),
    .rden ( sramRE2 ),
    .wraddress ( sram_Addr2 ),
    .wren ( sramWE2 ),
    .q ( output_data2 )
    );


endmodule 