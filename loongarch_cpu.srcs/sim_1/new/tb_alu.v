`timescale 1ns / 1ps
`include "../../sources_1/new/loongarch_defs.vh"

module tb_alu;

    reg  [11:0] alu_op;
    reg  [31:0] alu_src1;
    reg  [31:0] alu_src2;
    wire [31:0] alu_result;

    integer pass_count = 0;
    integer fail_count = 0;

    alu u_alu(
        .alu_op    (alu_op),
        .alu_src1  (alu_src1),
        .alu_src2  (alu_src2),
        .alu_result(alu_result)
    );

    task check;
        input [31:0] expected;
        input [8*24:1] test_name;
    begin
        if (alu_result === expected) begin
            $display("[PASS] %s : result=0x%08h", test_name, alu_result);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] %s : got=0x%08h expected=0x%08h", test_name, alu_result, expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin
        alu_op = `ALU_ADD; alu_src1 = 32'd100;        alu_src2 = 32'd200;        #10; check(32'd300,       "ADD 100+200");
        alu_op = `ALU_ADD; alu_src1 = 32'hFFFFFFFF;   alu_src2 = 32'd1;          #10; check(32'd0,         "ADD wrap");
        alu_op = `ALU_ADD; alu_src1 = 32'h7FFFFFFF;   alu_src2 = 32'd1;          #10; check(32'h80000000, "ADD max+1");

        alu_op = `ALU_SUB; alu_src1 = 32'd200;        alu_src2 = 32'd100;        #10; check(32'd100,       "SUB 200-100");
        alu_op = `ALU_SUB; alu_src1 = 32'd0;          alu_src2 = 32'd1;          #10; check(32'hFFFFFFFF, "SUB 0-1");
        alu_op = `ALU_SUB; alu_src1 = 32'h80000000;   alu_src2 = 32'd1;          #10; check(32'h7FFFFFFF, "SUB min-1");

        alu_op = `ALU_SLT; alu_src1 = -32'sd5;        alu_src2 = 32'd3;          #10; check(32'd1,         "SLT -5<3");
        alu_op = `ALU_SLT; alu_src1 = 32'd10;         alu_src2 = 32'd3;          #10; check(32'd0,         "SLT 10>3");
        alu_op = `ALU_SLT; alu_src1 = 32'h80000000;   alu_src2 = 32'h7FFFFFFF;   #10; check(32'd1,         "SLT min<max");

        alu_op = `ALU_SLTU; alu_src1 = 32'd1;         alu_src2 = 32'd2;          #10; check(32'd1,         "SLTU 1<2");
        alu_op = `ALU_SLTU; alu_src1 = 32'hFFFFFFFF;  alu_src2 = 32'd1;          #10; check(32'd0,         "SLTU big>1");
        alu_op = `ALU_SLTU; alu_src1 = 32'h7FFFFFFF;  alu_src2 = 32'h80000000;   #10; check(32'd1,         "SLTU low<high");

        alu_op = `ALU_AND; alu_src1 = 32'hFF00FF00;   alu_src2 = 32'h0F0F0F0F;   #10; check(32'h0F000F00, "AND");
        alu_op = `ALU_OR;  alu_src1 = 32'hFF00FF00;   alu_src2 = 32'h0F0F0F0F;   #10; check(32'hFF0FFF0F, "OR");
        alu_op = `ALU_XOR; alu_src1 = 32'hFF00FF00;   alu_src2 = 32'h0F0F0F0F;   #10; check(32'hF00FF00F, "XOR");
        alu_op = `ALU_NOR; alu_src1 = 32'hFF00FF00;   alu_src2 = 32'h0F0F0F0F;   #10; check(32'h00F000F0, "NOR");

        alu_op = `ALU_SLL; alu_src1 = 32'd1;          alu_src2 = 32'd4;          #10; check(32'd16,       "SLL 1<<4");
        alu_op = `ALU_SLL; alu_src1 = 32'd1;          alu_src2 = 32'd31;         #10; check(32'h80000000, "SLL 1<<31");
        alu_op = `ALU_SRL; alu_src1 = 32'h80000000;   alu_src2 = 32'd4;          #10; check(32'h08000000, "SRL logic");
        alu_op = `ALU_SRL; alu_src1 = 32'hFFFFFFFF;   alu_src2 = 32'd31;         #10; check(32'd1,        "SRL 31");
        alu_op = `ALU_SRA; alu_src1 = 32'h80000000;   alu_src2 = 32'd4;          #10; check(32'hF8000000, "SRA arith");
        alu_op = `ALU_SRA; alu_src1 = 32'h80000001;   alu_src2 = 32'd31;         #10; check(32'hFFFFFFFF, "SRA 31");

        alu_op = `ALU_LUI; alu_src1 = 32'd999;        alu_src2 = 32'h12345000;   #10; check(32'h12345000, "LUI passthru");

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
