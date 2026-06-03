module dmemory #()
(
    input wire clock,
    input wire [31:0] address,
    input wire [31:0] data_in, 
    input wire read_write, 
    input wire [1:0] access_size,
    output reg [31:0] data_out
);

//we will have sequential writes and combinational reads
//how do we know if we should be reading or writing?
//read_write = 0 means read
//read_write = 1 means write
//access_size = 3'b000 means byte
//access_size = 3'b001 means halfword
//access_size = 3'b010 means word

reg [7:0] memory [`MEM_DEPTH:0]; // memory array for instructions, 8 bits cause byte addressable
reg [31:0] base_address = 32'h01000000;
reg [31:0] temp_mem [`LINE_COUNT:0];
reg [31:0] arr [`LINE_COUNT:0]; // arr
reg [31:0] PC;
integer i; //exclusive for the loop


initial begin
    $readmemh(`MEM_PATH, arr); //so now array contains everything we need but not in memory yet

    for(i=0; i < `LINE_COUNT; i = i+1) begin //loop through the depth of the x file
        memory[base_address + i*4 + 0] = arr[i][7:0]; //first 8 bits are stored in memory byte address 0
        memory[base_address + i*4 + 1] = arr[i][15:8]; //next 8 bits in the seocond byte address
        memory[base_address + i*4 + 2] = arr[i][23:16]; //so on 
        memory[base_address + i*4 + 3] = arr[i][31:24]; //so forth
        //$display("memory[%h] = %h", base_address + i*4, arr[i]);
    end
end

//that sjould be all thats needed for the writes, but i am worried that
//since we havent really pipelined anything yet, we might have issues with
//writes being sequential and reads being combinational
always @(posedge clock) begin
    
    if (read_write == 1) begin
        case(access_size)
            2'b00: begin //we access byte
                memory[address + 0] <= data_in[7:0];
            end
            2'b01: begin //lets do halfword
                memory[address + 0] <= data_in[7:0];
                memory[address + 1] <= data_in[15:8];
            end
            2'b10: begin //word dat
                memory[address + 0] <= data_in[7:0];
                memory[address + 1] <= data_in[15:8];
                memory[address + 2] <= data_in[23:16];
                memory[address + 3] <= data_in[31:24];
            end
            default: begin
            end
        endcase
    end
end

always @(*) begin
    if (read_write == 0) begin //now we are reading, which is all combo
        data_out = {memory[address + 3], memory[address + 2], memory[address + 1], memory[address + 0]}; //is concatination
    end else begin
        data_out = 32'b0; //if we are writing, output 0
    end
end

endmodule
