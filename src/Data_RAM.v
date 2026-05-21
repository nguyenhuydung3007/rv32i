// =========================================
// Module Data_RAM
// + Bộ nhớ của CPU
// + Lưu dữ liệu của chương trình
// =========================================

module Data_RAM (
	input clk,
	input [31:0] addr,			// Địa chỉ cần truy cập vào RAM
	input [31:0] wr_data,		// Dữ liệu cần ghi vào RAM
	input read_en,					// Tín hiệu cho phép đọc dữ liệu trong RAM
	input write_en,				// Tín hiệu cho phép ghi dữ liệu vào RAM
	
	// Test
	//output [31:0] wr_data_test,// Kiểm tra dữ liệu ghi vào RAM
	
	output reg [31:0] rd_data	// Dữ liệu đọc ra từ RAM
	
);

	(* ramstyle = "M9K" *) reg [31:0] mem [0:1023];		// Bộ nhớ lưu firmware
	
	integer i;
	
	// Khởi tạo giá trị cho mem ban đầu
	initial begin
		for (i = 0; i < 1023; i = i + 1) begin
			mem[i] = 32'b0;
		end
	end
	
	always @(posedge clk) begin
		// Ghi dữ liệu vào RAM
		
		if (write_en) begin
			mem[addr[11:2]] <= wr_data;
		end
		
	end
	
	always @(*) begin
	
		if (read_en) begin
			rd_data = mem[addr[11:2]];
		end
		
		else begin
			rd_data = 32'b0;
		end
		
	end
	
	
endmodule