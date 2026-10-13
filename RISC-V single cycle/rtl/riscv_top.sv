// Code your design here
`include "controller"
`include "data_path"
module riscv_top (
    input  logic        clk,
    input  logic        rst,

    // observation / verification
    output logic [31:0] PC,
    output logic [31:0] Instr,
    output logic [31:0] ALUResult,
    output logic [31:0] WriteData,
    output logic [31:0] ReadData,
    output logic [31:0] Result
);

    // Controller -> datapath
    logic       PCSrc, RegWrite, ALUSrc, MemWrite, ResultSrc;
    logic [1:0] ImmSrc;
    logic [2:0] ALUControl;

    // Datapath -> controller
    logic       Zero;

    controller u_ctrl (
        .op         (Instr[6:0]),
        .funct3     (Instr[14:12]),
        .funct7_5   (Instr[30]),
        .Zero       (Zero),
        .RegWrite   (RegWrite),
        .ImmSrc     (ImmSrc),
        .ALUSrc     (ALUSrc),
        .MemWrite   (MemWrite),
        .ResultSrc  (ResultSrc),
        .PCSrc      (PCSrc),
        .ALUControl (ALUControl)
    );

    riscv_datapath u_dp (
        .clk        (clk),
        .rst        (rst),
        .PCSrc      (PCSrc),
        .RegWrite   (RegWrite),
        .ImmSrc     (ImmSrc),
        .ALUSrc     (ALUSrc),
        .ALUControl (ALUControl),
        .MemWrite   (MemWrite),
        .ResultSrc  (ResultSrc),
        .Instr      (Instr),
        .Zero       (Zero),
        .PC         (PC),
        .ALUResult  (ALUResult),
        .WriteData  (WriteData),
        .ReadData   (ReadData),
        .Result     (Result)
    );

endmodule
