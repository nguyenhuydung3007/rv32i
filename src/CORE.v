// =================================================
// Module CORE (Version 4 - 31/03/2026)
// Module TOP project
// ================================================

module CORE (
	
	input clk,
	input reset,
	
	// GPIO
	input [1:0] KEY,
	input [7:0] SW,
	output [7:0] LEDR,
	
	// UART Pins
	input uart_rx,
	output uart_tx,
	
	// Màn hình LED 7 đoạn
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5
	
);

	// ================================
	// PC (Program Counter)
	// ================================
	
	wire [31:0] pc_out;
	wire [31:0] pc_next;
	
	reg [7:0] led_reg;
	
	reg [31:0] wr_data;
	
	Program_Counter PC_uut (
		.clk			(clk),
		.pc_reset	(reset),
		.stall		(1'b0),
		.pc_in		(pc_next),
		.pc_out		(pc_out)
	);
	
	// ================================
	// Instruction Memory
	// ================================
	
	wire [31:0] instruction;
	
	Instr_Memory IM_uut (
		.addr				(pc_out),
		.instruction	(instruction)
	);
	
	// ================================
	// Decode
	// ================================
	
	wire [6:0] opcode;
	wire [2:0] funct3;
	wire [6:0] funct7;
	
	wire is_rtype;
	wire is_itype;
	wire is_load;
	wire is_store;
	wire is_branch;
	wire is_jal;
	wire is_jalr;
	wire is_lui;
	wire is_auipc;
	
	Decode DC_uut (
		.instruction	(instruction),
		.opcode			(opcode),
		.funct3			(funct3),
		.funct7			(funct7),
		.is_rtype		(is_rtype),
		.is_itype		(is_itype),
		.is_load			(is_load),
		.is_store		(is_store),
		.is_branch		(is_branch),
		.is_jal			(is_jal),
		.is_jalr			(is_jalr),
		.is_lui			(is_lui),
		.is_auipc		(is_auipc)
	);
	
	// =================================
	// Control
	// =================================
	
	wire BrEq;
	wire BrLt;
	
	wire Asel;
	wire Bsel;
	wire RegWEn;
	wire MemRead;
	wire MemWrite;
	wire [1:0] WBsel;
	wire PCSel;
	wire BrUn;
	wire [2:0] ImmSel;
	
	Control CT_uut (
		.instruction	(instruction),
		.BrEq				(BrEq),
		.BrLt				(BrLt),
		.is_rtype		(is_rtype),
		.is_itype		(is_itype),
		.is_load			(is_load),
		.is_store		(is_store),
		.is_branch		(is_branch),
		.is_jal			(is_jal),
		.is_jalr			(is_jalr),
		.is_lui			(is_lui),
		.is_auipc		(is_auipc),
		.Asel				(Asel),
		.Bsel				(Bsel),
		.RegWEn			(RegWEn),
		.MemRead			(MemRead),
		.MemWrite		(MemWrite),
		.WBsel			(WBsel),
		.PCSel			(PCSel),
		.BrUn				(BrUn),
		.ImmSel			(ImmSel)
	);
	
	// ===================================
	// Register
	// ===================================
	
	wire [31:0] rs1_data;
	wire [31:0] rs2_data;
	
	Regfile RF_uut (
		.clk			(clk),
		.reset_n		(~reset),
		.write_en	(RegWEn),
		.rs1_Add		(instruction[19:15]),
		.rs2_Add		(instruction[24:20]),
		.rd_Add		(instruction[11:7]),
		.wr_data		(wr_data),
		.rs_data1	(rs1_data),
		.rs_data2	(rs2_data)
	);
	
	// ===================================
	// ImmGen
	// ===================================
	
	wire [31:0] imm;
	
	ImmGen IG_uut (
		.instruction	(instruction),
		.ImmSel			(ImmSel),
		.imm				(imm)
	);
	
	// =============================================
	// ALU 
	// =============================================
	
	wire [31:0] alu_in1 = Asel ? pc_out : rs1_data;
	wire [31:0] alu_in2 = Bsel ? imm		: rs2_data;
	
	wire [3:0] alu_op;
	wire [31:0] alu_result;
	
	ALU_Control AC_uut (
		.opcode	(opcode),
		.funct3	(funct3),
		.funct7	(funct7),
		.alu_op	(alu_op)
	);
	
	ALU ALU_uut (
		.aluIn1	(alu_in1),
		.aluIn2	(alu_in2),
		.alu_op	(alu_op),
		.result	(alu_result),
		.zero		(zero)
	);
	
	// ======================================
	// Branch
	// ======================================
	
	Branch BR_uut (
		.A		(rs1_data),
		.B		(rs2_data),
		.BrUn	(BrUn),
		.BrEq	(BrEq),
		.BrLt	(BrLt)
	);
	
	// ==========================================
	// Memory + GPIO
	// + Điều khiển RAM ghi vào Memory hay GPIO
	// ==========================================
	
	wire [31:0] ram_data;
	wire [31:0] gpio_data;
	
	wire [31:0] data_out;
	
	// Địa chỉ của GPIO
	parameter GPIO_OUT_ADDR 	= 32'h1000_0000;
	parameter GPIO_IN_ADDR		= 32'h1000_0004;
	parameter SEG_ADDR			= 32'h1000_0008;
	parameter SW_ADDR				= 32'h1000_000C;
	parameter KEY_ADDR			= 32'h1000_0020;
	
	// UART
	parameter UART_TX_ADDR		= 32'h1000_0010;
	parameter UART_RX_ADDR		= 32'h1000_0014;
	parameter UART_STATUS_ADDR	= 32'h1000_0018;
	
	// GPIO
	wire is_key = (alu_result == KEY_ADDR);
	wire is_sw 	= (alu_result == SW_ADDR);
	
	// LEDR
	wire is_gpio = (alu_result == GPIO_OUT_ADDR) || (alu_result == GPIO_IN_ADDR);
	
	// Màn hình LED 7 đoạn
	wire is_seg7 = (alu_result == SEG_ADDR);
	
	// UART
	wire is_uart_tx = (alu_result == UART_TX_ADDR);
	wire is_uart_rx = (alu_result == UART_RX_ADDR);
	wire is_uart_status = (alu_result == UART_STATUS_ADDR);
	
	// Điều khiển tín hiệu ghi vào Memory hoặc GPIO
//	wire ram_we = MemWrite && !is_gpio;
//	wire ram_re = MemRead && !is_gpio;
	
	wire ram_we = MemWrite && 
						!is_gpio && 
						!is_uart_tx && 
						!is_uart_rx && 
						!is_uart_status && 
						!is_seg7 &&
						!is_sw &&
						!is_key;
						
	wire ram_re = MemRead && 
						!is_gpio && 
						!is_uart_tx && 
						!is_uart_rx && 
						!is_uart_status && 
						!is_seg7 &&
						!is_sw &&
						!is_key;
	
	wire gpio_we = MemWrite && is_gpio;
	wire gpio_re = MemRead && is_gpio;
	
	// LED 7 đoạn
	wire seg7_we = MemWrite && is_seg7;
	
	// UART
	wire uart_we = MemWrite && is_uart_tx;
	wire uart_re = MemRead  && is_uart_rx;
	
	// =========================================
	// Data_RAM
	// =========================================
	
	Data_RAM DR_uut (
		.clk			(clk),
		.addr			(alu_result),
		.wr_data		(rs2_data),
		.read_en		(ram_re),
		.write_en	(ram_we),
		.rd_data		(ram_data)
	);
	
	// =========================================
	// GPIO
	// =========================================
	
	wire [7:0] led_gpio;
	
	 GPIO	GPIO_uut (
		.clk			(clk),
		.reset		(reset),
		.addr			(alu_result),
		.wr_data		(rs2_data),
		.write_en	(gpio_we),
		.read_en		(gpio_re),
		.rd_data		(gpio_data),
		.gpio_in		(SW),
		.gpio_out	(led_gpio)
	);
	
	// =========================================
	// Màn hình LED 7 đoạn
	// =========================================
	
	Hex7_Seg HEX_uut (
		.clk			(clk),
		.reset		(reset),
		.write_en	(seg7_we),
		.wr_data		(rs2_data),
		.HEX0			(HEX0),
		.HEX1			(HEX1),
		.HEX2			(HEX2),
		.HEX3			(HEX3),
		.HEX4			(HEX4),
		.HEX5			(HEX5)
	);
	
	// =========================================
	// UART
	// =========================================
	
	wire [7:0] uart_rx_data;
	wire tx_full;
	wire rx_empty;
	
	reg uart_tx_wr_en;
	reg [7:0] uart_tx_data;
	reg uart_rx_rd_en;
	
	UART uart_inst (
		.clk			(clk),
		.reset		(reset),
		.rx			(uart_rx),
		.tx			(uart_tx),
		.tx_wr_en	(uart_tx_wr_en),
		.tx_data		(uart_tx_data),
		.tx_full		(tx_full),
		.rx_rd_en	(uart_rx_rd_en),
		.rx_data		(uart_rx_data),
		.rx_empty	(rx_empty),
		.rx_irq		()
	);
	
	// =========================================
	// FIX TIMING FIFO
	// =========================================

	reg [7:0] uart_rx_data_reg;
	
//	always @(posedge clk)
//		begin
//			if (reset)
//				begin
//					uart_rx_data_reg <= 0;
//				end
//			else if (uart_rx_rd_en)
//				begin
//					uart_rx_data_reg <= uart_rx_data;
//				end
//		end
	
	always @(posedge clk)
		begin
			if (reset)
				begin
					uart_rx_data_reg <= 0;
				end
				
			else 
				begin
					uart_rx_data_reg <= uart_rx_data;
				end
		end
	
	// TX
	
	always @(posedge clk) 
		begin
			uart_tx_wr_en	<= 0;
			
			if (MemWrite && is_uart_tx && !tx_full)
				begin
					uart_tx_wr_en	<= 1;
					uart_tx_data	<= rs2_data[7:0];
				end
		end
		
	// RX
	
//	always @(posedge clk) 
//		begin
//			uart_rx_rd_en	<= 0;
//			
//			if (MemRead && is_uart_rx && !rx_empty)
//				begin
//					uart_rx_rd_en <= 1;
//				end
//		end

	// RX FIX V2
	always @(posedge clk)
		begin
			if (reset)
				begin
					uart_rx_rd_en <= 0;
				end
			
			else 
				begin
					uart_rx_rd_en <= !rx_empty;
				end
		end
	
	// READ MUX
	
	wire [31:0] uart_data;
	
	assign uart_data = 
				is_uart_rx 		? {24'b0, uart_rx_data_reg} :
				is_uart_status ? {30'b0, tx_full, rx_empty}:
				32'b0;

	
	//assign data_out = is_gpio ? gpio_data : ram_data;
	assign data_out =
				is_gpio ? gpio_data :
				is_sw	  ? {24'b0, SW} :
				is_key  ? {30'b0, KEY} :
				(is_uart_rx || is_uart_status) ? uart_data :
				ram_data;
	
	// =======================================
	// WRITE BACK
	// =======================================
	
	always @(*) begin
		
		case (WBsel)
			
			2'b00: wr_data = alu_result;
			
			2'b01: wr_data = data_out;
			
			2'b10: wr_data = pc_out + 4;
			
			default: wr_data = 32'b0;
			
		endcase
		
	end
	
	// ========================================
	// PC Logic
	// ========================================
	
	PC_Logic PCL_uut (
		.pc_current		(pc_out),
		.imm				(imm),
		.rs1_data		(rs1_data),
		.PCSel			(PCSel),
		.is_jalr			(is_jalr),
		//.is_jal			(is_jal),
		//.is_branch		(is_branch),
		.pc_next			(pc_next)
	);
	
	
	// ==========================================
	// OUTPUT REGISTER (LEDR)
	// ==========================================
	
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			led_reg <= 8'b0;
		end
		
		else begin
			led_reg <= led_gpio;
		end
	end
	
	assign LEDR = led_reg;
	
	
	// ========================================
	// Debug
	// ========================================
	
	// Debug GPIO
	//assign LEDR = wr_data[7:0];	// Debug wr_data
	
	// Debug Regfile
	//assign LEDR = rs2_data[7:0];
	
	
//	reg [25:0] counter;
//
//always @(posedge clk) begin
//    counter <= counter + 1;
//end

//assign LEDR = counter[25:18];

//assign LEDR = {7'b0, reset};

endmodule