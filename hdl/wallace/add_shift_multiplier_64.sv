import mult_types::*;

module add_shift_multiplier
(
    input logic clk_i,
    input logic reset_n_i,
    input operand_t multiplicand_i,
    input operand_t multiplier_i,
    input logic start_i,
	 input logic[2:0] mul_funct3,
	 // need this for signed/unsigned conversion
	 // MUL 000: signed, MULH 001 signed, MULHU 010 unsigned, MULHSU 011 signed*unsigned
    output logic ready_o,
    output result_t product_o,
    output logic done_o
);

/******************************** Declarations *******************************/
mstate_s ms;
mstate_s ms_reset;
mstate_s ms_init;
mstate_s ms_add;
mstate_s ms_shift;
logic update_state;

/*****************************************************************************/

/******************************** Assignments ********************************/
assign ready_o = ms.ready;
assign done_o = ms.done;
assign product_o = {ms.A, ms.Q};
/*****************************************************************************/

/******************************** Monitors ***********************************/
//initial $monitor($time, " DUT: ready_o: %1b", ready_o);
//initial $monitor($time, " DUT: reset_n_i: %1b", reset_n_i);
//initial $monitor($time, " DUT: state: %s", ms.op.name);
//initial $monitor($time, " DUT: clk: %1b, reset_n_i %1b, state: %s, rdy: %1b",
            //clk_i, reset_n_i, ms.op.name, ready_o);
/*****************************************************************************/

/************************** Behavioral Descriptions **************************/

// Describes reset state
function void reset(output mstate_s ms_next);
    ms_next = 0;
    ms_next.ready = 1'b1;
endfunction

// Describes multiplication initialization state
function void init(input logic[width_p-1:0] multiplicand,
                   input logic[width_p-1:0] multiplier,
                   output mstate_s ms_next);
    ms_next.ready = 1'b0;
    ms_next.done = 1'b0;
    ms_next.iteration = 0;
    ms_next.op = ADD;
    
	 // signed  / unsigned
	 case(mul_funct3)
	   3'b000: begin // MUL 000 signed
		  if(multiplicand[width_p-1] == 1)
		    ms_next.M = ~(multiplicand) + 1;
		  else
		    ms_next.M = multiplicand;
		  if(multiplier[width_p-1] == 1)
		    ms_next.Q = ~(multiplier) + 1;
		  else
		    ms_next.Q = multiplier;
		end
		3'b001: begin // MULH 001 signed
		  if(multiplicand[width_p-1] == 1)
		    ms_next.M = ~(multiplicand) + 1;
		  else
		    ms_next.M = multiplicand;
		  if(multiplier[width_p-1] == 1)
		    ms_next.Q = ~(multiplier) + 1;
		  else
		    ms_next.Q = multiplier;
		end
		3'b010: begin // MULHSU 010 signed*unsigned
		  // stackoverflow: rs1 is signed, rs2 (multiplier) is unsigned.
		  if(multiplicand[width_p-1] == 1)
		    ms_next.M = ~(multiplicand) + 1;
		  else
		    ms_next.M = multiplicand;
		  ms_next.Q = multiplier;
		end
		3'b011: begin  // MULHU 011 unsigned
		  ms_next.M = multiplicand;
		  ms_next.Q = multiplier;
		end
		default: begin	// useless, get rid of warnings
		  ms_next.M = multiplicand;
		  ms_next.Q = multiplier;
		end
	 endcase
    ms_next.C = 1'b0;
    ms_next.A = 0;
endfunction

// Describes state after add occurs
function void add(input mstate_s cur, output mstate_s next);
    next = cur;
    next.op = SHIFT;
    if (cur.Q[0])
        {next.C, next.A} = cur.A + cur.M;
    else
        next.C = 1'b0;
endfunction

// Describes state after shift occurs
function void shift(input mstate_s cur, output mstate_s next);
      next = cur;
      {next.A, next.Q} = {cur.C, cur.A, cur.Q[width_p-1:1]};
      next.op = ADD;
      next.iteration += 1;
      if (next.iteration == width_p) begin
		      // add the sign back
				case(mul_funct3)
	           3'b000: begin // MUL 000 signed
				    // sign = multiplicand[31] XOR multiplier[31]
					 if (multiplicand_i[width_p-1] ^ multiplier_i[width_p-1] == 1)
					   {next.A, next.Q} = ~{next.A, next.Q} + 1;
		        end
		        3'b001: begin // MULH 001 signed
				    if (multiplicand_i[width_p-1] ^ multiplier_i[width_p-1] == 1)
					   {next.A, next.Q} = ~{next.A, next.Q} + 1;
		        end
		        3'b010: begin // MULHSU 010 signed*unsigned
				    if (multiplicand_i[width_p-1] == 1)
					   {next.A, next.Q} = ~{next.A, next.Q} + 1;
		        end
		        3'b011: begin // MULHU 011 unsigned
				    ;
		        end
				  default:;
	         endcase
            next.op = DONE;
            next.done = 1'b1;
            next.ready = 1'b1;
      end
endfunction
/*****************************************************************************/

always_comb begin
    update_state = 1'b0;
    if ((~reset_n_i) | (start_i) | (ms.op == ADD) || (ms.op == SHIFT))
        update_state = 1'b1;
    reset(ms_reset);
    init(multiplicand_i, multiplier_i, ms_init);
    add(ms, ms_add);
    shift(ms, ms_shift);
end

logic start_after_reset = 1'b0;
/*************************** Non-Blocking Assignments ************************/
always_ff @(posedge clk_i) begin
//    if (~reset_n_i)
//            ms <= ms_reset;
//    else if (update_state) begin
        if (start_i) begin	// & ready_o
            ms <= ms_reset; //ms_init
				start_after_reset <= 1'b1;
        end
        else begin
		    if(start_after_reset == 1'b1) begin
			   ms <= ms_init;
				start_after_reset <= 1'b0;
			 end
			 else begin
            case (ms.op)
                ADD: ms <= ms_add;
                SHIFT: ms <= ms_shift;
					 DONE: ms <= ms;  // new edit
                default: ms <= ms_reset;
            endcase
			 end
        end
//    end
end
/*****************************************************************************/

// synthesis translate_off
//default clocking @(posedge clk_i); endclocking
//default disable iff (~reset_n_i)
//
//genvar i;
//genvar j;
//generate
//    for (i = 0; i < (1 << width_p); ++i) begin : outer_cover_loop
//        for (j = 0; j < (1 << width_p); ++j) begin : inner_cover_loop
//            mult_cover: cover property (
//                start_i and (multiplicand_i == i) and (multiplier_i == j)
//            );
//        end
//    end
//endgenerate
// synthesis translate_on

endmodule : add_shift_multiplier

