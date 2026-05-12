module conv2d_depthwise_sequential #(
    parameter integer DATA_WIDTH = 16,
    parameter integer ACC_WIDTH = 64,
    parameter integer CHANNELS = 25,
    parameter integer IN_H = 80,
    parameter integer IN_W = 80,
    parameter integer K = 3,
    parameter integer STRIDE = 1,
    parameter integer PAD = 1,
    parameter integer RELU_OUTPUT = 0,
    parameter integer OUT_H = ((IN_H + 2 * PAD - K) / STRIDE + 1),
    parameter integer OUT_W = ((IN_W + 2 * PAD - K) / STRIDE + 1),
    parameter integer INPUT_SIZE = (CHANNELS * IN_H * IN_W),
    parameter integer OUTPUT_SIZE = (CHANNELS * OUT_H * OUT_W),
    parameter integer WEIGHT_SIZE = (CHANNELS * K * K)
) (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,

    output reg [$clog2(INPUT_SIZE)-1:0] input_addr,
    input wire signed [DATA_WIDTH-1:0] input_data,

    output reg [$clog2(WEIGHT_SIZE)-1:0] weight_addr,
    input wire signed [DATA_WIDTH-1:0] weight_data,

    output reg [$clog2(CHANNELS)-1:0] bias_addr,
    input wire signed [DATA_WIDTH-1:0] bias_data,

    output reg output_we,
    output reg [$clog2(OUTPUT_SIZE)-1:0] output_addr,
    output reg signed [DATA_WIDTH-1:0] output_data
);
    localparam S_IDLE = 3'd0;
    localparam S_BIAS_ADDR = 3'd1;
    localparam S_BIAS_WAIT = 3'd2;
    localparam S_BIAS_WAIT2 = 3'd3;
    localparam S_BIAS_LOAD = 3'd4;
    localparam S_MAC = 3'd5;
    localparam S_WRITE = 3'd6;
    localparam S_DONE = 3'd7;

    localparam signed [ACC_WIDTH-1:0] ROUND_BIAS_Q6_9 = 256;
    localparam signed [ACC_WIDTH-1:0] CLIP_MAX_Q6_9 = 32767;
    localparam signed [ACC_WIDTH-1:0] CLIP_MIN_Q6_9 = -32768;

    reg [2:0] state;
    integer oc;
    integer oy;
    integer ox;
    integer ky;
    integer kx;
    integer iy;
    integer ix;

    reg in_range;
    reg last_mac;
    reg issue_done;
    reg pipe_valid;
    reg pipe_in_range;
    reg pipe_last;
    reg pipe_valid_d;
    reg pipe_in_range_d;
    reg pipe_last_d;
    reg pipe_valid_dd;
    reg pipe_in_range_dd;
    reg pipe_last_dd;

    reg signed [ACC_WIDTH-1:0] acc;
    reg signed [ACC_WIDTH-1:0] rounded;
    reg signed [DATA_WIDTH-1:0] clipped;
    wire signed [(DATA_WIDTH*2)-1:0] product;
    wire signed [ACC_WIDTH-1:0] product_ext;
    wire signed [ACC_WIDTH-1:0] bias_ext;

    assign product = input_data * weight_data;
    assign product_ext = product;
    assign bias_ext = bias_data;

    task advance_kernel;
        begin
            if (kx < K - 1) begin
                kx = kx + 1;
            end else begin
                kx = 0;
                if (ky < K - 1) begin
                    ky = ky + 1;
                end else begin
                    ky = 0;
                end
            end
        end
    endtask

    task advance_output;
        begin
            if (ox < OUT_W - 1) begin
                ox = ox + 1;
            end else begin
                ox = 0;
                if (oy < OUT_H - 1) begin
                    oy = oy + 1;
                end else begin
                    oy = 0;
                    oc = oc + 1;
                end
            end
        end
    endtask

    always @(*) begin
        iy = oy * STRIDE + ky - PAD;
        ix = ox * STRIDE + kx - PAD;
        in_range = (iy >= 0 && iy < IN_H && ix >= 0 && ix < IN_W);
        last_mac = (ky == K - 1 && kx == K - 1);
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
            output_we <= 1'b0;
            input_addr <= 0;
            weight_addr <= 0;
            bias_addr <= 0;
            output_addr <= 0;
            output_data <= 0;
            oc = 0;
            oy = 0;
            ox = 0;
            ky = 0;
            kx = 0;
            issue_done <= 1'b0;
            pipe_valid <= 1'b0;
            pipe_in_range <= 1'b0;
            pipe_last <= 1'b0;
            pipe_valid_d <= 1'b0;
            pipe_in_range_d <= 1'b0;
            pipe_last_d <= 1'b0;
            pipe_valid_dd <= 1'b0;
            pipe_in_range_dd <= 1'b0;
            pipe_last_dd <= 1'b0;
            acc <= 0;
            rounded <= 0;
            clipped <= 0;
        end else begin
            done <= 1'b0;
            output_we <= 1'b0;

            case (state)
                S_IDLE: begin
                    pipe_valid <= 1'b0;
                    if (start) begin
                        oc = 0;
                        oy = 0;
                        ox = 0;
                        ky = 0;
                        kx = 0;
                        issue_done <= 1'b0;
                        state <= S_BIAS_ADDR;
                    end
                end

                S_BIAS_ADDR: begin
                    bias_addr <= oc;
                    state <= S_BIAS_WAIT;
                end

                S_BIAS_WAIT: begin
                    state <= S_BIAS_WAIT2;
                end

                S_BIAS_WAIT2: begin
                    state <= S_BIAS_LOAD;
                end

                S_BIAS_LOAD: begin
                    acc <= bias_ext <<< 9;
                    ky = 0;
                    kx = 0;
                    issue_done <= 1'b0;
                    pipe_valid <= 1'b0;
                    pipe_in_range <= 1'b0;
                    pipe_last <= 1'b0;
                    pipe_valid_d <= 1'b0;
                    pipe_in_range_d <= 1'b0;
                    pipe_last_d <= 1'b0;
                    pipe_valid_dd <= 1'b0;
                    pipe_in_range_dd <= 1'b0;
                    pipe_last_dd <= 1'b0;
                    state <= S_MAC;
                end

                S_MAC: begin
                    pipe_valid_d <= pipe_valid;
                    pipe_in_range_d <= pipe_in_range;
                    pipe_last_d <= pipe_last;
                    pipe_valid_dd <= pipe_valid_d;
                    pipe_in_range_dd <= pipe_in_range_d;
                    pipe_last_dd <= pipe_last_d;

                    if (pipe_valid_dd && pipe_in_range_dd) begin
                        acc <= acc + product_ext;
                    end

                    if (pipe_valid_dd && pipe_last_dd) begin
                        pipe_valid <= 1'b0;
                        state <= S_WRITE;
                    end else if (!issue_done) begin
                        weight_addr <= oc * K * K + ky * K + kx;
                        if (in_range) begin
                            input_addr <= oc * IN_H * IN_W + iy * IN_W + ix;
                        end
                        pipe_valid <= 1'b1;
                        pipe_in_range <= in_range;
                        pipe_last <= last_mac;
                        if (last_mac) begin
                            issue_done <= 1'b1;
                        end else begin
                            advance_kernel();
                        end
                    end else begin
                        pipe_valid <= 1'b0;
                    end
                end

                S_WRITE: begin
                    output_we <= 1'b1;
                    output_addr <= oc * OUT_H * OUT_W + oy * OUT_W + ox;

                    if (acc >= 0) begin
                        rounded = (acc + ROUND_BIAS_Q6_9) >>> 9;
                    end else begin
                        rounded = -(((-acc) + ROUND_BIAS_Q6_9) >>> 9);
                    end

                    if (rounded > CLIP_MAX_Q6_9) begin
                        clipped = 16'sh7fff;
                    end else if (rounded < CLIP_MIN_Q6_9) begin
                        clipped = 16'sh8000;
                    end else begin
                        clipped = rounded[DATA_WIDTH-1:0];
                    end

                    if (RELU_OUTPUT != 0 && clipped < 0) begin
                        output_data <= {DATA_WIDTH{1'b0}};
                    end else begin
                        output_data <= clipped;
                    end

                    if (oc == CHANNELS - 1 && oy == OUT_H - 1 && ox == OUT_W - 1) begin
                        state <= S_DONE;
                    end else begin
                        advance_output();
                        state <= S_BIAS_ADDR;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
