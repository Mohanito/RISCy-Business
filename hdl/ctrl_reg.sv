import rv32i_types::*;

module ctrl_reg
(
    input clk,
    input rst,
    input load,
    input rv32i_ctrl_word in,
    output rv32i_ctrl_word out
);

rv32i_ctrl_word data = '0;

rv32i_ctrl_word reset_val;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= reset_val;
    end
    else if (load)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

always_comb
begin
    reset_val.mem_read = 1'b0; 
    reset_val.mem_write = 1'b0;
    reset_val.mem_op = 1'b0;

    reset_val.immmux_sel = immmux::i_imm;
    reset_val.alumux1_sel = alumux::rs1_out;
    reset_val.alumux2_sel = alumux::imm;
    reset_val.regfilemux_sel = regfilemux::alu_out;
    reset_val.pcmux_sel = pcmux::pc_plus4;
    reset_val.cmpmux_sel = cmpmux::i_imm;
    
    reset_val.jmp_op = 1'b0;
    reset_val.br_op = 1'b0;

    reset_val.aluop = alu_add;
    reset_val.cmpop = beq;
    
    reset_val.load_regfile = 1'b0;

    reset_val.opcode = rv32i_opcode'(7'b0010011);
    reset_val.funct3 = 3'b000;

    reset_val.commit = 1'b0;
    reset_val.multiplier_start = 1'b0;
    reset_val.divider_start = 1'b0;
    reset_val.rd_valid = 1'b0;

    out = data;
end

endmodule : ctrl_reg
