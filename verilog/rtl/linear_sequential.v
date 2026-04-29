`include "../include/animalnet_defs.vh"

module linear_sequential #(
    parameter integer DATA_WIDTH = `DATA_WIDTH,
    parameter integer ACC_WIDTH = `ACC_WIDTH,
    parameter integer FRAC_BITS = `FRAC_BITS,
    parameter integer IN_FEATURES = `FLATTEN_SIZE,
    parameter integer OUT_FEATURES = `CLASS_COUNT,
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
    localparam S_BIAS = 3'd1;
    localparam S_ADDR = 3'd2;
    localparam S_ACC = 3'd3;
    localparam S_WRITE = 3'd4;
    localparam S_DONE = 3'd5;

    reg [2:0] state;
    integer out_i;
    integer in_i;
    reg signed [ACC_WIDTH-1:0] acc;
    reg signed [ACC_WIDTH-1:0] acc_next;
    reg signed [(DATA_WIDTH*2)-1:0] product;

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
            acc <= 0;
        end else begin
            done <= 1'b0;
            output_we <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        out_i = 0;
                        in_i = 0;
                        bias_addr <= 0;
                        state <= S_BIAS;
                    end
                end

                S_BIAS: begin
                    acc <= {{(ACC_WIDTH-DATA_WIDTH){bias_data[DATA_WIDTH-1]}}, bias_data} <<< FRAC_BITS;
                    in_i = 0;
                    state <= S_ADDR;
                end

                S_ADDR: begin
                    input_addr <= in_i;
                    weight_addr <= out_i * IN_FEATURES + in_i;
                    state <= S_ACC;
                end

                S_ACC: begin
                    product = input_data * weight_data;
                    acc_next = acc + {{(ACC_WIDTH-(DATA_WIDTH*2)){product[(DATA_WIDTH*2)-1]}}, product};
                    acc <= acc_next;
                    if (in_i < IN_FEATURES - 1) begin
                        in_i = in_i + 1;
                        state <= S_ADDR;
                    end else begin
                        state <= S_WRITE;
                    end
                end

                S_WRITE: begin
                    output_we <= 1'b1;
                    output_addr <= out_i;
                    output_data <= acc >>> FRAC_BITS;
                    if (out_i < OUT_FEATURES - 1) begin
                        out_i = out_i + 1;
                        bias_addr <= out_i + 1;
                        state <= S_BIAS;
                    end else begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
