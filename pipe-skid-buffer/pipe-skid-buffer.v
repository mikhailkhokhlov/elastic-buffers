module pipe_skid_buffer #(parameter DWIDTH = 8)
                         (input                   i_clock,
                          input                   i_reset,
                          input  [(DWIDTH - 1):0] i_data,
                          input                   i_data_valid,
                          output                  o_data_ready,
                          output [(DWIDTH - 1):0] o_data,
                          output                  o_data_valid,
                          input                   i_data_ready);

  localparam PIPE = 0;
  localparam SKID = 1;

  reg [(DWIDTH - 1):0] reg_temp_data;
  reg [(DWIDTH - 1):0] next_temp_data;

  reg                  reg_temp_data_valid;
  reg                  next_temp_data_valid;

  reg [(DWIDTH - 1):0] reg_data;
  reg [(DWIDTH - 1):0] next_data;

  reg                  reg_data_valid;
  reg                  next_data_valid;

  reg                  reg_data_ready;
  reg                  next_data_ready;

  reg                  reg_state;
  reg                  next_state;

  wire                 upstream_ready;

  always @(posedge i_clock, posedge i_reset)
    if (i_reset)
      begin
        reg_data            <= {DWIDTH{1'b0}} ;
        reg_data_valid      <= 1'b0           ;
        reg_temp_data       <= {DWIDTH{1'b0}} ;
        reg_temp_data_valid <= 1'b0           ;
        reg_data_ready      <= 1'b0           ;
        reg_state           <= 1'b0           ;
      end
    else
      begin
        reg_data            <= next_data            ;
        reg_data_valid      <= next_data_valid      ;
        reg_temp_data       <= next_temp_data       ;
        reg_temp_data_valid <= next_temp_data_valid ;
        reg_data_ready      <= next_data_ready      ;
        reg_state           <= next_state           ;
      end

  assign upstream_ready = i_data_ready | ~reg_data_valid;

  always @(*)
    next_state = (upstream_ready) ? PIPE : SKID;

  always @(*)
    case (reg_state)
      PIPE:
        begin
          next_data            = (upstream_ready)  ? i_data       : reg_data       ;
          next_data_valid      = (upstream_ready)  ? i_data_valid : reg_data_valid ;
          next_data_ready      = (upstream_ready)  ? 1'b1         : 1'b0           ;
          next_temp_data       = (~upstream_ready) ? i_data       : {DWIDTH{1'b0}} ;
          next_temp_data_valid = (~upstream_ready) ? i_data_valid : 1'b0           ;
        end
      SKID:
        begin
          next_data            = (upstream_ready)  ? reg_temp_data       : reg_data       ;
          next_data_valid      = (upstream_ready)  ? reg_temp_data_valid : reg_data_valid ;
          next_data_ready      = (upstream_ready)  ? 1'b1                : reg_data_ready ;
          next_temp_data       = reg_temp_data                                            ;
          next_temp_data_valid = reg_temp_data_valid                                      ;
        end
    endcase

  assign o_data_ready = reg_data_ready ;
  assign o_data_valid = reg_data_valid ;
  assign o_data       = reg_data       ;

endmodule
