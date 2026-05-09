`timescale 1ns / 1ps
module neuron #(
    parameter IN = 784
) (
    input      [IN-1:0]      weight,
    input      [IN-1:0]      x,
    output reg signed [31:0] count
);
    wire [IN-1:0] mult;
    assign mult = ~(weight ^ x);

    integer i;
    reg [31:0] popcount_reg;

    always @(*) begin
        popcount_reg = 0;
        for (i = 0; i < IN; i = i + 1) begin
            if (mult[i] === 1'b1)
                popcount_reg = popcount_reg + 1;
        end
    end

    always @(*) begin
        count = $signed({1'b0, popcount_reg} << 1) - $signed(IN);
    end
endmodule