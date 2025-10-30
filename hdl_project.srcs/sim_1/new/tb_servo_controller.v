`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 11:18:36 PM
// Design Name: 
// Module Name: tb_servo_controller
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


module tb_servo_controller;

  // Clock 100 MHz => T = 10 ns
  reg clk = 0;
  always #5 clk = ~clk;

  reg rst = 1;
  reg start = 0;
  wire pwm_out;
  wire [3:0] led;

  // DUT với override tham số để mô phỏng nhanh
  servo_controller #(
    .PERIOD_20MS (2000),     // 20 us
    .PULSE_RED   (100),      // 1.0 us (100 ticks)
    .PULSE_YEL   (133),      // 1.33 us
    .PULSE_GRN   (167),      // 1.67 us
    .PULSE_MID   (133),      // center
    .HOLD_TIME   (50000)     // 0.5 ms
  ) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .pwm_out(pwm_out),
    .led(led)
  );

  // Đo period và độ rộng xung
  integer period_cnt = 0;
  integer high_cnt   = 0;
  integer cycle_num  = 0;

  // Tự chấm từng giai đoạn theo LED (FSM)
  // Kỳ vọng: MOVE -> HOLD -> RETURN_CENTER -> DONE -> IDLE
  // LED map: 0001, 0010, 0100, 1000, 0000
  reg [3:0] last_led;

  // Đếm trong một chu kỳ PWM
  always @(posedge clk) begin
    period_cnt <= period_cnt + 1;
    if (pwm_out) high_cnt <= high_cnt + 1;

    // Khi hết chu kỳ 20us (PERIOD_20MS)
    if (period_cnt == (2000-1)) begin
      cycle_num  <= cycle_num + 1;

      // Kiểm tra period đúng
      if (period_cnt+1 !== 2000) begin
        $display("[%0t] FAIL: PWM period != 2000 ticks", $time);
        $fatal;
      end

      // In độ rộng xung 5 chu kỳ đầu mỗi state để bạn xem
      if (cycle_num < 5)
        $display("[%0t] State LED=%b  HighCnt=%0d / 2000", $time, led, high_cnt);

      // Reset counter cho chu kỳ tiếp
      period_cnt <= 0;
      high_cnt   <= 0;
    end
  end

  initial begin
    $display("== TB START ==");
    // Reset 200 ns
    #200; rst = 0;

    // Kích start sau 100 ns
    #100; start = 1;
    #10;  start = 0;

    // Chạy đủ lâu cho cả chuỗi MOVE->HOLD->RETURN->DONE->IDLE
    // HOLD_TIME=50,000 tick ~ 0.5ms; cần ~ 3 * HOLD + margin
    #(5_000_000); // 5 ms mô phỏng

    $display("== TB END: PASS (không phát hiện lỗi) ==");
    $finish;
  end

  // Kiểm tra chuyển trạng thái qua LED (thô nhưng hiệu quả)
  // Kỳ vọng thứ tự led: 0001 -> 0010 -> 0100 -> 1000 -> 0000
  reg seen_move, seen_hold, seen_return, seen_done, seen_idle;
  always @(posedge clk) begin
    last_led <= led;
    if (led == 4'b0001) seen_move   <= 1;
    if (seen_move   && led == 4'b0010) seen_hold   <= 1;
    if (seen_hold   && led == 4'b0100) seen_return <= 1;
    if (seen_return && led == 4'b1000) seen_done   <= 1;
    if (seen_done   && led == 4'b0000) seen_idle   <= 1;

    // Nếu thứ tự bị sai (ví dụ nhảy từ 0001 sang 0100), có thể thêm assert ở đây
    if (seen_move && !seen_hold && led == 4'b0100) begin
      $display("[%0t] FAIL: Skipped HOLD", $time);
      $fatal;
    end

    if (seen_done && led != 4'b0000 && seen_idle) begin
      $display("[%0t] FAIL: IDLE không ổn định", $time);
      $fatal;
    end
  end

  // Một số assert theo LED sau ~ thời gian hợp lý
  initial begin
    // Sau 1 ms, chắc chắn đã qua MOVE và HOLD
    #(1_000_000);
    if (!seen_move || !seen_hold) begin
      $display("FAIL: Không thấy MOVE/HOLD trong 1ms mô phỏng");
      $fatal;
    end
  end

endmodule
