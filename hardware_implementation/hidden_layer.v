module hidden_layer #(
    parameter IN = 784,
    parameter OUT = 256,
  ) (
    input [IN-1:0] weights [0:OUT-1],
    input [IN-1:0] x,
    output [OUT-1:0] weights_row
  );

  wire [IN-1:0] mult_out [0:OUT-1];

  genvar i;
  generate
    for (i = 0; i < OUT; i = i + 1) begin : neuron_multiplication
      mult_out[i] = ~(weights[i] ^ x)
    end
  endgenerate


  // TODO: make popcount and finish neuron addition
  genvar j;
  generate
    for (j = 0; j < OUT; j = j + 1) begin : neuron_addition

    end
  endgenerate

endmodule