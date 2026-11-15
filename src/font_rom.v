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
