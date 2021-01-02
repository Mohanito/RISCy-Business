// divider testbench

module divider_tb;

logic clk, reset, start, rdy, done;
logic [31:0] dividend, divisor;
logic [31:0] quotient, remainder;
logic correct = 1'b1;
logic is_signed = 1'b0;
int q, rem;
// generate clock
always begin
  clk = 0;
  #10;
  clk = 1;
  #10;
end

divider dut (
    .clk_i          ( clk          ),
    .reset_i      ( reset      ),
    .dividend_i ( dividend ),
    .divisor_i   ( divisor   ),
    .start_i        ( start        ),
	 .is_signed_i (is_signed),
    //.ready_o        ( rdy          ),
    .quotient_o      ( quotient      ),
	 .remainder_o  (remainder),
    .done_o         ( done         )
);

// Resets the divider
task reset_divider();
    reset <= 1'b1;
    #100;
    reset <= 1'b0;
    #1;
endtask : reset_divider

int i, j, i2, j2, i3, j3, i4, j4;	//stupid sv syntax
initial begin
    reset_divider();
	 // after the first reset, rdy should be 1 (unused in divider)
	 // signed
	 is_signed = 1'b1;
	 i = -103;
	 j = 20;
	 dividend <= i[31:0];
	divisor <= j[31:0];
	// assert start_i from READY state
	start <= 1'b1;
	#30;
	start <= 1'b0;
	while (done == 1'b0) begin
	  #1;
	end
	#100;
	
	i2 = -10;
	 j2 = -6;
	 dividend <= i2[31:0];
	divisor <= j2[31:0];
	// assert start_i from READY state
	start <= 1'b1;
	#30;
	start <= 1'b0;
	while (done == 1'b0) begin
	  #1;
	end
	#100;
	
	i3 = 5;
	 j3 = -3;
	 dividend <= i3[31:0];
	divisor <= j3[31:0];
	// assert start_i from READY state
	start <= 1'b1;
	#30;
	start <= 1'b0;
	while (done == 1'b0) begin
	  #1;
	end
	#100;
	
	i4 = 10;
	 j4 = 3;
	 dividend <= i4[31:0];
	divisor <= j4[31:0];
	// assert start_i from READY state
	start <= 1'b1;
	#30;
	start <= 1'b0;
	while (done == 1'b0) begin
	  #1;
	end
	#100;
	 
//	 // unsigned
//	 is_signed = 1'b0;
//    for (int i = 1; i <= 32'hF; ++i) begin
//			for (int j = 0; j <= 32'hF; ++j) begin
//				dividend <= i[31:0];
//				divisor <= j[31:0];
//				// assert start_i from READY state
//				start <= 1'b1;
//				#10;
//				start <= 1'b0;
//				
//				while (done == 1'b0) begin
//				  #1;
//				end
//				if (j == 0) begin
//				  q = 32'hFFFFFFFF;
//				  rem = dividend;
//				end
//				else begin
//				  q = int'(dividend / divisor);
//				  rem = (dividend % divisor);
//				end
//				// check output
//				assert (quotient == q) 
//				    else begin
//						correct = 1'b0;
//				    end
//				assert (remainder == rem) 
//				    else begin
//						correct = 1'b0;
//				    end
//				#10;	 
//			end
//	 end
end

endmodule
