module alu_decoder (
    input  logic [1:0] ALUOp,
    input  logic [2:0] funct3,
    input  logic       op5,        // Instr[5]
    input  logic       funct7_5,   // Instr[30]
    output logic [2:0] ALUControl
);

    always_comb begin
        ALUControl = 3'bxxx;               // default: unsupported combination

        case (ALUOp)
            2'b00: ALUControl = 3'b000;    // lw/sw: add
            2'b01: ALUControl = 3'b001;    // beq: subtract

            2'b10: begin                   // R-type: look inside the instruction
                case (funct3)
                    3'b000: begin
                        if ({op5, funct7_5} == 2'b11)
                            ALUControl = 3'b001;   // sub
                        else
                            ALUControl = 3'b000;   // add
                    end
                    3'b010: ALUControl = 3'b101;   // slt
                    3'b110: ALUControl = 3'b011;   // or
                    3'b111: ALUControl = 3'b010;   // and
                    default: ALUControl = 3'bxxx;
                endcase
            end

            default: ALUControl = 3'bxxx;
        endcase
    end

endmodule
