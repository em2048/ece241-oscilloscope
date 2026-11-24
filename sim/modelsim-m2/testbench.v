`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20; //20 ns clock period = CLOCK_50

	reg CLOCK_50, resetn, manual;
	reg [1:0] tb, sel;
	reg [11:0] max_l, min_l, ch0;
	wire tick, crossing;
	wire [11:0] level;

	real wave; //used to calculate sine

	initial begin
		CLOCK_50 <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
	end

	// 1 kHz sine, 0 to 3000 codes (3V)
	always @ (negedge CLOCK_50) begin
		//1 kHz sine (T=1ms)
		wave = 1500.0 + 1500.0 * $sin(2.0 * 3.14159265 * 1000.0 * $realtime * 1.0e-9); //scale sine wave to 0-3V (0-15V at front end)
		ch0 <= $rtoi(wave); //real to integer
	end

	col_tick U1 (CLOCK_50, resetn, tb, tick);
	trig_level U2 (manual, sel, max_l, min_l, level);
	edge_detect U3 (CLOCK_50, resetn, tick, ch0, level, crossing);

	initial begin
		resetn <= 1'b0;
		tb <= 2'b00;
		manual <= 1'b0;
		sel <= 2'b00;
		//max/min from capture is hard coded here
		max_l <= 12'd3000;
		min_l <= 12'd0;

		// Shows col_tick, trig_level and edge_detect working together on a 1 kHz sine (0-3000 codes)
		// 0 - 2 ms  0.5 ms/div, auto level (1500)
		// 2 - 3 ms  manual level 1000 (sel = 01)
		// 3 - 4 ms  manual level 2000 (sel = 10)
		// 4 - 6 ms  auto level, 1 ms/div (ticks twice as far apart)
		#40 resetn <= 1'b1;
		#2000000 manual <= 1'b1; sel <= 2'b01;
		#1000000 sel <= 2'b10;
		#1000000 manual <= 1'b0; tb <= 2'b01;
		#2000000 tb <= 2'b11;   // 6 ms: 5 ms/div --> expect to count to 250,000
		#3000000 tb <= 2'b00;   // 9 ms: back to 0.5 ms/div --> testing edge case: goes back to 25000 mod
	end // initial

endmodule
