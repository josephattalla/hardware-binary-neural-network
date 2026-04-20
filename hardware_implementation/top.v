`include "neuron.v"
`include "activation.v"

module top (
    input  [783:0] image,
    output [  3:0] classification
);

  // layer 1 weights
  (* DONT_TOUCH = "yes" *) reg [783:0] w1[0:255];
  initial begin
    $readmemb("../models/weights_layer1.txt", w1);
  end

  // layer 2 weights
  (* DONT_TOUCH = "yes" *) reg [255:0] w2[0:9];
  initial begin
    $readmemb("../models/weights_layer2.txt", w2);
  end


  // layer 1 neurons
  wire signed [31:0] layer_1_neuron_outputs[0:255];
  genvar i;
  generate
    for (i = 0; i < 256; i = i + 1) begin : g_layer_1_neurons
      neuron #(
          .IN(784)
      ) layer_1_neurons (
          .weight(w1[i]),
          .x(image),
          .count(layer_1_neuron_outputs[i])
      );
    end
  endgenerate

  // layer 1 activation
  wire [255:0] layer_1_out;
  generate
    for (i = 0; i < 256; i = i + 1) begin : g_layer_1_activation
      activation layer_1_activation (
          .count(layer_1_neuron_outputs[i]),
          .sign (layer_1_out[255 - i])
      );
    end
  endgenerate

  // layer 2 neurons
  wire signed [31:0] layer_2_neuron_outputs[0:9];
  generate
    for (i = 0; i < 10; i = i + 1) begin : g_layer_2
      neuron #(
          .IN(256)
      ) layer_2 (
          .weight(w2[i]),
          .x(layer_1_out),
          .count(layer_2_neuron_outputs[i])
      );
    end
  endgenerate

  // get classification
  reg [3:0] max_index;
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
