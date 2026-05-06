module alu #(parameter N = 8 , parameter M = 4)
(
    input CLK , RST , CE , CIN , MODE,
    input [1:0] INP_VALID,
    input [N-1:0] OPA, OPB,
    input [M-1:0] CMD,
    output reg [2*N:0] RES,
    output reg OFLOW,
    output reg COUT,
    output reg G,
    output reg L,
    output reg E,
    output reg ERR
);

    reg [2*N:0] res;
    reg oflow, cout, g, l, e, err;

    reg [N-1:0] opa_reg, opb_reg;
    reg [1:0] mul_state;
    reg res_x_phase;

    reg [N:0] temp;
    reg [2*N:0] mul_result;
    reg [N-1:0] shifted_opa;

    reg mul_invalid;

    reg mul_active;

    wire en = CE & ~RST;

    // ================= OUTPUT LOGIC =================
    always @(*) begin
        if (!en) begin
            RES = 0; OFLOW = 0; COUT = 0;
            G = 0; L = 0; E = 0; ERR = 0;
        end 
        else if (mul_active) begin
            RES = (res_x_phase) ? 0 : res;
            OFLOW = oflow;
            COUT = cout;
            G = g;
            L = l;
            E = e;
            ERR = (res_x_phase) ? 0 : err;  // show only in 3rd cycle
        end 
        else begin
            // Normal ops
            RES = (res_x_phase) ? 0 : res;
            OFLOW = oflow;
            COUT = cout;
            G = g;
            L = l;
            E = e;
            ERR = err;
        end
    end

    // ================= MAIN LOGIC =================
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            res <= 0; oflow <= 0; cout <= 0;
            g <= 0; l <= 0; e <= 0; err <= 0;

            mul_state <= 0;
            res_x_phase <= 0;
            opa_reg <= 0; opb_reg <= 0;

            temp <= 0; mul_result <= 0; shifted_opa <= 0;
            mul_invalid <= 0;
            mul_active <= 0;
        end

        else if (CE) begin
            // default flags
            oflow <= 0; cout <= 0; g <= 0;
            l <= 0; e <= 0; err <= 0;

            // ================= MULTIPLICATION CMD=9 =================
            if (MODE && CMD == 4'd9) begin
                case(mul_state)

                2'd0: begin
                    res_x_phase <= 1;
                    mul_invalid <= (INP_VALID != 2'b11);
                    mul_active <= 1;
                    opa_reg <= OPA;
                    opb_reg <= OPB;
                    mul_state <= 2'd1;
                end

                2'd1: begin
                    res_x_phase <= 1;
                    mul_invalid <= mul_invalid | (INP_VALID != 2'b11);
                    mul_state <= 2'd2;
                end

                2'd2: begin
                    res_x_phase <= 0;
                    if (mul_invalid) begin
                        err <= 1;   
                        res <= 0;
                    end else begin
                        err <= 0;
                        res <= (opa_reg + 1) * (opb_reg + 1);
                    end
                    mul_state <= 0;
                    mul_active <= 0;
                end
                endcase
            end

            // ================= MULTIPLICATION CMD=10 =================
            else if (MODE && CMD == 4'd10) begin
                case(mul_state)

                2'd0: begin
                    res_x_phase <= 1;
                    mul_invalid <= (INP_VALID != 2'b11);
                    mul_active <= 1;
                    opa_reg <= OPA;
                    opb_reg <= OPB;
                    mul_state <= 2'd1;
                end

                2'd1: begin
                    res_x_phase <= 1;
                    mul_invalid <= mul_invalid | (INP_VALID != 2'b11);
                    mul_state <= 2'd2;
                end

                2'd2: begin
                    res_x_phase <= 0;
                    if (mul_invalid) begin
                        err <= 1;
                        res <= 0;
                    end else begin
                        err <= 0;
                        shifted_opa = opa_reg << 1;
                        res <= shifted_opa * opb_reg;
                    end
                    mul_state <= 0;
                    mul_active <= 0;
                end
                endcase
            end

            // ================= NORMAL OPS =================
            else if (mul_state == 0) begin
                mul_active <= 0;
                res_x_phase <= 0;
                err <= 0;

                if (MODE) begin
                    case(CMD)

                    4'd0: if(INP_VALID==2'b11)
                        {cout, res[N-1:0]} <= OPA + OPB;

                    4'd1: if(INP_VALID==2'b11)
                        res <= OPA - OPB;

                    4'd2: if(INP_VALID==2'b11)
                        {cout, res[N-1:0]} <= OPA + OPB + CIN;

                    4'd3: if(INP_VALID==2'b11)
                        res <= OPA - OPB - CIN;

                    4'd4: if(INP_VALID==2'b01)
                        {cout, res} <= OPA + 1;

                    4'd5: if(INP_VALID==2'b01)
                        res <= OPA - 1;

                    4'd6: if(INP_VALID==2'b10)
                        {cout, res} <= OPB + 1;

                    4'd7: if(INP_VALID==2'b10)
                        res <= OPB - 1;

                    4'd8: if(INP_VALID==2'b11) begin
                        g <= (OPA > OPB);
                        e <= (OPA == OPB);
                        l <= (OPA < OPB);
                    end

                    4'd11: if(INP_VALID==2'b11) begin
                        temp = $signed(OPA) + $signed(OPB);
                        res <= temp;
                        oflow <= (OPA[N-1]==OPB[N-1]) && (temp[N-1]!=OPA[N-1]);
                    end

                    4'd12: if(INP_VALID==2'b11) begin
                        temp = $signed(OPA) - $signed(OPB);
                        res <= temp;
                        oflow <= (OPA[N-1]!=OPB[N-1]) && (temp[N-1]!=OPA[N-1]);
                    end

                    endcase
                end

                else begin
                    case(CMD)
                    4'd0: if(INP_VALID==2'b11) res <= (OPA & OPB);
                    4'd1: if(INP_VALID==2'b11) res <= ~(OPA & OPB);
                    4'd2: if(INP_VALID==2'b11) res <= (OPA | OPB);
                    4'd3: if(INP_VALID==2'b11) res <= ~(OPA | OPB);
                    4'd4: if(INP_VALID==2'b11) res <= (OPA ^ OPB);
                    4'd5: if(INP_VALID==2'b11) res <= ~(OPA ^ OPB);
                    4'd6: if(INP_VALID == 2'b01) res <= ~OPA;
                    4'd7: if(INP_VALID == 2'b10) res <= ~OPB;
                    4'd8: if(INP_VALID == 2'b01) res <= (OPA >> 1);
                    4'd9: if(INP_VALID == 2'b01) res <= (OPA << 1);
                    4'd10: if(INP_VALID == 2'b10) res <= (OPB >> 1);
                    4'd11: if(INP_VALID == 2'b10) res <= (OPB << 1);
                    4'd12: if(INP_VALID == 2'b11) begin
                        if (|OPB[N-1:4]) begin
                            err <= 1;  // Error for invalid rotate amount
                        end
                        else begin
                            res <= (OPA << OPB[$clog2(N) - 1:0]) | (OPA >> (N - OPB[$clog2(N) - 1:0]));
                            end
                    end

                    4'd13: if(INP_VALID == 2'b11) begin
                        if (|OPB[N-1:4]) begin
                            err <= 1;  // Error for invalid rotate amount
                        end
                        else begin
                            res <= (OPA >> OPB[$clog2(N) - 1:0]) | (OPA << (N - OPB[$clog2(N) - 1:0]));
                            end
                    end

                    default: err <= 0;
                    endcase
                end
            end

            else begin
                mul_state   <= mul_state;
                res_x_phase <= res_x_phase;
                opa_reg <= opa_reg;
                opb_reg <= opb_reg;
                res <= res;
                cout <= cout;
                oflow <= oflow;
                g <= g;
                l <= l;
                e <= e;
                err <= err;
            end
        end
    end

endmodule
