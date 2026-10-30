# PSX LLAPI rumble experiment

Based on official main cd17b5a0ad261005c321d9d5ba41b8dbe313a7d3, preserving LLAPI fork history and original authorship/licenses. The separate 2xCPU variant additionally incorporates the author's cbefef4b18d598d19e445a6123eb2beddb839370 branch; latest official CD implementation is retained. Normal and 2xCPU each have Single and Dual SDRAM build targets. Successful compilation of one does not establish success of another.

Target: BlisSTer / Bliss-Box and original PS1 DualShock. **Physical testing of this new path is pending.** Digital/analog input support remains. Enable `LLAPI rumble test` in the core menu; default is Off. USB rumble remains on its existing path.

The return path combines small/large motor activity and sends documented finite 0x1A jolt commands at most once per 50 ms. This is a first compatibility experiment, **not independent two-motor intensity emulation**. No indefinite-start command or ambiguous parameter payload is used. A lone controller in physical socket B receives P1 effects, matching existing input allocation. With both sockets, A receives P1 and B P2. Only reported DualShock/DualShock2 types are targeted.

Stop commands 0x12/0x18 are queued when activity ends or is inhibited while connected. Opening OSD disables the pre-existing LLAPI link: a stop cannot be transmitted over a disabled/disconnected link. The finite effect must then expire in adapter firmware; this must be checked on hardware. Do not claim immediate physical stop in that case. Reset/pause inhibit new pulses after synchronisation. On reconnection, stop commands precede new effects.

Protocol sources: https://bliss-box.com/pages/integration and vendor-linked https://github.com/ulao/Bliss-Box-LLAPI . The public reference is not proof of current shipped firmware behaviour. No firmware, BIOS or game data is included.

Local simulation covers player routing, command backpressure, finite-jolt refresh/stop/inhibit/reconnect and an adapter fixture performing discovery, analog/digital reports, motor commands and continued polling over the physical pins. The fixture explicitly supplies power-up zero values for pre-existing LLAPI timing counters. This is not full PSX simulation, FPGA fitting/timing or physical verification.
