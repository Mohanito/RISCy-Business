`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input clk,
    input rst,
	 
	 /**************** From Control ROM ****************/
	 input rv32i_ctrl_word id_ctrl,
	  
	 /**************** To Control ROM ****************/
	 output rv32i_opcode if_opcode, 
	 output logic [2:0] if_funct3, 
	 output logic [6:0] if_funct7,
	 
	 /**************** From I-Cache ****************/
	 input logic i_mem_resp,
	 input logic [31:0] if_i_mem_data,
	 
	 /**************** To I-Cache ****************/
	 output logic [31:0] i_mem_address,
	 output logic i_mem_read,
	 
	 /**************** From D-Cache ****************/
	 input logic d_mem_resp,
	 input logic [31:0] d_mem_data,

	 /**************** To D-Cache ****************/
	 output logic [31:0] d_mem_wdata, d_mem_address,
	 output logic d_mem_write, d_mem_read,
	 output logic [3:0] d_mem_byte_enable
);
/**************** Signals ****************/
logic is_br;
logic ms_flush;//, ms_flush1;
logic halt;

logic if_flush;
logic id_flush;
logic ex_flush;
logic mem_flush;
logic wb_flush;

logic read_regfile;

// load signals for pipeline registers
logic load_if, load_id, load_ex;
logic load_mem, load_wb;

// stall signal
logic data_stall; 
logic data_stall_ctr;

// IF stage:
logic load_pc = 1'b1;	// set pc to be always loading
rv32i_word pcmux1_out, pcmux2_out, if_pc_out;

// IF/ID:
// logic load_ir = 1'b1;	// set ir to be always loading
rv32i_word id_i_imm, id_s_imm, id_b_imm, id_u_imm, id_j_imm;	// Immediate values - go to immmux
logic [4:0] id_rs1, id_rs2, id_rd;	// rs1, rs2 are used by regfile; rd needs to be preserved to later stages.
rv32i_word id_pc_out, id_i_mem_data;

// ID stage:
rv32i_word id_rs1_out, id_rs2_out;
rv32i_word id_imm;

// ID/EX:
rv32i_word ex_pc_out, ex_rs1_out, ex_rs2_out,  ex_imm, ex_i_mem_data;
logic [4:0] ex_rs1, ex_rs2;
logic [4:0] ex_rd;
rv32i_ctrl_word ex_ctrl;

// EX stage:
rv32i_word ex_alumux1_out, ex_alumux2_out, ex_cmpmux_out, ex_alumux3_out, ex_alumux4_out, ex_cmpmux1_out, ex_cmpmux2_out;
logic ex_br_en;
rv32i_word ex_alu_out, ex_rs1_fwd, ex_rs2_fwd;
logic [63:0] ex_multiplier_out;
logic [63:0] ex_divider_out;
logic ex_multiplier_done, ex_divider_done;

// EX/MEM
rv32i_word mem_pc_out, mem_rs1_out, mem_rs2_out, mem_imm, mem_alu_out, mem_i_mem_data;
logic [4:0] mem_rs1, mem_rs2, mem_rd;
logic mem_br_en, mem_is_br;
rv32i_ctrl_word mem_ctrl;

logic trap;
logic [3:0] rmask, wmask;
logic [63:0] mem_multiplier_out;
logic [63:0] mem_divider_out;
rv32i_word d_mem_wdata_in;

// MEM
rv32i_word mem_regfilemux_out, mem_regfilemux_extra, d_mem_data_reg;

// MEM/WB:
rv32i_word wb_br_en;		// Note that br_en is zero-extended to 32 bits
rv32i_word wb_pc_out, wb_rs1_out, wb_rs2_out, wb_imm, wb_alu_out, wb_i_mem_data, wb_d_mem_wdata;
logic [4:0] wb_rs1, wb_rs2, wb_rd;
logic [3:0] wb_rmask, wb_wmask;
logic wb_trap, wb_is_br;

// WB
rv32i_word wb_regfilemux_out, wb_d_mem_data;
rv32i_ctrl_word wb_ctrl;
rv32i_word wb_d_mem_address;

// Datapath <-> Cache
assign i_mem_address = if_pc_out;
assign i_mem_read = 1'b1;
assign d_mem_address = {mem_alu_out[31:2], 2'b0};
assign d_mem_read = mem_ctrl.mem_read;
assign d_mem_write = mem_ctrl.mem_write;
assign d_mem_byte_enable = wmask;

// Casting functions
store_funct3_t store_funct3;
load_funct3_t load_funct3;
branch_funct3_t branch_funct3;

assign branch_funct3 = branch_funct3_t'(mem_ctrl.funct3);
assign load_funct3 = load_funct3_t'(mem_ctrl.funct3);
assign store_funct3 = store_funct3_t'(mem_ctrl.funct3);

logic memory_stall;
assign memory_stall = !i_mem_resp || (!d_mem_resp && mem_ctrl.mem_op);

// misspeculation flush signal
assign halt = is_br & (pcmux2_out + 8 == if_pc_out) & (if_pc_out == id_pc_out + 4) & (if_pc_out == ex_pc_out + 8);
assign ms_flush = is_br && load_ex; 

/**************** Modules ****************/
// IF Modules
pc_register PC(
	.clk 	(clk), .rst (rst),
	.load (load_pc),
	.in   (pcmux2_out),
	.out  (if_pc_out)
);

// IF/ID Modules
ir IR(
    .clk  (clk), .rst (ms_flush),
    .load (load_if),
	.in (if_i_mem_data),
	.funct3 (if_funct3), .funct7 (if_funct7),
	.opcode(if_opcode),
	.i_imm (id_i_imm), .s_imm (id_s_imm), .b_imm (id_b_imm), .u_imm (id_u_imm), .j_imm (id_j_imm),
	.rs1 (id_rs1), .rs2 (id_rs2), .rd (id_rd)
);

register if_id_pc_reg(
    .clk  (clk), .rst (ms_flush), .load (load_if),
    .in   (if_pc_out), .out  (id_pc_out)
);

register if_id_i_mem_data_reg(
    .clk  (clk), .rst (ms_flush), .load (load_if),
    .in   (if_i_mem_data), .out  (id_i_mem_data)
);

// ID Modules
regfile regfile(
  .clk  (clk),	.rst (rst),
  .load (wb_ctrl.load_regfile && load_wb),
  .read (read_regfile),
  .in   (wb_regfilemux_out),
	.src_a (id_rs1),
	.src_b (id_rs2),
	.dest (wb_rd),
  .reg_a (ex_rs1_out),
	.reg_b (ex_rs2_out)
);

// ID/EX:
register id_ex_pc_reg(
    .clk  (clk), .rst (ms_flush /*|| ms_flush1*/), .load (load_id),
    .in   (id_pc_out), .out  (ex_pc_out)
);

register id_ex_i_mem_data_reg(
    .clk  (clk), .rst (ms_flush /*|| ms_flush1*/), .load (load_id),
    .in   (id_i_mem_data), .out  (ex_i_mem_data)
);

register #(.width(5)) id_ex_rs1_reg(
    .clk  (clk), .rst (ms_flush /*|| ms_flush1*/), .load (load_id),
    .in   (id_rs1), .out  (ex_rs1)
);

register #(.width(5)) id_ex_rs2_reg(
    .clk  (clk), .rst (ms_flush /*|| ms_flush1*/), .load (load_id),
    .in   (id_rs2), .out  (ex_rs2)
);

register #(.width(5)) id_ex_rd_reg(
    .clk  (clk), .rst (ms_flush /*|| ms_flush1*/), .load (load_id),
    .in   (id_rd), .out  (ex_rd)
);

register id_ex_imm_reg(
    .clk  (clk), .rst (ms_flush /*|| ms_flush1*/), .load (load_id),
    .in   (id_imm), .out  (ex_imm)
);

ctrl_reg id_ex_ctrl_reg(
    .clk  (clk), .rst (ms_flush /*|| ms_flush1*/), .load (load_id),
    .in   (id_ctrl), .out  (ex_ctrl)
);

// EX stage:
alu ALU(
	 .aluop (ex_ctrl.aluop),
	 .a (ex_alumux3_out),
	 .b (ex_alumux4_out),
	 .f (ex_alu_out)
);

cmp CMP(
    .in_a (ex_cmpmux1_out),
	 .in_b (ex_cmpmux2_out),
	 .cmpop (ex_ctrl.cmpop),
	 .out (ex_br_en)
);

logic ready_o;

logic mult_start;
logic div_start;
logic mult_ip;
logic div_ip;
logic m_finished;

assign mult_start = ex_ctrl.multiplier_start && !mult_ip && !data_stall && !m_finished;

assign div_start = ex_ctrl.divider_start && !div_ip && !data_stall && !m_finished;

add_shift_multiplier multiplier(
    .clk_i          ( clk          ),
    .reset_n_i      ( ~rst      ),	//change later
    .multiplicand_i ( ex_alumux3_out ),
    .multiplier_i   ( ex_alumux4_out ),
    .start_i        ( mult_start ),
    .mul_funct3     ( ex_ctrl.funct3 ),
    .ready_o        ( ready_o ),
    .product_o      ( ex_multiplier_out ),
    .done_o         ( ex_multiplier_done )
);

logic is_signed;
assign is_signed = ~ex_ctrl.funct3[0];

divider divider (
    .clk_i        ( clk          ),
    .reset_i      ( rst      ),	//change later
    .dividend_i   ( ex_alumux3_out ),
    .divisor_i    ( ex_alumux4_out ),
    .start_i      ( div_start ),
    .is_signed_i  ( is_signed ),
    .quotient_o   ( ex_divider_out[31:0] ),
	.remainder_o  ( ex_divider_out[63:32]),
    .done_o       ( ex_divider_done )
);

// EX/MEM
register ex_mem_pc_reg(		// PC Adder + Reg
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_pc_out), .out  (mem_pc_out)
);

register ex_mem_i_mem_data_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_i_mem_data), .out  (mem_i_mem_data)
);

register #(.width(5)) ex_mem_rs1_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_rs1), .out  (mem_rs1)
);

register #(.width(5)) ex_mem_rs2_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_rs2), .out  (mem_rs2)
);

register #(.width(5)) ex_mem_rd_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_rd), .out(mem_rd)
);

register ex_mem_alu_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_alu_out), .out  (mem_alu_out)
);

register ex_mem_rs1_out_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_rs1_fwd), .out  (mem_rs1_out)
);

register ex_mem_rs2_out_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_rs2_fwd), .out  (mem_rs2_out)
);

register #(.width(1)) ex_mem_br_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_br_en), .out  (mem_br_en)
);

register ex_mem_imm_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_imm), .out  (mem_imm)
);

register #(.width(1)) ex_mem_is_br_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (is_br), .out  (mem_is_br)
);

ctrl_reg ex_mem_ctrl_reg(
    .clk  (clk), .rst (rst), .load (load_ex),
    .in   (ex_ctrl), .out  (mem_ctrl)
);

register #(.width(64)) ex_mem_multiplier_reg(
    .clk  (clk), .rst (rst || ex_flush), .load (load_ex),
    .in   (ex_multiplier_out), .out  (mem_multiplier_out)
);

register #(.width(64)) ex_mem_divider_reg(
    .clk  (clk), .rst (rst || ex_flush), .load (load_ex),
    .in   (ex_divider_out), .out  (mem_divider_out)
);

// MEM
always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;
    d_mem_wdata = d_mem_wdata_in;

    case (mem_ctrl.opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: begin
                    case (mem_alu_out[1:0])
                        2'b00: rmask = 4'b1111;
                        2'b01: begin
                            rmask = 4'b1110;
                            trap = 1'b1;
                        end
                        2'b10: begin
                            rmask = 4'b1100;
                            trap = 1'b1;
                        end
                        2'b11: begin
                            rmask = 4'b1000;
                            trap = 1'b1;
                        end
                    endcase
                end
                lh, lhu: begin
                    case (mem_alu_out[1:0])
                        2'b00: rmask = 4'b0011;
                        2'b01: rmask = 4'bXXXX;
                        2'b10: rmask = 4'b1100;
                        2'b11: rmask = 4'bXXXX;
                    endcase
                end
                lb, lbu: begin
                    case (mem_alu_out[1:0])
                        2'b00: rmask = 4'b0001;
                        2'b01: rmask = 4'b0010;
                        2'b10: rmask = 4'b0100;
                        2'b11: rmask = 4'b1000;
                    endcase
                end
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: begin
                    case (mem_alu_out[1:0])
                        2'b00: begin
                            wmask = 4'b1111;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                        2'b01: begin
                            wmask = 4'b1110;
                            trap = 1'b1;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                        2'b10: begin
                            wmask = 4'b1100;
                            trap = 1'b1;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                        2'b11: begin
                            wmask = 4'b1000;
                            trap = 1'b1;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                    endcase
                end
                sh: begin
                    case (mem_alu_out[1:0])
                        2'b00: begin
                            wmask = 4'b0011;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                        2'b01: begin
                            wmask = 4'bXXXX;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                        2'b10: begin
                            wmask = 4'b1100;
                            d_mem_wdata = d_mem_wdata_in << 16;
                        end
                        2'b11: begin
                            wmask = 4'bXXXX;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                    endcase
                end
                sb: begin
                    case (mem_alu_out[1:0])
                        2'b00: begin
                            wmask = 4'b0001;
                            d_mem_wdata = d_mem_wdata_in;
                        end
                        2'b01: begin
                            wmask = 4'b0010;
                            d_mem_wdata = d_mem_wdata_in << 8;
                        end
                        2'b10: begin
                            wmask = 4'b0100;
                            d_mem_wdata = d_mem_wdata_in << 16;
                        end
                        2'b11: begin
                            wmask = 4'b1000;
                            d_mem_wdata = d_mem_wdata_in << 24;
                        end
                    endcase
                end
                default: begin
                    trap = 1;
                    d_mem_wdata = d_mem_wdata_in;
                end
            endcase
        end

        default: trap = 1;
    endcase
end

// MEM/WB
register mem_wb_pc_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_pc_out), .out  (wb_pc_out)	// Goes to regfilemux
);

register mem_wb_i_mem_data_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_i_mem_data), .out  (wb_i_mem_data)
);

register #(.width(5)) mem_wb_rs1_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_rs1), .out  (wb_rs1)
);

register #(.width(5)) mem_wb_rs2_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_rs2), .out  (wb_rs2)
);

register #(.width(5)) mem_wb_rd_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_rd), .out  (wb_rd)	// Goes to regfile in ID stage
);

register mem_wb_br_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   ({31'b0, mem_br_en}), .out  (wb_br_en)	// Zero-extend Module here
);

register mem_wb_alu_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_alu_out), .out  (wb_alu_out)
);

register mem_wb_rs1_out_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_rs1_out), .out  (wb_rs1_out)
);

register mem_wb_rs2_out_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_rs2_out), .out  (wb_rs2_out)
);

register mem_wb_d_mem_data(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (d_mem_data), .out  (wb_d_mem_data)		// Goes to regfilemux
);

register mem_wb_imm_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_imm), .out  (wb_imm)		// Goes to regfilemux
);

register #(.width(1)) mem_wb_is_br_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_is_br), .out  (wb_is_br)
);

ctrl_reg mem_wb_ctrl_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (mem_ctrl), .out  (wb_ctrl)
);

register mem_wb_d_mem_addr_reg(
	.clk  (clk), .rst (rst), .load (load_mem),
	.in   (mem_alu_out), .out (wb_d_mem_address)
);

register mem_wb_regfilemux_extra_reg(
	.clk  (clk), .rst (rst), .load (1'b1),
	.in   (mem_regfilemux_out), .out (mem_regfilemux_extra)
);

register mem_wb_regfilemux_out_reg(
	.clk  (clk), .rst (rst), .load (load_mem),
	.in   (mem_regfilemux_out), .out (wb_regfilemux_out)
);

register #(.width(4)) mem_wb_rmask_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (rmask), .out  (wb_rmask)
);

register #(.width(4)) mem_wb_wmask_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (wmask), .out  (wb_wmask)
);

register #(.width(1)) mem_wb_trap_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (trap), .out  (wb_trap)
);

register mem_wb_mem_wdata_reg(
    .clk  (clk), .rst (rst), .load (load_mem),
    .in   (d_mem_wdata), .out (wb_d_mem_wdata)
);

assign is_br = ex_ctrl.jmp_op || (ex_ctrl.br_op & ex_br_en);

/**************** MUXES ****************/
always_comb begin
  load_if = 1'b1;
  load_id = 1'b1; 
  load_ex = 1'b1;
  load_mem = 1'b1; 
  load_wb = 1'b1;
  load_pc = 1'b1;
  read_regfile = 1'b1;
  data_stall = 1'b0;

  if_flush = 1'b0;
  id_flush = 1'b0;
  ex_flush = 1'b0;
  mem_flush = 1'b0;
  wb_flush = 1'b0;

  ex_rs1_fwd = ex_rs1_out;
  ex_rs2_fwd = ex_rs2_out;

  d_mem_wdata_in = mem_rs2_out;

    // REGFILEMUX
    unique case (mem_ctrl.regfilemux_sel)
        regfilemux::alu_out: mem_regfilemux_out = mem_alu_out;
        regfilemux::br_en: mem_regfilemux_out = {31'b0, mem_br_en}; // already ZEXTed
        regfilemux::u_imm: mem_regfilemux_out = mem_imm;    
        regfilemux::pc_plus4: mem_regfilemux_out = mem_pc_out + 4;          // already +4'ed in EX stage
        regfilemux::lw: begin
            unique case (mem_alu_out[1:0])
                2'b00: mem_regfilemux_out = d_mem_data;
                2'b01: mem_regfilemux_out = {8'b0, d_mem_data[31:8]};
                2'b10: mem_regfilemux_out = {16'b0, d_mem_data[31:16]};
                2'b11: mem_regfilemux_out = {24'b0, d_mem_data[31:24]};
            endcase
        end
        regfilemux::lb: begin 
            unique case (mem_alu_out[1:0])
                2'b00: mem_regfilemux_out = {{24{d_mem_data[7]}}, d_mem_data[7:0]};
                2'b01: mem_regfilemux_out = {{24{d_mem_data[15]}}, d_mem_data[15:8]};
                2'b10: mem_regfilemux_out = {{24{d_mem_data[23]}}, d_mem_data[23:16]};
                2'b11: mem_regfilemux_out = {{24{d_mem_data[31]}}, d_mem_data[31:24]};
            endcase
        end
        regfilemux::lbu: begin
            unique case (mem_alu_out[1:0])
                2'b00: mem_regfilemux_out = {24'b0, d_mem_data[7:0]};
                2'b01: mem_regfilemux_out = {24'b0, d_mem_data[15:8]};
                2'b10: mem_regfilemux_out = {24'b0, d_mem_data[23:16]};
                2'b11: mem_regfilemux_out = {24'b0, d_mem_data[31:24]};
            endcase
        end
        regfilemux::lh: begin
            unique case (mem_alu_out[1:0])
                2'b00: mem_regfilemux_out = {{16{d_mem_data[15]}}, d_mem_data[15:0]};
                2'b01: mem_regfilemux_out = 32'bX; 
                2'b10: mem_regfilemux_out = {{16{d_mem_data[31]}}, d_mem_data[31:16]};
                2'b11: mem_regfilemux_out = 32'bX;
            endcase
        end
        regfilemux::lhu: begin
            unique case (mem_alu_out[1:0])
                2'b00: mem_regfilemux_out = {16'b0, d_mem_data[15:0]};
                2'b01: mem_regfilemux_out = 32'bX; 
                2'b10: mem_regfilemux_out = {16'b0, d_mem_data[31:16]};
                2'b11: mem_regfilemux_out = 32'bX;
            endcase
        end
        regfilemux::mul: mem_regfilemux_out = mem_multiplier_out[31:0];
        regfilemux::mulh: mem_regfilemux_out = mem_multiplier_out[63:32];
        regfilemux::div: mem_regfilemux_out = mem_divider_out[31:0];
        regfilemux::rem: mem_regfilemux_out = mem_divider_out[63:32];
        default: `BAD_MUX_SEL;
    endcase

	// MUX before PCMUX in the datapath diagram
    unique case (is_br)
        1'b0: pcmux1_out = if_pc_out + 4;	// Adder in IF stage
        1'b1: pcmux1_out = ex_pc_out + ex_imm;		// PC <- b_imm + PC if br_en
        default: pcmux1_out = if_pc_out + 4;
	endcase
	 
	 // IMMMUX
	unique case (id_ctrl.immmux_sel)
		  immmux::i_imm: id_imm = id_i_imm;
		  immmux::u_imm: id_imm = id_u_imm;
		  immmux::b_imm: id_imm = id_b_imm;
		  immmux::s_imm: id_imm = id_s_imm;
		  immmux::j_imm: id_imm = id_j_imm;
        default: `BAD_MUX_SEL;
	endcase
	 
	// ALUMUX1
	unique case (ex_ctrl.alumux1_sel)
		alumux::rs1_out: ex_alumux1_out = ex_rs1_out;
		alumux::pc_out:  ex_alumux1_out = ex_pc_out;
        default: `BAD_MUX_SEL;
	endcase
	 
	// ALUMUX2
	unique case (ex_ctrl.alumux2_sel)
        alumux::imm: ex_alumux2_out = ex_imm;
		alumux::rs2_out: ex_alumux2_out = ex_rs2_out;
        default: `BAD_MUX_SEL;
    endcase
	
	// ALUMUX3 - Data Hazards, please see pseudocode in design doc.
	if (ex_ctrl.alumux1_sel == alumux::rs1_out) begin	// no data hazards if alumux1 == pc_out
        if (ex_rs1 == mem_rd && ex_rs1 != 5'b0 && mem_ctrl.rd_valid) begin		// 1 stage away
            if (mem_ctrl.mem_read) begin
				ex_alumux3_out = mem_regfilemux_extra;
				ex_rs1_fwd = mem_regfilemux_extra;
				data_stall = data_stall_ctr ? 1'b0 : 1'b1;
		    end 
		    else begin
                ex_alumux3_out = mem_regfilemux_out;
                ex_rs1_fwd = mem_regfilemux_out;
            end
		end
		    else if (ex_rs1 == wb_rd && ex_rs1 != 5'b0 && wb_ctrl.rd_valid) begin	// 2 stages away
          ex_alumux3_out = wb_regfilemux_out;
          ex_rs1_fwd = wb_regfilemux_out;
		 end
		 else begin 	// no data hazards; set default values.
		     ex_alumux3_out = ex_alumux1_out;
		 end
	end
	else begin
	    ex_alumux3_out = ex_alumux1_out;
	end
	
	// ALUMUX4 - Data Hazards
	if (ex_ctrl.alumux2_sel == alumux::rs2_out) begin
	    if (ex_rs2 == mem_rd && ex_rs2 != 5'b0 && mem_ctrl.rd_valid) begin         
		    if (mem_ctrl.mem_read) begin
				ex_alumux4_out = mem_regfilemux_extra;
				ex_rs2_fwd = mem_regfilemux_extra;
				data_stall = data_stall_ctr ? 1'b0 : 1'b1;
			end
            else begin
		        ex_alumux4_out = mem_regfilemux_out;
		    	ex_rs2_fwd = mem_regfilemux_out;
		    end
		 end
		 else if (ex_rs2 == wb_rd && ex_rs2 != 5'b0 && wb_ctrl.rd_valid) begin
		    ex_alumux4_out = wb_regfilemux_out;
		    ex_rs2_fwd = wb_regfilemux_out;
		 end
		 else begin
		     ex_alumux4_out = ex_alumux2_out;
		 end
	end
	else begin
	    ex_alumux4_out = ex_alumux2_out;
	end
	
	// CMPMUX
	unique case (ex_ctrl.cmpmux_sel)
		cmpmux::rs2_out: ex_cmpmux_out = ex_rs2_out;
		cmpmux::i_imm: ex_cmpmux_out = ex_imm;
		default: `BAD_MUX_SEL;
	endcase
	
   // CMPMUX1 - cmpmux1_out replaces rs1_out as one input to CMP.
	 if (ex_rs1 == mem_rd && ex_rs1 != 5'b0 && mem_ctrl.rd_valid) begin		// 1 stage away
		  if (mem_ctrl.mem_read) begin
		  	    ex_cmpmux1_out = mem_regfilemux_extra;
				ex_rs1_fwd = mem_regfilemux_extra;
				data_stall = data_stall_ctr ? 1'b0 : 1'b1;
		  end
      	else begin
				ex_cmpmux1_out = mem_regfilemux_out;
				ex_rs1_fwd = mem_regfilemux_out;
		end
	 end
	 else if (ex_rs1 == wb_rd && ex_rs1 != 5'b0 && wb_ctrl.rd_valid) begin	// 2 stages away
		ex_cmpmux1_out = wb_regfilemux_out;
		ex_rs1_fwd = wb_regfilemux_out;
	 end
	 else begin 	// no data hazards; set default values.
		ex_cmpmux1_out = ex_rs1_out;
	 end

	// CMPMUX2 - Inserted between original CMPMUX and CMP.
	if (ex_ctrl.cmpmux_sel == cmpmux::rs2_out) begin
	    if (ex_rs2 == mem_rd && ex_rs2 != 5'b0 && mem_ctrl.rd_valid) begin
		    if (mem_ctrl.mem_read) begin
		     	ex_cmpmux2_out = mem_regfilemux_extra;
				ex_rs2_fwd = mem_regfilemux_extra;
				data_stall = data_stall_ctr ? 1'b0 : 1'b1;
			end
            else begin
		        ex_cmpmux2_out = mem_regfilemux_out;
		    	ex_rs2_fwd = mem_regfilemux_out;
		    end
		end
		 else if (ex_rs2 == wb_rd && ex_rs2 != 5'b0 && wb_ctrl.rd_valid) begin
            ex_cmpmux2_out = wb_regfilemux_out;
            ex_rs2_fwd = wb_regfilemux_out;
		 end
		 else begin
		     ex_cmpmux2_out = ex_cmpmux_out;
		 end
	end
	else begin
	    ex_cmpmux2_out = ex_cmpmux_out;
	end

    if (ex_ctrl.opcode == op_store && ex_rs2 == mem_rd && ex_rs2 != 5'b0 && mem_ctrl.rd_valid) begin
        if(mem_ctrl.mem_read) begin
            ex_rs2_fwd = mem_regfilemux_extra;
            data_stall = data_stall_ctr ? 1'b0 : 1'b1;
        end
        else begin
            ex_rs2_fwd = mem_regfilemux_out;
        end
    end
    else if (ex_ctrl.opcode == op_store && ex_rs2 == wb_rd && ex_rs2 != 5'b0 && wb_ctrl.rd_valid) begin
        ex_rs2_fwd = wb_regfilemux_out;
    end

    // PCMUX
    unique case (ex_ctrl.opcode == op_jalr)
        1'b1: begin
            pcmux2_out = (data_stall) ? 32'b0 : ex_rs1_fwd + ex_imm;   // JALR: Target addr <- i_imm + rs1, with LSB set to zero.
        end 
        default: pcmux2_out = pcmux1_out;
    endcase

    // if we have data hazard, handle stalling / if we have RAW, stall for extra cycle
    if (data_stall || mult_start || mult_ip || div_start || div_ip|| !i_mem_resp || (!d_mem_resp && mem_ctrl.mem_op)) begin
      load_pc = 1'b0;
      load_if = 1'b0;
      load_id = 1'b0;
      load_ex = 1'b0;
      load_mem = 1'b0;
      load_wb = 1'b0;
      read_regfile = 1'b0;
    end
end

always_ff @(posedge clk) begin
	if(data_stall && d_mem_resp)
		data_stall_ctr <= 1'b1;
	else
		data_stall_ctr <= 1'b0;

    if(!load_ex && m_finished)
        m_finished <= 1'b1;
    else
        m_finished <= 1'b0;

    if(mult_start)
        mult_ip <= 1'b1;
    else if(mult_ip && !ex_multiplier_done)
        mult_ip <= 1'b1;
    else if(mult_ip && ex_multiplier_done) begin
        m_finished <= 1'b1;
        mult_ip <= 1'b0;
    end
    else
        mult_ip <= 1'b0;

    if(div_start)
        div_ip <= 1'b1;
    else if(div_ip && !ex_divider_done)
        div_ip <= 1'b1;
    else if(div_ip && ex_divider_done) begin
        m_finished <= 1'b1;
        div_ip <= 1'b0;
    end
    else
        div_ip <= 1'b0;

end

endmodule : datapath
