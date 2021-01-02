import rv32i_types::*;

module control_rom(
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,

    output rv32i_ctrl_word ctrl
);
logic [3:0] wmask, rmask;
logic trap;

store_funct3_t store_funct3;
load_funct3_t load_funct3;
branch_funct3_t branch_funct3;

assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);


function void set_defaults();
    ctrl.mem_read = 1'b0; 
    ctrl.mem_write = 1'b0;
    ctrl.mem_op = 1'b0;

    ctrl.immmux_sel = immmux::i_imm;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::imm;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.pcmux_sel = pcmux::pc_plus4;
    ctrl.cmpmux_sel = cmpmux::i_imm;
    
    ctrl.jmp_op = 1'b0;
    ctrl.br_op = 1'b0;

    ctrl.aluop = alu_add;
    ctrl.cmpop = beq;
    
    ctrl.load_regfile = 1'b0;

    ctrl.opcode = opcode;
    ctrl.funct3 = funct3;

    ctrl.rd_valid = 1'b1;

    ctrl.commit = 1'b0;
	 
	 ctrl.multiplier_start = 1'b0;
	 ctrl.divider_start = 1'b0;
endfunction

always_comb begin
    set_defaults();
    case (opcode)
        op_lui:
        begin
            ctrl.immmux_sel = immmux::u_imm;
            ctrl.regfilemux_sel = regfilemux::u_imm; 
            ctrl.load_regfile = 1'b1;
            ctrl.commit = 1'b1;
        end
        op_auipc: 
        begin
            ctrl.immmux_sel = immmux::u_imm;
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.regfilemux_sel = regfilemux::alu_out;
            ctrl.load_regfile = 1'b1;
            ctrl.commit = 1'b1;
        end
        
        op_jal: 
        begin
            ctrl.immmux_sel = immmux::j_imm;
            ctrl.jmp_op = 1'b1;
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.load_regfile = 1'b1;
            ctrl.commit = 1'b1;
        end
        
        op_jalr: 
        begin
            ctrl.immmux_sel = immmux::i_imm;
            ctrl.jmp_op = 1'b1;
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.load_regfile = 1'b1;
            ctrl.commit = 1'b1;
        end
        op_br: 
        begin
            ctrl.br_op = 1'b1;
            ctrl.immmux_sel = immmux::b_imm;
            ctrl.cmpop = branch_funct3_t'(funct3);
            ctrl.cmpmux_sel = cmpmux::rs2_out;
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.commit = 1'b1;
            ctrl.rd_valid = 1'b0;
        end
        op_load: 
        begin
            ctrl.immmux_sel = immmux::i_imm;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            
            // memory stuff needs to be looked at
            // ctrl.mem_address = alu_out; // figure this out
            ctrl.mem_read = 1'b1;
            ctrl.mem_op = 1'b1;
            // put case statements in whenever we figure out alignment
            unique case (funct3)
                    3'b000: ctrl.regfilemux_sel = regfilemux::lb;
                    3'b001: ctrl.regfilemux_sel = regfilemux::lh;
                    3'b010: ctrl.regfilemux_sel = regfilemux::lw;
                    3'b100: ctrl.regfilemux_sel = regfilemux::lbu;
                    3'b101: ctrl.regfilemux_sel = regfilemux::lhu;
                    default: begin end
                endcase
            ctrl.load_regfile = 1'b1;
            ctrl.commit = 1'b1;
        end
        op_store:
        begin 
            ctrl.immmux_sel = immmux::s_imm;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            
            // memory stuff
            // ctrl.mem_address = alu_out; // figure this out
            // ctrl.wdata = rs2_out;
            ctrl.mem_write = 1'b1;
            ctrl.mem_op = 1'b1;
            ctrl.load_regfile = 1'b0;
            ctrl.commit = 1'b1;
            ctrl.rd_valid = 1'b0;
        end
        op_imm: 
        begin
            ctrl.immmux_sel = immmux::i_imm;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.load_regfile = 1'b1;
            ctrl.commit = 1'b1;
            case (arith_funct3_t'(funct3))
                slt: 
                begin 
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.cmpop = blt;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sltu: 
                begin 
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.cmpop = bltu; 
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sr: 
                begin 
                    case(funct7[5])
                        1'b0: ctrl.aluop = alu_srl;
                        1'b1: ctrl.aluop = alu_sra;
                    endcase
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end
                default: 
                begin 
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                    ctrl.aluop = alu_ops'(funct3);
                end
            endcase
        end
        op_reg: 
        begin
		    ctrl.immmux_sel = immmux::i_imm;
          ctrl.alumux1_sel = alumux::rs1_out;
          ctrl.alumux2_sel = alumux::rs2_out;
          ctrl.load_regfile = 1'b1;
          ctrl.commit = 1'b1;
			 
		    if (funct7 == 7'b0000001) begin	// M-extension
			   case (funct3)
				  3'b000: begin  //MUL
				    ctrl.multiplier_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::mul;
				  end
				  3'b001: begin  //MULH
				    ctrl.multiplier_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::mulh;
				  end
				  3'b010: begin  //MULHSU
				    ctrl.multiplier_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::mulh;
				  end
				  3'b011: begin  //MULHU
				    ctrl.multiplier_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::mulh;
				  end
				  3'b100: begin  //DIV
				    ctrl.divider_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::div;
				  end
				  3'b101: begin  //DIVU
				    ctrl.divider_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::div;
				  end
				  3'b110: begin  //REM
				    ctrl.divider_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::rem;
				  end
				  3'b111: begin  //REMU
				    ctrl.divider_start = 1'b1;
					 ctrl.regfilemux_sel = regfilemux::rem;
				  end
				endcase
			 end 
			 else begin
            case (arith_funct3_t'(funct3))
                slt: 
                begin 
                    ctrl.cmpmux_sel = cmpmux::rs2_out;
                    ctrl.cmpop = blt;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sltu: 
                begin 
                    ctrl.cmpmux_sel = cmpmux::rs2_out;
                    ctrl.cmpop = bltu; 
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end
                sr: 
                begin 
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                    case(funct7[5])
                        1'b0: ctrl.aluop = alu_srl;
                        1'b1: ctrl.aluop = alu_sra;
                    endcase
                end
                add: 
                begin 
                    case(funct7[5])
                        1'b0: ctrl.aluop = alu_add;
                        1'b1: ctrl.aluop = alu_sub;
                    endcase
                end
                default: 
                begin 
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                    ctrl.aluop = alu_ops'(funct3);
                end
            endcase
			 end
        end
        op_csr:
        begin
            /* not going to handle anything with csr (for now) */
        end

        default: set_defaults();
    endcase
end

endmodule
