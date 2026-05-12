`timescale 1ns / 1ps

module sync_ram_1p #(
    parameter integer DATA_WIDTH = 16,
    parameter integer DEPTH = 76800,
    parameter integer ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH),
    parameter RAM_STYLE = "block",
    parameter INIT_FILE = ""
) (
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire signed [DATA_WIDTH-1:0] din,
    output wire signed [DATA_WIDTH-1:0] dout
);
    generate
        if (RAM_STYLE == "ultra") begin : gen_inferred_ultra
            localparam integer ULTRA_PACK_FACTOR = 4;
            localparam integer ULTRA_WORD_WIDTH = DATA_WIDTH * ULTRA_PACK_FACTOR;
            localparam integer ULTRA_DEPTH = (DEPTH + ULTRA_PACK_FACTOR - 1) / ULTRA_PACK_FACTOR;
            localparam integer ULTRA_ADDR_WIDTH = (ULTRA_DEPTH <= 1) ? 1 : $clog2(ULTRA_DEPTH);

            wire [ULTRA_ADDR_WIDTH-1:0] ultra_addr = addr >> 2;
            wire [1:0] ultra_lane = addr[1:0];

            reg [ULTRA_WORD_WIDTH-1:0] dout_d0;
            reg [DATA_WIDTH-1:0] dout_d1;
            reg [1:0] lane_d0;

            (* ram_style = "ultra", cascade_height = 0 *)
            reg [ULTRA_WORD_WIDTH-1:0] mem [0:ULTRA_DEPTH-1];

            always @(posedge clk) begin
                if (we) begin
                    case (ultra_lane)
                        2'd0: mem[ultra_addr][DATA_WIDTH-1:0] <= din;
                        2'd1: mem[ultra_addr][(2*DATA_WIDTH)-1:DATA_WIDTH] <= din;
                        2'd2: mem[ultra_addr][(3*DATA_WIDTH)-1:(2*DATA_WIDTH)] <= din;
                        2'd3: mem[ultra_addr][(4*DATA_WIDTH)-1:(3*DATA_WIDTH)] <= din;
                        default: ;
                    endcase
                end

                dout_d0 <= mem[ultra_addr];
                lane_d0 <= ultra_lane;

                case (lane_d0)
                    2'd0: dout_d1 <= dout_d0[DATA_WIDTH-1:0];
                    2'd1: dout_d1 <= dout_d0[(2*DATA_WIDTH)-1:DATA_WIDTH];
                    2'd2: dout_d1 <= dout_d0[(3*DATA_WIDTH)-1:(2*DATA_WIDTH)];
                    default: dout_d1 <= dout_d0[(4*DATA_WIDTH)-1:(3*DATA_WIDTH)];
                endcase
            end

            assign dout = dout_d1;
        end else begin : gen_bram
            reg [DATA_WIDTH-1:0] dout_d0;
            reg [DATA_WIDTH-1:0] dout_d1;

            (* ram_style = "block" *)
            reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

            initial begin
                if (INIT_FILE != "") begin
                    $readmemh(INIT_FILE, mem);
                end
            end

            always @(posedge clk) begin
                if (we) begin
                    mem[addr] <= din;
                end
                dout_d0 <= mem[addr];
                dout_d1 <= dout_d0;
            end

            assign dout = dout_d1;
        end
    endgenerate
endmodule
