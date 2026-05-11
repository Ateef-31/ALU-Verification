module tb_alu();
parameter b = 8;
parameter c = 4;
reg clk, rst, mode, ce, cin;
reg [b-1:0] opa, opb;
reg [1:0] inp_valid;
reg [c-1:0] cmd;
reg [2*b-1:0] res_ref_latch;
reg oflow_ref_latch, err_ref_latch;
reg g_ref_latch, l_ref_latch, e_ref_latch, cout_ref_latch;
wire [2*b-1:0] res_dut;
wire oflow_dut, err_dut, l_dut, e_dut, g_dut, cout_dut;
wire [2*b-1:0] res_ref;
wire oflow_ref, err_ref, l_ref, e_ref, g_ref, cout_ref;
integer pass_count, fail_count;

alu_dut #(b) dut (
    .clk(clk),
    .rst(rst),
    .ce(ce),
    .cin(cin),
    .mode(mode),
    .opa(opa),
    .opb(opb),
    .cmd(cmd),
    .inp_valid(inp_valid),
    .res(res_dut),
    .oflow(oflow_dut),
    .err(err_dut),
    .l(l_dut),
    .e(e_dut),
    .g(g_dut),
    .cout(cout_dut)
);

reference_alu #(b,c) ref (
    .rst(rst),
    .ce(ce),
    .cin(cin),
    .mode(mode),
    .inp_valid(inp_valid),
    .cmd(cmd),
    .opa(opa),
    .opb(opb),
    .res(res_ref),
    .g(g_ref),
    .l(l_ref),
    .e(e_ref),
    .err(err_ref),
    .oflow(oflow_ref),
    .cout(cout_ref)
);

initial clk = 0;
always #5 clk = ~clk;

// ============================================================
// TASK: apply single-cycle or multi-cycle (MUL) test
// ============================================================
task apply;
    input [50*8:1] id;
    input t_rst;
    input t_mode;
    input t_ce;
    input t_cin;
    input [1:0] t_inp_valid;
    input [c-1:0] t_cmd;
    input [b-1:0] t_opa;
    input [b-1:0] t_opb;
    begin
        @(posedge clk);
        rst       = t_rst;
        mode      = t_mode;
        ce        = t_ce;
        cin       = t_cin;
        inp_valid = t_inp_valid;
        cmd       = t_cmd;
        opa       = t_opa;
        opb       = t_opb;

        if((t_mode == 1'b1) && ((t_cmd == 4'd9) || (t_cmd == 4'd10))) begin
            @(posedge clk);
            @(posedge clk);
        end
        else begin
            @(posedge clk);
        end

        #1;

        if ((res_dut   === res_ref)   &&
            (err_dut   === err_ref)   &&
            (oflow_dut === oflow_ref) &&
            (g_dut     === g_ref)     &&
            (l_dut     === l_ref)     &&
            (e_dut     === e_ref)     &&
            (cout_dut  === cout_ref))
        begin
            $display("PASS [%0s]", id);
            $display("  DUT: res=%0d oflow=%0b err=%0b g=%0b l=%0b e=%0b cout=%0b",
                      res_dut, oflow_dut, err_dut, g_dut, l_dut, e_dut, cout_dut);
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL [%0s]", id);
            $display("  DUT: res=%b oflow=%0b err=%0b g=%0b l=%0b e=%0b cout=%0b",
                      res_dut, oflow_dut, err_dut, g_dut, l_dut, e_dut, cout_dut);
            $display("  REF: res=%b oflow=%0b err=%0b g=%0b l=%0b e=%0b cout=%0b",
                      res_ref, oflow_ref, err_ref, g_ref, l_ref, e_ref, cout_ref);
            fail_count = fail_count + 1;
        end
    end
endtask

// ============================================================
// TASK: mul_check compares against latched reference
// ============================================================
task mul_check;
    input [50*8:1] id;
    begin
        #1;
        if ((res_dut   === res_ref_latch)   &&
            (err_dut   === err_ref_latch)   &&
            (oflow_dut === oflow_ref_latch) &&
            (g_dut     === g_ref_latch)     &&
            (l_dut     === l_ref_latch)     &&
            (e_dut     === e_ref_latch)     &&
            (cout_dut  === cout_ref_latch))
        begin
            $display("PASS [%0s]", id);
            $display("  DUT: res=%0d oflow=%0b err=%0b g=%0b l=%0b e=%0b cout=%0b",
                      res_dut, oflow_dut, err_dut, g_dut, l_dut, e_dut, cout_dut);
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL [%0s]", id);
            $display("  DUT: res=%b oflow=%0b err=%0b g=%0b l=%0b e=%0b cout=%0b",
                      res_dut, oflow_dut, err_dut, g_dut, l_dut, e_dut, cout_dut);
            $display("  REF: res=%b oflow=%0b err=%0b g=%0b l=%0b e=%0b cout=%0b",
                      res_ref_latch, oflow_ref_latch, err_ref_latch,
                      g_ref_latch, l_ref_latch, e_ref_latch, cout_ref_latch);
            fail_count = fail_count + 1;
        end
    end
endtask

// ============================================================
// MAIN TEST SEQUENCE
// ============================================================
initial begin

    pass_count = 0;
    fail_count = 0;

    rst       = 1;
    mode      = 0;
    ce        = 0;
    cin       = 0;
    inp_valid = 2'b00;
    cmd       = 4'b0000;
    opa       = 0;
    opb       = 0;

    repeat(4) @(posedge clk);
    rst = 0;
    repeat(2) @(posedge clk);

    // ============================================================
    // ARITHMETIC TESTS
    // Feature Name, RST, MODE, CE, CIN, INP_VALID, CMD, OPA, OPB
    // ============================================================

    apply("RST",                    0,1,1,0, 2'b11, 4'd0,  8'd3,    8'd5);

    // -- ADD (cmd=0) --
    apply("ADD",                    0,1,1,0, 2'b11, 4'd0,  8'd10,   8'd20);
    apply("ADD_zero_operands",      0,1,1,0, 2'b11, 4'd0,  8'd0,    8'd0);
    apply("ADD_MAX_MIN",            0,1,1,0, 2'b11, 4'd0,  8'd255,  8'd0);
    apply("ADD_WITHOUT_CIN_VALUE",  0,1,1,1, 2'b11, 4'd0,  8'd4,    8'd7);
    apply("MODE_VALUE_GREATER_THAN_1",  0,1,3,1, 2'b11, 4'd0,  8'd4,    8'd7);    
    apply("ADD_CARRY_OUT_96",       0,1,1,0, 2'b11, 4'd0,  8'd255,  8'd1);
    apply("ADD_max_overflow",       0,1,1,0, 2'b11, 4'd0,  8'd255,  8'd255);
    apply("OFLOW_TRIGGER",          0,1,1,0, 2'b11, 4'd0,  8'd255,  8'd255);
    apply("OFLOW_CLEARS",           0,1,1,0, 2'b11, 4'd0,  8'd10,   8'd20);
    // ADD invalid input
    apply("ADD_WITH_INVALID_INP",   0,1,1,0, 2'b00, 4'd0,  8'd12,   8'd20);

    // -- SUB (cmd=1) --
    apply("SUB",                    0,1,1,0, 2'b11, 4'd1,  8'd30,   8'd10);
    apply("SUB_ZERO",               0,1,1,0, 2'b11, 4'd1,  8'd0,    8'd0);
    apply("SUB_OPA_OPB_INV_INPUT",  0,1,1,0, 2'b10, 4'd1,  8'd50,   8'd20);
    apply("SUB_OPA_OPB_CIN_INV",    0,1,1,1, 2'b00, 4'd1,  8'd5,    8'd2);

    // -- ADD_CIN (cmd=2) --
    apply("ADD_CIN",                0,1,1,1, 2'b11, 4'd2,  8'd10,   8'd20);
    apply("ADD_CIN_CARRY_116",      0,1,1,1, 2'b11, 4'd2,  8'd255,  8'd1);
    apply("ADD_CIN_CARRY_116b",     0,1,1,1, 2'b11, 4'd2,  8'd200,  8'd56);
    apply("ADD_CIN_FOR_COUT",       0,1,1,1, 2'b11, 4'd2,  8'd255,  8'd1);
    apply("ADD_CIN_COUT",           0,1,1,1, 2'b11, 4'd2,  8'd255,  8'd0);
    apply("ADD_CIN_INVALID_INP",    0,1,1,0, 2'b10, 4'd2,  8'd4,    8'd7);
    apply("Signed_SUB_overflow",    0,1,1,0, 2'b11, 4'd2,  8'sd127, -8'sd1);

    // -- SUB_CIN (cmd=3) --
    apply("SUB_CIN",                0,1,1,1, 2'b11, 4'd3,  8'd30,   8'd10);
    apply("SUB_CIN_OFLOW",          0,1,1,1, 2'b11, 4'd3,  8'd0,    8'd0);
    apply("SUB_CIN_OFLOW2",         0,1,1,1, 2'b11, 4'd3,  8'd0,    8'd0);
    // Line 132: opa < (opb+cin) cases
    apply("SUB_CIN_OFLOW_132a",     0,1,1,1, 2'b11, 4'd3,  8'd5,    8'd10);
    apply("SUB_CIN_OFLOW_132b",     0,1,1,1, 2'b11, 4'd3,  8'd0,    8'd5);
    apply("SUB_CIN_NOOFLOW_132",    0,1,1,1, 2'b11, 4'd3,  8'd50,   8'd10);
    apply("SUB_CIN_ERR",            0,1,1,1, 2'b00, 4'd3,  8'd10,   8'd5);

    // -- INC_A (cmd=4) --
    apply("INC_A",                  0,1,1,0, 2'b01, 4'd4,  8'd15,   8'd0);
    apply("INC_A_INPUT_VALID_2",    0,1,1,0, 2'b11, 4'd4,  8'd15,   8'd0);
    apply("INC_A_INV_INPUT",        0,1,1,0, 2'b00, 4'd4,  8'd5,    8'd0);

    // -- DEC_A (cmd=5) --
    apply("DEC_A",                  0,1,1,0, 2'b01, 4'd5,  8'd15,   8'd0);
    apply("DEC_A_INPUT_VALID_2",    0,1,1,0, 2'b11, 4'd5,  8'd15,   8'd0);
    apply("DEC_A_INV_INPUT",        0,1,1,0, 2'b10, 4'd5,  8'd0,    8'd20);

    // -- INC_B (cmd=6) --
    apply("INC_B",                  0,1,1,0, 2'b10, 4'd6,  8'd0,    8'd20);
    // Line 153: inp_valid[1]==0 ? err
    apply("INC_B_ERR_153",          0,1,1,0, 2'b00, 4'd6,  8'd0,    8'd20);
    apply("INC_B_ERR_153b",         0,1,1,0, 2'b01, 4'd6,  8'd0,    8'd20);
    apply("INC_B_INV_INPUT",        0,1,1,0, 2'b01, 4'd6,  8'd0,    8'd0);

    // -- DEC_B (cmd=7) --
    apply("DEC_B",                  0,1,1,0, 2'b10, 4'd7,  8'd0,    8'd20);
    apply("DEC_B_ERR_168",          0,1,1,0, 2'b01, 4'd7,  8'd50,   8'd1);
    apply("DEC_B_ERR_168b",         0,1,1,0, 2'b00, 4'd7,  8'd50,   8'd1);

    // -- CMP (cmd=8) --
    apply("CMP_G",                  0,1,1,0, 2'b11, 4'd8,  8'd20,   8'd10);
    apply("CMP_E",                  0,1,1,0, 2'b11, 4'd8,  8'd20,   8'd20);
    apply("CMP_L",                  0,1,1,0, 2'b11, 4'd8,  8'd10,   8'd20);
    apply("EQS_operation",          0,1,1,0, 2'b11, 4'd8,  8'd111,  8'd111);
    apply("LES_operation",          0,1,1,0, 2'b11, 4'd8,  8'd001,  8'd101);
    apply("CMP_EQ_INV_INP",         0,1,1,0, 2'b00, 4'd8,  8'd20,   8'd20);
    apply("CMP_GT_INV_INP",         0,1,1,0, 2'b01, 4'd8,  8'd20,   8'd10);
    apply("CMP_LT_INV_INP",         0,1,1,0, 2'b10, 4'd8,  8'd10,   8'd20);

    // -- MUL_INC (cmd=9) --
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'd0,    8'd0);
    apply("CMP_G",                  0,1,1,0, 2'b11, 4'd8,  8'd20,   8'd10);
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'hBF,    8'hFF);
    apply("CMP_E",                  0,1,1,0, 2'b11, 4'd8,  8'd20,   8'd20);
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'd0,    8'd0);
    apply("CMP_L",                  0,1,1,0, 2'b11, 4'd8,  8'd10,   8'd20);
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'h17,    8'hFF);
    apply("EQS_operation",          0,1,1,0, 2'b11, 4'd8,  8'd111,  8'd111);
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'd0,    8'd0);
    apply("LES_operation",          0,1,1,0, 2'b11, 4'd8,  8'd001,  8'd101);
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'd0,    8'h7F);
    apply("CMP_EQ_INV_INP",         0,1,1,0, 2'b00, 4'd8,  8'd20,   8'd20);
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'd0,    8'd0);




    apply("RST_FOR_MUL9",           1,1,1,0, 2'b11, 4'd9,  8'd5,    8'd4); 
    apply("MUL9_CYC2_AFTER_RST",    0,1,1,0, 2'b11, 4'd9,  8'd5,    8'd4);  
    apply("MUL_INC_INP_INVALID",    0,1,1,0, 2'b00, 4'd9,  8'd5,    8'd4);
    apply("MUL_INC",                0,1,1,0, 2'b11, 4'd9,  8'd5,    8'd4);
    apply("MUL_WITH_ZERO_OPA",      0,1,1,0, 2'b11, 4'd9,  8'd0,    8'd10);
    apply("MUL_WITH_ZERO",          0,1,1,0, 2'b11, 4'd9,  8'd0,    8'd0);
    apply("MUL_WITH_ZERO_OPB",      0,1,1,0, 2'b11, 4'd9,  8'd10,   8'd0);
    apply("MUL_CONSECUTIVE_1",      0,1,1,0, 2'b11, 4'd9,  8'd5,    8'd4);
    apply("MUL_CONSECUTIVE_2",      0,1,1,0, 2'b11, 4'd9,  8'd3,    8'd7);
    apply("MUL_INC_INP_INVALID",    0,1,1,0, 2'b00, 4'd9,  8'd5,    8'd4);
    apply("MUL_INC_INP_INVALID",    0,1,1,0, 2'b10, 4'd9,  8'd5,    8'd4);
    apply("MUL_INC_INP_INVALID",    0,1,1,0, 2'b01, 4'd9,  8'd5,    8'd4);
    
	

    // -- MUL_SHIFT (cmd=10) --
  
    apply("MUL_10_INC_INP_INVALID", 0,1,1,0, 2'b00, 4'd10,  8'd5,   8'd4);
    apply("RST_FOR_MUL10",          1,1,1,0, 2'b11, 4'd10, 8'd5,    8'd4);  
    apply("MUL10_CYC2_AFTER_RST",   0,1,1,0, 2'b11, 4'd10, 8'd5,    8'd4);  
    apply("MUL_SHIFT_INP_INVALID",  0,1,1,0, 2'b01, 4'd10, 8'd5,    8'd4);
    apply("MUL_SHIFT_INP_VALID_2",  0,1,1,0, 2'b10, 4'd10, 8'd5,    8'd4);

    // Back-to-back and cross-transition MUL tests (FEC condition coverage)
    apply("MUL9_BACK2BACK_1",       0,1,1,0, 2'b11, 4'd9,  8'd3,    8'd3);
    apply("MUL9_BACK2BACK_2",       0,1,1,0, 2'b11, 4'd9,  8'd4,    8'd4);
    apply("MUL10_BACK2BACK_1",      0,1,1,0, 2'b11, 4'd10, 8'd3,    8'd3);
    apply("MUL10_BACK2BACK_2",      0,1,1,0, 2'b11, 4'd10, 8'd4,    8'd4);
    apply("ADD_THEN_MUL9",          0,1,1,0, 2'b11, 4'd0,  8'd5,    8'd5);
    apply("MUL9_AFTER_ADD",         0,1,1,0, 2'b11, 4'd9,  8'd6,    8'd6);
    apply("ADD_THEN_MUL10",         0,1,1,0, 2'b11, 4'd0,  8'd5,    8'd5);
    apply("MUL10_AFTER_ADD",        0,1,1,0, 2'b11, 4'd10, 8'd6,    8'd6);
    apply("MUL9_THEN_MUL10",        0,1,1,0, 2'b11, 4'd9,  8'd3,    8'd4);
    apply("MUL10_AFTER_MUL9",       0,1,1,0, 2'b11, 4'd10, 8'd3,    8'd4);
    apply("MUL10_THEN_MUL9",        0,1,1,0, 2'b11, 4'd10, 8'd3,    8'd4);
    apply("MUL9_AFTER_MUL10",       0,1,1,0, 2'b11, 4'd9,  8'd3,    8'd4);
    apply("MUL_THEN_ADD",           0,1,1,0, 2'b11, 4'd9,  8'd5,    8'd4);
    apply("ADD_AFTER_MUL",          0,1,1,0, 2'b11, 4'd0,  8'd10,   8'd20);

    // -- SIGNED ADD (cmd=11) --
    apply("SIGNED_ADD",             0,1,1,0, 2'b11, 4'd11, 8'sd50,  8'sd20);
    apply("Signed_ADD_overflow",    0,1,1,0, 2'b11, 4'd11, 8'sd127, 8'sd1);
    apply("SIGNED_ADD_WITHOUT_OFLOW",0,1,1,0,2'b11, 4'd11, 8'sd10,  8'sd21);
    apply("SIGNED_ADD_NO_OFLOW",    0,1,1,0, 2'b11, 4'd11, 8'sd50,  8'sd20);
    apply("SIGNED_ADD_ERR",         0,1,1,0, 2'b00, 4'd11, 8'sd10,  8'sd5);

    // -- SIGNED SUB (cmd=12) --
    apply("SIGNED_SUB",             0,1,1,0, 2'b11, 4'd12, -8'sd50, 8'sd20);
    apply("SIGNED_SUB_WITHOUT_OFLOW",0,1,1,0,2'b11, 4'd12, 8'sd20,  8'sd5);
    apply("SIGNED_SUB_NO_OFLOW",    0,1,1,0, 2'b11, 4'd12, 8'sd50,  8'sd20);
    apply("SIGNED_SUB_ERR",         0,1,1,0, 2'b00, 4'd12, 8'sd20,  8'sd5);

    // -- Arithmetic CMD > 12 ? default err --
    apply("CMD_GREATER_ARITHMETIC", 0,1,1,0, 2'b11, 4'd15, -8'sd50, 8'sd20);
    apply("CMD_GT12_ARITH_13",      0,1,1,0, 2'b11, 4'd13, 8'd10,   8'd20);
    apply("CMD_GT12_ARITH_14",      0,1,1,0, 2'b11, 4'd14, 8'd10,   8'd20);
    apply("CMD_GT12_ARITH_15",      0,1,1,0, 2'b11, 4'd15, 8'd10,   8'd20);

    // -- CE / RST control --
    apply("CE_DISABLED",            0,1,0,0, 2'b11, 4'd0,  8'd10,   8'd20);
    apply("CE_REENABLED",           0,1,1,0, 2'b11, 4'd0,  8'd10,   8'd20);
    apply("RST_DURING_OP",          1,1,1,0, 2'b11, 4'd9,  8'd5,    8'd4);
    apply("NORMAL_OP_AFTER_RST",    0,1,1,0, 2'b11, 4'd0,  8'd10,   8'd20);
    apply("RST_CE_PRIORITY",        1,1,0,0, 2'b11, 4'd0,  8'd10,   8'd20);
    apply("CE_AT_ZERO",             0,1,0,0, 2'b11, 4'd0,  8'd0,    8'd0);

    // CMP after CE/RST tests
    apply("CMP_E_AFTER_RST",        0,1,1,0, 2'b11, 4'd8,  8'd00,   8'd20);

    // ============================================================
    // LOGICAL TESTS  (mode=0)
    // Feature Name, RST, MODE, CE, CIN, INP_VALID, CMD, OPA, OPB
    // ============================================================


    apply("AND",               0,0,1,0, 2'b11, 4'd0,  8'hAA,   8'h55);
    apply("NAND",              0,0,1,0, 2'b11, 4'd1,  8'hAA,   8'h55);
    apply("L_NAND_ERR",        0,0,1,0, 2'b00, 4'd1,  8'hAA,   8'h55);
    apply("L_NAND_ERR",        0,0,1,0, 2'b01, 4'd1,  8'hAA,   8'h55);
    apply("L_NAND_ERR",        0,0,1,0, 2'b10, 4'd1,  8'hAA,   8'h55);
    apply("L_NAND_INVALID_INP",     0,0,1,0, 2'b01, 4'd0,  8'hAA,   8'h55);

    // -- OR (cmd=2) --
    apply("OR",                     0,0,1,0, 2'b11, 4'd2,  8'hAA,   8'h55);
    apply("L_OR_ERR_225",           0,0,1,0, 2'b00, 4'd2,  8'hAA,   8'h55);
    apply("L_OR_ERR_225b",          0,0,1,0, 2'b01, 4'd2,  8'hAA,   8'h55);
    apply("L_OR_ERR_225c",          0,0,1,0, 2'b10, 4'd2,  8'hAA,   8'h55);
    apply("L_OR_INVALID_INP",       0,0,1,0, 2'b00, 4'd2,  8'hAA,   8'h55);

    // -- NOR (cmd=3) --
    apply("NOR",                    0,0,1,0, 2'b11, 4'd3,  8'hAA,   8'h55);
    apply("L_NOR_INVALID_INP",      0,0,1,0, 2'b10, 4'd3,  8'hAA,   8'h55);

    // -- XOR (cmd=4) --
    apply("XOR",                    0,0,1,0, 2'b11, 4'd4,  8'hAA,   8'h55);
    apply("L_XOR_INVALID_INP",      0,0,1,0, 2'b00, 4'd4,  8'hAA,   8'h55);
    apply("XOR",                    0,0,1,0, 2'b11, 4'd4,  8'hFF,   8'hFF);

    // -- XNOR (cmd=5) --
    apply("XNOR",                   0,0,1,0, 2'b11, 4'd5,  8'hAA,   8'h55);
    apply("L_XNOR_INVALID_INP",     0,0,1,0, 2'b00, 4'd5,  8'hAA,   8'h55);
    apply("XNOR",                   0,0,1,0, 2'b11, 4'd5,  8'hFF,   8'h00);

    // -- NOT_A (cmd=6) --
    apply("NOT_A",                  0,0,1,0, 2'b01, 4'd6,  8'hAA,   8'h00);
    apply("L_NOT_A_INP_INVALID",    0,0,1,0, 2'b10, 4'd6,  8'hAA,   8'h00);
    apply("L_NOT_A_B_VALUE_GIVEN",  0,0,1,0, 2'b11, 4'd6,  8'hAA,   8'h33); 
    apply("L_NOT_A_INP_INVALID_0",    0,0,1,0, 2'b00, 4'd6,  8'hAA,   8'h00);
 

    // -- NOT_B (cmd=7) --
    apply("NOT_B",                  0,0,1,0, 2'b10, 4'd7,  8'h00,   8'h55);
    apply("L_NOT_B_INP_INVALID",    0,0,1,0, 2'b01, 4'd7,  8'h00,   8'h55);
    apply("L_NOT_B_A_VALUE_GIVEN",  0,0,1,0, 2'b10, 4'd7,  8'hAA,   8'h55);
    apply("L_NOT_A_INP_INVALID_0",    0,0,1,0, 2'b00, 4'd7,  8'hAA,   8'h00);
    apply("L_NOT_A_INP_INVALID_2",    0,0,1,0, 2'b11, 4'd7,  8'hAA,   8'h00);

    // -- SHR_A (cmd=8) --
    apply("SHR_A",                  0,0,1,0, 2'b01, 4'd8,  8'hAA,   8'h00);
    apply("LOGICAL_XOR_INP_INVALID",0,0,1,0, 2'b00, 4'd8,  8'hFF,   8'h55);

    // -- SHL_A (cmd=9) --
    apply("SHL_A",                  0,0,1,0, 2'b01, 4'd9,  8'hAA,   8'h00);
    apply("SHL1_A_INV",             0,0,1,0, 2'b10, 4'd9,  8'hC3,   8'h55);

    // -- SHR_B (cmd=10) --
    apply("SHR_B",                  0,0,1,0, 2'b10, 4'd10, 8'h00,   8'h55);
    apply("SHR1_B_INV",             0,0,1,0, 2'b01, 4'd10, 8'h00,   8'h55);

    // -- SHL_B (cmd=11) --
    apply("SHL_B",                  0,0,1,0, 2'b10, 4'd11, 8'h00,   8'h55);
    apply("SHL_B_INVALID_INP",      0,0,1,0, 2'b01, 4'd11, 8'h00,   8'h55);

    // -- ROL (cmd=12) 
    apply("ROL",                    0,0,1,0, 2'b11, 4'd12, 8'hAA,   8'd3);
    apply("ROL_INVALID_INPUT",      0,0,1,0, 2'b00, 4'd12, 8'hAA,   8'd4);
    apply("ROL_ERR_LARGE_OPB",      0,0,1,0, 2'b11, 4'd12, 8'hAA,   8'd16);
    apply("ROL_OPB_ZERO",           0,0,1,0, 2'b11, 4'd12, 8'hAA,   8'd7);
    apply("ROL_OPB_ZERO",           0,0,1,0, 2'b11, 4'd12, 8'hAA,   8'd8);



    apply("ROR",                    0,0,1,0, 2'b11, 4'd13, 8'hAA,   8'd3);
    apply("ROR_INVALID_INPUT",      0,0,1,0, 2'b00, 4'd13, 8'hAA,   8'd1);
    apply("ROR_ERR_LARGE_OPB",      0,0,1,0, 2'b11, 4'd13, 8'hAA,   8'd16); 

    // -- Logical CMD > 13 ? default err --
    apply("CMD_GREATER_LOGICAL",    0,0,1,0, 2'b11, 4'd15, -8'sd50, 8'sd20);
    apply("CMD_GT13_LOGIC_14",      0,0,1,0, 2'b11, 4'd14, 8'hAA,   8'h55);
    apply("CMD_GT13_LOGIC_15",      0,0,1,0, 2'b11, 4'd15, 8'hAA,   8'h55);

    // ============================================================
    // MULTIPLICATION MULTI-CYCLE MANUAL TESTS
    // ============================================================

    // -- 14. MODE CHANGE IN MULTIPLICATION CYCLE --
    @(posedge clk);
    rst=0; mode=1; ce=1; cin=0; inp_valid=2'b11;
    cmd=4'd9; opa=8'd5; opb=8'd4;
    #1;
    res_ref_latch=res_ref; oflow_ref_latch=oflow_ref; err_ref_latch=err_ref;
    g_ref_latch=g_ref; l_ref_latch=l_ref; e_ref_latch=e_ref; cout_ref_latch=cout_ref;
    @(posedge clk);
    mode=0; cmd=4'd1; opa=8'hAA; opb=8'h55;
    @(posedge clk);
    mul_check("MODE_CHANGE_IN_MUL_CYCLE");

    // -- 15. CMD CHANGE IN MULTIPLICATION CYCLE --
    @(posedge clk);
    rst=0; mode=1; ce=1; cin=0; inp_valid=2'b11;
    cmd=4'd9; opa=8'd5; opb=8'd4;
    #1;
    res_ref_latch=res_ref; oflow_ref_latch=oflow_ref; err_ref_latch=err_ref;
    g_ref_latch=g_ref; l_ref_latch=l_ref; e_ref_latch=e_ref; cout_ref_latch=cout_ref;
    @(posedge clk);
    cmd=4'd0; opa=8'd10; opb=8'd20;
    @(posedge clk);
    mul_check("CMD_CHANGE_IN_MUL_CYCLE");

    // -- 16. MULTIPLICATION 2ND CYCLE CMD CHANGE --
    @(posedge clk);
    rst=0; mode=1; ce=1; cin=0; inp_valid=2'b11;
    cmd=4'd9; opa=8'd6; opb=8'd3;
    #1;
    res_ref_latch=res_ref; oflow_ref_latch=oflow_ref; err_ref_latch=err_ref;
    g_ref_latch=g_ref; l_ref_latch=l_ref; e_ref_latch=e_ref; cout_ref_latch=cout_ref;
    @(posedge clk);
    cmd=4'd1;
    @(posedge clk);
    mul_check("MUL_2ND_CYCLE_CMD_CHANGE");

    // -- 17. MULTIPLICATION 2ND CYCLE MODE CHANGE --
    @(posedge clk);
    rst=0; mode=1; ce=1; cin=0; inp_valid=2'b11;
    cmd=4'd9; opa=8'd6; opb=8'd3;
    #1;
    res_ref_latch=res_ref; oflow_ref_latch=oflow_ref; err_ref_latch=err_ref;
    g_ref_latch=g_ref; l_ref_latch=l_ref; e_ref_latch=e_ref; cout_ref_latch=cout_ref;
    @(posedge clk);
    mode=0;
    @(posedge clk);
    mul_check("MUL_2ND_CYCLE_MODE_CHANGE");

    // -- 18. SAMPLING INPUT AT 3RD CYCLE OF MULTIPLICATION --
    @(posedge clk);
    rst=0; mode=1; ce=1; cin=0; inp_valid=2'b11;
    cmd=4'd9; opa=8'd5; opb=8'd4;
    #1;
    res_ref_latch=res_ref; oflow_ref_latch=oflow_ref; err_ref_latch=err_ref;
    g_ref_latch=g_ref; l_ref_latch=l_ref; e_ref_latch=e_ref; cout_ref_latch=cout_ref;
    @(posedge clk);
    @(posedge clk);
    opa=8'd99; opb=8'd99;
    mul_check("SAMPLE_INP_AT_3RD_CYCLE_MUL");

    // -- 19. GIVING INVALID INPUT AT 3RD CYCLE OF MULTIPLICATION --
    @(posedge clk);
    rst=0; mode=1; ce=1; cin=0; inp_valid=2'b11;
    cmd=4'd9; opa=8'd5; opb=8'd4;
    #1;
    res_ref_latch=res_ref; oflow_ref_latch=oflow_ref; err_ref_latch=err_ref;
    g_ref_latch=g_ref; l_ref_latch=l_ref; e_ref_latch=e_ref; cout_ref_latch=cout_ref;
    @(posedge clk);
    @(posedge clk);
    inp_valid=2'b00;
    mul_check("INV_INP_AT_3RD_CYCLE_MUL");

    // ============================================================
    // SUMMARY
    // ============================================================
    $display("\n===================================");
    $display("PASS = %0d", pass_count);
    $display("FAIL = %0d", fail_count);
    $display("===================================\n");

    $finish;
end

initial begin
    #50000;
    $display("TIMEOUT");
    $finish;
end

endmodule
