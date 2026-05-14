`timescale 1ns / 1ps
module top (
    input        clk,                       //clock is necessary for BRAM now
    input        start,                     //start signal
    input  [7:0] pixel_in,                  //input image will be pipelined due to limited IO   
    output reg [3:0] classification = 0,    //classification is final output determining the value of the MNIST number
    output reg       done = 0
);
    //FSM states
    localparam IDLE=0, LOAD=1, CALC=2, WAIT_L2=3, FINISH=4;
    reg [2:0] state = 0;                    //State must be 3-bits to account for 4 states
    //Image buffer
    reg [783:0] image_buf = 0;              //image buffer -- there will be 98 cycles becuse 784/8 is 98
    reg [6:0]   load_cnt  = 0;              //7-bits account for 98 values

    //Layer 1 weight memory (BRAM)
    (* ram_style = "block" *) reg [783:0] w1_mem [0:255];       //forces inferred memory as BRAM ranther than LUT
    initial $readmemb("../models/weights_layer1.txt", w1_mem);  //reads the txt file

    //Layer 2 weight memory (not necessary to use BRAM)
    reg [255:0] w2_mem [0:9];
    initial $readmemb("../models/weights_layer2.txt", w2_mem);

    //Pipeline counter
    reg [8:0] pipeline_cnt = 0;

    reg [783:0] w1_dout_reg = 0;
    always @(posedge clk) begin
        if (state == CALC)
            w1_dout_reg <= w1_mem[pipeline_cnt];    //when stat is CALC, weights are read (saves some power)
    end

    //Layer 1 Neuron 
    wire signed [31:0] l1_count;
    neuron #(.IN(784)) l1_inst (
        .weight(w1_dout_reg),       //weight
        .x(image_buf),              //input
        .count(l1_count)            //output "integer"
    );

    //Layer 1 Results 
    reg [255:0] l1_results = 0;
    reg [255:0] l1_results_stable = 0;  // l1_results_stable only updates ONCE after CALC completes,

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

    always @(posedge clk) begin     //state machine
        case (state)

            IDLE: begin
                done         <= 0;
                pipeline_cnt <= 0;
                if (start) begin
                    image_buf <= {image_buf[775:0], pixel_in};  //784 - 8 = 776, loading in each pixel from the top then shift 8
                    load_cnt  <= 1;
                    state     <= LOAD;
                end
            end

            LOAD: begin
                image_buf <= {image_buf[775:0], pixel_in};
                load_cnt  <= load_cnt + 1;
                if (load_cnt == 97) state <= CALC;
            end
            //activation function
            CALC: begin
                pipeline_cnt <= pipeline_cnt + 1;
                if (pipeline_cnt >= 1 && pipeline_cnt <= 256) begin
                    l1_results[255 - (pipeline_cnt - 1)] <= (l1_count >= 0);
                end
                if (pipeline_cnt == 256) state <= WAIT_L2;
            end

            WAIT_L2: begin
                l1_results_stable <= l1_results;    //for stability of layer 1 results
                state <= FINISH;
            end
            FINISH: begin
                max_val = l2_outs[0];
                classification <= 0;
                for (j = 1; j < 10; j = j + 1) begin
                    if (l2_outs[j] > max_val) begin
                        max_val = l2_outs[j];
                        classification <= j[3:0];
                    end
                end
                done  <= 1;
                state <= IDLE;
            end
        endcase
    end
endmodule