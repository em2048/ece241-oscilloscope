// Milestone 2: reading input from the ADC module + DC measuring mode (scrolling graph)
 
module scope (CLOCK_50, KEY, LEDR, SW, HEX0, HEX1, HEX2, ADC_SCLK, ADC_CS_N, ADC_DOUT, ADC_DIN,VGA_R, VGA_G, VGA_B,VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
	
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
	
	// VGA lines
	output [7:0] VGA_R, VGA_G, VGA_B;
	output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
	
	wire reset; 
	wire dc_mode; // high when in DC measuring mode (LEDR[0] lit)
	
	wire [11:0] ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7; // for now ch1-7 are not used
 
	// pixel writes from the DC graph to the VGA adapter
	wire [7:0] vga_x;
	wire [6:0] vga_y;
	wire [2:0] vga_color;
	wire vga_write;
	
	assign reset = ~KEY[0]; // active high reset for the ADC
	
	// SW[0] selects DC measuring mode, LEDR[0] shows that the mode is active
	assign dc_mode = SW[0];
	assign LEDR[0] = dc_mode;
	
	ADC adc1 (CLOCK_50, ADC_SCLK, ADC_CS_N, ADC_DOUT, ADC_DIN,
				 ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7, reset);
	
 
	hex_decoder u1 (ch0[3:0], HEX0);
	hex_decoder u2 (ch0[7:4], HEX1);
	hex_decoder u3 (ch0[11:8], HEX2);
	
	// scrolling voltage graph, only active in DC mode
	dc_graph g1 (CLOCK_50, KEY[0], dc_mode, ch0, vga_x, vga_y, vga_color, vga_write);
	
	// with the ones above using dc_mode as the select.
	
	vga_adapter VGA (
		.resetn(KEY[0]),
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
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.COLOR_DEPTH = 3;
		defparam VGA.BACKGROUND_IMAGE = "mif/black_160_3.mif";
	
endmodule

// DC scrolling strip chart on 160 x 120 at 0.4 ms at 50MHz
 
module dc_graph (clock, resetn, enable, sample, x, y, color, write);
 
	// clock cycles steps time window shown = 150 * SHIFT_TICKS / 50 MHz is 20ms per step
	
	parameter SHIFT_TICKS = 24'd1000000;
 
	localparam MARGIN = 8'd10; // columns 0, 9 hold the voltage labels, graph columns are x = 10, 159
 
	input clock, resetn, enable;
	input [11:0] sample;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] color;
	output reg write;
 
	reg [6:0] hist [0:149]; // hist[0] = oldest (left), hist[149] = newest (right)
	reg [7:0] gx;           // pixel currently being drawn (x,y) = (gx, gy)
	reg [6:0] gy;
	reg [23:0] timer;
	reg shift_pending;
	integer k;
 
	// map the top 7 bits to get a range of 0-128
	wire [10:0] scaled = sample[11:5] * 4'd15;		// 120 = 128 *15/2^4 (same as shift btw)
	wire [6:0] new_y = 7'd119 - (scaled >> 4);      // Flip so larger voltage is higher on the screen
 
 
	// Is it a trace pixel?
	
	// trace this column's sample and the one to its left, joined by a vertical segment (to account for sudden jumps)
	wire [7:0] i = gx - MARGIN;                     // history index of this column
	wire [6:0] cur_y = hist[i];
	wire [6:0] p_y = (i == 8'd0) ? cur_y : hist[i - 8'd1]; // check if its the left most col
	wire [6:0] lo = (p_y < cur_y) ? p_y : cur_y;
	wire [6:0] hi = (p_y < cur_y) ? cur_y : p_y;
	wire in_span = (gx >= MARGIN) && (gy >= lo) && (gy <= hi); // Connect the two points
 
 
 
	// Is it a grideline pixel?
	
	wire is_grid = (gy == 7'd90) || (gy == 7'd61) || (gy == 7'd32) || (gy == 7'd2);
 
	// voltage labels 1V 2V 3V 4V in the left margin (3x5 height)
	reg label_here;
	reg [2:0] label_digit;
	reg [2:0] label_row; // relative to the labels (mini 5x3 box)
 
	// is gx and gy a label pixel? If so which one?
	
	always @ (*) begin
		label_here = 1'b1;
		label_digit = 3'd0;
		label_row = 3'd0;
		if (gy >= 7'd88 && gy <= 7'd92) begin label_digit = 3'd1; label_row = gy - 7'd88; end // bottom label 
		else if (gy >= 7'd59 && gy <= 7'd63) begin label_digit = 3'd2; label_row = gy - 7'd59; end 
		else if (gy >= 7'd30 && gy <= 7'd34) begin label_digit = 3'd3; label_row = gy - 7'd30; end
		else if (gy <= 7'd4) begin label_digit = 3'd4; label_row = gy[2:0]; end // top label
		else label_here = 1'b0; // no label 
	end
 
	// 3x5 bitmaps for each digit, determine the label code
	reg [14:0] digit_pat;
	always @ (*) begin
		case (label_digit)
			3'd1: digit_pat = 15'b010_110_010_010_111; // 1
			3'd2: digit_pat = 15'b111_001_111_100_111; // 2 
			3'd3: digit_pat = 15'b111_001_111_001_111; // 3 
			3'd4: digit_pat = 15'b101_101_111_001_001; // 4 
			default: digit_pat = 15'b000_000_000_000_000; // blank
		endcase
	end
	
	wire [14:0] v_pat = 15'b101_101_101_101_010; // the letter V
 
	// offset to account for the label width and height on the screen
	wire [4:0] idx_d = label_row * 3 + (gx - 8'd1); // digit occupies x 1-3
	wire [4:0] idx_v = label_row * 3 + (gx - 8'd5); // V occupies x 5-7
 
	
	reg label_pix;
	
	// if gx is at a label spot, loop through the digit pattern found above
	always @ (*) begin
		label_pix = 1'b0;
		if (label_here) begin
			if (gx >= 8'd1 && gx <= 8'd3) label_pix = digit_pat[14 - idx_d];
			else if (gx >= 8'd5 && gx <= 8'd7) label_pix = v_pat[14 - idx_v];
		end
	end
 
	// this basically makes priority for margin labels W, then trace G, then gridlines B, then blank
	wire [2:0] pix_color = (gx < MARGIN) ? (label_pix ? 3'b111 : 3'b000) : in_span ? 3'b010 : is_grid ? 3'b001 : 3'b000;
 
	always @ (posedge clock) begin
		if (!resetn) begin
			for (k = 0; k < 150; k = k + 1)
				hist[k] <= 7'd119; // start flat at 0 V
			gx <= 8'd0;
			gy <= 7'd0;
			timer <= 24'd0;
			shift_pending <= 1'b0;
			write <= 1'b0;
		end
		else begin
			// registered outputs to the VGA adapter
			x <= gx;
			y <= gy;
			color <= pix_color;
			write <= enable;
 
			// scroll step every SHIFT_TICKS cycles
			if (timer >= SHIFT_TICKS) begin
				timer <= 24'd0;
				shift_pending <= 1'b1;
			end
			else
				timer <= timer + 1'b1;
 
			if (enable) begin
				// walk over every pixel of the screen, column by column
				if (gy == 7'd119) begin
					gy <= 7'd0;
					if (gx == 8'd159) begin
						gx <= 8'd0;
						// finished a full redraw: apply the scroll now so the picture never changes mid-frame
						if (shift_pending) begin
							for (k = 0; k < 149; k = k + 1)
								hist[k] <= hist[k + 1];
							hist[149] <= new_y;
							shift_pending <= 1'b0;
						end
					end
					else
						gx <= gx + 1'b1;
				end
				else
					gy <= gy + 1'b1;
			end
			else begin
				gx <= 8'd0;
				gy <= 7'd0;
			end
		end
	end
 
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