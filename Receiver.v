module Receiver(
    input        i_Clock,
    input        i_Rx_Serial,
    output       o_Rx_DV,
    output [7:0] out_Rx_byte
    );
    // PARAMETERS
    parameter CLK_PER_BIT = 87;
    parameter S_IDLE      = 3'b000;
    parameter S_START     = 3'b001;
    parameter S_DATA      = 3'b010;
    parameter S_STOP      = 3'b011;
    parameter S_CLEAN     = 3'b100;
    
    // REGISTER
    reg       r_Rx_Data_R   = 1'b1;
    reg       r_Rx_Data     = 1'b1;
    reg [7:0] Clock_Count = 0;
    reg [2:0] r_Bit_Index = 0;
    reg [7:0] r_Rx_Byte   = 0;
    reg       r_Rx_DV     = 0;
    reg [2:0] r_SM_Main   = 0;
    
    always @(posedge i_Clock)
    begin
        r_Rx_Data_R <= i_Rx_Serial;
        r_Rx_Data   <= r_Rx_Data_R;
    end
    
    //STATE MACHINE
    always @(posedge i_Clock)
    begin
        case (r_SM_Main)
        //IDLE STATE: Wait for start bit
        S_IDLE :
        begin
            r_Rx_DV     <= 1'b00;
            Clock_Count <= 0;
            r_Bit_Index <= 0;
            if (r_Rx_Data == 1'b0)
                r_SM_Main <= S_START;
            else
                r_SM_Main <= S_IDLE;
         end
         //START STATE: Check middle of start bit to ensure that the signal is integrity
         S_START :
         begin
            if (Clock_Count == (CLK_PER_BIT - 1) / 2)
                begin
                    if (r_Rx_Data == 1'b0)
                        begin
                            Clock_Count <= 0;
                            r_SM_Main   <= S_DATA;
                         end
                    else
                        r_SM_Main   <= S_IDLE;
                end
            else
                begin
                    Clock_Count <= Clock_Count + 1;
                    r_SM_Main   <= S_START;
                end
         end  
         //DATA STATE: Sample data bit
         S_DATA :
         begin
            if (Clock_Count < CLK_PER_BIT - 1)
                begin
                    Clock_Count <= Clock_Count + 1;
                    r_SM_Main   <= S_DATA; 
                end
            else
                begin
                    Clock_Count <= 0;
                    r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
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
         //STOP STATE
         S_STOP :
         begin
            if (Clock_Count < CLK_PER_BIT - 1)
                begin
                    Clock_Count <= Clock_Count + 1;
                    r_SM_Main   <= S_STOP;
                end
            else
                begin
                    r_Rx_DV <= 1'b1;
                    Clock_Count <= 0;
                    r_SM_Main   <= S_CLEAN;
                end
         end
         //CLEAN STATE: Stay for 1 cycle to ensure
         S_CLEAN :
         begin
            r_SM_Main <= S_IDLE;
            r_Rx_DV   <= 1'b0;
         end
         
         default :
            r_SM_Main <= S_IDLE;
        endcase
    end
    
    assign o_Rx_DV    = r_Rx_DV;
    assign o_Rx_Byte  = r_Rx_Byte;
endmodule

