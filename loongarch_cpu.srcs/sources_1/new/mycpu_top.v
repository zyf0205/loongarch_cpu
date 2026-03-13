//==============================================================
// 顶层模块：mycpu_top
// 功能：一个极简的单周期/直连式CPU顶层（仅支持 add.w / addi.w / lu12i.w）
// 说明：
//  - 通过 inst_sram_* 接口取指
//  - 暂不实现跳转、访存、流水、异常等
//  - debug_* 输出用于观察“写回阶段”的信息（此处等同于当前指令）
//==============================================================
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,

    //==================== 指令存储器接口 ====================
    output wire        inst_sram_en,    // 指令SRAM使能（读/写总体开关）
    output wire [ 3:0] inst_sram_we,    // 指令SRAM写使能（字节写使能）；取指时为0表示只读
    output wire [31:0] inst_sram_addr,  // 指令SRAM地址（这里直接用PC）
    output wire [31:0] inst_sram_wdata, // 指令SRAM写数据（取指时不用）
    input  wire [31:0] inst_sram_rdata, // 指令SRAM读数据（取回的指令）

    //==================== 数据存储器接口（暂时不用）====================
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,

    //==================== debug 输出 ====================
    output wire [31:0] debug_wb_pc,       // 正在写回的指令PC（此简化CPU里就是当前PC）
    output wire [ 3:0] debug_wb_rf_we,    // 写回寄存器堆写使能（4位通常表示按字节；这里复制rf_we）
    output wire [ 4:0] debug_wb_rf_wnum,  // 写回目的寄存器号
    output wire [31:0] debug_wb_rf_wdata  // 写回数据
);

    // resetn为低有效复位，这里转成高有效reset
    wire reset = ~resetn;

    //==============================================================
    // 1. PC（取指地址）
    //==============================================================

    wire [31:0] pc;       // 当前指令地址PC
    wire [31:0] next_pc;  // 下一条指令地址（由pc_reg产生）

    // PC寄存器模块：负责PC更新
    // 目前 br_taken 固定为0，表示不发生跳转，next_pc通常为pc+4
    pc_reg u_pc(
        .clk      (clk),
        .reset    (reset),
        .br_taken (1'b0),       // 暂时不跳转
        .br_target(32'b0),      // 跳转目标地址（未用）
        .pc       (pc),
        .next_pc  (next_pc)
    );

    // 指令SRAM接口连接：
    //  - 复位期间一般不取指，这里用 ~reset 作为使能
    //  - we=0：只读
    //  - addr=pc：通过PC取指
    assign inst_sram_en    = ~reset;
    assign inst_sram_we    = 4'b0;
    assign inst_sram_addr  = pc;
    assign inst_sram_wdata = 32'b0;

    // 取回的32位指令
    wire [31:0] inst = inst_sram_rdata;

    //==============================================================
    // 2. 译码（拆字段 + 识别指令 + 立即数生成）
    //==============================================================

    //--------- 拆指令字段（按LoongArch格式）---------
    wire [ 4:0] rd    = inst[ 4: 0];  // 目的寄存器
    wire [ 4:0] rj    = inst[ 9: 5];  // 源寄存器1
    wire [ 4:0] rk    = inst[14:10];  // 源寄存器2（add.w用）
    wire [11:0] imm12 = inst[21:10];  // 12位立即数（addi.w用）
    wire [19:0] imm20 = inst[24: 5];  // 20位立即数（lu12i.w用，后续左移12位）

    //--------- 指令识别（用固定opcode/字段匹配）---------
    // add.w  ：通过inst[31:15]匹配特定常量
    // addi.w ：inst[31:22]匹配特定常量
    // lu12i.w：inst[31:25]匹配特定常量
    wire inst_add_w   = (inst[31:15] == 17'b00000000000100000);
    wire inst_addi_w  = (inst[31:22] == 10'b0000001010);
    wire inst_lu12i_w = (inst[31:25] == 7'b0001010);

    //--------- 立即数处理---------
    // imm12：符号扩展到32位
    wire [31:0] imm12_sext  = {{20{imm12[11]}}, imm12};
    // imm20：拼接后左移12位（等价于放到高20位）
    wire [31:0] imm20_shift = {imm20, 12'b0};

    //==============================================================
    // 3. 寄存器堆（Regfile）
    //==============================================================

    wire        rf_we;     // 寄存器堆写使能
    wire [ 4:0] rf_waddr;  // 写地址（目的寄存器号）
    wire [31:0] rf_wdata;  // 写数据（写回值）
    wire [31:0] rf_rdata1; // 读端口1数据（rj）
    wire [31:0] rf_rdata2; // 读端口2数据（rk）

    // 两读一写寄存器堆
    regfile u_regfile(
        .clk   (clk),
        .raddr1(rj),        .rdata1(rf_rdata1), // 读rj
        .raddr2(rk),        .rdata2(rf_rdata2), // 读rk
        .we    (rf_we),     .waddr (rf_waddr),  .wdata(rf_wdata) // 写回
    );

    //==============================================================
    // 4. ALU（执行）
    //==============================================================

    // 操作数1选择：
    //  - 对 lu12i.w：不需要rj的值，这里给0（结果由“直通src2”得到）
    //  - 其他指令：src1=rj的读数
    wire [31:0] alu_src1 = inst_lu12i_w ? 32'b0 : rf_rdata1;

    // 操作数2选择：
    //  - add.w  ：src2=rk的读数
    //  - addi.w ：src2=imm12符号扩展
    //  - lu12i.w：src2=imm20<<12
    //  - 否则   ：默认0
    wire [31:0] alu_src2 = inst_add_w   ? rf_rdata2  :
                           inst_addi_w  ? imm12_sext  :
                           inst_lu12i_w ? imm20_shift :
                                          32'b0;

    // ALU操作编码（one-hot或位定义，取决于你的alu模块约定）
    // 这里：
    //  - alu_op[0]=1 表示加法（add.w / addi.w）
    //  - alu_op[11]=1 表示直通（lu12i.w把src2直接输出）
    wire [11:0] alu_op;
    assign alu_op[ 0] = inst_add_w | inst_addi_w;   // 加法
    assign alu_op[ 1] = 1'b0;
    assign alu_op[ 2] = 1'b0;
    assign alu_op[ 3] = 1'b0;
    assign alu_op[ 4] = 1'b0;
    assign alu_op[ 5] = 1'b0;
    assign alu_op[ 6] = 1'b0;
    assign alu_op[ 7] = 1'b0;
    assign alu_op[ 8] = 1'b0;
    assign alu_op[ 9] = 1'b0;
    assign alu_op[10] = 1'b0;
    assign alu_op[11] = inst_lu12i_w;               // 直通（pass-through）

    wire [31:0] alu_result; // ALU计算结果

    // ALU实例
    alu u_alu(
        .alu_op    (alu_op),
        .alu_src1  (alu_src1),
        .alu_src2  (alu_src2),
        .alu_result(alu_result)
    );

    //==============================================================
    // 5. 写回（把结果写入寄存器堆）
    //==============================================================

    // 这三条指令都会写rd
    assign rf_we    = inst_add_w | inst_addi_w | inst_lu12i_w;
    assign rf_waddr = rd;
    assign rf_wdata = alu_result;

    //==============================================================
    // 6. 数据存储器接口（当前不实现load/store）
    //==============================================================
    // 因为没有实现访存类指令，所以全部拉为无效/0
    assign data_sram_en    = 1'b0;
    assign data_sram_we    = 4'b0;
    assign data_sram_addr  = 32'b0;
    assign data_sram_wdata = 32'b0;

    //==============================================================
    // 7. Debug信号输出
    //==============================================================
    // 注意：严格意义“WB阶段”属于流水线概念；
    // 这里是简化CPU，直接用当前pc / 当前写回控制与数据作为debug输出
    assign debug_wb_pc       = pc;
    assign debug_wb_rf_we    = {4{rf_we}};     // 将1位写使能复制成4位
    assign debug_wb_rf_wnum  = rf_waddr;
    assign debug_wb_rf_wdata = rf_wdata;

endmodule