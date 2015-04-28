// File name : custom_slave.sv
// Author : Ishaan Biswas
// Created : 03/29/2015
// Version 1.0 
// Description : Demo example to illustrate slave interface usage


module custom_master_slave #(
    parameter MASTER_ADDRESSWIDTH = 26 ,    // ADDRESSWIDTH specifies how many addresses the Master can address 
    parameter SLAVE_ADDRESSWIDTH = 8 ,      // ADDRESSWIDTH specifies how many addresses the slave needs to be mapped to. log(NUMREGS)
    parameter DATAWIDTH = 32,          // DATAWIDTH specifies the data width. Default 32 bits
    parameter NUMREGS = 256,              // Number of Internal Registers for Custom Logic
    parameter REGWIDTH = 32,            // Data Width for the Internal Registers. Default 32 bits
    parameter NUMCOUNT = 10,
    parameter QUEUESIZE = 50
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
parameter SDRAM_ADDR = 32'h08000000;


parameter READ_BYTE = 32'hF00BF00B;
parameter WRITE_BYTE = 32'hDEADF00B;

// GIVEN
logic [NUMREGS-1:0][REGWIDTH-1:0] csr_registers;        // Command and Status Registers (CSR) for custom logic
logic [MASTER_ADDRESSWIDTH-1:0] address, nextAddress, finalAddress, nextfinalAddress;
logic [DATAWIDTH-1:0] nextRead_data, read_data;
logic [DATAWIDTH-1:0] nextData, wr_data;
logic [NUMREGS-1:0] reg_index, nextRegIndex;
logic [NUMREGS-1:0][REGWIDTH-1:0] read_data_registers;  //Store SDRAM read data for display
logic new_data_flag;
logic des_start;

typedef enum {IDLE, WRITE, WRITE_WAIT, READ_REQ, READ_WAIT, READ_ACK, READ_DATA, READ_REQ2, READ_DATA2 } state_t;
state_t state, nextState;


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
logic next_des_done_old; 

logic [63:0] encrypted_data;

logic [NUMCOUNT: 0] count;
logic [NUMCOUNT: 0] head_count;
logic [NUMCOUNT: 0] head_count_next;
logic [NUMCOUNT: 0] next_head_count_next;
logic [NUMCOUNT: 0] next_head_count;
logic [NUMCOUNT: 0] tail_count;
logic [NUMCOUNT: 0] next_tail_count;
logic queue_full;
logic queue_empty;

logic [31:0] partial_data;
logic [31:0] next_raw_data;
logic [63:0] raw_data;

logic [63:0] next_actual_data;
logic [63:0] actual_data;
logic [1:0]count2;

logic [7:0] fifo_used;
logic next_fifo_full, fifo_full, next_fifo_empty, fifo_empty, next_fifo_almost_full, fifo_almost_full;
logic [31:0] next_fifo_output, fifo_output;

assign queue_empty = (head_count == tail_count);
assign queue_full = (next_head_count == tail_count);
// Slave side 
always_ff @ ( posedge clk ) begin 
  if(!reset_n)
    begin
        slave_readdata <= 32'h0;
        csr_registers <= '0;

        head_count <= 10'd0;
        tail_count <= 10'd0;
        next_head_count <= 10'd1;
        count2 <= '0;
        
    end else begin


        head_count <= head_count_next;
        next_head_count <= next_head_count_next;
        tail_count <= next_tail_count;
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



        // BUFFER FOR DES
        if(new_data_flag)
        begin
            partial_data <= nextRead_data;
            next_raw_data <= partial_data;
            raw_data <= {next_raw_data, partial_data};
            actual_data <= next_actual_data;
            count2 = count2 + 1;
        end
        else
        begin
            if(count2 >= 2'h2)
                count2 = 0;
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

        // OUTPUT DES
        /*if (des_done) 
        begin
            
          */

            /*head_count <= head_count + 1;
            if(head_count >= QUEUESIZE)
            begin
                head_count = 0;
            end
            next_head_count = head_count + 1;
            if(next_head_count >= QUEUESIZE)
            begin
                next_head_count = 0;
            end

        end*/
        /*else if(csr_registers[0][2])
        begin         
            count2 = count2 + 1;
        end*/
        /*if(csr_registers[0][26])
        begin
            csr_registers[200] <= csr_registers[tail_count+32];
            tail_count = tail_count + 1;
            if(tail_count >= QUEUESIZE)
                tail_count = 0;
        end*/
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
    if (count2 == 2)
    begin
        next_actual_data = raw_data;
    end  

    /*head_count_next = head_count;
    next_head_count_next = next_head_count;
    next_tail_count = tail_count;
    if (des_done) 
        begin
        head_count_next = head_count + 1;
        if(head_count_next >= QUEUESIZE)
        begin
            head_count_next = 0;
        end
        next_head_count_next = head_count_next + 1;
        if(next_head_count_next >= QUEUESIZE)
        begin
            next_head_count_next = 0;
        end
    end
    if(csr_registers[0][26])
    begin
        next_tail_count = tail_count + 1;
        if(next_tail_count >= QUEUESIZE)
            next_tail_count = 0;
    end*/
end



// Master Side 

always_ff @ ( posedge clk ) begin 
    if (!reset_n) begin 
        address <= SDRAM_ADDR;
        reg_index <= 0;
        state <= IDLE;
        wr_data <= 0 ;
        read_data <= 32'hFEEDFEED; 
        read_data_registers <= '0;
        finalAddress <= SDRAM_ADDR;
    end else begin 
        state <= nextState;
        address <= nextAddress;
        reg_index <= nextRegIndex;
        wr_data <= nextData;
        finalAddress <= nextfinalAddress;
        //read_data <= nextRead_data;
        if(new_data_flag)
            read_data_registers[reg_index] <= nextRead_data;
    end
end



// Next State Logic 
// If user wants to input data and addresses using a state machine instead of signals/conditions,
// the following code has commented lines for how this could be done.
always_comb begin 
    nextState = state;
    nextAddress = address;
    nextRegIndex = reg_index;
    //nextData = wr_data;
    nextRead_data = master_readdata;
    new_data_flag = 0;
    nextfinalAddress = finalAddress;
    case( state ) 
        IDLE : begin 
            if ( csr_registers[34] == WRITE_BYTE && reg_index < NUMREGS) begin 
                nextState = WRITE;
                //nextData = wr_data;
            end else if ( csr_registers[33] == READ_BYTE && address >= SDRAM_ADDR && fifo_almost_full != 1) begin 
                nextState = READ_REQ;               
                nextfinalAddress = {csr_registers[35], csr_registers[36], csr_registers[37], csr_registers[38]};
            end
        end 
        WRITE: begin
            if (!master_waitrequest) begin 
                nextRegIndex = reg_index + 1;
                nextAddress = address + 4;
                nextState = IDLE;
            end
        end 
        READ_REQ : begin 
            if (!master_waitrequest) begin
                nextState = READ_DATA;
                nextAddress = finalAddress ; 
                nextRegIndex = reg_index - 1;
            end
        end
        READ_DATA : begin
            if ( master_readdatavalid) begin
                nextRead_data = master_readdata;
                nextState = READ_REQ2;
                new_data_flag = 1;
            end
        end
        READ_REQ2 : begin 
            if (!master_waitrequest) begin
                nextState = READ_DATA2;
                nextAddress = address - 4 ; 
                nextRegIndex = reg_index - 1;
            end
        end
        READ_DATA2 : begin
            if ( master_readdatavalid) begin
                nextRead_data = master_readdata;
                nextState = IDLE;
                if(fifo_almost_full)
                    nextState = IDLE;
                else if( address > SDRAM_ADDR)//csr_registers[33] == READ_BYTE )
                begin
                    nextState = READ_REQ;
                    nextfinalAddress = address - 4;
                end
                new_data_flag = 1;
            end
        end
    endcase
end

// Output Logic 

always_comb begin 
    master_write = 1'b0;
    master_read = 1'b0;
    master_writedata = 32'h0;
    master_address = 32'hbad1bad1;
    case(state) 
        WRITE : begin 
            master_write = 1;
            master_address =  address;
            master_writedata = csr_registers[reg_index];
        end 
        READ_REQ : begin 
            master_address = address;
            master_read = 1;    
        end
        READ_REQ2 : begin 
            master_address = address;
            master_read = 1;    
        end
    endcase
end

assign des_start = (state == READ_DATA2);
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
    .des_start(des_start), //csr_registers[0][2]),

    // OUTPUT
    .ecc1_done(next_ecc1_done),
    .ecc2_done(next_ecc2_done),
    .des_done(next_des_done_old),
    
    .data_valid_in(csr_registers[0][2]),
    .data_valid_out(next_des_done),
    .PuX(PuX),
    .PuY(PuY)
);

fifo fifo_inst (
    .aclr ( reset_n ),
    .clock ( clk ),
    .data ( encrypted_data ),
    .rdreq ( csr_registers[0][26] ),
    .sclr ( 0 ),
    .wrreq ( des_done ),
    .almost_full ( next_fifo_almost_full ),
    .empty ( next_fifo_empty ),
    .full ( next_fifo_full ),
    .q ( next_fifo_output ),
    .usedw ( fifo_used )
    );


endmodule 