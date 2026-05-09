`timescale 1ns / 1ps
module top (
    input        clk,
    input        start,
    input  [7:0] pixel_in,
    output reg [3:0] classification = 0,
    output reg       done = 0
);
    //FSM States
    localparam IDLE=0, LOAD=1, CALC=2, WAIT_L2=3, FINISH=4;
    reg [2:0] state = 0;

    //Image Buffer (filled over 98 cycles)
    reg [783:0] image_buf = 0;
    reg [6:0]   load_cnt  = 0;

    //Layer 1 Weight Memory (BRAM)
    (* ram_style = "block" *) reg [783:0] w1_mem [0:255];
    initial $readmemb("../models/weights_layer1.txt", w1_mem);

    //Layer 2 Weight Memory (small, kept as registers)
    reg [255:0] w2_mem [0:9];
    initial $readmemb("../models/weights_layer2.txt", w2_mem);

    //Pipeline Counter
    reg [8:0] pipeline_cnt = 0;

    //Gate BRAM reads - only read during CALC
    // Previously read every cycle even in IDLE/LOAD/FINISH (wasted BRAM power)
    // Now BRAM output held stable outside CALC
    reg [783:0] w1_dout_reg = 0;
    always @(posedge clk) begin
        if (state == CALC)
            w1_dout_reg <= w1_mem[pipeline_cnt];
    end

    //Layer 1 Neuron (time-multiplexed)
    wire signed [31:0] l1_count;
    neuron #(.IN(784)) l1_inst (
        .weight(w1_dout_reg),
        .x(image_buf),
        .count(l1_count)
    );

    //Layer 1 Results 
    reg [255:0] l1_results = 0;

    // Previously l2_outs recomputed every cycle during CALC as l1_results
    // changed bit-by-bit (256 unnecessary recomputations per image)
    // Now l1_results_stable only updates ONCE after CALC completes,
    // so layer-2 combinational logic is quiet during CALC
    reg [255:0] l1_results_stable = 0;

    //Layer 2 Neurons (combinational on stable snapshot only) 
    wire signed [31:0] l2_outs [0:9];
    genvar k;
    generate
        for (k = 0; k < 10; k = k + 1) begin : l2_gen
            neuron #(.IN(256)) l2_inst (
                .weight(w2_mem[k]),
                .x(l1_results_stable),
                .count(l2_outs[k])
            );
        end
    endgenerate

    integer j;
    reg signed [31:0] max_val;

    always @(posedge clk) begin
        case (state)

            IDLE: begin
                done         <= 0;
                pipeline_cnt <= 0;
                if (start) begin
                    image_buf <= {image_buf[775:0], pixel_in};
                    load_cnt  <= 1;
                    state     <= LOAD;
                end
            end

            LOAD: begin
                image_buf <= {image_buf[775:0], pixel_in};
                load_cnt  <= load_cnt + 1;
                if (load_cnt == 97) state <= CALC;
            end
            //New activation function format
            CALC: begin
                pipeline_cnt <= pipeline_cnt + 1;
                if (pipeline_cnt >= 1 && pipeline_cnt <= 256) begin
                    l1_results[255 - (pipeline_cnt - 1)] <= (l1_count >= 0);
                end
                if (pipeline_cnt == 256) state <= WAIT_L2;
            end

            // Capture stable snapshot of l1_results for layer-2.
            // l1_results_stable is registered here, so l2_outs fully
            // settles before FINISH reads them on the next cycle.
            WAIT_L2: begin
                l1_results_stable <= l1_results;
                state <= FINISH;
            end

            FINISH: begin
                max_val        = l2_outs[0];
                classification <= 0;
                for (j = 1; j < 10; j = j + 1) begin
                    if (l2_outs[j] > max_val) begin
                        max_val        = l2_outs[j];
                        classification <= j[3:0];
                    end
                end
                done  <= 1;
                state <= IDLE;
            end

        endcase
    end
endmodule