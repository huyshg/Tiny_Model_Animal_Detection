`include "../include/animalnet_defs.vh"

module relu_vector #(
    parameter integer DATA_WIDTH = `DATA_WIDTH,
    parameter integer LENGTH = 1
) (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,

    output reg [$clog2(LENGTH)-1:0] rd_addr,
    input wire signed [DATA_WIDTH-1:0] rd_data,

    output reg wr_en,
    output reg [$clog2(LENGTH)-1:0] wr_addr,
    output reg signed [DATA_WIDTH-1:0] wr_data
);
    localparam S_IDLE = 2'd0;
    localparam S_READ = 2'd1;
    localparam S_WRITE = 2'd2;
    localparam S_DONE = 2'd3;

    reg [1:0] state;
    reg [$clog2(LENGTH)-1:0] index;
    reg signed [DATA_WIDTH-1:0] value_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
            wr_en <= 1'b0;
            rd_addr <= 0;
            wr_addr <= 0;
            wr_data <= 0;
            index <= 0;
            value_reg <= 0;
        end else begin
            wr_en <= 1'b0;
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        index <= 0;
                        rd_addr <= 0;
                        state <= S_READ;
                    end
                end

                S_READ: begin
                    value_reg <= rd_data;
                    state <= S_WRITE;
                end

                S_WRITE: begin
                    wr_en <= 1'b1;
                    wr_addr <= index;
                    wr_data <= value_reg[DATA_WIDTH-1] ? {DATA_WIDTH{1'b0}} : value_reg;
                    if (index == LENGTH - 1) begin
                        state <= S_DONE;
                    end else begin
                        index <= index + 1'b1;
                        rd_addr <= index + 1'b1;
                        state <= S_READ;
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
