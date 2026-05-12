module tb_argmax;
    localparam integer DATA_WIDTH = 16;
    localparam integer LENGTH = 8;
    localparam integer ADDR_WIDTH = $clog2(LENGTH);

    reg clk;
    reg rst;
    reg start;
    wire done;
    wire [ADDR_WIDTH-1:0] rd_addr;
    wire signed [DATA_WIDTH-1:0] rd_data;
    wire [ADDR_WIDTH-1:0] max_index;
    wire signed [DATA_WIDTH-1:0] max_value;

    reg signed [DATA_WIDTH-1:0] input_mem [0:LENGTH-1];
    reg [DATA_WIDTH+ADDR_WIDTH-1:0] golden [0:0];
    reg signed [DATA_WIDTH-1:0] rd_data_d0;
    reg signed [DATA_WIDTH-1:0] rd_data_d1;

    assign rd_data = rd_data_d1;

    argmax #(
        .DATA_WIDTH(DATA_WIDTH),
        .LENGTH(LENGTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .max_index(max_index),
        .max_value(max_value)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        rd_data_d0 <= input_mem[rd_addr];
        rd_data_d1 <= rd_data_d0;
    end

    initial begin
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/argmax_input.mem", input_mem);
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/argmax_expected.mem", golden);

        rst = 1'b1;
        start = 1'b0;
        rd_data_d0 = 0;
        rd_data_d1 = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done);
        @(posedge clk);

        if ((max_index !== golden[0][DATA_WIDTH+ADDR_WIDTH-1:DATA_WIDTH]) ||
            (max_value !== golden[0][DATA_WIDTH-1:0])) begin
            $fatal;
        end

        $finish;
    end
endmodule
