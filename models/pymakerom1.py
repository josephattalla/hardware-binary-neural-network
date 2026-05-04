import os

def generate_verilog_rom(input_filename, output_filename):
    # Check if the file actually exists before trying to open it
    if not os.path.exists(input_filename):
        print(f"Error: I can't find a file named '{input_filename}' in this folder.")
        print(f"Current folder is: {os.getcwd()}")
        return

    try:
        with open(input_filename, 'r') as f:
            weights = [line.strip() for line in f if line.strip()]

        with open(output_filename, 'w') as v:
            v.write("module ROM_W1(\n")
            v.write("    input      [7:0]   address, \n")
            v.write("    output reg [783:0] data    \n")
            v.write("    );\n\n")
            v.write("    always @(*) begin\n")
            v.write("        case(address)\n")

            for i in range(256):
                addr_hex = f"{i:02X}"
                if i < len(weights):
                    # Ensure it's exactly 784 bits
                    binary_str = weights[i][:784].zfill(784)
                else:
                    binary_str = "0" * 784
                
                v.write(f"            8'h{addr_hex}: data = 784'b{binary_str};\n")

            v.write("            default: data = 784'b0;\n")
            v.write("        endcase\n")
            v.write("    end\n\n")
            v.write("endmodule\n")

        print(f"Successfully created {output_filename} using {len(weights)} lines from {input_filename}.")

    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# --- CHANGE THESE NAMES TO MATCH YOUR FILES ---
MY_INPUT_FILE = '.\models\weights_layer1.txt'  # Your source file
MY_OUTPUT_FILE = 'ROM_W1.v'     # The file you will copy into Vivado

generate_verilog_rom(MY_INPUT_FILE, MY_OUTPUT_FILE)