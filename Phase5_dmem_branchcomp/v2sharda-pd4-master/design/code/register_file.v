module register_file #()
(
 input wire clock,
 input wire reset,
 input wire [4:0] addr_rs1,
 input wire [4:0] addr_rs2, 
 input wire [4:0] addr_rd,
 input wire [31:0] data_rd,
 output reg [31:0] data_rs1,
 output reg [31:0] data_rs2,
 input wire write_enable
);

reg [31:0] registers [31:0]; //32 registers of 32 bits each
integer i;


initial begin

    for(i = 0; i<32; i = i + 1) begin
        registers[i] = 32'b0; //initialize all registers to 0
    end

    registers[2] = 32'h01000000 + `MEM_DEPTH; //initialize stack pointer to the end of memory
end

always @(posedge clock) begin
    if(reset) begin
        registers[2] <= 32'h01000000 + `MEM_DEPTH; //x0 is always 0
    end

    else if (write_enable && (addr_rd != 5'b0)) begin //if write enable is high and we are not writing to x0
        registers[addr_rd] <= data_rd; //write the data to the register
    end
end

always @(*) begin
    data_rs1 = registers[addr_rs1]; //read the data from the register
    data_rs2 = registers[addr_rs2]; //read the data from the register
end


endmodule
