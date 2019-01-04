module debouncer
	#(
		parameter CLK_FREQ_HZ = 50_000_000,  // 时钟频率(默认使用开发板自带50MHz晶振时钟), 单位: Hz
		parameter INTERVAL_MS = 40  // 消抖间隔近似值, 单位: ms
	)
	(
		input wire clk,
		input wire reset,
		input wire sw,
		output reg db_level,
		output reg db_tick
	);

// 状态寄存器相关常量和变量定义
localparam [1:0]
	STATE_LOW_VOLTAGE = 2'b00,
	STATE_RAISING_EDGE = 2'b01,
	STATE_HIGH_VOLTAGE = 2'b11,
	STATE_FALLING_EDGE = 2'b10;
reg [1:0] state_reg;
reg [1:0] state_next;

// 状态寄存器时序逻辑
always @(posedge clk, posedge reset)
begin
	if (reset)
		state_reg <= STATE_LOW_VOLTAGE;
	else
		state_reg <= state_next;
end

// 递减计数器相关常量和变量定义
localparam CLK_PERIOD_NS = (1_000_000_000 / CLK_FREQ_HZ);// 例如: 频率=50MHz则周期=20ns; 频率=100MHz则周期=10ns
localparam N = log2(1_000_000 * (INTERVAL_MS/CLK_PERIOD_NS));// 例如: 令2^N * 20ns ≈ 40ms, 则N=log2(40ms/20ns)=21（其中1ms=1_000_000ns）
localparam CNT_VALUE_MAX = {N{1'b1}};// 递减计数器最大值=(2^N - 1)
localparam CNT_VALUE_0 = {N{1'b0}};
reg [N-1:0] cnt_reg;
wire [N-1:0] cnt_next;
reg cnt_load;
wire cnt_end_tick;

// 递减计数器时序逻辑
always @(posedge clk, posedge reset)
begin
	if (reset)
		cnt_reg <= CNT_VALUE_0;
	else
		cnt_reg <= cnt_next;
end

// 递减计数器的 next-state 组合逻辑
assign cnt_next =
	cnt_load?  CNT_VALUE_MAX :
		(
			(CNT_VALUE_0 == cnt_reg)?  CNT_VALUE_0 :
				(
					cnt_reg - 1'b1  // cnt_next=(cnt_reg - 1)
				)
		)
	;

// 有限状态机控制通道的 next-state 组合逻辑
always @*
begin
	state_next = state_reg;  // default state: the same
	cnt_load = 1'b0;  // default
	db_tick = 1'b0;  // default
	case (state_reg[1:0])
		STATE_LOW_VOLTAGE:
			begin
				db_level = 1'b0;
				if (sw)
					begin
						state_next = STATE_RAISING_EDGE;
						cnt_load = 1'b1;
					end
			end
		STATE_RAISING_EDGE:
			begin
				db_level = 1'b0;
				if (CNT_VALUE_0 == cnt_reg)
					begin
						if (~sw)
							begin
								state_next = STATE_LOW_VOLTAGE; // back to previous state
							end
						else
							begin
								state_next = STATE_HIGH_VOLTAGE;
								db_tick = 1'b1; // output
							end
					end
			end
		STATE_HIGH_VOLTAGE:
			begin
				db_level = 1'b1;
				if (~sw)
					begin
						state_next = STATE_FALLING_EDGE;
						cnt_load = 1'b1;
					end
			end
		STATE_FALLING_EDGE:
			begin
				db_level = 1'b1;
				if (CNT_VALUE_0 == cnt_reg)
					begin
						if (sw)
							begin
								state_next = STATE_HIGH_VOLTAGE; // back to previous state
							end
						else
							begin
								state_next = STATE_LOW_VOLTAGE;
							end
					end
			end
		default:
			begin
				state_next = STATE_LOW_VOLTAGE;
			end
	endcase
end

// log2 辅助计算
function integer log2(input integer x);
	integer i;
	begin
		log2 = 1;
		for (i = 0; 2**i < x; i = i + 1) begin
			log2 = i + 1;
		end
	end
endfunction

endmodule
