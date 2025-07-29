
module test_cpu;

  reg clk,rst;
  wire [6:0]out1,out2;
  cpu c1(clk,rst,out1,out2);
  always # 5 clk=~clk;
  initial
  begin
  clk=0;
  rst=0;
  #20 rst=1;
  #20 rst=0;
  #150 $pause;
  end
   
endmodule

