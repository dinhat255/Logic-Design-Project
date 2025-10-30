`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 11:01:47 PM
// Design Name: 
// Module Name: motor_controller
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


module motor_controller (
    input  wire clk,
    input  wire rst,
    output reg  enable,
    output reg  dir
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enable <= 1'b0;
            dir    <= 1'b0;
        end else begin
            enable <= 1'b1; // always on
            dir    <= 1'b1; // forward
        end
    end
endmodule
