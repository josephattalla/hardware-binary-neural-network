import os

def generate_flattened_rom(input_filename, output_filename, module_name, depth, width):
    if not os.path.exists(input_filename):
        print(f"Error: I can't find '{input_filename}'")
        return

    try:
        with open(input_filename, 'r') as f:
            weights = [line.strip() for line in f if line.strip()]

        total_bits = depth * width

        with open(output_filename, 'w') as v:
            v.write(f"module {module_name}(\n")
            v.write(f"    output [{total_bits-1}:0] data\n")
            v.write("    );\n\n")
            
            v.write(f"    localparam [{total_bits-1}:0] WEIGHT_DATA = {{\n")

            for i in range(depth):
                # Grab the weight or use zeros if missing
                if i < len(weights):
                    binary_str = weights[i][:width].zfill(width)
                else:
                    binary_str = "0" * width
                
                # Verilog concatenation uses commas between elements
                # We add a comma to every line EXCEPT the very last one
                comma = "," if i < depth - 1 else ""
                v.write(f"        {width}'b{binary_str}{comma} // Neuron {i}\n")

            v.write("    };\n\n")
            v.write("    assign data = WEIGHT_DATA;\n\n")
            v.write("endmodule\n")

        print(f"Created {output_filename} ({depth}x{width})")

    except Exception as e:
        print(f"Error: {e}")

# --- RUNNING FOR BOTH LAYERS ---

# Layer 1: 256 neurons, 784 weights each
generate_flattened_rom(
    input_filename  = r'.\models\weights_layer1.txt', 
    output_filename = 'ROM_W1_flat.v', 
    module_name     = 'ROM_W1_flat', 
    depth           = 256, 
    width           = 784
)

# Layer 2: 10 neurons, 256 weights each
generate_flattened_rom(
    input_filename  = r'.\models\weights_layer2.txt', 
    output_filename = 'ROM_W2_flat.v', 
    module_name     = 'ROM_W2_flat', 
    depth           = 10, 
    width           = 256
)