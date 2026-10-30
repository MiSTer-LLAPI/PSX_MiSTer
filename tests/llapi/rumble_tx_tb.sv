`timescale 1ns/1ps
module rumble_tx_tb;
 reg clk=0,connected=0,request=0,inhibit=1,accepted=0;
 wire valid; wire [7:0] command;
 always #10 clk=~clk;
 psx_llapi_rumble_tx #(.REFRESH_CYCLES(40)) dut(clk,connected,request,inhibit,valid,command,accepted);
 task take(input [7:0] expected);
  integer n;
  begin
   n=0; while(!valid && n<100) begin @(negedge clk); n=n+1; end
   if(!valid || command!==expected) $fatal(1,"wanted %h got valid=%b command=%h",expected,valid,command);
   // Backpressure must preserve the selected command.
   repeat(5)begin @(negedge clk); if(!valid || command!==expected)$fatal(1,"unstable command");end
   accepted=1; @(negedge clk); accepted=0;
  end
 endtask
 initial begin
  repeat(5)@(negedge clk); connected=1;
  take(8'h12); take(8'h18);
  repeat(5)@(negedge clk); if(valid)$fatal(1,"rumble while inhibited");
  inhibit=0; request=1; take(8'h1a);
  repeat(10)@(negedge clk); if(valid)$fatal(1,"refresh not rate limited");
  take(8'h1a);
  request=0; take(8'h12); take(8'h18);
  request=1; take(8'h1a); inhibit=1; take(8'h12); take(8'h18);
  repeat(50)@(negedge clk); if(valid)$fatal(1,"repeat while paused");
  inhibit=0; take(8'h1a); connected=0;
  repeat(5)@(negedge clk); if(valid)$fatal(1,"traffic after disconnect");
  request=0; connected=1; take(8'h12); take(8'h18);
  repeat(5)@(negedge clk); if(valid)$fatal(1,"stale rumble after reconnect");
  $display("PASS finite jolt, refresh bound, stop, inhibit, backpressure, reconnect");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
