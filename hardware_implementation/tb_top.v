`timescale 1ns / 1ps
module tb_top;
    reg        clk   = 0;
    reg        start = 0;
    reg  [7:0] pixel_in = 0;
    wire [3:0] classification;
    wire       done;

    reg [783:0] test_images [0:9999];
    reg [3:0]   test_labels [0:9999];

    integer i, b, correct;
    integer active_count, l1_idx;

    top dut (
        .clk            (clk),
        .start          (start),
        .pixel_in       (pixel_in),
        .classification (classification),
        .done           (done)
    );

    always #5 clk = ~clk;

    initial begin
        $readmemb("../models/test_data.txt",   test_images);
        $readmemh("../models/test_labels.txt", test_labels);

        correct = 0;

        for (i = 0; i < 100; i = i + 1) begin

            //Send byte 0 with start asserted
            @(negedge clk);
            pixel_in = test_images[i][783:776]; // bits [783:776] = byte 0 (MSB first)
            start    = 1;

            // Send bytes 1-97, deassert start after first byte 
            for (b = 1; b < 98; b = b + 1) begin
                @(negedge clk);
                start    = 0;
                // Extract byte b: MSB-first from test_images[i]
                // b=1  -> [775:768], b=97 -> [7:0]
                pixel_in = test_images[i][783 - b*8 -: 8];
            end

            // Wait for DUT to finish
            wait(done === 1'b1);
            @(negedge clk); // let classification register settle

            if (classification == test_labels[i]) correct = correct + 1;

            // Debug count active layer-1 neurons
            active_count = 0;
            for (l1_idx = 0; l1_idx < 256; l1_idx = l1_idx + 1) begin
                if (dut.l1_results[l1_idx] === 1'b1) active_count = active_count + 1;
            end

            $display("Image %0d | Predicted: %0d | Actual: %0d | L1 Active: %0d/256",
                     i+1, classification, test_labels[i], active_count);
        end

        $display("Final Accuracy: %0d / 100", correct);
        $finish;
    end
endmodule