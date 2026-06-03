module pd(
  input clock,
  input reset
);

reg [31:0] PC_fetch = 32'h01000000; //instantiation
wire [31:0] PC_next;

reg [31:0] data_in;
wire [31:0] data_out;
wire [31:0] dmem_data_out;
reg read_write;
wire [6:0] D_OPCODE;
wire [4:0] D_RD;
wire [4:0] D_RS1;
wire [4:0] D_RS2;
wire [2:0] D_FUNCT3;
wire [6:0] D_FUNCT7;
wire [31:0] D_IMM;
wire [4:0] D_SHAMT;
reg R_Write_Enable; //do we need this???? -----------VID-----------------
reg R_Write_Destination;
reg R_Wite_Data;
//the alu result will not always be there it should actually be the result of a mux that determines 
reg r_write_enable;
wire [31:0] alu_result; //this is the output of the ALU that will be fed to the register file (to be pipelined)       
wire [31:0] data_rs1; //this is the output of the register file (to be pipelined)
wire [31:0] data_rs2; //this is the output of the register file (to be pipelined)   
reg unsign_or_signed;
wire BrEq;
wire BrLT;
wire branch_taken;
reg branch_taken_priority; //this signal needs to exist because if for instance we get to a jump
reg jump_taken_JALR;
reg branch_taken_real; //this is the branch taken signal that comes from execute
reg jump_taken; //this is the jump taken signal that comes from execute 
// reg pc_mux; //this is the pc mux select signal that comes from execute  
reg [1:0] Bsel;
reg [1:0] Asel;
wire [31:0] alu_A; //this is the A input to the ALU that comes from a mux
wire [31:0] alu_B; //this is the B input to the ALU that comes from a mux
reg [3:0] ALU_sel;

wire [31:0] bc_A; //rs1 input to Branch Comparator
wire [31:0] bc_B; //rs2 input to Branch Comparator
reg [1:0] bc_Asel; //select signal for rs1 operand to branch comparator
reg [1:0] bc_Bsel; //select signal for rs2 operand to branch comparator

reg MemRW; //this is the memory read write signal that comes from execute
reg [1:0] WB_sel;
reg [1:0] access_size;
wire [31:0] dmem_out_fixed;
wire [31:0] wb_data; //data to be written back to register file

//pipelined operands
reg [31:0] PC_fetchd;
reg [31:0] PC_fetchx;
reg [31:0] PC_fetchm;
reg [31:0] PC_fetchw;

// we don't need these because we are using pipelining D_RD, D_FUNCT3, D_IMM
reg [31:0] instd; //imem -> F/D pipeline reg 
reg [31:0] instx; //imem -> F/D -> D/X
reg [31:0] instm; //imem -> F/D -> D/X -> X/M
reg [31:0] instw; //imem -> F/D -> D/X -> X/M - > M/W

reg [4:0] D_RDx;
reg [4:0] D_RDm; // need to see if the destination register matches an operand: BYPASSING CASE
reg [4:0] D_RDw;

reg [2:0] D_FUNCT3x;
reg [2:0] D_FUNCT3m;
reg [2:0] D_FUNCT3m_delay;
reg [31:0] D_IMMx;

//reg [31:0] data_rs1x; //register file -> pipeline reg -> ALU
//reg [31:0] data_rs2x; //register file -> pipeline reg -> ALU
reg [31:0] data_rs2m; //register file -> pipeline reg D/X -> pipeline reg X/M 
reg [31:0] alu_resultm; //pipelined alu result
reg [31:0] alu_resultw; //pipelined alu_resultm -> because of BRAM 1 cycle read latency 

reg jump_takenx;
reg branch_takenm;
reg branch_taken_realx;


//need the following signals to be pipelined for the memory module 
reg MemRWx; 
reg MemRWm;
reg MemRW_in;
reg [1:0] access_sizex;
reg [1:0] access_sizem;
reg [1:0] access_size_in;

reg [1:0] WB_selx;
reg [1:0] WB_selm;
reg [1:0] WB_selw;

reg [31:0] wb_data_reg; // shadow reg for wb_data

//pipelined control signals

reg [3:0] ALU_selx;
reg [1:0] Aselx;
reg [1:0] Bselx; 

reg [1:0] bc_Aselx; // pipeline bc select signal for rs1 operand 
reg [1:0] bc_Bselx; // pipeline bc select signal for rs1 operand 

reg enable; //branch comparator enable signal
reg enablex;

reg r_write_enablex;
reg r_write_enablem;
reg r_write_enablew;

reg rs2MX_Bypass;
reg rs1MX_Bypass;
reg rs2WX_Bypass;
reg rs1WX_Bypass;
reg wm_cond;
reg stall_crit_rs1;
reg stall_crit_rs2;
reg stall_crit_load_use;
//buffer variables meant for stall
reg [31:0] data_rs1_in;
reg [31:0] data_rs2_in;
reg [31:0] D_IMM_in;
reg [3:0] ALU_sel_in;
reg [1:0] Asel_in;
reg [1:0] Bsel_in;
reg [4:0] D_RD_in;    
reg branch_taken_real_in;
reg r_write_enable_in;

reg stallrs1;
reg stallrs2;

reg [15:0] clockcoutner = 0;

reg flush;
reg [1:0] DataW_sel_in;
reg crown; //giving jal a priority flag since it unconditionally jumps whereas jalr might need to stall.
reg crownx;

reg stall_overload;

reg imem_enable; //PD6
reg imem_enabled;
reg imem_enable_in; //PD6
//pulling the instruction from instruction memory
imemory imem(
    .clock(clock),
    .address(PC_fetch),
    .data_in(data_in),
    .read_write(read_write),
    .enable(imem_enable),
    .data_out(data_out)
);
//Stage 2: Decode
reg decode_enable;
reg decode_enable_in;
decode decode1(
    .clock(clock),
    .enable(decode_enable),
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
    .addr_rd(D_RDw), // need to use pipelined version from instW
    .data_rd(wb_data), // BRAM 1 cycle read so use output of 31 mux
    .data_rs1(data_rs1), //to execute
    .data_rs2(data_rs2), //to execute
    .write_enable(r_write_enablew) //pipelined write enable signal from W stage 
);
//Stage 3: Execute

mux31 bc_rs1(
    .sel(bc_Aselx),
    .in0(data_rs1),
    .in1(alu_resultm),
    .in2(wb_data),
    .out(bc_A)
);

mux31 bc_rs2(
    .sel(bc_Bselx),
    .in0(data_rs2),
    .in1(alu_resultm),
    .in2(wb_data),
    .out(bc_B)
);


branch_compare branch_compare1(
    .clock(clock),
    .enable(enablex),
    .A(bc_A), //register file -> pipeline reg D/X -> branch compare
    .B(bc_B), //register file -> pipeline reg D/X -> branch compare
    .BrUN(D_FUNCT3x), //pipelined version of D_FUNCT3
    .BrEq(BrEq), //to execute
    .BrLT(BrLT), //to execute
    .branch_taken(branch_taken) //to execute
);

mux41 mux_alu_A(
    .sel(Aselx), //Asel -> Aselx
    .in0(data_rs1), //reg file -> D/X pipeline -> ALU Mux 00
    .in1(PC_fetchx), //pc counter 01
    .in2(alu_resultm), //MX BYPASS: aluresult_m --> aluA operand 10
    .in3(wb_data), //WX BYPASS: wb_data --> aluA operand 11
    .out(alu_A) //to execute
);

mux41 mux_alu_B(
    .sel(Bselx), //Bsel -> Bselx
    .in0(data_rs2), //reg file -> D/X pipeline -> ALU Mux 
    .in1(D_IMMx), //from decode
    .in2(alu_resultm), //MX BYPASS: aluresult_m --> aluB operand
    .in3(wb_data), //WX BYPASS: wb_data --> aluB operand
    .out(alu_B) //to execute
);

ALU alu(
    .clock(clock),
    .A(alu_A), //register file output 1 or pc
    .B(alu_B), //from mux, pretty much either rs2 or imm
    .ALU_sel(ALU_selx), // ALU_Sel --> ALU_Selx
    .ALU_out(alu_result) //to register file
);
//Stage 4: Memory
dmemory dmem(
    .clock(clock),
    .read_write(MemRWm),
    .access_size(access_sizem), //
    .address(alu_resultm), //from piplined alu reg
    .data_in(data_W), // reg file -> rs2 D/X -> rs2 X/M -> DMEM     
    .data_out(dmem_data_out) //to register file
);

loadster loadstore1(
    .clock(clock),
    .reset(reset),
    .dmem_data_out(dmem_data_out), //from data memory
    .D_FUNCT3(D_FUNCT3m_delay), //need to pipeline D_FUNCT3x -> D_FUNCT3m to be able to use in loadster
    .data_out(dmem_out_fixed) //to register file
);

//Stage 5: Write Back
mux31 mux_write_data(
    .sel(WB_selw), //
    .in0(alu_resultw), //from piplined alu reg
    .in1(dmem_out_fixed), //from data memory
    .in2(PC_fetchw + 4), //for jal and jalr; use pipelined PC fetch
    .out(wb_data) //to register file
);

mux21 mux_pc_branch(
    .sel(branch_taken||jump_takenx), 
    .in0(PC_fetch + 4), //normal pc + 4
    .in1(alu_result), //branch target address from alu 
    .out(PC_next) //to pc register
);

wire [31:0] data_W;
reg [31:0] writeback_shadow_reg;
reg writeback_shadow_reg_enable;
reg [1:0] DataW_sel;
reg [1:0] DataW_selm;
reg [1:0] DataW_selx;
reg [1:0] DataW_selw;
reg stall;

mux31 WM_bypass_mux(
    .sel(DataW_selm), 
    .in0(wb_data),
    .in1(data_rs2m), 
    .in2(wb_data_reg), //shadow reg
    .out(data_W)
);


always @(*) begin
    
    
    branch_taken_priority = 1'b0;
    jump_taken = 1'b0;
    jump_taken_JALR = 0;
    r_write_enable = 1'b0;
    
    // ALU_sel = 4'b0000; // default to ADD
    // Asel    = 2'b00;   // default select for rs1
    // Bsel    = 2'b00;   // default select for rs2 or imm
    // bc_Asel = 2'b00;
    // bc_Bsel = 2'b00;
    
    // MemRW = 1'b0;
    // WB_sel = 2'b00; //selects out of pcw+4, aluw, dmem_out
    // DataW_sel = 2'b01; //selects out of wb_data, shadow reg, or rs2m
    // DataW_sel_in = 2'b01;
    
    access_size = 2'b00;
    crown = 0;
    imem_enable = 1'b1;
    rs2MX_Bypass = 1'b0;
    rs1MX_Bypass = 1'b0;
    rs2WX_Bypass = 1'b0;
    rs1WX_Bypass = 1'b0;
    wm_cond = 1'b0;
    stall_crit_rs1 = 1'b0;
    stall_crit_rs2 = 1'b0;
    stall_crit_load_use = 1'b0;
    stall_overload = 1'b0;
    stallrs1 = 1'b0;
    stallrs2 = 1'b0;
    stall = 1'b0;
    writeback_shadow_reg_enable = 1'b0;
    data_rs1_in = 0;
    data_rs2_in = 0;
    // D_IMM_in = 0;
    ALU_sel_in = 0;
    Asel_in = 2'b00;
    Bsel_in = 2'b00;
    // D_RD_in = 0;
    branch_taken_real_in = 0;
    r_write_enable_in = 0;

    access_size_in = 2'b00;
    imem_enable_in = 1'b0;
    MemRW_in = 0;
    decode_enable_in = 1'b1;

    // *************** Reset condition ***************
    if (reset) begin
        // Override only what must explicitly clear
        MemRW = 0;
        r_write_enable = 0;
        stall = 0;
        imem_enable = 1;
        enable = 1'b1;

        unsign_or_signed = 1'b0; //DFUNCT3 Signed 

        ALU_sel = 4'b0000; //default to ADD
        Bsel = 2'b00;
        Asel = 2'b00;
        bc_Asel = 2'b00;
        bc_Bsel = 2'b00;
    
        MemRW = 0;
        WB_sel = 2'b00;
        DataW_sel = 2'b00; //selects out of wb_data, shadow reg, or rs2m
        DataW_sel_in = 2'b00;

        D_IMM_in = 0;
        D_RD_in = 0;
        imem_enable_in = 1'b0;
        imem_enable = 1'b0;
        decode_enable_in = 1'b0;
        
    end else begin

        unsign_or_signed = 1'b0; //default to signed
        branch_taken_priority = 1'b0; //default to not taken
        jump_taken = 1'b0; //default to no jump
        jump_taken_JALR = 0;
        // pc_mux = branch_taken_real || jump_taken;
        MemRW = 1'b0; //default to read
        WB_sel = 2'b00; //default to alu result
        r_write_enable = 1'b0; //default to write enabled
        access_size = D_FUNCT3[1:0]; //for load and store instructions
        bc_Asel = 2'b00; //branch comparator operand1 is typically rs1
        bc_Bsel = 2'b00; //branch comparator operand2 is typically rs2
        DataW_sel = 2'b01; //default to no bypassing for store data
        enable = 1'b0;
        crown = 0;
        imem_enable = 1; //default to enabled
        decode_enable_in = 1'b1; //default to enabled  

        rs2MX_Bypass = (D_RDx == D_RS2) && (D_RDx != 5'b00000);
        rs1MX_Bypass = (D_RDx == D_RS1) && (D_RDx != 5'b00000);
        rs2WX_Bypass = (D_RDm == D_RS2) && (D_RDm != 5'b00000);
        rs1WX_Bypass = (D_RDm == D_RS1) && (D_RDm != 5'b00000);

        wm_cond = (D_RDx == D_RS2) && (D_RDx != 5'b00000);

        

        stall_crit_rs1 = ((D_RDw == D_RS1) && (D_RDw != 5'b00000));
        stall_crit_rs2 = ((D_RDw == D_RS2) && (D_RDw != 5'b00000));
        stall_crit_load_use = ((D_RDx == D_RS1) || (D_RDx == D_RS2)) && (D_RDx != 5'b00000) && (instx[6:0] == 7'b0000011); //load-use hazard detection
        
        if (D_OPCODE == (7'b0100011) && (instx[6:0] == 7'b0000011) && (D_RDx == D_RS2)) begin //store following load to same register
            stall_overload = 1'b1;
            wm_cond = 1'b1; //disable wm bypassing in this case
        end else begin
            stall_overload = 1'b0;
            wm_cond = wm_cond;
        end 

        // stall_fr = (stallrs1 || stallrs2);

        //stall logic?
        stall = 1'b0; //default to no stall
        writeback_shadow_reg_enable = 1'b0; //default to no wx bypass for store data

        case(D_OPCODE) 
            
            7'b0110011: begin //R type
                ALU_sel = {D_FUNCT7[5], D_FUNCT3}; //so this is func7_3
                Bsel = rs2MX_Bypass ? 2'b10 :
                    rs2WX_Bypass ? 2'b11 : 2'b00; // take rs2 unless we need to bypass

                Asel = rs1MX_Bypass ? 2'b10 :
                    rs1WX_Bypass ? 2'b11 : 2'b00; // take rs1 unless we need to bypass

                r_write_enable = 1'b1;

            // stall = (((D_RDw == D_RS1) || (D_RDw == D_RS2)) && (D_RDw != 5'b00000))  ? 1'b1 : 1'b0; //haven't finished writing back yet but need in decode so stall
                
            end
            7'b0010011: begin //I type
                //i type has no func7 so we just make it 0
                //but the decoder already does that i think but we may need to add it here
                ALU_sel = {D_FUNCT7[5], D_FUNCT3}; //so this is func7_3
                Bsel = rs2MX_Bypass ? 2'b10 : 
                    rs2WX_Bypass ? 2'b11 : 2'b01; //take pipelined immediate otherwise use WX bypass  

                Asel = rs1MX_Bypass ? 2'b10 : 
                    rs1WX_Bypass ? 2'b11 : 2'b00; // take rs1 unless we need to bypass

                r_write_enable = 1'b1;
                
            //  stall = (((D_RDw == D_RS1) || (D_RDw == D_RS2)) && (D_RDw != 5'b00000))  ? 1'b1 : 1'b0; //haven't finished writing back yet but need in decode so stall
                
            end
            7'b0000011: begin //load    
                ALU_sel = 4'b0000; //ADD
                Bsel = 2'b01; //always taking the immediate
                Asel = 2'b00; //always taking rs1
                WB_sel = 2'b01; //data memory output
                r_write_enable = 1'b1;

                Asel = (rs1MX_Bypass) ? 2'b10 :
                    (rs1WX_Bypass) ? 2'b11 : 2'b00;
                Bsel = 2'b01;
                //load should never need to bypass for rs2 since its just a destination register
                // bc_Bsel = (rs2MX_Bypass) ? 2'b01 : 
                //           (rs2WX_Bypass) ? 2'b10 : 2'b00;

                
            //    stall = ( (D_RDx == D_RS1) || ((D_RDx == D_RS2) && (instm[6:0] != 7'b0100011)) ) ? 1'b1 : 1'b0; //stall if load-use hazard detected

            end
            7'b0100011: begin //store
                ALU_sel = 4'b0000; //ADD

                Bsel = 2'b01; //always taking the immediate
                Asel = rs1MX_Bypass ? 2'b10 : 
                    rs1WX_Bypass ? 2'b11 : 2'b00; // take rs1 unless we need to bypass



                MemRW = 1; //write to memory
                r_write_enable = 0; //no write back to register file
                DataW_sel = (wm_cond) ? 2'b00 : 2'b01; //wm bypass -> 
            // stall = ((D_RDx == D_RS1) || (D_RDx == D_RS2) ) ? 1'b1 : 1'b0; //stall if load-use hazard detected
                if((D_RDm == D_RS2) && (D_RDm != 5'b00000) && !wm_cond) begin
                    writeback_shadow_reg_enable = 1; //use WX bypass
                    DataW_sel = 2'b10;
            end
            end
            7'b1100011: begin //branch
                enable = 1'b1;
                ALU_sel = 4'b0000; //ADD
                Asel = 2'b01; //always taking pc
                Bsel = 2'b01; //always taking the immediate
                unsign_or_signed = D_FUNCT3[0]; //BrUN signal
                

                //Need to update control logic if we need to BYPASS (MX, WX)
                //typically 2'b00, 2'b10 if we have WX, 2'b01 if we have MX
                bc_Asel = (rs1MX_Bypass) ? 2'b01 :
                        (rs1WX_Bypass) ? 2'b10 : 2'b00;    
                
                bc_Bsel = (rs2MX_Bypass) ? 2'b01 : 
                        (rs2WX_Bypass) ? 2'b10 : 2'b00;

                
                //branch_taken_priority = jump_takenx ? 1'b0 : branch_taken; //from branch compare
                r_write_enable = 0; //no write back to register file


            end
            7'b1101111: begin //jal
                ALU_sel = 4'b0000; //ADD
                Bsel = 2'b01; //always taking the immediate
                Asel = 2'b01; //pc + 4
                WB_sel = 2'b10; //pc + 4
                jump_taken = branch_taken ? 1'b0 : 
                            jump_takenx ?   1'b0 : 1'b1; //pc mux select ; deals with back to back jals
                r_write_enable = 1'b1;
                
            end
            7'b1100111: begin //jalr
                ALU_sel = 4'b0000; //ADD
                Bsel = 2'b01; //always taking the immediate

                Asel = rs1MX_Bypass ? 2'b10 :
                    rs1WX_Bypass ? 2'b11 : 2'b00; // take rs1 unless we need to bypass 

                WB_sel = 2'b10; //pc + 4
                
                jump_taken = branch_taken ? 1'b0 : 
                            jump_takenx   ? 1'b0 : 1'b1; //pc mux select
                
                r_write_enable = 1'b1;
                crown = 1; 

            end
            7'b0010111: begin //auipc
                ALU_sel = 4'b0000; //ADD
                Bsel = 2'b01; //always taking the immediate
                Asel = 2'b01; //pc + imm
                r_write_enable = 1'b1;
            end
            7'b0110111: begin //lui
                ALU_sel = 4'b1111; //LUI
                Bsel = 2'b01; //always taking the immediate
                Asel = 2'b00; //pc + imm --> don't care
                r_write_enable = 1'b1; 
            end
            default: begin
                ALU_sel = 4'b0000; //default to ADD
                Bsel = 2'b00;
                Asel = 2'b00;
                MemRW = 0;
                WB_sel = 2'b00;
            end
        endcase

        //rs1
        if (stall_crit_rs1) begin
            stallrs1 = 1;
            if (rs1WX_Bypass || rs1MX_Bypass) begin
                stallrs1 = 0;
            end else begin
                stallrs1 = 1;
            end
        end else begin
            stallrs1 = 0;
        end 

        //rs2
        if (stall_crit_rs2) begin
            stallrs2 = 1;
            if (rs2WX_Bypass || rs2MX_Bypass || wm_cond) begin
                stallrs2 = 0;
            end else begin
                stallrs2 = 1;
            end
        end else begin
            stallrs2 = 0;
        end 


        // //if we have to stall either rs1 or rs2 then do not bypass, use stall instead. 
        // if (jump_taken && stall) begin
        //     stall = 0;
        // end else begin
        //     stall = 1;
        // end

        if (jump_takenx && (!crownx)) begin //JAL case, it takes priority
            stall = 1;
            imem_enable = 1'b1; //enable instruction memory during branch/jump stall PD6
            decode_enable_in = 1'b0; //disable decode during branch/jump stall
        end else if (stall_overload) begin
            stall = 0;    
        end else if (stallrs1 || stallrs2) begin
            stall = 1;
            // Asel = 2'b00;
            // Bsel = 2'b01;
            imem_enable = 1'b0; //enable instruction memory during branch/jump stall PD6
        end else if (branch_taken || (jump_takenx && crownx)) begin //branches and jalr same priority
            stall = (branch_taken || (jump_takenx && crownx)); 
            imem_enable = 1'b1; //enable instruction memory during branch/jump stall PD6
            decode_enable_in = 1'b0; //disable decode during branch/jump stall
        end else if (stall_crit_load_use) begin
            stall = 1;
            imem_enable = 1'b0; //enable instruction memory during branch/jump stall PD6
        end else begin
            stall = 0;
        end


        if (stall) begin
            data_rs1_in = 0;
            data_rs2_in = 0;
            D_IMM_in = 0;
            ALU_sel_in = 0;
            Asel_in = 2'b00; //mux select line default to datars1x
            Bsel_in = 2'b01; //mux select line default to imm = 0
            D_RD_in = 0;
            branch_taken_real_in = 0;
            r_write_enable_in = 1;   
            DataW_sel_in = 2'b01; //disable any bypassing for store data during stall 
            access_size_in = 2'b00; //default to byte access during stall
            //imem_enable = 0; //disable instruction memory during stall PD6
            //imem_enable_in = 0; //disable instruction memory during stall PD6
            MemRW_in = 0; //disable data memory during stall

        end else begin
            data_rs1_in = data_rs1;
            data_rs2_in = data_rs2;
            D_IMM_in = D_IMM;
            ALU_sel_in = ALU_sel;
            Asel_in = Aselx;
            Bsel_in = Bselx;
            D_RD_in = D_RD;
            branch_taken_real_in = branch_taken_real;
            r_write_enable_in = r_write_enable;
            DataW_sel_in = DataW_sel;
            access_size_in = access_size;
            imem_enable_in = imem_enable; //enable instruction memory during normal operation PD6
            MemRW_in = MemRW;
        end     

    end
end


always @(posedge clock) begin //PIPELINING LOGIC
    if (reset) begin
        PC_fetch <= 32'h01000000;
        imem_enabled <= 0;

        Aselx <= 0;
        Bselx <= 0;
        

    end else begin
        
        //Stage 1: F/D
        if (stall) begin
            // imem_enabled <= imem_enable_in;

            PC_fetch <= PC_fetch; //hold pc value
            instd <= instd; // value was instd but i think what we want to do is set it as 0; //hold instruction in F/D pipeline reg
            PC_fetchd <= PC_fetchd; //hold F/D pipeline reg
            //imem_enable <= imem_enable_in; //PD6, shoulnt make a difference putting this here but yea 
            
            D_RDx <= D_RD_in; //destination reg
            ALU_selx <= ALU_sel_in;
            Aselx <= Asel_in;
            Bselx <= Bsel_in;
            branch_taken_realx <= branch_taken_real_in;
            r_write_enablex <= r_write_enable_in; // NOT THE FIX WE NEED 
            DataW_selx <= DataW_sel_in;
            enablex <= 0;
            access_sizex <= access_size_in;
            MemRWx <= MemRW_in;
            
            if(branch_taken || jump_takenx) begin
                PC_fetch <= alu_result; //potentially cutting this does nothing cause there is a mux doing the same thing
                PC_fetchd <= 0;;
                instd <= 32'b00000000000000000000000000010011;   //PD6, this is used to insert a NOP instruction during a branch or jump stall
                // Aselx <= 2'b00;
                // Bselx <= 2'b01;
            end

        end else begin

            //regular pipeline flow
            PC_fetch <= PC_next;
            PC_fetchd <= PC_fetch; //AUIPC CHANGE, THIS IS
            // instx <= data_out; //AUIPC CHANGE, THIS IS ORIGINAL
            
            D_RDx <= D_RD_in; //destination reg
            ALU_selx <= ALU_sel;
            Aselx <= Asel;
            Bselx <= Bsel; //AUIPC CHANGE THIS WAS HERE BEFORE 
            branch_taken_realx <= branch_taken_real;
            r_write_enablex <= r_write_enable;
            DataW_selx <= DataW_sel;
            enablex <= enable;
            crownx <= crown;
            MemRWx <= MemRW;
            
        end

        imem_enabled <= imem_enable;

        //Stage 2: D/X 
        PC_fetchx <= PC_fetchd;
        decode_enable <= decode_enable_in;
        
        D_FUNCT3x <= D_FUNCT3; 
        D_IMMx <= D_IMM_in; //A CHANGE I MADE FOR THE AUIPC THING, BUT THIS IS THE ORIGINAL ONE BEFORE 
        
        //data_rs1x <= data_rs1_in; // A CHANGE I MADE FOR THE AUIPC BUT THIS IS THE ORIGINAL
        //data_rs2x <= data_rs2_in;


        //DMEM Signals
        //MemRWx <= MemRW; 
        access_sizex <= access_size_in;
        DataW_selx <= DataW_sel_in;

        clockcoutner <= clockcoutner + 1;


        // DataW_selx <= 1; //disable any bypassing for store data during stall

        //contents from register file        
        DataW_selm <= DataW_selx;
        DataW_selw <= DataW_selm;

        //Stage 2 control signals 
       
        ALU_selx <= ALU_sel;
        bc_Aselx <= bc_Asel;
        bc_Bselx <= bc_Bsel;
        jump_takenx <= (stall && crown) ? 0 : jump_taken; //we need to pipeline jump taken so that JAL and JALR function properly
        branch_taken_realx <= branch_taken_real;
    
        WB_selx <= WB_sel;
        // r_write_enablex <= r_write_enable_in;
        instx <= data_out;

        //Stage 3: X/M
        PC_fetchm <= PC_fetchx;
        instm <= instx;
        D_RDm <= D_RDx;
        D_FUNCT3m <= D_FUNCT3x;

        alu_resultm <= alu_result;
        branch_takenm <= branch_taken;
        
        data_rs2m <= data_rs2;

        //Stage 3 control signals 
        MemRWm <= MemRWx; 
        access_sizem <= access_sizex;
        WB_selm <= WB_selx;

        r_write_enablem <= r_write_enablex;

        //Stage 4: M/W
        PC_fetchw <= PC_fetchm;
        instw <= instm;
        alu_resultw <= alu_resultm;


        D_RDw <= D_RDm;
        wb_data_reg <= wb_data; // write_back_data is only valid once we are in the Memory stage
        // writeback_shadow_reg <= wb_data_reg; wb_data_reg becomes the shadow reg
        D_FUNCT3m_delay <= D_FUNCT3m; //pipeline D_FUNCT3m to be used in loadster
        //Stage 4: Control Signals:
        WB_selw <= WB_selm; // choose which value goes through the writeback stage
        r_write_enablew <= r_write_enablem;
        
    end
end

endmodule