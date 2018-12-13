module sort4 #(
	parameter DATA_WIDTH = 8
)(
	input wire reset,
	input wire [DATA_WIDTH*4-1:0] data,// 四个无符号整数
	output wire [DATA_WIDTH*4-1:0] dataout// 四个无符号整数, 排序完成后输出, 约定默认低字节输出最小值, 高字节输出最大值
);

localparam W = DATA_WIDTH;
wire [W-1:0] a, b, c, d;
wire [W-1:0] m, n;
wire [W*4-1:0] result;

// stage1: 输出分组排序结果, 其中 a>b, c>d
sort2 #(
	.DATA_WIDTH(W)
) stage1_sort_a_b (
	.data(data[W*4-1:W*2]),
	.dataout({a, b})
);
sort2 #(
	.DATA_WIDTH(W)
) stage1_sort_c_d (
	.data(data[W*2-1:0]),
	.dataout({c, d})
);

// stage2: 输出最大值=maxof(a,c) 最小值=minof(b,d) 排第二或三位的中间值m,n
sort2 #(
	.DATA_WIDTH(W)
) stage2_maxof (
	.data({a, c}),
	.dataout({result[W*4-1:W*3], m})
);
sort2 #(
	.DATA_WIDTH(W)
) stage2_minof (
	.data({b, d}),
	.dataout({n, result[W-1:0]})
);

// stage3: 比较中间值m,n
// 输出第二大=maxof(m,n) 和倒数第二小=minof(m,n)
sort2 #(
	.DATA_WIDTH(W)
) stage3_middle (
	.data({m, n}),
	.dataout(result[W*3-1:W])
);

// 输出排序结果
localparam ALL_ZEROS = {(W*4){1'b0}};
assign dataout = (reset)? (ALL_ZEROS):(result);

endmodule
