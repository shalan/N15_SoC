`define TB_CLK_GEN(clk, period)\
    initial clk = 1'b0;\
    always #(period/2) clk = ~ clk;


`define TB_RESET_SYNC(clk, rst, level, rst_time)\
    initial begin\
        rst = 1'bx;\
        #33;\
        rst = level;\
        #rst_time;\
        @(posedge clk);\
        rst = ~level;\
    end\

`define TB_RESET_ASYNC(rst, level, rst_time)\
    initial begin\
        rst = 1'bx;\
        #33;\
        rst = level;\
        #rst_time;\
        rst = ~level;\
    end\


`define TB_INIT(top, vcd_file, dump_level, sim_duration)\
    initial begin\
        $dumpfile(vcd_file);\
        $dumpvars(dump_level, top);\
        #sim_duration;\
        $finish;\
    end\


