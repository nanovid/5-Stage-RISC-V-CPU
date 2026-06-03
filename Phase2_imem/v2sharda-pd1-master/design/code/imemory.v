module imemory #()
(
    input wire clock,
    input wire [31:0] address,
    input wire [31:0] data_in, 
    input wire read_write, 
    output reg [31:0] data_out

);

//registers that we need for the memory operation to happen
reg [7:0] memory [`MEM_DEPTH:0]; // memory array that we can access, and only 8 bits cause its byte accessesable
reg [31:0] temp_mem [`LINE_COUNT:0];
reg [31:0] arr [`LINE_COUNT:0]; // arr
reg [31:0] PC;
reg [31:0] base_address = 32'h01000000;
integer i; //exclusive for the loop

//assign base_address = 32'h01000000; //base address for the memory



initial begin
    $readmemh(`MEM_PATH, arr); //so now array contains everything we need but not in memory yet

    for(i=0; i < `LINE_COUNT; i = i+1) begin //loop through the depth of the x file
        memory[base_address + i*4 + 0] = arr[i][7:0]; //first 8 bits are stored in memory byte address 0
        memory[base_address + i*4 + 1] = arr[i][15:8]; //next 8 bits in the seocond byte address
        memory[base_address + i*4 + 2] = arr[i][23:16]; //so on 
        memory[base_address + i*4 + 3] = arr[i][31:24]; //so forth
        $display("memory[%h] = %h", base_address + i*4, arr[i]);
    end
end

//what have you?

always @(posedge clock) begin
    //$display(memory[0]);

    if (read_write==1) begin //so here we are gonna be writing. 
        memory[address + 0] <= data_in[7:0];
        memory[address + 1] <= data_in[15:8];
        memory[address + 2] <= data_in[23:16];
        memory[address + 3] <= data_in[31:24];
    end 
    
end

//error log was complaining cause blocking in sequential is a big nono, google suggested always *, wanna try assign later 
always @(*) begin
    if (read_write==0) begin //reading //now we have to do an instant read??? how do i make it combinational logic?
        data_out = {memory[address + 3], memory[address + 2], memory[address + 1], memory[address + 0]}; //is concatination
    end else begin
        data_out = 32'b0; //if we are writing, output 0
    end
end

endmodule
