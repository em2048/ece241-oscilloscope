`timescale 1ns/1ps
module tb_scope;
	reg CLOCK_50;
	reg [3:0] KEY;
	reg [9:0] SW;
	reg ADC_DOUT;
	wire [9:0] LEDR;

	scope dut(
		.CLOCK_50(CLOCK_50),
		.KEY(KEY),
		.SW(SW),
		.LEDR(LEDR),
		.ADC_DOUT(ADC_DOUT)
	);

	always #10 CLOCK_50 = ~CLOCK_50;

	initial begin
		CLOCK_50 = 0; KEY = 4'b1110; SW = 0; ADC_DOUT = 0;
		#100 KEY[0] = 1;
		#2000 $stop;
	end
endmodule
