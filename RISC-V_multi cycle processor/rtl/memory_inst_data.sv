module memory_inst_data #(
  parameter DATA_WIDTH = 32,
  parameter DEPTH      = 64,
  parameter INIT_FILE  = ""
)(
  input  logic                  clk,
  input  logic                  we,
  input  logic [31:0]           a,
  input  logic [DATA_WIDTH-1:0] wd,
  output logic [DATA_WIDTH-1:0] rd
);
  logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];
  logic [$clog2(DEPTH)-1:0] word_addr;

  assign word_addr = a[$clog2(DEPTH)+1:2];

  initial if (INIT_FILE != "") $readmemh(INIT_FILE, mem);

  always_ff @(posedge clk)
    if (we) mem[word_addr] <= wd;

  assign rd = mem[word_addr];
endmodule
