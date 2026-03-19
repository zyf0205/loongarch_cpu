`include "loongarch_defs.vh"

module decoder(
        input  wire [31:0] inst,

        // 拆出的字段
        output wire [ 4:0] rd,
        output wire [ 4:0] rj,
        output wire [ 4:0] rk,
        output wire [11:0] imm12,
        output wire [19:0] imm20,
        output wire [15:0] offs16,
        output wire [25:0] offs26,

        // 识别出的指令（每条一根线，是就为1，共35条指令）
        output wire inst_add_w,
        output wire inst_sub_w,
        output wire inst_slt,
        output wire inst_sltu,
        output wire inst_nor,
        output wire inst_and,
        output wire inst_or,
        output wire inst_xor,
        output wire inst_sll_w,
        output wire inst_srl_w,
        output wire inst_sra_w,
        output wire inst_slli_w,
        output wire inst_srli_w,
        output wire inst_srai_w,
        output wire inst_addi_w,
        output wire inst_slti,
        output wire inst_sltui,
        output wire inst_andi,
        output wire inst_ori,
        output wire inst_xori,
        output wire inst_lu12i_w,
        output wire inst_pcaddu12i,
        output wire inst_beq,
        output wire inst_bne,
        output wire inst_b,
        output wire inst_bl,
        output wire inst_jirl,
        output wire inst_ld_w,
        output wire inst_ld_b,
        output wire inst_ld_bu,
        output wire inst_ld_h,
        output wire inst_ld_hu,
        output wire inst_st_w,
        output wire inst_st_b,
        output wire inst_st_h,

        // 分类信号
        output wire type_r3,
        output wire type_load,
        output wire type_store
    );

    // 拆字段
    assign rd     = inst[ 4: 0];
    assign rj     = inst[ 9: 5];
    assign rk     = inst[14:10];
    assign imm12  = inst[21:10];
    assign imm20  = inst[24: 5];
    assign offs16 = inst[25:10];
    assign offs26 = {inst[9:0], inst[25:10]};

    // 指令识别
    assign inst_add_w    = (inst[31:15] == `ADD_W);
    assign inst_sub_w    = (inst[31:15] == `SUB_W);
    assign inst_slt      = (inst[31:15] == `SLT_);
    assign inst_sltu     = (inst[31:15] == `SLTU_);
    assign inst_nor      = (inst[31:15] == `NOR_);
    assign inst_and      = (inst[31:15] == `AND_);
    assign inst_or       = (inst[31:15] == `OR_);
    assign inst_xor      = (inst[31:15] == `XOR_);
    assign inst_sll_w    = (inst[31:15] == `SLL_W);
    assign inst_srl_w    = (inst[31:15] == `SRL_W);
    assign inst_sra_w    = (inst[31:15] == `SRA_W);
    assign inst_slli_w   = (inst[31:15] == `SLLI_W);
    assign inst_srli_w   = (inst[31:15] == `SRLI_W);
    assign inst_srai_w   = (inst[31:15] == `SRAI_W);
    assign inst_addi_w   = (inst[31:22] == `ADDI_W);
    assign inst_slti     = (inst[31:22] == `SLTI_);
    assign inst_sltui    = (inst[31:22] == `SLTUI_);
    assign inst_andi     = (inst[31:22] == `ANDI_);
    assign inst_ori      = (inst[31:22] == `ORI_);
    assign inst_xori     = (inst[31:22] == `XORI_);
    assign inst_lu12i_w  = (inst[31:25] == `LU12I);
    assign inst_pcaddu12i= (inst[31:25] == `PCADD);
    assign inst_beq      = (inst[31:26] == `BEQ_);
    assign inst_bne      = (inst[31:26] == `BNE_);
    assign inst_b        = (inst[31:26] == `B_);
    assign inst_bl       = (inst[31:26] == `BL_);
    assign inst_jirl     = (inst[31:26] == `JIRL_);
    assign inst_ld_w     = (inst[31:22] == `LD_W);
    assign inst_ld_b     = (inst[31:22] == `LD_B);
    assign inst_ld_bu    = (inst[31:22] == `LD_BU);
    assign inst_ld_h     = (inst[31:22] == `LD_H);
    assign inst_ld_hu    = (inst[31:22] == `LD_HU);
    assign inst_st_w     = (inst[31:22] == `ST_W);
    assign inst_st_b     = (inst[31:22] == `ST_B);
    assign inst_st_h     = (inst[31:22] == `ST_H);

    // 分类
    assign type_r3    = inst_add_w | inst_sub_w | inst_slt  | inst_sltu
           | inst_nor   | inst_and   | inst_or   | inst_xor
           | inst_sll_w | inst_srl_w | inst_sra_w;
    assign type_load  = inst_ld_w | inst_ld_b | inst_ld_bu | inst_ld_h | inst_ld_hu;
    assign type_store = inst_st_w | inst_st_b | inst_st_h;

endmodule
