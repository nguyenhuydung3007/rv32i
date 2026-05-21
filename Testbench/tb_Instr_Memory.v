// ===============================================
// Testbench Instruction Memory
// ===============================================

`timescale 1ns/1ps

module tb_Instr_Memory;

	reg [31:0] addr;
	wire [31:0] instruction;
	
	integer i;
	
	Instr_Memory Instr_Memory_uut (
		.addr				(addr),
		.instruction 	(instruction)
	);
	
	initial begin
		addr = 0;
		
		for (i = 0; i < 30; i = i + 1) begin
			#10
			addr = addr + 4;
		end
		
		#10 $finish;
	end

endmodule