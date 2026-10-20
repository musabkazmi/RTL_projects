// Code your testbench here
// or browse Examples
`timescale 1ns/1ps
module controller_tb;
    logic clk=0, reset;
    logic [6:0] op; logic [2:0] funct3; logic funct7_5, Zero;
    logic PCWrite, RegWrite, MemWrite, IRWrite, AdrSrc;
    logic [1:0] ResultSrc, ALUSrcA, ALUSrcB, ImmSrc; logic [2:0] ALUControl;

    controller dut(.*);
    always #5 clk = ~clk;

    localparam [6:0] LW=7'b0000011, SW=7'b0100011, RT=7'b0110011, IT=7'b0010011, BEQ=7'b1100011, JAL=7'b1101111;
    int errors=0, checks=0;

    // check all datapath controls for one cycle, then advance one clock
    task automatic cyc(input string tag,
        input logic pcw, rw, mw, irw, adr, input logic [1:0] rs, sa, sb, input logic [2:0] ac);
        checks++;
        if ({PCWrite,RegWrite,MemWrite,IRWrite,AdrSrc,ResultSrc,ALUSrcA,ALUSrcB,ALUControl} !==
            {pcw,rw,mw,irw,adr,rs,sa,sb,ac}) begin
            errors++;
            $display("FAIL %-14s got  PCW=%b RW=%b MW=%b IRW=%b Adr=%b Res=%b A=%b B=%b ALUC=%b",
                tag,PCWrite,RegWrite,MemWrite,IRWrite,AdrSrc,ResultSrc,ALUSrcA,ALUSrcB,ALUControl);
            $display("     %-14s want PCW=%b RW=%b MW=%b IRW=%b Adr=%b Res=%b A=%b B=%b ALUC=%b",
                "",pcw,rw,mw,irw,adr,rs,sa,sb,ac);
        end
        @(posedge clk); #1;
    endtask

    task automatic imm(input string tag, input logic [1:0] exp);
        checks++;
        if (ImmSrc !== exp) begin errors++; $display("FAIL %s ImmSrc got %b want %b", tag, ImmSrc, exp); end
    endtask

    task automatic start(input [6:0] o, input [2:0] f3, input f75, input z);
        op=o; funct3=f3; funct7_5=f75; Zero=z;
    endtask

    //             tag       PCW RW MW IRW Adr  Res   A     B    ALUC
    task automatic fetch;  cyc("FETCH",     1,0,0,1,0, 2'b10,2'b00,2'b10,3'b000); endtask
    task automatic decode; cyc("DECODE",    0,0,0,0,0, 2'b00,2'b01,2'b01,3'b000); endtask

    initial begin
        reset=1; start(LW,0,0,0);
        @(negedge clk); reset=0; #1;   // release at negedge: FSM sits in FETCH, sampled before next posedge

        // ---------- lw ----------
        start(LW,3'b010,0,0);
        fetch; decode; imm("lw",2'b00);
        cyc("lw MEMADR",  0,0,0,0,0, 2'b00,2'b10,2'b01,3'b000);
        cyc("lw MEMREAD", 0,0,0,0,1, 2'b00,2'b00,2'b00,3'b000);
        cyc("lw MEMWB",   0,1,0,0,0, 2'b01,2'b00,2'b00,3'b000);
        // ---------- sw ----------
        start(SW,3'b010,0,0);
        fetch; decode; imm("sw",2'b01);
        cyc("sw MEMADR",  0,0,0,0,0, 2'b00,2'b10,2'b01,3'b000);
        cyc("sw MEMWRITE",0,0,1,0,1, 2'b00,2'b00,2'b00,3'b000);
        // ---------- add ----------
        start(RT,3'b000,0,0);
        fetch; decode;
        cyc("add EXECUTER",0,0,0,0,0, 2'b00,2'b10,2'b00,3'b000);
        cyc("add ALUWB",   0,1,0,0,0, 2'b00,2'b00,2'b00,3'b000);
        // ---------- sub ----------
        start(RT,3'b000,1,0);
        fetch; decode;
        cyc("sub EXECUTER",0,0,0,0,0, 2'b00,2'b10,2'b00,3'b001);
        cyc("sub ALUWB",   0,1,0,0,0, 2'b00,2'b00,2'b00,3'b000);
        // ---------- and / or / slt ----------
        start(RT,3'b111,0,0); fetch; decode; cyc("and EXEC",0,0,0,0,0,2'b00,2'b10,2'b00,3'b010); cyc("and WB",0,1,0,0,0,2'b00,2'b00,2'b00,3'b000);
        start(RT,3'b110,0,0); fetch; decode; cyc("or EXEC",0,0,0,0,0,2'b00,2'b10,2'b00,3'b011);  cyc("or WB",0,1,0,0,0,2'b00,2'b00,2'b00,3'b000);
        start(RT,3'b010,0,0); fetch; decode; cyc("slt EXEC",0,0,0,0,0,2'b00,2'b10,2'b00,3'b101); cyc("slt WB",0,1,0,0,0,2'b00,2'b00,2'b00,3'b000);
        // ---------- addi (positive imm) ----------
        start(IT,3'b000,0,0);
        fetch; decode; imm("addi",2'b00);
        cyc("addi EXECUTEI",0,0,0,0,0, 2'b00,2'b10,2'b01,3'b000);
        cyc("addi ALUWB",   0,1,0,0,0, 2'b00,2'b00,2'b00,3'b000);
        // ---------- addi with negative imm (instr[30]=1) must still ADD ----------
        start(IT,3'b000,1,0);
        fetch; decode;
        cyc("addi- EXECUTEI",0,0,0,0,0, 2'b00,2'b10,2'b01,3'b000);
        cyc("addi- ALUWB",   0,1,0,0,0, 2'b00,2'b00,2'b00,3'b000);
        // ---------- beq not taken ----------
        start(BEQ,3'b000,0,0);
        fetch; decode; imm("beq",2'b10);
        cyc("beq NT BEQ", 0,0,0,0,0, 2'b00,2'b10,2'b00,3'b001);
        // ---------- beq taken ----------
        start(BEQ,3'b000,0,1);
        fetch; decode;
        cyc("beq T BEQ",  1,0,0,0,0, 2'b00,2'b10,2'b00,3'b001);
        // ---------- jal ----------
        start(JAL,3'b000,0,0);
        fetch; decode; imm("jal",2'b11);
        cyc("jal JAL",   1,0,0,0,0, 2'b00,2'b01,2'b10,3'b000);
        cyc("jal ALUWB", 0,1,0,0,0, 2'b00,2'b00,2'b00,3'b000);
        // ---------- unsupported opcode (lui) returns to FETCH after DECODE ----------
        start(7'b0110111,0,0,0);
        fetch; decode;
        fetch;                       // must be back in FETCH, no RegWrite/MemWrite
        decode;
        // ---------- Zero must not matter outside BEQ ----------
        start(RT,3'b000,0,1);
        fetch; decode;
        cyc("add Z=1 EXEC",0,0,0,0,0, 2'b00,2'b10,2'b00,3'b000);
        cyc("add Z=1 WB",  0,1,0,0,0, 2'b00,2'b00,2'b00,3'b000);
        // ---------- asynchronous reset mid-instruction ----------
        start(LW,3'b010,0,0);
        fetch; decode;
        #1 reset=1; #1;
        checks++;
        if (!(IRWrite===1 && RegWrite===0 && MemWrite===0 && PCWrite===1)) begin errors++; $display("FAIL reset did not return to FETCH"); end
        reset=0;

        $display("----------------------------------------");
        $display("%0d checks, %0d errors  ->  %s", checks, errors, errors==0 ? "ALL PASS" : "FAILED");
        $finish;
    end

    initial begin #20000 $display("TIMEOUT"); $finish; end
endmodule
