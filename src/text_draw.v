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

	// step through 3 characters of 8 rows of 8 pixels, then start again
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
	assign color = bits[3'd7 - col] ? 3'b111 : 3'b000; //bits is [7:0] so bits[7] msut be the leftmost --> we need col = 0 to make 7
	assign write = 1'b1;

endmodule
