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

imemory imem(
    .clock(clock),
    .address(PC_fetch),
    .data_in(data_in),
    .read_write(read_write),
    .data_out(data_out)
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
