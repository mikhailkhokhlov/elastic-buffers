`timescale 1ns/1ps

interface sk_buffer_if #(parameter DWIDTH = 8)
                        (input logic clock,
                         input logic reset);

  logic [(DWIDTH - 1):0] input_data;
  logic                  input_data_valid;
  logic                  input_data_ready;
  logic [(DWIDTH - 1):0] output_data;
  logic                  output_data_valid;
  logic                  output_data_ready;

  clocking cb @(posedge clock);

    output input_data;
    output input_data_valid;
    input  input_data_ready;

    input  output_data;
    input  output_data_valid;
    output output_data_ready;

  endclocking

  modport TEST(clocking cb,
               input reset);

endinterface

program sk_test #(parameter DWIDTH = 8,
                  parameter COUNT  = 100)
                 (sk_buffer_if.TEST skb_if);

  logic [(DWIDTH - 1):0] in_monitor_data;
  logic [(DWIDTH - 1):0] out_monitor_data;

  int                    in_valid_delay;
  logic                  out_ready;

  logic                  input_valid_prev;
  logic [(DWIDTH - 1):0] input_data_prev;

  logic                  output_ready_prev;

  mailbox                in_mbx = new();
  mailbox                out_mbx = new();

  // drive input
  initial begin
    @(negedge skb_if.reset);
    @skb_if.cb;

    for (int i = 0; i < COUNT; i++)
      begin
        assert(std::randomize(in_valid_delay) with {
          in_valid_delay dist { 0:/30, [1:3]:/70 };
        }) else begin
          $fatal("FAIL randomize valid delay");
          $finish();
        end

        skb_if.cb.input_data_valid <= 1'b0;
        skb_if.cb.input_data       <= {DWIDTH{1'b0}};

        repeat (in_valid_delay) @(skb_if.cb);

        skb_if.cb.input_data       <= $urandom_range(0, 2**DWIDTH);
        skb_if.cb.input_data_valid <= 1'b1;

        do
          @skb_if.cb;
        while(~skb_if.cb.input_data_ready);
      end
  end

  // monitor input
  initial begin
    @(negedge skb_if.reset);
    @skb_if.cb;

    $display("[%0t] start input monitor", $time);

    forever begin
      input_valid_prev = skb_if.cb.input_data_valid;
      input_data_prev  = skb_if.cb.input_data;

      @skb_if.cb;

      if (input_valid_prev & skb_if.cb.input_data_ready) begin
        in_mbx.put(input_data_prev);
      end
    end
  end

  // drive output
  initial begin
    @(negedge skb_if.reset);
    @skb_if.cb;

    forever begin
      assert(std::randomize(out_ready) with {
        out_ready dist { 0:/50, 1:/50 }; 
      }) else begin
        $fatal("FAIL randomize ready delay");
        $finish();
      end

      skb_if.cb.output_data_ready <= out_ready;
      @skb_if.cb;
    end
  end

  // monitor output
  initial begin
    @(negedge skb_if.reset);
    @skb_if.cb;
    $display("[%0t] start output monitor", $time);

    forever begin
      output_ready_prev = skb_if.cb.output_data_ready;

      @skb_if.cb;

      if (skb_if.cb.output_data_valid & output_ready_prev) begin
        out_mbx.put(skb_if.cb.output_data);
      end
    end
  end

  // compare inputs and outputs
  initial begin
    @(negedge skb_if.reset);
    @skb_if.cb;

    for (int i = 0; i < COUNT; i++)
      begin
        in_mbx.get(in_monitor_data);
        out_mbx.get(out_monitor_data);

        if (in_monitor_data == out_monitor_data)
          $display("[%0t][%02d] SUCCESS: Slave input data: 0x%02x, Master output data: 0x%02x",
                   $time(), i, in_monitor_data, out_monitor_data);
        else begin
          $error("[%0t][%02d] FAIL: Slave input data 0x%02x not equal to Master output data 0x%02x",
                 $time(), i, out_monitor_data, in_monitor_data);
          $stop;
        end
      end

    $stop();
  end

endprogram

module testbench();

  localparam DWIDTH = 8;

  logic clock;
  logic reset;

  // test clock
  initial begin
    clock = 0;
    forever
      #5 clock = ~clock;
  end

  // test reset
  initial begin
    reset = 1'b0;
    #12 reset = 1'b1;
    $display("[%0t] reset begin", $time);
    #12 reset = 1'b0;
    $display("[%0t] reset end", $time);
  end

  // reset DUT inputs
  initial begin
    skb_if.input_data        = {DWIDTH{1'b0}};
    skb_if.input_data_valid  = 1'b0;
    skb_if.output_data_ready = 1'b0;
  end

  sk_buffer_if skb_if(clock, reset);

  sk_test tb(skb_if);

`ifdef RTL1
    skid_buffer dut(.i_clock      ( clock                    ),
                    .i_reset      ( reset                    ),
                    .i_data       ( skb_if.input_data        ),
                    .i_data_valid ( skb_if.input_data_valid  ),
                    .o_data_ready ( skb_if.input_data_ready  ),
                    .o_data       ( skb_if.output_data       ),
                    .o_data_valid ( skb_if.output_data_valid ),
                    .i_data_ready ( skb_if.output_data_ready ));
`elsif RTL2
    pipe_skid_buffer dut(.i_clock      ( clock                    ),
                         .i_reset      ( reset                    ),
                         .i_data       ( skb_if.input_data        ),
                         .i_data_valid ( skb_if.input_data_valid  ),
                         .o_data_ready ( skb_if.input_data_ready  ),
                         .o_data       ( skb_if.output_data       ),
                         .o_data_valid ( skb_if.output_data_valid ),
                         .i_data_ready ( skb_if.output_data_ready ));
`else
    $error("DUT is not defined");
`endif

endmodule
