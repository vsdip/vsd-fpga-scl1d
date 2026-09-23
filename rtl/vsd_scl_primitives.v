`default_nettype none

module vsd_scl_inv (
    input  wire a,
    output wire y
);
    INVR01 u_vsd_cell (.IN1(a), .OUT1(y));
endmodule

module vsd_scl_buf (
    input  wire a,
    output wire y
);
    DELBUF u_vsd_cell (.IN1(a), .OUT1(y));
endmodule

module vsd_scl_mux2 (
    input  wire d0,
    input  wire d1,
    input  wire sel,
    output wire y
);
    MX2101 u_vsd_cell (
        .D0(d0),
        .D1(d1),
        .A0(sel),
        .OUT1(y)
    );
endmodule

module vsd_scl_or2 (
    input  wire a,
    input  wire b,
    output wire y
);
    OR2101 u_vsd_cell (
        .IN1(a),
        .IN2(b),
        .OUT1(y)
    );
endmodule

module vsd_scl_cfg_ff (
    input  wire prog_clk,
    input  wire cfg_d,
    output wire cfg_q,
    output wire cfg_qb
);
    DFFL11 u_vsd_cell (
        .D(cfg_d),
        .C(prog_clk),
        .Q(cfg_q),
        .QB(cfg_qb)
    );
endmodule

module vsd_scl_user_scan_ff (
    input  wire user_clk,
    input  wire user_reset_n,
    input  wire scan_enable,
    input  wire functional_d,
    input  wire scan_d,
    output wire q,
    output wire qb
);

    wire selected_d;

    MX2101 u_vsd_scan_mux (
        .D0(functional_d),
        .D1(scan_d),
        .A0(scan_enable),
        .OUT1(selected_d)
    );

    DFCL11 u_vsd_user_ff (
        .D(selected_d),
        .CLRB(user_reset_n),
        .C(user_clk),
        .Q(q),
        .QB(qb)
    );

endmodule

`default_nettype wire
`default_nettype none

// Secondary inverter required by the original OpenFPGA architecture.
module vsd_scl_inv2 (
    input  wire a,
    output wire y
);
    INVR02 u_vsd_cell (
        .IN1(a),
        .OUT1(y)
    );
endmodule

// Higher-drive logical buffer model.
// DELBUF is retained until another SCL buffer is physically qualified.
module vsd_scl_buf4 (
    input  wire a,
    output wire y
);
    DELBUF u_vsd_cell (
        .IN1(a),
        .OUT1(y)
    );
endmodule

// Functional OpenFPGA I/O adapter.
//
// This model is used only for fabric generation and functional simulation.
// The final physical-design core will use separate gpio_in, gpio_out and
// gpio_oeb signals and will not contain an internal tri-state.
module vsd_scl_gpio (
    inout  wire Y,
    output wire A,
    input  wire mem_out,
    output wire IE,
    output wire OE,
    input  wire in,
    output wire out
);

    assign A   = in;
    assign out = Y;

    // mem_out=1 means FPGA I/O is configured as input.
    assign IE = mem_out;
    assign OE = ~mem_out;

    // Temporary simulation-only bidirectional behavior.
    assign Y = mem_out ? 1'bz : in;

endmodule

`default_nettype wire
