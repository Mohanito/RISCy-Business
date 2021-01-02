// Adder.sv - full adder and half adder
// ^ == XOR
module halfadder(
  input logic a,
  input logic b,
  output logic s,
  output logic c
);
assign s = a ^ b;
assign c = a & b;

endmodule: halfadder

module fulladder(
  input logic a,
  input logic b,
  input logic cin,
  output logic s,
  output logic c
);
assign s = a ^ b ^ cin;
assign c = (a & b) | (a & cin) | (a & cin);

endmodule: fulladder

module wallace_3_to_2
#(parameter width = 32)
(
  input logic[(2*width-1):0] a1,
  input logic[(2*width-1):0] a2,
  input logic[(2*width-1):0] a3,
  output logic[(2*width-1):0] b1,
  output logic[(2*width-1):0] b2
);

genvar g;
generate
  for(g = 0; g < 2*width-1; g++) begin : fulladder_layer
    fulladder fa1(.a(a1[g]), .b(a2[g]), .cin(a3[g]), .s(b1[g]), .c(b2[g + 1]));
  end
endgenerate

fulladder fa2(.a(a1[2*width-1]), .b(a2[2*width-1]), .cin(a3[2*width-1]), .s(b1[2*width-1]), .c());

endmodule: wallace_3_to_2

// TODO: 32-bit Carry Propagate Adder or CLA for the last stage
