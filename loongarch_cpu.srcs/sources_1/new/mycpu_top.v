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

    wire reset = ~resetn;   //resetn=0时处于复位状态
    wire [31:0] inst = inst_sram_rdata;     //指令

    // ===== 译码器输出 =====
    wire [ 4:0] rd, rj, rk; //三个寄存器
    wire [11:0] imm12;  //12位立即数
    wire [19:0] imm20;  //20位立即数
    wire [15:0] offs16; //跳转偏移字段
    wire [25:0] offs26; //跳转偏移字段
    //指令识别结果位，由译码器赋值，控制器消费
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
    //指令分类
    wire type_r3, type_load, type_store;

    // ===== 控制器输出 =====
    wire [11:0] alu_op; //运算选择
    wire src1_is_pc, src1_is_zero;  //操作数1来源
    wire src2_is_reg, src2_is_simm12, src2_is_uimm12, src2_is_ui5, src2_is_imm20;   //操作数2来源
    wire rf_we, rf_dst_is_r1, rf_src_is_mem, rf_src_is_link;    //寄存器写回控制
    wire mem_en, raddr2_is_rd;  //数据存储器和第二端口控制

    // ===== 1. PC =====
    wire [31:0] pc, next_pc;
    wire        br_taken;
    wire [31:0] br_target;

    pc_reg u_pc(
               .clk(clk), .reset(reset),
               .br_taken(br_taken), .br_target(br_target),
               .pc(pc), .next_pc(next_pc)
           );

    assign inst_sram_en    = ~reset;    //运行时reset=0，取反使能->取指存储器使能
    assign inst_sram_we    = 4'b0;      //取指令存储器写失能，只读不写
    assign inst_sram_addr  = pc;    //指令地址
    assign inst_sram_wdata = 32'b0; //指令

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
    wire [31:0] rf_rdata1, rf_rdata2;/*寄存器堆读取的两个操作数*/
    wire [ 4:0] rf_waddr = rf_dst_is_r1 ? 5'd1 : rd;/*判断写回寄存器堆的寄存器地址，如果是link型的话就是R1寄存器保存pc+4*/
    wire [31:0] rf_wdata;/*写入数据*/

    regfile u_regfile(
                .clk(clk),
                .raddr1(rj),                                .rdata1(rf_rdata1),
                .raddr2(raddr2_is_rd ? rd : rk),            .rdata2(rf_rdata2),
                .we(rf_we), .waddr(rf_waddr), .wdata(rf_wdata)
            );

    // ===== 5. 立即数扩展 =====
    wire [31:0] imm12_sext  = {{20{imm12[11]}}, imm12};/*有符号扩展*/
    wire [31:0] imm12_zext  = {20'b0, imm12};/*无符号扩展*/
    wire [31:0] imm20_shift = {imm20, 12'b0};/*有符号立即数左移*/
    wire [31:0] ui5_zext    = {27'b0, rk};/*移位数：由rk扩展*/
    /*跳转偏移有符号扩展，在这里左移两位（乘以4），因为pc是以字节为单位的，最终要和pc相加*/
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
    wire rj_eq_rd = (rf_rdata1 == rf_rdata2);/*是否相等*/

    assign br_taken = (inst_beq & rj_eq_rd) | (inst_bne & ~rj_eq_rd)/*判断是否跳转*/
           | inst_b | inst_bl | inst_jirl;

    assign br_target = inst_jirl ? (rf_rdata1 + offs16_sext)
           : (pc + (inst_b|inst_bl ? offs26_sext : offs16_sext));/*得到跳转地址（字节为单位）*/

    // ===== 8. 数据存储器 =====
    wire [1:0] addr_low2 = alu_result[1:0];/*表示当前访问落在 32 位字中的哪个字节位置*/

    assign data_sram_en = mem_en;/*是否访问数据存储器*/

    assign data_sram_we = inst_st_w ? 4'b1111 :
           inst_st_h ? (addr_low2[1] ? 4'b1100 : 4'b0011) :     /*地址在低半区时写低两字节 0011，在高半区时写高两字节 1100*/
           inst_st_b ? (4'b0001 << addr_low2) :     /*用地址最低两位决定到底写第 0/1/2/3 个字节*/
           4'b0000;

    assign data_sram_addr  = alu_result;/*ALU 算出来的有效地址直接作为 DataRAM 地址。*/
    assign data_sram_wdata = inst_st_w ? rf_rdata2 :
           inst_st_h ? {2{rf_rdata2[15:0]}} :   /*低16位复制两份*/
           inst_st_b ? {4{rf_rdata2[7:0]}} :   /*第八位复制四份*/
           rf_rdata2;

    // ===== 9. 读数据处理 =====
    wire [7:0]  load_byte = data_sram_rdata[addr_low2*8 +: 8]; //从start开始向高位连续取8bit
    wire [15:0] load_half = addr_low2[1] ? data_sram_rdata[31:16] : data_sram_rdata[15:0]; //取高16位或者低16位

    /*根据指令类型决定load_result数据*/
    wire [31:0] load_result = inst_ld_w  ? data_sram_rdata :
         inst_ld_b  ? {{24{load_byte[7]}}, load_byte} :
         inst_ld_bu ? {24'b0, load_byte} :
         inst_ld_h  ? {{16{load_half[15]}}, load_half} :
         inst_ld_hu ? {16'b0, load_half} :
         32'b0;

    // ===== 10. 写回 =====
    assign rf_wdata = rf_src_is_mem  ? load_result :    //从内存写回
           rf_src_is_link ? (pc + 32'd4) :       //是链接指令，写回pc+4
           alu_result;      //算数逻辑类，写alu_result

    // ===== 11. Debug =====
    wire debug_rf_we = rf_we & (rf_waddr != 5'b0);      /*寄存器写使能*/

    assign debug_wb_pc      = pc;         /*这条写回对应的pc*/
    assign debug_wb_rf_we   = {4{debug_rf_we}};  /*把一位写使能复制为4位*/
    assign debug_wb_rf_wnum = rf_waddr;   /*导出写回的目的寄存器号*/
    assign debug_wb_rf_wdata= rf_wdata;   /*导出实际写回的数据*/

endmodule
