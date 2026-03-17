module inst_ram(
    input  wire        en,
    input  wire [31:0] addr,//指令地址
    output wire [31:0] rdata//输出指令
);

    reg [31:0] mem [0:1023];

    // 除以4得到数组下标，CPU 的 addr 通常是“字节地址”
    wire [9:0] index = addr[11:2];

    assign rdata = en ? mem[index] : 32'b0;

endmodule