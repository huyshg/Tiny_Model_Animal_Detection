`include "../include/animalnet_defs.vh"

module avgpool_1x1 #(
    parameter integer DATA_WIDTH = `DATA_WIDTH,
    parameter integer ACC_WIDTH = `ACC_WIDTH,
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
    localparam S_IDLE = 3'd0;
    localparam S_ADDR = 3'd1;
    localparam S_ACC = 3'd2;
    localparam S_WRITE = 3'd3;
    localparam S_DONE = 3'd4;

    reg [2:0] state;
    integer c;
    integer y;
    integer x;
    reg signed [ACC_WIDTH-1:0] acc;
    reg signed [ACC_WIDTH-1:0] acc_next;

    function integer input_index;
        input integer channel;
        input integer row;
        input integer col;
        begin
            input_index = (channel * IN_H + row) * IN_W + col;
        end
    endfunction

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
            acc <= 0;
        end else begin
            done <= 1'b0;
            output_we <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        c = 0;
                        y = 0;
                        x = 0;
                        acc <= 0;
                        state <= S_ADDR;
                    end
                end

                S_ADDR: begin
                    input_addr <= input_index(c, y, x);
                    state <= S_ACC;
                end

                S_ACC: begin
                    acc_next = acc + {{(ACC_WIDTH-DATA_WIDTH){input_data[DATA_WIDTH-1]}}, input_data};
                    acc <= acc_next;
                    if (x < IN_W - 1) begin
                        x = x + 1;
                        state <= S_ADDR;
                    end else begin
                        x = 0;
                        if (y < IN_H - 1) begin
                            y = y + 1;
                            state <= S_ADDR;
                        end else begin
                            y = 0;
                            state <= S_WRITE;
                        end
                    end
                end

                S_WRITE: begin
                    output_we <= 1'b1;
                    output_addr <= c;
                    output_data <= acc / (IN_H * IN_W);
                    acc <= 0;
                    if (c < CHANNELS - 1) begin
                        c = c + 1;
                        state <= S_ADDR;
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
