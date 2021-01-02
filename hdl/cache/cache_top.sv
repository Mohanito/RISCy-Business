import rv32i_types::*;

module cache_top 
(
    input clk,
    input rst,

    input rv32i_word i_mem_address,
    output rv32i_word i_mem_rdata,
    input rv32i_word i_mem_wdata,
    input logic i_mem_read,
    input logic i_mem_write,
    input [3:0] i_mem_byte_enable,
    output logic i_mem_resp,

    input rv32i_word d_mem_address,
    output rv32i_word d_mem_rdata,
    input rv32i_word d_mem_wdata,
    input logic d_mem_read,
    input logic d_mem_write,
    input [3:0] d_mem_byte_enable,
    output logic d_mem_resp,

    output rv32i_word pmem_address,
    input [63:0] pmem_rdata,
    output [63:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp
);

parameter L2_CACHE = 1;
parameter L1_FOUR_WAY = 0;

rv32i_word i_pmem_address, d_pmem_address, c_pmem_address;
logic [255:0] i_pmem_rdata, d_pmem_rdata, c_pmem_rdata;
logic [255:0] i_pmem_wdata, d_pmem_wdata, c_pmem_wdata;
logic i_pmem_read, d_pmem_read, c_pmem_read;
logic i_pmem_write, d_pmem_write, c_pmem_write;
logic i_pmem_resp, d_pmem_resp, c_pmem_resp;
logic i_miss, d_miss, l2_miss, l2_serve;

assign i_miss = (i_pmem_read || i_pmem_write) && i_pmem_resp;
assign d_miss = (d_pmem_read || d_pmem_write) && d_pmem_resp;


generate 
if (L1_FOUR_WAY == 1) begin
cache_wide i_cache (
    .clk(clk),
    .rst(rst),
    .mem_address(i_mem_address),
    .mem_rdata(i_mem_rdata),
    .mem_wdata(i_mem_wdata),
    .mem_read(i_mem_read),
    .mem_write(i_mem_write),
    .mem_byte_enable(i_mem_byte_enable),
    .mem_resp(i_mem_resp),

    .pmem_address(i_pmem_address),
    .pmem_rdata(i_pmem_rdata),
    .pmem_wdata(i_pmem_wdata),
    .pmem_read(i_pmem_read),
    .pmem_write(i_pmem_write),
    .pmem_resp(i_pmem_resp)
);
cache_wide d_cache (
    .clk(clk),
    .rst(rst),
    .mem_address(d_mem_address),
    .mem_rdata(d_mem_rdata),
    .mem_wdata(d_mem_wdata),
    .mem_read(d_mem_read),
    .mem_write(d_mem_write),
    .mem_byte_enable(d_mem_byte_enable),
    .mem_resp(d_mem_resp),

    .pmem_address(d_pmem_address),
    .pmem_rdata(d_pmem_rdata),
    .pmem_wdata(d_pmem_wdata),
    .pmem_read(d_pmem_read),
    .pmem_write(d_pmem_write),
    .pmem_resp(d_pmem_resp)
);
end
else begin
// cache i_cache (
//     .clk(clk),
//     .rst(rst),
//     .mem_address(i_mem_address),
//     .mem_rdata(i_mem_rdata),
//     .mem_wdata(i_mem_wdata),
//     .mem_read(i_mem_read),
//     .mem_write(i_mem_write),
//     .mem_byte_enable(i_mem_byte_enable),
//     .mem_resp(i_mem_resp),

//     .pmem_address(i_pmem_address),
//     .pmem_rdata(i_pmem_rdata),
//     .pmem_wdata(i_pmem_wdata),
//     .pmem_read(i_pmem_read),
//     .pmem_write(i_pmem_write),
//     .pmem_resp(i_pmem_resp)
// );
// cache d_cache (
//     .clk(clk),
//     .rst(rst),
//     .mem_address(d_mem_address),
//     .mem_rdata(d_mem_rdata),
//     .mem_wdata(d_mem_wdata),
//     .mem_read(d_mem_read),
//     .mem_write(d_mem_write),
//     .mem_byte_enable(d_mem_byte_enable),
//     .mem_resp(d_mem_resp),

//     .pmem_address(d_pmem_address),
//     .pmem_rdata(d_pmem_rdata),
//     .pmem_wdata(d_pmem_wdata),
//     .pmem_read(d_pmem_read),
//     .pmem_write(d_pmem_write),
//     .pmem_resp(d_pmem_resp)
// );

given_cache d_cache (
  .clk(clk),

  /* Physical memory signals */
  .pmem_resp(d_pmem_resp),
  .pmem_rdata(d_pmem_rdata),
  .pmem_address(d_pmem_address),
  .pmem_wdata(d_pmem_wdata),
  .pmem_read(d_pmem_read),
  .pmem_write(d_pmem_write),

  /* CPU memory signals */
  .mem_read(d_mem_read),
  .mem_write(d_mem_write),
  .mem_byte_enable_cpu(d_mem_byte_enable),
  .mem_address(d_mem_address),
  .mem_wdata_cpu(d_mem_wdata),
  .mem_resp(d_mem_resp),
  .mem_rdata_cpu(d_mem_rdata)
);

given_cache i_cache (
  .clk(clk),

  /* Physical memory signals */
  .pmem_resp(i_pmem_resp),
  .pmem_rdata(i_pmem_rdata),
  .pmem_address(i_pmem_address),
  .pmem_wdata(i_pmem_wdata),
  .pmem_read(i_pmem_read),
  .pmem_write(i_pmem_write),

  /* CPU memory signals */
  .mem_read(i_mem_read),
  .mem_write(i_mem_write),
  .mem_byte_enable_cpu(4'b1111),
  .mem_address(i_mem_address),
  .mem_wdata_cpu(i_mem_wdata),
  .mem_resp(i_mem_resp),
  .mem_rdata_cpu(i_mem_rdata)
);

end


if (L2_CACHE == 1) begin
l2cache_wide _l2cache (
    .clk(clk),
    .rst(rst),

    .i_mem_address(i_pmem_address),
    .i_mem_rdata(i_pmem_rdata),
    .i_mem_wdata(i_pmem_wdata),
    .i_mem_read(i_pmem_read),
    .i_mem_write(i_pmem_write),
    .i_mem_resp(i_pmem_resp),

    .d_mem_address(d_pmem_address),
    .d_mem_rdata(d_pmem_rdata),
    .d_mem_wdata(d_pmem_wdata),
    .d_mem_read(d_pmem_read),
    .d_mem_write(d_pmem_write),
    .d_mem_resp(d_pmem_resp),

    .pmem_address(c_pmem_address),
    .pmem_rdata(c_pmem_rdata),
    .pmem_wdata(c_pmem_wdata),
    .pmem_read(c_pmem_read),
    .pmem_write(c_pmem_write),
    .pmem_resp(c_pmem_resp)
);
assign l2_serve = (i_pmem_resp || d_pmem_resp);
assign l2_miss = (c_pmem_read || c_pmem_write) && c_pmem_resp;
end 
else begin
arbiter _arbiter (
    .clk(clk),
    .rst(rst),

    .i_pmem_address(i_pmem_address),
    .i_pmem_rdata(i_pmem_rdata),
    .i_pmem_wdata(i_pmem_wdata),
    .i_pmem_read(i_pmem_read),
    .i_pmem_write(i_pmem_write),
    .i_pmem_resp(i_pmem_resp),

    .d_pmem_address(d_pmem_address),
    .d_pmem_rdata(d_pmem_rdata),
    .d_pmem_wdata(d_pmem_wdata),
    .d_pmem_read(d_pmem_read),
    .d_pmem_write(d_pmem_write),
    .d_pmem_resp(d_pmem_resp),

    .c_pmem_address(c_pmem_address),
    .c_pmem_rdata(c_pmem_rdata),
    .c_pmem_wdata(c_pmem_wdata),
    .c_pmem_read(c_pmem_read),
    .c_pmem_write(c_pmem_write),
    .c_pmem_resp(c_pmem_resp)

);
assign l2_serve = 1'b0;
assign l2_miss = 1'b0;
end

endgenerate

cacheline_adaptor _cacheline_adaptor (
	.clk (clk),
	.reset_n (~rst),

	.line_i(c_pmem_wdata),
	.line_o(c_pmem_rdata),
	.address_i(c_pmem_address),
	.read_i(c_pmem_read),
	.write_i(c_pmem_write),
	.resp_o(c_pmem_resp),

	.burst_i(pmem_rdata),
	.burst_o(pmem_wdata),
	.address_o(pmem_address),
	.read_o(pmem_read),
	.write_o(pmem_write),
	.resp_i(pmem_resp)
);
endmodule 