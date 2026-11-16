`timescale 1ns / 1ns

`include "resolution.v"

// Shows ON or OFF in the middle of the VGA screen, depending on whether the input is above
// the threshold. DESim has no ADC, so SW[9:2] stand in for the ADC reading and SW[1:0]
// select the threshold, as in scope.v. The text is drawn by text_draw (written for 160x120).
// First press KEY[0] to reset.
module onoff_demo (CLOCK_50, SW, KEY, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, VGA_X, VGA_Y, VGA_COLOR, plot);

    parameter nX = `ifdef VGA_640_480 10 `elsif VGA_320_240 9 `else 8 `endif ; // VGA x bitwidth
    parameter nY = nX - 1;

    input wire CLOCK_50;            // DE-series board 50 MHz Clock
    input wire [9:0] SW;            // switches
    input wire [3:0] KEY;           // push buttons
    output wire [9:0] LEDR;         // LEDs
    output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;   // 7-segment displays
    output wire [nX-1:0] VGA_X;     // VGA column
    output wire [nY-1:0] VGA_Y;     // VGA row
    output wire [23:0] VGA_COLOR;   // VGA pixel colour (24-bit color)
    output wire plot;               // Pixel is drawn plot = 1

    wire Resetn;                    // active-low reset
    assign Resetn = KEY[0];

    wire [11:0] ch0;                // stand-in for the ADC reading
    reg [11:0] thresh;              // selected threshold
    wire on;                        // input is above the threshold

    wire [7:0] x;                   // pixel from text_draw
    wire [6:0] y;
    wire [2:0] color;
    wire write;

    // SW[9:2] set the top 8 bits of the reading (0 to 4080 in steps of 16)
    assign ch0 = {SW[9:2], 4'b0000};

    // same threshold selection as scope.v
    always @ (*) begin
        case (SW[1:0])
            2'b00: thresh = 12'd1000; // 1V0
            2'b01: thresh = 12'd2000; // 2V0
            2'b10: thresh = 12'd3000; // 3V0
            2'b11: thresh = 12'd3500; // 3V5
            default: thresh = 12'd0;
        endcase
    end

    assign on = (ch0 > thresh);
    assign LEDR = {9'b0, on};

    // show the reading on hex displays
    hex7seg H0 (ch0[3:0], HEX0);
    hex7seg H1 (ch0[7:4], HEX1);
    hex7seg H2 (ch0[11:8], HEX2);
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;

    text_draw T1 (CLOCK_50, Resetn, on, x, y, color, write);

    // need to convert to 24 bit colour
    assign VGA_X = x;
    assign VGA_Y = y;
    assign VGA_COLOR = {{8{color[2]}}, {8{color[1]}}, {8{color[0]}}};
    assign plot = write;

endmodule


// Keeps redrawing "ON " or "OFF" into the VGA adapter, one pixel per clock

module text_draw (clk, resetn, on, x, y, color, write);

	parameter X0 = 8'd68; // left edge of the text (centred for 160x120)
	parameter Y0 = 7'd56; // top edge of the text

	input clk, resetn;
	input on;
	output [7:0] x;
	output [6:0] y;
	output [2:0] color;
	output write;

	reg [1:0] char_idx;
	reg [2:0] row, col;
	reg [1:0] char;
	wire [7:0] bits;

	always @ (posedge clk) begin
		if (!resetn) begin
			char_idx <= 2'd0;
			row <= 3'd0;
			col <= 3'd0;
		end
		else begin
			col <= col + 3'd1; //loop thru the cols
			if (col == 3'd7) begin
				row <= row + 3'd1; //go down a row
				if (row == 3'd7) begin
					if (char_idx == 2'd2)
						char_idx <= 2'd0;
					else
						char_idx <= char_idx + 2'd1; //go to next char
				end
			end
		end
	end

	always @ (*) begin
		case (char_idx)
			2'd0: char = 2'd0;
			2'd1: char = on ? 2'd1 : 2'd2;
			2'd2: char = on ? 2'd3 : 2'd2;
			default: char = 2'd3;
		endcase
	end

	font_rom f1 (char, row, bits);

	assign x = X0 + {3'b000, char_idx, 3'b000} + {5'b00000, col};
	assign y = Y0 + {4'b0000, row};
	assign color = bits[3'd7 - col] ? 3'b111 : 3'b000;
	assign write = 1'b1;

endmodule

// 8x8 characters for the ON / OFF text. Bit 7 is the leftmost pixel.
// Codes: 0 = O, 1 = N, 2 = F, 3 = space

module font_rom (char, row, bits);

	input [1:0] char;
	input [2:0] row;
	output reg [7:0] bits;

	always @ (*) begin
		case ({char, row})
			// O
			{2'd0, 3'd0}: bits = 8'b01111000;
			{2'd0, 3'd1}: bits = 8'b11001100;
			{2'd0, 3'd2}: bits = 8'b11001100;
			{2'd0, 3'd3}: bits = 8'b11001100;
			{2'd0, 3'd4}: bits = 8'b11001100;
			{2'd0, 3'd5}: bits = 8'b11001100;
			{2'd0, 3'd6}: bits = 8'b01111000;
			{2'd0, 3'd7}: bits = 8'b00000000;
			// N
			{2'd1, 3'd0}: bits = 8'b11001100;
			{2'd1, 3'd1}: bits = 8'b11101100;
			{2'd1, 3'd2}: bits = 8'b11111100;
			{2'd1, 3'd3}: bits = 8'b11111100;
			{2'd1, 3'd4}: bits = 8'b11011100;
			{2'd1, 3'd5}: bits = 8'b11001100;
			{2'd1, 3'd6}: bits = 8'b11001100;
			{2'd1, 3'd7}: bits = 8'b00000000;
			// F
			{2'd2, 3'd0}: bits = 8'b11111100;
			{2'd2, 3'd1}: bits = 8'b11000000;
			{2'd2, 3'd2}: bits = 8'b11000000;
			{2'd2, 3'd3}: bits = 8'b11111000;
			{2'd2, 3'd4}: bits = 8'b11000000;
			{2'd2, 3'd5}: bits = 8'b11000000;
			{2'd2, 3'd6}: bits = 8'b11000000;
			{2'd2, 3'd7}: bits = 8'b00000000;
			// space
			{2'd3, 3'd0}: bits = 8'b00000000;
			{2'd3, 3'd1}: bits = 8'b00000000;
			{2'd3, 3'd2}: bits = 8'b00000000;
			{2'd3, 3'd3}: bits = 8'b00000000;
			{2'd3, 3'd4}: bits = 8'b00000000;
			{2'd3, 3'd5}: bits = 8'b00000000;
			{2'd3, 3'd6}: bits = 8'b00000000;
			{2'd3, 3'd7}: bits = 8'b00000000;
			default: bits = 8'b00000000;
		endcase
	end

endmodule
