module controller(
        // 来自decoder的指令识别信号
        /*指令*/
        input  wire inst_add_w, inst_sub_w, inst_slt, inst_sltu,
        input  wire inst_nor, inst_and, inst_or, inst_xor,
        input  wire inst_sll_w, inst_srl_w, inst_sra_w,
        input  wire inst_slli_w, inst_srli_w, inst_srai_w,
        input  wire inst_addi_w, inst_slti, inst_sltui,
        input  wire inst_andi, inst_ori, inst_xori,
        input  wire inst_lu12i_w, inst_pcaddu12i,
        input  wire inst_beq, inst_bne, inst_b, inst_bl, inst_jirl,
        input  wire inst_ld_w, inst_ld_b, inst_ld_bu, inst_ld_h, inst_ld_hu,
        input  wire inst_st_w, inst_st_b, inst_st_h,
        /*指令类型*/
        input  wire type_r3, type_load, type_store,

        // 输出控制信号
        output wire [11:0] alu_op,         // ALU操作码
        output wire        src1_is_pc,     // ALU src1 选PC
        output wire        src1_is_zero,   // ALU src1 选0
        output wire        src2_is_reg,    // ALU src2 选寄存器
        output wire        src2_is_simm12, // ALU src2 选符号扩展imm12
        output wire        src2_is_uimm12, // ALU src2 选零扩展imm12
        output wire        src2_is_ui5,    // ALU src2 选5位移位量
        output wire        src2_is_imm20,  // ALU src2 选imm20<<12
        output wire        rf_we,          // 寄存器堆写使能
        output wire        rf_dst_is_r1,   // 写地址选r1（BL用）
        output wire        rf_src_is_mem,  // 写数据来自内存
        output wire        rf_src_is_link, // 写数据来自PC+4
        output wire        mem_en,         // 数据存储器使能
        output wire        raddr2_is_rd    // 读端口2选rd
    );

    // ALU操作码
    assign alu_op[ 0] = inst_add_w | inst_addi_w | type_load | type_store | inst_pcaddu12i;
    assign alu_op[ 1] = inst_sub_w;
    assign alu_op[ 2] = inst_slt   | inst_slti;
    assign alu_op[ 3] = inst_sltu  | inst_sltui;
    assign alu_op[ 4] = inst_and   | inst_andi;
    assign alu_op[ 5] = inst_nor;
    assign alu_op[ 6] = inst_or    | inst_ori;
    assign alu_op[ 7] = inst_xor   | inst_xori;
    assign alu_op[ 8] = inst_sll_w | inst_slli_w;
    assign alu_op[ 9] = inst_srl_w | inst_srli_w;
    assign alu_op[10] = inst_sra_w | inst_srai_w;
    assign alu_op[11] = inst_lu12i_w;

    // ALU操作数来源
    assign src1_is_pc     = inst_pcaddu12i;/*rd = PC + SignExtend(si20 << 12)*/
    assign src1_is_zero   = inst_lu12i_w;/*rd=SignExtend(si20≪12)*/
    assign src2_is_reg    = type_r3;
    assign src2_is_simm12 = inst_addi_w | inst_slti | inst_sltui | type_load | type_store;
    assign src2_is_uimm12 = inst_andi | inst_ori | inst_xori;
    assign src2_is_ui5    = inst_slli_w | inst_srli_w | inst_srai_w;
    assign src2_is_imm20  = inst_lu12i_w | inst_pcaddu12i;

    // 写回控制
    wire rf_we_alu  = type_r3 | inst_addi_w | inst_slti | inst_sltui
         | inst_andi | inst_ori | inst_xori
         | inst_slli_w | inst_srli_w | inst_srai_w
         | inst_lu12i_w | inst_pcaddu12i;
    wire rf_we_link = inst_bl | inst_jirl;
    wire rf_we_load = type_load;

    assign rf_we          = rf_we_alu | rf_we_link | rf_we_load;
    assign rf_dst_is_r1   = inst_bl;/*把返回地址写到R1*/
    assign rf_src_is_mem  = type_load;/*把 DataRAM 读到的数据写回寄存器堆*/
    assign rf_src_is_link = inst_bl | inst_jirl;/*写回pc+4即返回地址*/

    // 存储器控制
    assign mem_en      = type_load | type_store;
    assign raddr2_is_rd = inst_beq | inst_bne | type_store;/*根据指令判断 寄存器堆读口2到底读 rk 还是 rd*/

endmodule
