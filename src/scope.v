module scope(
	input CLOCK_50,
	input [3:0] KEY,
	input [9:0] SW,
	output [9:0] LEDR,
	output [6:0] HEX0, HEX1, HEX2,
	output ADC_CS_N, ADC_SCLK, ADC_DIN,
	input ADC_DOUT,
	output [7:0] VGA_R, VGA_G, VGA_B,
	output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK
);
	assign LEDR = 10'b0;
endmodule
