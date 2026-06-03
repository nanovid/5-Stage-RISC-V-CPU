module register_file #()
(
    input  wire        clock,
    input  wire        reset,
    input  wire [4:0]  addr_rs1,
    input  wire [4:0]  addr_rs2,
    input  wire [4:0]  addr_rd,
    input  wire [31:0] data_rd,
    input  wire        write_enable,
    output wire [31:0]  data_rs1, //change these to wires instead of regs
    output wire [31:0]  data_rs2
);

// Use the BRAM forcing attributes
(* ram_style = "block", max_depth_attr = 1024 *) reg [31:0] bankA [0:31];
(* ram_style = "block", max_depth_attr = 1024 *) reg [31:0] bankB [0:31];


//The only problem I can imagine with the changes is with the stack pointer. 

initial begin
    $readmemh("regfile_init.mem", bankA);
    $readmemh("regfile_init.mem", bankB);
end


// We need to create registers for the synchronous read output
reg [31:0] data_rs1_q;
reg [31:0] data_rs2_q;

assign data_rs1 = data_rs1_q;
assign data_rs2 = data_rs2_q;

    // Synch write port -> should force mapping to the BRAM's synchronous write port
    always @(posedge clock) begin
        if (write_enable && addr_rd != 5'd0) begin
            bankA[addr_rd] <= data_rd;
            bankB[addr_rd] <= data_rd;
        end
    end

    // Synch read ports ->  maps to the BRAM's registered output with a cycle delay
    always @(posedge clock) begin
        if (reset) begin
            data_rs1_q <= 32'd0;
            data_rs2_q <= 32'd0;
        end else begin
            if (addr_rs1 == 5'd0) begin
                data_rs1_q <= 32'd0;
            end else begin
                data_rs1_q <= bankA[addr_rs1];
            end
            
            if (addr_rs2 == 5'd0) begin
                data_rs2_q <= 32'd0;
            end else begin
                data_rs2_q <= bankB[addr_rs2];
            end
        end
    end

endmodule