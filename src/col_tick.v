module col_tick (clk, resetn, tb, tick);

	input clk, resetn;
	input [1:0] tb;
	output reg tick;

	reg [17:0] acc;
	reg [17:0] wrap;
	wire [17:0] next;

	always @ (*) begin
		case (tb)
			2'b00: wrap = 18'd25000;
			2'b01: wrap = 18'd50000;
			2'b10: wrap = 18'd100000;
			default: wrap = 18'd250000;
		endcase
	end

	assign next = acc + 18'd52;

	always @ (posedge clk) begin
		if (!resetn) begin
			acc <= 18'd0;
			tick <= 1'b0;
		end
		else if (next >= wrap) begin
			acc <= (next - wrap >= wrap) ? 18'd0 : next - wrap; // edge case for go to smaller timebase
			tick <= 1'b1;
		end
		else begin
			acc <= next;
			tick <= 1'b0;
		end
	end

endmodule
