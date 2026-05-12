`timescale 1ns / 1ps

module tb_conv2d_sequential;
    localparam integer DATA_WIDTH = 16;
    localparam integer ACC_WIDTH = 64;
    localparam integer IN_C = 2;
    localparam integer OUT_C = 2;
    localparam integer IN_H = 3;
    localparam integer IN_W = 3;
    localparam integer K = 3;
    localparam integer STRIDE = 1;
    localparam integer PAD = 1;
    localparam integer GROUPS = 1;
    localparam integer RELU_OUTPUT = 0;
    localparam integer OUT_H = ((IN_H + 2 * PAD - K) / STRIDE + 1);
    localparam integer OUT_W = ((IN_W + 2 * PAD - K) / STRIDE + 1);
    localparam integer IN_PER_GROUP = (IN_C / GROUPS);
    localparam integer INPUT_SIZE = IN_C * IN_H * IN_W;
    localparam integer OUTPUT_SIZE = OUT_C * OUT_H * OUT_W;
    localparam integer WEIGHT_SIZE = OUT_C * IN_PER_GROUP * K * K;
    localparam integer IN_ADDR_WIDTH = $clog2(INPUT_SIZE);
    localparam integer WEIGHT_ADDR_WIDTH = $clog2(WEIGHT_SIZE);
    localparam integer BIAS_ADDR_WIDTH = $clog2(OUT_C);
    localparam integer OUT_ADDR_WIDTH = $clog2(OUTPUT_SIZE);

    reg clk;
    reg rst;
    reg start;
    wire done;

    wire [IN_ADDR_WIDTH-1:0] input_addr;
    wire signed [DATA_WIDTH-1:0] input_data;
    wire [WEIGHT_ADDR_WIDTH-1:0] weight_addr;
    wire signed [DATA_WIDTH-1:0] weight_data;
    wire [BIAS_ADDR_WIDTH-1:0] bias_addr;
    wire signed [DATA_WIDTH-1:0] bias_data;
    wire output_we;
    wire [OUT_ADDR_WIDTH-1:0] output_addr;
    wire signed [DATA_WIDTH-1:0] output_data;

    reg signed [DATA_WIDTH-1:0] input_mem [0:INPUT_SIZE-1];
    reg signed [DATA_WIDTH-1:0] weight_mem [0:WEIGHT_SIZE-1];
    reg signed [DATA_WIDTH-1:0] bias_mem [0:OUT_C-1];
    reg signed [DATA_WIDTH-1:0] expected_mem [0:OUTPUT_SIZE-1];

    reg signed [DATA_WIDTH-1:0] input_data_d0;
    reg signed [DATA_WIDTH-1:0] input_data_d1;
    reg signed [DATA_WIDTH-1:0] weight_data_d0;
    reg signed [DATA_WIDTH-1:0] weight_data_d1;
    reg signed [DATA_WIDTH-1:0] bias_data_d0;
    reg signed [DATA_WIDTH-1:0] bias_data_d1;

    integer output_count;
    integer timeout_count;

    assign input_data = input_data_d1;
    assign weight_data = weight_data_d1;
    assign bias_data = bias_data_d1;

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .IN_C(IN_C),
        .OUT_C(OUT_C),
        .IN_H(IN_H),
        .IN_W(IN_W),
        .K(K),
        .STRIDE(STRIDE),
        .PAD(PAD),
        .GROUPS(GROUPS),
        .RELU_OUTPUT(RELU_OUTPUT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .input_addr(input_addr),
        .input_data(input_data),
        .weight_addr(weight_addr),
        .weight_data(weight_data),
        .bias_addr(bias_addr),
        .bias_data(bias_data),
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
        weight_data_d0 <= weight_mem[weight_addr];
        weight_data_d1 <= weight_data_d0;
        bias_data_d0 <= bias_mem[bias_addr];
        bias_data_d1 <= bias_data_d0;
    end

    always @(posedge clk) begin
        if (rst) begin
            output_count <= 0;
        end else if (output_we) begin
            if (output_addr >= OUTPUT_SIZE) begin
                $display("Output address out of range: addr=%0d", output_addr);
                $fatal;
            end

            if (output_data !== expected_mem[output_addr]) begin
                $display("Mismatch at output[%0d]: got %0d (0x%h), expected %0d (0x%h)",
                         output_addr, output_data, output_data,
                         expected_mem[output_addr], expected_mem[output_addr]);
                $fatal;
            end

            output_count <= output_count + 1;
        end
    end

    initial begin
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/conv2d_input.mem", input_mem);
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/conv2d_weight.mem", weight_mem);
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/conv2d_bias.mem", bias_mem);
        $readmemh("C:/Users/NguyenHuy/Downloads/SoC_Project/golden/conv2d_expected.mem", expected_mem);

        rst = 1'b1;
        start = 1'b0;
        input_data_d0 = 0;
        input_data_d1 = 0;
        weight_data_d0 = 0;
        weight_data_d1 = 0;
        bias_data_d0 = 0;
        bias_data_d1 = 0;
        output_count = 0;
        timeout_count = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        while (!done && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (!done) begin
            $display("Timeout waiting for done");
            $fatal;
        end

        @(posedge clk);

        if (output_count != OUTPUT_SIZE) begin
            $display("Wrong output count: got %0d, expected %0d", output_count, OUTPUT_SIZE);
            $fatal;
        end

        $display("tb_conv2d_sequential passed");
        $finish;
    end
endmodule
