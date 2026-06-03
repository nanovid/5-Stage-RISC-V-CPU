module ALU #()
(
 input wire clock,
 input wire [31:0] A, 
 input wire [31:0] B,
 input wire [3:0] ALU_sel,
 output reg [31:0] ALU_out
);

//reg [4:0] opcode_temp = opcode[6:2];
//reg func7_temp = funct7[5];
//reg [3:0] func7_3 = {funct7[5], funct3}; 

//keep the operation codes here for easy reference
//but lets also make them func7 and funct3 combinations
//so we can just use one 4 bit ALU select line
reg [3:0] ADD = 4'b0000;
reg [3:0] SUB = 4'b1000;
reg [3:0] AND = 4'b0111;
reg [3:0] OR  = 4'b0110;
reg [3:0] XOR = 4'b0100;
reg [3:0] SLL = 4'b0001;
reg [3:0] SRL = 4'b0101;
reg [3:0] SRA = 4'b1101;
reg [3:0] SLT = 4'b0010;
reg [3:0] SLTU= 4'b0011;


always @(*) begin
    case(ALU_sel)
        4'b0000: ALU_out = A + B; //ADD
        4'b1000: ALU_out = A - B; //SUB
        4'b0111: ALU_out = A & B; //AND
        4'b0110: ALU_out = A | B; //OR
        4'b0100: ALU_out = A ^ B; //XOR
        4'b0001: ALU_out = A << B[4:0]; //SLL
        4'b0101: ALU_out = A >> B[4:0]; //SRL
        4'b1101: ALU_out = $signed(A) >>> B[4:0]; //SRA
        4'b0010: ALU_out = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; //SLT
        4'b0011: ALU_out = (A < B) ? 32'b1 : 32'b0; //SLTU
        default: ALU_out = 32'b0; //default case
    endcase
end




endmodule 