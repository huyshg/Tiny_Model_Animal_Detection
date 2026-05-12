`timescale 1ns / 1ps

module animalnet_axi_lite (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,

    input wire [4:0] S_AXI_AWADDR, 
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,

    input wire [31:0] S_AXI_WDATA,
    input wire [3:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,

    output wire [1:0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,

    input wire [4:0] S_AXI_ARADDR,
    input wire [2:0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,

    output reg [31:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY
);
    localparam [4:0] CONTROL = 5'h00;
    localparam [4:0] STATUS = 5'h04;
    localparam [4:0] INPUT_ADDR = 5'h08;
    localparam [4:0] INPUT_DATA = 5'h0c;
    localparam [4:0] INPUT_WRITE = 5'h10;
    localparam [4:0] PREDICTED_CLASS = 5'h14;
    localparam integer INPUT_SIZE = 76800;

    reg [31:0] input_addr;
    reg [15:0] input_data;
    reg input_loaded;
    reg reset_core;
    reg busy;
    reg done;
    reg start;
    reg [3:0] predicted_class;

    wire write = S_AXI_AWVALID && S_AXI_WVALID && S_AXI_AWREADY;
    wire read = S_AXI_ARVALID && S_AXI_ARREADY;
    wire input_ready = S_AXI_ARESETN && !reset_core && !busy && (input_addr < INPUT_SIZE);
    wire input_we = write && (S_AXI_AWADDR == INPUT_WRITE) && S_AXI_WDATA[0] && input_ready;
    wire core_done;
    wire [3:0] core_class;

    assign S_AXI_AWREADY = S_AXI_ARESETN && S_AXI_AWVALID && S_AXI_WVALID && !S_AXI_BVALID;
    assign S_AXI_WREADY = S_AXI_AWREADY;
    assign S_AXI_ARREADY = S_AXI_ARESETN && !S_AXI_RVALID;
    assign S_AXI_BRESP = 2'b00;
    assign S_AXI_RRESP = 2'b00;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <=0;
            S_AXI_RVALID <= 0;
            S_AXI_RDATA <= 32'd0;
            input_addr <= 32'd0;
            input_data <= 16'd0;
            input_loaded <= 0;
            reset_core <= 0;
            busy <= 0;
            done <= 0;
            start <= 0;
            predicted_class <= 0;
        end else begin
            start <= 0;
            if (write) S_AXI_BVALID <= 1;
            else if (S_AXI_BVALID && S_AXI_BREADY) S_AXI_BVALID <= 1'b0;
            if (read) begin
                S_AXI_RVALID <= 1'b1;
                case (S_AXI_ARADDR)
                    CONTROL: S_AXI_RDATA <= {reset_core, 1'b0};
                    STATUS: S_AXI_RDATA <= {busy, done};
                    INPUT_ADDR: S_AXI_RDATA <= input_addr;
                    INPUT_DATA: S_AXI_RDATA <= input_data;
                    PREDICTED_CLASS: S_AXI_RDATA <= predicted_class;
                    default: S_AXI_RDATA <= 32'd0;
                endcase
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
            if (core_done) begin
                done <= 1;
                busy <= 0;
                predicted_class <= core_class;
            end
            if (input_we) begin
                if (input_addr == INPUT_SIZE - 1) input_loaded <= 1;
            end
            if (reset_core) begin
                busy <= 0;
                done <= 0;
                input_loaded <= 0;
                predicted_class <= 0;
            end
            if (write) begin
                case (S_AXI_AWADDR)
                    CONTROL: begin
                        reset_core <= S_AXI_WDATA[1];
                        if (S_AXI_WDATA[0] && input_loaded && !busy && !reset_core && !S_AXI_WDATA[1]) begin
                            start <= 1;
                            busy <= 1;
                            done <= 0;
                        end
                    end
                    INPUT_ADDR: input_addr <= S_AXI_WDATA;
                    INPUT_DATA: input_data <= S_AXI_WDATA[15:0];
                    default: ;
                endcase
            end
        end
    end

    animalnet_top u_animalnet_top (
        .clk(S_AXI_ACLK),
        .rst(!S_AXI_ARESETN || reset_core),
        .start(start),
        .input_we(input_we),
        .input_write_addr(input_addr[18:0]),
        .input_write_data(input_data),
        .done(core_done),
        .predicted_class(core_class)
    );
endmodule
