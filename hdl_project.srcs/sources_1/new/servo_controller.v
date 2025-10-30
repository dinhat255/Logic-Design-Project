`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025
// Design Name: 
// Module Name: servo_controller
// Target Devices: Arty Z7-20
// Description: 
//   Servo PWM controller with FSM and LED debug.
//   Fixed MOVE state to hold visible duration for LED0.
//
//////////////////////////////////////////////////////////////////////////////////

module servo_controller(
    input  wire clk,      // 100 MHz clock
    input  wire rst,      // active high reset (BTN1)
    input  wire start,    // trigger one classification (BTN0)
    output reg  pwm_out,  // PWM output for servo
    output reg  [3:0] led // LED debug
    );

    //===========================================================
    // Parameters
    //===========================================================
    parameter PERIOD_20MS  = 2000000;   // 20ms * 100MHz
    parameter PULSE_RED    = 100000;    // 1.0ms (0 degrees)
    parameter PULSE_YEL    = 133333;    // 1.33ms (60 degrees)
    parameter PULSE_GRN    = 166667;    // 1.67ms (120 degrees)
    parameter PULSE_MID    = 133333;    // center
    parameter MOVE_TIME    = 50000000;  // 500ms @100MHz
    parameter HOLD_TIME    = 50000000;  // 500ms @100MHz

    //===========================================================
    // State encoding
    //===========================================================
    parameter S_IDLE          = 3'd0;
    parameter S_MOVE          = 3'd1;
    parameter S_HOLD          = 3'd2;
    parameter S_RETURN_CENTER = 3'd3;
    parameter S_DONE          = 3'd4;

    reg [2:0] state, next_state;
    reg [31:0] counter;
    reg [20:0] pwm_counter;
    reg [17:0] pulse_width;

    //===========================================================
    // State register
    //===========================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    //===========================================================
    // Next-state logic
    //===========================================================
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:          if (start) next_state = S_MOVE;
            S_MOVE:          if (counter >= MOVE_TIME) next_state = S_HOLD;
            S_HOLD:          if (counter >= HOLD_TIME) next_state = S_RETURN_CENTER;
            S_RETURN_CENTER: if (counter >= HOLD_TIME) next_state = S_DONE;
            S_DONE:          if (counter >= HOLD_TIME) next_state = S_IDLE;
            default:         next_state = S_IDLE;
        endcase
    end

    //===========================================================
    // General purpose counter (for timing MOVE/HOLD/RETURN/DONE)
    //===========================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            counter <= 0;
        else if (state != next_state)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    //===========================================================
    // PWM 50 Hz (20 ms period)
    //===========================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            pwm_counter <= 0;
        else if (pwm_counter >= PERIOD_20MS - 1)
            pwm_counter <= 0;
        else
            pwm_counter <= pwm_counter + 1;
    end

    //===========================================================
    // Pulse width selection
    //===========================================================
    always @(*) begin
        case (state)
            S_MOVE:          pulse_width = PULSE_RED;
            S_HOLD:          pulse_width = PULSE_GRN;
            S_RETURN_CENTER: pulse_width = PULSE_MID;
            default:         pulse_width = PULSE_MID;
        endcase
    end

    //===========================================================
    // PWM output
    //===========================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            pwm_out <= 1'b0;
        else
            pwm_out <= (pwm_counter < pulse_width);
    end

    //===========================================================
    // LED debug display
    //===========================================================
    always @(*) begin
        led = 4'b0000;
        case (state)
            S_MOVE:          led = 4'b0001; // LED0
            S_HOLD:          led = 4'b0010; // LED1
            S_RETURN_CENTER: led = 4'b0100; // LED2
            S_DONE:          led = 4'b1000; // LED3
            default:         led = 4'b0000; // IDLE
        endcase
    end

endmodule
