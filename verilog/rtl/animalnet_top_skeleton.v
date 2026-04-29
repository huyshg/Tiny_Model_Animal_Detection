`include "../include/animalnet_defs.vh"

module animalnet_top_skeleton (
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,
    output wire [3:0] predicted_class
);
    localparam S_IDLE = 8'd0;
    localparam S_CONV0 = 8'd1;
    localparam S_RELU0 = 8'd2;
    localparam S_CONV1 = 8'd3;
    localparam S_RELU1 = 8'd4;
    localparam S_CONV2 = 8'd5;
    localparam S_RELU2 = 8'd6;
    localparam S_CONV3 = 8'd7;
    localparam S_RELU3 = 8'd8;
    localparam S_CONV4 = 8'd9;
    localparam S_RELU4 = 8'd10;
    localparam S_CONV5 = 8'd11;
    localparam S_RELU5 = 8'd12;
    localparam S_CONV6 = 8'd13;
    localparam S_RELU6 = 8'd14;
    localparam S_CONV7 = 8'd15;
    localparam S_RELU7 = 8'd16;
    localparam S_CONV8 = 8'd17;
    localparam S_RELU8 = 8'd18;
    localparam S_CONV9 = 8'd19;
    localparam S_RELU9 = 8'd20;
    localparam S_CONV10 = 8'd21;
    localparam S_RELU10 = 8'd22;
    localparam S_CONV11 = 8'd23;
    localparam S_RELU11 = 8'd24;
    localparam S_CONV12 = 8'd25;
    localparam S_RELU12 = 8'd26;
    localparam S_CONV13 = 8'd27;
    localparam S_RELU13 = 8'd28;
    localparam S_CONV14 = 8'd29;
    localparam S_RELU14 = 8'd30;
    localparam S_POOL = 8'd31;
    localparam S_LINEAR = 8'd32;
    localparam S_ARGMAX = 8'd33;
    localparam S_DONE = 8'd34;

    reg [7:0] state;
    reg [7:0] next_state;

    assign predicted_class = 4'd0;

    always @(*) begin
        case (state)
            S_IDLE: next_state = start ? S_CONV0 : S_IDLE;
            S_CONV0: next_state = S_RELU0;
            S_RELU0: next_state = S_CONV1;
            S_CONV1: next_state = S_RELU1;
            S_RELU1: next_state = S_CONV2;
            S_CONV2: next_state = S_RELU2;
            S_RELU2: next_state = S_CONV3;
            S_CONV3: next_state = S_RELU3;
            S_RELU3: next_state = S_CONV4;
            S_CONV4: next_state = S_RELU4;
            S_RELU4: next_state = S_CONV5;
            S_CONV5: next_state = S_RELU5;
            S_RELU5: next_state = S_CONV6;
            S_CONV6: next_state = S_RELU6;
            S_RELU6: next_state = S_CONV7;
            S_CONV7: next_state = S_RELU7;
            S_RELU7: next_state = S_CONV8;
            S_CONV8: next_state = S_RELU8;
            S_RELU8: next_state = S_CONV9;
            S_CONV9: next_state = S_RELU9;
            S_RELU9: next_state = S_CONV10;
            S_CONV10: next_state = S_RELU10;
            S_RELU10: next_state = S_CONV11;
            S_CONV11: next_state = S_RELU11;
            S_RELU11: next_state = S_CONV12;
            S_CONV12: next_state = S_RELU12;
            S_RELU12: next_state = S_CONV13;
            S_CONV13: next_state = S_RELU13;
            S_RELU13: next_state = S_CONV14;
            S_CONV14: next_state = S_RELU14;
            S_RELU14: next_state = S_POOL;
            S_POOL: next_state = S_LINEAR;
            S_LINEAR: next_state = S_ARGMAX;
            S_ARGMAX: next_state = S_DONE;
            S_DONE: next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 1'b0;
        end else begin
            state <= next_state;
            done <= (state == S_DONE);
        end
    end

    /*
        This file is the integration map. Instantiate conv2d_sequential,
        relu_vector, avgpool_1x1, linear_sequential, and argmax here with
        BRAMs sized for each layer.

        The arithmetic modules are already provided in this folder. Keeping
        this top-level as a skeleton makes it easier to decide later whether
        to reuse one compute engine for all layers or instantiate multiple
        engines for parallelism.
    */
endmodule
