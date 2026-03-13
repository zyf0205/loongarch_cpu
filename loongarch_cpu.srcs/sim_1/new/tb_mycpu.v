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
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            u_inst_ram.mem[i] = 32'h03400000;

        // ===== 准备数据 =====
        // 0: LU12I.W r1, 0x12345            → r1 = 0x12345000
        u_inst_ram.mem[0] = {7'b0001010, 20'h12345, 5'd1};
        // 1: ADDI.W r2, r1, 0x678           → r2 = 0x12345678
        u_inst_ram.mem[1] = {10'b0000001010, 12'h678, 5'd1, 5'd2};
        // 2: ADDI.W r3, r0, 5               → r3 = 5
        u_inst_ram.mem[2] = {10'b0000001010, 12'd5, 5'd0, 5'd3};
        // 3: ADDI.W r4, r0, 3               → r4 = 3
        u_inst_ram.mem[3] = {10'b0000001010, 12'd3, 5'd0, 5'd4};
        // 4: ADDI.W r5, r0, -8              → r5 = 0xFFFFFFF8
        u_inst_ram.mem[4] = {10'b0000001010, 12'hFF8, 5'd0, 5'd5};

        // ===== 三寄存器运算（旧测试）=====
        // 5: ADD.W r10, r3, r4              → r10 = 8
        u_inst_ram.mem[5] = {17'b00000000000100000, 5'd4, 5'd3, 5'd10};
        // 6: SUB.W r11, r3, r4              → r11 = 2
        u_inst_ram.mem[6] = {17'b00000000000100010, 5'd4, 5'd3, 5'd11};
        // 7: SLT r12, r4, r3               → r12 = 1 (3<5)
        u_inst_ram.mem[7] = {17'b00000000000100100, 5'd3, 5'd4, 5'd12};
        // 8: SLTU r13, r3, r4              → r13 = 0 (5<3u? no)
        u_inst_ram.mem[8] = {17'b00000000000100101, 5'd4, 5'd3, 5'd13};
        // 9: AND r14, r1, r2               → r14 = 0x12345000
        u_inst_ram.mem[9] = {17'b00000000000101001, 5'd2, 5'd1, 5'd14};
        // 10: OR r15, r1, r2               → r15 = 0x12345678
        u_inst_ram.mem[10] = {17'b00000000000101010, 5'd2, 5'd1, 5'd15};
        // 11: XOR r16, r1, r2              → r16 = 0x00000678
        u_inst_ram.mem[11] = {17'b00000000000101011, 5'd2, 5'd1, 5'd16};
        // 12: NOR r17, r1, r2              → r17 = 0xEDCBA987
        u_inst_ram.mem[12] = {17'b00000000000101000, 5'd2, 5'd1, 5'd17};
        // 13: SLL.W r18, r3, r4            → r18 = 5<<3 = 40 = 0x28
        u_inst_ram.mem[13] = {17'b00000000000101110, 5'd4, 5'd3, 5'd18};
        // 14: SRL.W r19, r1, r4            → r19 = 0x02468A00
        u_inst_ram.mem[14] = {17'b00000000000101111, 5'd4, 5'd1, 5'd19};
        // 15: SRA.W r20, r5, r4            → r20 = 0xFFFFFFFF
        u_inst_ram.mem[15] = {17'b00000000000110000, 5'd4, 5'd5, 5'd20};

        // ===== 新增：立即数运算 =====
        // 16: SLTI r21, r3, 10             → r21 = 1 (5 < 10 有符号)
        u_inst_ram.mem[16] = {10'b0000001000, 12'd10, 5'd3, 5'd21};
        // 17: SLTI r22, r3, -1             → r22 = 0 (5 < -1? 不是)
        u_inst_ram.mem[17] = {10'b0000001000, 12'hFFF, 5'd3, 5'd22};
        // 18: SLTUI r23, r3, 10            → r23 = 1 (5 < 10 无符号)
        u_inst_ram.mem[18] = {10'b0000001001, 12'd10, 5'd3, 5'd23};
        // 19: ANDI r24, r2, 0xFF           → r24 = 0x78
        u_inst_ram.mem[19] = {10'b0000001101, 12'hFF, 5'd2, 5'd24};
        // 20: ORI r25, r3, 0xF0            → r25 = 0xF5
        u_inst_ram.mem[20] = {10'b0000001110, 12'hF0, 5'd3, 5'd25};
        // 21: XORI r26, r3, 0xFF           → r26 = 0xFA
        u_inst_ram.mem[21] = {10'b0000001111, 12'hFF, 5'd3, 5'd26};
        // 22: SLLI.W r27, r3, 4            → r27 = 5<<4 = 80 = 0x50
        u_inst_ram.mem[22] = {17'b00000000010000001, 5'd4, 5'd3, 5'd27};
        // 23: SRLI.W r28, r1, 8            → r28 = 0x00123450
        u_inst_ram.mem[23] = {17'b00000000010001001, 5'd8, 5'd1, 5'd28};
        // 24: SRAI.W r29, r5, 4            → r29 = 0xFFFFFFFF
        u_inst_ram.mem[24] = {17'b00000000010010001, 5'd4, 5'd5, 5'd29};
    end

    // ========== 实时打印 ==========
    always @(posedge clk) begin
        if (resetn && inst_sram_en) begin
            if (debug_wb_rf_we != 4'b0)
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
        #600;

        $display("");
        $display("====== Old Instructions ======");
        check_reg(5'd1,  32'h12345000, "LU12I.W r1");
        check_reg(5'd2,  32'h12345678, "ADDI.W r2");
        check_reg(5'd3,  32'h00000005, "ADDI.W r3=5");
        check_reg(5'd4,  32'h00000003, "ADDI.W r4=3");
        check_reg(5'd5,  32'hFFFFFFF8, "ADDI.W r5=-8");
        check_reg(5'd10, 32'h00000008, "ADD.W r10=5+3");
        check_reg(5'd11, 32'h00000002, "SUB.W r11=5-3");
        check_reg(5'd12, 32'h00000001, "SLT r12=3<5");
        check_reg(5'd13, 32'h00000000, "SLTU r13=5<3u");
        check_reg(5'd14, 32'h12345000, "AND r14");
        check_reg(5'd15, 32'h12345678, "OR r15");
        check_reg(5'd16, 32'h00000678, "XOR r16");
        check_reg(5'd17, 32'hEDCBA987, "NOR r17");
        check_reg(5'd18, 32'h00000028, "SLL.W r18=5<<3");
        check_reg(5'd19, 32'h02468A00, "SRL.W r19");
        check_reg(5'd20, 32'hFFFFFFFF, "SRA.W r20");

        $display("");
        $display("====== New: Immediate Ops ======");
        check_reg(5'd21, 32'h00000001, "SLTI r21=5<10");
        check_reg(5'd22, 32'h00000000, "SLTI r22=5<-1? no");
        check_reg(5'd23, 32'h00000001, "SLTUI r23=5<10u");
        check_reg(5'd24, 32'h00000078, "ANDI r24=0x678&0xFF");
        check_reg(5'd25, 32'h000000F5, "ORI r25=5|0xF0");
        check_reg(5'd26, 32'h000000FA, "XORI r26=5^0xFF");
        check_reg(5'd27, 32'h00000050, "SLLI.W r27=5<<4");
        check_reg(5'd28, 32'h00123450, "SRLI.W r28>>8");
        check_reg(5'd29, 32'hFFFFFFFF, "SRAI.W r29>>>4");

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