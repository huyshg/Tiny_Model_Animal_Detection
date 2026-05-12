module argmax #(
    parameter integer DATA_WIDTH = 16,
    parameter integer LENGTH = 10
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
    localparam S_IDLE = 3'd0;
    localparam S_ADDR = 3'd1;
    localparam S_WAIT = 3'd2;
    localparam S_WAIT2 = 3'd3;
    localparam S_LATCH = 3'd4;
    localparam S_COMPARE = 3'd5;
    localparam S_DONE = 3'd6;

    reg [2:0] state;
    reg [$clog2(LENGTH)-1:0] index;
    reg signed [DATA_WIDTH-1:0] sample_data;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
            rd_addr <= 0;
            index <= 0;
            max_index <= 0;
            max_value <= {1'b1, {(DATA_WIDTH-1){1'b0}}};
            sample_data <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (start) begin
                        index <= 0;
                        max_index <= 0;
                        max_value <= {1'b1, {(DATA_WIDTH-1){1'b0}}};
                        state <= S_ADDR;
                    end
                end

                S_ADDR: begin
                    rd_addr <= index;
                    state <= S_WAIT;
                end

                S_WAIT: begin
                    state <= S_WAIT2;
                end

                S_WAIT2: begin
                    state <= S_LATCH;
                end

                S_LATCH: begin
                    sample_data <= rd_data;
                    state <= S_COMPARE;
                end

                S_COMPARE: begin
                    if (sample_data > max_value) begin
                        max_value <= sample_data;
                        max_index <= index;
                    end
                    if (index == LENGTH - 1) begin
                        state <= S_DONE;
                    end else begin
                        index <= index + 1'b1;
                        state <= S_ADDR;
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
