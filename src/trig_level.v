// Auto: middle of the last capture
//Manual: (sel+1) x 600 codes = 3, 6, 9, 12 V
module trig_level (manual, sel, max_l, min_l, level);

	input manual;
	input [1:0] sel;
	input [11:0] max_l, min_l;
	output [11:0] level;

	wire [12:0] sum;
	reg [11:0] man_level;

	assign sum = {1'b0, max_l} + {1'b0, min_l};

	always @ (*) begin
		case (sel)
			2'b00: man_level = 12'd600;
			2'b01: man_level = 12'd1200;
			2'b10: man_level = 12'd1800;
			default: man_level = 12'd2400;
		endcase
	end

	assign level = manual ? man_level : sum[12:1]; // sum/2

endmodule
