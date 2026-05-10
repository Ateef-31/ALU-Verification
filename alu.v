module alu #(parameter N = 8, parameter M = 4)
(
    input              CLK,
    input              RST,
    input              CE,
    input              CIN,
    input              MODE,
    input      [1:0]   INP_VALID,
    input      [N-1:0] OPA,
    input      [N-1:0] OPB,
    input      [M-1:0] CMD,
    output reg [2*N-1:0] RES,
    output reg         OFLOW,
    output reg         COUT,
    output reg         G,
    output reg         L,
    output reg         E,
    output reg         ERR
);

    reg              p_valid;
    reg              p_mode;
    reg              p_cin;
    reg [1:0]        p_inp_valid;
    reg [N-1:0]      p_opa;
    reg [N-1:0]      p_opb;
    reg [M-1:0]      p_cmd;
    reg              mul_wait;
    reg [N-1:0]      mul_opa;
    reg [N-1:0]      mul_opb;
    reg [M-1:0]      mul_cmd;
    reg [1:0]        mul_inp_valid;
    reg [N:0]        tmp_ext;
    reg [N-1:0]      tmp_n;
    reg [2*N-1:0]      tmp_wide;
    // ------------------------------------------------------------
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            RES          <= {(2*N+1){1'b0}};
            OFLOW        <= 1'b0;
            COUT         <= 1'b0;
            G            <= 1'b0;
            L            <= 1'b0;
            E            <= 1'b0;
            ERR          <= 1'b0;
            // stage 1 sample registers
            p_valid      <= 1'b0;
            p_mode       <= 1'b0;
            p_cin        <= 1'b0;
            p_inp_valid  <= 2'b00;
            p_opa        <= {N{1'b0}};
            p_opb        <= {N{1'b0}};
            p_cmd        <= {M{1'b0}};
            // multiply pipeline registers
            mul_wait     <= 1'b0;
            mul_opa      <= {N{1'b0}};
            mul_opb      <= {N{1'b0}};
            mul_cmd      <= {M{1'b0}};
            mul_inp_valid<= 2'b00;
            // temp
            tmp_ext      <= {(N+1){1'b0}};
            tmp_n        <= {N{1'b0}};
            tmp_wide     <= {(2*N+1){1'b0}};
        end
        else if (CE) begin
            // MULTIPLICATION RESULT STAGE
            // cycle 3 : compute and output result
            if (mul_wait) begin
                // check if MODE and CMD are still same as multiply
                if (MODE && (CMD == mul_cmd)) begin
                    OFLOW <= 1'b0;
                    COUT  <= 1'b0;
                    G     <= 1'b0;
                    L     <= 1'b0;
                    E     <= 1'b0;
                    ERR   <= 1'b0;
                    RES   <= {(2*N+1){1'b0}};
                    // check validity
                    if (mul_inp_valid != 2'b11) begin
                        ERR <= 1'b1;
                        RES <= {(2*N+1){1'b0}};
                    end
                    else begin
                        case (mul_cmd)
                            4'd9: begin
                                // (OPA+1) * (OPB+1)
                                tmp_wide = ({1'b0, mul_opa} + {{N{1'b0}}, 1'b1}) *
                                           ({1'b0, mul_opb} + {{N{1'b0}}, 1'b1});
                                RES  <= tmp_wide;
                                ERR  <= 1'b0;
                            end
                            4'd10: begin
                                // (OPA << 1) * OPB
                                tmp_wide = ({1'b0, (mul_opa << 1)}) *
                                           ({1'b0, mul_opb});
                                RES  <= tmp_wide;
                                ERR  <= 1'b0;
                            end
                            default: begin
                                ERR <= 1'b1;
                                RES <= {(2*N+1){1'b0}};
                            end
                        endcase
                    end
                    // done with multiplication
                    mul_wait <= 1'b0;
                    // sample current inputs for next operation
                    p_valid     <= 1'b1;
                    p_mode      <= MODE;
                    p_cin       <= CIN;
                    p_inp_valid <= INP_VALID;
                    p_opa       <= OPA;
                    p_opb       <= OPB;
                    p_cmd       <= CMD;
                end
                else begin
                    // MODE or CMD changed during multiplication
                    // cancel multiplication
                    mul_wait <= 1'b0;
                    // sample new command for next cycle processing
                    p_valid     <= 1'b1;
                    p_mode      <= MODE;
                    p_cin       <= CIN;
                    p_inp_valid <= INP_VALID;
                    p_opa       <= OPA;
                    p_opb       <= OPB;
                    p_cmd       <= CMD;
                end
            end
            // NORMAL OPERATION
            else begin
                if (p_valid) begin
                    // ------------------------------------------------
                    // pending command is multiplication
                    // cycle 2 : validate and move to multiply pipeline
                    // ------------------------------------------------
                    if (p_mode && ((p_cmd == 4'd9) || (p_cmd == 4'd10))) begin
                        // check if current MODE and CMD still same
                        if (MODE && (CMD == p_cmd)) begin
                            // move to multiply pipeline
                            mul_wait      <= 1'b1;
                            mul_opa       <= p_opa;
                            mul_opb       <= p_opb;
                            mul_cmd       <= p_cmd;
                            mul_inp_valid <= p_inp_valid;
                            p_valid <= 1'b0;
                        end
                        else begin
                            // MODE or CMD changed, cancel pending multiply
                            // sample new command instead
                            p_valid     <= 1'b1;
                            p_mode      <= MODE;
                            p_cin       <= CIN;
                            p_inp_valid <= INP_VALID;
                            p_opa       <= OPA;
                            p_opb       <= OPB;
                            p_cmd       <= CMD;
                        end
                    end
                    // ------------------------------------------------
                    // pending command is normal operation
                    // cycle 2 : compute and output result
                    // ------------------------------------------------
                    else begin
                        RES   <= {(2*N+1){1'b0}};
                        OFLOW <= 1'b0;
                        COUT  <= 1'b0;
                        G     <= 1'b0;
                        L     <= 1'b0;
                        E     <= 1'b0;
                        ERR   <= 1'b0;
                        if (p_mode) begin
                            case (p_cmd)
                                // CMD 0 : Unsigned Addition
                                4'd0: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_ext      = {1'b0, p_opa} + {1'b0, p_opb};
                                        RES          <= {{(N+1){1'b0}}, tmp_ext[N-1:0]};
                                        COUT         <= tmp_ext[N];
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 1 : Unsigned Subtraction
                                4'd1: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n  = p_opa - p_opb;
                                        RES   <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 2 : Unsigned Addition with Carry In
                                4'd2: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_ext = {1'b0, p_opa} + {1'b0, p_opb} +
                                                  {{N{1'b0}}, p_cin};
                                        RES  <= {{(N+1){1'b0}}, tmp_ext[N-1:0]};
                                        COUT <= tmp_ext[N];
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 3 : Unsigned Subtraction with Borrow In
                                4'd3: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = p_opa - p_opb - {{(N-1){1'b0}}, p_cin};
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 4 : Increment A
                                4'd4: begin
                                    if (p_inp_valid[0] == 1) begin
                                        tmp_ext = {1'b0, p_opa} + {{N{1'b0}}, 1'b1};
                                        RES  <= {{(N+1){1'b0}}, tmp_ext[N-1:0]};
                                        COUT <= tmp_ext[N];
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 5 : Decrement A
                                4'd5: begin
                                    if (p_inp_valid[0] == 1) begin
                                        tmp_n = p_opa - {{(N-1){1'b0}}, 1'b1};
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 6 : Increment B
                                4'd6: begin
                                    if (p_inp_valid[1] == 1) begin
                                        tmp_ext = {1'b0, p_opb} + {{N{1'b0}}, 1'b1};
                                        RES  <= {{(N+1){1'b0}}, tmp_ext[N-1:0]};
                                        COUT <= tmp_ext[N];
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 7 : Decrement B
                                4'd7: begin
                                    if (p_inp_valid[1] == 1) begin
                                        tmp_n = p_opb - {{(N-1){1'b0}}, 1'b1};
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 8 : Compare A and B
                                4'd8: begin
                                    if (p_inp_valid == 2'b11) begin
                                        G <= (p_opa > p_opb);
                                        L <= (p_opa < p_opb);
                                        E <= (p_opa == p_opb);
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 9 : Multiplication handled by pipeline
                                4'd9: begin
                                    ERR <= 1'b1;
                                end
                                // CMD 10 : Multiplication handled by pipeline
                                4'd10: begin
                                    ERR <= 1'b1;
                                end
                                // CMD 11 : Signed Addition with Overflow
                                4'd11: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = $signed(p_opa) + $signed(p_opb);
                                        RES   <= {{(N+1){1'b0}}, tmp_n};
                                        OFLOW <= (p_opa[N-1]==p_opb[N-1]) && (tmp_n[N-1]!= p_opa[N-1]);
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 12 : Signed Subtraction with Overflow
                                4'd12: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = $signed(p_opa) - $signed(p_opb);
                                        RES   <= {{(N+1){1'b0}}, tmp_n};
                                        OFLOW <= (p_opa[N-1]!=p_opb[N-1]) && (tmp_n[N-1]!= p_opa[N-1]);
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD > 12 in arithmetic : error
                                default: begin
                                    ERR <= 1'b1;
                                end
                            endcase
                        end
                        else begin
                            case (p_cmd)
                                // CMD 0 : AND
                                4'd0: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = p_opa & p_opb;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 1 : NAND
                                4'd1: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = ~(p_opa & p_opb);
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 2 : OR
                                4'd2: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = p_opa | p_opb;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 3 : NOR
                                4'd3: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = ~(p_opa | p_opb);
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 4 : XOR
                                4'd4: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = p_opa ^ p_opb;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 5 : XNOR
                                4'd5: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = ~(p_opa ^ p_opb);
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 6 : NOT A
                                4'd6: begin
                                    if (p_inp_valid[0] == 1) begin
                                        tmp_n = ~p_opa;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 7 : NOT B
                                4'd7: begin
                                    if (p_inp_valid[1] == 1) begin
                                        tmp_n = ~p_opb;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 8 : Shift Right A by 1
                                4'd8: begin
                                    if (p_inp_valid[0] == 1) begin
                                        tmp_n = p_opa >> 1;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 9 : Shift Left A by 1
                                4'd9: begin
                                    if (p_inp_valid[0] == 1) begin
                                        tmp_n = p_opa << 1;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 10 : Shift Right B by 1
                                4'd10: begin
                                    if (p_inp_valid[1] == 1) begin
                                        tmp_n = p_opb >> 1;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 11 : Shift Left B by 1
                                4'd11: begin
                                    if (p_inp_valid[1] == 1) begin
                                        tmp_n = p_opb << 1;
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD 12 : ROL A by OPB[2:0]
                                // ERR if OPB[N-1:4] has any 1
                                // result still computed from OPB[2:0]
                                4'd12: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = (p_opa << p_opb[$clog2(N)-1:0]) |
                                                (p_opa >> (N - p_opb[$clog2(N)-1:0]));
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                        if (|p_opb[N-1:4]) begin
                                            ERR <= 1'b1;
                                        end
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                4'd13: begin
                                    if (p_inp_valid == 2'b11) begin
                                        tmp_n = (p_opa >> p_opb[$clog2(N)-1:0]) |
                                                (p_opa << (N - p_opb[$clog2(N)-1:0]));
                                        RES  <= {{(N+1){1'b0}}, tmp_n};
                                        if (|p_opb[N-1:4]) begin
                                            ERR <= 1'b1;
                                        end
                                    end
                                    else begin
                                        ERR <= 1'b1;
                                    end
                                end
                                // CMD > 13 in logical : error
                                default: begin
                                    ERR <= 1'b1;
                                end
                            endcase
                        end
                        p_valid     <= 1'b1;
                        p_mode      <= MODE;
                        p_cin       <= CIN;
                        p_inp_valid <= INP_VALID;
                        p_opa       <= OPA;
                        p_opb       <= OPB;
                        p_cmd       <= CMD;
                    end
                end
                else begin
                    p_valid     <= 1'b1;
                    p_mode      <= MODE;
                    p_cin       <= CIN;
                    p_inp_valid <= INP_VALID;
                    p_opa       <= OPA;
                    p_opb       <= OPB;
                    p_cmd       <= CMD;
                end
            end
        end
    end
endmodule

