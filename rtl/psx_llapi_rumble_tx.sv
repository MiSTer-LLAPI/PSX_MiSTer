// SPDX-License-Identifier: MIT
// Experimental Bliss-Box return path. Uses documented finite jolt (0x1a),
// never an indefinite start or unverified parameter payload. Both PSX motors
// are combined into activity; this does not emulate their intensities separately.
module psx_llapi_rumble_tx #(
    parameter integer REFRESH_CYCLES = 2500000, // 50 ms at 50 MHz
    parameter integer SHARED_TIMEBASE = 0
) (
    input wire clk,
    input wire refresh_tick,
    input wire connected,
    input wire request_async,
    input wire inhibit_async,
    output wire valid,
    output wire [7:0] command,
    input wire accepted
);
    (* async_reg = "true" *) reg request_meta=0, request_sync=0;
    (* async_reg = "true" *) reg inhibit_meta=1, inhibit_sync=1;
    always @(posedge clk) begin
        request_meta <= request_async;
        request_sync <= request_meta;
        inhibit_meta <= inhibit_async;
        inhibit_sync <= inhibit_meta;
    end
    localparam IDLE=2'd0, JOLT=2'd1, STOP_CONST=2'd2, STOP_SINE=2'd3;
    reg [1:0] state=IDLE;
    reg linked=0, playing=0;
    localparam CW = SHARED_TIMEBASE ? 2 : ((REFRESH_CYCLES < 2) ? 1 : $clog2(REFRESH_CYCLES));
    reg [CW-1:0] cooldown=0;
    wire wanted = request_sync && !inhibit_sync;
    // Inhibition withdraws an unsent jolt immediately after synchronisation.
    assign valid = connected && state!=IDLE && (state!=JOLT || wanted);
    assign command = state==JOLT ? 8'h1a : state==STOP_CONST ? 8'h12 : 8'h18;
    always @(posedge clk) begin
        if (!connected) begin
            state<=IDLE; linked<=0; playing<=0; cooldown<=0;
        end else begin
            linked<=1;
            if(cooldown!=0 && (!SHARED_TIMEBASE || refresh_tick)) cooldown<=cooldown-1'b1;
            if (!linked) begin
                // Clear any previous adapter effect before accepting new activity.
                state<=STOP_CONST; playing<=0; cooldown<=0;
            end else case(state)
                IDLE: begin
                    if (!wanted && playing) state<=STOP_CONST;
                    else if (wanted && cooldown==0) state<=JOLT;
                end
                JOLT: begin
                    if (!wanted) state<=STOP_CONST;
                    else if (accepted) begin
                        playing<=1; cooldown<=SHARED_TIMEBASE ? 2 : REFRESH_CYCLES-1; state<=IDLE;
                    end
                end
                STOP_CONST: if(accepted) state<=STOP_SINE;
                STOP_SINE: if(accepted) begin
                    playing<=0; cooldown<=0; state<=IDLE;
                end
                default: state<=STOP_CONST;
            endcase
        end
    end
    // Shared mode waits two ticks after acceptance: even if the first tick
    // is adjacent, continuous-effect refresh spacing is at least one full period.
    // Per-port state stays independent, with only a two-bit cooldown per socket.
    // If the link is disabled/disconnected, stop commands cannot be delivered.
    // The finite jolt must expire in adapter firmware; hardware validation needed.
endmodule
