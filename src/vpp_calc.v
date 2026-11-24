// vpp at the probe in mV, (max - min) codes x 5 mV (divide-by-5 front end)

module vpp_calc (max_l, min_l, vpp_mv);

	input [11:0] max_l, min_l;
	output [15:0] vpp_mv;

	wire [11:0] d;

	assign d = (max_l > min_l) ? max_l - min_l : 12'd0;
	assign vpp_mv = {2'b00, d, 2'b00} + {4'b0000, d}; //x*4+x

endmodule
