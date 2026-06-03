
/* Your Code Below! Enable the following define's 
 * and replace ??? with actual wires */
// ----- signals -----
// You will also need to define PC properly
`define F_PC                PC_fetch
`define F_INSN              data_out

`define D_PC                PC_fetchd
`define D_OPCODE            D_OPCODE
`define D_RD                D_RD
`define D_RS1               D_RS1
`define D_RS2               D_RS2
`define D_FUNCT3            D_FUNCT3
`define D_FUNCT7            D_FUNCT7 
`define D_IMM               D_IMM
`define D_SHAMT             D_SHAMT

`define R_WRITE_ENABLE      r_write_enable
`define R_WRITE_DESTINATION D_RD
`define R_WRITE_DATA        alu_result
`define R_READ_RS1          D_RS1
`define R_READ_RS2          D_RS2
`define R_READ_RS1_DATA     data_rs1
`define R_READ_RS2_DATA     data_rs2

`define E_PC                PC_fetchx
`define E_ALU_RES           alu_result
`define E_BR_TAKEN          branch_taken

`define M_PC                PC_fetchm
`define M_ADDRESS           alu_resultm
`define M_RW                MemRWm
`define M_SIZE_ENCODED      access_sizem
`define M_DATA              data_W

`define W_PC                PC_fetchw
`define W_ENABLE            r_write_enablew
`define W_DESTINATION       D_RDw
`define W_DATA              wb_data_reg

// ----- signals -----

// ----- design -----
`define TOP_MODULE                 pd
// ----- design -----
