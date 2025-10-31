module baudrate (
    input  wire clk_50m,
    input  wire reset,
    output reg  Rxclk_en,
    output reg  Txclk_en
);
    // 50,000,000 / 115200 ? 434 clocks per bit
    parameter DIVISOR = 434;

    reg[15:0] count   = 0;

    always @(posedge clk_50m or posedge reset) begin
        if (reset) begin
            count <= 0;
            Rxclk_en <= 0;
            Txclk_en <= 0;
        end else if (count == DIVISOR - 1) begin
            count <= 0;
            Rxclk_en <= 1;
            Txclk_en <= 1;
        end else begin
            count <= count + 1;
            Rxclk_en <= 0;
            Txclk_en <= 0;
        end
    end
endmodule
