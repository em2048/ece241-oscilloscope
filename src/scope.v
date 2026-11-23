// 640x480 VGA, 624x464 graph (12 x 8 div), 1 ms/div default, 5 V/div, divide-by-5 front end

module scope (CLOCK_50, KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
	ADC_SCLK, ADC_CS_N, ADC_DOUT, ADC_DIN,
	VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

	input CLOCK_50;
	input [1:0] KEY;
	input [9:0] SW;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

	output ADC_SCLK, ADC_CS_N, ADC_DIN;
	input ADC_DOUT;

	output [7:0] VGA_R, VGA_G, VGA_B;
	output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;

	wire resetn;
	wire [11:0] ch0;
	wire tick;
	wire [11:0] level;
	wire crossing;
	wire [9:0] rd_col;
	wire [11:0] rd_data;
	wire done, draw_done, trigd;
	wire [11:0] max_l, min_l, mid;
	wire [12:0] mm_sum;

	wire [9:0] g_x, t_x, vga_x;
	wire [8:0] g_y, t_y, vga_y;
	wire [2:0] g_color, t_color, vga_color;
	wire g_write, t_write, vga_write;
	wire grid_done;

	wire [15:0] freq, vpp_mv, value;
	wire [19:0] digits;

	assign resetn = KEY[0];

	// SW[9] freeze, SW[8] manual level, SW[7] HEX shows Hz, SW[6:5] timebase, SW[1:0] manual level

	ADC adc1 (
		.CLOCK(CLOCK_50),
		.RESET(~resetn),
		.ADC_SCLK(ADC_SCLK),
		.ADC_CS_N(ADC_CS_N),
		.ADC_DOUT(ADC_DOUT),
		.ADC_DIN(ADC_DIN),
		.CH0(ch0));

	col_tick ct (CLOCK_50, resetn, SW[6:5], tick);

	trig_level tl (SW[8], SW[1:0], max_l, min_l, level);

	edge_detect ed (CLOCK_50, resetn, tick, ch0, level, crossing);

	capture cap (CLOCK_50, resetn, tick, ch0, crossing, SW[9], draw_done,
		rd_col, rd_data, done, trigd, max_l, min_l);

	grid_draw gd (CLOCK_50, resetn, g_x, g_y, g_color, g_write, grid_done);

	assign mm_sum = {1'b0, max_l} + {1'b0, min_l};
	assign mid = mm_sum[12:1];

	trace_draw td (CLOCK_50, resetn, grid_done, done, rd_data, mid, rd_col,
		t_x, t_y, t_color, t_write, draw_done);

	assign vga_x = grid_done ? t_x : g_x;
	assign vga_y = grid_done ? t_y : g_y;
	assign vga_color = grid_done ? t_color : g_color;
	assign vga_write = grid_done ? t_write : g_write;

	vga_adapter VGA (
		.resetn(resetn),
		.clock(CLOCK_50),
		.color(vga_color),
		.x(vga_x),
		.y(vga_y),
		.write(vga_write),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "640x480";
		defparam VGA.COLOR_DEPTH = 3;
		defparam VGA.BACKGROUND_IMAGE = "mif/black_640_3.mif";

	freq_counter fc (CLOCK_50, resetn, crossing, SW[9], freq);

	vpp_calc vc (max_l, min_l, vpp_mv);

	assign value = SW[7] ? freq : vpp_mv;

	bin2bcd bb (CLOCK_50, resetn, value, digits);

	hex_decoder h0 (digits[3:0], HEX0);
	hex_decoder h1 (digits[7:4], HEX1);
	hex_decoder h2 (digits[11:8], HEX2);
	hex_decoder h3 (digits[15:12], HEX3);
	hex_decoder h4 (digits[19:16], HEX4);
	assign HEX5 = 7'b1111111;

	assign LEDR = {SW[9], 8'b00000000, trigd};

endmodule
