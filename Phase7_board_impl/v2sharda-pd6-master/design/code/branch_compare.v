module branch_compare #()
(
 input wire clock,
 input wire enable,
 input wire [31:0] A, 
 input wire [31:0] B,
 input wire [2:0] BrUN, //funct3 from decode
 output reg BrEq,
 output reg BrLT,
 output reg branch_taken
);

reg signed_or_unsigned;


always @(*) begin
    
    BrEq            = 1'b0;
    BrLT            = 1'b0;
    branch_taken    = 1'b0;
    signed_or_unsigned = 1'b0;

    if (enable) begin
        if (BrUN == 3'b110 || BrUN == 3'b111) begin
            signed_or_unsigned = 1'b1; //unsigned
        end else begin
            signed_or_unsigned = 1'b0; //signed
        end

        BrEq = (A == B) ? 1:0; //set BrEq if A == B 
        
        if (signed_or_unsigned) begin
            BrLT = (A < B) ? 1:0; //unsigned comparison
        end else begin
            BrLT = ($signed(A) < $signed(B)) ? 1:0; //signed comparison
        end

        if (BrUN == 3'b000) begin
            branch_taken = BrEq; //BEQ
        end else if (BrUN == 3'b001) begin
            branch_taken = ~BrEq; //BNE
        end else if (BrUN == 3'b100) begin
            branch_taken = BrLT; //BLT
        end else if (BrUN == 3'b101) begin
            branch_taken = ~BrLT; //BGE
        end else if (BrUN == 3'b110) begin
            branch_taken = BrLT; //BLTU
        end else if (BrUN == 3'b111) begin
            branch_taken = ~BrLT; //BGEU
        end else begin
            branch_taken = 1'b0; //default case, should not happen
        end
    end 
end





endmodule