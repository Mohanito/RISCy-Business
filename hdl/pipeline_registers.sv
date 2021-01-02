/* 
 * pipeline_registers.sv
 * Description: definitions for the pipeline registers that will pass
 * control signals down the pipeline.
 */

module if_id_register
(
    input clk, rst, load,
    input logic [31:0] mem_rdata,
    input logic [31:0] if_PC_out,

    output logic [31:0] id_PC_out,
    output rv32i_opcode id_opcode,
    output logic [2:0] id_funct3,
    output logic [6:0] id_funct7,
    output logic [31:0] id_i_imm, id_s_imm, id_b_imm, id_u_imm, id_j_imm,
    output logic [4:0] id_rs1, id_rs2, id_rd
);
    logic [31:0] pc_out;
    assign id_PC_out = pc_out;
    ir IR(
        .*, 
        .load(1'b1), 
        .in(mem_rdata), 
        .funct3(id_funct3), 
        .funct7(id_funct7),
        .opcode(id_opcode),
        .i_imm(id_i_imm),
        .s_imm(id_s_imm),
        .b_imm(id_b_imm),
        .u_imm(id_u_imm),
        .j_imm(id_j_imm),
        .rs1(id_rs1),
        .rs2(id_rs1),
        .rd(id_rs1)
    );

    always_ff @(posedge clk)
    begin
        if (rst)
        begin
            pc_out <= '0;
        end
        else if (load == 1)
        begin
            pc_out <= if_PC_out;
        end
        else
        begin
            pc_out <= id_PC_out;
        end
    end
endmodule

module id_ex_register
(

);
endmodule

module ex_mem_register
(

);
endmodule

module mem_wb_register
(

);
endmodule