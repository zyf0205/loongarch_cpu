`timescale 1ns / 1ps

module tb_mycpu;

    reg         clk;
    reg         resetn;

    wire        inst_sram_en;
    wire [ 3:0] inst_sram_we;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    reg  [31:0] inst_sram_rdata;

    wire        data_sram_en;
    wire [ 3:0] data_sram_we;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    reg  [31:0] data_sram_rdata;

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

    // 时钟
    initial clk = 0;
    always #5 clk = ~clk;

    // ========== 指令存储器 ==========
    reg [31:0] inst_mem [0:31];
    integer i;

    initial begin
        // 全部先填NOP
        for (i = 0; i < 32; i = i + 1)
            inst_mem[i] = 32'h03400000;

        // 指令0: LU12I.W r1, 0x12345          → r1 = 0x12345000
        inst_mem[0] = {7'b0001010, 20'h12345, 5'd1};

        // 指令1: ADDI.W r2, r1, 0x678          → r2 = 0x12345678
        inst_mem[1] = {10'b0000001010, 12'h678, 5'd1, 5'd2};

        // 指令2: ADD.W r3, r1, r2               → r3 = 0x2468A678
        inst_mem[2] = {17'b00000000000100000, 5'd2, 5'd1, 5'd3};

        // 指令3: ADDI.W r4, r0, 100             → r4 = 0x00000064
        inst_mem[3] = {10'b0000001010, 12'd100, 5'd0, 5'd4};

        // 指令4: ADD.W r5, r3, r4               → r5 = 0x2468A6DC
        inst_mem[4] = {17'b00000000000100000, 5'd4, 5'd3, 5'd5};

        // 指令5: ADDI.W r6, r0, -1              → r6 = 0xFFFFFFFF
        inst_mem[5] = {10'b0000001010, 12'hFFF, 5'd0, 5'd6};

        // 指令6: ADD.W r7, r5, r6               → r7 = 0x2468A6DB
        inst_mem[6] = {17'b00000000000100000, 5'd6, 5'd5, 5'd7};
    end

    // 指令读取
    always @(*) begin
        if (inst_sram_en)
            inst_sram_rdata = inst_mem[(inst_sram_addr - 32'h1C000000) >> 2];//括号里面计算指令数组下标
        else
            inst_sram_rdata = 32'b0;
    end

    // 数据存储器不用
    always @(*) data_sram_rdata = 32'b0;

    // ========== 实时打印每条指令执行情况 ==========
    always @(posedge clk) begin
        if (resetn && debug_wb_rf_we != 4'b0) begin
            $display("[exec] PC=0x%08h  r%0d <- 0x%08h",
                     debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
        end
    end

    // ========== 检查工具 ==========
    integer pass_count = 0;
    integer fail_count = 0;

    task check_reg;
        input [ 4:0] reg_num;
        input [31:0] expected;
        input [8*30:1] name;
        reg   [31:0] actual;
    begin
        actual = u_cpu.u_regfile.rf[reg_num];
        if (actual === expected) begin
            $display("[PASS] %s : r%0d = 0x%08h", name, reg_num, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s : r%0d got=0x%08h expected=0x%08h",
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
        #200;   // 等所有指令跑完

        $display("");
        $display("====== Register Check ======");
        check_reg(5'd1, 32'h12345000, "LU12I.W r1, 0x12345");
        check_reg(5'd2, 32'h12345678, "ADDI.W r2, r1, 0x678");
        check_reg(5'd3, 32'h2468A678, "ADD.W r3, r1, r2");
        check_reg(5'd4, 32'h00000064, "ADDI.W r4, r0, 100");
        check_reg(5'd5, 32'h2468A6DC, "ADD.W r5, r3, r4");
        check_reg(5'd6, 32'hFFFFFFFF, "ADDI.W r6, r0, -1");
        check_reg(5'd7, 32'h2468A6DB, "ADD.W r7, r5, r6");
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