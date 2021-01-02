/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

import rv32i_types::*;

module cache_wide_datapath
(
	input clk,
	input rst,
	input rv32i_word mem_address,
	output rv32i_word pmem_address,
	input logic [255:0] pmem_rdata,
	input logic [255:0] mem_wdata256,
	input logic [31:0] mem_byte_enable256,
	output logic [255:0] pmem_wdata,
	output logic [3:0] cache_hit,
	output logic write_back,
	output logic [1:0] way_reg,
	output logic [1:0] way,
	input logic [3:0] load_dirty,
	input logic set_dirty,
	input logic load_lru,
	input logic [1:0] way_sel,
	input logic [1:0] write_sel,
	input logic [3:0] load_valid,
	input logic set_valid,
	input logic [3:0] load_tag,
	input logic load_way_reg,
	input logic [3:0] read_data_array
);

logic [2:0] index;
assign index = mem_address[7:5];
logic [23:0] tag;
assign tag = mem_address[31:8];

logic [31:0] write_mask, write_mask1, write_mask2, write_mask3, write_mask4;
logic write_en, write_en1, write_en2, write_en3, write_en4;
logic [255:0] datain, dataout1, dataout2, dataout3, dataout4;
logic comp1, comp2, comp3, comp4;

/********************************* Arrays ************************************/

ram_array data_array1 (
	.byteena_a(write_mask1),
	.data(datain),
	.rdaddress(index),
	.rdclock(~clk),
	.rden(read_data_array[0]),
	.wraddress(index),
	.wrclock(~clk),
	.wren(write_en1),
	.q(dataout1)
	);

ram_array data_array2 (
	.byteena_a(write_mask2),
	.data(datain),
	.rdaddress(index),
	.rdclock(~clk),
	.rden(read_data_array[1]),
	.wraddress(index),
	.wrclock(~clk),
	.wren(write_en2),
	.q(dataout2)
	);

ram_array data_array3 (
	.byteena_a(write_mask3),
	.data(datain),
	.rdaddress(index),
	.rdclock(~clk),
	.rden(read_data_array[2]),
	.wraddress(index),
	.wrclock(~clk),
	.wren(write_en3),
	.q(dataout3)
	);

ram_array data_array4 (
	.byteena_a(write_mask4),
	.data(datain),
	.rdaddress(index),
	.rdclock(~clk),
	.rden(read_data_array[3]),
	.wraddress(index),
	.wrclock(~clk),
	.wren(write_en4),
	.q(dataout4)
	);

/*****************************************************************************/

/***************************** Registers *************************************/

logic [7:0][2:0] lru_array;
logic [2:0] lru;
logic [1:0] lru_way;
logic [2:0] set_lru;
assign lru = lru_array[index];

logic [3:0] dirty_out;
logic [7:0] dirty_array1;
assign dirty_out[0] = dirty_array1[index];
logic [7:0] dirty_array2;
assign dirty_out[1] = dirty_array2[index];
logic [7:0] dirty_array3;
assign dirty_out[2] = dirty_array3[index];
logic [7:0] dirty_array4;
assign dirty_out[3] = dirty_array4[index];

logic [3:0] valid_out;
logic [7:0] valid_array1;
assign valid_out[0] = valid_array1[index];
logic [7:0] valid_array2;
assign valid_out[1] = valid_array2[index];
logic [7:0] valid_array3;
assign valid_out[2] = valid_array3[index];
logic [7:0] valid_array4;
assign valid_out[3] = valid_array4[index];

logic [23:0] tag_out1;
logic [7:0][23:0] tag_array1;
assign tag_out1 = tag_array1[index];
logic [23:0] tag_out2;
logic [7:0][23:0] tag_array2;
assign tag_out2 = tag_array2[index];
logic [23:0] tag_out3;
logic [7:0][23:0] tag_array3;
assign tag_out3 = tag_array3[index];
logic [23:0] tag_out4;
logic [7:0][23:0] tag_array4;
assign tag_out4 = tag_array4[index];

logic [31:0] zext_tag1, zext_tag2, zext_tag3, zext_tag4;
assign zext_tag1 = {tag_out1, index, 5'b0};
assign zext_tag2 = {tag_out2, index, 5'b0};
assign zext_tag3 = {tag_out3, index, 5'b0};
assign zext_tag4 = {tag_out4, index, 5'b0};

always_comb begin
	if(lru[0] === 1'b1) begin
		if(lru[2] === 1'b1) begin
			lru_way = 2'b11;
			write_back = dirty_out[3];
		end
		else begin
			lru_way = 2'b10;
			write_back = dirty_out[2];
		end
	end
	else begin
		if(lru[1] === 1'b1) begin
			lru_way = 2'b01;
			write_back = dirty_out[1];
		end
		else begin
			lru_way = 2'b00;
			write_back = dirty_out[0];
		end
	end
end

always_ff @(posedge clk) begin
	if(rst) begin
		way_reg <= 2'b0;
		lru_array <= 24'b0;
		dirty_array1 <= 8'b0;
		dirty_array2 <= 8'b0;
		dirty_array3 <= 8'b0;
		dirty_array4 <= 8'b0;
		valid_array1 <= 8'b0;
		valid_array2 <= 8'b0;
		valid_array3 <= 8'b0;
		valid_array4 <= 8'b0;
		tag_array1 <= 192'b0;
		tag_array2 <= 192'b0;
		tag_array3 <= 192'b0;
		tag_array4 <= 192'b0;
	end
	else begin
		if(load_way_reg)
			way_reg <= way;
	    if(load_lru)
			lru_array[index] <= set_lru;
		if(load_dirty[0])
			dirty_array1[index] <= set_dirty;
		if(load_dirty[1])
			dirty_array2[index] <= set_dirty;
		if(load_dirty[2])
			dirty_array3[index] <= set_dirty;
		if(load_dirty[3])
			dirty_array4[index] <= set_dirty;
		if(load_valid[0])
			valid_array1[index] <= set_valid;
		if(load_valid[1])
			valid_array2[index] <= set_valid;
		if(load_valid[2])
			valid_array3[index] <= set_valid;
		if(load_valid[3])
			valid_array4[index] <= set_valid;
		if(load_tag[0])
			tag_array1[index] <= tag;
		if(load_tag[1])
			tag_array2[index] <= tag;
		if(load_tag[2])
			tag_array3[index] <= tag;
		if(load_tag[3])
			tag_array4[index] <= tag;
	end
end

/*****************************************************************************/

/******************************* AND and CMP *********************************/

assign comp1 = (tag === tag_out1) ? 1'b1 : 1'b0;
assign comp2 = (tag === tag_out2) ? 1'b1 : 1'b0;
assign comp3 = (tag === tag_out3) ? 1'b1 : 1'b0;
assign comp4 = (tag === tag_out4) ? 1'b1 : 1'b0;
assign cache_hit[0] = (comp1 && valid_out[0]) ? 1'b1 : 1'b0;
assign cache_hit[1] = (comp2 && valid_out[1]) ? 1'b1 : 1'b0;
assign cache_hit[2] = (comp3 && valid_out[2]) ? 1'b1 : 1'b0;
assign cache_hit[3] = (comp4 && valid_out[3]) ? 1'b1 : 1'b0;
always_comb begin
    if (cache_hit[0])
        way = 2'b00;
    else if (cache_hit[1])
        way = 2'b01;
    else if (cache_hit[2])
        way = 2'b10;
    else if (cache_hit[3])
        way = 2'b11;
    else
        way = lru_way;
end

/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES

    unique case (write_sel)
    	2'b00: begin 
			datain = mem_wdata256;
			write_mask = 32'hffffffff;
			write_en = 1'b0;
		end
    	2'b01: begin
			datain = pmem_rdata;
			write_mask = 32'hffffffff;
			write_en = 1'b1;
		end
		2'b10: begin
			datain = mem_wdata256;
			write_mask = mem_byte_enable256;
			write_en = 1'b1;
		end
		default: begin
			datain = mem_wdata256;
			write_mask = 32'hffffffff;
			write_en = 1'b0;
		end
    endcase
    unique case (way_sel)
    	2'b00: begin
    		pmem_address = zext_tag1;
    		pmem_wdata = dataout1;
			write_mask1 = write_mask;
			write_mask2 = 32'b0;
			write_mask3 = 32'b0;
			write_mask4 = 32'b0;
			write_en1 = write_en;
			write_en2 = 1'b0;
			write_en3 = 1'b0;
			write_en4 = 1'b0;
			set_lru[0] = 1'b1;
			set_lru[1] = 1'b1;
			set_lru[2] = lru[2];
    	end
    	2'b01: begin
    		pmem_address = zext_tag2;
    		pmem_wdata = dataout2;
			write_mask1 = 32'b0;
			write_mask2 = write_mask;
			write_mask3 = 32'b0;
			write_mask4 = 32'b0;
			write_en1 = 1'b0;
			write_en2 = write_en;
			write_en3 = 1'b0;
			write_en4 = 1'b0;
			set_lru[0] = 1'b1;
			set_lru[1] = 1'b0;
			set_lru[2] = lru[2];
    	end
    	2'b10: begin
    		pmem_address = zext_tag3;
    		pmem_wdata = dataout3;
			write_mask1 = 32'b0;
			write_mask2 = 32'b0;
			write_mask3 = write_mask;
			write_mask4 = 32'b0;
			write_en1 = 1'b0;
			write_en2 = 1'b0;
			write_en3 = write_en;
			write_en4 = 1'b0;
			set_lru[0] = 1'b0;
			set_lru[1] = lru[1];
			set_lru[2] = 1'b1;
    	end
    	2'b11: begin
    		pmem_address = zext_tag4;
    		pmem_wdata = dataout4;
			write_mask1 = 32'b0;
			write_mask2 = 32'b0;
			write_mask3 = 32'b0;
			write_mask4 = write_mask;
			write_en1 = 1'b0;
			write_en2 = 1'b0;
			write_en3 = 1'b0;
			write_en4 = write_en;
			set_lru[0] = 1'b0;
			set_lru[1] = lru[1];
			set_lru[2] = 1'b0;
    	end
		default: begin
			pmem_address = zext_tag1;
    		pmem_wdata = dataout1;
			write_mask1 = write_mask;
			write_mask2 = 32'b0;
			write_mask3 = 32'b0;
			write_mask4 = 32'b0;
			write_en1 = write_en;
			write_en2 = 1'b0;
			write_en3 = 1'b0;
			write_en4 = 1'b0;
			set_lru[0] = 1'b1;
			set_lru[1] = 1'b1;
			set_lru[2] = lru[2];
		end
    endcase
end
/*****************************************************************************/

endmodule : cache_wide_datapath
