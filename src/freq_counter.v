// Counts trigger crossings over a 1 s gate, so freq is in Hz. Holds its value while frozen.

module freq_counter (clk, resetn, crossing, freeze, freq);

	input clk, resetn, crossing, freeze;
	output reg [15:0] freq;

	reg [25:0] gate;
	reg [15:0] edges;

	always @ (posedge clk) begin
		if (!resetn) begin
			gate <= 26'd0;
			edges <= 16'd0;
			freq <= 16'd0;
		end
		else if (gate == 26'd49999999) begin
			gate <= 26'd0;
			edges <= 16'd0;
			if (!freeze)
				freq <= edges; //freq = cycles/s
		end
		else begin
			gate <= gate + 26'd1;
			if (crossing)
				edges <= edges + 16'd1; //count rising edges for 1 second to get Hz 
		end
	end

endmodule
