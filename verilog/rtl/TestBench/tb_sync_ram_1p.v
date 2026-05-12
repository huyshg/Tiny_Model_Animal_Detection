`timescale 1ns / 1ps

module tb_sync_ram_1p;
    localparam integer DATA_WIDTH = 16;
    localparam integer DEPTH = 8;
    localparam integer ADDR_WIDTH = $clog2(DEPTH);

    reg clk;
    reg we;
    reg [ADDR_WIDTH-1:0] addr;
    reg signed [DATA_WIDTH-1:0] din;
    wire signed [DATA_WIDTH-1:0] dout;

    reg signed [DATA_WIDTH-1:0] expected_mem [0:DEPTH-1];
    integer i;

    sync_ram_1p #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .RAM_STYLE("block"),
        .INIT_FILE("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/sync_ram_init.mem")
    ) dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/sync_ram_expected.mem", expected_mem);

        we = 1'b0;
        addr = 0;
        din = 0;

        repeat (2) @(posedge clk);

        for (i = 0; i < DEPTH; i = i + 1) begin
            addr = i[ADDR_WIDTH-1:0];
            repeat (3) @(posedge clk);
            if (dout !== expected_mem[i]) begin
                $fatal;
            end
        end

        @(posedge clk);
        we = 1'b1;
        addr = 3;
        din = 16'h00a5;
        @(posedge clk);
        we = 1'b0;
        expected_mem[3] = 16'h00a5;
        addr = 3;
        repeat (3) @(posedge clk);
        if (dout !== expected_mem[3]) begin
            $fatal;
        end

        $finish;
    end
endmodule
