// Code your testbench here
// or browse Examples
module tb;
  logic clk = 0, rst = 1;
  logic [31:0] PC, Instr, ALUResult, WriteData, ReadData, Result;

  riscv_top dut (.*);

  always #5 clk = ~clk;

  initial begin
    // Preload: lw x5, 8(x1) at address 0
    dut.u_dp.u_imem.im[0] = 32'h0080A283;
    dut.u_dp.u_rf.rf[1]   = 32'd4;            // x1 = 4
    dut.u_dp.u_dmem.dm[3] = 32'hDEADBEEF;     // byte address 12 (word 3)
    dut.u_dp.u_rf.rf[5]   = 32'h0;            // x5 starts at 0

    // Reset edge: PC becomes 0
    @(posedge clk); #1 rst = 0;
    #2;   // let combinational logic settle

    $display("PC=%h Instr=%h", PC, Instr);
    $display("ctrl: RegWrite=%b ImmSrc=%b ALUSrc=%b MemWrite=%b ResultSrc=%b PCSrc=%b ALUControl=%b",
      dut.RegWrite, dut.ImmSrc, dut.ALUSrc, dut.MemWrite,
      dut.ResultSrc, dut.PCSrc, dut.ALUControl);
    $display("ALUResult=%0d (address)   ReadData=%h   Result=%h",
      ALUResult, ReadData, Result);

    // Same-cycle (combinational) checks
    if (ALUResult === 32'd12)       $display("PASS  ALUResult is the address 12");
    else                            $display("FAIL  ALUResult");
    if (ReadData === 32'hDEADBEEF)  $display("PASS  ReadData is the memory word");
    else                            $display("FAIL  ReadData");
    if (Result === ReadData)        $display("PASS  Result == ReadData");
    else                            $display("FAIL  Result");

    // Registered check: x5 must not change until the clock edge
    $display("x5 before edge = %h", dut.u_dp.u_rf.rf[5]);
    @(posedge clk); #1;
    $display("x5 after edge  = %h   PC=%h", dut.u_dp.u_rf.rf[5], PC);
    if (dut.u_dp.u_rf.rf[5] === 32'hDEADBEEF) $display("PASS  x5 written on the clock edge");
    else                                      $display("FAIL  x5");

    $finish;
  end
endmodule
