module cpu(
  input clk,input rst, output wire[6:0]seven_seg_out2,output wire[6:0]seven_seg_out1
  );
	wire[7:0]ram_q;
	reg[10:0] mar_q,pc_q,pc_next;
	reg[3:0]ps,ns,op,sel_ram_mux,sel_pc;
	wire[3:0]sel_bit;
	reg load_pc,load_ir,load_mar_q,load_w
	,sel_alu,ram_en,sel_bus,load_port_b,load_port_c,push,pop,rst_ir;
	wire [13:0]r1_out;
	reg[13:0]ir_q;
	wire [10:0]pc_in,stack_q;
	reg [7:0]alu_mux,alu_out,databus,ram_mux,bsf_mux,bcf_mux,
	port_b_out,port_c_out,w_q;
	wire [10:0]w_change,k_change;
	Program_Rom r1(r1_out,mar_q);
	single_port_ram_128x8 ram(
	.data(databus),
	.addr(ir_q[6:0]),
	.en(ram_en),
	.clk(clk),
	.q(ram_q));
	//seven seg
	seven_segment seven1(port_b_out[3:0],seven_seg_out1);
	seven_segment seven2(port_b_out[7:4],seven_seg_out2);
	//stack
	Stack stack(stack_q,pc_q,push,pop,rst,clk);
	//port c
	always@(posedge clk)
	if(rst)port_c_out<=0;
	else if (load_port_c)port_c_out<=databus;
	//port b
	always@(posedge clk)
	if(rst)port_b_out<=0;
	else if (load_port_b)port_b_out<=databus;
	//bsf_mux
	always@(*)
		begin
			case(sel_bit)
				3'b000:bsf_mux=ram_q|8'h01;
				3'b001:bsf_mux=ram_q|8'h02;
				3'b010:bsf_mux=ram_q|8'h04;
				3'b011:bsf_mux=ram_q|8'h08;
				3'b100:bsf_mux=ram_q|8'h10;
				3'b101:bsf_mux=ram_q|8'h20;
				3'b110:bsf_mux=ram_q|8'h40;
				3'b111:bsf_mux=ram_q|8'h80;
			endcase
		end
			
	//bcf_mux
	always@(*)
		begin
			case(sel_bit)
				3'b000:bcf_mux=ram_q&8'hfe;
				3'b001:bcf_mux=ram_q&8'hfd;
				3'b010:bcf_mux=ram_q&8'hfb;
				3'b011:bcf_mux=ram_q&8'hf7;
				3'b100:bcf_mux=ram_q&8'hef;
				3'b101:bcf_mux=ram_q&8'hdf;
				3'b110:bcf_mux=ram_q&8'hbf;
				3'b111:bcf_mux=ram_q&8'h7f;
			endcase
		end
	//bsf bcf
	assign sel_bit =ir_q[9:7];
	//ram_mux
	always @(*)
		begin	
			case(sel_ram_mux)
				0: ram_mux= ram_q;
				1: ram_mux= bcf_mux;
				2: ram_mux=bsf_mux;
				default: ram_mux=8'bx;
			endcase
		end
	//databus mux
	always@(*)
	begin
		if(sel_bus)
			databus=w_q;
		else 
			databus=alu_out;
	end
	always@(*)//alu
	begin
		case(op)
		4'h0:alu_out= alu_mux[7:0]+w_q;
		4'h1:alu_out= alu_mux[7:0]-w_q;
		4'h2:alu_out= alu_mux[7:0]&w_q;
		4'h3:alu_out= alu_mux[7:0]|w_q;
		4'h4:alu_out= alu_mux[7:0]^w_q;
		4'h5:alu_out= alu_mux[7:0];//bypass
		4'h6:alu_out=  alu_mux[7:0]+1;
		4'h7:alu_out=  alu_mux[7:0]-1;
		4'h8:alu_out=  0;
		4'h9:alu_out= ~alu_mux[7:0];
		4'ha:alu_out= {alu_mux[7], alu_mux[7:1]};
		4'hb:alu_out= {alu_mux[6:0],1'b0};
		4'hc:alu_out= {1'b0,alu_mux[7:1]};
		4'hd:alu_out= {alu_mux[6:0],alu_mux[7]};
		4'he:alu_out= {alu_mux[0],alu_mux[7:1]};
		4'hf:alu_out= {alu_mux[3:0],alu_mux[7:4]};
		default alu_out= 8'bxxxxxxxx;
		endcase
	end
	//alu_mux
	always@(*)
	begin
		if(sel_alu)
			alu_mux=ram_mux;
		else 
			alu_mux=ir_q[7:0];
	end
	//pc_mux
	always@(*)
	begin
		if(sel_pc==3'b001)
			pc_next=ir_q[10:0];
		else if(sel_pc==3'b010)
			pc_next=stack_q;
		else if(sel_pc==3'b011)
			pc_next=pc_q+k_change;
		else if(sel_pc==3'b100)
			pc_next=pc_q+w_change;
		else
			pc_next=pc_in;
	end
	
	always@(posedge clk)//pc
	begin	
		if(load_pc)pc_q<=pc_next;
		if(rst)pc_q<=0;
	end
	
	assign pc_in=pc_q+1;
	
	always @(posedge clk)//dq
	begin
		if(rst)
		begin
			ps<=0;
		end
		else ps<=ns;
	end
	
	always @(posedge clk)//mar_q
	begin
		if(load_mar_q)mar_q<=pc_q;
	end
	
	
	
	always@(posedge clk)//ir
	begin//order matters
		if(rst_ir)ir_q<=0;
		else if(load_ir)ir_q<=r1_out;
		else if (rst)ir_q<=0;
		
	end
	
	
	always@(posedge clk)//w reg
	begin
		if(load_w)
			w_q<=alu_out;
		//else if(rst)
		//	w_q<=0;
	end
	
	
	wire ADDWF,ANDWF,CLRF,CLRW,DECF,COMF,GOTO,   
	MOVLW,ADDLW,SUBLW,ANDLW,IORLW,XORLW,
	INCF, IORWF, MOVF,MOVWF,SUBWF,XORWF,
	DECFSZ,INCFSZ,aluout_zero,BCF,BSF,BTFSC,BTFSS,
	btfsc_btfss_skip_bit,btfsc_skip_bit,btfss_skip_bit,
	ASRF,LSLF,LSRF,RLF,RRF,SWAPF,addr_port_b,
	CALL,RETURN,BRA,BRW,NOP,INCFEQCSZ;
	
	assign ADDWF = (ir_q[13:8] ==6'b00_0111);
	assign ANDWF = (ir_q[13:8] ==6'b00_0101);
	assign CLRF  = (ir_q[13:7] ==7'b00_0001_1);
	assign CLRW  = (ir_q[13:2] ==12'b00_0001_0000_00);
	assign COMF  = (ir_q[13:8] ==6'b00_1001);
	assign DECF  = (ir_q[13:8] ==6'b00_0011);
	assign GOTO  = (ir_q[13:11]==3'b10_1);
	
	assign MOVLW = (ir_q[13:8] ==6'b11_0000);
	assign ADDLW = (ir_q[13:8] ==6'b11_1110);
	assign SUBLW = (ir_q[13:8] ==6'b11_1100);
	assign ANDLW = (ir_q[13:8] ==6'b11_1001);
	assign IORLW = (ir_q[13:8] ==6'b11_1000);
	assign XORLW = (ir_q[13:8] ==6'b11_1010);
	
	assign INCF  = (ir_q[13:8] ==6'b00_1010);
	assign IORWF = (ir_q[13:8] ==6'b00_0100);
	assign MOVF  = (ir_q[13:8] ==6'b00_1000);
	assign MOVWF = (ir_q[13:7] ==7'b00_0000_1);
	assign SUBWF = (ir_q[13:8] ==6'b00_0010);
	assign XORWF = (ir_q[13:8] ==6'b00_0110);
	
	assign DECFSZ= (ir_q[13:8] ==6'b00_1011);
	assign INCFSZ= (ir_q[13:8] ==6'b00_1111);
	assign aluout_zero=(alu_out==0)?1'b1:1'b0;
	assign BCF	 = (ir_q[13:10] ==4'b0100);
	assign BSF	 = (ir_q[13:10] ==4'b0101);
	assign BTFSC = (ir_q[13:10] ==4'b0110);
	assign BTFSS = (ir_q[13:10] ==4'b0111);
	
	assign btfsc_skip_bit=ram_q[ir_q[9:7]]==0;
	assign btfss_skip_bit=ram_q[ir_q[9:7]]==1;
	assign btfsc_btfss_skip_bit=(BTFSC&btfsc_skip_bit)|
								(BTFSS&btfss_skip_bit);
    assign ASRF  = (ir_q[13:8] ==6'b11_0111);
	assign LSLF  = (ir_q[13:8] ==6'b11_0101);
	assign LSRF  = (ir_q[13:8] ==6'b11_0110);
	assign RLF   = (ir_q[13:8] ==6'b00_1101);
	assign RRF   = (ir_q[13:8] ==6'b00_1100);
	assign SWAPF = (ir_q[13:8] ==6'b00_1110);
	
	assign addr_port_b = (ir_q[6:0]==7'h0d);
	assign addr_port_c = (ir_q[6:0]==7'h0e);
	
	assign CALL	 = (ir_q[13:11] ==3'b100);	
	assign RETURN= (ir_q[13:0] ==14'b00_0000_0000_1000);
	
	assign BRA	 = (ir_q[13:9] ==5'b11_001);	
	assign BRW	 = (ir_q[13:0] ==14'b00_0000_0000_1011);	
	assign NOP	 = (ir_q[13:0] ==14'b00_0000_0000_0000);
	assign w_change={3'b0,w_q}-1;
	assign k_change={ir_q[8],ir_q[8],ir_q[8:0]}	-1;
	assign INCFEQCSZ=(ir_q[13:8] ==6'b11_0100);
	always@(*)
	begin
		load_pc=0;load_ir=0;rst_ir=0;load_mar_q=0;load_w=0;
		sel_pc=0;sel_alu=0;ram_en=0;op=0;sel_bus=0;
		sel_ram_mux=0;load_port_b=0;load_port_c=0;push=0;pop=0;
		case(ps)
			0:ns=1;
			1:
			begin
				load_mar_q=1;
				sel_pc=0;
				load_pc=1;
				
				ns=2;
			end
			2:
			begin
				
				ns=3;
			end
			3:
			begin
				load_ir=1;
				ns=4;
			end
			4:
			begin
				load_mar_q=1;
				sel_pc=0;
				load_pc=1;
				
				if(MOVLW|ADDLW|ANDLW|IORLW)
				begin
					load_w=1;
					if(MOVLW)begin op=5;end
					else if(ADDLW)begin op=0;end
					else if(IORLW)begin op=3;end
					else if(SUBLW)begin op=1;end
					else if(ANDLW)begin op=2;end
					else if(XORLW)begin op=4;end
				end
				else if(ADDWF)
				begin
					op=0;
					sel_alu=1;
					if(ir_q[7])begin//d=1
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(ANDWF)
				begin
					op=2;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(CLRF)
				begin
					op=8;
					sel_bus=0;
					ram_en=1;
				end
				else if(CLRW)
				begin
					op=8;
					load_w=1;
				end
				else if(COMF)
				begin
					op=9;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(DECF)
				begin
					op=7;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(INCF)
				begin
					op=6;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(IORWF)
				begin
					op=3;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(MOVF)
				begin
					op=5;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(MOVWF)
				begin					
					sel_bus=1;
					if(addr_port_b)
						load_port_b=1;
					else if(addr_port_c)
						load_port_c=1;
					else 
						ram_en=1;
				end
				else if(SUBWF)
				begin
					op=1;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(XORWF)
				begin
					op=4;
					sel_alu=1;
					if(ir_q[7])begin//d
						ram_en=1;
						sel_bus=0;end
					else
						load_w=1;
				end
				else if(BCF)
				begin
					sel_alu=1;
					sel_ram_mux=1;
					op[3:0]=5;
					sel_bus=0;
					ram_en=1;
				end
				else if(BSF)
				begin
					sel_alu=1;
					sel_ram_mux=2;
					op[3:0]=5;
					sel_bus=0;
					ram_en=1;
				end
				
				else if(ASRF)
				begin
					sel_alu=1;
					sel_ram_mux=0;
					op=4'hA;
					if(ir_q[7])
						begin
							sel_bus=0;
							ram_en=1;
						end
					else
						load_w=1;
				end
				else if(LSLF)
				begin
					sel_alu=1;
					sel_ram_mux=0;
					op=4'hb;
					if(ir_q[7])
						begin
							sel_bus=0;
							ram_en=1;
						end
					else
						load_w=1;
				end
				else if(LSRF)
				begin
					sel_alu=1;
					sel_ram_mux=0;
					op=4'hc;
					if(ir_q[7])
						begin
							sel_bus=0;
							ram_en=1;
						end
					else
						load_w=1;
				end
				else if(RLF)
				begin
					sel_alu=1;
					sel_ram_mux=0;
					op=4'hd;
					if(ir_q[7])
						begin
							sel_bus=0;
							ram_en=1;
						end
					else
						load_w=1;
				end
				else if(RRF)
				begin
					sel_alu=1;
					sel_ram_mux=0;
					op=4'hE;
					if(ir_q[7])
						begin
							sel_bus=0;
							ram_en=1;
						end
					else
						load_w=1;
				end
				else if(SWAPF)
				begin
					sel_alu=1;
					sel_ram_mux=0;
					op=4'hF;
					if(ir_q[7])
						begin
							sel_bus=0;
							ram_en=1;
						end
					else
						load_w=1;
				end
				else if(CALL)
				begin
					push=1;
				end
				else if(RETURN)
				begin
					
				end
				else if(BRA)
				begin
					sel_pc=3'b011;
					load_pc=1;
				end
				else if(BRW)
				begin
					sel_pc=3'b100;
					load_pc=1;
				end
				else if(NOP)
				begin
					
				end
				
				ns=5;
			end
			5:
			begin
				if(GOTO)begin
					sel_pc=2'b01;
					load_pc=1;
				end
				else if(CALL)begin
					sel_pc=2'b01;
					load_pc=1;
				end
				else if(RETURN)begin
					sel_pc=2'b10;
					load_pc=1;
					pop=1;
				end
				
				
				ns=6;
			end
			6:
			begin
				load_ir=1;
				if(GOTO||CALL||RETURN||BRA||BRW)begin
					rst_ir=1;
				end
				else if(DECFSZ)begin
					sel_alu=1;
					op[3:0]=7;
					if(!ir_q[7])
						load_w=1;
					else
					begin
						ram_en=1;
						sel_bus=0;
					end
					if(aluout_zero)rst_ir=1	;
				end
				else if(INCFSZ)begin
					sel_alu=1;
					op[3:0]=6;
					if(!ir_q[7])
					begin//d
						load_w=1;
					end
					else
					begin
						ram_en=1;
						sel_bus=0;
					end
					if(aluout_zero)
							begin
							rst_ir=1;
							end
				end
				else if(INCFEQCSZ)begin
					sel_alu=1;
					op[3:0]=6;
					ram_en=1;
					sel_bus=0;
					if(alu_out==port_c_out)
						rst_ir=1;
				end
				else if(BTFSC)
				begin
					if (btfsc_btfss_skip_bit)begin
						rst_ir=1;end
				end
				else if(BTFSS)
				begin
					if (btfsc_btfss_skip_bit)begin
						rst_ir=1;end
				end
				ns=4;
			end
		endcase
	end
  
endmodule




