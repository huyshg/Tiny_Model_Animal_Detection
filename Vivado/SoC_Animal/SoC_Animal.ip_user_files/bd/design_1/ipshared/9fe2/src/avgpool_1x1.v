module avgpool_1x1 #(
    parameter integer DATA_WIDTH = 16,
    parameter integer CHANNELS = 307,
    parameter integer IN_H = 10,
    parameter integer IN_W = 10,
    parameter integer INPUT_SIZE = (CHANNELS * IN_H * IN_W)
) (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,

    output reg [$clog2(INPUT_SIZE)-1:0] input_addr,
    input wire signed [DATA_WIDTH-1:0] input_data,

    output reg output_we,
    output reg [$clog2(CHANNELS)-1:0] output_addr,
    output reg signed [DATA_WIDTH-1:0] output_data
);
    localparam integer POOL_SIZE = IN_H * IN_W;
    localparam integer POOL_ACC_WIDTH = DATA_WIDTH + $clog2(POOL_SIZE) + 1;
    localparam signed [POOL_ACC_WIDTH-1:0] ROUND_HALF = (POOL_SIZE / 2);

    localparam S_IDLE = 2'd0;
    localparam S_POOL = 2'd1;
    localparam S_WRITE = 2'd2;
    localparam S_DONE = 2'd3;

    reg [1:0] state;
    integer c;
    integer y;
    integer x;
    reg issue_done;
    reg pipe_valid;
    reg pipe_last;
    reg pipe_valid_d;
    reg pipe_last_d;
    reg pipe_valid_dd;
    reg pipe_last_dd;
    reg signed [POOL_ACC_WIDTH-1:0] acc;
    wire signed [POOL_ACC_WIDTH-1:0] input_ext;
    wire signed [POOL_ACC_WIDTH-1:0] acc_abs;
    wire signed [POOL_ACC_WIDTH-1:0] avg_abs;
    wire signed [POOL_ACC_WIDTH-1:0] avg_value;

    assign input_ext = input_data;
    assign acc_abs = (acc < 0) ? -acc : acc;
    assign avg_abs = (acc_abs + ROUND_HALF) / POOL_SIZE;
    assign avg_value = (acc < 0) ? -avg_abs : avg_abs;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
            output_we <= 1'b0;
            input_addr <= 0;
            output_addr <= 0;
            output_data <= 0;
            c = 0;
            y = 0;
            x = 0;
            issue_done <= 1'b0;
            pipe_valid <= 1'b0;
            pipe_last <= 1'b0;
            pipe_valid_d <= 1'b0;
            pipe_last_d <= 1'b0;
            pipe_valid_dd <= 1'b0;
            pipe_last_dd <= 1'b0;
            acc <= 0;
        end else begin
            done <= 1'b0;
            output_we <= 1'b0;

            case (state)
                S_IDLE: begin
                    pipe_valid <= 1'b0;
                    if (start) begin
                        c = 0;
                        y = 0;
                        x = 0;
                        issue_done <= 1'b0;
                        pipe_valid <= 1'b0;
                        pipe_last <= 1'b0;
                        pipe_valid_d <= 1'b0;
                        pipe_last_d <= 1'b0;
                        pipe_valid_dd <= 1'b0;
                        pipe_last_dd <= 1'b0;
                        acc <= 0;
                        state <= S_POOL;
                    end
                end

                S_POOL: begin
                    pipe_valid_d <= pipe_valid;
                    pipe_last_d <= pipe_last;
                    pipe_valid_dd <= pipe_valid_d;
                    pipe_last_dd <= pipe_last_d;

                    if (pipe_valid_dd) begin
                        acc <= acc + input_ext;
                    end

                    if (pipe_valid_dd && pipe_last_dd) begin
                        pipe_valid <= 1'b0;
                        state <= S_WRITE;
                    end else if (!issue_done) begin
                        input_addr <= c * IN_H * IN_W + y * IN_W + x;
                        pipe_valid <= 1'b1;
                        pipe_last <= (x == IN_W - 1 && y == IN_H - 1);

                        if (x == IN_W - 1 && y == IN_H - 1) begin
                            issue_done <= 1'b1;
                        end else begin
                        if (x < IN_W - 1) begin
                            x = x + 1;
                        end else begin
                            x = 0;
                            y = y + 1;
                        end
                        end
                    end else begin
                        pipe_valid <= 1'b0;
                    end
                end

                S_WRITE: begin
                    output_we <= 1'b1;
                    output_addr <= c;
                    output_data <= avg_value[DATA_WIDTH-1:0];
                    acc <= 0;
                    if (c < CHANNELS - 1) begin
                        c = c + 1;
                        y = 0;
                        x = 0;
                        issue_done <= 1'b0;
                        pipe_valid <= 1'b0;
                        pipe_last <= 1'b0;
                        pipe_valid_d <= 1'b0;
                        pipe_last_d <= 1'b0;
                        pipe_valid_dd <= 1'b0;
                        pipe_last_dd <= 1'b0;
                        state <= S_POOL;
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
