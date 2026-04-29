`include "../include/animalnet_defs.vh"

module argmax #(
    parameter integer DATA_WIDTH = `DATA_WIDTH,
    parameter integer LENGTH = `CLASS_COUNT
) (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,

    output reg [$clog2(LENGTH)-1:0] rd_addr,
    input wire signed [DATA_WIDTH-1:0] rd_data,

    output reg [$clog2(LENGTH)-1:0] max_index,
    output reg signed [DATA_WIDTH-1:0] max_value
);
    localparam S_IDLE = 2'd0;
    localparam S_READ = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [$clog2(LENGTH)-1:0] index;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
            rd_addr <= 0;
            index <= 0;
            max_index <= 0;
            max_value <= {1'b1, {(DATA_WIDTH-1){1'b0}}};
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (start) begin
                        index <= 0;
                        rd_addr <= 0;
                        max_index <= 0;
                        max_value <= {1'b1, {(DATA_WIDTH-1){1'b0}}};
                        state <= S_READ;
                    end
                end

                S_READ: begin
                    if (rd_data > max_value) begin
                        max_value <= rd_data;
                        max_index <= index;
                    end
                    if (index == LENGTH - 1) begin
                        state <= S_DONE;
                    end else begin
                        index <= index + 1'b1;
                        rd_addr <= index + 1'b1;
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
