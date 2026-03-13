`timescale 1ns / 1ps

module tb_pc_reg;

    reg         clk;
    reg         reset;
    reg         br_taken;
    reg  [31:0] br_target;
    wire [31:0] pc;
    wire [31:0] next_pc;

    pc_reg u_pc(
        .clk      (clk),
        .reset    (reset),
        .br_taken (br_taken),
        .br_target(br_target),
        .pc       (pc),
        .next_pc  (next_pc)
    );

    // 时钟
    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*30:1] name;
    begin
        if (actual === expected) begin
            $display("[PASS] %s : pc=0x%08h", name, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] %s : got=0x%08h, expected=0x%08h", name, actual, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        // 初始状态
        reset     = 1;
        br_taken  = 0;
        br_target = 32'b0;

        // ====== 测试1：复位值 ======
        @(posedge clk); #1;
        check(pc, 32'h1C000000, "reset value");

        // ====== 测试2：释放复位，顺序+4 ======
        reset = 0;

        @(posedge clk); #1;
        check(pc, 32'h1C000004, "pc+4 first");

        @(posedge clk); #1;
        check(pc, 32'h1C000008, "pc+4 second");

        @(posedge clk); #1;
        check(pc, 32'h1C00000C, "pc+4 third");

        // ====== 测试3：跳转 ======
        br_taken  = 1;
        br_target = 32'h1C001000;
        @(posedge clk); #1;
        check(pc, 32'h1C001000, "branch taken");

        // 跳转后恢复顺序执行
        br_taken = 0;
        @(posedge clk); #1;
        check(pc, 32'h1C001004, "after branch +4");

        @(posedge clk); #1;
        check(pc, 32'h1C001008, "after branch +8");

        // ====== 测试4：连续跳转 ======
        br_taken  = 1;
        br_target = 32'h1C000000;   // 跳回起始地址
        @(posedge clk); #1;
        check(pc, 32'h1C000000, "jump back to start");

        br_target = 32'h1CFFF000;   // 跳到另一个地址
        @(posedge clk); #1;
        check(pc, 32'h1CFFF000, "jump again");

        // ====== 测试5：跳转中途复位 ======
        reset = 1;
        @(posedge clk); #1;
        check(pc, 32'h1C000000, "reset during branch");

        reset = 0;
        br_taken = 0;
        @(posedge clk); #1;
        check(pc, 32'h1C000004, "normal after reset");

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