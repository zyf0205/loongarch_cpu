module inst_ram(
    input  wire        en,
    input  wire [31:0] addr,
    output wire [31:0] rdata
);

    reg [31:0] mem [0:1023];

    // 只取低12位做索引，忽略高位基地址
    wire [9:0] index = addr[11:2];

    assign rdata = en ? mem[index] : 32'b0;

endmodule