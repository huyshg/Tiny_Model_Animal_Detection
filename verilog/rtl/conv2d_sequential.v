`include "../include/animalnet_defs.vh"

module conv2d_sequential #(
    parameter integer DATA_WIDTH = `DATA_WIDTH,
    parameter integer ACC_WIDTH = `ACC_WIDTH,
    parameter integer FRAC_BITS = `FRAC_BITS,
    parameter integer IN_C = 3,
    parameter integer OUT_C = 25,
    parameter integer IN_H = 160,
    parameter integer IN_W = 160,
    parameter integer K = 3,
    parameter integer STRIDE = 2,
    parameter integer PAD = 1,
    parameter integer GROUPS = 1,
    parameter integer OUT_H = ((IN_H + 2 * PAD - K) / STRIDE + 1),
    parameter integer OUT_W = ((IN_W + 2 * PAD - K) / STRIDE + 1),
    parameter integer IN_PER_GROUP = (IN_C / GROUPS),
    parameter integer OUT_PER_GROUP = (OUT_C / GROUPS),
    parameter integer INPUT_SIZE = (IN_C * IN_H * IN_W),
    parameter integer OUTPUT_SIZE = (OUT_C * OUT_H * OUT_W),
    parameter integer WEIGHT_SIZE = (OUT_C * IN_PER_GROUP * K * K)
) (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,

    output reg [$clog2(INPUT_SIZE)-1:0] input_addr,
    input wire signed [DATA_WIDTH-1:0] input_data,

    output reg [$clog2(WEIGHT_SIZE)-1:0] weight_addr,
    input wire signed [DATA_WIDTH-1:0] weight_data,

    output reg [$clog2(OUT_C)-1:0] bias_addr,
    input wire signed [DATA_WIDTH-1:0] bias_data,

    output reg output_we,
    output reg [$clog2(OUTPUT_SIZE)-1:0] output_addr,
    output reg signed [DATA_WIDTH-1:0] output_data
);
    localparam S_IDLE = 4'd0;
    localparam S_BIAS = 4'd1;
    localparam S_MAC_ADDR = 4'd2;
    localparam S_MAC_ACC = 4'd3;
    localparam S_WRITE = 4'd4;
    localparam S_DONE = 4'd5;

    reg [3:0] state;
    integer oc;
    integer oy;
    integer ox;
    integer icg;
    integer ky;
    integer kx;
    integer ic;
    integer iy;
    integer ix;
    integer group_id;
    integer valid_sample;
    integer last_kernel;

    reg signed [ACC_WIDTH-1:0] acc;
    reg signed [ACC_WIDTH-1:0] acc_next;
    reg signed [(DATA_WIDTH*2)-1:0] product;

    function integer input_index;
        input integer c;
        input integer y;
        input integer x;
        begin
            input_index = (c * IN_H + y) * IN_W + x;
        end
    endfunction

    function integer weight_index;
        input integer out_c;
        input integer in_group_c;
        input integer kernel_y;
        input integer kernel_x;
        begin
            weight_index = (((out_c * IN_PER_GROUP + in_group_c) * K + kernel_y) * K + kernel_x);
        end
    endfunction

    function integer output_index;
        input integer out_c;
        input integer y;
        input integer x;
        begin
            output_index = (out_c * OUT_H + y) * OUT_W + x;
        end
    endfunction

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
            icg = 0;
            ky = 0;
            kx = 0;
            acc <= 0;
        end else begin
            done <= 1'b0;
            output_we <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        oc = 0;
                        oy = 0;
                        ox = 0;
                        icg = 0;
                        ky = 0;
                        kx = 0;
                        bias_addr <= 0;
                        state <= S_BIAS;
                    end
                end

                S_BIAS: begin
                    acc <= {{(ACC_WIDTH-DATA_WIDTH){bias_data[DATA_WIDTH-1]}}, bias_data} <<< FRAC_BITS;
                    icg = 0;
                    ky = 0;
                    kx = 0;
                    state <= S_MAC_ADDR;
                end

                S_MAC_ADDR: begin
                    group_id = oc / OUT_PER_GROUP;
                    ic = group_id * IN_PER_GROUP + icg;
                    iy = oy * STRIDE + ky - PAD;
                    ix = ox * STRIDE + kx - PAD;
                    valid_sample = (iy >= 0 && iy < IN_H && ix >= 0 && ix < IN_W);
                    if (valid_sample) begin
                        input_addr <= input_index(ic, iy, ix);
                        weight_addr <= weight_index(oc, icg, ky, kx);
                    end
                    state <= S_MAC_ACC;
                end

                S_MAC_ACC: begin
                    acc_next = acc;
                    if (valid_sample) begin
                        product = input_data * weight_data;
                        acc_next = acc + {{(ACC_WIDTH-(DATA_WIDTH*2)){product[(DATA_WIDTH*2)-1]}}, product};
                    end
                    acc <= acc_next;
                    last_kernel = (icg == IN_PER_GROUP - 1) && (ky == K - 1) && (kx == K - 1);
                    if (last_kernel) begin
                        icg = 0;
                        ky = 0;
                        kx = 0;
                        state <= S_WRITE;
                    end else begin
                        if (kx < K - 1) begin
                            kx = kx + 1;
                        end else begin
                            kx = 0;
                            if (ky < K - 1) begin
                                ky = ky + 1;
                            end else begin
                                ky = 0;
                                icg = icg + 1;
                            end
                        end
                        state <= S_MAC_ADDR;
                    end
                end

                S_WRITE: begin
                    output_we <= 1'b1;
                    output_addr <= output_index(oc, oy, ox);
                    output_data <= acc >>> FRAC_BITS;
                    if (oc == OUT_C - 1 && oy == OUT_H - 1 && ox == OUT_W - 1) begin
                        state <= S_DONE;
                    end else begin
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
                        state <= S_BIAS;
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
