// Records one screen (624 samples) into a circular buffer so the trigger sample is column 312
// tracks max/min for Vpp and auto level

module capture (clk, resetn, tick, ch0, crossing, freeze, rd_col, rd_data, trigd, max_l, min_l);

	input clk, resetn, tick, crossing, freeze;
	input [11:0] ch0;
	input [9:0] rd_col;
	output [11:0] rd_data; //read data out from ram
	output reg trigd;
	output reg [11:0] max_l, min_l;

	parameter ARM = 3'd0, PREFILL = 3'd1, WAIT = 3'd2, POST = 3'd3, HOLD = 3'd4;

	reg [2:0] state; 
	reg [9:0] wptr, trig_addr; //write pointer, trigger address (0-623) whcih holds the trigger sample
	reg [8:0] cnt;
	reg [21:0] tcount;
	reg [11:0] cur_max, cur_min;

	wire writing, timeout; //timeout is a forced trigger to ensure minimum number of measurements per second/recorrect incorrect trigger --> ~9meas/s at 5ms/div worst case
	wire [9:0] start, rd_addr;
	wire [10:0] rsum; //reach 1246 (623+623)

	assign writing = tick & ((state == PREFILL) | (state == WAIT) | (state == POST)); //only turn on during fill states
	assign timeout = (tcount == 22'd2499999);

	always @ (posedge clk) begin
		if (!resetn) begin
			state <= ARM;
			wptr<=10'd0;
			trig_addr <= 10'd0;
			cnt <= 9'd0;
			tcount <= 22'd0;
			cur_max <= 12'd0; //min voltage possible
			cur_min <= 12'd4095; //max voltage possible
			max_l <= 12'd0;
			min_l <= 12'd0;
			trigd <= 1'b0;
		end
		else begin
			if (writing) begin //only during fill states. counts up wptr and wraps around
				wptr <= (wptr == 10'd623) ? 10'd0 : wptr + 10'd1; //move ptr up until 623 and wrap around
				if (ch0 > cur_max)
					cur_max <= ch0;
				if (ch0 < cur_min)
					cur_min <= ch0;
			end

			case (state)
				ARM: begin
					max_l <= cur_max;
					min_l <= cur_min;
					cur_max <= 12'd0;
					cur_min <= 12'd4095;
					cnt <= 9'd0;
					tcount <= 22'd0;
					state <= PREFILL;
				end
				PREFILL: begin
					if (tick) begin
						if (cnt == 9'd311) begin
							cnt <= 9'd0; //reset cnt and wait for trigger 
							state <= WAIT;
						end
						else
							cnt <= cnt + 9'd1;
					end
				end
				WAIT: begin
					if (!timeout)
						tcount <= tcount + 22'd1;
					if (tick & (crossing | timeout)) begin //wait for trigger or timeout
						trig_addr <= wptr;
						trigd <= crossing; //record whether it was trigger or timeout
						cnt <= 9'd0;
						state <= POST;
					end
				end
				POST: begin
					if (tick) begin
						if (cnt == 9'd310)
							state <= HOLD;
						else
							cnt <= cnt + 9'd1; //write 311 more samples for 312 + trigger + 311 = 624 samples
					end
				end
				HOLD: begin
					if (~freeze)
						state <= ARM;
				end
				default: state <= ARM; //never happens
			endcase
		end
	end

    //needed code for reading out of ram for later
	// assign start = (trig_addr >= 10'd312) ? trig_addr - 10'd312 : trig_addr + 10'd312; //find oldest sample, which is 312 samples before trigger
	// assign rsum = {1'b0, start} + {1'b0, rd_col}; //col c is c slots after start
	// assign rd_addr = (rsum >= 11'd624) ? rsum - 11'd624 : rsum[9:0]; // wrap r_sum around 624

	sample_ram ram (clk, writing, wptr, ch0, rd_addr, rd_data); //write to ram

endmodule
