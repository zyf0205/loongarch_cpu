`timescale 1ns / 1ps

module tb_regfile;

    reg         clk;
    reg  [ 4:0] raddr1, raddr2;
    wire [31:0] rdata1, rdata2;
    reg         we;
    reg  [ 4:0] waddr;
    reg  [31:0] wdata;

    integer pass_count = 0;
    integer fail_count = 0;

    regfile u_regfile(
        .clk   (clk),
        .raddr1(raddr1), .rdata1(rdata1),
        .raddr2(raddr2), .rdata2(rdata2),
        .we    (we),     .waddr (waddr),  .wdata(wdata)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*30:1] name;
    begin
        if (actual === expected) begin
            $display("[PASS] %s : got=0x%08h", name, actual);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] %s : got=0x%08h expected=0x%08h", name, actual, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        we = 0;
        waddr = 0;
        wdata = 0;
        raddr1 = 0;
        raddr2 = 0;

        #10;
        check(rdata1, 32'b0, "r0 read = 0");

        @(posedge clk);
        we = 1; waddr = 5'd0; wdata = 32'hDEADBEEF;
        @(posedge clk);
        we = 0; raddr1 = 5'd0;
        #1;
        check(rdata1, 32'b0, "write r0 ignored");

        @(posedge clk);
        we = 1; waddr = 5'd1; wdata = 32'hAAAA_0001;
        @(posedge clk);
        we = 0; raddr1 = 5'd1;
        #1;
        check(rdata1, 32'hAAAA0001, "write then read r1");

        @(posedge clk);
        we = 1; waddr = 5'd2; wdata = 32'hBBBB_0002;
        @(posedge clk);
        we = 0; raddr1 = 5'd1; raddr2 = 5'd2;
        #1;
        check(rdata1, 32'hAAAA0001, "r1 still correct");
        check(rdata2, 32'hBBBB0002, "r2 correct");

        @(posedge clk);
        we = 1; waddr = 5'd10; wdata = 32'h0000_000A;
        @(posedge clk);
        waddr = 5'd20; wdata = 32'h0000_0014;
        @(posedge clk);
        waddr = 5'd31; wdata = 32'h0000_001F;
        @(posedge clk);
        we = 0;

        raddr1 = 5'd10; raddr2 = 5'd20; #1;
        check(rdata1, 32'h0000000A, "r10");
        check(rdata2, 32'h00000014, "r20");
        raddr1 = 5'd31; #1;
        check(rdata1, 32'h0000001F, "r31");

        @(posedge clk);
        we = 1; waddr = 5'd1; wdata = 32'h1E11_1111;
        @(posedge clk);
        we = 0; raddr1 = 5'd1; #1;
        check(rdata1, 32'h1E11_1111, "r1 overwritten");

        @(posedge clk);
        we = 1; waddr = 5'd5; wdata = 32'h1234_5678;
        raddr1 = 5'd5;
        @(posedge clk);
        we = 0;
        #1;
        check(rdata1, 32'h12345678, "read after writeback");

        @(posedge clk);
        we = 1; waddr = 5'd0; wdata = 32'hFFFF_FFFF;
        @(posedge clk);
        we = 0; raddr1 = 5'd0; raddr2 = 5'd5;
        #1;
        check(rdata1, 32'b0, "r0 still zero");
        check(rdata2, 32'h12345678, "r5 preserved");

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
