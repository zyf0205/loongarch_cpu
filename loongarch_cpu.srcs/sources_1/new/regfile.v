module regfile(
    input  wire        clk,

    // 读端口1
    input  wire [ 4:0] raddr1,   // 读地址1（5位，寻址0~31号寄存器）
    output wire [31:0] rdata1,   // 读数据1

    // 读端口2
    input  wire [ 4:0] raddr2,
    output wire [31:0] rdata2,

    // 写端口
    input  wire        we,       // 写使能
    input  wire [ 4:0] waddr,    // 写地址
    input  wire [31:0] wdata     // 写数据
);

    // 32个32位寄存器
    reg [31:0] rf [31:0];

    // 写：时钟上升沿写入，但0号寄存器不能写
    always @(posedge clk) begin
        if (we && waddr != 5'b0) begin
            rf[waddr] <= wdata;
        end
    end

    // 读：组合逻辑，给地址立刻出数据
    // 0号寄存器永远读出0
    // 如果读写同一地址，直接把写数据转发出来（写优先）
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 :
                    (raddr1 == waddr && we) ? wdata :
                    rf[raddr1];

    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 :
                    (raddr2 == waddr && we) ? wdata :
                    rf[raddr2];

endmodule