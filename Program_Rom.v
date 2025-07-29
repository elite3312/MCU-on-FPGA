module Program_Rom(Rom_data_out, Rom_addr_in);

//---------
    output [13:0] Rom_data_out;
    input [10:0] Rom_addr_in; 
//---------
    
    reg   [13:0] data;
    wire  [13:0] Rom_data_out;
    
    always @(Rom_addr_in)
        begin
            case (Rom_addr_in)
                11'h0 : data = 14'h3004;		//MOVLW W<=4
                11'h1 : data = 14'h008e;		//MOVWF portc=4
				11'h2 : data = 14'h3000;		//MOVLW W<=0
				11'h3 : data = 14'h00A5;		//ram[37]<=0 
				11'h4 : data = 14'h0725;		//addwf w<=w+ram[37]
				11'h5 : data = 14'h3425;		//incfeqcsz
                11'h6 : data = 14'h2804;		//goto pc=4
                11'h7 : data = 14'h3001;		//MOVLW W<=1
                11'h8 : data = 14'h3002;		//MOVLW W<=2
				11'h9 : data = 14'h2808;		//goto $
                11'ha : data = 14'h3400;		
                11'hb : data = 14'h3400;
                default: data = 14'h0;   
            endcase
        end

     assign Rom_data_out = data;

endmodule
