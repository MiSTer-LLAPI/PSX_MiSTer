// SPDX-License-Identifier: MIT
// Candidate return-path routing for the existing PSX LLAPI player allocation.
// This does NOT implement the adapter's motor command protocol.
module psx_llapi_rumble_route (
    input  wire        port_a_active, port_b_active,
    input  wire        inhibit,
    input  wire [15:0] player1, player2,
    output wire [15:0] port_a, port_b
);
    // A alone=P1; B alone=P1; A+B=P1/P2. Never send a P2 effect
    // to a lone B controller: the existing PSX input allocation makes it P1.
    assign port_a = !inhibit && port_a_active ? player1 : 16'd0;
    assign port_b = !inhibit && port_b_active ?
                    (port_a_active ? player2 : player1) : 16'd0;
endmodule
