#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
iverilog -g2012 -s rumble_route_tb -o "$work_dir/route" rtl/psx_llapi_rumble_route.sv tests/llapi/rumble_route_tb.sv
vvp "$work_dir/route"
iverilog -g2012 -s rumble_tx_tb -o "$work_dir/tx" rtl/psx_llapi_rumble_tx.sv tests/llapi/rumble_tx_tb.sv
vvp "$work_dir/tx"
iverilog -g2012 -s command_transport_tb -o "$work_dir/wire" rtl/llapi.sv tests/llapi/command_transport_tb.sv
vvp "$work_dir/wire"
iverilog -g2012 -s input_wire_tb -o "$work_dir/input" rtl/llapi.sv rtl/psx_llapi_rumble_tx.sv tests/llapi/input_wire_tb.sv
vvp "$work_dir/input"
