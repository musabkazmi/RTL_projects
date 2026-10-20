// Code your design here
// N-bit ALU with SLT support (Harris & Harris, Fig. 5.17 + Table 5.3)
//
// ALUControl[2:0]  Function
//   000            ADD
//   001            SUB
//   010            AND
//   011            OR
//   101            SLT  (signed set-less-than)
//   others         result = 0
//
// Flags (Table 5.2) come from the adder/subtractor and are only meaningful
// for ADD / SUB / SLT:
//   neg      = Sum[N-1]            (N)
//   zero     = (Sum == 0)          (Z)
//   carry    = Cout                (C)  -> for SUB, unsigned A >= B
//   overflow = signed overflow     (V)
module alu #(
  parameter int N = 32
) (
  input  logic [N-1:0] a,
  input  logic [N-1:0] b,
  input  logic [2:0]   alu_control,
  output logic [N-1:0] result,
  output logic         zero,
  output logic         neg,
  output logic         carry,
  output logic         overflow
);

  // ---------------- Adder / subtractor ----------------
  // ALUControl[0] = 1 -> subtract: invert B and set carry-in
  logic [N-1:0] b_mux;
  logic [N-1:0] sum;
  logic         cout;

  assign b_mux       = alu_control[0] ? ~b : b;
  assign {cout, sum} = {1'b0, a} + {1'b0, b_mux} + N'(alu_control[0]);

  // ---------------- Flags ----------------
  assign neg   = sum[N-1];
  assign zero  = (sum == '0);
  assign carry = cout;

  // Overflow (only for add/sub, i.e. ALUControl[1] == 0):
  //   sign of sum differs from sign of A, AND the operation was effectively
  //   an addition of operands with the same sign (A and B_eff same sign).
  logic same_sign;   // A and (B xor sub) have the same sign
  assign same_sign = ~(alu_control[0] ^ a[N-1] ^ b[N-1]);
  assign overflow  = ~alu_control[1] & (a[N-1] ^ sum[N-1]) & same_sign;

  // ---------------- SLT ----------------
  // Signed A < B  <=>  N xor V  (Table 5.2), zero-extended to N bits
  logic [N-1:0] slt;
  assign slt = N'(sum[N-1] ^ overflow);

  // ---------------- Result mux ----------------
  always_comb begin
    unique case (alu_control)
      3'b000:  result = sum;
      3'b001:  result = sum;
      3'b010:  result = a & b;
      3'b011:  result = a | b;
      3'b101:  result = slt;
      default: result = '0;
    endcase
  end

endmodule
