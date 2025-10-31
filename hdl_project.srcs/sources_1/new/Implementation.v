module uart (
    input  wire       clk_50m,     // 50 MHz system clock
    input  wire       clear,       // async reset (active high)
    input  wire [7:0] data_in,     // data to transmit
    input  wire       wr_en,       // write enable
    input  wire       ready_clr,   // clear ready flag
    input  wire       Rx,          // UART RX line
    output wire       Tx,          // UART TX line
    output wire [7:0] data_out,    // received data
    output wire       ready,       // data ready
    output wire       Tx_busy,     // TX active
    output wire [7:0] LEDR,        // debug LEDs
    output wire       Tx2          // duplicate TX
);

    assign LEDR = data_in;
    assign Tx2  = Tx;

    // clock enables
    wire Txclk_en;
    wire Rxclk_en;

    // ==========================
    // Baudrate Generator
    // ==========================
    baudrate uart_baud (
        .clk_50m(clk_50m),
        .reset(clear),
        .Rxclk_en(Rxclk_en),
        .Txclk_en(Txclk_en)
    );

    // ==========================
    // UART Transmitter
    // ==========================
    Transmitter uart_tx (
        .i_Clock(clk_50m),
        .i_Tx_DV(wr_en),
        .i_Tx_Byte(data_in),
        .o_Tx_Active(Tx_busy),
        .o_Tx_Serial(Tx),
        .o_Tx_Done()          
    );

    // ==========================
    // UART Receiver
    // ==========================
    Receiver uart_rx (
        .i_Clock(clk_50m),
        .i_Rx_Serial(Rx),
        .o_Rx_DV(ready),
        .o_Rx_Byte(data_out)
    );

endmodule
