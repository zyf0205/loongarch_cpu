module pc_reg(
    input  wire        clk,
    input  wire        reset,       // 高有效复位
    input  wire        br_taken,    // 是否跳转（1=跳转，0=顺序）
    input  wire [31:0] br_target,   // 跳转目标地址
    output reg  [31:0] pc,          // 当前PC值
    output wire [31:0] next_pc      // 下一条指令的PC（给指令存储器用）
);

    // 组合逻辑，阻塞赋值，计算下一个PC
    assign next_pc = br_taken ? br_target : pc + 32'd4; //组合逻辑用阻塞赋值

    // PC寄存器：时钟上升沿更新
    always @(posedge clk) begin
        if (reset)
            pc <= 32'h1C000000;   // LoongArch复位地址
        else
            pc <= next_pc;  //非阻塞赋值
    end

endmodule