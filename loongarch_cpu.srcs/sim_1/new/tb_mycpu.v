`timescale 1ns / 1ps
`include "../../sources_1/new/loongarch_defs.vh"

module tb_mycpu;

    localparam [31:0] STAGE_R3_START     = 32'h1C00001C;
    localparam [31:0] STAGE_IMM_START    = 32'h1C00004C;
    localparam [31:0] STAGE_PCADD_START  = 32'h1C00006C;
    localparam [31:0] STAGE_MEM_START    = 32'h1C000070;
    localparam [31:0] STAGE_BRANCH_START = 32'h1C0000C8;
    localparam [31:0] STAGE_LOOP_START   = 32'h1C000120;
    localparam [31:0] STAGE_NOP_START    = 32'h1C000140;
    localparam integer INSTR_COUNT       = 35;
    localparam integer NOP_INDEX         = 35;

    integer instr_hits [0:NOP_INDEX];
    integer fake_write_to_r0_count;
    integer nop_exec_count;
    integer pass_count;
    integer fail_count;
    integer i;
    integer n;
    integer decode_idx;

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

    initial clk = 1'b0;
    always #5 clk = ~clk;

    function integer decode_instruction_index;
        input [31:0] inst;
    begin
        if (inst == 32'h03400000)                       decode_instruction_index = NOP_INDEX;
        else if (inst[31:15] == `ADD_W)                 decode_instruction_index = 0;
        else if (inst[31:15] == `SUB_W)                 decode_instruction_index = 1;
        else if (inst[31:15] == `SLT_)                  decode_instruction_index = 2;
        else if (inst[31:15] == `SLTU_)                 decode_instruction_index = 3;
        else if (inst[31:15] == `NOR_)                  decode_instruction_index = 4;
        else if (inst[31:15] == `AND_)                  decode_instruction_index = 5;
        else if (inst[31:15] == `OR_)                   decode_instruction_index = 6;
        else if (inst[31:15] == `XOR_)                  decode_instruction_index = 7;
        else if (inst[31:15] == `SLL_W)                 decode_instruction_index = 8;
        else if (inst[31:15] == `SRL_W)                 decode_instruction_index = 9;
        else if (inst[31:15] == `SRA_W)                 decode_instruction_index = 10;
        else if (inst[31:15] == `SLLI_W)                decode_instruction_index = 11;
        else if (inst[31:15] == `SRLI_W)                decode_instruction_index = 12;
        else if (inst[31:15] == `SRAI_W)                decode_instruction_index = 13;
        else if (inst[31:22] == `ADDI_W)                decode_instruction_index = 14;
        else if (inst[31:22] == `SLTI_)                 decode_instruction_index = 15;
        else if (inst[31:22] == `SLTUI_)                decode_instruction_index = 16;
        else if (inst[31:22] == `ANDI_)                 decode_instruction_index = 17;
        else if (inst[31:22] == `ORI_)                  decode_instruction_index = 18;
        else if (inst[31:22] == `XORI_)                 decode_instruction_index = 19;
        else if (inst[31:25] == `LU12I)                 decode_instruction_index = 20;
        else if (inst[31:25] == `PCADD)                 decode_instruction_index = 21;
        else if (inst[31:26] == `BEQ_)                  decode_instruction_index = 22;
        else if (inst[31:26] == `BNE_)                  decode_instruction_index = 23;
        else if (inst[31:26] == `B_)                    decode_instruction_index = 24;
        else if (inst[31:26] == `BL_)                   decode_instruction_index = 25;
        else if (inst[31:26] == `JIRL_)                 decode_instruction_index = 26;
        else if (inst[31:22] == `LD_W)                  decode_instruction_index = 27;
        else if (inst[31:22] == `LD_B)                  decode_instruction_index = 28;
        else if (inst[31:22] == `LD_BU)                 decode_instruction_index = 29;
        else if (inst[31:22] == `LD_H)                  decode_instruction_index = 30;
        else if (inst[31:22] == `LD_HU)                 decode_instruction_index = 31;
        else if (inst[31:22] == `ST_W)                  decode_instruction_index = 32;
        else if (inst[31:22] == `ST_B)                  decode_instruction_index = 33;
        else if (inst[31:22] == `ST_H)                  decode_instruction_index = 34;
        else                                             decode_instruction_index = -1;
    end
    endfunction

    task check_reg;
        input [4:0] reg_num;
        input [31:0] expected;
        input [8*40:1] name;
        reg [31:0] actual;
    begin
        actual = (reg_num == 5'd0) ? 32'b0 : u_cpu.u_regfile.rf[reg_num];
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
        reg [31:0] actual;
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

    task check_cov;
        input integer idx;
        input [8*24:1] name;
    begin
        if (instr_hits[idx] > 0) begin
            $display("[PASS] coverage %s : hits=%0d", name, instr_hits[idx]);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] coverage %s : instruction not executed", name);
            fail_count = fail_count + 1;
        end
    end
    endtask

    task check_no_fake_r0_write;
    begin
        if (fake_write_to_r0_count == 0) begin
            $display("[PASS] no fake r0 debug writes");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] fake r0 debug writes : count=%0d", fake_write_to_r0_count);
            fail_count = fail_count + 1;
        end
    end
    endtask

    task wait_for_pc;
        input [31:0] target_pc;
    begin
        wait (debug_wb_pc == target_pc);
        #1;
    end
    endtask

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            u_inst_ram.mem[i] = 32'h03400000;
            u_data_ram.mem[i] = 32'b0;
        end

        for (i = 0; i <= NOP_INDEX; i = i + 1)
            instr_hits[i] = 0;

        fake_write_to_r0_count = 0;
        nop_exec_count = 0;
        pass_count = 0;
        fail_count = 0;

        n = 0;
        `include "../../sources_1/new/prog_35.vh"
    end

    always @(posedge clk) begin
        if (resetn) begin
            decode_idx = decode_instruction_index(inst_sram_rdata);
            if (decode_idx >= 0) begin
                instr_hits[decode_idx] = instr_hits[decode_idx] + 1;
                if (decode_idx == NOP_INDEX)
                    nop_exec_count = nop_exec_count + 1;
            end

            if (debug_wb_rf_we != 4'b0) begin
                $display("[exec] PC=0x%08h  r%0d <- 0x%08h",
                         debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
                if (debug_wb_rf_wnum == 5'd0)
                    fake_write_to_r0_count = fake_write_to_r0_count + 1;
            end

            if (data_sram_en && data_sram_we != 4'b0000) begin
                $display("[store] addr=0x%08h we=%b data=0x%08h",
                         data_sram_addr, data_sram_we, data_sram_wdata);
            end
        end
    end

    initial begin
        resetn = 1'b0;
        #50;
        resetn = 1'b1;

        wait_for_pc(STAGE_R3_START);
        $display("");
        $display("========== STAGE: SETUP ==========");
        check_reg(5'd1,  32'd7,         "setup r1");
        check_reg(5'd2,  32'd3,         "setup r2");
        check_reg(5'd3,  32'hFFFFFFFB,  "setup r3");
        check_reg(5'd4,  32'h12345678,  "setup r4");
        check_reg(5'd5,  32'd0,         "setup r5");
        check_reg(5'd6,  32'hFFFFFFFF,  "setup r6");

        wait_for_pc(STAGE_IMM_START);
        $display("");
        $display("======= STAGE: R-TYPE OPS =======");
        check_reg(5'd10, 32'd10,        "ADD.W");
        check_reg(5'd11, 32'd4,         "SUB.W");
        check_reg(5'd12, 32'd1,         "SLT");
        check_reg(5'd13, 32'd0,         "SLT false");
        check_reg(5'd14, 32'd1,         "SLTU");
        check_reg(5'd15, 32'h12345678,  "AND");
        check_reg(5'd16, 32'd7,         "OR");
        check_reg(5'd17, 32'd4,         "XOR");
        check_reg(5'd18, 32'hFFFFFFF8,  "NOR");
        check_reg(5'd19, 32'h00000038,  "SLL.W");
        check_reg(5'd20, 32'h01FFFFFF,  "SRL.W");
        check_reg(5'd21, 32'hFFFFFFFF,  "SRA.W");

        wait_for_pc(STAGE_PCADD_START);
        $display("");
        $display("===== STAGE: IMMEDIATE OPS =====");
        check_reg(5'd22, 32'd1,         "SLTI");
        check_reg(5'd23, 32'd0,         "SLTUI");
        check_reg(5'd24, 32'h00000078,  "ANDI");
        check_reg(5'd25, 32'h000000F7,  "ORI");
        check_reg(5'd26, 32'h000000F8,  "XORI");
        check_reg(5'd27, 32'h00000070,  "SLLI.W");
        check_reg(5'd28, 32'h000000FF,  "SRLI.W");
        check_reg(5'd29, 32'hFFFFFFFE,  "SRAI.W");

        wait_for_pc(STAGE_MEM_START);
        $display("");
        $display("======= STAGE: PC RELATIVE =======");
        check_reg(5'd30, 32'h1C00106C,  "PCADDU12I");

        wait_for_pc(STAGE_BRANCH_START);
        $display("");
        $display("========== STAGE: MEMORY ==========");
        check_mem(32'd0,  32'h12345678, "mem[0] ST.W");
        check_mem(32'd4,  32'h80FF80FE, "mem[4] sign data");
        check_mem(32'd8,  32'h0000CDAB, "mem[8] ST.B");
        check_mem(32'd12, 32'h0000BEEF, "mem[12] ST.H");
        check_reg(5'd10, 32'h12345678,  "LD.W");
        check_reg(5'd11, 32'hFFFFFFFE,  "LD.B");
        check_reg(5'd12, 32'h000000FE,  "LD.BU");
        check_reg(5'd13, 32'hFFFF80FE,  "LD.H");
        check_reg(5'd14, 32'h000080FE,  "LD.HU");
        check_reg(5'd15, 32'hFFFF80FF,  "LD.H upper");
        check_reg(5'd16, 32'h000080FF,  "LD.HU upper");
        check_reg(5'd17, 32'h0000CDAB,  "LD.W byte mix");
        check_reg(5'd18, 32'h0000BEEF,  "LD.W half mix");

        wait_for_pc(STAGE_LOOP_START);
        $display("");
        $display("========= STAGE: BRANCH =========");
        check_reg(5'd19, 32'd11,        "BEQ taken");
        check_reg(5'd20, 32'd22,        "BNE taken");
        check_reg(5'd21, 32'd33,        "BEQ not taken");
        check_reg(5'd22, 32'd44,        "B");
        check_reg(5'd23, 32'd55,        "BL target");
        check_reg(5'd24, 32'h1C000118,  "JIRL link");
        check_reg(5'd25, 32'd66,        "JIRL target");

        wait_for_pc(STAGE_NOP_START);
        $display("");
        $display("========== STAGE: LOOP ==========");
        check_mem(32'd16, 32'd15,       "mem[16] loop");
        check_reg(5'd26, 32'd15,        "loop sum");
        check_reg(5'd27, 32'd5,         "loop count");
        check_reg(5'd29, 32'd15,        "loop loadback");
        check_reg(5'd0,  32'd0,         "r0 preserved");

        #200;

        $display("");
        $display("======= COVERAGE SUMMARY =======");
        check_cov(0,  "ADD.W");
        check_cov(1,  "SUB.W");
        check_cov(2,  "SLT");
        check_cov(3,  "SLTU");
        check_cov(4,  "NOR");
        check_cov(5,  "AND");
        check_cov(6,  "OR");
        check_cov(7,  "XOR");
        check_cov(8,  "SLL.W");
        check_cov(9,  "SRL.W");
        check_cov(10, "SRA.W");
        check_cov(11, "SLLI.W");
        check_cov(12, "SRLI.W");
        check_cov(13, "SRAI.W");
        check_cov(14, "ADDI.W");
        check_cov(15, "SLTI");
        check_cov(16, "SLTUI");
        check_cov(17, "ANDI");
        check_cov(18, "ORI");
        check_cov(19, "XORI");
        check_cov(20, "LU12I.W");
        check_cov(21, "PCADDU12I");
        check_cov(22, "BEQ");
        check_cov(23, "BNE");
        check_cov(24, "B");
        check_cov(25, "BL");
        check_cov(26, "JIRL");
        check_cov(27, "LD.W");
        check_cov(28, "LD.B");
        check_cov(29, "LD.BU");
        check_cov(30, "LD.H");
        check_cov(31, "LD.HU");
        check_cov(32, "ST.W");
        check_cov(33, "ST.B");
        check_cov(34, "ST.H");
        check_no_fake_r0_write();

        if (nop_exec_count > 0) begin
            $display("[PASS] NOP stream observed : hits=%0d", nop_exec_count);
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] NOP stream not observed");
            fail_count = fail_count + 1;
        end

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
