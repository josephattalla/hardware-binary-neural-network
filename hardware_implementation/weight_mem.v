module weight_mem #(
    parameter IN = 784,
    parameter OUT = 256,
    parameter FILE = "./models/weights_layer1.txt"
  )(
    input  [$clog2(OUT)-1:0] neuron,
    output reg [IN-1:0] weights_row
  );
  reg [IN-1:0] weights [0:OUT-1];

  always @(neuron)
  begin
    weights_row = weights[neuron];
  end

  initial
  begin
    $readmemb(FILE, weights);
  end
endmodule
