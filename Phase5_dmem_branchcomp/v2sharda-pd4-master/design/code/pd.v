module pd(
  input clock,
  input reset
);


reg [31:0] PC_fetch = 32'h01000000; //instantiation
reg [31:0] PC_next;

reg [31:0] data_in;
reg [31:0] data_out;
reg [31:0] dmem_data_out;
reg read_write;
reg [31:0] instruction; 
reg [6:0] D_OPCODE;
reg [4:0] D_RD;
reg [4:0] D_RS1;
reg [4:0] D_RS2;
reg [2:0] D_FUNCT3;
reg [6:0] D_FUNCT7;
reg [31:0] D_IMM;
reg [4:0] D_SHAMT;
reg R_Write_Enable;
reg R_Write_Destination;
reg R_Wite_Data;
//the alu result will not always be there it should actually be the result of a mux that determines 
reg r_write_enable;
reg [31:0] alu_result; //this is the output of the ALU that will be fed to the register file        
reg [31:0] data_rs1; //this is the output of the register file that will be fed to the ALU
reg [31:0] data_rs2; //this is the output of the register file    
reg unsign_or_signed;
reg BrEq;
reg BrLT;
reg branch_taken;
reg branch_taken_real; //this is the branch taken signal that comes from execute
reg jump_taken; //this is the jump taken signal that comes from execute 
reg pc_mux; //this is the pc mux select signal that comes from execute  
reg Bsel;
reg Asel;
reg [31:0] alu_A; //this is the A input to the ALU that comes from a mux
reg [3:0] ALU_sel;
reg [31:0] alu_B; //this is the B input to the ALU that comes from a mux
reg MemRW; //this is the memory read write signal that comes from execute
reg [1:0] WB_sel;
reg [1:0] access_size;
reg [31:0] dmem_out_fixed;
reg [31:0] write_back_data; //data to be written back to register file


//pulling the instruction from instruction memory
imemory imem(
    .clock(clock),
    .address(PC_fetch),
    .data_in(data_in),
    .read_write(read_write),
    .data_out(data_out)
);
//Stage 2: Decode
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

register_file rf(
    .clock(clock),
    .reset(reset),
    .addr_rs1(D_RS1),
    .addr_rs2(D_RS2),
    .addr_rd(D_RD),
    .data_rd(write_back_data), //from execute /
    .data_rs1(data_rs1), //to execute
    .data_rs2(data_rs2), //to execute
    .write_enable(r_write_enable) //from execute
);
//Stage 3: Execute
branch_compare branch_compare1(
    .clock(clock),
    .A(data_rs1), //from register file
    .B(data_rs2), //from register file
    .BrUN(D_FUNCT3), //from decode
    .BrEq(BrEq), //to execute
    .BrLT(BrLT), //to execute
    .branch_taken(branch_taken) //to execute
);

mux21 mux_alu_A(
    .sel(Asel), //always 0 for now, later will be from execute
    .in0(data_rs1), //from register
    .in1(PC_fetch), //pc coutner
    .out(alu_A) //to execute
);

mux21 mux_alu_B(
    .sel(Bsel), //from execute
    .in0(data_rs2), //from register file
    .in1(D_IMM), //from decode
    .out(alu_B) //to execute
);

ALU alu(
    .clock(clock),
    .A(alu_A), //register file output 1 or pc
    .B(alu_B), //from mux, pretty much either rs2 or imm
    .ALU_sel(ALU_sel), //from execute
    .ALU_out(alu_result) //to register file
);
//Stage 4: Memory
dmemory dmem(
    .clock(clock),
    .address(alu_result), //from alu
    .data_in(data_rs2), //from register file
    .read_write(MemRW), //from execute
    .access_size(access_size), //from decode - but will we have to limit its usgae to be only with store and load?
    .data_out(dmem_data_out) //to register file
);

loadster loadstore1(
    .clock(clock),
    .reset(reset),
    .dmem_data_out(dmem_data_out), //from data memory
    .D_FUNCT3(D_FUNCT3), //from decode
    .data_out(dmem_out_fixed) //to register file
);

//Stage 5: Write Back
mux31 mux_write_data(
    .sel(WB_sel), //from execute
    .in0(alu_result), //from alu
    .in1(dmem_out_fixed), //from data memory
    .in2(PC_fetch + 4), //for jal and jalr
    .out(write_back_data) //to register file
);

mux21 mux_pc_branch(
    .sel(branch_taken_real||jump_taken), //from execute
    .in0(PC_fetch + 4), //normal pc + 4
    .in1(alu_result), //branch target address from alu
    .out(PC_next) //to pc register
);

always @(*) begin
    unsign_or_signed = 1'b0; //default to signed
    branch_taken_real = 1'b0; //default to not taken
    jump_taken = 1'b0; //default to no jump
    pc_mux = branch_taken_real || jump_taken;
    MemRW = 1'b0; //default to read
    WB_sel = 2'b00; //default to alu result
    r_write_enable = 1'b1; //default to write enabled
    access_size = D_FUNCT3[1:0]; //for load and store instructions
    case(D_OPCODE) 
        7'b0110011: begin //R type
            ALU_sel = {D_FUNCT7[5], D_FUNCT3}; //so this is func7_3
            Bsel = 0; //always taking rs2
            Asel = 0; //always taking rs1
        end
        7'b0010011: begin //I type
            //i type has no func7 so we just make it 0
            //but the decoder already does that i think but we may need to add it here
            ALU_sel = {D_FUNCT7[5], D_FUNCT3}; //so this is func7_3
            Bsel = 1;
            Asel = 0; //always taking rs1
        end
        7'b0000011: begin //load
            ALU_sel = 4'b0000; //ADD
            Bsel = 1; //always taking the immediate
            Asel = 0; //always taking rs1
            WB_sel = 2'b01; //data memory output
        end
        7'b0100011: begin //store
            ALU_sel = 4'b0000; //ADD
            Bsel = 1; //always taking the immediate
            Asel = 0; //always taking rs1
            MemRW = 1; //write to memory
            r_write_enable = 0; //no write back to register file
        end
        7'b1100011: begin //branch
            ALU_sel = 4'b0000; //ADD
            Bsel = 1; //always taking the immediate
            unsign_or_signed = D_FUNCT3[0]; //BrUN signal
            Asel = 1; //always taking pc
            branch_taken_real = branch_taken; //from branch compare
            r_write_enable = 0; //no write back to register file
        end
        7'b1101111: begin //jal
            ALU_sel = 4'b0000; //ADD
            Bsel = 1; //always taking the immediate
            Asel = 1; //pc + 4
            WB_sel = 2'b10; //pc + 4
            jump_taken = 1'b1; //pc mux select 
        end
        7'b1100111: begin //jalr
            ALU_sel = 4'b0000; //ADD
            Bsel = 1; //always taking the immediate
            Asel = 0; //rs1
            WB_sel = 2'b10; //pc + 4
            jump_taken = 1'b1; //pc mux select
        end
        7'b0010111: begin //auipc
            ALU_sel = 4'b0000; //ADD
            Bsel = 1; //always taking the immediate
            Asel = 1; //pc + imm
        end
        7'b0110111: begin //lui
            ALU_sel = 4'b1111; //LUI
            Bsel = 1; //always taking the immediate
            Asel = 0; //pc + imm --> don't care 
        end
        default: begin
            ALU_sel = 4'b0000; //default to ADD
            Bsel = 0;
            Asel = 0;
            MemRW = 0;
            WB_sel = 2'b00;
        end
    endcase
end

always @(posedge clock) begin
    if (reset) begin
        PC_fetch <= 32'h01000000;
       
        
    end else begin
        PC_fetch <= PC_next;
        
    end
end

endmodule

