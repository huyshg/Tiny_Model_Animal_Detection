module linear_sequential #(
    parameter integer DATA_WIDTH = 16,
    parameter integer ACC_WIDTH = 64,
    parameter integer FRAC_BITS = 9,
    parameter integer IN_FEATURES = 307,
    parameter integer OUT_FEATURES = 10,
    parameter integer WEIGHT_SIZE = (IN_FEATURES * OUT_FEATURES)
) (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,

    output reg [$clog2(IN_FEATURES)-1:0] input_addr,
    input wire signed [DATA_WIDTH-1:0] input_data,

    output reg [$clog2(WEIGHT_SIZE)-1:0] weight_addr,
    input wire signed [DATA_WIDTH-1:0] weight_data,

    output reg [$clog2(OUT_FEATURES)-1:0] bias_addr,
    input wire signed [DATA_WIDTH-1:0] bias_data,

    output reg output_we,
    output reg [$clog2(OUT_FEATURES)-1:0] output_addr,
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

    reg [2:0] state;
    integer out_i;
    integer in_i;
    reg issue_done;
    reg pipe_valid;
    reg pipe_last;
    reg pipe_valid_d;
    reg pipe_last_d;
    reg pipe_valid_dd;
    reg pipe_last_dd;
    reg signed [ACC_WIDTH-1:0] acc;
    reg [31:0] weight_base;
    wire signed [(DATA_WIDTH*2)-1:0] product;
    wire signed [ACC_WIDTH-1:0] bias_ext;
    wire signed [ACC_WIDTH-1:0] product_ext;
    wire signed [ACC_WIDTH-1:0] round_bias;
    wire signed [ACC_WIDTH-1:0] acc_abs;
    wire signed [ACC_WIDTH-1:0] rounded;
    wire signed [DATA_WIDTH-1:0] clipped;

    localparam signed [ACC_WIDTH-1:0] CLIP_MAX = {{(ACC_WIDTH-DATA_WIDTH+1){1'b0}}, {(DATA_WIDTH-1){1'b1}}};
    localparam signed [ACC_WIDTH-1:0] CLIP_MIN = {{(ACC_WIDTH-DATA_WIDTH+1){1'b1}}, {(DATA_WIDTH-1){1'b0}}};

    assign product = input_data * weight_data;
    assign bias_ext = bias_data;
    assign product_ext = product;
    assign round_bias = {{(ACC_WIDTH-1){1'b0}}, 1'b1} <<< (FRAC_BITS - 1);
    assign acc_abs = (acc < 0) ? -acc : acc;
    assign rounded = (acc < 0) ? -((acc_abs + round_bias) >>> FRAC_BITS) : ((acc + round_bias) >>> FRAC_BITS);
    assign clipped = (rounded > CLIP_MAX) ? {1'b0, {(DATA_WIDTH-1){1'b1}}} :
                     (rounded < CLIP_MIN) ? {1'b1, {(DATA_WIDTH-1){1'b0}}} :
                     rounded[DATA_WIDTH-1:0];

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
            out_i = 0;
            in_i = 0;
            issue_done <= 1'b0;
            pipe_valid <= 1'b0;
            pipe_last <= 1'b0;
            pipe_valid_d <= 1'b0;
            pipe_last_d <= 1'b0;
            pipe_valid_dd <= 1'b0;
            pipe_last_dd <= 1'b0;
            acc <= 0;
            weight_base <= 0;
        end else begin
            done <= 1'b0;
            output_we <= 1'b0;

            case (state)
                S_IDLE: begin
                    pipe_valid <= 1'b0;
                    if (start) begin
                        out_i = 0;
                        in_i = 0;
                        issue_done <= 1'b0;
                        weight_base <= 0;
                        state <= S_BIAS_ADDR;
                    end
                end

                S_BIAS_ADDR: begin
                    bias_addr <= out_i;
                    state <= S_BIAS_WAIT;
                end

                S_BIAS_WAIT: begin
                    state <= S_BIAS_WAIT2;
                end

                S_BIAS_WAIT2: begin
                    state <= S_BIAS_LOAD;
                end

                S_BIAS_LOAD: begin
                    acc <= bias_ext <<< FRAC_BITS;
                    in_i = 0;
                    issue_done <= 1'b0;
                    pipe_valid <= 1'b0;
                    pipe_last <= 1'b0;
                    pipe_valid_d <= 1'b0;
                    pipe_last_d <= 1'b0;
                    pipe_valid_dd <= 1'b0;
                    pipe_last_dd <= 1'b0;
                    state <= S_MAC;
                end

                S_MAC: begin
                    pipe_valid_d <= pipe_valid;
                    pipe_last_d <= pipe_last;
                    pipe_valid_dd <= pipe_valid_d;
                    pipe_last_dd <= pipe_last_d;

                    if (pipe_valid_dd) begin
                        acc <= acc + product_ext;
                    end

                    if (pipe_valid_dd && pipe_last_dd) begin
                        pipe_valid <= 1'b0;
                        state <= S_WRITE;
                    end else if (!issue_done) begin
                        input_addr <= in_i;
                        weight_addr <= weight_base + in_i;
                        pipe_valid <= 1'b1;
                        pipe_last <= (in_i == IN_FEATURES - 1);

                        if (in_i == IN_FEATURES - 1) begin
                            issue_done <= 1'b1;
                        end else begin
                            in_i = in_i + 1;
                        end
                    end else begin
                        pipe_valid <= 1'b0;
                    end
                end

                S_WRITE: begin
                    output_we <= 1'b1;
                    output_addr <= out_i;
                    output_data <= clipped;
                    if (out_i < OUT_FEATURES - 1) begin
                        out_i = out_i + 1;
                        weight_base <= weight_base + IN_FEATURES;
                        state <= S_BIAS_ADDR;
                    end else begin
                        state <= S_DONE;
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
