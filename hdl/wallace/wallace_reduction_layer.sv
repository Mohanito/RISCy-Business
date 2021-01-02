// wallace reduction layer
module wallace_reduction_layer
#(parameter width = 32)
(
  input logic [(width-1):0][(width*2-1):0] p_in,
  input num_lines_in,
  output logic [(width-1):0][(width*2-1):0] p_out,
  output num_lines_out
);

byte num_lines = num_lines_in; //p_in.size;
// byte width = p_in[0].size;
/*
             p_in[0].size
	XXXXXXXXXXXXXXXXXXXXXXXX
	XXXXXXXXXXXXXXXXXXXXXXXX num_lines
	XXXXXXXXXXXXXXXXXXXXXXXX
*/
byte num_3_to_2 = int'(num_lines / 3);
assign num_lines_out = 2 * num_3_to_2 + (num_lines % 3);
//byte new_num_lines = 2 * num_3_to_2 + (num_lines % 3);

logic [(width-1):0][(width*2-1):0] p_new;	//[(num_lines_out-1):0][(width*2-1):0]

genvar i;

generate
  for(i = 0; i < int'(width * 2 / 3); i++) begin : why_this_block_needs_a_name_too	// < num_3_to_2
    //take p_in 3i, 3i+1, 3i+2, output to p_new 2i, 2i+1.
    wallace_3_to_2 w32(.a1(p_in[3*i]), 
	                    .a2(p_in[3*i + 1]), 
						     .a3(p_in[3*i + 2]), 
						     .b1(p_new[2*i]), 
						     .b2(p_new[2*i + 1]));
  end
endgenerate

always_comb begin	// "is not a constant" error?
  for(int j = 0; j < (num_lines % 3); j++) begin : this_block_needs_a_name
    assign p_new[num_lines_out - 1 - j] = p_in[num_lines - 1 - j];
  end
end

assign p_out = p_new;

endmodule: wallace_reduction_layer