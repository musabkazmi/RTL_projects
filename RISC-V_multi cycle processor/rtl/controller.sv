// Code your design here

module controller (
    input  logic       clk,
    input  logic       reset,

    // from the instruction register
    input  logic [6:0] op,          // Instr[6:0]
    input  logic [2:0] funct3,      // Instr[14:12]
    input  logic       funct7_5,    // Instr[30]

    // from the datapath
    input  logic       Zero,

    // to the datapath
    output logic       PCWrite,
    output logic       RegWrite,
    output logic       MemWrite,
    output logic       IRWrite,
    output logic       AdrSrc,
    output logic [1:0] ResultSrc,
    output logic [1:0] ALUSrcA,
    output logic [1:0] ALUSrcB,
    output logic [1:0] ImmSrc,
    output logic [2:0] ALUControl
);

    // internal signals
    logic       Branch;
    logic       PCUpdate;
    logic [1:0] ALUOp;

    // Main FSM
    main_FSM fsm (
        .clk       (clk),
        .reset     (reset),
        .op        (op),
        .Branch    (Branch),
        .PCUpdate  (PCUpdate),
        .RegWrite  (RegWrite),
        .MemWrite  (MemWrite),
        .IRWrite   (IRWrite),
        .ResultSrc (ResultSrc),
        .ALUSrcB   (ALUSrcB),
        .ALUSrcA   (ALUSrcA),
        .AdrSrc    (AdrSrc),
        .ALUOp     (ALUOp)
    );

    // ALU Decoder (op5 is bit 5 of the opcode, the "5" wire in the figure)
    alu_decoder aludec (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .op5        (op[5]),
        .funct7_5   (funct7_5),
        .ALUControl (ALUControl)
    );

    // Instruction Decoder
    instr_decoder instrdec (
        .op     (op),
        .ImmSrc (ImmSrc)
    );

    // PCWrite = (Branch & Zero) | PCUpdate
    assign PCWrite = (Branch & Zero) | PCUpdate;

endmodule
