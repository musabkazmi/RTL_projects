module instr_decoder (
    input  logic [6:0] op,
    output logic [1:0] ImmSrc
);

    always_comb begin
        case (op)
            7'b0000011: ImmSrc = 2'b00;  // lw      (I-type)
            7'b0010011: ImmSrc = 2'b00;  // addi    (I-type ALU)
            7'b0100011: ImmSrc = 2'b01;  // sw      (S-type)
            7'b1100011: ImmSrc = 2'b10;  // beq     (B-type)
            7'b1101111: ImmSrc = 2'b11;  // jal     (J-type)
            7'b0110011: ImmSrc = 2'bxx;  // R-type  (don't care)
            default:    ImmSrc = 2'bxx;  // unsupported opcode
        endcase
    end

endmodule
