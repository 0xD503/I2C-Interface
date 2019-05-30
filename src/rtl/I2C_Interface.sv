module I2C_Master
	#(parameter	DataWidth	= 8,
				BuferSize	= 64)
	(input logic					i_CLK, i_NRESET,
	input logic						i_ENABLE,

	//	CPU interface
	input logic						i_Start, i_Stop,
	input logic[6:0]				i_Address,
	input logic						i_R_NW,
	input logic[(DataWidth - 1):0]	i_WriteData,
	//output logic[(DataWidth - 1):0]	o_ReadData,

	//	Bus interface
	output logic					o_SCL,
	output logic					o_SDA);

	//logic[(DataWidth - 1):0]		s_DataBufer[(BuferSize - 1):0];
	logic					s_SCL, s_SDA;
	logic					s_Start, s_Stop;
	logic[6:0]				s_Address;
	logic					s_R_NW;
	logic[3:0]				s_BitCounter;
	logic[7:0]				s_Address_RW;
	logic					s_StopCount;

	typedef enum logic[2:0]	{I2C_STATE_IDLE, I2C_STATE_SEND_START, I2C_STATE_SEND_ADDR, I2C_STATE_WRITE_BYTE/*, I2C_STATE_READ_BYTE*/, I2C_STATE_SEND_STOP}	stateType_I2C;
	stateType_I2C		st_CurrentState, st_NewState;


	//	Register logic
	always_ff	@(posedge i_CLK, negedge i_NRESET)
	begin
		if (~i_NRESET)
			begin
				st_CurrentState <= I2C_STATE_IDLE;
				s_BitCounter <= 4'd9;
			end
		else if (i_ENABLE)
			begin
				st_CurrentState <= st_NewState;
				if (~i_Start)					s_BitCounter <= 4'd9;
				else if (s_BitCounter == 4'd0)	s_BitCounter <= 4'd8;
				else							s_BitCounter <= s_BitCounter - 4'd1;
			end
	end

	//	New State logic
	always_comb
	begin
		case (st_CurrentState)
			I2C_STATE_IDLE:
			begin
				s_Start	= 1'b1;
				s_Stop	= 1'b0;
				s_Address	= i_Address;
				s_R_NW		= i_R_NW;

				s_SDA = 1'b1;

				st_NewState = (~i_Start)	?	I2C_STATE_SEND_START : I2C_STATE_IDLE;
			end

			I2C_STATE_SEND_START:
			begin
				s_Start	= 1'b0;
				s_Stop	= 1'b0;
				s_Address	= i_Address;
				s_R_NW		= i_R_NW;

				s_SDA = 1'b0;

				st_NewState = (i_Stop)	?	I2C_STATE_SEND_STOP : I2C_STATE_SEND_ADDR;
			end

			I2C_STATE_SEND_ADDR:
			begin
				s_Start	= 1'b1;
				s_Stop	= 1'b0;
				s_Address	= i_Address;
				s_R_NW		= i_R_NW;
				
				s_SDA = (s_SCL) ?	s_Address_RW[s_BitCounter - 4'd1] : (s_BitCounter == 4'd0) ?
									1'bz : s_Address_RW[s_BitCounter - 4'd1];

				st_NewState = (i_Stop)	?	I2C_STATE_SEND_STOP : (s_BitCounter != 4'd0) ?
											I2C_STATE_SEND_ADDR : (s_R_NW) ?
											/*I2C_STATE_READ_BYTE*/I2C_STATE_IDLE : I2C_STATE_WRITE_BYTE;
			end

			I2C_STATE_WRITE_BYTE:
			begin
				s_Start	= i_Start;
				s_Stop	= 1'b0;
				s_Address	= i_Address;
				s_R_NW		= i_R_NW;
				
				s_SDA = (s_SCL) ?	i_WriteData[s_BitCounter - 1] : (s_BitCounter == 4'd0) ?
									1'bz : i_WriteData[s_BitCounter - 1];

				st_NewState = (i_Stop)	?	I2C_STATE_SEND_STOP : (s_Start) ?
											I2C_STATE_WRITE_BYTE : I2C_STATE_SEND_ADDR;
			end

			//I2C_STATE_READ_BYTE:
				//begin
				
				//end

			I2C_STATE_SEND_STOP:
			begin
				s_Start	= i_Start;
				s_Stop	= 1'b1;
				s_Address	= i_Address;
				s_R_NW		= i_R_NW;;

				s_SDA = (s_BitCounter == 4'd7) ?	1'b1 : 1'b0;

				st_NewState = (s_BitCounter == 4'd7) ?	I2C_STATE_IDLE : I2C_STATE_SEND_STOP;
			end

			default:
			begin
				s_Start	= 1'bz;
				s_Stop	= 1'bz;
				s_Address	= 7'bz;
				s_R_NW		= 1'bz;

				s_SDA = 1'bz;

				st_NewState = I2C_STATE_IDLE;
			end

		endcase
	end

	assign s_Address_RW = {s_Address, s_R_NW};

	assign s_SCL = i_CLK;
	//	Output logic
	assign o_SCL = (~i_ENABLE | ((st_CurrentState == I2C_STATE_IDLE) | (s_Stop == 1'b1))) ?	1'b1 : s_SCL;
	assign o_SDA = (i_ENABLE) ?	s_SDA : 1'b1;


	//assign s_NSCL = ~s_SCL;

endmodule

