module I2C_Master_tb
	#(parameter	DataWidth	= 8)	();

	logic								s_CLK, s_NRESET;
	logic								s_ENABLE;

	logic								s_Start, s_Stop;
	logic[6:0]							s_Address;
	logic								s_R_NW;

	logic[(DataWidth - 1):0]	s_WriteData;//, s_ReadData;

	logic								s_SCL, s_SDA;

	

	I2C_Master DUT
		(s_CLK, s_NRESET,
		s_ENABLE,
		s_Start, s_Stop,
		s_Address, s_R_NW,
		s_WriteData, //s_ReadData,
		s_SCL, s_SDA);


	/*	Initial system state	*/
	initial
	begin
		s_CLK = 1'b0; s_NRESET = 1'b1;
		s_ENABLE = 1'b0;
	end

	/*	System Clock	*/
	always
	begin
		#5;	s_CLK = ~s_CLK;
	end
	
	event ResetTrigger_Event;
		event ResetTriggerDone_Event;
		initial
		forever
		begin
			@(ResetTrigger_Event);
			@(negedge s_CLK);
			s_NRESET = 1'b0;
			repeat (2)	@(negedge s_CLK);
//			for (i = 0; i < 2; i++)
	//		begin
		//		@(negedge s_CLK);
			//end
			s_NRESET = 1'b1;

			s_ENABLE = 1'b0;
			s_Start = 1'b1;	s_Stop = 1'b0;
			//s_SDA = 1'b1; s_SCL = 1'b1;
			->	ResetTriggerDone_Event;
		end

	event FinishTestbench_Event;
	initial
	begin
		@(FinishTestbench_Event);
		#47;	$stop;
	end

	event Testbench_Event;
		event TestbenchDone_Event;
		initial
		forever
		begin
			@(Testbench_Event);
			#27;
			s_ENABLE = 1'b1;
			repeat (2)	@(negedge s_CLK);
			s_WriteData = 8'h5A;
			s_Address = 7'b0011010;
			s_R_NW = 1'b0;
			#17;
			@(negedge s_CLK);				s_Start = 1'b0;
			repeat(1)	@(negedge s_CLK);	s_Start = 1'b1;
			repeat(18)	@(negedge s_CLK);	s_WriteData = 8'h67;
			repeat(9)	@(negedge s_CLK);	s_Stop = 1'b1;
			repeat(3)	@(negedge s_CLK);	s_Stop = 1'b0;
			repeat(2)	@(negedge s_CLK);	s_Start = 1'b0;
			repeat(1)	@(negedge s_CLK);	s_Start = 1'b1;
			repeat(19)	@(negedge s_CLK);
			#45;
			->	TestbenchDone_Event;
			->	FinishTestbench_Event;
		end

		
	event SystemInitialization_Event;
		event SystemInitializationDone_Event;
		initial
		begin
			@(ResetTriggerDone_Event);
			@(negedge s_CLK);
			s_ENABLE = 1'b1;
			s_Start = 1'b1; s_Stop = 1'b0;
			s_WriteData = 8'h00;//, s_ReadData;
			@(negedge s_CLK);
			#1;	->	Testbench_Event;
		end


	initial
	begin
		#17;	->	ResetTrigger_Event;
	end

endmodule
