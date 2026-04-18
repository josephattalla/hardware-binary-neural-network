`include "neuron.v"
`include "activation.v"

module top (
    input  [783:0] image,
    output [  3:0] classification
);

  // layer 1 weights
  wire [783:0] w1[0:255];
  initial begin
    $readmemb("../models/weights_layer1.txt", weights);
  end

  // layer 2 weights
  wire [255:0] w2[0:9];
  initial begin
    $readmemb("../models/weights_layer1.txt", weights);
  end


  // layer 1 neurons
  integer [255:0] layer_1_neuron_outputs;
  genvar i;
  generate
    for (i = 0; i < 256; i = i + 1) begin : g_layer_1_neurons
      neuron #(N(
          784
      )) layer_1_neurons (
          .weight(w1[i]),
          .x(image),
          .out(layer_1_neuron_outputs)
      );
    end
  endgenerate

  // layer 1 activation
  wire [255:0] layer_1_out;
  generate
    for (i = 0; i < 256; i = i + 1) begin : g_layer_1_activation
      neuron layer_1_activation (
          .neuron(layer_1_neuron_outputs[i]),
          .out(layer_1_out[i])
      );
    end
  endgenerate

  // layer 2 neurons
  integer [9:0] layer_2_neuron_outputs;
  generate
    for (i = 0; i < 10; i = i + 1) begin : g_layer_2
      neuron #(N(
          256
      )) layer_2 (
          .weight(w2[i]),
          .x(layer_1_out[i]),
          .out(layer_2_neuron_outputs)
      );
    end
  endgenerate

  // get classification
  integer j;
  integer max_value;

  always @(*) begin
    max_value = layer_2_neuron_outputs[0];
    max_index = 0;

    for (j = 1; j < 10; j = j + 1) begin
      if (layer_2_neuron_outputs[j] > max_value) begin
        max_value = layer_2_neuron_outputs[j];
        max_index = j;
      end
    end
  end

  assign classification = max_index;

endmodule
