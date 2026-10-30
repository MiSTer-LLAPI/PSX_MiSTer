`timescale 1ns/1ps
module rumble_route_tb;
    reg a=0,b=0,inhibit=0;
    reg [15:0] p1=16'h0180,p2=16'h0040;
    wire [15:0] out_a,out_b;
    psx_llapi_rumble_route dut(a,b,inhibit,p1,p2,out_a,out_b);
    task expect_ports(input [15:0] ea,eb);
        begin #1;if(out_a!==ea || out_b!==eb)
            $fatal(1,"A/B active %b%b inhibit %b expected %h/%h got %h/%h",a,b,inhibit,ea,eb,out_a,out_b);
        end
    endtask
    initial begin
        expect_ports(0,0);
        a=1;expect_ports(p1,0);
        a=0;b=1;expect_ports(0,p1);
        a=1;expect_ports(p1,p2);
        p1=16'hff01;expect_ports(p1,p2);
        p2=0;expect_ports(p1,0);
        inhibit=1;expect_ports(0,0);
        p2=16'h0080;expect_ports(0,0);
        inhibit=0;expect_ports(p1,p2);
        a=0;expect_ports(0,p1);
        b=0;expect_ports(0,0);
        a=1;inhibit=1;expect_ports(0,0);
        $display("PASS logical-to-physical routing, independent players, inhibition, disconnect/reallocation");
        $finish;
    end
endmodule
