import rv32i_types::*;

module arbiter (
    input clk,
    input rst,

    input rv32i_word i_pmem_address,
    output logic [255:0] i_pmem_rdata,
    input logic [255:0] i_pmem_wdata,
    input logic i_pmem_read,
    input logic i_pmem_write,
    output logic i_pmem_resp,

    input rv32i_word d_pmem_address,
    output logic [255:0] d_pmem_rdata,
    input logic [255:0] d_pmem_wdata,
    input logic d_pmem_read,
    input logic d_pmem_write,
    output logic d_pmem_resp,

    output rv32i_word c_pmem_address,
    input logic [255:0] c_pmem_rdata,
    output logic [255:0] c_pmem_wdata,
    output logic c_pmem_read,
    output logic c_pmem_write,
    input logic c_pmem_resp
);

logic serving_i, serving_d;

always_ff @(posedge clk) begin
    if(rst) begin
	     serving_i <= 1'b0;
		  serving_d <= 1'b0;
	 end
    else if(serving_i === 1'b0 && serving_d === 1'b0) begin
        if(i_pmem_read || i_pmem_write)
            serving_i <= 1'b1;
        else if(d_pmem_read || d_pmem_write)
            serving_d <= 1'b1;
    end
    else if(c_pmem_resp === 1'b1) begin
        if(serving_d && (i_pmem_read || i_pmem_write)) begin
            serving_i <= 1'b1;
            serving_d <= 1'b0;
        end
        else if(serving_i && (d_pmem_read || d_pmem_write)) begin
            serving_d <= 1'b1;
            serving_i <= 1'b0;
        end else begin
            serving_i <= 1'b0;
            serving_d <= 1'b0;
        end
    end
end


always_comb begin
    if(serving_i) begin
    	// I-Cache
        i_pmem_rdata = c_pmem_rdata;
        c_pmem_address = i_pmem_address;
        c_pmem_wdata = i_pmem_wdata;
        c_pmem_read = i_pmem_read;
        c_pmem_write = i_pmem_write;
        i_pmem_resp = c_pmem_resp;

        d_pmem_rdata = 256'b0;
        d_pmem_resp = 1'b0;
    end 
    else if(serving_d) begin
        // D-Cache
        d_pmem_rdata = c_pmem_rdata;
        c_pmem_address = d_pmem_address;
        c_pmem_wdata = d_pmem_wdata;
        c_pmem_read = d_pmem_read;
        c_pmem_write = d_pmem_write;
        d_pmem_resp = c_pmem_resp;

        i_pmem_rdata = 256'b0;
        i_pmem_resp = 1'b0;
    end
    else begin
    	c_pmem_address = 32'b0;
        c_pmem_wdata = 256'b0;
        c_pmem_read = 1'b0;
        c_pmem_write = 1'b0;

        i_pmem_rdata = 256'b0;
        i_pmem_resp = 1'b0;

        d_pmem_rdata = 256'b0;
        d_pmem_resp = 1'b0;
    end
end
endmodule
