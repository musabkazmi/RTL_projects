module controller_tb;

    // DUT inputs
    logic [6:0] op;
    logic [2:0] funct3;
    logic       funct7_5;
    logic       Zero;

    // DUT outputs
    logic       RegWrite;
    logic [1:0] ImmSrc;
    logic       ALUSrc;
    logic       MemWrite;
    logic       ResultSrc;
    logic       PCSrc;
    logic [2:0] ALUControl;

    // All outputs packed into one vector:
    // {RegWrite, ImmSrc[1:0], ALUSrc, MemWrite, ResultSrc, PCSrc, ALUControl[2:0]}
    logic [9:0] actual;
    assign actual = {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, PCSrc, ALUControl};

    int errors = 0;
    int tests  = 0;

    controller dut (
        .op         (op),
        .funct3     (funct3),
        .funct7_5   (funct7_5),
        .Zero       (Zero),
        .RegWrite   (RegWrite),
        .ImmSrc     (ImmSrc),
        .ALUSrc     (ALUSrc),
        .MemWrite   (MemWrite),
        .ResultSrc  (ResultSrc),
        .PCSrc      (PCSrc),
        .ALUControl (ALUControl)
    );

    // expected: value of each output
    // care    : 1 = this bit must match, 0 = don't care
    task automatic check(
        input string      name,
        input logic [6:0] t_op,
        input logic [2:0] t_funct3,
        input logic       t_funct7_5,
        input logic       t_zero,
        input logic [9:0] expected,
        input logic [9:0] care
    );
        op       = t_op;
        funct3   = t_funct3;
        funct7_5 = t_funct7_5;
        Zero     = t_zero;
        #1;
        tests++;

        if (((actual ^ expected) & care) !== 10'b0) begin
            errors++;
            $display("FAIL %s", name);
            $display("     got      : RegW=%b Imm=%b ALUSrc=%b MemW=%b ResSrc=%b PCSrc=%b ALUCtl=%b",
                     RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, PCSrc, ALUControl);
            $display("     expected : RegW=%b Imm=%b ALUSrc=%b MemW=%b ResSrc=%b PCSrc=%b ALUCtl=%b (where masked in)",
                     expected[9], expected[8:7], expected[6], expected[5],
                     expected[4], expected[3], expected[2:0]);
        end else begin
            $display("PASS %s", name);
        end
    endtask

    initial begin
        //                                          RegW Imm ALUS MemW Res PCS ALUCtl
        // lw: nothing is a don't-care
        check("lw",            7'b0000011, 3'b010, 0, 0, 10'b1_00_1_0_1_0_000, 10'b1_11_1_1_1_1_111);
        // bit 30 is part of the immediate for lw; ALU control must still be add
        check("lw f7_5=1",     7'b0000011, 3'b010, 1, 0, 10'b1_00_1_0_1_0_000, 10'b1_11_1_1_1_1_111);
        // sw: ResultSrc is a don't-care
        check("sw",            7'b0100011, 3'b010, 0, 0, 10'b0_01_1_1_0_0_000, 10'b1_11_1_1_0_1_111);

        // R-type: ImmSrc is a don't-care
        check("add",           7'b0110011, 3'b000, 0, 0, 10'b1_00_0_0_0_0_000, 10'b1_00_1_1_1_1_111);
        check("sub",           7'b0110011, 3'b000, 1, 0, 10'b1_00_0_0_0_0_001, 10'b1_00_1_1_1_1_111);
        check("slt",           7'b0110011, 3'b010, 0, 0, 10'b1_00_0_0_0_0_101, 10'b1_00_1_1_1_1_111);
        check("or",            7'b0110011, 3'b110, 0, 0, 10'b1_00_0_0_0_0_011, 10'b1_00_1_1_1_1_111);
        check("and",           7'b0110011, 3'b111, 0, 0, 10'b1_00_0_0_0_0_010, 10'b1_00_1_1_1_1_111);

        // beq: ResultSrc is a don't-care; only PCSrc changes with Zero
        check("beq not taken", 7'b1100011, 3'b000, 0, 0, 10'b0_10_0_0_0_0_001, 10'b1_11_1_1_0_1_111);
        check("beq taken",     7'b1100011, 3'b000, 0, 1, 10'b0_10_0_0_0_1_001, 10'b1_11_1_1_0_1_111);

        // Zero=1 on a non-branch must NOT take the branch
        check("sub zero=1",    7'b0110011, 3'b000, 1, 1, 10'b1_00_0_0_0_0_001, 10'b1_00_1_1_1_1_111);

        // Unknown opcode: only the state-changing outputs are checked
        // (RegWrite, MemWrite, PCSrc must all be 0)
        check("unknown op",    7'b1111111, 3'b000, 0, 1, 10'b0_00_0_0_0_0_000, 10'b1_00_0_1_0_1_000);

        $display("----------------------------------------");
        $display("%0d tests, %0d errors", tests, errors);
        if (errors == 0) $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
