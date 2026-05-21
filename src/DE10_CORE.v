// =========================================================
// Module DE10_CORE
// + Module Top: Kết nối với kit DE10-Lite	
// =========================================================

module DE10_CORE (
	
	input CLOCK_50,
	input [1:0] KEY,
	input [7:0] SW,
	
	output [7:0] LEDR,
	
	// UART GPIO
	input GPIO0,
	output GPIO1,
	
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5
);

	CORE CORE_uut (
		.clk		(CLOCK_50),
		.reset	(~KEY[0]),
		.SW		(SW),
		.KEY		(KEY),
		.LEDR		(LEDR),
		.uart_rx (GPIO0),
		.uart_tx	(GPIO1),
		.HEX0		(HEX0),
		.HEX1		(HEX1),
		.HEX2		(HEX2),
		.HEX3		(HEX3),
		.HEX4		(HEX4),
		.HEX5		(HEX5)
	);

endmodule