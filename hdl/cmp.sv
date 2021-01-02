import rv32i_types::*;

module cmp
(
    input rv32i_word in_a, in_b,
	input branch_funct3_t cmpop,
	output logic out
);

rv32i_word result;

always_comb
begin
	result = in_a - in_b;
    case (cmpop)
	    beq: begin
			out = 1'b1;
			for (int i = 0; i < 32; i++) begin
				if (result[i] == 1'b1) out = 1'b0;
			end
		end
		bne: begin
			out = 1'b0;
			for (int i = 0; i < 32; i++) begin
				if (result[i] == 1'b1) out = 1'b1;
			end
		end
	    blt, bltu: begin
			out = result[31];
		end
		bge, bgeu: begin
			out = ~(result[31]);
		end
	    default: 
		    out = 0;
	 endcase
end

endmodule : cmp