<<<<<<< HEAD
// ADC.v

`timescale 1 ps / 1 ps
module ADC (
=======
// ADC.v

`timescale 1 ps / 1 ps
module ADC (
>>>>>>> 14c9a331b9d47a5cab79046af6a4f57769a84eb2
		input  wire        CLOCK,    //                clk.clk
		output wire        ADC_SCLK, // external_interface.SCLK
		output wire        ADC_CS_N, //                   .CS_N
		input  wire        ADC_DOUT, //                   .DOUT
		output wire        ADC_DIN,  //                   .DIN
		output wire [11:0] CH0,      //           readings.CH0
		output wire [11:0] CH1,      //                   .CH1
		output wire [11:0] CH2,      //                   .CH2
		output wire [11:0] CH3,      //                   .CH3
		output wire [11:0] CH4,      //                   .CH4
		output wire [11:0] CH5,      //                   .CH5
		output wire [11:0] CH6,      //                   .CH6
		output wire [11:0] CH7,      //                   .CH7
		input  wire        RESET     //              reset.reset
<<<<<<< HEAD
	);

	ADC_adc_mega_0 #(
		.board          ("DE10-Standard"),
		.board_rev      ("Autodetect"),
		.tsclk          (4),
		.numch          (0), // only one channel is read
		.max10pllmultby (1),
		.max10plldivby  (1)
=======
	);

	ADC_adc_mega_0 #(
		.board          ("DE10-Standard"),
		.board_rev      ("Autodetect"),
		.tsclk          (4),
		.numch          (0), // only one channel is read
		.max10pllmultby (1),
		.max10plldivby  (1)
>>>>>>> 14c9a331b9d47a5cab79046af6a4f57769a84eb2
	) adc_mega_0 (
		.CLOCK    (CLOCK),    //                clk.clk
		.RESET    (RESET),    //              reset.reset
		.CH0      (CH0),      //           readings.export
		.CH1      (CH1),      //                   .export
		.CH2      (CH2),      //                   .export
		.CH3      (CH3),      //                   .export
		.CH4      (CH4),      //                   .export
		.CH5      (CH5),      //                   .export
		.CH6      (CH6),      //                   .export
		.CH7      (CH7),      //                   .export
		.ADC_SCLK (ADC_SCLK), // external_interface.export
		.ADC_CS_N (ADC_CS_N), //                   .export
		.ADC_DOUT (ADC_DOUT), //                   .export
		.ADC_DIN  (ADC_DIN)   //                   .export
<<<<<<< HEAD
	);

endmodule
=======
	);

endmodule
>>>>>>> 14c9a331b9d47a5cab79046af6a4f57769a84eb2
