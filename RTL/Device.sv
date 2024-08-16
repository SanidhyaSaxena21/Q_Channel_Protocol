module Device (
  input   logic          clk,
  input   logic          reset,

  // Wakeup interface
  input   logic          if_wakeup_i,

  // Write interface
  input   logic          wr_valid_i,
  input   logic [7:0]    wr_payload_i,

  // Upstream flush interface
  output  logic          wr_flush_o,
  input   logic          wr_done_i,
  output  logic          fifo_full,

  // Read interface
  input   logic          rd_valid_i,
  output  logic [7:0]    rd_payload_o,
  output  logic          fifo_empty,

  // Q-channel interface
  input   logic          qreqn_i,
  output  logic          qacceptn_o,
  output  logic          qactive_o

);

 wire qreqn;
 
 dff2_sync #(.RESET_VAL(1)) sync_qreq (
    .clk(clk),
    .reset(reset),
    .async(qreqn_i),
    .sync(qreqn)
    );
  // Write your logic here
  typedef enum {Q_RUN, Q_REQUEST, Q_STOPPED, Q_EXIT  } state_t;
  state_t next_state;
  state_t present_state;
  logic qaccept_q;
  logic nxt_qaccept;
  logic qactive_q;
  logic qenable;

  FIFO_TOP  #(.DSIZE(8), .ASIZE(6)) data_fifo (
      .wclk(clk),
      .wrst_n(!reset),
      .w_valid(wr_valid_i),
      .wdata(wr_payload_i),
      .rclk(clk),
      .rrst_n(!reset),
      .r_valid(rd_valid_i),
      .rdata(rd_payload_o),
      .rempty(fifo_empty),
      .wfull(fifo_full)

  );


  // qactive signal generation
  assign qactive_o = if_wakeup_i | qactive_q ;

  always_ff @( posedge clk or posedge reset ) begin
    if(reset)
      qactive_q <= 1'b0;
    else 
      qactive_q <= (wr_valid_i | ~fifo_empty | rd_valid_i);
  end



  // wr_flush_o signal logic 
  always_ff @( posedge clk or posedge reset ) begin : WRITE_FLUSH
    if(reset)
      wr_flush_o <= 1'b0;
    else begin
      if( !qreqn && !wr_flush_o) wr_flush_o <= 1'b1;
      if(wr_done_i) wr_flush_o <= 1'b0;
    end
    
  end

  // Low power State Machine logic
  always_ff @( posedge clk or posedge reset ) begin : PS_LOGIC
    if(reset)
      present_state <= Q_RUN;
    else
      present_state <= next_state;
    
  end

  always_comb begin : NS_LOGIC
    case (present_state)
      Q_RUN: if(qreqn == 1'b0) next_state = Q_REQUEST;
      Q_REQUEST: if(qacceptn_o == 1'b0) next_state= Q_STOPPED;
      Q_STOPPED: if(qreqn == 1'b1) next_state = Q_EXIT;
      Q_EXIT: if(qacceptn_o == 1'b1) next_state = Q_RUN;
      default: next_state = Q_RUN;
    endcase
  end

// QACCEPT Logic 
  assign qenable = (present_state == Q_REQUEST) | (present_state == Q_EXIT);
  assign nxt_qaccept = ~( fifo_empty & wr_done_i & ~qreqn ) ; 

  always_ff @( posedge clk or posedge reset ) begin : QACCEPT_FLOP
    if(reset)
      qaccept_q <= 1'b1;
    else if(qenable)
      qaccept_q <= nxt_qaccept;
    
  end

  assign qacceptn_o = qaccept_q;

endmodule 
