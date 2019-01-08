module uart_rx
	#(
	parameter N_DATA_BITS = 8, // 串口数据位个数, 取值范围: 5, 6, 7, 8, 默认值: 8位
	          HOW_MANY_TICKS_FOR_STOP_BIT = 16
	)
	(
	input wire clk,
	input wire reset,
	input wire rx,
	input wire s_tick,
	output reg rx_done_tick,
	output wire [7:0] dout
	);

// symbolic state declaration for UART receiver
localparam [1:0]
	idle = 2'b00,
	start = 2'b01,
	data = 2'b10,
	stop = 2'b11;

// state register
reg [1:0] state_reg, state_next;

// signal declaration
reg [7:0] b_reg, b_next; // 数据位在寄存器内每个周期向右移1bit
reg [2:0] n_reg, n_next;
reg [3:0] s_reg, s_next; // 作为s_tick的计数器, 递增计数

// body
// FSMD state and data registers
always @(posedge clk, posedge reset)
begin
	if (reset)
		begin
			state_reg <= idle;
			b_reg <= 8'b0;
			n_reg <= 3'd0;
			s_reg <= 4'd0;
		end
	else
		begin
			state_reg <= state_next;
			b_reg <= b_next;
			n_reg <= n_next;
			s_reg <= s_next;
		end
end

// FSMD next-state logic
always @*
begin
	rx_done_tick = 1'b0;
	state_next = state_reg;
	b_next = b_reg;
	n_next = n_reg;
	s_next = s_reg;
	case (state_reg)
		/* 空闲位阶段 */
		idle:
		if (rx == 1'b0)
			begin
				state_next = start; // 当rx首次出现低电平时空闲位结束, 准备进入下一状态读起始位
				s_next = 0;
			end
		/* 起始位阶段 */
		start:
		if (s_tick)
			begin
				s_next = s_reg + 1;
				if (s_reg == 7)
					begin
						s_next = 0;
						state_next = data; // 准备开始读数据位
						n_next = 0;
					end
			end
		/* 数据位阶段 */
		data:
		if (s_tick)
			begin
				s_next = s_reg + 1;
				if (s_reg == (16-1))
					begin
						s_next = 0;
						b_next = {rx, b_reg[7:1]};
						n_next = n_reg + 1;
						if (n_reg == (N_DATA_BITS-1))
							begin
								state_next = stop;
								//n_next = n_reg;
							end
					end
			end
		/* 停止位阶段 */
		stop:
		if (s_tick)
			begin
				s_next = s_reg + 1;
				if (s_reg == (HOW_MANY_TICKS_FOR_STOP_BIT-1))
					begin
						rx_done_tick = 1'b1;
						state_next = idle;
						//s_next = s_reg;
					end
			end
	endcase
end

// output
assign dout = b_reg;

endmodule
