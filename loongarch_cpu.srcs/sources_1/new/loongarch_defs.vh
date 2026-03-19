`ifndef LOONGARCH_DEFS_VH
`define LOONGARCH_DEFS_VH

/*参数宏*/
`define R(op, rk, rj, rd)      {op, rk, rj, rd}
`define I12(op, imm, rj, rd)   {op, imm, rj, rd}
`define I20(op, imm, rd)       {op, imm, rd}
`define BR16(op, off, rj, rd)  {op, off, rj, rd}
`define BR26(op, off_lo16, off_hi10) {op, off_lo16, off_hi10}

//35条指令对应的特征码
`define ADD_W   17'b00000000000100000
`define SUB_W   17'b00000000000100010
`define SLT_    17'b00000000000100100
`define SLTU_   17'b00000000000100101
`define NOR_    17'b00000000000101000
`define AND_    17'b00000000000101001
`define OR_     17'b00000000000101010
`define XOR_    17'b00000000000101011
`define SLL_W   17'b00000000000101110
`define SRL_W   17'b00000000000101111
`define SRA_W   17'b00000000000110000

`define SLLI_W  17'b00000000010000001
`define SRLI_W  17'b00000000010001001
`define SRAI_W  17'b00000000010010001

`define ADDI_W  10'b0000001010
`define SLTI_   10'b0000001000
`define SLTUI_  10'b0000001001
`define ANDI_   10'b0000001101
`define ORI_    10'b0000001110
`define XORI_   10'b0000001111

`define LU12I   7'b0001010
`define PCADD   7'b0001110

`define BEQ_    6'b010110
`define BNE_    6'b010111
`define B_      6'b010100
`define BL_     6'b010101
`define JIRL_   6'b010011

`define LD_W    10'b0010100010
`define LD_B    10'b0010100000
`define LD_BU   10'b0010101000
`define LD_H    10'b0010100001
`define LD_HU   10'b0010101001
`define ST_W    10'b0010100110
`define ST_B    10'b0010100100
`define ST_H    10'b0010100101

`define ALU_ADD  12'b000000000001
`define ALU_SUB  12'b000000000010
`define ALU_SLT  12'b000000000100
`define ALU_SLTU 12'b000000001000
`define ALU_AND  12'b000000010000
`define ALU_NOR  12'b000000100000
`define ALU_OR   12'b000001000000
`define ALU_XOR  12'b000010000000
`define ALU_SLL  12'b000100000000
`define ALU_SRL  12'b001000000000
`define ALU_SRA  12'b010000000000
`define ALU_LUI  12'b100000000000

`endif
