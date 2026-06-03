/**
* Exercise 3.4
* you can change the code below freely
  * */
module reg_and_reg(
  input  wire clock,
  input  wire reset,
  input  wire x,
  input  wire y,
  output reg  z
);

reg reg_x;
reg reg_y;

// assign_and assign_and_reg(
//   .x(x), 
//   .y(y),
//   .z(z)
// )

always @(posedge clock) begin

  if(reset) begin
    reg_x <= 1'b0;
    reg_y <= 1'b0;
    z <= 1'b0;
  
  end else begin

    reg_x <= x;
    reg_y <= y;
    z <= reg_x & reg_y;

end
end

endmodule
