`timescale 1ns/1ps
`default_nettype none

module vsd_tb_scl_primitives;

    reg  a;
    reg  b;
    reg  d0;
    reg  d1;
    reg  sel;

    wire inv_y;
    wire buf_y;
    wire mux_y;
    wire or_y;

    reg  prog_clk;
    reg  cfg_d;
    wire cfg_q;
    wire cfg_qb;

    reg  user_clk;
    reg  user_reset_n;
    reg  scan_enable;
    reg  functional_d;
    reg  scan_d;
    wire user_q;
    wire user_qb;

    integer errors;

    vsd_scl_inv u_vsd_inv (
        .a(a),
        .y(inv_y)
    );

    vsd_scl_buf u_vsd_buf (
        .a(a),
        .y(buf_y)
    );

    vsd_scl_mux2 u_vsd_mux (
        .d0(d0),
        .d1(d1),
        .sel(sel),
        .y(mux_y)
    );

    vsd_scl_or2 u_vsd_or (
        .a(a),
        .b(b),
        .y(or_y)
    );

    vsd_scl_cfg_ff u_vsd_cfg_ff (
        .prog_clk(prog_clk),
        .cfg_d(cfg_d),
        .cfg_q(cfg_q),
        .cfg_qb(cfg_qb)
    );

    vsd_scl_user_scan_ff u_vsd_user_ff (
        .user_clk(user_clk),
        .user_reset_n(user_reset_n),
        .scan_enable(scan_enable),
        .functional_d(functional_d),
        .scan_d(scan_d),
        .q(user_q),
        .qb(user_qb)
    );

    task automatic check_value;
        input condition;
        input [8*80-1:0] message;
        begin
            if (!condition) begin
                errors = errors + 1;
                $display("FAIL: %0s", message);
            end
        end
    endtask

    task automatic pulse_prog_clk;
        begin
            #1 prog_clk = 1'b1;
            #1 prog_clk = 1'b0;
            #1;
        end
    endtask

    task automatic pulse_user_clk;
        begin
            #1 user_clk = 1'b1;
            #1 user_clk = 1'b0;
            #1;
        end
    endtask

    initial begin
        errors = 0;

        a = 0;
        b = 0;
        d0 = 0;
        d1 = 0;
        sel = 0;

        prog_clk = 0;
        cfg_d = 0;

        user_clk = 0;
        user_reset_n = 0;
        scan_enable = 0;
        functional_d = 0;
        scan_d = 0;

        #2;

        // Inverter and buffer
        a = 0;
        #1;
        check_value(inv_y === 1'b1, "INVR01: 0 must produce 1");
        check_value(buf_y === 1'b0, "DELBUF: 0 must produce 0");

        a = 1;
        #1;
        check_value(inv_y === 1'b0, "INVR01: 1 must produce 0");
        check_value(buf_y === 1'b1, "DELBUF: 1 must produce 1");

        // OR truth table
        a = 0; b = 0; #1;
        check_value(or_y === 1'b0, "OR2101: 0 OR 0");

        a = 0; b = 1; #1;
        check_value(or_y === 1'b1, "OR2101: 0 OR 1");

        a = 1; b = 0; #1;
        check_value(or_y === 1'b1, "OR2101: 1 OR 0");

        a = 1; b = 1; #1;
        check_value(or_y === 1'b1, "OR2101: 1 OR 1");

        // MX2101: sel=0 selects d0
        d0 = 0; d1 = 1; sel = 0; #1;
        check_value(mux_y === 1'b0, "MX2101: sel=0 must select d0");

        d0 = 1; d1 = 0; sel = 0; #1;
        check_value(mux_y === 1'b1, "MX2101: sel=0 second vector");

        // MX2101: sel=1 selects d1
        d0 = 0; d1 = 1; sel = 1; #1;
        check_value(mux_y === 1'b1, "MX2101: sel=1 must select d1");

        d0 = 1; d1 = 0; sel = 1; #1;
        check_value(mux_y === 1'b0, "MX2101: sel=1 second vector");

        // Configuration FF: rising-edge capture
        cfg_d = 0;
        pulse_prog_clk;
        check_value(cfg_q === 1'b0, "DFFL11: capture cfg_d=0");
        check_value(cfg_qb === 1'b1, "DFFL11: QB complement after 0");

        cfg_d = 1;
        pulse_prog_clk;
        check_value(cfg_q === 1'b1, "DFFL11: capture cfg_d=1");
        check_value(cfg_qb === 1'b0, "DFFL11: QB complement after 1");

        // User FF asynchronous active-low clear
        user_reset_n = 0;
        #1;
        check_value(user_q === 1'b0, "DFCL11: active-low reset");
        check_value(user_qb === 1'b1, "DFCL11: QB during reset");

        // Functional-data mode
        user_reset_n = 1;
        scan_enable = 0;
        functional_d = 1;
        scan_d = 0;
        pulse_user_clk;
        check_value(user_q === 1'b1,
                    "User FF: functional data selected");

        // Scan-data mode
        scan_enable = 1;
        scan_d = 0;
        functional_d = 1;
        pulse_user_clk;
        check_value(user_q === 1'b0,
                    "User FF: scan data selected");

        scan_d = 1;
        functional_d = 0;
        pulse_user_clk;
        check_value(user_q === 1'b1,
                    "User FF: scan data=1 captured");

        // Reset must override stored value
        user_reset_n = 0;
        #1;
        check_value(user_q === 1'b0,
                    "User FF: reset must override Q");
        check_value(user_qb === 1'b1,
                    "User FF: reset must override QB");

        if (errors == 0) begin
            $display("VSD SCL PRIMITIVES: ALL TESTS PASSED");
            $finish;
        end
        else begin
            $fatal(1, "VSD SCL PRIMITIVES: %0d TESTS FAILED", errors);
        end
    end

endmodule

`default_nettype wire
