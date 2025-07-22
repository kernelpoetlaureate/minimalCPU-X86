// Verilog module for the x86 Register File

module RegisterFile(
    input wire clk,
    input wire reset,
    input wire [1:0] reg_select, // Selects one of the 4 general-purpose registers
    input wire write_enable,    // Enables writing to the selected register
    input wire [15:0] data_in,  // Data to write to the register
    output reg [15:0] data_out  // Data read from the selected register
);

    // General Purpose Registers (16-bit each)
    reg [15:0] AX, BX, CX, DX;

    // Instruction Pointer (IP)
    reg [15:0] IP;

    // Flags Register (FLAGS)
    reg ZF, CF; // Zero Flag and Carry Flag

    // Register Write Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            AX <= 16'b0;
            BX <= 16'b0;
            CX <= 16'b0;
            DX <= 16'b0;
            IP <= 16'b0;
            ZF <= 1'b0;
            CF <= 1'b0;
        end else if (write_enable) begin
            case (reg_select)
                2'b00: AX <= data_in;
                2'b01: BX <= data_in;
                2'b10: CX <= data_in;
                2'b11: DX <= data_in;
            endcase
        end
    end

    // Register Read Logic
    always @(*) begin
        case (reg_select)
            2'b00: data_out = AX;
            2'b01: data_out = BX;
            2'b10: data_out = CX;
            2'b11: data_out = DX;
            default: data_out = 16'b0;
        endcase
    end

endmodule
