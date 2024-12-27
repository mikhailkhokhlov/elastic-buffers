module skid_buffer #(parameter DWIDTH = 8)
                    (input                   i_clock,
                     input                   i_reset,
                     input  [(DWIDTH - 1):0] i_data,
                     input                   i_data_valid,
                     output                  o_data_ready,
                     output [(DWIDTH - 1):0] o_data,
                     output                  o_data_valid,
                     input                   i_data_ready);

  localparam BYPASS = 0;
  localparam SKID   = 1;

  reg [(DWIDTH - 1):0] reg_data;
  reg [(DWIDTH - 1):0] next_data;

  reg                  reg_data_ready;
  reg                  next_data_ready;

  reg                  reg_state;
  reg                  next_state;

  wire                 stall;
  wire                 hand_shake;

  assign hand_shake = ( i_data_valid  & reg_data_ready );
  assign stall      = ( !i_data_ready & hand_shake     );

  always @(posedge i_clock, posedge i_reset)
    if (i_reset)
      reg_state <= BYPASS;
    else
      reg_state <= next_state;

  always @(*)
    case (reg_state)
      BYPASS: next_state = ( stall        ) ? SKID   : reg_state ;
      SKID:   next_state = ( i_data_ready ) ? BYPASS : reg_state ;
    endcase

  always @(posedge i_clock, posedge i_reset)
    if (i_reset)
      begin
        reg_data       <= {DWIDTH{1'b0}};
        reg_data_ready <= 1'b0;
      end
    else
      begin
        reg_data       <= next_data;
        reg_data_ready <= next_data_ready;
      end

  always @(*)
    case (reg_state)
      BYPASS: begin
        next_data       = ( stall ) ? i_data : {DWIDTH{1'b0}} ;
        next_data_ready = ( stall ) ? 1'b0   : 1'b1           ;
      end
      SKID: begin
        next_data       = reg_data;
        next_data_ready = ( i_data_ready ) ? 1'b1 : reg_data_ready ;
      end
    endcase

  assign o_data_ready = reg_data_ready;
  assign o_data_valid = ( reg_state == BYPASS ) ? hand_shake : 1'b1     ;
  assign o_data       = ( reg_state == BYPASS ) ? i_data     : reg_data ;

endmodule
