// rising edge trigger with hysteresis.
//fires when ch0 rises above level + H
// and re-arms iff then ch0 falls below level - H

module edge_detect (clk, resetn, tick, ch0, level, crossing);

	parameter H = 13'd1; //hysteresis

	input clk, resetn, tick;
	input [11:0] ch0, level;
	output crossing;

	reg high; // 0 = low
	wire above, below;

	assign above = ({1'b0, ch0} >= {1'b0, level} + H);
	assign below = ({1'b0, ch0} + H <= {1'b0, level});

	always @ (posedge clk) begin
		if (!resetn)
			high <= 1'b0;
		else if (tick) begin
			if (above)
				high <= 1'b1;
			else if (below)
				high <= 1'b0;
		end
	end

	assign crossing = tick & ~high & above;

endmodule
