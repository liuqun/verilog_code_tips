// 模块名: sort2()
// ---------------
// 2个任意长度无符号整数的排序
//
// 输出: 排序结果, 其中高字节存放最大值, 低字节存放最小值.
module sort2 #(
	parameter DATA_WIDTH=8
)(
	input wire [DATA_WIDTH*2-1:0] data,// 2个无符号整数, 输入
	output wire [DATA_WIDTH*2-1:0] dataout// 2个无符号整数, 排序完成后输出
);

localparam W=DATA_WIDTH;
wire [W-1:0] a[1:0];

assign a[0] = data[W-1:0];
assign a[1] = data[W*2-1:W];
assign dataout = (a[0] > a[1])? ({a[0], a[1]}):({a[1], a[0]});

endmodule
