module pd(
  input clock,
  input reset
);

reg [31:0] PC_fetch = 32'h01000000; //instantiation

//now lowkey i dont really know what to do with the outputs of the memory module 
//so im just gonna make variables and assign them there

reg [31:0] data_in;
reg [31:0] data_out;
reg read_write;
reg [31:0] instruction; //this is the output of the memory module that will be fed to decode
reg [6:0] D_OPCODE;
reg [4:0] D_RD;
reg [4:0] D_RS1;
reg [4:0] D_RS2;
reg [2:0] D_FUNCT3;
reg [6:0] D_FUNCT7;
reg [31:0] D_IMM;
reg [4:0] D_SHAMT;


imemory imem(
    .clock(clock),
    .address(PC_fetch),
    .data_in(data_in),
    .read_write(read_write),
    .data_out(data_out)
);

decode decode1(
    .clock(clock),
    .instruction(data_out),
    .D_OPCODE(D_OPCODE),
    .D_RD(D_RD),
    .D_RS1(D_RS1),
    .D_RS2(D_RS2),
    .D_FUNCT3(D_FUNCT3),
    .D_FUNCT7(D_FUNCT7),
    .D_IMM(D_IMM),
    .D_SHAMT(D_SHAMT)
);

always @(posedge clock) begin
    if (reset) begin
        PC_fetch <= 32'h01000000;
        //data_out <= 32'b0;
        
        
    end else begin
        PC_fetch <= PC_fetch + 4;
        
    end
end




endmodule

