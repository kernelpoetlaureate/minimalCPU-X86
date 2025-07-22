// Verilog module for the x86 Register File (Bit-Level Implementation)

module RegisterFile(
    input wire clk,
    input wire reset,
    input wire [1:0] reg_select, // Selects one of the 4 general-purpose registers
    input wire write_enable,    // Enables writing to the selected register
    input wire [15:0] data_in,  // Data to write to the register
    output wire [15:0] data_out // Data read from the selected register
);

    // ------------------------
    // PER-REGISTER WRITE ENABLES (one-hot)
    // ------------------------
    wire [3:0] reg_write_enable;
    Decoder2to4 dec_write (
        .sel(reg_select),
        .decoded(reg_write_enable)
    );

    wire ax_load = write_enable & reg_write_enable[0];
    wire bx_load = write_enable & reg_write_enable[1];
    wire cx_load = write_enable & reg_write_enable[2];
    wire dx_load = write_enable & reg_write_enable[3];

    // ------------------------
    // 16-BIT REGISTERS (BIT-LEVEL)
    // ------------------------
    wire [15:0] AX_out, BX_out, CX_out, DX_out;

    Reg16_BitLevel ax_reg (
        .clk(clk),
        .reset(reset),
        .load(ax_load),
        .din(data_in),
        .dout(AX_out)
    );

    Reg16_BitLevel bx_reg (
        .clk(clk),
        .reset(reset),
        .load(bx_load),
        .din(data_in),
        .dout(BX_out)
    );

    Reg16_BitLevel cx_reg (
        .clk(clk),
        .reset(reset),
        .load(cx_load),
        .din(data_in),
        .dout(CX_out)
    );

    Reg16_BitLevel dx_reg (
        .clk(clk),
        .reset(reset),
        .load(dx_load),
        .din(data_in),
        .dout(DX_out)
    );

    // ------------------------
    // READ MUX: SELECT OUTPUT
    // ------------------------
    Mux4to1_16bit read_mux (
        .sel(reg_select),
        .in0(AX_out),
        .in1(BX_out),
        .in2(CX_out),
        .in3(DX_out),
        .out(data_out)
    );

endmodule

// ------------------------
// 2-to-4 Decoder (Bit-Level)
// ------------------------
module Decoder2to4(
    input wire [1:0] sel,
    output wire [3:0] decoded // one-hot: which reg is selected
);
    assign decoded[0] = ~sel[1] & ~sel[0]; // 00
    assign decoded[1] = ~sel[1] &  sel[0]; // 01
    assign decoded[2] =  sel[1] & ~sel[0]; // 10
    assign decoded[3] =  sel[1] &  sel[0]; // 11
endmodule

// ------------------------
// 16-Bit Register (Bit-Level)
// ------------------------
module Reg16_BitLevel(
    input wire clk,
    input wire reset,
    input wire load,
    input wire [15:0] din,
    output reg [15:0] dout
);

    wire [15:0] d;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : mux_and_ff
            // 2:1 Mux: choose between new data or hold
            assign d[i] = load ? din[i] : dout[i];

            // D Flip-Flop
            always @(posedge clk or posedge reset) begin
                if (reset)
                    dout[i] <= 1'b0;
                else
                    dout[i] <= d[i];
            end
        end
    endgenerate

endmodule

// ------------------------
// 4-to-1 Multiplexer (16-bit wide, structural)
// ------------------------
module Mux4to1_16bit(
    input wire [1:0] sel,
    input wire [15:0] in0,
    input wire [15:0] in1,
    input wire [15:0] in2,
    input wire [15:0] in3,
    output wire [15:0] out
);
    wire [3:0] decoded;
    Decoder2to4 dec(.sel(sel), .decoded(decoded));

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : mux_bits
            assign out[i] =
                (decoded[0] & in0[i]) |
                (decoded[1] & in1[i]) |
                (decoded[2] & in2[i]) |
                (decoded[3] & in3[i]);
        end
    endgenerate
endmodule
