`timescale 1ns / 1ps
module neuron #(
    parameter IN = 784              //Input width default is 784 bits
) (
    //each weight will multiply each input in the neuron nxm multiplies mxo which outputs nxo
    input      [IN-1:0]      weight,
    input      [IN-1:0]      x,
    output reg signed [31:0] count  //output is "integer" which is 32 bits
);
    wire [IN-1:0] mult;             //variable for wiring the multiplied value
    assign mult = ~(weight ^ x);    //XNOR operation for "multiplicaton"

    integer i;
    reg [31:0] popcount_reg;        //popcount that takes the number of 1's in the multiplied value
    
    always @(*) begin
        popcount_reg = 0;
        for (i = 0; i < IN; i = i + 1) begin
            if (mult[i] === 1'b1)
                popcount_reg = popcount_reg + 1;
        end
    end
    //extends the popcount by 1 bit to avoid overflow
    //converts to signed type and left shits by one and subtracts by the number of inputs
    always @(*) begin
        count = $signed({1'b0, popcount_reg} << 1) - $signed(IN);
    end
endmodule