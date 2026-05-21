transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {uart.vo}

vlog -vlog01compat -work work +incdir+D:/1\ -\ FPGA/5\ -\ RISCV/3\ -\ UART/UART {D:/1 - FPGA/5 - RISCV/3 - UART/UART/tb_UART_Rx.v}

vsim -t 1ps -L altera_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L gate_work -L work -voptargs="+acc"  tb_UART_Rx

add wave *
view structure
view signals
run -all
