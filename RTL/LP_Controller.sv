`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2024 22:41:58
// Design Name: 
// Module Name: LP_Controller
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


module LP_Controller (
    input clock,
    input reset,
    input qacceptn_i,
    input qactive_i,
    input low_power_req_i,
    output reg device_icg_enable,
    output qreq_n_o
);
 
 wire qaccept_n;
 wire qactive;
 dff2_sync #(.RESET_VAL(1)) sync_qctive (
    .clk(clock),
    .reset(reset),
    .async(qacceptn_i),
    .sync(qaccept_n)
    );
    
 dff2_sync #(.RESET_VAL(0)) sync_qaccept (
    .clk(clock),
    .reset(reset),
    .async(qactive_i),
    .sync(qactive)
    );
        
typedef enum {Q_RUN,Q_REQUEST,Q_STOPPED,Q_EXIT } state_t;
state_t present_state;
state_t next_state;
logic q_req;
logic q_req_next;
logic q_req_enable;

always_ff @( posedge clock or posedge reset ) begin : STATE_LOGIC
    if(reset)
        present_state <= Q_RUN;
    else
        present_state <= next_state;
end

always_comb begin : NS_LOGIC
    case (present_state)
        Q_RUN: if(!qreq_n_o) next_state = Q_REQUEST;
        Q_REQUEST: if(!qaccept_n) next_state = Q_STOPPED;
        Q_STOPPED: if(qreq_n_o) next_state = Q_EXIT;
        Q_EXIT: if(qaccept_n) next_state = Q_RUN;
        default: next_state = Q_RUN;
    endcase
end


// QREQ_N Generation logic
// q_req_n can from HIGH TO LOW in Q_RUN STATE (q_acceptn is high)
// q_req_n can from LOW TO HIGH in Q-STROPPED or Q_REQUEST STATE 

// Counter Logic to check whether Active is high for more than 5 cycles

//------------------------------------------------------------------------------------------------------------
logic [2:0] count_active;
logic up_active_signal;
logic up_flag;

always_ff @( posedge clock or posedge reset ) begin : Active_Counter
    if(reset) begin
        count_active <= 3'd0;
    end
    else begin
        if(count_active == 3'd5) begin 
            count_active <= 3'd0;
        end
        else if(qactive & !up_flag) begin 
            count_active <= count_active + 1'b1;
        end
        else count_active <= 3'd0;
    end
    
end

always_ff @( posedge clock or posedge reset ) begin : up_flag_logic
    if(reset)
        up_flag <= 1'b0;
    else begin
        if(count_active == 3'd5) up_flag <= 1'b1;
        else if(!qactive) up_flag <=1'b0;
    end
end

assign up_active_signal = (count_active == 3'd5) ? 1'b1 : 1'b0; // This will be used to set the qreq_n signal in Q_STOPPED --> Q_EXIT state 

//------------------------------------------------------------------------------------------------------------
logic [2:0] count_active_down;
logic down_active_signal;
logic down_flag;

always_ff @( posedge clock or posedge reset ) begin : Active_Counter_down
    if(reset) begin
        count_active_down <= 3'd0;
    end
    else begin
        if(count_active_down == 3'd5) begin 
            count_active_down <= 3'd0;
        end
        else if(!qactive & !up_flag) begin 
            count_active_down <= count_active_down + 1'b1;
        end
        else count_active_down <= 3'd0;
    end
    
end

always_ff @( posedge clock or posedge reset ) begin : down_flag_logic
    if(reset)
        down_flag <= 1'b0;
    else begin
        if(count_active == 3'd5) down_flag <= 1'b1;
        else if(qactive) down_flag <=1'b0;
    end
end

assign down_active_signal = (count_active_down == 3'd5) ? 1'b1 : 1'b0; // This will be used to make the qreq_n signal go low in Q_RUN --> Q_REQUEST


//------------------------------------------------------------------------------------------------------------

assign q_req_enable = (present_state == Q_RUN) | (present_state == Q_STOPPED) | (present_state == Q_REQUEST);

always_comb begin : NEXT_QREQ
    q_req_next = q_req;
    case (present_state)
        Q_RUN: if((down_active_signal) | low_power_req_i) q_req_next = 1'b0;
        Q_STOPPED: if(up_active_signal) q_req_next = 1'b1;
        default: q_req_next = q_req_next;
    endcase
end
always_ff @( posedge clock or posedge reset ) begin : Q_REQ_LOGIC
    if(reset)
        q_req <= 1'b1;
    else begin
        if(q_req_enable)
            q_req <= q_req_next;
    end
    
end

assign qreq_n_o = q_req;

//----------------------ICG Enable Signal 

always@(negedge clock or posedge reset) begin: DEVICE_EN_ICG
    if(reset) device_icg_enable <= 1'b1;
    else if(present_state == Q_STOPPED) device_icg_enable <= 1'b0;
    else device_icg_enable <= 1'b1;
end



    
endmodule
