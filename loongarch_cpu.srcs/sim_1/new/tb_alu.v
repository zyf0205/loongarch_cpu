`timescale 1ns / 1ps

module tb_alu;

    reg  [11:0] alu_op;
    reg  [31:0] alu_src1;
    reg  [31:0] alu_src2;
    wire [31:0] alu_result;

    alu u_alu(
        .alu_op    (alu_op),
        .alu_src1  (alu_src1),
        .alu_src2  (alu_src2),
        .alu_result(alu_result)
    );

    // 给alu_op起个好记的名字
    localparam ADD  = 12'b000000000001;
    localparam SUB  = 12'b000000000010;
    localparam SLT  = 12'b000000000100;
    localparam SLTU = 12'b000000001000;
    localparam AND_ = 12'b000000010000;
    localparam NOR_ = 12'b000000100000;
    localparam OR_  = 12'b000001000000;
    localparam XOR_ = 12'b000010000000;
    localparam SLL_ = 12'b000100000000;
    localparam SRL_ = 12'b001000000000;
    localparam SRA_ = 12'b010000000000;
    localparam LUI  = 12'b100000000000;

    integer pass_count = 0;
    integer fail_count = 0;

    // 检查任务：自动比对结果
    task check;
        input [31:0] expected;
        input [8*20:1] test_name;  // 测试名称字符串
    begin
        if (alu_result === expected) begin
            $display("[PASS] %s : result=0x%08h", test_name, alu_result);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s : got=0x%08h, expected=0x%08h", test_name, alu_result, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        // ====== 加法测试 ======
        alu_op = ADD; alu_src1 = 32'd100;  alu_src2 = 32'd200; #10;
        check(32'd300, "ADD 100+200");

        alu_op = ADD; alu_src1 = 32'hFFFFFFFF; alu_src2 = 32'd1; #10;
        check(32'd0, "ADD overflow");

        // ====== 减法测试 ======
        alu_op = SUB; alu_src1 = 32'd200;  alu_src2 = 32'd100; #10;
        check(32'd100, "SUB 200-100");

        alu_op = SUB; alu_src1 = 32'd0;    alu_src2 = 32'd1;   #10;
        check(32'hFFFFFFFF, "SUB 0-1");

        // ====== 有符号比较 ======
        alu_op = SLT; alu_src1 = -32'sd5;  alu_src2 = 32'd3;   #10;
        check(32'd1, "SLT -5<3");

        alu_op = SLT; alu_src1 = 32'd10;   alu_src2 = 32'd3;   #10;
        check(32'd0, "SLT 10>3");

        // ====== 无符号比较 ======
        alu_op = SLTU; alu_src1 = 32'd1;   alu_src2 = 32'd2;   #10;
        check(32'd1, "SLTU 1<2");

        alu_op = SLTU; alu_src1 = 32'hFFFFFFFF; alu_src2 = 32'd1; #10;
        check(32'd0, "SLTU big>1");

        // ====== 逻辑运算 ======
        alu_op = AND_; alu_src1 = 32'hFF00FF00; alu_src2 = 32'h0F0F0F0F; #10;
        check(32'h0F000F00, "AND");

        alu_op = OR_;  alu_src1 = 32'hFF00FF00; alu_src2 = 32'h0F0F0F0F; #10;
        check(32'hFF0FFF0F, "OR");

        alu_op = XOR_; alu_src1 = 32'hFF00FF00; alu_src2 = 32'h0F0F0F0F; #10;
        check(32'hF00FF00F, "XOR");

        alu_op = NOR_; alu_src1 = 32'hFF00FF00; alu_src2 = 32'h0F0F0F0F; #10;
        check(32'h00F000F0, "NOR");

        // ====== 移位 ======
        alu_op = SLL_; alu_src1 = 32'd1;        alu_src2 = 32'd4;  #10;
        check(32'd16, "SLL 1<<4");

        alu_op = SRL_; alu_src1 = 32'h80000000; alu_src2 = 32'd4;  #10;
        check(32'h08000000, "SRL logic");

        alu_op = SRA_; alu_src1 = 32'h80000000; alu_src2 = 32'd4;  #10;
        check(32'hF8000000, "SRA arith");

        // ====== LUI ======
        alu_op = LUI; alu_src1 = 32'd999; alu_src2 = 32'h12345000; #10;
        check(32'h12345000, "LUI passthru");

        // ====== 汇总 ======
        #10;
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