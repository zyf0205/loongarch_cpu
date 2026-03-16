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

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            u_inst_ram.mem[i] = 32'h03400000;

        // ===== 准备基地址 =====
        // 0x00: ADDI.W r1, r0, 0              r1 = 0（数据RAM基地址）
        u_inst_ram.mem[0] = {10'b0000001010, 12'd0, 5'd0, 5'd1};

        // ===== 测试1: ST.W + LD.W (回归测试) =====
        // 0x04: LU12I.W r2, 0x44332          r2 = 0x44332000
        u_inst_ram.mem[1] = {7'b0001010, 20'h44332, 5'd2};
        // 0x08: ORI r2, r2, 0x211            r2 = 0x44332211
        u_inst_ram.mem[2] = {10'b0000001110, 12'h211, 5'd2, 5'd2};
        // 0x0C: ST.W r2, r1, 0               mem[0] = 0x44332211
        u_inst_ram.mem[3] = {10'b0010100110, 12'd0, 5'd1, 5'd2};
        // 0x10: LD.W r10, r1, 0              r10 = 0x44332211
        u_inst_ram.mem[4] = {10'b0010100010, 12'd0, 5'd1, 5'd10};

        // ===== 测试2: LD.B 从不同字节位置读 =====
        // 0x14: LD.B r11, r1, 0              r11 = sext(0x11) = 0x00000011
        u_inst_ram.mem[5] = {10'b0010100000, 12'd0, 5'd1, 5'd11};
        // 0x18: LD.B r12, r1, 1              r12 = sext(0x22) = 0x00000022
        u_inst_ram.mem[6] = {10'b0010100000, 12'd1, 5'd1, 5'd12};
        // 0x1C: LD.B r13, r1, 2              r13 = sext(0x33) = 0x00000033
        u_inst_ram.mem[7] = {10'b0010100000, 12'd2, 5'd1, 5'd13};
        // 0x20: LD.B r14, r1, 3              r14 = sext(0x44) = 0x00000044
        u_inst_ram.mem[8] = {10'b0010100000, 12'd3, 5'd1, 5'd14};

        // ===== 测试3: LD.B 符号扩展 =====
        // 先存一个含0x80的字
        // 0x24: LU12I.W r3, 0x80FF8          r3 = 0x80FF8000
        u_inst_ram.mem[9] = {7'b0001010, 20'h80FF8, 5'd3};
        // 0x28: ORI r3, r3, 0x0FE            r3 = 0x80FF80FE
        u_inst_ram.mem[10] = {10'b0000001110, 12'h0FE, 5'd3, 5'd3};
        // 0x2C: ST.W r3, r1, 4               mem[4] = 0x80FF80FE
        u_inst_ram.mem[11] = {10'b0010100110, 12'd4, 5'd1, 5'd3};
        // 0x30: LD.B r15, r1, 4              r15 = sext(0xFE) = 0xFFFFFFFE
        u_inst_ram.mem[12] = {10'b0010100000, 12'd4, 5'd1, 5'd15};
        // 0x34: LD.BU r16, r1, 4             r16 = zext(0xFE) = 0x000000FE
        u_inst_ram.mem[13] = {10'b0010101000, 12'd4, 5'd1, 5'd16};

        // ===== 测试4: LD.H / LD.HU =====
        // 0x38: LD.H r17, r1, 4              r17 = sext(0x80FE) = 0xFFFF80FE
        u_inst_ram.mem[14] = {10'b0010100001, 12'd4, 5'd1, 5'd17};
        // 0x3C: LD.HU r18, r1, 4             r18 = zext(0x80FE) = 0x000080FE
        u_inst_ram.mem[15] = {10'b0010101001, 12'd4, 5'd1, 5'd18};
        // 0x40: LD.H r19, r1, 6              r19 = sext(0x80FF) = 0xFFFF80FF
        u_inst_ram.mem[16] = {10'b0010100001, 12'd6, 5'd1, 5'd19};
        // 0x44: LD.HU r20, r1, 6             r20 = zext(0x80FF) = 0x000080FF
        u_inst_ram.mem[17] = {10'b0010101001, 12'd6, 5'd1, 5'd20};

        // ===== 测试5: ST.B =====
        // 0x48: ADDI.W r4, r0, 0              r4 = 0
        u_inst_ram.mem[18] = {10'b0000001010, 12'd0, 5'd0, 5'd4};
        // 0x4C: ST.W r4, r1, 8               mem[8] = 0x00000000（先清零）
        u_inst_ram.mem[19] = {10'b0010100110, 12'd8, 5'd1, 5'd4};
        // 0x50: ADDI.W r5, r0, 0xAB           r5 = 0xAB（不对，12位立即数符号扩展）
        // 用ORI代替
        // 0x50: ORI r5, r0, 0xAB              r5 = 0x000000AB
        u_inst_ram.mem[20] = {10'b0000001110, 12'hAB, 5'd0, 5'd5};
        // 0x54: ST.B r5, r1, 8               mem[8] 字节0 = 0xAB → mem[8]=0x000000AB
        u_inst_ram.mem[21] = {10'b0010100100, 12'd8, 5'd1, 5'd5};
        // 0x58: ORI r6, r0, 0xCD              r6 = 0x000000CD
        u_inst_ram.mem[22] = {10'b0000001110, 12'hCD, 5'd0, 5'd6};
        // 0x5C: ST.B r6, r1, 9               mem[8] 字节1 = 0xCD → mem[8]=0x0000CDAB
        u_inst_ram.mem[23] = {10'b0010100100, 12'd9, 5'd1, 5'd6};
        // 0x60: LD.W r21, r1, 8              r21 = 0x0000CDAB
        u_inst_ram.mem[24] = {10'b0010100010, 12'd8, 5'd1, 5'd21};

        // ===== 测试6: ST.H =====
        // 0x64: ST.W r4, r1, 12              mem[12] = 0（先清零）
        u_inst_ram.mem[25] = {10'b0010100110, 12'd12, 5'd1, 5'd4};
        // 0x68: LU12I.W r7, 0x0BEEF          不对，直接用ORI
        // 0x68: ORI r7, r0, 0xEF              r7 = 0xEF
        u_inst_ram.mem[26] = {10'b0000001110, 12'hEF, 5'd0, 5'd7};
        // 0x6C: LU12I.W r8, 0x00BE           r8 = 0x000BE000
        u_inst_ram.mem[27] = {7'b0001010, 20'h000BE, 5'd8};
        // 0x70: ORI r7, r8, 0xEF             r7 = 0x000BE0EF  不对...
        // 简单点：直接构造0xBEEF
        // 0x70: LU12I.W r7, 0x0000B          r7 = 0x0000B000
        u_inst_ram.mem[28] = {7'b0001010, 20'h0000B, 5'd7};
        // 0x74: ORI r7, r7, 0xEEF            r7 = 0x0000BEEF
        u_inst_ram.mem[29] = {10'b0000001110, 12'hEEF, 5'd7, 5'd7};
        // 0x78: ST.H r7, r1, 12              mem[12] 低半字 = 0xBEEF → mem[12]=0x0000BEEF
        u_inst_ram.mem[30] = {10'b0010100101, 12'd12, 5'd1, 5'd7};
        // 0x7C: LD.W r22, r1, 12             r22 = 0x0000BEEF
        u_inst_ram.mem[31] = {10'b0010100010, 12'd12, 5'd1, 5'd22};

        // ===== 测试7: PCADDU12I =====
        // 0x80: PCADDU12I r23, 1              r23 = PC + (1<<12) = 0x1C000080 + 0x1000 = 0x1C001080
        u_inst_ram.mem[32] = {7'b0001110, 20'd1, 5'd23};
        // 0x84: PCADDU12I r24, 0              r24 = PC + 0 = 0x1C000084
        u_inst_ram.mem[33] = {7'b0001110, 20'd0, 5'd24};
    end

    // ========== 实时打印 ==========
    always @(posedge clk) begin
        if (resetn && inst_sram_en) begin
            if (debug_wb_rf_we != 4'b0)
                $display("[exec] PC=0x%08h  r%0d <- 0x%08h",
                         debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
            if (data_sram_en && data_sram_we != 4'b0)
                $display("[store] addr=0x%08h  we=%b  data=0x%08h",
                         data_sram_addr, data_sram_we, data_sram_wdata);
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

    task check_mem;
        input [31:0] addr;
        input [31:0] expected;
        input [8*40:1] name;
        reg   [31:0] actual;
    begin
        actual = u_data_ram.mem[addr[11:2]];
        if (actual === expected) begin
            $display("[PASS] %s : mem[%0d] = 0x%08h", name, addr, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s : mem[%0d] got=0x%08h exp=0x%08h",
                     name, addr, actual, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        resetn = 0;
        #50;
        resetn = 1;
        #1000;

        $display("");
        $display("====== LD.W/ST.W Regression ======");
        check_reg(5'd10, 32'h44332211,   "LD.W word");

        $display("");
        $display("====== LD.B Tests ======");
        check_reg(5'd11, 32'h00000011,   "LD.B byte0");
        check_reg(5'd12, 32'h00000022,   "LD.B byte1");
        check_reg(5'd13, 32'h00000033,   "LD.B byte2");
        check_reg(5'd14, 32'h00000044,   "LD.B byte3");
        check_reg(5'd15, 32'hFFFFFFFE,   "LD.B sign ext");
        check_reg(5'd16, 32'h000000FE,   "LD.BU zero ext");

        $display("");
        $display("====== LD.H Tests ======");
        check_reg(5'd17, 32'hFFFF80FE,   "LD.H sign ext low");
        check_reg(5'd18, 32'h000080FE,   "LD.HU zero ext low");
        check_reg(5'd19, 32'hFFFF80FF,   "LD.H sign ext high");
        check_reg(5'd20, 32'h000080FF,   "LD.HU zero ext high");

        $display("");
        $display("====== ST.B Tests ======");
        check_reg(5'd21, 32'h0000CDAB,   "ST.B two bytes");
        check_mem(32'd8,  32'h0000CDAB,   "mem after ST.B");

        $display("");
        $display("====== ST.H Tests ======");
        check_reg(5'd22, 32'h0000BEEF,   "ST.H half word");
        check_mem(32'd12, 32'h0000BEEF,   "mem after ST.H");

        $display("");
        $display("====== PCADDU12I Tests ======");
        check_reg(5'd23, 32'h1C001080,   "PCADDU12I +1");
        check_reg(5'd24, 32'h1C000084,   "PCADDU12I +0");

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