// Quartus II Verilog Template
// Single port RAM with single read/write address 

module single_port_ram_128x8(
	data,
	addr,
	en,
	clk,
	q
);
	input [6:0] addr;
	input [7:0] data;
	input en, clk;
	output [7:0] q;
	
	// Declare the RAM variable
	//reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	reg [7:0] ram[127:0];
	
	// Variable to hold the registered read address
	//reg [6:0] addr_reg;
	
	always @ (posedge clk)
	begin
		// Write
		if (en)
			ram[addr] <= data;
		
			//addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  

	assign q = ram[addr];
endmodule

