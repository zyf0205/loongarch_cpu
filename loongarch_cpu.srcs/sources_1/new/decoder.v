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

    // 识别出的指令（每条一根线，是就为1）
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
    assign inst_add_w    = (inst[31:15] == 17'b00000000000100000);
    assign inst_sub_w    = (inst[31:15] == 17'b00000000000100010);
    assign inst_slt      = (inst[31:15] == 17'b00000000000100100);
    assign inst_sltu     = (inst[31:15] == 17'b00000000000100101);
    assign inst_nor      = (inst[31:15] == 17'b00000000000101000);
    assign inst_and      = (inst[31:15] == 17'b00000000000101001);
    assign inst_or       = (inst[31:15] == 17'b00000000000101010);
    assign inst_xor      = (inst[31:15] == 17'b00000000000101011);
    assign inst_sll_w    = (inst[31:15] == 17'b00000000000101110);
    assign inst_srl_w    = (inst[31:15] == 17'b00000000000101111);
    assign inst_sra_w    = (inst[31:15] == 17'b00000000000110000);
    assign inst_slli_w   = (inst[31:15] == 17'b00000000010000001);
    assign inst_srli_w   = (inst[31:15] == 17'b00000000010001001);
    assign inst_srai_w   = (inst[31:15] == 17'b00000000010010001);
    assign inst_addi_w   = (inst[31:22] == 10'b0000001010);
    assign inst_slti     = (inst[31:22] == 10'b0000001000);
    assign inst_sltui    = (inst[31:22] == 10'b0000001001);
    assign inst_andi     = (inst[31:22] == 10'b0000001101);
    assign inst_ori      = (inst[31:22] == 10'b0000001110);
    assign inst_xori     = (inst[31:22] == 10'b0000001111);
    assign inst_lu12i_w  = (inst[31:25] == 7'b0001010);
    assign inst_pcaddu12i= (inst[31:25] == 7'b0001110);
    assign inst_beq      = (inst[31:26] == 6'b010110);
    assign inst_bne      = (inst[31:26] == 6'b010111);
    assign inst_b        = (inst[31:26] == 6'b010100);
    assign inst_bl       = (inst[31:26] == 6'b010101);
    assign inst_jirl     = (inst[31:26] == 6'b010011);
    assign inst_ld_w     = (inst[31:22] == 10'b0010100010);
    assign inst_ld_b     = (inst[31:22] == 10'b0010100000);
    assign inst_ld_bu    = (inst[31:22] == 10'b0010101000);
    assign inst_ld_h     = (inst[31:22] == 10'b0010100001);
    assign inst_ld_hu    = (inst[31:22] == 10'b0010101001);
    assign inst_st_w     = (inst[31:22] == 10'b0010100110);
    assign inst_st_b     = (inst[31:22] == 10'b0010100100);
    assign inst_st_h     = (inst[31:22] == 10'b0010100101);

    // 分类
    assign type_r3    = inst_add_w | inst_sub_w | inst_slt  | inst_sltu
                      | inst_nor   | inst_and   | inst_or   | inst_xor
                      | inst_sll_w | inst_srl_w | inst_sra_w;
    assign type_load  = inst_ld_w | inst_ld_b | inst_ld_bu | inst_ld_h | inst_ld_hu;
    assign type_store = inst_st_w | inst_st_b | inst_st_h;

endmodule