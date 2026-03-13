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

    // ==================== 1. PC ====================

    wire [31:0] pc;
    wire [31:0] next_pc;
    wire        br_taken;
    wire [31:0] br_target;

    pc_reg u_pc(
        .clk      (clk),
        .reset    (reset),
        .br_taken (br_taken),
        .br_target(br_target),
        .pc       (pc),
        .next_pc  (next_pc)
    );

    assign inst_sram_en    = ~reset;
    assign inst_sram_we    = 4'b0;
    assign inst_sram_addr  = pc;
    assign inst_sram_wdata = 32'b0;

    wire [31:0] inst = inst_sram_rdata;

    // ==================== 2. 译码 ====================

    wire [ 4:0] rd     = inst[ 4: 0];
    wire [ 4:0] rj     = inst[ 9: 5];
    wire [ 4:0] rk     = inst[14:10];
    wire [11:0] imm12  = inst[21:10];
    wire [19:0] imm20  = inst[24: 5];
    wire [15:0] offs16 = inst[25:10];
    wire [25:0] offs26 = {inst[9:0], inst[25:10]};

    // --- 三寄存器型 ---
    wire inst_add_w  = (inst[31:15] == 17'b00000000000100000);
    wire inst_sub_w  = (inst[31:15] == 17'b00000000000100010);
    wire inst_slt    = (inst[31:15] == 17'b00000000000100100);
    wire inst_sltu   = (inst[31:15] == 17'b00000000000100101);
    wire inst_nor    = (inst[31:15] == 17'b00000000000101000);
    wire inst_and    = (inst[31:15] == 17'b00000000000101001);
    wire inst_or     = (inst[31:15] == 17'b00000000000101010);
    wire inst_xor    = (inst[31:15] == 17'b00000000000101011);
    wire inst_sll_w  = (inst[31:15] == 17'b00000000000101110);
    wire inst_srl_w  = (inst[31:15] == 17'b00000000000101111);
    wire inst_sra_w  = (inst[31:15] == 17'b00000000000110000);

    // --- 移位立即数型 ---
    wire inst_slli_w = (inst[31:15] == 17'b00000000010000001);
    wire inst_srli_w = (inst[31:15] == 17'b00000000010001001);
    wire inst_srai_w = (inst[31:15] == 17'b00000000010010001);

    // --- 12位立即数型 ---
    wire inst_addi_w = (inst[31:22] == 10'b0000001010);
    wire inst_slti   = (inst[31:22] == 10'b0000001000);
    wire inst_sltui  = (inst[31:22] == 10'b0000001001);
    wire inst_andi   = (inst[31:22] == 10'b0000001101);
    wire inst_ori    = (inst[31:22] == 10'b0000001110);
    wire inst_xori   = (inst[31:22] == 10'b0000001111);

    // --- 20位立即数型 ---
    wire inst_lu12i_w = (inst[31:25] == 7'b0001010);

    // --- 跳转指令 ---
    wire inst_beq  = (inst[31:26] == 6'b010110);
    wire inst_bne  = (inst[31:26] == 6'b010111);
    wire inst_b    = (inst[31:26] == 6'b010100);
    wire inst_bl   = (inst[31:26] == 6'b010101);
    wire inst_jirl = (inst[31:26] == 6'b010011);

    // 分类
    wire type_r3  = inst_add_w | inst_sub_w | inst_slt  | inst_sltu
                  | inst_nor   | inst_and   | inst_or   | inst_xor
                  | inst_sll_w | inst_srl_w | inst_sra_w;

    // 立即数扩展
    wire [31:0] imm12_sext  = {{20{imm12[11]}}, imm12};
    wire [31:0] imm12_zext  = {20'b0, imm12};
    wire [31:0] imm20_shift = {imm20, 12'b0};
    wire [31:0] ui5_zext    = {27'b0, rk};
    wire [31:0] offs16_sext = {{14{offs16[15]}}, offs16, 2'b0};
    wire [31:0] offs26_sext = {{ 4{offs26[25]}}, offs26, 2'b0};

    // ==================== 3. 寄存器堆 ====================

    // BEQ/BNE需要比较rj和rd，所以读端口2要选rd
    wire [ 4:0] rf_raddr2 = (inst_beq | inst_bne) ? rd : rk;

    wire        rf_we;
    wire [ 4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;

    regfile u_regfile(
        .clk   (clk),
        .raddr1(rj),          .rdata1(rf_rdata1),
        .raddr2(rf_raddr2),   .rdata2(rf_rdata2),
        .we    (rf_we),       .waddr (rf_waddr),  .wdata(rf_wdata)
    );

    // ==================== 4. ALU ====================

    wire [31:0] alu_src1 = inst_lu12i_w ? 32'b0 : rf_rdata1;

    wire src2_is_reg    = type_r3;
    wire src2_is_simm12 = inst_addi_w | inst_slti | inst_sltui;
    wire src2_is_uimm12 = inst_andi   | inst_ori  | inst_xori;
    wire src2_is_ui5    = inst_slli_w | inst_srli_w | inst_srai_w;

    wire [31:0] alu_src2 = src2_is_reg    ? rf_rdata2  :
                           src2_is_simm12 ? imm12_sext :
                           src2_is_uimm12 ? imm12_zext :
                           src2_is_ui5    ? ui5_zext   :
                           inst_lu12i_w   ? imm20_shift :
                                            32'b0;

    wire [11:0] alu_op;
    assign alu_op[ 0] = inst_add_w  | inst_addi_w;
    assign alu_op[ 1] = inst_sub_w;
    assign alu_op[ 2] = inst_slt    | inst_slti;
    assign alu_op[ 3] = inst_sltu   | inst_sltui;
    assign alu_op[ 4] = inst_and    | inst_andi;
    assign alu_op[ 5] = inst_nor;
    assign alu_op[ 6] = inst_or     | inst_ori;
    assign alu_op[ 7] = inst_xor    | inst_xori;
    assign alu_op[ 8] = inst_sll_w  | inst_slli_w;
    assign alu_op[ 9] = inst_srl_w  | inst_srli_w;
    assign alu_op[10] = inst_sra_w  | inst_srai_w;
    assign alu_op[11] = inst_lu12i_w;

    wire [31:0] alu_result;

    alu u_alu(
        .alu_op    (alu_op),
        .alu_src1  (alu_src1),
        .alu_src2  (alu_src2),
        .alu_result(alu_result)
    );

    // ==================== 5. 跳转逻辑 ====================

    wire rj_eq_rd = (rf_rdata1 == rf_rdata2);

    assign br_taken = (inst_beq  &  rj_eq_rd)
                    | (inst_bne  & ~rj_eq_rd)
                    | inst_b
                    | inst_bl
                    | inst_jirl;

    assign br_target = inst_jirl ? (rf_rdata1 + offs16_sext)
                                 : (pc + (inst_b | inst_bl ? offs26_sext : offs16_sext));

    // ==================== 6. 写回 ====================

    wire need_link = inst_bl | inst_jirl;

    assign rf_we    = type_r3 | src2_is_simm12 | src2_is_uimm12
                    | src2_is_ui5 | inst_lu12i_w | need_link;

    assign rf_waddr = inst_bl ? 5'd1 : rd;

    assign rf_wdata = need_link ? (pc + 32'd4) : alu_result;

    // ==================== 7. 数据存储器（不用）====================

    assign data_sram_en    = 1'b0;
    assign data_sram_we    = 4'b0;
    assign data_sram_addr  = 32'b0;
    assign data_sram_wdata = 32'b0;

    // ==================== 8. Debug ====================

    assign debug_wb_pc      = pc;
    assign debug_wb_rf_we   = {4{rf_we}};
    assign debug_wb_rf_wnum = rf_waddr;
    assign debug_wb_rf_wdata= rf_wdata;

endmodule