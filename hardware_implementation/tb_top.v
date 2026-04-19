`include "top.v"
module tb_top;
  reg [783:0] test_data[0:9999];
  reg [3:0] test_labels[0:9999];
  reg [783:0] image;
  wire [3:0] classification;

  initial begin
    $readmemb("../models/test_data.txt", test_data);
    $readmemh("../models/test_labels.txt", test_labels);
  end

  top dut (
      .image(image),
      .classification(classification)
  );

  integer i;
  integer correct;
  initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
    correct = 0;
    for (i = 0; i < 10000; i = i + 1) begin
      image = test_data[i];
      #10;
      if (classification == test_labels[i]) correct = correct + 1;
      if (i % 10 == 0) $display("%d images completed", i);
    end
    $display("accuracy: %0d / 10000", correct);
    $finish;
  end
endmodule
