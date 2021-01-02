module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

localparam [1:0] idle = 2'b00, write = 2'b01, read = 2'b10, finish = 2'b11;

logic [1:0] state = idle;
logic [1:0] state_next;

logic resp_next, read_next, write_next;

logic [63:0] burst_r;
logic [31:0] address_next;

logic [2:0] count;

always_ff @(posedge clk)
begin
    if(!reset_n)
        begin
            state <= idle;
            resp_o <= 1'b0;
            count <= 3'b0;
            line_o <= 256'b0;
            read_o <= 1'b0;
            write_o <= 1'b0;
        end
    else if(state == read && resp_i == 1'b1) 
        begin
            state <= state_next;
            resp_o <= resp_next;
            line_o[64*count +: 64] <= burst_i; 
            count <= count + 3'b001;
            read_o <= read_next;

        end
    else if(state == write && resp_i == 1'b0)
        begin
            state <= state_next;
            resp_o <= resp_next;
            burst_o <= line_i[63:0];
            write_o <= write_next;
        end
    else if(state == write && resp_i == 1'b1)
        begin
            state <= state_next;
            resp_o <= resp_next;
            burst_o <= line_i[64*count+64 +: 64];
            count <= count + 3'b001;
            write_o <= write_next;
        end
    else
        begin
            state <= state_next;
            address_o <= address_next;
            resp_o <= resp_next;
            count <= 3'b0;
            read_o <= read_next;
            write_o <= write_next;
        end
end

always_comb
begin
    state_next = state;
    address_next = address_o;
    resp_next = resp_o;
    read_next = read_o;
    write_next = write_o;
    case(state)
        idle:
            begin
            if(read_i === 1'b1) begin
                state_next = read;
                address_next = address_i;
                read_next = 1'b1;
            end
            else if(write_i === 1'b1) begin
                state_next = write;
                address_next = address_i;
                write_next = 1'b1;
            end
            resp_next = 1'b0;
            end
        write:
            begin
            if(count == 3'b011) begin
                resp_next = 1'b1;
                state_next = finish;
                write_next = 1'b0;
            end
            end
        read:
            begin
            if(count == 3'b011) begin
                resp_next = 1'b1;
                state_next = finish;
                read_next = 1'b0;
            end
            end
		  finish: begin
				state_next = idle;
				resp_next = 1'b0;
			end
        default:
            state_next = idle;
    endcase
end

endmodule : cacheline_adaptor
