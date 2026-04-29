module sync_ram_1p #(
    parameter integer DATA_WIDTH = 32,
    parameter integer DEPTH = 1,
    parameter INIT_FILE = ""
) (
    input wire clk,
    input wire we,
    input wire [$clog2(DEPTH)-1:0] addr,
    input wire signed [DATA_WIDTH-1:0] din,
    output reg signed [DATA_WIDTH-1:0] dout
);
    reg signed [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
        end
        dout <= mem[addr];
    end
endmodule
