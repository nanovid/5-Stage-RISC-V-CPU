module loadster #()
(
    input wire clock,
    input wire reset,
    input wire [31:0] dmem_data_out,
    input wire [2:0] D_FUNCT3,
    output reg [31:0] data_out
);

    always @(*) begin
        case(D_FUNCT3)
            3'b000: begin //LB
                data_out = {{24{dmem_data_out[7]}}, dmem_data_out[7:0]}; //sign extend
            end
            3'b001: begin //LH
                data_out = {{16{dmem_data_out[15]}}, dmem_data_out[15:0]}; //sign extend
            end
            3'b010: begin //LW
                data_out = dmem_data_out; //no extension needed
            end
            3'b100: begin //LBU
                data_out = {24'b0, dmem_data_out[7:0]}; //zero extend
            end
            3'b101: begin //LHU
                data_out = {16'b0, dmem_data_out[15:0]}; //zero extend
            end
            default: data_out = dmem_data_out; //default case
        endcase
    end

endmodule