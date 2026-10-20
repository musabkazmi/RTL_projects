module main_FSM (
    input  logic       clk,
    input  logic       reset,
    input  logic [6:0] op,

    output logic       Branch,
    output logic       PCUpdate,
    output logic       RegWrite,
    output logic       MemWrite,
    output logic       IRWrite,
    output logic [1:0] ResultSrc,
    output logic [1:0] ALUSrcB,
    output logic [1:0] ALUSrcA,
    output logic       AdrSrc,
    output logic [1:0] ALUOp
);

    typedef enum logic [3:0] {
        S_FETCH,
        S_DECODE,
        S_MEMADR,
        S_MEMREAD,
        S_MEMWB,
        S_MEMWRITE,
        S_EXECUTER,
        S_EXECUTEI,
        S_ALUWB,
        S_BEQ,
        S_JAL
    } state_t;

    state_t state, state_next;

    // opcodes
    localparam logic [6:0] OP_LW   = 7'b0000011;
    localparam logic [6:0] OP_SW   = 7'b0100011;
    localparam logic [6:0] OP_RTYPE= 7'b0110011; // add, sub
    localparam logic [6:0] OP_ITYPE= 7'b0010011; // addi
    localparam logic [6:0] OP_BEQ  = 7'b1100011;
    localparam logic [6:0] OP_JAL  = 7'b1101111;

    // state register
    always_ff @(posedge clk or posedge reset)
        if (reset) state <= S_FETCH;
        else       state <= state_next;

    // next-state logic and Moore outputs
    always_comb begin
        // defaults
        state_next = S_FETCH;
        Branch     = 1'b0;
        PCUpdate   = 1'b0;
        RegWrite   = 1'b0;
        MemWrite   = 1'b0;
        IRWrite    = 1'b0;
        ResultSrc  = 2'b00;
        ALUSrcA    = 2'b00;
        ALUSrcB    = 2'b00;
        ALUOp      = 2'b00;
        AdrSrc     = 1'b0;

        case (state)
            S_FETCH: begin
                AdrSrc     = 1'b0;
                IRWrite    = 1'b1;
                ALUSrcA    = 2'b00;
                ALUSrcB    = 2'b10;
                ALUOp      = 2'b00;
                ResultSrc  = 2'b10;
                PCUpdate   = 1'b1;
                state_next = S_DECODE;
            end

            S_DECODE: begin
                // precompute branch/jal target: OldPC + ImmExt
                ALUSrcA = 2'b01;
                ALUSrcB = 2'b01;
                ALUOp   = 2'b00;
                case (op)
                    OP_LW,
                    OP_SW:    state_next = S_MEMADR;
                    OP_RTYPE: state_next = S_EXECUTER;
                    OP_ITYPE: state_next = S_EXECUTEI;
                    OP_JAL:   state_next = S_JAL;
                    OP_BEQ:   state_next = S_BEQ;
                    default:  state_next = S_FETCH;
                endcase
            end

            S_MEMADR: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b01;
                ALUOp   = 2'b00;
                case (op)
                    OP_LW:   state_next = S_MEMREAD;
                    OP_SW:   state_next = S_MEMWRITE;
                    default: state_next = S_FETCH;
                endcase
            end

            S_MEMREAD: begin
                ResultSrc  = 2'b00;
                AdrSrc     = 1'b1;
                state_next = S_MEMWB;
            end

            S_MEMWB: begin
                ResultSrc  = 2'b01;
                RegWrite   = 1'b1;
                state_next = S_FETCH;
            end

            S_MEMWRITE: begin
                ResultSrc  = 2'b00;
                AdrSrc     = 1'b1;
                MemWrite   = 1'b1;
                state_next = S_FETCH;
            end

            S_EXECUTER: begin
                ALUSrcA    = 2'b10;
                ALUSrcB    = 2'b00;
                ALUOp      = 2'b10;
                state_next = S_ALUWB;
            end

            S_EXECUTEI: begin
                ALUSrcA    = 2'b10;
                ALUSrcB    = 2'b01;
                ALUOp      = 2'b10;
                state_next = S_ALUWB;
            end

            S_ALUWB: begin
                ResultSrc  = 2'b00;
                RegWrite   = 1'b1;
                state_next = S_FETCH;
            end

            S_BEQ: begin
                ALUSrcA    = 2'b10;
                ALUSrcB    = 2'b00;
                ALUOp      = 2'b01;
                ResultSrc  = 2'b00;
                Branch     = 1'b1;
                state_next = S_FETCH;
            end

            S_JAL: begin
                ALUSrcA    = 2'b01;
                ALUSrcB    = 2'b10;
                ALUOp      = 2'b00;
                ResultSrc  = 2'b00;
                PCUpdate   = 1'b1;
                state_next = S_ALUWB;
            end

            default: state_next = S_FETCH;
        endcase
    end

endmodule
