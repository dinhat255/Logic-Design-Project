`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 11:02:42 PM
// Design Name: 
// Module Name: top_module
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


module top_module (
    input  wire clk,        // 100MHz clock from Arty Z7-20
    input  wire rst,        // BTN1
    input  wire btn_start,  // BTN0
    output wire servo_pwm,
    output wire motor_en,
    output wire motor_dir,
    output wire [3:0] led
);

    servo_controller u_servo (
        .clk(clk),
        .rst(rst),
        .start(btn_start),
        .pwm_out(servo_pwm),
        .led(led)
    );

    motor_controller u_motor (
        .clk(clk),
        .rst(rst),
        .enable(motor_en),
        .dir(motor_dir)
    );

endmodule
