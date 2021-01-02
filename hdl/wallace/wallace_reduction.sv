// Wallace Reduction Module
module wallace_reduction
#(parameter width = 32)
(
  input logic [(width-1):0][(width*2-1):0] p,
  output logic [(2*width-1):0] f1, f2	// final 64-bit result
);

logic [(width-1):0][(width*2-1):0] p_out = p;

genvar num_lines;
genvar useless_syntax;
generate
  for(num_lines = width; num_lines > 2; useless_syntax++) begin : why_does_this_need_a_name // cannot use while loop for some reason
    wallace_reduction_layer wrl(.p_in(p_out), .num_lines_in(num_lines), 
	                             .p_out(p_out), .num_lines_out(num_lines));
  end
  assign f1 = p_out[0];
  assign f2 = p_out[1];

endgenerate

endmodule: wallace_reduction