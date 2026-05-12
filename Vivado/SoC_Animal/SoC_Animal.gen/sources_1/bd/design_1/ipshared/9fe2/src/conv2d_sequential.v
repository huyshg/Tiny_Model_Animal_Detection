module conv2d_sequential #(
    parameter integer DATA_WIDTH = 16,
    parameter integer ACC_WIDTH = 64,
    parameter integer FRAC_BITS = 9,
    parameter integer IN_C = 3,
    parameter integer OUT_C = 25,
    parameter integer IN_H = 160,
    parameter integer IN_W = 160,
    parameter integer K = 3,
    parameter integer STRIDE = 2,
    parameter integer PAD = 1,
    parameter integer GROUPS = 1,
    parameter integer RELU_OUTPUT = 0,
    parameter integer OUT_H = ((IN_H + 2 * PAD - K) / STRIDE + 1),
    parameter integer OUT_W = ((IN_W + 2 * PAD - K) / STRIDE + 1),
    parameter integer IN_PER_GROUP = (IN_C / GROUPS),
    parameter integer INPUT_SIZE = (IN_C * IN_H * IN_W),
    parameter integer OUTPUT_SIZE = (OUT_C * OUT_H * OUT_W),
    parameter integer WEIGHT_SIZE = (OUT_C * IN_PER_GROUP * K * K)
) (
    input wire clk,
    input wire rst,
    input wire start,
    output wire done,

    output wire [$clog2(INPUT_SIZE)-1:0] input_addr,
    input wire signed [DATA_WIDTH-1:0] input_data,

    output wire [$clog2(WEIGHT_SIZE)-1:0] weight_addr,
    input wire signed [DATA_WIDTH-1:0] weight_data,

    output wire [$clog2(OUT_C)-1:0] bias_addr,
    input wire signed [DATA_WIDTH-1:0] bias_data,

    output wire output_we,
    output wire [$clog2(OUTPUT_SIZE)-1:0] output_addr,
    output wire signed [DATA_WIDTH-1:0] output_data
);
    generate
        if (GROUPS == 1) begin : gen_regular
            conv2d_regular_sequential #(
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(ACC_WIDTH),
                .IN_C(IN_C),
                .OUT_C(OUT_C),
                .IN_H(IN_H),
                .IN_W(IN_W),
                .K(K),
                .STRIDE(STRIDE),
                .PAD(PAD),
                .RELU_OUTPUT(RELU_OUTPUT)
            ) u_conv (
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
        end else if (GROUPS == IN_C && OUT_C == IN_C) begin : gen_depthwise
            conv2d_depthwise_sequential #(
                .DATA_WIDTH(DATA_WIDTH),
                .ACC_WIDTH(ACC_WIDTH),
                .CHANNELS(IN_C),
                .IN_H(IN_H),
                .IN_W(IN_W),
                .K(K),
                .STRIDE(STRIDE),
                .PAD(PAD),
                .RELU_OUTPUT(RELU_OUTPUT)
            ) u_conv (
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
        end else begin : gen_unsupported
            initial begin
                $error("conv2d_sequential supports only GROUPS=1 or depthwise GROUPS=IN_C=OUT_C");
            end

            assign done = 1'b0;
            assign input_addr = {$clog2(INPUT_SIZE){1'b0}};
            assign weight_addr = {$clog2(WEIGHT_SIZE){1'b0}};
            assign bias_addr = {$clog2(OUT_C){1'b0}};
            assign output_we = 1'b0;
            assign output_addr = {$clog2(OUTPUT_SIZE){1'b0}};
            assign output_data = {DATA_WIDTH{1'b0}};
        end
    endgenerate
endmodule
