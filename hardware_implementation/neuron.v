module neuron #(
    parameter IN = 784
) (
    input [IN-1:0] weight,
    input [IN-1:0] x,
    output reg signed [31:0] count
);
  wire [IN-1:0] mult;


  assign mult = ~(weight ^ x);


  integer popcount;
  integer i;

  always @(*) begin
    popcount = 0;
    for (i = 0; i < IN; i = i + 1) begin
      if (mult[i]) begin
        popcount = popcount + 1;
      end
    end
  end

  always @(*) begin
    count = (popcount * 2) - IN;
  end

endmodule

