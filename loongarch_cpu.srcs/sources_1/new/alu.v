module alu(
    input  wire [11:0] alu_op,     // 12种操作，独热编码，哪位为1就做哪种运算
    input  wire [31:0] alu_src1,   // 操作数1
    input  wire [31:0] alu_src2,   // 操作数2
    output wire [31:0] alu_result  // 运算结果
);

    wire op_add   = alu_op[ 0];  // 加法
    wire op_sub   = alu_op[ 1];  // 减法
    wire op_slt   = alu_op[ 2];  // 有符号比较 小于置1
    wire op_sltu  = alu_op[ 3];  // 无符号比较 小于置1
    wire op_and   = alu_op[ 4];  // 按位与
    wire op_nor   = alu_op[ 5];  // 按位或非，先或再取反
    wire op_or    = alu_op[ 6];  // 按位或
    wire op_xor   = alu_op[ 7];  // 按位异或
    wire op_sll   = alu_op[ 8];  // 逻辑左移，右边补0
    wire op_srl   = alu_op[ 9];  // 逻辑右移，左边补0
    wire op_sra   = alu_op[10];  // 算术右移，左边补符号位
    wire op_lui   = alu_op[11];  // 直接输出src2（用于LU12I.W）

    // 加减法共用一个加法器
    wire [31:0] adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
    wire        adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;//补码减法需要加1
    wire [32:0] adder_result = {1'b0, alu_src1} + {1'b0, adder_b} + adder_cin;//防止进位，故拼接一位
    // 补码减法: a - b = a + (~b) + 1

    wire [31:0] add_sub_result = adder_result[31:0];//加法器最终结果，去掉最高位

    // 有符号比较: 看减法结果的符号位，但要考虑溢出
    wire slt_result = (alu_src1[31] & ~alu_src2[31])                          // 负-正 → 小于（直接置为1）
                    | (~(alu_src1[31] ^ alu_src2[31]) & adder_result[31]);     // adder_result[31]=1，则减法为小于

    // 无符号比较: 看33位减法是否借位
    wire sltu_result = ~adder_result[32];//够减有进位，不够减没有进位

    // 移位，2^5=32
    wire [31:0] sll_result = alu_src1 << alu_src2[4:0];//逻辑左移
    wire [31:0] srl_result = alu_src1 >> alu_src2[4:0];//逻辑右移，左边补0
    wire [31:0] sra_result = ($signed(alu_src1)) >>> alu_src2[4:0];//算数右移，左边补符号位

    // 最终结果选择
    //32{op_add | op_sub} 将括号里面的最终值复制32份
    assign alu_result = ({32{op_add | op_sub}} & add_sub_result)//加 减
                      | ({32{op_slt}}          & {31'b0, slt_result})//有符号比较，小于为1
                      | ({32{op_sltu}}         & {31'b0, sltu_result})//无符号比较
                      | ({32{op_and}}          & (alu_src1 & alu_src2))//与
                      | ({32{op_nor}}          & ~(alu_src1 | alu_src2))//或非
                      | ({32{op_or}}           & (alu_src1 | alu_src2))//或
                      | ({32{op_xor}}          & (alu_src1 ^ alu_src2))//与或
                      | ({32{op_sll}}          & sll_result)//逻辑左移
                      | ({32{op_srl}}          & srl_result)//逻辑右移
                      | ({32{op_sra}}          & sra_result)//算数右移
                      | ({32{op_lui}}          & alu_src2);//直接输出src2（用于LU12I.W）

endmodule