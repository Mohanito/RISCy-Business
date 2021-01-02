// add shift 64 tb
import mult_types::*;

module add_shift_tb;

logic clk, reset_n, start, rdy, done;
logic [width_p-1:0] multiplicand, multiplier;
logic [2*width_p-1:0] product;
logic [2*width_p-1:0] p;
logic correct = 1'b1;
logic [2:0] mul_funct3 = 3'b011;  // unsigned 010, signed 000,001, signed*unsigned 011

// generate clock
always begin
  clk = 0;
  #10;
  clk = 1;
  #10;
end
add_shift_multiplier dut (
    .clk_i          ( clk          ),
    .reset_n_i      ( reset_n      ),
    .multiplicand_i ( multiplicand ),
    .multiplier_i   ( multiplier   ),
    .start_i        ( start        ),
	 .mul_funct3     ( mul_funct3   ),
    .ready_o        ( rdy          ),
    .product_o      ( product      ),
    .done_o         ( done         )
);

// Resets the multiplier
task reset();
    reset_n <= 1'b0;
    #100;
    reset_n <= 1'b1;
    #1;
endtask : reset

initial begin
    reset_n <= 1'b0;
    #100;
    reset_n <= 1'b1;
    #1;
	 // after the first reset, rdy should be 1
	
    for (int i = -15; i <= 15; ++i) begin
			for (int j = 0; j <= 15; ++j) begin
				multiplicand <= i[width_p-1:0];
				multiplier <= j[width_p-1:0];
				// assert start_i from READY state
				start <= 1'b1;
				#10;
				start <= 1'b0;
				
				while (done == 1'b0) begin
				  #10;
				end
				p = $signed(multiplicand) * $signed(multiplier);
				// check output
				assert (product == p)
				    else begin
						correct = 1'b0;
				    end
				#10;	 
			end
	 end
end


endmodule
