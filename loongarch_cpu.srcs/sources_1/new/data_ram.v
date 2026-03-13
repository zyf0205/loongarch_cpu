module data_ram(
    input  wire        clk,
    input  wire        en,
    input  wire [ 3:0] we,       // 字节写使能，4位对应4个字节
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [31:0] mem [0:1023];   // 4KB

    wire [9:0] index = addr[11:2];   // 字对齐

    // 读：组合逻辑
    assign rdata = en ? mem[index] : 32'b0;

    // 写：时钟上升沿，按字节写
    always @(posedge clk) begin
        if (en) begin
            if (we[0]) mem[index][ 7: 0] <= wdata[ 7: 0];
            if (we[1]) mem[index][15: 8] <= wdata[15: 8];
            if (we[2]) mem[index][23:16] <= wdata[23:16];
            if (we[3]) mem[index][31:24] <= wdata[31:24];
        end
    end

endmodule