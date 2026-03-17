// ============================================================
// 第1段：准备操作数
// ============================================================
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd7,    5'd0, 5'd1);  n=n+1; // r1=7
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd3,    5'd0, 5'd2);  n=n+1; // r2=3
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'hFFB,  5'd0, 5'd3);  n=n+1; // r3=-5
u_inst_ram.mem[n] = `I20(`LU12I,  20'h12345,      5'd4);  n=n+1; // r4=0x12345000
u_inst_ram.mem[n] = `I12(`ORI_,   12'h678,  5'd4, 5'd4);  n=n+1; // r4=0x12345678
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd0,    5'd0, 5'd5);  n=n+1; // r5=0
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'hFFF,  5'd0, 5'd6);  n=n+1; // r6=-1

// ============================================================
// 第2段：三寄存器运算
// ============================================================
u_inst_ram.mem[n] = `R(`ADD_W,  5'd2, 5'd1, 5'd10); n=n+1; // r10=7+3=10
u_inst_ram.mem[n] = `R(`SUB_W,  5'd2, 5'd1, 5'd11); n=n+1; // r11=7-3=4
u_inst_ram.mem[n] = `R(`SLT_,   5'd1, 5'd3, 5'd12); n=n+1; // r12=(-5<7)=1
u_inst_ram.mem[n] = `R(`SLT_,   5'd3, 5'd1, 5'd13); n=n+1; // r13=(7<-5)=0
u_inst_ram.mem[n] = `R(`SLTU_,  5'd6, 5'd1, 5'd14); n=n+1; // r14=(7<0xFFFFFFFF)=1
u_inst_ram.mem[n] = `R(`AND_,   5'd6, 5'd4, 5'd15); n=n+1; // r15=0x12345678
u_inst_ram.mem[n] = `R(`OR_,    5'd2, 5'd1, 5'd16); n=n+1; // r16=7
u_inst_ram.mem[n] = `R(`XOR_,   5'd2, 5'd1, 5'd17); n=n+1; // r17=4
u_inst_ram.mem[n] = `R(`NOR_,   5'd0, 5'd1, 5'd18); n=n+1; // r18=~7
u_inst_ram.mem[n] = `R(`SLL_W,  5'd2, 5'd1, 5'd19); n=n+1; // r19=56
u_inst_ram.mem[n] = `R(`SRL_W,  5'd1, 5'd6, 5'd20); n=n+1; // r20=0x01FFFFFF
u_inst_ram.mem[n] = `R(`SRA_W,  5'd2, 5'd3, 5'd21); n=n+1; // r21=-1

// ============================================================
// 第3段：立即数运算
// ============================================================
u_inst_ram.mem[n] = `I12(`SLTI_,  12'd10,  5'd1, 5'd22); n=n+1; // r22=1
u_inst_ram.mem[n] = `I12(`SLTUI_, 12'd3,   5'd1, 5'd23); n=n+1; // r23=0
u_inst_ram.mem[n] = `I12(`ANDI_,  12'h0FF, 5'd4, 5'd24); n=n+1; // r24=0x78
u_inst_ram.mem[n] = `I12(`ORI_,   12'h0F0, 5'd1, 5'd25); n=n+1; // r25=0xF7
u_inst_ram.mem[n] = `I12(`XORI_,  12'h0FF, 5'd1, 5'd26); n=n+1; // r26=0xF8
u_inst_ram.mem[n] = `R(`SLLI_W,   5'd4,    5'd1, 5'd27); n=n+1; // r27=0x70
u_inst_ram.mem[n] = `R(`SRLI_W,   5'd24,   5'd6, 5'd28); n=n+1; // r28=0xFF
u_inst_ram.mem[n] = `R(`SRAI_W,   5'd2,    5'd3, 5'd29); n=n+1; // r29=-2

// ============================================================
// 第4段：PCADDU12I
// ============================================================
u_inst_ram.mem[n] = `I20(`PCADD, 20'd1, 5'd30); n=n+1;

// ============================================================
// 第5段：访存
// ============================================================
u_inst_ram.mem[n] = `I12(`ST_W, 12'd0,  5'd5, 5'd4);  n=n+1; // mem[0]=r4
u_inst_ram.mem[n] = `I12(`LD_W, 12'd0,  5'd5, 5'd10); n=n+1; // r10=mem[0]

u_inst_ram.mem[n] = `I20(`LU12I, 20'h80FF8, 5'd7);    n=n+1; // r7=0x80FF8000
u_inst_ram.mem[n] = `I12(`ORI_,  12'h0FE,  5'd7, 5'd7); n=n+1; // r7=0x80FF80FE
u_inst_ram.mem[n] = `I12(`ST_W,  12'd4,    5'd5, 5'd7); n=n+1; // mem[4]=r7

u_inst_ram.mem[n] = `I12(`LD_B,  12'd4,    5'd5, 5'd11); n=n+1; // sext(FE)
u_inst_ram.mem[n] = `I12(`LD_BU, 12'd4,    5'd5, 5'd12); n=n+1; // zext(FE)
u_inst_ram.mem[n] = `I12(`LD_H,  12'd4,    5'd5, 5'd13); n=n+1; // sext(80FE)
u_inst_ram.mem[n] = `I12(`LD_HU, 12'd4,    5'd5, 5'd14); n=n+1; // zext(80FE)
u_inst_ram.mem[n] = `I12(`LD_H,  12'd6,    5'd5, 5'd15); n=n+1; // sext(80FF)
u_inst_ram.mem[n] = `I12(`LD_HU, 12'd6,    5'd5, 5'd16); n=n+1; // zext(80FF)

u_inst_ram.mem[n] = `I12(`ST_W,  12'd8,    5'd5, 5'd0); n=n+1; // mem[8]=0
u_inst_ram.mem[n] = `I12(`ORI_,  12'h0AB,  5'd0, 5'd8); n=n+1; // r8=0xAB
u_inst_ram.mem[n] = `I12(`ST_B,  12'd8,    5'd5, 5'd8); n=n+1; // mem[8].byte0=AB
u_inst_ram.mem[n] = `I12(`ORI_,  12'h0CD,  5'd0, 5'd9); n=n+1; // r9=0xCD
u_inst_ram.mem[n] = `I12(`ST_B,  12'd9,    5'd5, 5'd9); n=n+1; // mem[8].byte1=CD
u_inst_ram.mem[n] = `I12(`LD_W,  12'd8,    5'd5, 5'd17); n=n+1; // r17=0x0000CDAB

u_inst_ram.mem[n] = `I12(`ST_W,  12'd12,   5'd5, 5'd0); n=n+1; // mem[12]=0
u_inst_ram.mem[n] = `I20(`LU12I, 20'h0000B, 5'd8);      n=n+1; // r8=0x0000B000
u_inst_ram.mem[n] = `I12(`ORI_,  12'hEEF,   5'd8, 5'd8); n=n+1; // r8=0x0000BEEF
u_inst_ram.mem[n] = `I12(`ST_H,  12'd12,    5'd5, 5'd8); n=n+1; // mem[12]=0x0000BEEF
u_inst_ram.mem[n] = `I12(`LD_W,  12'd12,    5'd5, 5'd18); n=n+1; // r18=0x0000BEEF

// ============================================================
// 第6段：跳转
// ============================================================

// BEQ taken
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd5, 5'd0, 5'd1);  n=n+1; // r1=5
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd5, 5'd0, 5'd2);  n=n+1; // r2=5
u_inst_ram.mem[n] = `BR16(`BEQ_,  16'd2, 5'd1, 5'd2);  n=n+1; // 跳过下一条
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd99,5'd0, 5'd19); n=n+1; // skip
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd11,5'd0, 5'd19); n=n+1; // r19=11

// BNE taken
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd3, 5'd0, 5'd3);  n=n+1; // r3=3
u_inst_ram.mem[n] = `BR16(`BNE_,  16'd2, 5'd1, 5'd3);  n=n+1; // 跳过下一条
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd99,5'd0, 5'd20); n=n+1; // skip
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd22,5'd0, 5'd20); n=n+1; // r20=22

// BEQ not taken
u_inst_ram.mem[n] = `BR16(`BEQ_,  16'd2, 5'd1, 5'd3);  n=n+1; // 不跳
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd33,5'd0, 5'd21); n=n+1; // r21=33

// B
u_inst_ram.mem[n] = `BR26(`B_, 16'd2, 10'd0);          n=n+1; // 跳过下一条
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd99,5'd0, 5'd22); n=n+1; // skip
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd44,5'd0, 5'd22); n=n+1; // r22=44

// BL
u_inst_ram.mem[n] = `BR26(`BL_, 16'd2, 10'd0);         n=n+1; // 跳过下一条，r1=PC+4
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd99,5'd0, 5'd23); n=n+1; // skip
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd55,5'd0, 5'd23); n=n+1; // r23=55

// JIRL
// 这里目标地址固定设置为 0x1C000000 + 4*(当前n+3)
// 因为后面还有：ORI / JIRL / skip / target 这几条关系太绕，
// 为了简单稳妥，这里直接手工写目标低12位 = 0x130
// JIRL
u_inst_ram.mem[n] = `I20(`LU12I, 20'h1C000, 5'd8);       n=n+1; // r8=0x1C000000
u_inst_ram.mem[n] = `I12(`ORI_,  12'h11C,   5'd8, 5'd8); n=n+1; // r8=0x1C00011C
u_inst_ram.mem[n] = `BR16(`JIRL_,16'd0,     5'd8, 5'd24); n=n+1; // r24=PC+4, jump to 0x11C
u_inst_ram.mem[n] = `I12(`ADDI_W,12'd99,    5'd0, 5'd25); n=n+1; // skip
u_inst_ram.mem[n] = `I12(`ADDI_W,12'd66,    5'd0, 5'd25); n=n+1; // r25=66
// ============================================================

// 第7段：循环
// ============================================================
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd0, 5'd0,  5'd26); n=n+1; // sum=0
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd0, 5'd0,  5'd27); n=n+1; // cnt=0
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd5, 5'd0,  5'd28); n=n+1; // limit=5

// loop:
u_inst_ram.mem[n] = `I12(`ADDI_W, 12'd1, 5'd27, 5'd27); n=n+1; // cnt++
u_inst_ram.mem[n] = `R(`ADD_W,     5'd27,5'd26, 5'd26); n=n+1; // sum+=cnt
u_inst_ram.mem[n] = `BR16(`BNE_,   16'hFFFE, 5'd27, 5'd28); n=n+1; // 如果cnt!=5，回跳两条

u_inst_ram.mem[n] = `I12(`ST_W, 12'd16, 5'd5, 5'd26); n=n+1; // mem[16]=sum
u_inst_ram.mem[n] = `I12(`LD_W, 12'd16, 5'd5, 5'd29); n=n+1; // r29=mem[16]