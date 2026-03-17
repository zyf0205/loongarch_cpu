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

    // =========================================================
    // 宏：指令编码模板
    // =========================================================
    `define R(op, rk, rj, rd)      {op, rk, rj, rd}
    `define I12(op, imm, rj, rd)   {op, imm, rj, rd}
    `define I20(op, imm, rd)       {op, imm, rd}
    `define BR16(op, off, rj, rd)  {op, off, rj, rd}
    `define BR26(op, off_lo16, off_hi10) {op, off_lo16, off_hi10}

    // =========================================================
    // 宏：opcode
    // =========================================================
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

    // =========================================================
    // DUT
    // =========================================================
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

    // =========================================================
    // Clock
    // =========================================================
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // =========================================================
    // 初始化程序
    // =========================================================
    integer i;
    integer n;
    initial begin
        // 指令RAM填NOP
        for (i = 0; i < 1024; i = i + 1)
            u_inst_ram.mem[i] = 32'h03400000;

        // 数据RAM清零
        for (i = 0; i < 1024; i = i + 1)
            u_data_ram.mem[i] = 32'b0;

        n = 0;
        `include "prog_35.vh"
    end

    // =========================================================
    // 实时打印
    // =========================================================
    always @(posedge clk) begin
        if (resetn) begin
            if (debug_wb_rf_we != 4'b0) begin
                $display("[exec] PC=0x%08h  r%0d <- 0x%08h",
                         debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
            end

            if (data_sram_en && data_sram_we != 4'b0000) begin
                $display("[store] addr=0x%08h we=%b data=0x%08h",
                         data_sram_addr, data_sram_we, data_sram_wdata);
            end
        end
    end

    // =========================================================
    // 检查工具
    // =========================================================
    integer pass_count = 0;
    integer fail_count = 0;

    task check_reg;
        input [4:0] reg_num;
        input [31:0] expected;
        input [8*40:1] name;
        reg   [31:0] actual;
    begin
        actual = u_cpu.u_regfile.rf[reg_num];
        if (actual === expected) begin
            $display("[PASS] %s : r%0d = 0x%08h", name, reg_num, actual);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] %s : r%0d got=0x%08h exp=0x%08h",
                     name, reg_num, actual, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    task check_mem;
        input [31:0] byte_addr;
        input [31:0] expected;
        input [8*40:1] name;
        reg   [31:0] actual;
    begin
        actual = u_data_ram.mem[byte_addr[11:2]];
        if (actual === expected) begin
            $display("[PASS] %s : mem[%0d] = 0x%08h", name, byte_addr, actual);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] %s : mem[%0d] got=0x%08h exp=0x%08h",
                     name, byte_addr, actual, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // =========================================================
    // 仿真流程
    // =========================================================
    initial begin
        resetn = 1'b0;
        #50;
        resetn = 1'b1;

        #3000;

        $display("");
        $display("========== FINAL CHECK ==========");

        // 访存结果
        check_mem(32'd0,  32'h12345678, "mem[0] ST.W");
        check_mem(32'd4,  32'h80FF80FE, "mem[4] sign data");
        check_mem(32'd8,  32'h0000CDAB, "mem[8] ST.B");
        check_mem(32'd12, 32'h0000BEEF, "mem[12] ST.H");
        check_mem(32'd16, 32'd15,       "mem[16] loop result");

        // 跳转结果
        check_reg(5'd19, 32'd11,        "BEQ taken result");
        check_reg(5'd20, 32'd22,        "BNE taken result");
        check_reg(5'd21, 32'd33,        "BEQ not taken result");
        check_reg(5'd22, 32'd44,        "B result");
        check_reg(5'd23, 32'd55,        "BL target result");
        check_reg(5'd25, 32'd66,        "JIRL target result");

        // 循环结果
        check_reg(5'd26, 32'd15,        "loop sum");
        check_reg(5'd27, 32'd5,         "loop counter");
        check_reg(5'd29, 32'd15,        "loop loadback");

        check_reg(5'd24, 32'h1C000118, "JIRL link result");

        $display("=================================");
        $display("PASS: %0d   FAIL: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL PASSED!");
        else
            $display("SOME TESTS FAILED!");
        $display("=================================");
        $finish;
    end

endmodule