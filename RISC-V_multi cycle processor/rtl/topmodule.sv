module top (input logic clk, reset);
    logic [6:0] op; logic [2:0] funct3; logic funct7_5, Zero;
    logic PCWrite, RegWrite, MemWrite, IRWrite, AdrSrc;
    logic [1:0] ResultSrc, ALUSrcA, ALUSrcB, ImmSrc; logic [2:0] ALUControl;
    logic [31:0] Result;
    controller c (.clk, .reset, .op, .funct3, .funct7_5, .Zero,
                  .PCWrite, .RegWrite, .MemWrite, .IRWrite, .AdrSrc,
                  .ResultSrc, .ALUSrcA, .ALUSrcB, .ImmSrc, .ALUControl);
    multi_cycle_datapath dp (.clk, .reset, .PCWrite, .AdrSrc, .MemWrite, .IRWrite, .RegWrite,
                  .ImmSrc, .ALUSrcA, .ALUSrcB, .ALUControl, .ResultSrc, .Zero, .Result,
                  .op, .funct3, .funct7_5);
endmodule
