module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

    wire reset = ~resetn;
    wire [31:0] inst = inst_sram_rdata;

    // ===== 译码器输出 =====
    wire [ 4:0] rd, rj, rk;
    wire [11:0] imm12;
    wire [19:0] imm20;
    wire [15:0] offs16;
    wire [25:0] offs26;
    wire inst_add_w, inst_sub_w, inst_slt, inst_sltu;
    wire inst_nor, inst_and, inst_or, inst_xor;
    wire inst_sll_w, inst_srl_w, inst_sra_w;
    wire inst_slli_w, inst_srli_w, inst_srai_w;
    wire inst_addi_w, inst_slti, inst_sltui;
    wire inst_andi, inst_ori, inst_xori;
    wire inst_lu12i_w, inst_pcaddu12i;
    wire inst_beq, inst_bne, inst_b, inst_bl, inst_jirl;
    wire inst_ld_w, inst_ld_b, inst_ld_bu, inst_ld_h, inst_ld_hu;
    wire inst_st_w, inst_st_b, inst_st_h;
    wire type_r3, type_load, type_store;

    // ===== 控制器输出 =====
    wire [11:0] alu_op;
    wire src1_is_pc, src1_is_zero;
    wire src2_is_reg, src2_is_simm12, src2_is_uimm12, src2_is_ui5, src2_is_imm20;
    wire rf_we, rf_dst_is_r1, rf_src_is_mem, rf_src_is_link;
    wire mem_en, raddr2_is_rd;

    // ===== 1. PC =====
    wire [31:0] pc, next_pc;
    wire        br_taken;
    wire [31:0] br_target;

    pc_reg u_pc(
        .clk(clk), .reset(reset),
        .br_taken(br_taken), .br_target(br_target),
        .pc(pc), .next_pc(next_pc)
    );

    assign inst_sram_en    = ~reset;
    assign inst_sram_we    = 4'b0;
    assign inst_sram_addr  = pc;
    assign inst_sram_wdata = 32'b0;

    // ===== 2. 译码 =====
    decoder u_dec(
        .inst(inst),
        .rd(rd), .rj(rj), .rk(rk),
        .imm12(imm12), .imm20(imm20), .offs16(offs16), .offs26(offs26),
        .inst_add_w(inst_add_w), .inst_sub_w(inst_sub_w),
        .inst_slt(inst_slt), .inst_sltu(inst_sltu),
        .inst_nor(inst_nor), .inst_and(inst_and),
        .inst_or(inst_or), .inst_xor(inst_xor),
        .inst_sll_w(inst_sll_w), .inst_srl_w(inst_srl_w), .inst_sra_w(inst_sra_w),
        .inst_slli_w(inst_slli_w), .inst_srli_w(inst_srli_w), .inst_srai_w(inst_srai_w),
        .inst_addi_w(inst_addi_w), .inst_slti(inst_slti), .inst_sltui(inst_sltui),
        .inst_andi(inst_andi), .inst_ori(inst_ori), .inst_xori(inst_xori),
        .inst_lu12i_w(inst_lu12i_w), .inst_pcaddu12i(inst_pcaddu12i),
        .inst_beq(inst_beq), .inst_bne(inst_bne),
        .inst_b(inst_b), .inst_bl(inst_bl), .inst_jirl(inst_jirl),
        .inst_ld_w(inst_ld_w), .inst_ld_b(inst_ld_b), .inst_ld_bu(inst_ld_bu),
        .inst_ld_h(inst_ld_h), .inst_ld_hu(inst_ld_hu),
        .inst_st_w(inst_st_w), .inst_st_b(inst_st_b), .inst_st_h(inst_st_h),
        .type_r3(type_r3), .type_load(type_load), .type_store(type_store)
    );

    // ===== 3. 控制器 =====
    controller u_ctrl(
        .inst_add_w(inst_add_w), .inst_sub_w(inst_sub_w),
        .inst_slt(inst_slt), .inst_sltu(inst_sltu),
        .inst_nor(inst_nor), .inst_and(inst_and),
        .inst_or(inst_or), .inst_xor(inst_xor),
        .inst_sll_w(inst_sll_w), .inst_srl_w(inst_srl_w), .inst_sra_w(inst_sra_w),
        .inst_slli_w(inst_slli_w), .inst_srli_w(inst_srli_w), .inst_srai_w(inst_srai_w),
        .inst_addi_w(inst_addi_w), .inst_slti(inst_slti), .inst_sltui(inst_sltui),
        .inst_andi(inst_andi), .inst_ori(inst_ori), .inst_xori(inst_xori),
        .inst_lu12i_w(inst_lu12i_w), .inst_pcaddu12i(inst_pcaddu12i),
        .inst_beq(inst_beq), .inst_bne(inst_bne),
        .inst_b(inst_b), .inst_bl(inst_bl), .inst_jirl(inst_jirl),
        .inst_ld_w(inst_ld_w), .inst_ld_b(inst_ld_b), .inst_ld_bu(inst_ld_bu),
        .inst_ld_h(inst_ld_h), .inst_ld_hu(inst_ld_hu),
        .inst_st_w(inst_st_w), .inst_st_b(inst_st_b), .inst_st_h(inst_st_h),
        .type_r3(type_r3), .type_load(type_load), .type_store(type_store),
        .alu_op(alu_op),
        .src1_is_pc(src1_is_pc), .src1_is_zero(src1_is_zero),
        .src2_is_reg(src2_is_reg), .src2_is_simm12(src2_is_simm12),
        .src2_is_uimm12(src2_is_uimm12), .src2_is_ui5(src2_is_ui5),
        .src2_is_imm20(src2_is_imm20),
        .rf_we(rf_we), .rf_dst_is_r1(rf_dst_is_r1),
        .rf_src_is_mem(rf_src_is_mem), .rf_src_is_link(rf_src_is_link),
        .mem_en(mem_en), .raddr2_is_rd(raddr2_is_rd)
    );

    // ===== 4. 寄存器堆 =====
    wire [31:0] rf_rdata1, rf_rdata2;
    wire [ 4:0] rf_waddr = rf_dst_is_r1 ? 5'd1 : rd;
    wire [31:0] rf_wdata;

    regfile u_regfile(
        .clk(clk),
        .raddr1(rj),                                .rdata1(rf_rdata1),
        .raddr2(raddr2_is_rd ? rd : rk),            .rdata2(rf_rdata2),
        .we(rf_we), .waddr(rf_waddr), .wdata(rf_wdata)
    );

    // ===== 5. 立即数扩展 =====
    wire [31:0] imm12_sext  = {{20{imm12[11]}}, imm12};
    wire [31:0] imm12_zext  = {20'b0, imm12};
    wire [31:0] imm20_shift = {imm20, 12'b0};
    wire [31:0] ui5_zext    = {27'b0, rk};
    wire [31:0] offs16_sext = {{14{offs16[15]}}, offs16, 2'b0};
    wire [31:0] offs26_sext = {{ 4{offs26[25]}}, offs26, 2'b0};

    // ===== 6. ALU =====
    wire [31:0] alu_src1 = src1_is_pc   ? pc   :
                           src1_is_zero ? 32'b0 :
                                          rf_rdata1;

    wire [31:0] alu_src2 = src2_is_reg    ? rf_rdata2  :
                           src2_is_simm12 ? imm12_sext :
                           src2_is_uimm12 ? imm12_zext :
                           src2_is_ui5    ? ui5_zext   :
                           src2_is_imm20  ? imm20_shift :
                                            32'b0;

    wire [31:0] alu_result;
    alu u_alu(.alu_op(alu_op), .alu_src1(alu_src1), .alu_src2(alu_src2), .alu_result(alu_result));

    // ===== 7. 跳转 =====
    wire rj_eq_rd = (rf_rdata1 == rf_rdata2);

    assign br_taken = (inst_beq & rj_eq_rd) | (inst_bne & ~rj_eq_rd)
                    | inst_b | inst_bl | inst_jirl;

    assign br_target = inst_jirl ? (rf_rdata1 + offs16_sext)
                                 : (pc + (inst_b|inst_bl ? offs26_sext : offs16_sext));

    // ===== 8. 数据存储器 =====
    wire [1:0] addr_low2 = alu_result[1:0];

    assign data_sram_en = mem_en;

    assign data_sram_we = inst_st_w ? 4'b1111 :
                          inst_st_h ? (addr_low2[1] ? 4'b1100 : 4'b0011) :
                          inst_st_b ? (4'b0001 << addr_low2) :
                                      4'b0000;

    assign data_sram_addr  = alu_result;
    assign data_sram_wdata = inst_st_w ? rf_rdata2 :
                             inst_st_h ? {2{rf_rdata2[15:0]}} :
                             inst_st_b ? {4{rf_rdata2[7:0]}} :
                                         rf_rdata2;

    // ===== 9. 读数据处理 =====
    wire [7:0]  load_byte = data_sram_rdata[addr_low2*8 +: 8];
    wire [15:0] load_half = addr_low2[1] ? data_sram_rdata[31:16] : data_sram_rdata[15:0];

    wire [31:0] load_result = inst_ld_w  ? data_sram_rdata :
                              inst_ld_b  ? {{24{load_byte[7]}}, load_byte} :
                              inst_ld_bu ? {24'b0, load_byte} :
                              inst_ld_h  ? {{16{load_half[15]}}, load_half} :
                              inst_ld_hu ? {16'b0, load_half} :
                                           32'b0;

    // ===== 10. 写回 =====
    assign rf_wdata = rf_src_is_mem  ? load_result :
                      rf_src_is_link ? (pc + 32'd4) :
                                       alu_result;

    // ===== 11. Debug =====
    assign debug_wb_pc      = pc;
    assign debug_wb_rf_we   = {4{rf_we}};
    assign debug_wb_rf_wnum = rf_waddr;
    assign debug_wb_rf_wdata= rf_wdata;

endmodule