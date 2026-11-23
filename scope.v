// Milestone 1: reading input from the ADC module

module scope (CLOCK_50, KEY, LEDR, SW, HEX0, HEX1, HEX2, ADC_SCLK, ADC_CS_N, ADC_DOUT, ADC_DIN);
	
	input CLOCK_50;
	input [1:0] KEY;
	input [1:0] SW;
	
	output [0:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2;
	
	// External ADC SPI lines
	output wire ADC_SCLK; // CLK
	output wire ADC_CS_N; // Chip select

	input wire ADC_DOUT; // MISO
	output wire ADC_DIN; // MOSI
	
	wire reset; 
	
	reg [11:0] thresh;
	wire [11:0] ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7; // for now ch1-7 are not used
	
	assign reset = ~KEY[0]; // active high reset for the ADC
	
	// combinational circuit to configure the selected threshold voltage 
	always @ (*) begin
		
		case(SW)
			
			2'b00: thresh = 12'd1000; // 1V0
			
			2'b01: thresh = 12'd2000; // 2V0
			
			2'b10: thresh = 12'd3000; // 3V0
			
			2'b11: thresh = 12'd3500; // 3V5
		
			default: thresh = 12'd000; //0V
		endcase
	end
	
	ADC adc1 (CLOCK_50, ADC_SCLK, ADC_CS_N, ADC_DOUT, ADC_DIN,
				 ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7, reset);
	

	hex_decoder u1 (ch0[3:0], HEX0);
	hex_decoder u2 (ch0[7:4], HEX1);
	hex_decoder u3 (ch0[11:8], HEX2);
	
	assign LEDR = (ch0 > thresh); // turn on if the input voltage is larger than a threshold
	
endmodule

// seven segment decoder

module hex_decoder (in, out);

	input [3:0] in;
	output reg [6:0] out;

	always @ (*) begin
		case (in)
			4'h0: out = 7'b1000000;
			4'h1: out = 7'b1111001;
			4'h2: out = 7'b0100100;
			4'h3: out = 7'b0110000;
			4'h4: out = 7'b0011001;
			4'h5: out = 7'b0010010;
			4'h6: out = 7'b0000010;
			4'h7: out = 7'b1111000;
			4'h8: out = 7'b0000000;
			4'h9: out = 7'b0010000;
			4'hA: out = 7'b0001000;
			4'hB: out = 7'b0000011;
			4'hC: out = 7'b1000110;
			4'hD: out = 7'b0100001;
			4'hE: out = 7'b0000110;
			4'hF: out = 7'b0001110;
			default: out = 7'b1111111;
		endcase
	end
endmodule
