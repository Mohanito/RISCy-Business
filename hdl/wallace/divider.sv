// 32 bit divider
module divider
(
    input logic clk_i,
    input logic reset_i,
    input logic [31:0] dividend_i,
    input logic [31:0] divisor_i,
    input logic start_i,
	 input logic is_signed_i,
    //output logic ready_o,
    output logic [31:0] quotient_o,
	 output logic [31:0] remainder_o,
    output logic done_o
);


logic [63:0] dd, ds, dd_in, ds_in;
logic [31:0] q;
logic [5:0] counter, counter_in;	// counts # of times shifted
logic load_q, load_dd, load_ds, load_counter;
logic [31:0] q_in;
// signed division
logic [31:0] unsigned_dd, unsigned_ds;
int sign;

assign quotient_o = q;
assign remainder_o = dd[31:0];

enum int unsigned {init, division_by_0, subtract, shift, add_sign, done} state, next_state;

register reg_q (
    .clk  (clk_i), .rst (reset_i), .load (load_q),
    .in   (q_in), .out  (q)
);
register #(.width(64)) reg_dd (
    .clk  (clk_i), .rst (reset_i), .load (load_dd),
    .in   (dd_in), .out  (dd)
);
register #(.width(64)) reg_ds (
    .clk  (clk_i), .rst (reset_i), .load (load_ds),
    .in   (ds_in), .out  (ds)
);
register #(.width(6)) reg_counter (
    .clk  (clk_i), .rst (reset_i), .load (load_counter),
    .in   (counter_in), .out  (counter)
);


function void set_defaults();
    done_o = 1'b0;
	 load_dd = 1'b0;
	 load_ds = 1'b0;
	 load_q = 1'b0;
	 load_counter = 1'b0;
	 q_in = q;
	 ds_in = ds;
	 dd_in = dd;
	 counter_in = counter;
endfunction


always_comb begin : sign_actions
  sign = dividend_i[31] ^ divisor_i[31];	//XOR
  if (dividend_i[31] == 1)
    unsigned_dd = (~dividend_i) + 1;
  else
    unsigned_dd = dividend_i;

  if (divisor_i[31] == 1)
    unsigned_ds = (~divisor_i) + 1;
  else
    unsigned_ds = divisor_i;
end

always_comb begin : state_actions
set_defaults();
  case(state)
    // initially, have 64bit 0000dividend and divisor0000, 32 bit quotient = 0, done_o = 0
    init: begin
	   if (is_signed_i) begin	// if is signed division, we convert to unsigned division then add the sign later.
		  dd_in = {32'b0, unsigned_dd};
		  ds_in = {unsigned_ds, 32'b0};
		end
		else begin
		  dd_in = {32'b0, dividend_i};
		  ds_in = {divisor_i, 32'b0};
		end
		load_dd = 1'b1;
		load_ds = 1'b1;
		q_in = 32'b0;
		load_q = 1'b1;
		counter_in = 6'b0;
		load_counter = 1'b1;
		done_o = 1'b0;
	 end
	 division_by_0: begin	// x/0: q = -1 for signed, 2^32 - 1 for unsigned, rem = x
	   q_in = 32'hFFFFFFFF;
		load_q = 1'b1;
		dd_in = {32'b0, dividend_i};
		load_dd = 1'b1;
		counter_in = 6'd32;
		load_counter = 1'b1;
	 end
	 // subtract state: if ds <= dd, then: dd = dd - ds, q += 1
    // else: do nothing. shift.
	 subtract: begin
	   done_o = 1'b0;
		load_ds = 1'b0;
	   if(ds <= dd) begin
		  dd_in = dd - ds;
		  load_dd = 1'b1;
		  q_in = q + 1;
		  load_q = 1'b1;
		end
	 end
	 // shift state: quotient << 1, ds >> 1;
	 shift: begin
	   if (counter < 6'd32) begin
	     q_in = q << 1;
		  load_q = 1'b1;
		  ds_in = ds >> 1;
		  load_ds = 1'b1;
		end
		counter_in = counter + 1;
		load_counter = 1'b1;
		done_o = 1'b0;
	 end
	 add_sign: begin
	   if(sign) begin
		  q_in = ~q + 1;
		  load_q = 1'b1;
		end
		// The remainder has the same sign as the dividend
		if(dividend_i[31] != dd[31]) begin
		  dd_in = ~dd + 1;
		  load_dd = 1'b1;
		end
	 end
	 done: begin
	   done_o = 1'b1;
	 end
  endcase
end

always_comb begin : next_state_logic
  case(state)
    init: begin
	   if(divisor_i == 32'b0)
	     next_state = division_by_0;
		else
		  next_state = subtract;
	 end
	 division_by_0:
	   next_state = done;
	 subtract: begin
	   if (counter < 6'd32)
	     next_state = shift;
		else begin
		  if (is_signed_i)
		    next_state = add_sign;
		  else
		    next_state = done;
		end
	 end
	 shift: begin
	     next_state = subtract;
	 end
	 add_sign:
	   next_state = done;
	 done: 
	   next_state = done;
  endcase
end


always_ff @(posedge clk_i) begin: next_state_assignment
  if(reset_i || ((start_i) && state == done) )
    state <= init;
  else
    state <= next_state;
end

endmodule: divider
