`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sanidhya Saxena
// 
// Create Date: 13.08.2024 23:15:18
// Design Name: 
// Module Name: tb_System
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_System(
    );
    
    parameter DSIZE = 8;
    parameter ASIZE = 4;
    
    reg clk_a,clk_b,reset;
    reg [DSIZE-1:0] wdata;
    reg w_valid,r_valid;
    wire wfull,rempty;
    wire [DSIZE-1:0] rdata;
    reg low_power_req_i;
    wire wr_flush_o;
    reg wr_done_i;
    wire fifo_empty,fifo_full;
    reg if_wakeup_i;
    wire qreqn,qactive,qacceptn;
    wire device_icg_enable;
    
    System_top DUT (
        .clk_a(clk_device), // Clock for Device 
        .clk_b(clk_b), // Clock for controller 
        .reset(reset), // Active high reset
        .if_wakeup_i(if_wakeup_i), // Async Signl for wakeup
        .wr_payload_i(wdata), // 8-bit Write data payload
        .wr_valid_i(w_valid), // Write valid signal 
        .fifo_full(fifo_full), // Write FIFO full signal
        .wr_flush_o(wr_flush_o), // FIFO Flush to read side 
        .wr_done_i(wr_done_i), // FIFO done signal 
        .rd_payload_o(rdata), // 8-bit Read data 
        .rd_valid_i(r_valid), // Read valid 
        .fifo_empty(fifo_empty),
        .device_icg_enable(device_icg_enable),
        .qreqn(qreqn),
        .qactive(qactive),
        .qacceptn(qacceptn),
        .low_power_req_i(low_power_req_i)
    ); 
    
  // 2 Asynchornous clocks   
  always #10 clk_a = ~clk_a;
  always #10 clk_b = ~clk_b;
  
  assign clk_device = (clk_a & device_icg_enable );
  //always #35 rclk = ~rclk;
  
  
  reg [DSIZE-1:0] wdata_q[$], din;
  
  //-----CLOCK INIT FOR CONTROLLER
  initial begin
  clk_b = 0;
  end
  
  //-----CLOCK INIT FOR DEVICE
  initial begin
  clk_a = 0;
  reset=1;
  repeat(10) @(posedge clk_a);
  reset=0;
  end
  
  // Asynchronous Wakeup signal Drive from Enviroment 
  initial begin
    if_wakeup_i = 1'b0;
    repeat(30) @(posedge clk_a);
    if_wakeup_i= 1'b1;
  end
  
  // -------------------Write Master side Control and Data
  initial begin
    w_valid = 1'b0;
    wdata = 0;
    
    repeat(10) @(posedge clk_a);
    
    repeat(5) begin
        @(posedge clk_a);
        #2 w_valid = 1'b1;
        if (w_valid & ~fifo_full) begin
            wdata = $urandom;
            //wdata_q.push_back(wdata);
        end 
    end
    #2 w_valid = 1'b0;
    
    @(posedge clk_a);
    low_power_req_i = 1'b1;
    
    @(posedge clk_a);
    low_power_req_i = 1'b0;
    
  end
  
  always @(posedge clk_a or posedge reset) begin
    if(w_valid) wdata_q.push_back(wdata);
  end
  
  // Write Done geneeration Logic 
  always @(posedge clk_a or posedge reset) begin
    if(reset) wr_done_i <= 1'b0;
    else begin
        if(wr_flush_o) wr_done_i <= 1'b1;
        else if(qreqn) wr_done_i <= 1'b0;
    end
  end
  
  // Read Slave side control and Data siganals
  always @(posedge clk_a or posedge reset) begin
    if(reset) r_valid <= 1'b0;
    else if(wr_done_i && ~fifo_empty) begin
         r_valid <= 1'b1;
         din <= wdata_q.pop_front();
    end
    else r_valid <= 1'b0;
  end

    //--------------FIFO TESTING CODE----------------------
  /*initial 
  fork
      begin
        w_valid = 1'b0;
        wdata = 0;
    
        repeat(2) begin
          for (int i=0; i<30; i++) begin
            @(posedge clk_a iff !wfull);
            w_valid = (i%2 == 0)? 1'b1 : 1'b0;
            if (w_valid) begin
              wdata = $urandom;
              wdata_q.push_back(wdata);
            end
          end
          #50;
        end
      end
        begin
        
        r_valid = 1'b0;

        repeat(2) begin
          for (int i=0; i<30; i++) begin
            @(posedge clk_a iff !rempty);
            r_valid = (i%2 == 0)? 1'b1 : 1'b0;
            if (r_valid) begin
              din = wdata_q.pop_front();
              if(rdata !== din) $error("Time = %0t: Comparison Failed: expected wr_data = %h, rd_data = %h", $time, din, rdata);
              else $display("Time = %0t: Comparison Passed: wr_data = %h and rd_data = %h",$time, din, rdata);
            end
          end
          #50;
        end
    
        $finish;
      end      
  join*/
 
endmodule
