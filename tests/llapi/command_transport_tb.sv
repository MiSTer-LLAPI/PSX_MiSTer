`timescale 1ns/1ps
module command_transport_tb;
reg clk=0,enable=0,valid=0;reg [7:0] data=0;
wire ready,latch_out,data_out;
always #10 clk=~clk;
LLAPI #(.EXTERNAL_COMMANDS(1)) dut(.CLK_50M(clk),.ENABLE(enable),.LLAPI_SYNC(1'b0),
 .IO_LATCH_IN(1'b1),.IO_DATA_IN(1'b1),.IO_LATCH_OUT(latch_out),.IO_DATA_OUT(data_out),
 .LLAPI_EN(),.LLAPI_TYPE(),.LLAPI_MODES(),.LLAPI_BUTTONS(),.LLAPI_ANALOG(),
 .CMD_VALID(valid),.CMD_BYTE(data),.CMD_READY(ready));
reg [7:0] bytes[0:3];integer seen=0,bitno;reg [7:0] decoded;
// Decode physical output levels using the existing 50 MHz protocol periods.
always begin
 @(negedge latch_out);
 repeat(251) @(negedge clk);
 for(bitno=0;bitno<8;bitno=bitno+1) begin
  decoded[bitno]=~data_out;
  if(bitno<7)repeat(224)@(negedge clk);
 end
 bytes[seen]=decoded;seen=seen+1;
end
task send(input [7:0] value);
 begin
  @(negedge clk);data=value;valid=1;
  do @(negedge clk); while(!ready);
  valid=0;
 end
endtask
initial begin
 repeat(5)@(negedge clk);enable=1;
 // Fixture establishes an idle connected link. This test covers transmission,
 // not discovery or reception of an adapter status packet.
 force dut.enable=1;
 dut.cycle=600;dut.count=0;dut.sync_counter=0;dut.poll_counter=0;
 dut.poll_offset=0;dut.poll_offset_latch=0;
 send(8'h1c);send(8'h01);send(8'h40);send(8'h11);
 repeat(2500)@(negedge clk);
 if(seen!=4)$fatal(1,"expected four complete command bytes, got %d",seen);
 if(bytes[0]!==8'h1c || bytes[1]!==8'h01 || bytes[2]!==8'h40 || bytes[3]!==8'h11)
  $fatal(1,"wire bytes %h %h %h %h",bytes[0],bytes[1],bytes[2],bytes[3]);
 send(8'h12);enable=0;repeat(5)@(negedge clk);
 if(latch_out!==1)$fatal(1,"disable must release latch");
 $display("PASS output-byte serialization/order, busy backpressure and disable releases pins; fixture link only");$finish;
end
initial begin #1000000;$fatal(1,"timeout");end
endmodule
