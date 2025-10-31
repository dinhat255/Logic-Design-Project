module Transmitter(
    input        i_Clock,
    input        i_Tx_DV,
    input[7:0]   i_Tx_Byte,
    output       o_Tx_Active,
    output reg   o_Tx_Serial,
    output       o_Tx_Done
    );

    // PARAMETERS
    parameter CLK_PER_BIT = 87;
    parameter S_IDLE      = 3'b000;
    parameter S_START     = 3'b001;
    parameter S_DATA      = 3'b010;
    parameter S_STOP      = 3'b011;
    parameter S_CLEAN     = 3'b100;

    // REGISTERS
    reg[2:0] r_SM_Main     = 0;
    reg[7:0] r_Tx_Data     = 0;
    reg[2:0] r_Bit_Index   = 0;
    reg[7:0] Clock_Count   = 0;
    reg      r_Tx_Done     = 0;
    reg      r_Tx_Active   = 0;

    // STATE MACHINE
    always @(posedge i_Clock)
    begin
        case (r_SM_Main)
        // ====================================================
        // IDLE STATE: Wait for data valid signal (i_Tx_DV)
        // ====================================================
        S_IDLE :
        begin
            o_Tx_Serial   <= 1'b1;  // Line high (idle)
            r_Tx_Done     <= 1'b0;
            Clock_Count   <= 0;
            r_Bit_Index   <= 0;

            if (i_Tx_DV == 1'b1)
                begin
                    r_Tx_Active <= 1'b1;
                    r_Tx_Data   <= i_Tx_Byte;
                    r_SM_Main   <= S_START;
                end
            else
                r_SM_Main <= S_IDLE;
        end

        // ====================================================
        // START STATE: Send start bit (logic 0)
        // ====================================================
        S_START :
        begin
            o_Tx_Serial <= 1'b0;  // Start bit = 0
            if (Clock_Count < CLK_PER_BIT - 1)
                begin
                    Clock_Count <= Clock_Count + 1;
                    r_SM_Main   <= S_START;
                end
            else
                begin
                    Clock_Count <= 0;
                    r_SM_Main   <= S_DATA;
                end
        end

        // ====================================================
        // DATA STATE: Send 8 data bits (LSB first)
        // ====================================================
        S_DATA :
        begin
            o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
            if (Clock_Count < CLK_PER_BIT - 1)
                begin
                    Clock_Count <= Clock_Count + 1;
                    r_SM_Main   <= S_DATA;
                end
            else
                begin
                    Clock_Count <= 0;
                    if (r_Bit_Index < 7)
                        begin
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_SM_Main   <= S_DATA;
                        end
                    else
                        begin
                            r_Bit_Index <= 0;
                            r_SM_Main   <= S_STOP;
                        end
                end
        end

        // ====================================================
        // STOP STATE: Send stop bit (logic 1)
        // ====================================================
        S_STOP :
        begin
            o_Tx_Serial <= 1'b1;  // Stop bit = 1
            if (Clock_Count < CLK_PER_BIT - 1)
                begin
                    Clock_Count <= Clock_Count + 1;
                    r_SM_Main   <= S_STOP;
                end
            else
                begin
                    r_Tx_Done   <= 1'b1;
                    Clock_Count <= 0;
                    r_SM_Main   <= S_CLEAN;
                    r_Tx_Active <= 1'b0;
                end
        end

        // ====================================================
        // CLEAN STATE: Hold "Done" for 1 clock cycle
        // ====================================================
        S_CLEAN :
        begin
            r_Tx_Done <= 1'b1;
            r_SM_Main <= S_IDLE;
        end

        default :
            r_SM_Main <= S_IDLE;

        endcase
    end

    // OUTPUT ASSIGNMENTS
    assign o_Tx_Active = r_Tx_Active;
    assign o_Tx_Done   = r_Tx_Done;

endmodule
