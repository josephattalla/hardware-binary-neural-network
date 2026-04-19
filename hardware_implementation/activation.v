module activation (
    input signed [31:0] count, // integers cannot be used as input ports, this is functionally identical
    output sign
);
  assign sign = (count >= 0) ? 1'b1 : 1'b0;
endmodule

