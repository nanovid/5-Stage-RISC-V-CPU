module mux31 (
    input wire [1:0] sel,
    input wire [31:0] in0,
    input wire [31:0] in1,
    input wire [31:0] in2,
    output reg [31:0] out
);


always @(*) begin
    case(sel)
        2'b00: out = in0;
        2'b01: out = in1;
        2'b10: out = in2;
        default: out = in0; //default case
    endcase
end

endmodule