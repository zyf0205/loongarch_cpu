module regfile(
        input  wire        clk,

        input  wire [ 4:0] raddr1,
        output wire [31:0] rdata1,

        input  wire [ 4:0] raddr2,
        output wire [31:0] rdata2,

        input  wire        we,
        input  wire [ 4:0] waddr,
        input  wire [31:0] wdata
    );

    reg [31:0] rf [31:0];

    /*时序逻辑*/
    always @(posedge clk)
    begin
        if (we && waddr != 5'b0)/*写使能且写的不是R0*/
        begin
            rf[waddr] <= wdata;/*非阻塞赋值*/
        end
    end

    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : rf[raddr1];
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : rf[raddr2];

endmodule
