// $Id: $
// File name:   gf_Mult.sv
// Created:     3/18/2015
// Author:      Manish Gupta
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Galoid Field Multiplication

module gf_Mult
#(
  parameter NUM_BITS = 163
 )
(
  input wire clk, 
  input wire n_rst,
  input wire start,
  input wire [NUM_BITS:0] A,
  input wire [NUM_BITS:0] B,
  output reg [NUM_BITS:0] Product,
  output reg done
);



typedef enum logic [4:0] {IDLE, GETDATA, CALC, DONE} state_type;
state_type state, nextstate;

reg [(NUM_BITS * 2): 0]next_product, product;
reg [(NUM_BITS * 2): 0]midVal, next_midVal;
reg [(NUM_BITS): 0]midValB, next_midValB;
reg [8:0]count_out;
reg [8:0]count, next_count;
reg next_clear, clear, next_ready, ready, count_done;
//logic [NUM_BITS:0] poly;
//assign poly = 9'b100011011; //For easy 8 poly
//assign poly = {1'b1, 155'b0, 1'b1, 1'b1, 2'b0, 1'b1, 2'b0, 1'b1}; //For the proper 163 poly  163,7,6,3,0

always_ff @(posedge clk, negedge n_rst)
begin: StateReg
if(n_rst == 0)
  begin
    state <= IDLE;
    clear <= 1;
    ready <= 0;
    product <= 0;
    midVal <= 0;
    midValB <= 0;
    count <= 0;
  end
  else 
  begin
    state <= nextstate;
    clear <= next_clear;
    ready <= next_ready;
    product <= next_product;
    midVal <= next_midVal;
    midValB <= next_midValB;
    count <= next_count;
  end
end 

//flex_counter #(9) count1(.clk(clk), .n_rst(n_rst), .clear(count_done | clear), .count_out(count_out), .count_enable(ready), .rollover_val(9'd162), .rollover_flag(count_done));

integer i;
always_comb
begin
  next_midVal = midVal;
  next_midValB = midValB;
  next_count = count;
  //next_midVal = A & {NUM_BITS {B[count_out]}};
  //next_midVal = midVal << count_out;
  //next_clear = clear;
  //next_ready = ready;
  next_product = product;
  done = 0;
  nextstate = state;
  case(state)
      IDLE: begin
        next_count = 0;
        //next_clear = 1;
        
        if(start == 1)
        begin
          next_product = 0;
          nextstate = GETDATA;
          //next_ready = 1;
          //next_clear = 0;
        end       
        else
          nextstate = IDLE;
      end
      GETDATA: begin
          nextstate = CALC;
          next_midVal = A;
          next_midValB = B;

      end
      CALC: begin
          next_count = count + 1;
          //next_ready = 1;
          //next_clear = 0;
          next_product = product ^ (midVal  & {(2*NUM_BITS) {midValB[0]}});
          next_midVal = midVal << 1;
          next_midValB = midValB >> 1;
          nextstate = CALC;          
          if(count == 162)
          begin
            nextstate = DONE;
            //next_ready = 0;
          end
      end
      DONE: begin
          next_count = 0;
          //next_clear = 1;
          //next_ready = 0;
          nextstate = IDLE;
          done = 1;
      end
  endcase
  //for(i = 0; i < NUM_BITS; i++)
  //begin
    //midVal[i+:NUM_BITS] = A & {NUM_BITS {B[count_out]}};
    //product = product ^ midVal;
    //midVal = 0;
  //end
end

//midVal[i+:NUM_BITS] = A & {NUM_BITS {B[count_out]}};
//product = product ^ midVal;

gf_Mod MOD(.poly({25'b0, product}), .rr_poly(Product));

endmodule
