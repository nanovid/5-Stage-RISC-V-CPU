module pd0(
  input clock,
  input reset
);
  /* demonstrating the usage of assign_and */
  reg assign_and_x;
  reg assign_and_y;
  wire assign_and_z;
  assign_and assign_and_0 (
    .x(assign_and_x),
    .y(assign_and_y),
    .z(assign_and_z)
  );

  /* Exercise 3.3 module/probes */

  reg reg_and_arst_areset;
  reg reg_and_arst_x;
  reg reg_and_arst_y;
  wire reg_and_arst_z;


  reg_and_arst reg_and_arst_0 (
    .clock(clock),
    .areset(reg_and_arst_areset),
    .x(reg_and_arst_x),
    .y(reg_and_arst_y),
    .z(reg_and_arst_z)
  );


  /* Exercise 3.4 module/probes */

  reg reg_and_reg_reset;
  reg reg_and_reg_x;
  reg reg_and_reg_y;
  wire reg_and_reg_z;

  reg_and_reg reg_and_reg_0 (
    .clock(clock),
    .reset(reg_and_reg_reset),
    .x(reg_and_reg_x),
    .y(reg_and_reg_y),
    .z(reg_and_reg_z)

  );
  
endmodule
