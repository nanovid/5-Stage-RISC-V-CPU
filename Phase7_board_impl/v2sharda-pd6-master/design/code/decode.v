module decode #()
(
    input clock,
    input enable, 
    input wire [31:0] instruction,
    output reg  [6:0] D_OPCODE,       
    output reg [4:0] D_RD, 
    output reg [4:0] D_RS1,               
    output reg [4:0] D_RS2,               
    output reg [2:0] D_FUNCT3,            
    output reg [6:0] D_FUNCT7,            
    output reg [31:0] D_IMM,      //so i have to make this 31 bits to accomodate the largest immediate value and i forgot that i have to extend it like a silly boy       
    output reg [4:0] D_SHAMT
);

reg [6:0] opcode;
reg [31:0] instruction_temp;

// always @(*) begin
//     opcode = instruction[6:0];
//     instruction_temp = instruction;
// end

always @(*) begin

    D_OPCODE = 0;
    D_RD = 0;
    D_RS1 = 0;
    D_RS2 = 0;
    D_FUNCT3 = 0;
    D_FUNCT7 = 0;
    D_IMM = 0;
    D_SHAMT = 0;
    
    if (enable) begin 
    
    D_OPCODE = instruction[6:0];

        case(D_OPCODE)  //R type
            7'b0110011: begin //R type  
                D_RD = instruction[11:7];
                D_FUNCT3 = instruction[14:12];
                D_RS1 = instruction[19:15];
                D_RS2 = instruction[24:20];
                D_FUNCT7 = instruction[31:25];
            end
            7'b0010011: begin //i type
                // $display("Decoding instruction: %h", instruction);
                D_RD = instruction[11:7];
                D_FUNCT3 = instruction[14:12];
                D_RS1 = instruction[19:15];
                if(D_FUNCT3 == 3'b001 || D_FUNCT3 == 3'b101) begin //SLLI, SRLI, SRAI
                    D_FUNCT7 = instruction[31:25];
                    D_SHAMT = instruction[24:20];
                    //D_IMM[6:0] = instruction[31:25]; //what might happen is that D_IMM is set as 32 bits but is only being assigned 7 here
                    //what we may have to do is D_IMM[6:0] = instruction[25:31]; and then sign extend OR just do a temp imm variable before extension
                    D_IMM = {27'b0, D_SHAMT}; //zero extend cause its a shift amount

                    //D_IMM = {{25{instruction[31]}}, D_IMM[6:0]}; //sign extend
                end else begin 
                    D_SHAMT = 0;
                    D_IMM[11:0] = instruction[31:20];
                    D_IMM = {{20{instruction[31]}}, D_IMM[11:0]}; //sign extend
                end
                // $display("D_OPCODE: %b", D_OPCODE);
                // $display("D_FUNCT7: %b", D_FUNCT7); 
                // $display("D_FUNCT3: %b", D_FUNCT3);
                // $display("D_RS1: %b", D_RS1);
                // $display("D_RS2: %b", D_RS2);
                // $display("D_RD: %b", D_RD);
                // $display("D_IMM: %h", D_IMM);
                // $display("D_SHAMT: %b", D_SHAMT);

            end
            7'b0000011: begin //i type load case
                D_RD = instruction[11:7];
                D_FUNCT3 = instruction[14:12];
                D_RS1 = instruction[19:15];
                D_IMM[11:0] = instruction[31:20];
                D_IMM = {{20{instruction[31]}}, D_IMM[11:0]}; //same extenstion problem may apply here as well
            end
                
            7'b0100011: begin // s type, store type
                //D_RD = instruction[11:7];            
                D_IMM[11:0] = {instruction[31:25], instruction[11:7]};
                D_FUNCT3 = instruction[14:12];
                D_RS1 = instruction[19:15];
                D_RS2 = instruction[24:20];
                D_IMM = {{20{instruction[31]}}, D_IMM[11:0]};
            end
            7'b1100011: begin //b-type for branches
                D_IMM[12:1] = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
                D_FUNCT3 = instruction[14:12];
                D_RS1 = instruction[19:15];
                D_RS2 = instruction[24:20];
                D_IMM = {{19{instruction[31]}}, D_IMM[12:1], 1'b0}; //sign extend and shift left by 1 bit
            end
            7'b0010111, 7'b0110111: begin //b type lui and apac
                D_RD = instruction[11:7];
                D_IMM[31:12] = instruction[31:12]; // sets upper 20 bits
            end

            7'b1101111: begin //jal
                D_RD = instruction[11:7];
                D_IMM[20] = instruction[31];
                D_IMM[10:1] = instruction[30:21];
                D_IMM[11] = instruction[20];
                D_IMM[19:12] = instruction[19:12]; //funky comcept and i dont know why they did this but its probably imp to know so i will 
                //crazy how prof did so much of the work and this is still hard as hell
                //weren't handling sign extension and bit alignment properly
                D_IMM = {{11{instruction[31]}}, D_IMM[20:1], 1'b0}; //sign extend and shift left by 1 bit
            end

            7'b1100111: begin //jalr
                D_RD = instruction[11:7];
                D_FUNCT3 = instruction[14:12];
                D_RS1 = instruction[19:15];
                D_IMM[11:0] = instruction[31:20];
                D_IMM = {{20{instruction[31]}}, D_IMM[11:0]};
            end
            default: begin
                // D_OPCODE = 0;
                D_RD = 0;
                D_RS1 = 0;
                D_RS2 = 0;
                D_FUNCT3 = 0;
                D_FUNCT7 = 0;
                D_IMM = 0;
                D_SHAMT = 0;
            end
        endcase
    end
end
endmodule