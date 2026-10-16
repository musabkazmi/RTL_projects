// Code your design here
// Code your design here
module register_file #(parameter DATA_WIDTH = 32,
parameter NUM_REGS   = 32)
  (input logic clk,
input logic we3,
   input logic [$clog2(NUM_REGS ) -1:0] a1, a2, a3,
   input logic [DATA_WIDTH -1:0] wd3,
   output logic [DATA_WIDTH  -1 :0] rd1, rd2);
  
  logic [DATA_WIDTH -1:0] rf[NUM_REGS- 1:0];
// three ported register file
// read two ports combinationally (A1/RD1, A2/RD2)
// write third port on rising edge of clock (A3/WD3/WE3)
// register 0 hardwired to 0
always_ff @(posedge clk)
if (we3) rf[a3] <= wd3;
assign rd1 = (a1 != 0) ? rf[a1] : 0;
assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule
