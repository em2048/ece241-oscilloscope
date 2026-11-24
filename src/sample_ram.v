// 624 x 12-bit sample memory, read data appears one clock after rd_addr
// inferred memory according to memory lab
module sample_ram (clk, wr_en, wr_addr, wr_data, rd_addr, rd_data);

	input clk, wr_en;
	input [9:0] wr_addr, rd_addr;
	input [11:0] wr_data;
	output reg [11:0] rd_data;

	reg [11:0] mem [623:0];

	always @ (posedge clk) begin
		if (wr_en)
			mem[wr_addr] <= wr_data;
		rd_data <= mem[rd_addr];
	end

endmodule
