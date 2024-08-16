`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sanidhya Saxena
// 
// Create Date: 16.08.2024 17:33:02
// Design Name: 
// Module Name: dff2_sync
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


module dff2_sync #(parameter RESET_VAL = 1)(
    input async,
    input clk,
    input reset,
    output reg sync
    );
    
    reg meta;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            meta <= RESET_VAL;
            sync <= RESET_VAL;
        end
        else begin
            meta <= async;
            sync <= meta;
        end
    end
endmodule
