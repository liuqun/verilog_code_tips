// 模块名: rsort2()
// ----------------
// 对2个任意长度无符号整数按降序进行排序
//
// 输出: 排序结果, 其中低字节输出最大值, 高字节输出最小值.
// rsort2与sort2顺序相反.
module rsort2 #(
	parameter DATA_WIDTH=8
)(
	input wire [DATA_WIDTH*2-1:0] data,// 2个无符号整数, 输入
	output wire [DATA_WIDTH*2-1:0] dataout// 2个无符号整数, 排序完成后输出
);

localparam W=DATA_WIDTH;
wire [W-1:0] a[1:0];

assign a[0] = data[W-1:0];
assign a[1] = data[W*2-1:W];
assign dataout = (a[0] > a[1])? ({a[1], a[0]}):({a[0], a[1]});

endmodule
