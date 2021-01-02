import rv32i_types::*;

module mp4(
	input clk,
	input rst,

	output rv32i_word pmem_address,
	input logic [63:0] pmem_rdata,
	output logic [63:0] pmem_wdata, 
	output logic pmem_read, 
	output logic pmem_write,
	input logic pmem_resp
);

/* WIRES */
rv32i_opcode opcode; 
logic [2:0] funct3; 
logic [6:0] funct7;
rv32i_ctrl_word ctrl;

rv32i_word i_mem_address;
rv32i_word i_mem_rdata;
logic i_mem_read;
logic i_mem_resp;

rv32i_word d_mem_address;
rv32i_word d_mem_rdata;
rv32i_word d_mem_wdata;
logic d_mem_read;
logic d_mem_write;
logic [3:0] d_mem_byte_enable;
logic d_mem_resp;

/* MODULES */
datapath i_datapath(
    .clk(clk),
    .rst(rst),

	.id_ctrl(ctrl),

	.if_opcode(opcode), 
	.if_funct3(funct3), 
	.if_funct7(funct7),

	.i_mem_address(i_mem_address),
	.if_i_mem_data(i_mem_rdata),
	.i_mem_read(i_mem_read),
	.i_mem_resp(i_mem_resp),

	.d_mem_address(d_mem_address),
	.d_mem_data(d_mem_rdata),
	.d_mem_wdata(d_mem_wdata), 
	.d_mem_read(d_mem_read),
	.d_mem_write(d_mem_write), 
	.d_mem_byte_enable(d_mem_byte_enable),
	.d_mem_resp(d_mem_resp)
);

control_rom i_control_rom(
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .ctrl(ctrl)
);

cache_top i_cache_top(
	.clk(clk),
    .rst(rst),

    .i_mem_address(i_mem_address),
    .i_mem_rdata(i_mem_rdata),
    .i_mem_wdata(32'b0),
    .i_mem_read(i_mem_read),
    .i_mem_write(1'b0),
    .i_mem_byte_enable(4'b1111),
    .i_mem_resp(i_mem_resp),

    .d_mem_address(d_mem_address),
    .d_mem_rdata(d_mem_rdata),
    .d_mem_wdata(d_mem_wdata),
    .d_mem_read(d_mem_read),
    .d_mem_write(d_mem_write),
    .d_mem_byte_enable(d_mem_byte_enable),
    .d_mem_resp(d_mem_resp),

    .pmem_address(pmem_address),
    .pmem_rdata(pmem_rdata),
    .pmem_wdata(pmem_wdata),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .pmem_resp(pmem_resp)
);

endmodule : mp4
