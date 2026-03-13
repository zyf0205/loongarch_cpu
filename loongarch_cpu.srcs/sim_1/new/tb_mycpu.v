`timescale 1ns / 1ps

module tb_mycpu;

    reg         clk;
    reg         resetn;

    wire        inst_sram_en;
    wire [ 3:0] inst_sram_we;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;

    wire        data_sram_en;
    wire [ 3:0] data_sram_we;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;

    wire [31:0] debug_wb_pc;
    wire [ 3:0] debug_wb_rf_we;
    wire [ 4:0] debug_wb_rf_wnum;
    wire [31:0] debug_wb_rf_wdata;

    mycpu_top u_cpu(
        .clk              (clk),
        .resetn           (resetn),
        .inst_sram_en     (inst_sram_en),
        .inst_sram_we     (inst_sram_we),
        .inst_sram_addr   (inst_sram_addr),
        .inst_sram_wdata  (inst_sram_wdata),
        .inst_sram_rdata  (inst_sram_rdata),
        .data_sram_en     (data_sram_en),
        .data_sram_we     (data_sram_we),
        .data_sram_addr   (data_sram_addr),
        .data_sram_wdata  (data_sram_wdata),
        .data_sram_rdata  (data_sram_rdata),
        .debug_wb_pc      (debug_wb_pc),
        .debug_wb_rf_we   (debug_wb_rf_we),
        .debug_wb_rf_wnum (debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );

    inst_ram u_inst_ram(
        .en   (inst_sram_en),
        .addr (inst_sram_addr),
        .rdata(inst_sram_rdata)
    );

    data_ram u_data_ram(
        .clk  (clk),
        .en   (data_sram_en),
        .we   (data_sram_we),
        .addr (data_sram_addr),
        .wdata(data_sram_wdata),
        .rdata(data_sram_rdata)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ========== 加载测试程序 ==========
    // 基地址 0x1C000000，每条指令偏移+4
    // 用地址标注方便算跳转偏移
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            u_inst_ram.mem[i] = 32'h03400000;

        // ===== 测试1：BEQ (相等跳转) =====
        // 0x00: ADDI.W r1, r0, 5              r1 = 5
        u_inst_ram.mem[0] = {10'b0000001010, 12'd5, 5'd0, 5'd1};
        // 0x04: ADDI.W r2, r0, 5              r2 = 5
        u_inst_ram.mem[1] = {10'b0000001010, 12'd5, 5'd0, 5'd2};
        // 0x08: BEQ r1, r2, +8  → 跳到 0x10  (offs16 = 8/4 = 2)
        //       编码: 010110 | offs16(16位) | rj(5位) | rd(5位)
        //       BEQ比较rj和rd，offs16=2
        u_inst_ram.mem[2] = {6'b010110, 16'd2, 5'd1, 5'd2};
        // 0x0C: ADDI.W r10, r0, 99            r10 = 99 (应该被跳过)
        u_inst_ram.mem[3] = {10'b0000001010, 12'd99, 5'd0, 5'd10};
        // 0x10: ADDI.W r10, r0, 77            r10 = 77 (跳转目标)
        u_inst_ram.mem[4] = {10'b0000001010, 12'd77, 5'd0, 5'd10};

        // ===== 测试2：BNE (不等跳转) =====
        // 0x14: ADDI.W r3, r0, 3              r3 = 3
        u_inst_ram.mem[5] = {10'b0000001010, 12'd3, 5'd0, 5'd3};
        // 0x18: BNE r1, r3, +8  → 跳到 0x20  (offs16 = 8/4 = 2)
        u_inst_ram.mem[6] = {6'b010111, 16'd2, 5'd1, 5'd3};
        // 0x1C: ADDI.W r11, r0, 99            r11 = 99 (应该被跳过)
        u_inst_ram.mem[7] = {10'b0000001010, 12'd99, 5'd0, 5'd11};
        // 0x20: ADDI.W r11, r0, 88            r11 = 88 (跳转目标)
        u_inst_ram.mem[8] = {10'b0000001010, 12'd88, 5'd0, 5'd11};

        // ===== 测试3：BEQ 不跳（不相等时不跳）=====
        // 0x24: BEQ r1, r3, +8  → 不跳（r1=5, r3=3 不等）
        u_inst_ram.mem[9] = {6'b010110, 16'd2, 5'd1, 5'd3};
        // 0x28: ADDI.W r12, r0, 66            r12 = 66 (不跳转，应该执行)
        u_inst_ram.mem[10] = {10'b0000001010, 12'd66, 5'd0, 5'd12};

        // ===== 测试4：B 无条件跳转 =====
        // 0x2C: B +8  → 跳到 0x34  (offs26 = 8/4 = 2)
        //       编码: 010100 | offs26高16位在inst[25:10] | offs26低10位在inst[9:0]
        //       offs26 = 2 = 26'b00_0000_0000_0000_0000_0000_0010
        //       inst[25:10] = offs26[25:10] = 0, inst[9:0] = offs26[9:0] = 2
        //       但注意拼接：offs26 = {inst[9:0], inst[25:10]}
        //       所以要反过来：inst[9:0]=offs26高位, inst[25:10]=offs26低位
        //       offs26 = 2, 高10位=0, 低16位=2
        //       inst = {6'b010100, 16'd2, 10'd0}
        u_inst_ram.mem[11] = {6'b010100, 16'd2, 10'd0};
        // 0x30: ADDI.W r13, r0, 99            r13 = 99 (应该被跳过)
        u_inst_ram.mem[12] = {10'b0000001010, 12'd99, 5'd0, 5'd13};
        // 0x34: ADDI.W r13, r0, 55            r13 = 55 (跳转目标)
        u_inst_ram.mem[13] = {10'b0000001010, 12'd55, 5'd0, 5'd13};

        // ===== 测试5：BL 跳转并链接 =====
        // 0x38: BL +8  → 跳到 0x40, r1 = 0x3C (PC+4)
        u_inst_ram.mem[14] = {6'b010101, 16'd2, 10'd0};
        // 0x3C: ADDI.W r14, r0, 99            (被跳过)
        u_inst_ram.mem[15] = {10'b0000001010, 12'd99, 5'd0, 5'd14};
        // 0x40: ADDI.W r14, r0, 44            r14 = 44 (跳转目标)
        u_inst_ram.mem[16] = {10'b0000001010, 12'd44, 5'd0, 5'd14};

        // ===== 测试6：JIRL 间接跳转 =====
        // r1现在 = BL存的返回地址 = 0x1C00003C
        // 0x44: ADDI.W r6, r0, 20             r6 = 20
        u_inst_ram.mem[17] = {10'b0000001010, 12'd20, 5'd0, 5'd6};
        // 0x48: LU12I.W r7, 0x1C000           r7 = 0x1C000000
        u_inst_ram.mem[18] = {7'b0001010, 20'h1C000, 5'd7};
        // 0x4C: ORI r7, r7, 0x58              r7 = 0x1C000058 (目标地址)
        u_inst_ram.mem[19] = {10'b0000001110, 12'h058, 5'd7, 5'd7};
        // 0x50: JIRL r8, r7, 0  → 跳到r7=0x1C000058, r8=PC+4=0x1C000054
        u_inst_ram.mem[20] = {6'b010011, 16'd0, 5'd7, 5'd8};
        // 0x54: ADDI.W r15, r0, 99            (被跳过)
        u_inst_ram.mem[21] = {10'b0000001010, 12'd99, 5'd0, 5'd15};
        // 0x58: ADDI.W r15, r0, 33            r15 = 33 (JIRL目标)
        u_inst_ram.mem[22] = {10'b0000001010, 12'd33, 5'd0, 5'd15};

        // ===== 测试7：循环（用BNE实现）=====
        // r20 = 0, 循环5次 r20 = r20 + 1
        // 0x5C: ADDI.W r20, r0, 0             r20 = 0 (循环计数器)
        u_inst_ram.mem[23] = {10'b0000001010, 12'd0, 5'd0, 5'd20};
        // 0x60: ADDI.W r21, r0, 5             r21 = 5 (循环上限)
        u_inst_ram.mem[24] = {10'b0000001010, 12'd5, 5'd0, 5'd21};
        // 0x64: ADDI.W r20, r20, 1            r20 = r20 + 1 (循环体)
        u_inst_ram.mem[25] = {10'b0000001010, 12'd1, 5'd20, 5'd20};
        // 0x68: BNE r20, r21, -4  → 如果r20!=r21, 跳回0x64 (offs16 = -4/4 = -1)
        u_inst_ram.mem[26] = {6'b010111, 16'hFFFF, 5'd20, 5'd21};
        // 0x6C: 循环结束后到达这里
    end

    // ========== 实时打印 ==========
    always @(posedge clk) begin
        if (resetn && inst_sram_en) begin
            if (debug_wb_rf_we != 4'b0)
                $display("[exec] PC=0x%08h  r%0d <- 0x%08h",
                         debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
            else if (u_cpu.br_taken)
                $display("[jump] PC=0x%08h  → 0x%08h",
                         debug_wb_pc, u_cpu.br_target);
        end
    end

    // ========== 检查工具 ==========
    integer pass_count = 0;
    integer fail_count = 0;

    task check_reg;
        input [ 4:0] reg_num;
        input [31:0] expected;
        input [8*40:1] name;
        reg   [31:0] actual;
    begin
        actual = u_cpu.u_regfile.rf[reg_num];
        if (actual === expected) begin
            $display("[PASS] %s : r%0d = 0x%08h", name, reg_num, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s : r%0d got=0x%08h exp=0x%08h",
                     name, reg_num, actual, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ========== 测试流程 ==========
    initial begin
        resetn = 0;
        #50;
        resetn = 1;
        #1500;  // 给循环足够时间

        $display("");
        $display("====== Branch Tests ======");
        check_reg(5'd10, 32'd77,         "BEQ taken: r10=77");
        check_reg(5'd11, 32'd88,         "BNE taken: r11=88");
        check_reg(5'd12, 32'd66,         "BEQ not taken: r12=66");
        check_reg(5'd13, 32'd55,         "B unconditional: r13=55");
        check_reg(5'd14, 32'd44,         "BL target: r14=44");
        check_reg(5'd8,  32'h1C000054,   "JIRL link: r8=PC+4");
        check_reg(5'd15, 32'd33,         "JIRL target: r15=33");
        check_reg(5'd20, 32'd5,          "Loop 5 times: r20=5");
        check_reg(5'd21, 32'd5,          "Loop limit: r21=5");

        $display("");
        $display("============================");
        $display("PASS: %0d   FAIL: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
        $display("============================");
        $finish;
    end

endmodule