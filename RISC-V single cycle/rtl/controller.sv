

// ----------------------------------
`include "main_decoder"
`include "alu_decoder"

// ===========Main controller ===========-------------------
module controller (
    input  logic [6:0] op,          // Instr[6:0]
    input  logic [2:0] funct3,      // Instr[14:12]
    input  logic       funct7_5,    // Instr[30]
    input  logic       Zero,        // ALU zero flag, from the datapath
    output logic       RegWrite,
    output logic [1:0] ImmSrc,
    output logic       ALUSrc,
    output logic       MemWrite,
    output logic       ResultSrc,
    output logic       PCSrc,
    output logic [2:0] ALUControl
);

    // Internal signals: never leave the controller
    logic       Branch;
    logic [1:0] ALUOp;

    main_decoder md (
        .op        (op),
        .RegWrite  (RegWrite),
        .ImmSrc    (ImmSrc),
        .ALUSrc    (ALUSrc),
        .MemWrite  (MemWrite),
        .ResultSrc (ResultSrc),
        .Branch    (Branch),
        .ALUOp     (ALUOp)
    );

    alu_decoder ad (
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .op5        (op[5]),
        .funct7_5   (funct7_5),
        .ALUControl (ALUControl)
    );

    // Take the branch only if this is a branch AND the ALU says the operands are equal
    assign PCSrc = Branch & Zero;

endmodule
