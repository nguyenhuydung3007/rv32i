// ====================================
//	Module Instruction Memory
// + Lưu trữ chương trình (firmware)
// ====================================

module Instr_Memory (
	input [31:0] addr,				// Địa chỉ Instruction (lấy từ PC)
	output [31:0] instruction		// Instruction trả về CPU	
);

	(* ramstyle = "M9K" *) reg [31:0] mem [0:1023];		// Bộ nhớ lưu firmware
	
	// Load firmware
	initial begin
		$readmemh("firmware.hex", mem);
	end
	
	assign instruction = mem[addr[11:2]];		

endmodule