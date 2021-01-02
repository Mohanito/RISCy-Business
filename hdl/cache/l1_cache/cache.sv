import rv32i_types::*;

module cache 
(
    input clk,
    input rst,
    input rv32i_word mem_address,
    output rv32i_word mem_rdata,
    input rv32i_word mem_wdata,
    input logic mem_read,
    input logic mem_write,
    input [3:0] mem_byte_enable,
    output logic mem_resp,

    output rv32i_word pmem_address,
    input [255:0] pmem_rdata,
    output [255:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp
);

logic [255:0] mem_rdata256_out;
assign pmem_wdata = mem_rdata256_out;

logic [1:0] cache_hit;
logic write_back;
logic way_reg;
logic way;
logic [1:0] load_dirty;
logic set_dirty;
logic load_lru;
logic set_lru;
logic set_valid;
logic [1:0] load_tag;
logic way_sel;
logic [1:0] write_sel;
logic [1:0] load_valid;
logic load_way_reg;
logic [255:0] mem_wdata256;
logic [31:0] mem_byte_enable256;

cache_control control
(
	.clk (clk),
	.rst (rst),
	.mem_read (mem_read),
	.mem_write (mem_write),
	.mem_resp (mem_resp),
	.cache_hit (cache_hit),
	.write_back (write_back),
	.way_reg (way_reg),
	.way (way),
	.load_dirty (load_dirty),
	.set_dirty (set_dirty),
	.load_lru (load_lru),
	.set_lru (set_lru),
	.way_sel (way_sel),
	.pmem_resp (pmem_resp),
	.pmem_write (pmem_write),
	.pmem_read (pmem_read),
	.write_sel (write_sel),
	.load_valid (load_valid),
	.set_valid (set_valid),
	.load_tag (load_tag),
	.load_way_reg (load_way_reg)
);

cache_datapath datapath
(
	.clk (clk),
	.rst (rst),
	.mem_address (mem_address),
	.pmem_address (pmem_address),
	.pmem_rdata (pmem_rdata),
	.pmem_wdata (mem_rdata256_out),
	.mem_wdata256 (mem_wdata256),
	.mem_byte_enable256 (mem_byte_enable256),
	.cache_hit (cache_hit),
	.write_back (write_back),
	.way_reg (way_reg),
	.way (way),
	.load_dirty (load_dirty),
	.set_dirty (set_dirty),
	.load_lru (load_lru),
	.set_lru (set_lru),
	.way_sel (way_sel),
	.write_sel (write_sel),
	.load_valid (load_valid),
	.set_valid (set_valid),
	.load_tag (load_tag),
	.load_way_reg (load_way_reg)
);

bus_adapter bus_adapter
(
	.mem_wdata256 (mem_wdata256),
	.mem_rdata256 (mem_rdata256_out),
	.mem_wdata (mem_wdata),
	.mem_rdata (mem_rdata),
	.mem_byte_enable (mem_byte_enable),
	.mem_byte_enable256 (mem_byte_enable256),
	.address(mem_address)
);

endmodule : cache
