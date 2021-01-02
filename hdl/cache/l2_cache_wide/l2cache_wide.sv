import rv32i_types::*;

module l2cache_wide
(
    input clk,
    input rst,
    // To I-Cache
    input rv32i_word i_mem_address,
    output [255:0] i_mem_rdata,
    input [255:0] i_mem_wdata,
    input logic i_mem_read,
    input logic i_mem_write,
    output logic i_mem_resp,
    // To D-Cache
    input rv32i_word d_mem_address,
    output [255:0] d_mem_rdata,
    input [255:0] d_mem_wdata,
    input logic d_mem_read,
    input logic d_mem_write,
    output logic d_mem_resp,
    // To Cacheline Adaptor
    output rv32i_word pmem_address,
    input [255:0] pmem_rdata,
    output [255:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp
);

logic [3:0] cache_hit;
logic write_back;
logic [1:0] way_reg;
logic [1:0] way;
logic [3:0] load_dirty;
logic set_dirty;
logic load_lru;
logic set_valid;
logic [3:0] load_tag;
logic [1:0] way_sel;
logic [1:0] write_sel;
logic [3:0] load_valid;
logic load_way_reg;
logic [3:0] read_data_array;

rv32i_word mem_address;
logic [255:0] mem_rdata;
logic [255:0] mem_wdata;
logic mem_read, mem_write, mem_resp;

l2cache_wide_control control
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
	.way_sel (way_sel),
	.pmem_resp (pmem_resp),
	.pmem_write (pmem_write),
	.pmem_read (pmem_read),
	.write_sel (write_sel),
	.load_valid (load_valid),
	.set_valid (set_valid),
	.load_tag (load_tag),
	.load_way_reg (load_way_reg),
	.read_data_array (read_data_array)
);

l2cache_wide_datapath datapath
(
	.clk (clk),
	.rst (rst),
	.mem_address (mem_address),
	.pmem_address (pmem_address),
	.pmem_rdata (pmem_rdata),
	.pmem_wdata (pmem_wdata),
	.mem_wdata (mem_wdata),
	.cache_hit (cache_hit),
	.write_back (write_back),
	.way_reg (way_reg),
	.way (way),
	.load_dirty (load_dirty),
	.set_dirty (set_dirty),
	.load_lru (load_lru),
	.way_sel (way_sel),
	.write_sel (write_sel),
	.load_valid (load_valid),
	.set_valid (set_valid),
	.load_tag (load_tag),
	.load_way_reg (load_way_reg),
	.read_data_array (read_data_array)
);

assign mem_rdata = pmem_wdata;

arbiter arbiter
(
    .clk(clk),
    .rst(rst),

    .i_pmem_address(i_mem_address),
    .i_pmem_rdata(i_mem_rdata),
    .i_pmem_wdata(i_mem_wdata),
    .i_pmem_read(i_mem_read),
    .i_pmem_write(i_mem_write),
    .i_pmem_resp(i_mem_resp),

    .d_pmem_address(d_mem_address),
    .d_pmem_rdata(d_mem_rdata),
    .d_pmem_wdata(d_mem_wdata),
    .d_pmem_read(d_mem_read),
    .d_pmem_write(d_mem_write),
    .d_pmem_resp(d_mem_resp),

    .c_pmem_address(mem_address),
    .c_pmem_rdata(mem_rdata),
    .c_pmem_wdata(mem_wdata),
    .c_pmem_read(mem_read),
    .c_pmem_write(mem_write),
    .c_pmem_resp(mem_resp)
);

endmodule : l2cache_wide
