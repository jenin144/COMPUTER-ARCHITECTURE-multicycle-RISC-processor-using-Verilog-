


// Define global variables
reg [2:0]current_state;
reg [2:0]next_state;
reg [31:0]IR;
integer i=1; 
integer S=1; 
integer  l=1;


module TheAllSystem (	   // < ------------
    input clk,
    input reset,
	
	//For Instruction Decode
	output reg [31:0] Rd, // (Bus W) Output data from register 3  <---
	output reg [31:0] Rs1, // (Bus A )Output data from register 1	 <---
    output reg [31:0] Rs2, // (Bus B) Output data from register 2	  <---	
	
	//ALU result 
	output reg[31:0] ALUResult, //for verification
	
	//ExtenderResult
	output reg[31:0]extended_immediate, ////////////////////////////////Added This
	reg[15:0] immediate_16bit,
	
    output reg PCSrc0, // sel 1
    output reg PCSrc1 ,// sel 2 	   
	output reg RegWrite1,
	output reg RegWrite2,
	output reg extension_signal,
	output reg ALUSrc, 
	output reg [1:0] ALUOp,
	output reg MemWrite, 
	output reg MemRead,
	output reg WriteBack,
	output reg DataInSig1,
	output reg AddressSig1,
	output reg RegSrc2              ///////---------------------> I added this
			 

);	
//****************************************************************************************
		/// Instruction Fetch

   	 reg [31:0] Imemory [0:31];	  
	 reg [31:0] PC;	
	 reg [31:0] Registers[0:15];
	 reg [31:0] sp_address;	 //Stack Pointer to the empty slot
	 reg [31:0] Top_ofthe_stack;	 //Stack Point the last dain in
	 reg [31:0] DataMemory [63:0];
	 reg [31:0] address,data_in;
     reg [31:0] data_out;
	 reg [31:0] muxOut;
	 
	 			
	 
	 //ID
	 reg [5:0] OP_CODE; 	
	 reg [3:0] AddressToRd;	 // Address for Rd
	 reg [3:0] AddressToRs1;  // Address for RS1
	 reg [3:0] AddressToRs2;  // Address for RS2	 
	 reg [25:0] Imm26;  //
	 	 
		 
	///ALU Part
	reg zero; // Zero flag indicating if the result is zero	
	reg OverFlow;  // <--
	reg Negative;  //<--
	
	//////////////////////////////////////////////////////////// I added this
	reg [31:0] Y;
	reg[31:0] OperandA;	
	reg[31:0] OperandB;

	reg [1:0] MODE;
	
	reg[31:0] outputOfBTA;
	/////////////////////////////////////////////////////////////////
	
	
	
	 
    // State definitions
    parameter IF = 0, ID = 1, EX = 2, MEM = 3, WB = 4;
    reg [4:0] flag; //
	
	
		 		 	  initial begin
		 DataMemory[12] = 32'h00000007;  
		 DataMemory[14] = 32'h00000006;

				  end
	
	
	

	 		  initial begin
		 DataMemory[12] = 32'h00000007;  
		 DataMemory[14] = 32'h00000006;
		 DataMemory[33] = 32'h00000007;  
		 DataMemory[35] = 32'h00000006;
		 DataMemory[36] = 32'h00000006;
				  end
	initial begin
		
           Imemory[0] =32'b00000100010010100100000000000000; // ADD   ->  reg(1) =reg(2)+ reg(9) -> 3=2+1
		   Imemory[1] = 32'b00001100100001000000000001001000; // ANDI   -> reg(2) = reg(1) & 12 = 2 = 3&12
		   Imemory[2] = 32'b00011110111000000000000000011000;	// sw the value 4 to mem[12] (from 7 to 4)	 then use load to put in reg 6 then use reg 6 to see the result	
	       Imemory[3] = 32'b00011001100101000000000000001101;  //LW.poi  (reg(6)=3) = mem[reg(5)= 9) + (imm16=3)] -> mem[12/c]	--> mem[12] = 4 -> data-out=4 then reg(6)=4														       //reg(5)++ -> 10  
		   Imemory[4] =32'b00001000100101011000000000000000; // Sub reg(2) = (reg(5) = 10 ) - (reg(6)=4 )	 
		 
		   Imemory[5]  =32'b00110100000000000000000000000111; //   call	  Imemory[7]	 
		 
		   Imemory[6] = 32'b00100010101011000000000000001000;	 //BGT-->taken<---  (reg(10)=12  - reg(11)=4)  = rs1 - rd = -8 -> ra<rd taken go to Imemory[8]
				 
		   Imemory[7] =32'b00111000000000000000000000000000; // return	 to Imemory[5]+1 = 6
		  
		   Imemory[8] =32'b00001100100001000000000001001000;  // just to check  brnash is taken   
		   
		   Imemory[9]=32'b00111110000000000000000000000000;  // PUSH Reg(8) = 6
		   Imemory[10]=32'b00000110001000100100000000000000;    // add then the value in R7	-> reg(8) + reg(9) = 6+1 = 7
		   Imemory[11]=32'b01000001110000000000000000000000;  // pop to Reg7 ->  Rd =  6 
		 //->  
		   Imemory[12]=32'b00000101110000000000000000000000;  //  ADD
		   
		   Imemory[13]=32'b00010101110000000000000000000000;  //  LW
		   
		   Imemory[14]=32'b00100101110000000000000000000000;  // BLT
		   
		   Imemory[15]=32'b00101101110000000000000000000000;  //	 BNEQ
		   
		   Imemory[16]=32'b00110001110000000000000000000000;  // 	JMP
		   
		   
		   
		end

		
		//*****************************************************************************************
          	initial begin		
		// 16 32-bit general-purpose registers: from R0 to R15. 
	  	    Registers[0] = 32'h00000000;				
            Registers[1] = 32'h00000003;
            Registers[2] = 32'h00000002;
            Registers[3] = 32'h00000011;//11
            Registers[4] = 32'h00000006;
            Registers[5] = 32'h00000009;
            Registers[6] = 32'h00000003;
            Registers[7] = 32'h00000005;
            Registers[8] = 32'h00000006;
            Registers[9] = 32'h00000001;
            Registers[10] = 32'h00000012;
            Registers[11] = 32'h00000004;
            Registers[12] = 32'h00000017;
            Registers[13] = 32'h00000020;
            Registers[14] = 32'h00000026;
            Registers[15] = 32'h00000032; //000000, 0011-0010
		
			   end
		
		 //////////////////

	
//************************************************************************************************	
   integer j;
   always @(posedge clk) 
        case (current_state)
            IF: next_state <= ID;
            ID: next_state <= EX;
            EX: next_state <= MEM;
            MEM: next_state <= WB;
            WB: next_state <= IF;
        endcase
    	 
		 
	always @(posedge clk) 
 		current_state = next_state;
		
		
    always @(posedge clk or posedge reset)  
	
        if (reset) begin
			
			// Put A reset Printing Statement Here
			 $display ("Before Entering Stage, We are Resetting Variables.\n"); 
			
            current_state <= WB;	   
			Rd = 32'd0;
            PC <= 32'h00000000;	
		 	Rs1 = 32'd0;
			Rs2 = 32'd0;
			Y = 32'h00000000;         //Added this to reset the result of 2ndOperand Mux --> input to ALU
            ALUResult <= 32'h00000000;	 //Added by alaa
			outputOfBTA <= 32'h00000000; //Added by alaa 
			flag <= 0;
  			Top_ofthe_stack<= 32'h00000021; // <---- the stack part start at address - datamemory[33]
			sp_address <= 32'h00000021; // <---- the stack part start at address - datamemory[33]
			data_in= 32'h00000000; 
			data_out= 32'h00000000;
			address= 32'h00000000;
			immediate_16bit=0  ;   
			muxOut=0;

     		//for (j = 0; j < 16; j = j + 1)
    	 		// Registers[j] <= 32'h00000000;	//<---
		end	   

		
//----------------------------------------------------------------------------------------		
		
       else if (current_state == IF) begin	 
		   	// Put A reset Printing Statement Here
		   		 $display ("\n\n---------------->We are in FETCH Stage.<---------------\n\n"); 
		   
		   		
//******************** mux4x1 ********************************** 
		   if (flag != 0) begin		   		   
                case ({PCSrc0, PCSrc1})
                    2'b00: PC <= PC + 2 - l ;
                    2'b01: PC <= {PC[31:26],Imm26}; // JMP   
		    2'b10:  PC <= outputOfBTA; 								
                    2'b11: PC <= DataMemory[Top_ofthe_stack]; // Top of the stack 
                endcase               
           		 end 
		  flag <= flag + 1;
		  l=l+1;
		  IR = Imemory[PC]; 
 

	$display ("IR: %b", IR); 
	$display ("PC: %b", PC);  
	
	
		  		 end
		
//------------------------------------------------------------------------------------------


  else if (current_state == ID) begin	
		l=1;
	 $display ("\n\n---------------->We are in Decode Stage.<---------------\n\n"); 
	
    	OP_CODE = IR[31:26];
			$display ("OP: %b",  OP_CODE); 	
	
		   
	
		   
//########################################################################			   
		   // R-type
	if 	( OP_CODE >= 6'b000000 &&  OP_CODE <= 6'b000010 )
	  begin
		  
		
	 	AddressToRd = IR[25:22];  	  		 
		AddressToRs1 = IR[21:18];
		AddressToRs2 = IR[17:14];
		
	 

		  
		// Control Signals  
		  
	 PCSrc0	=   1'b0; // PC+1
     PCSrc1 = 	1'b0;   
   	 RegWrite1 =  1'b1;
   	 RegWrite2 =  1'b0;
	 ALUSrc =  1'b0; //BusB
	 MemWrite = 1'b0; 
	 MemRead =	1'b0;
	 WriteBack =   1'b0; // ALU Result
	 DataInSig1 =  1'bx;   
	 AddressSig1 =  1'b0; // Adress from ALU 
	 RegSrc2 = 1'b0;		  
	  
		
				 if (OP_CODE == 6'b000000)	  begin
					ALUOp = 2'b00;	 // AND	 
					extension_signal = 1'bx; 
				 end
				 
				else if (OP_CODE == 6'b000001) begin 
					ALUOp = 2'b01; // ADD
					extension_signal =1'bx;
					
				end
				
				else
					ALUOp = 2'b10;  begin // SUB 
					extension_signal=1'bx;
	 
		 		 end	  
		  
				  
	   end  
//####################################################	 
	   	
  
	   // I-TYPE	

	else if ( OP_CODE >= 6'b000011 &&  OP_CODE <= 6'b001011 )	 
		
	  begin	  				
		  
		AddressToRd = IR[25:22];  	  		  // we have to do this division for all types
		AddressToRs1 = IR[21:18];
		immediate_16bit = IR[17:2];
		MODE = IR[1:0];	 
					   
		  
	 if (OP_CODE == 6'b000011 || OP_CODE == 6'b000100)	  begin
  
		  
	 PCSrc0	=   1'b0; // pc+1
     PCSrc1 = 	1'b0; 
	 RegWrite1 =  1'b1;
   	 RegWrite2 =  1'b0; 		
	 ALUSrc =  1'b1; //	imm 
	 MemWrite = 1'b0; //  
	 MemRead =	1'b0; 
	 WriteBack =   1'b0; // ALU Result
	 DataInSig1 =  1'bx; 
	 RegSrc2 = 1'bx; // <---
	 AddressSig1 =  1'bx; 

	 
	 	 if (OP_CODE == 6'b000011)	  begin
					ALUOp = 2'b00;	 // ANDi	 
					extension_signal = 1'b0;
				 end
				 
	 	else 
			begin 
					ALUOp = 2'b01; // ADDi
					extension_signal =1'b1;
					
			 end 
	 
	 									end	  
	 
	 
	 if (OP_CODE == 6'b000101 || OP_CODE == 6'b000110 || OP_CODE == 6'b000111)	 
		 begin
		 
			 
			 
			 	 PCSrc0	=   1'b0; // pc+1
			     PCSrc1 = 	1'b0; 
				 ALUSrc =  1'b1; //	imm 
				 RegSrc2 = 1'b1; // Rd <---
				 AddressSig1 =  1'b0; //<-- ALU
		         ALUOp = 2'b01;   
				 extension_signal=1'b1; 
			 
			 
			 
			 		
				 if (OP_CODE == 6'b000101)	  begin // LW
			 	 RegWrite1 =  1'b1;
			   	 RegWrite2 =  1'b0; 
				 MemWrite = 1'b0; //  
				 MemRead =	1'b1;
				 WriteBack =   1'b1;  
				 DataInSig1 =  1'bx; 
				
				 end
				 
				else if (OP_CODE == 6'b000110 ) begin  //poi
				 RegWrite1 =  1'b1;
			   	 RegWrite2 =  1'b1;
				 MemWrite = 1'b0; //  
				 MemRead =	1'b1; 
				 WriteBack =   1'b1; 
				 DataInSig1 =  1'bx; 
					
				end
				
				else	begin				// SW
		 		 RegWrite1 =  1'b0;
			   	 RegWrite2 =  1'b0; 
				 MemWrite = 1'b1; //  
				 MemRead =	1'b0; 
				 WriteBack =   1'bx ;
				 DataInSig1 =  1'b1; 
	 
		 		 end	
			 
		 
		 end
	 
		 
		 if (OP_CODE >= 6'b001000 && OP_CODE <= 6'b001011 )		// branches
			 begin
			
				 			// Control Signals  
		  
	 PCSrc0	=   1'b1; 
     PCSrc1 = 	1'b0;   
   	 RegWrite1 =  1'b0;
   	 RegWrite2 =  1'b0;
	 ALUSrc =  1'b0; 
	 MemWrite = 1'b0; 
	 MemRead =	1'b0;
	 WriteBack =   1'bx; 
	 DataInSig1 =  1'bx;   
	 AddressSig1 =  1'bx; 
	 RegSrc2 = 1'b1; 
     ALUOp = 2'b10; 
	 extension_signal =1'b1;
				 
				 
		 	  end
		 
		 
	 
		 		 
			 if (extension_signal == 1'b0) begin
        		// Zero-extension (extend by 0's)
     			extended_immediate = {16'b0, immediate_16bit};
    		 end
    		 else begin
        		// Sign-extension
     		   extended_immediate = {{16{IR[15]}}, immediate_16bit};
  			 end		  	  
	  end
	  
//########################################################################	 																	  
	  
    // J-TYPE
	  
	else if 	( OP_CODE >= 6'b001100 &&  OP_CODE <= 6'b001110 )
	  begin	 
		  
		  
		  	Imm26 = IR[25:0];  
		  
		  
	if  (OP_CODE >= 6'b001100) // <-- jmp
	 begin  
	 PCSrc0	=   1'b0; // jmp address
     PCSrc1 = 	1'b1; 
	 RegWrite1 =  1'b0;
   	 RegWrite2 =  1'b0; 		
	 ALUSrc =  1'bx; // we don't use the alu 	 
	 MemWrite = 1'b0; // <-- to the stack  
	 MemRead =	1'b0; 
	 WriteBack =   1'bx; // ALU Result
	 DataInSig1 =  1'bx; 
	 RegSrc2 = 1'bx;
	 AddressSig1 =  1'bx; 
	 ALUOp = 2'bxx;   
	 extension_signal=1'bx;  
	 
	 current_state <= WB;

	 		  
		end  
		  
		  
			  
	if  (OP_CODE >= 6'b001101) // <-- call
	 begin  
	 PCSrc0	=   1'b0; // jmp address
     PCSrc1 = 	1'b1; 
	 RegWrite1 =  1'b0;
   	 RegWrite2 =  1'b0; 		
	 ALUSrc =  1'bx; // we don't use the alu 	 
	 MemWrite = 1'b1; // <-- to the stack  
	 MemRead =	1'b0; 
	 WriteBack =   1'bx; // ALU Result
	 DataInSig1 =  1'b0;  // Pc+1 call 
	 RegSrc2 = 1'bx; //////////////////////// 
	 AddressSig1 =  1'b1; // from the stack pointer 
	 ALUOp = 2'bxx;   
	 extension_signal=1'bx; 
	   current_state <= EX;	// skip alu
	 

	 		  
		end  
		
	
	if  (OP_CODE >= 6'b001110) // <-- RET
	 begin  
	   
	 PCSrc0	=   1'b1; // stack address
     PCSrc1 = 	1'b1; 	 
	 RegWrite1 =  1'b0;
   	 RegWrite2 =  1'b0; 		
	 ALUSrc =  1'bx; // we don't use the alu 	 
	 MemWrite = 1'b0; // <-- to the stack  
	 MemRead =	1'b1; 
	 WriteBack =   1'bx; // ALU Result
	 DataInSig1 =  1'bx;  // call 
	 RegSrc2 = 1'bx; 
	 AddressSig1 =  1'b1; // from the stack pointer 
	 ALUOp = 2'bxx;   
	 extension_signal=1'bx;  
	 		  
		end  
		
				
		  		  
	  end 
	 
//########################################################################  
	  // S-type
	  
	else if 	( OP_CODE >= 6'b001111 &&  OP_CODE <= 6'b010000 )
	  begin
		
	AddressToRd = IR[25:22];  // AdrressOfRd 4 bits length
		  
		  
		  
	// Control Signals  
		  
	 PCSrc0	=   1'b0; // PC+1
     PCSrc1 = 	1'b0;
	 
	 
	 
	 
	 if  (OP_CODE == 6'b001111) // <-- push
	 begin	
		 	 
			 
   	 RegWrite1 =  1'b0;
   	 RegWrite2 =  1'b0; 		
	 ALUSrc =  1'bx; // we don't use the alu 	 
	 MemWrite = 1'b1; // <-- to the stack  
	 MemRead =	1'b0; 
	 WriteBack =   1'bx; // ALU Result				 
	 RegSrc2 = 1'b1;   // the second operand is Rd which is pushed on stack
	 DataInSig1 =  1'b1; // choose BusB which will be Rd
	 AddressSig1 =  1'b1; // from the stack pointer 
	 ALUOp = 2'bxx;   
	 extension_signal=1'bx;    
		 
	 current_state <= EX; //< --- Skip EX	 ;
		  	 
	 end
	 
	 
	 else // pop	 
		 begin
			 
			 
   	 RegWrite1 =  1'b1;
   	 RegWrite2 =  1'b0; 		
	 ALUSrc =  1'bx; // we don't use the alu 	 
	 MemWrite = 1'b0; // <-- to the stack  
	 MemRead =	1'b1; 
	 WriteBack =   1'b1; // ALU Result
	 DataInSig1 =  1'bx; // data-out  
	 AddressSig1 =  1'b1; // from the stack pointer 
	 ALUOp = 2'bxx;   
	 extension_signal=1'bx;  	 
	 RegSrc2 = 1'bx; 		 
		end	 
	
	  current_state <= EX; //< --- if this allowed  because these two instruction not using the alu ! 	  
		  
		 	  
	  	end 	  
	  
//########################################################################	  
	   	case ({RegSrc2})
			
		 2'b0 :  	 Rs2 = Registers[AddressToRs2];	 
		 2'b1 :	     Rs2 = Registers[AddressToRd];	  //if regSrc2 = 1
		endcase   	  
		
		Rd = Registers[AddressToRd];  	// Destination Register
		Rs1 = Registers[AddressToRs1];		   //Operand Sr1  
		
		
		
		$display ("ADDRESSRD: %b",  AddressToRd);	
		$display ("ADDRESSRS1: %b",  AddressToRs1);	
	    $display ("ADDRESSRS2: %b",  AddressToRs2);
		
		
		$display ("\n\n Contents Here \n");
		$display ("Content of Rd: %b",  Rd);	
		$display ("Content of Rs1: %b",  Rs1);	
	    $display ("Content of Rs2: %b",  Rs2);
	    
		     
		
	   
	   end
//------------------------------------------------------------------------------------	



else if (current_state == EX) begin	 
	
			$display ("\n\n---------------->We are in Execution Stage.<---------------\n\n"); 
		    $display ("PC: %b", PC); 	   
			$display ("outputOfBTA: %b", outputOfBTA); 
			$display ("zero flag: %b", zero);
			$display ("Negative flag: %b", Negative);
			
	case ({ALUSrc})	
		0'b0: Y =  Rs2;
		0'b1: Y =  extended_immediate;
	endcase
	
	OperandA = Rs1;
	OperandB = Y; // output of previous Mux
	
	case(ALUOp)
		2'b00: ALUResult = OperandA & OperandB;    //Anding between the Operands
		2'b01: ALUResult = OperandA + OperandB;       //Adding between Operands
		2'b10: ALUResult = OperandA - OperandB;		 //Subtracting between Operands
		default: ALUResult = 32'b0;
	endcase	 
	
	
	
	if (OP_CODE >= 6'b000000 && OP_CODE <= 6'b000100) begin	 // If instruc. are: AND, ADD, SUB, ANDI, ADDI skip memory stage

			current_state = MEM;	
	 end

	
	
	//Setting the Flags 
	zero = (ALUResult == 32'b0); 
	if (ALUResult[31] == 1'b1) begin
            Negative = 1'b1;		
        end
        else begin
           Negative = 1'b0; 
	end
	
	// For these Instructions:BGT, BLT, BEQ, BNE we must move to the next instruction after Execution Stage
		 //BGT Reg(Rd) > Reg(Rs1) operandB-OpeA
		if (OP_CODE == 6'b001000) begin	//branch if Operand2(content of Rd) is gretaer than Operand1 (content of Rs1) meaning Rs1-Rd results in Negative Number

			
			
			if (Negative == 1)	begin
				// Branch Target Address
				outputOfBTA = PC + extended_immediate;
				current_state = WB;					
			end
	
			else begin
				outputOfBTA = PC + 1;
				current_state = WB;
			end	
		end
   		
		/////////////////////////////////////////////////////////
		// BLT 	
		else if (OP_CODE == 6'b001001) begin	//branch if Operand2(content of Rd) is less than Operand1 (content of Rs1) meaning Rs1-Rd results is +ve Number

			if (Negative == 0 && zero == 0)	begin
				// Branch Target Address
				outputOfBTA = PC + extended_immediate;
				current_state = WB;	
			end
	
		else
			begin
				outputOfBTA = PC + 1;
				current_state = WB;
			end	
		end
		/////////////////////////////////////////////////////////
		// BEQ	
		else if (OP_CODE == 6'b001010) begin
			

			if (zero == 1)	begin
				// Branch Target Address
				outputOfBTA = PC + extended_immediate; 
				//PC = outputOfBTA;
				current_state = WB;	
			end
	
		else begin		
				outputOfBTA = PC + 1;
				current_state = WB;
			end	
		end	 
		/////////////////////////////////////////////////////////
		// BNE	
		else if (OP_CODE == 6'b001011) begin

			
			if (zero == 0)	begin
				// Branch Target Address
				outputOfBTA = PC + extended_immediate;
				current_state = WB;	
			end
	
		else begin	

				outputOfBTA = PC + 1;
				current_state = WB;
			end	
		end

end		  



	
//-------------------------------------------------------------------------------------
 
	
	else if (current_state == MEM) begin  
	$display ("\n\n---------------->We are in Memory Stage.<---------------\n\n"); 
		
		  if ( AddressSig1 ==  1'b0) 	
			  address <= ALUResult; 
			  	  
		 else    
		begin  		  
		  address = Top_ofthe_stack ;
		  
		 if (MemWrite) begin
			if ( sp_address == Top_ofthe_stack) 
		 sp_address= sp_address + 1'b1 ;
			else begin
			 sp_address= sp_address + 1'b1 ;
			  Top_ofthe_stack= Top_ofthe_stack + 1'b1 ;
			end												   //////////                       sp addresss + top of the satck must be >>> 33
		 end// 
		else begin 
			if ( Top_ofthe_stack == 32'h00000021 && sp_address != 32'h00000021)
			sp_address= sp_address - 1'b1 ;
			else if (  Top_ofthe_stack != 32'h00000021 && sp_address != 32'h00000021) 	begin
			sp_address= sp_address - 1'b1 ;	
			Top_ofthe_stack= Top_ofthe_stack - 1'b1 ;
		 	 end
			else if (Top_ofthe_stack == 32'h00000021 && sp_address == 32'h00000021) 
					$display ("\n\n--The the stack is empty:\n"); 
		 end
     	end
		 $display ("\n\n--The sp_address: %d\n",sp_address); 
		 $display ("\n\n--Top_ofthe_stack: %d\n",Top_ofthe_stack); 
		
		case ({DataInSig1})
			
		 2'b0 :  	 data_in <= PC+1 ;
		 2'b1 :	     data_in <= Rd ;///Rs2	 ;	   <-----	must add mux to choose rs2 = >rd first
		endcase 
		
	
				
		
		 if (MemWrite)  DataMemory[address] <= data_in	;				
		
    	else if (MemRead) data_out <= DataMemory[address] ;	
			
		 	
		$display ("\n\n--The Address: %d\n",address); 
		$display ("\n\n--The MemoryOut (DataOut): %d\n",data_out);
		$display ("\n\n--The Memoryin (Datain): %d\n",data_in);
		
		
	if (OP_CODE == 6'b000111 || OP_CODE == 6'b001101 || OP_CODE == 6'b001110 || OP_CODE == 6'b001111 )	// store , call,return,push 
     	  	current_state = WB ;	 //skiip write back
	
		
	
	end	
	
//----------------------------------------------------------------------------------------------------------------------------------------------------------


else if (current_state == WB) begin	 
		 
	
	

		 case (WriteBack)		
		 1'b0 :  	 muxOut <=  ALUResult;
		 1'b1 :	     muxOut <=  data_out;
		 endcase 
		 
		 $display ("\n\n---------------->We are in Write Back  Stage.<---------------\n\n"); 
		 
		 
		 $display ("\n:MuxOut : %h\n",muxOut);
		 
		 if ( RegWrite1 ==  1'b1) begin 	
			 Registers [AddressToRd] <= muxOut;
	     end
		 
	     if (RegWrite2 ==  1'b1)	begin
			 Registers [AddressToRs1] <= Registers [AddressToRs1] + 2 - i;
			 
			 i=i+1;
		 end	
		 
		 
		 $display ("\n\n\n***********DONE The INST*****************\n\n\n");	
				
	end
	
//----------------------------------------------------------------------------------------------------------------------------------------------------------------	
endmodule	 

module TestBench ();
    reg clk;
    reg reset;	  
    wire [31:0] Rd;
    wire [31:0] Rs1;
    wire [31:0] Rs2;	
    wire [31:0] ALUResult;
    wire [31:0] extended_immediate;	
    wire[15:0] immediate_16bit;
    wire PCSrc0;
    wire PCSrc1;
    wire RegWrite1;
    wire RegWrite2;
    wire extension_signal;
    wire ALUSrc; 
    wire [1:0] ALUOp;
    wire MemWrite;
    wire MemRead;
    wire WriteBack;
    wire DataInSig1;
    wire AddressSig1;
    wire RegSrc2;

    TheAllSystem allss (
        .clk(clk),
        .reset(reset),
        .Rd(Rd),
        .Rs1(Rs1),
        .Rs2(Rs2),
        .ALUResult(ALUResult),
        .extended_immediate(extended_immediate), 
		.immediate_16bit(immediate_16bit),
        .PCSrc0(PCSrc0),
        .PCSrc1(PCSrc1),
        .RegWrite1(RegWrite1),
        .RegWrite2(RegWrite2),
        .extension_signal(extension_signal),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .WriteBack(WriteBack),
        .DataInSig1(DataInSig1),
        .AddressSig1(AddressSig1),
        .RegSrc2(RegSrc2)
    );

    initial begin
        current_state = 0;
        clk = 0;
        reset = 1;
        #1ns reset = 0;
    end

    always #2ns clk = ~clk;

    always @(posedge clk) begin
        $display("Time=%0t: current_state=%0d, Rd=%h, Rs1=%h, Rs2=%h, ALUResult=%h,immediate_16bit=%d,extended_immediate=%h, PCSrc0=%b, PCSrc1=%b, RegWrite1=%b, RegWrite2=%b, extension_signal=%b, ALUSrc=%b, ALUOp=%b, MemWrite=%b, MemRead=%b, WriteBack=%b, DataInSig1=%b, AddressSig1=%b, RegSrc2=%b", 
                  $time, current_state, Rd, Rs1, Rs2, ALUResult,immediate_16bit, extended_immediate, PCSrc0, PCSrc1, RegWrite1, RegWrite2, extension_signal, ALUSrc, ALUOp, MemWrite, MemRead, WriteBack, DataInSig1, AddressSig1, RegSrc2);
    end

    initial #400ns $finish;
endmodule
