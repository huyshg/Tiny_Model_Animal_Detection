module animalnet_top (
    input wire clk,
    input wire rst,
    input wire start,
    input wire input_we,
    input wire [18:0] input_write_addr,
    input wire signed [15:0] input_write_data,
    output reg done,
    output reg [3:0] predicted_class
);
    localparam integer DATA_WIDTH = 16;
    localparam integer ACC_WIDTH = 64;
    localparam integer FRAC_BITS = 9;
    localparam integer ADDR_WIDTH = 19;
    localparam integer INPUT_SIZE = 76800;
    localparam integer ACT_DEPTH = 326400;
    localparam integer WEIGHT_ROM_DEPTH = 202085;
    localparam integer WEIGHT_ROM_ADDR_WIDTH = 18;
    localparam integer BIAS_ROM_DEPTH = 2051;
    localparam integer BIAS_ROM_ADDR_WIDTH = 12;

    localparam integer CONV0_WEIGHT_BASE = 0;
    localparam integer CONV1_WEIGHT_BASE = 675;
    localparam integer CONV2_WEIGHT_BASE = 900;
    localparam integer CONV3_WEIGHT_BASE = 2175;
    localparam integer CONV4_WEIGHT_BASE = 2634;
    localparam integer CONV5_WEIGHT_BASE = 6510;
    localparam integer CONV6_WEIGHT_BASE = 7194;
    localparam integer CONV7_WEIGHT_BASE = 14946;
    localparam integer CONV8_WEIGHT_BASE = 15864;
    localparam integer CONV9_WEIGHT_BASE = 31470;
    localparam integer CONV10_WEIGHT_BASE = 32847;
    localparam integer CONV11_WEIGHT_BASE = 64059;
    localparam integer CONV12_WEIGHT_BASE = 65895;
    localparam integer CONV13_WEIGHT_BASE = 118119;
    localparam integer CONV14_WEIGHT_BASE = 120423;
    localparam integer LINEAR_WEIGHT_BASE = 199015;

    localparam integer CONV0_BIAS_BASE = 0;
    localparam integer CONV1_BIAS_BASE = 25;
    localparam integer CONV2_BIAS_BASE = 50;
    localparam integer CONV3_BIAS_BASE = 101;
    localparam integer CONV4_BIAS_BASE = 152;
    localparam integer CONV5_BIAS_BASE = 228;
    localparam integer CONV6_BIAS_BASE = 304;
    localparam integer CONV7_BIAS_BASE = 406;
    localparam integer CONV8_BIAS_BASE = 508;
    localparam integer CONV9_BIAS_BASE = 661;
    localparam integer CONV10_BIAS_BASE = 814;
    localparam integer CONV11_BIAS_BASE = 1018;
    localparam integer CONV12_BIAS_BASE = 1222;
    localparam integer CONV13_BIAS_BASE = 1478;
    localparam integer CONV14_BIAS_BASE = 1734;
    localparam integer LINEAR_BIAS_BASE = 2041;

    localparam [5:0] S_IDLE = 6'd0;
    localparam [5:0] S_CONV0 = 6'd1;
    localparam [5:0] S_CONV1 = 6'd2;
    localparam [5:0] S_CONV2 = 6'd3;
    localparam [5:0] S_CONV3 = 6'd4;
    localparam [5:0] S_CONV4 = 6'd5;
    localparam [5:0] S_CONV5 = 6'd6;
    localparam [5:0] S_CONV6 = 6'd7;
    localparam [5:0] S_CONV7 = 6'd8;
    localparam [5:0] S_CONV8 = 6'd9;
    localparam [5:0] S_CONV9 = 6'd10;
    localparam [5:0] S_CONV10 = 6'd11;
    localparam [5:0] S_CONV11 = 6'd12;
    localparam [5:0] S_CONV12 = 6'd13;
    localparam [5:0] S_CONV13 = 6'd14;
    localparam [5:0] S_CONV14 = 6'd15;
    localparam [5:0] S_POOL = 6'd16;
    localparam [5:0] S_LINEAR = 6'd17;
    localparam [5:0] S_ARGMAX = 6'd18;
    localparam [5:0] S_DONE = 6'd19;

    reg [5:0] state;
    reg launch;

    wire conv0_done;
    wire conv0_we;
    wire [16:0] conv0_input_addr;
    wire [9:0] conv0_weight_addr;
    wire [4:0] conv0_bias_addr;
    wire [17:0] conv0_output_addr;
    wire signed [DATA_WIDTH-1:0] conv0_output_data;
    wire signed [DATA_WIDTH-1:0] conv0_weight_q;
    wire signed [DATA_WIDTH-1:0] conv0_bias_q;

    wire conv1_done;
    wire conv1_we;
    wire [17:0] conv1_input_addr;
    wire [7:0] conv1_weight_addr;
    wire [4:0] conv1_bias_addr;
    wire [17:0] conv1_output_addr;
    wire signed [DATA_WIDTH-1:0] conv1_output_data;
    wire signed [DATA_WIDTH-1:0] conv1_weight_q;
    wire signed [DATA_WIDTH-1:0] conv1_bias_q;

    wire conv2_done;
    wire conv2_we;
    wire [17:0] conv2_input_addr;
    wire [10:0] conv2_weight_addr;
    wire [5:0] conv2_bias_addr;
    wire [18:0] conv2_output_addr;
    wire signed [DATA_WIDTH-1:0] conv2_output_data;
    wire signed [DATA_WIDTH-1:0] conv2_weight_q;
    wire signed [DATA_WIDTH-1:0] conv2_bias_q;

    wire conv3_done;
    wire conv3_we;
    wire [18:0] conv3_input_addr;
    wire [8:0] conv3_weight_addr;
    wire [5:0] conv3_bias_addr;
    wire [16:0] conv3_output_addr;
    wire signed [DATA_WIDTH-1:0] conv3_output_data;
    wire signed [DATA_WIDTH-1:0] conv3_weight_q;
    wire signed [DATA_WIDTH-1:0] conv3_bias_q;

    wire conv4_done;
    wire conv4_we;
    wire [16:0] conv4_input_addr;
    wire [11:0] conv4_weight_addr;
    wire [6:0] conv4_bias_addr;
    wire [16:0] conv4_output_addr;
    wire signed [DATA_WIDTH-1:0] conv4_output_data;
    wire signed [DATA_WIDTH-1:0] conv4_weight_q;
    wire signed [DATA_WIDTH-1:0] conv4_bias_q;

    wire conv5_done;
    wire conv5_we;
    wire [16:0] conv5_input_addr;
    wire [9:0] conv5_weight_addr;
    wire [6:0] conv5_bias_addr;
    wire [16:0] conv5_output_addr;
    wire signed [DATA_WIDTH-1:0] conv5_output_data;
    wire signed [DATA_WIDTH-1:0] conv5_weight_q;
    wire signed [DATA_WIDTH-1:0] conv5_bias_q;

    wire conv6_done;
    wire conv6_we;
    wire [16:0] conv6_input_addr;
    wire [12:0] conv6_weight_addr;
    wire [6:0] conv6_bias_addr;
    wire [17:0] conv6_output_addr;
    wire signed [DATA_WIDTH-1:0] conv6_output_data;
    wire signed [DATA_WIDTH-1:0] conv6_weight_q;
    wire signed [DATA_WIDTH-1:0] conv6_bias_q;

    wire conv7_done;
    wire conv7_we;
    wire [17:0] conv7_input_addr;
    wire [9:0] conv7_weight_addr;
    wire [6:0] conv7_bias_addr;
    wire [15:0] conv7_output_addr;
    wire signed [DATA_WIDTH-1:0] conv7_output_data;
    wire signed [DATA_WIDTH-1:0] conv7_weight_q;
    wire signed [DATA_WIDTH-1:0] conv7_bias_q;

    wire conv8_done;
    wire conv8_we;
    wire [15:0] conv8_input_addr;
    wire [13:0] conv8_weight_addr;
    wire [7:0] conv8_bias_addr;
    wire [15:0] conv8_output_addr;
    wire signed [DATA_WIDTH-1:0] conv8_output_data;
    wire signed [DATA_WIDTH-1:0] conv8_weight_q;
    wire signed [DATA_WIDTH-1:0] conv8_bias_q;

    wire conv9_done;
    wire conv9_we;
    wire [15:0] conv9_input_addr;
    wire [10:0] conv9_weight_addr;
    wire [7:0] conv9_bias_addr;
    wire [15:0] conv9_output_addr;
    wire signed [DATA_WIDTH-1:0] conv9_output_data;
    wire signed [DATA_WIDTH-1:0] conv9_weight_q;
    wire signed [DATA_WIDTH-1:0] conv9_bias_q;

    wire conv10_done;
    wire conv10_we;
    wire [15:0] conv10_input_addr;
    wire [14:0] conv10_weight_addr;
    wire [7:0] conv10_bias_addr;
    wire [16:0] conv10_output_addr;
    wire signed [DATA_WIDTH-1:0] conv10_output_data;
    wire signed [DATA_WIDTH-1:0] conv10_weight_q;
    wire signed [DATA_WIDTH-1:0] conv10_bias_q;

    wire conv11_done;
    wire conv11_we;
    wire [16:0] conv11_input_addr;
    wire [10:0] conv11_weight_addr;
    wire [7:0] conv11_bias_addr;
    wire [14:0] conv11_output_addr;
    wire signed [DATA_WIDTH-1:0] conv11_output_data;
    wire signed [DATA_WIDTH-1:0] conv11_weight_q;
    wire signed [DATA_WIDTH-1:0] conv11_bias_q;

    wire conv12_done;
    wire conv12_we;
    wire [14:0] conv12_input_addr;
    wire [15:0] conv12_weight_addr;
    wire [7:0] conv12_bias_addr;
    wire [14:0] conv12_output_addr;
    wire signed [DATA_WIDTH-1:0] conv12_output_data;
    wire signed [DATA_WIDTH-1:0] conv12_weight_q;
    wire signed [DATA_WIDTH-1:0] conv12_bias_q;

    wire conv13_done;
    wire conv13_we;
    wire [14:0] conv13_input_addr;
    wire [11:0] conv13_weight_addr;
    wire [7:0] conv13_bias_addr;
    wire [14:0] conv13_output_addr;
    wire signed [DATA_WIDTH-1:0] conv13_output_data;
    wire signed [DATA_WIDTH-1:0] conv13_weight_q;
    wire signed [DATA_WIDTH-1:0] conv13_bias_q;

    wire conv14_done;
    wire conv14_we;
    wire [14:0] conv14_input_addr;
    wire [16:0] conv14_weight_addr;
    wire [8:0] conv14_bias_addr;
    wire [14:0] conv14_output_addr;
    wire signed [DATA_WIDTH-1:0] conv14_output_data;
    wire signed [DATA_WIDTH-1:0] conv14_weight_q;
    wire signed [DATA_WIDTH-1:0] conv14_bias_q;

    wire pool_done;
    wire pool_we;
    wire [14:0] pool_input_addr;
    wire [8:0] pool_output_addr;
    wire signed [DATA_WIDTH-1:0] pool_output_data;

    wire linear_done;
    wire linear_we;
    wire [8:0] linear_input_addr;
    wire [11:0] linear_weight_addr;
    wire [3:0] linear_bias_addr;
    wire [3:0] linear_output_addr;
    wire signed [DATA_WIDTH-1:0] linear_output_data;
    wire signed [DATA_WIDTH-1:0] linear_weight_q;
    wire signed [DATA_WIDTH-1:0] linear_bias_q;

    wire argmax_done;
    wire [3:0] argmax_rd_addr;
    wire [3:0] argmax_index;
    wire signed [DATA_WIDTH-1:0] argmax_value;

    reg [WEIGHT_ROM_ADDR_WIDTH-1:0] weight_rom_addr;
    reg [BIAS_ROM_ADDR_WIDTH-1:0] bias_rom_addr;
    wire signed [DATA_WIDTH-1:0] weight_rom_q;
    wire signed [DATA_WIDTH-1:0] bias_rom_q;

    assign conv0_weight_q = weight_rom_q;
    assign conv1_weight_q = weight_rom_q;
    assign conv2_weight_q = weight_rom_q;
    assign conv3_weight_q = weight_rom_q;
    assign conv4_weight_q = weight_rom_q;
    assign conv5_weight_q = weight_rom_q;
    assign conv6_weight_q = weight_rom_q;
    assign conv7_weight_q = weight_rom_q;
    assign conv8_weight_q = weight_rom_q;
    assign conv9_weight_q = weight_rom_q;
    assign conv10_weight_q = weight_rom_q;
    assign conv11_weight_q = weight_rom_q;
    assign conv12_weight_q = weight_rom_q;
    assign conv13_weight_q = weight_rom_q;
    assign conv14_weight_q = weight_rom_q;
    assign linear_weight_q = weight_rom_q;

    assign conv0_bias_q = bias_rom_q;
    assign conv1_bias_q = bias_rom_q;
    assign conv2_bias_q = bias_rom_q;
    assign conv3_bias_q = bias_rom_q;
    assign conv4_bias_q = bias_rom_q;
    assign conv5_bias_q = bias_rom_q;
    assign conv6_bias_q = bias_rom_q;
    assign conv7_bias_q = bias_rom_q;
    assign conv8_bias_q = bias_rom_q;
    assign conv9_bias_q = bias_rom_q;
    assign conv10_bias_q = bias_rom_q;
    assign conv11_bias_q = bias_rom_q;
    assign conv12_bias_q = bias_rom_q;
    assign conv13_bias_q = bias_rom_q;
    assign conv14_bias_q = bias_rom_q;
    assign linear_bias_q = bias_rom_q;

    reg [ADDR_WIDTH-1:0] act_a_addr;
    reg [ADDR_WIDTH-1:0] act_b_addr;
    wire [ADDR_WIDTH-1:0] input_mem_addr;
    reg act_a_we;
    reg act_b_we;
    reg signed [DATA_WIDTH-1:0] act_a_din;
    reg signed [DATA_WIDTH-1:0] act_b_din;
    wire signed [DATA_WIDTH-1:0] act_a_q;
    wire signed [DATA_WIDTH-1:0] act_b_q;
    wire signed [DATA_WIDTH-1:0] input_q;

    assign input_mem_addr = input_we ? input_write_addr : conv0_input_addr;

    sync_ram_1p #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(INPUT_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .RAM_STYLE("ultra")
    ) u_input_mem (
        .clk(clk), .we(input_we), .addr(input_mem_addr),
        .din(input_write_data), .dout(input_q)
    );

    sync_ram_1p #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(ACT_DEPTH), .ADDR_WIDTH(ADDR_WIDTH), .RAM_STYLE("ultra"))
    u_act_a (.clk(clk), .we(act_a_we), .addr(act_a_addr), .din(act_a_din), .dout(act_a_q));

    sync_ram_1p #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(ACT_DEPTH), .ADDR_WIDTH(ADDR_WIDTH), .RAM_STYLE("ultra"))
    u_act_b (.clk(clk), .we(act_b_we), .addr(act_b_addr), .din(act_b_din), .dout(act_b_q));

    sync_ram_1p #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(WEIGHT_ROM_DEPTH), .ADDR_WIDTH(WEIGHT_ROM_ADDR_WIDTH),
        .RAM_STYLE("block"),
        .INIT_FILE("C:/Users/NguyenHuy/Downloads/all_weights_q6_9.mem"))
    u_weight_rom (.clk(clk), .we(1'b0), .addr(weight_rom_addr),
        .din({DATA_WIDTH{1'b0}}), .dout(weight_rom_q));

    sync_ram_1p #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(BIAS_ROM_DEPTH), .ADDR_WIDTH(BIAS_ROM_ADDR_WIDTH),
        .RAM_STYLE("block"),
        .INIT_FILE("C:/Users/NguyenHuy/Downloads/all_bias_q6_9.mem"))
    u_bias_rom (.clk(clk), .we(1'b0), .addr(bias_rom_addr),
        .din({DATA_WIDTH{1'b0}}), .dout(bias_rom_q));

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(3), .OUT_C(25), .IN_H(160), .IN_W(160),
        .K(3), .STRIDE(2), .PAD(1), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv0 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV0), .done(conv0_done),
        .input_addr(conv0_input_addr), .input_data(input_q),
        .weight_addr(conv0_weight_addr), .weight_data(conv0_weight_q),
        .bias_addr(conv0_bias_addr), .bias_data(conv0_bias_q),
        .output_we(conv0_we), .output_addr(conv0_output_addr), .output_data(conv0_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(25), .OUT_C(25), .IN_H(80), .IN_W(80),
        .K(3), .STRIDE(1), .PAD(1), .GROUPS(25),
        .RELU_OUTPUT(1)
    ) u_conv1 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV1), .done(conv1_done),
        .input_addr(conv1_input_addr), .input_data(act_a_q),
        .weight_addr(conv1_weight_addr), .weight_data(conv1_weight_q),
        .bias_addr(conv1_bias_addr), .bias_data(conv1_bias_q),
        .output_we(conv1_we), .output_addr(conv1_output_addr), .output_data(conv1_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(25), .OUT_C(51), .IN_H(80), .IN_W(80),
        .K(1), .STRIDE(1), .PAD(0), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv2 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV2), .done(conv2_done),
        .input_addr(conv2_input_addr), .input_data(act_b_q),
        .weight_addr(conv2_weight_addr), .weight_data(conv2_weight_q),
        .bias_addr(conv2_bias_addr), .bias_data(conv2_bias_q),
        .output_we(conv2_we), .output_addr(conv2_output_addr), .output_data(conv2_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(51), .OUT_C(51), .IN_H(80), .IN_W(80),
        .K(3), .STRIDE(2), .PAD(1), .GROUPS(51),
        .RELU_OUTPUT(1)
    ) u_conv3 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV3), .done(conv3_done),
        .input_addr(conv3_input_addr), .input_data(act_a_q),
        .weight_addr(conv3_weight_addr), .weight_data(conv3_weight_q),
        .bias_addr(conv3_bias_addr), .bias_data(conv3_bias_q),
        .output_we(conv3_we), .output_addr(conv3_output_addr), .output_data(conv3_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(51), .OUT_C(76), .IN_H(40), .IN_W(40),
        .K(1), .STRIDE(1), .PAD(0), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv4 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV4), .done(conv4_done),
        .input_addr(conv4_input_addr), .input_data(act_b_q),
        .weight_addr(conv4_weight_addr), .weight_data(conv4_weight_q),
        .bias_addr(conv4_bias_addr), .bias_data(conv4_bias_q),
        .output_we(conv4_we), .output_addr(conv4_output_addr), .output_data(conv4_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(76), .OUT_C(76), .IN_H(40), .IN_W(40),
        .K(3), .STRIDE(1), .PAD(1), .GROUPS(76),
        .RELU_OUTPUT(1)
    ) u_conv5 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV5), .done(conv5_done),
        .input_addr(conv5_input_addr), .input_data(act_a_q),
        .weight_addr(conv5_weight_addr), .weight_data(conv5_weight_q),
        .bias_addr(conv5_bias_addr), .bias_data(conv5_bias_q),
        .output_we(conv5_we), .output_addr(conv5_output_addr), .output_data(conv5_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(76), .OUT_C(102), .IN_H(40), .IN_W(40),
        .K(1), .STRIDE(1), .PAD(0), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv6 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV6), .done(conv6_done),
        .input_addr(conv6_input_addr), .input_data(act_b_q),
        .weight_addr(conv6_weight_addr), .weight_data(conv6_weight_q),
        .bias_addr(conv6_bias_addr), .bias_data(conv6_bias_q),
        .output_we(conv6_we), .output_addr(conv6_output_addr), .output_data(conv6_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(102), .OUT_C(102), .IN_H(40), .IN_W(40),
        .K(3), .STRIDE(2), .PAD(1), .GROUPS(102),
        .RELU_OUTPUT(1)
    ) u_conv7 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV7), .done(conv7_done),
        .input_addr(conv7_input_addr), .input_data(act_a_q),
        .weight_addr(conv7_weight_addr), .weight_data(conv7_weight_q),
        .bias_addr(conv7_bias_addr), .bias_data(conv7_bias_q),
        .output_we(conv7_we), .output_addr(conv7_output_addr), .output_data(conv7_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(102), .OUT_C(153), .IN_H(20), .IN_W(20),
        .K(1), .STRIDE(1), .PAD(0), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv8 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV8), .done(conv8_done),
        .input_addr(conv8_input_addr), .input_data(act_b_q),
        .weight_addr(conv8_weight_addr), .weight_data(conv8_weight_q),
        .bias_addr(conv8_bias_addr), .bias_data(conv8_bias_q),
        .output_we(conv8_we), .output_addr(conv8_output_addr), .output_data(conv8_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(153), .OUT_C(153), .IN_H(20), .IN_W(20),
        .K(3), .STRIDE(1), .PAD(1), .GROUPS(153),
        .RELU_OUTPUT(1)
    ) u_conv9 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV9), .done(conv9_done),
        .input_addr(conv9_input_addr), .input_data(act_a_q),
        .weight_addr(conv9_weight_addr), .weight_data(conv9_weight_q),
        .bias_addr(conv9_bias_addr), .bias_data(conv9_bias_q),
        .output_we(conv9_we), .output_addr(conv9_output_addr), .output_data(conv9_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(153), .OUT_C(204), .IN_H(20), .IN_W(20),
        .K(1), .STRIDE(1), .PAD(0), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv10 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV10), .done(conv10_done),
        .input_addr(conv10_input_addr), .input_data(act_b_q),
        .weight_addr(conv10_weight_addr), .weight_data(conv10_weight_q),
        .bias_addr(conv10_bias_addr), .bias_data(conv10_bias_q),
        .output_we(conv10_we), .output_addr(conv10_output_addr), .output_data(conv10_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(204), .OUT_C(204), .IN_H(20), .IN_W(20),
        .K(3), .STRIDE(2), .PAD(1), .GROUPS(204),
        .RELU_OUTPUT(1)
    ) u_conv11 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV11), .done(conv11_done),
        .input_addr(conv11_input_addr), .input_data(act_a_q),
        .weight_addr(conv11_weight_addr), .weight_data(conv11_weight_q),
        .bias_addr(conv11_bias_addr), .bias_data(conv11_bias_q),
        .output_we(conv11_we), .output_addr(conv11_output_addr), .output_data(conv11_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(204), .OUT_C(256), .IN_H(10), .IN_W(10),
        .K(1), .STRIDE(1), .PAD(0), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv12 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV12), .done(conv12_done),
        .input_addr(conv12_input_addr), .input_data(act_b_q),
        .weight_addr(conv12_weight_addr), .weight_data(conv12_weight_q),
        .bias_addr(conv12_bias_addr), .bias_data(conv12_bias_q),
        .output_we(conv12_we), .output_addr(conv12_output_addr), .output_data(conv12_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(256), .OUT_C(256), .IN_H(10), .IN_W(10),
        .K(3), .STRIDE(1), .PAD(1), .GROUPS(256),
        .RELU_OUTPUT(1)
    ) u_conv13 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV13), .done(conv13_done),
        .input_addr(conv13_input_addr), .input_data(act_a_q),
        .weight_addr(conv13_weight_addr), .weight_data(conv13_weight_q),
        .bias_addr(conv13_bias_addr), .bias_data(conv13_bias_q),
        .output_we(conv13_we), .output_addr(conv13_output_addr), .output_data(conv13_output_data)
    );

    conv2d_sequential #(
        .DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_C(256), .OUT_C(307), .IN_H(10), .IN_W(10),
        .K(1), .STRIDE(1), .PAD(0), .GROUPS(1),
        .RELU_OUTPUT(1)
    ) u_conv14 (
        .clk(clk), .rst(rst), .start(launch && state == S_CONV14), .done(conv14_done),
        .input_addr(conv14_input_addr), .input_data(act_b_q),
        .weight_addr(conv14_weight_addr), .weight_data(conv14_weight_q),
        .bias_addr(conv14_bias_addr), .bias_data(conv14_bias_q),
        .output_we(conv14_we), .output_addr(conv14_output_addr), .output_data(conv14_output_data)
    );

    avgpool_1x1 #(.DATA_WIDTH(DATA_WIDTH), .CHANNELS(307), .IN_H(10), .IN_W(10))
    u_pool (
        .clk(clk), .rst(rst), .start(launch && state == S_POOL), .done(pool_done),
        .input_addr(pool_input_addr), .input_data(act_a_q),
        .output_we(pool_we), .output_addr(pool_output_addr), .output_data(pool_output_data)
    );

    linear_sequential #(.DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH),
        .IN_FEATURES(307), .OUT_FEATURES(10))
    u_linear (
        .clk(clk), .rst(rst), .start(launch && state == S_LINEAR), .done(linear_done),
        .input_addr(linear_input_addr), .input_data(act_b_q),
        .weight_addr(linear_weight_addr), .weight_data(linear_weight_q),
        .bias_addr(linear_bias_addr), .bias_data(linear_bias_q),
        .output_we(linear_we), .output_addr(linear_output_addr), .output_data(linear_output_data)
    );

    argmax #(.DATA_WIDTH(DATA_WIDTH), .LENGTH(10))
    u_argmax (
        .clk(clk), .rst(rst), .start(launch && state == S_ARGMAX), .done(argmax_done),
        .rd_addr(argmax_rd_addr), .rd_data(act_a_q),
        .max_index(argmax_index), .max_value(argmax_value)
    );

    always @(*) begin
        case (state)
            S_CONV0: begin
                weight_rom_addr = CONV0_WEIGHT_BASE + conv0_weight_addr;
                bias_rom_addr = CONV0_BIAS_BASE + conv0_bias_addr;
            end
            S_CONV1: begin
                weight_rom_addr = CONV1_WEIGHT_BASE + conv1_weight_addr;
                bias_rom_addr = CONV1_BIAS_BASE + conv1_bias_addr;
            end
            S_CONV2: begin
                weight_rom_addr = CONV2_WEIGHT_BASE + conv2_weight_addr;
                bias_rom_addr = CONV2_BIAS_BASE + conv2_bias_addr;
            end
            S_CONV3: begin
                weight_rom_addr = CONV3_WEIGHT_BASE + conv3_weight_addr;
                bias_rom_addr = CONV3_BIAS_BASE + conv3_bias_addr;
            end
            S_CONV4: begin
                weight_rom_addr = CONV4_WEIGHT_BASE + conv4_weight_addr;
                bias_rom_addr = CONV4_BIAS_BASE + conv4_bias_addr;
            end
            S_CONV5: begin
                weight_rom_addr = CONV5_WEIGHT_BASE + conv5_weight_addr;
                bias_rom_addr = CONV5_BIAS_BASE + conv5_bias_addr;
            end
            S_CONV6: begin
                weight_rom_addr = CONV6_WEIGHT_BASE + conv6_weight_addr;
                bias_rom_addr = CONV6_BIAS_BASE + conv6_bias_addr;
            end
            S_CONV7: begin
                weight_rom_addr = CONV7_WEIGHT_BASE + conv7_weight_addr;
                bias_rom_addr = CONV7_BIAS_BASE + conv7_bias_addr;
            end
            S_CONV8: begin
                weight_rom_addr = CONV8_WEIGHT_BASE + conv8_weight_addr;
                bias_rom_addr = CONV8_BIAS_BASE + conv8_bias_addr;
            end
            S_CONV9: begin
                weight_rom_addr = CONV9_WEIGHT_BASE + conv9_weight_addr;
                bias_rom_addr = CONV9_BIAS_BASE + conv9_bias_addr;
            end
            S_CONV10: begin
                weight_rom_addr = CONV10_WEIGHT_BASE + conv10_weight_addr;
                bias_rom_addr = CONV10_BIAS_BASE + conv10_bias_addr;
            end
            S_CONV11: begin
                weight_rom_addr = CONV11_WEIGHT_BASE + conv11_weight_addr;
                bias_rom_addr = CONV11_BIAS_BASE + conv11_bias_addr;
            end
            S_CONV12: begin
                weight_rom_addr = CONV12_WEIGHT_BASE + conv12_weight_addr;
                bias_rom_addr = CONV12_BIAS_BASE + conv12_bias_addr;
            end
            S_CONV13: begin
                weight_rom_addr = CONV13_WEIGHT_BASE + conv13_weight_addr;
                bias_rom_addr = CONV13_BIAS_BASE + conv13_bias_addr;
            end
            S_CONV14: begin
                weight_rom_addr = CONV14_WEIGHT_BASE + conv14_weight_addr;
                bias_rom_addr = CONV14_BIAS_BASE + conv14_bias_addr;
            end
            S_LINEAR: begin
                weight_rom_addr = LINEAR_WEIGHT_BASE + linear_weight_addr;
                bias_rom_addr = LINEAR_BIAS_BASE + linear_bias_addr;
            end
            default: begin end
        endcase
    end

    always @(*) begin
        act_a_addr = {ADDR_WIDTH{1'b0}};
        act_b_addr = {ADDR_WIDTH{1'b0}};
        act_a_we = 1'b0;
        act_b_we = 1'b0;
        act_a_din = {DATA_WIDTH{1'b0}};
        act_b_din = {DATA_WIDTH{1'b0}};
        case (state)
            S_CONV0: begin
                act_a_addr = conv0_output_addr;
                act_a_we = conv0_we;
                act_a_din = conv0_output_data;
            end
            S_CONV1: begin
                act_a_addr = conv1_input_addr;
                act_b_addr = conv1_output_addr;
                act_b_we = conv1_we;
                act_b_din = conv1_output_data;
            end
            S_CONV2: begin
                act_b_addr = conv2_input_addr;
                act_a_addr = conv2_output_addr;
                act_a_we = conv2_we;
                act_a_din = conv2_output_data;
            end
            S_CONV3: begin
                act_a_addr = conv3_input_addr;
                act_b_addr = conv3_output_addr;
                act_b_we = conv3_we;
                act_b_din = conv3_output_data;
            end
            S_CONV4: begin
                act_b_addr = conv4_input_addr;
                act_a_addr = conv4_output_addr;
                act_a_we = conv4_we;
                act_a_din = conv4_output_data;
            end
            S_CONV5: begin
                act_a_addr = conv5_input_addr;
                act_b_addr = conv5_output_addr;
                act_b_we = conv5_we;
                act_b_din = conv5_output_data;
            end
            S_CONV6: begin
                act_b_addr = conv6_input_addr;
                act_a_addr = conv6_output_addr;
                act_a_we = conv6_we;
                act_a_din = conv6_output_data;
            end
            S_CONV7: begin
                act_a_addr = conv7_input_addr;
                act_b_addr = conv7_output_addr;
                act_b_we = conv7_we;
                act_b_din = conv7_output_data;
            end
            S_CONV8: begin
                act_b_addr = conv8_input_addr;
                act_a_addr = conv8_output_addr;
                act_a_we = conv8_we;
                act_a_din = conv8_output_data;
            end
            S_CONV9: begin
                act_a_addr = conv9_input_addr;
                act_b_addr = conv9_output_addr;
                act_b_we = conv9_we;
                act_b_din = conv9_output_data;
            end
            S_CONV10: begin
                act_b_addr = conv10_input_addr;
                act_a_addr = conv10_output_addr;
                act_a_we = conv10_we;
                act_a_din = conv10_output_data;
            end
            S_CONV11: begin
                act_a_addr = conv11_input_addr;
                act_b_addr = conv11_output_addr;
                act_b_we = conv11_we;
                act_b_din = conv11_output_data;
            end
            S_CONV12: begin
                act_b_addr = conv12_input_addr;
                act_a_addr = conv12_output_addr;
                act_a_we = conv12_we;
                act_a_din = conv12_output_data;
            end
            S_CONV13: begin
                act_a_addr = conv13_input_addr;
                act_b_addr = conv13_output_addr;
                act_b_we = conv13_we;
                act_b_din = conv13_output_data;
            end
            S_CONV14: begin
                act_b_addr = conv14_input_addr;
                act_a_addr = conv14_output_addr;
                act_a_we = conv14_we;
                act_a_din = conv14_output_data;
            end
            S_POOL: begin
                act_a_addr = pool_input_addr;
                act_b_addr = pool_output_addr;
                act_b_we = pool_we;
                act_b_din = pool_output_data;
            end
            S_LINEAR: begin
                act_b_addr = linear_input_addr;
                act_a_addr = linear_output_addr;
                act_a_we = linear_we;
                act_a_din = linear_output_data;
            end
            S_ARGMAX: begin
                act_a_addr = argmax_rd_addr;
            end
            default: begin end
        endcase
    end

    reg op_done;

    always @(*) begin
        op_done = 1'b0;
        case (state)
            S_CONV0: op_done = conv0_done;
            S_CONV1: op_done = conv1_done;
            S_CONV2: op_done = conv2_done;
            S_CONV3: op_done = conv3_done;
            S_CONV4: op_done = conv4_done;
            S_CONV5: op_done = conv5_done;
            S_CONV6: op_done = conv6_done;
            S_CONV7: op_done = conv7_done;
            S_CONV8: op_done = conv8_done;
            S_CONV9: op_done = conv9_done;
            S_CONV10: op_done = conv10_done;
            S_CONV11: op_done = conv11_done;
            S_CONV12: op_done = conv12_done;
            S_CONV13: op_done = conv13_done;
            S_CONV14: op_done = conv14_done;
            S_POOL: op_done = pool_done;
            S_LINEAR: op_done = linear_done;
            S_ARGMAX: op_done = argmax_done;
            default: op_done = 1'b0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            launch <= 1'b0;
            done <= 1'b0;
            predicted_class <= 4'd0;
        end else begin
            launch <= 1'b0;
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (start) begin
                        state <= S_CONV0;
                        launch <= 1'b1;
                    end
                end
                S_CONV0: begin
                    if (op_done) begin
                        state <= S_CONV1;
                        launch <= 1'b1;
                    end
                end
                S_CONV1: begin
                    if (op_done) begin
                        state <= S_CONV2;
                        launch <= 1'b1;
                    end
                end
                S_CONV2: begin
                    if (op_done) begin
                        state <= S_CONV3;
                        launch <= 1'b1;
                    end
                end
                S_CONV3: begin
                    if (op_done) begin
                        state <= S_CONV4;
                        launch <= 1'b1;
                    end
                end
                S_CONV4: begin
                    if (op_done) begin
                        state <= S_CONV5;
                        launch <= 1'b1;
                    end
                end
                S_CONV5: begin
                    if (op_done) begin
                        state <= S_CONV6;
                        launch <= 1'b1;
                    end
                end
                S_CONV6: begin
                    if (op_done) begin
                        state <= S_CONV7;
                        launch <= 1'b1;
                    end
                end
                S_CONV7: begin
                    if (op_done) begin
                        state <= S_CONV8;
                        launch <= 1'b1;
                    end
                end
                S_CONV8: begin
                    if (op_done) begin
                        state <= S_CONV9;
                        launch <= 1'b1;
                    end
                end
                S_CONV9: begin
                    if (op_done) begin
                        state <= S_CONV10;
                        launch <= 1'b1;
                    end
                end
                S_CONV10: begin
                    if (op_done) begin
                        state <= S_CONV11;
                        launch <= 1'b1;
                    end
                end
                S_CONV11: begin
                    if (op_done) begin
                        state <= S_CONV12;
                        launch <= 1'b1;
                    end
                end
                S_CONV12: begin
                    if (op_done) begin
                        state <= S_CONV13;
                        launch <= 1'b1;
                    end
                end
                S_CONV13: begin
                    if (op_done) begin
                        state <= S_CONV14;
                        launch <= 1'b1;
                    end
                end
                S_CONV14: begin
                    if (op_done) begin
                        state <= S_POOL;
                        launch <= 1'b1;
                    end
                end
                S_POOL: begin
                    if (op_done) begin
                        state <= S_LINEAR;
                        launch <= 1'b1;
                    end
                end
                S_LINEAR: begin
                    if (op_done) begin
                        state <= S_ARGMAX;
                        launch <= 1'b1;
                    end
                end
                S_ARGMAX: begin
                    if (op_done) begin
                        predicted_class <= argmax_index;
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

