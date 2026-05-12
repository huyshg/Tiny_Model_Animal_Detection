module tb_avgpool_1x1;
    localparam integer DATA_WIDTH = 16;
    localparam integer CHANNELS = 3;
    localparam integer IN_H = 2;
    localparam integer IN_W = 2;
    localparam integer INPUT_SIZE = CHANNELS * IN_H * IN_W;
    localparam integer IN_ADDR_WIDTH = $clog2(INPUT_SIZE);
    localparam integer OUT_ADDR_WIDTH = $clog2(CHANNELS);

    reg clk;
    reg rst;
    reg start;
    wire done;
    wire [IN_ADDR_WIDTH-1:0] input_addr;
    wire signed [DATA_WIDTH-1:0] input_data;
    wire output_we;
    wire [OUT_ADDR_WIDTH-1:0] output_addr;
    wire signed [DATA_WIDTH-1:0] output_data;

    reg signed [DATA_WIDTH-1:0] input_mem [0:INPUT_SIZE-1];
    reg signed [DATA_WIDTH-1:0] expected_mem [0:CHANNELS-1];
    reg signed [DATA_WIDTH-1:0] input_data_d0;
    reg signed [DATA_WIDTH-1:0] input_data_d1;
    integer output_count;

    assign input_data = input_data_d1;

    avgpool_1x1 #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNELS(CHANNELS),
        .IN_H(IN_H),
        .IN_W(IN_W),
        .INPUT_SIZE(INPUT_SIZE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .input_addr(input_addr),
        .input_data(input_data),
        .output_we(output_we),
        .output_addr(output_addr),
        .output_data(output_data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        input_data_d0 <= input_mem[input_addr];
        input_data_d1 <= input_data_d0;
    end

    always @(posedge clk) begin
        if (rst) begin
            output_count <= 0;
        end else if (output_we) begin
            if (output_data !== expected_mem[output_addr]) begin
                $fatal;
            end
            output_count <= output_count + 1;
        end
    end

    initial begin
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/avgpool_input.mem", input_mem);
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/avgpool_expected.mem", expected_mem);

        rst = 1'b1;
        start = 1'b0;
        input_data_d0 = 0;
        input_data_d1 = 0;
        output_count = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done);
        @(posedge clk);

        if (output_count != CHANNELS) begin
            $fatal;
        end

        $finish;
    end
endmodule
