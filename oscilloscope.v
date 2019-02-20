module oscilloscope(  CLOCK_50,
signal,
oVGA_CLK,
oVS,
oHS,
oBLANK_n,
b_data,
g_data,
r_data,
SW0,
ifft_I,
ifft_Q);


input CLOCK_50;
input [15:0] signal;
output oVGA_CLK;
output oVS;
output oHS;
output oBLANK_n;
output reg [7:0]b_data ;
output reg [7:0]g_data ;  
output reg [7:0]r_data ;
input SW0;  
input wire signed [7:0] ifft_I;
input wire signed [7:0] ifft_Q;                  


//Variable and parameters declaration
//**************************************************************

wire cBLANK_n;
wire cHS;
wire cVS;  //use them in your code instead of using the output ports, at the end they will be assigned them to the corresponding output ports
wire  [15:0]signal;
// Variables for VGA Clock 
reg vga_clk_reg;                   
wire iVGA_CLK;

//Variables for (x,y) coordinates VGA
wire [10:0] CX;
wire [9:0] CY;

//Oscilloscope parameters
	//Horizontal
	parameter DivX=10.0;  			// number of horizontal division
	parameter Ttotal=0.000025;   		// total time represented in the screen
	parameter pixelsH=640.0;  		// number of horizontal pixels
	parameter IncPixX=Ttotal/(pixelsH-1.0);			// time between two consecutive pixels
	//Amplitude
	parameter DivY=8.0;  			// number of vertical divisions
	parameter Atotal=8.0;			// total volts represented in the screen
	parameter pixelsV=480.0;  		// number of vertical pixels	
	parameter IncPixY=Atotal/(pixelsV-1.0);	// volts between two consecutive pixels

// Sinusoidal wave amplitude (Section 6)
parameter Amp=3.0;				// maximum amplitude of sinusoidal wave [-Amp, Amp]
parameter integer Apixels=Amp/IncPixY;		// number of pixels to represent the maximum amplitude	

//Vector to store the input signal (Section 6.1)
parameter nc = 1;	//9				
reg [15:0] capturedVals[((nc*8)-1):0]; //256		// vector with values of input signal
integer i;					// index of the vector

//Read the signal values from the vector (Section 6.2)
integer j; 					// read the correct element of the vector
parameter integer nf=2; 			//Vector points between two consecutive pixels 

//Value of the current pixel (Section 6.2 and 6.3)
reg [9:0] ValforVGA; 
reg [9:0] oldValforVGA; 

//BPSK Parameters

integer cf;
integer cf_count;
integer mov = ((nc*8)-1-2);//256

always@(negedge cVS)
begin
if(SW0)
begin
if (cf_count==cf)
	begin
	cf_count<= 0;
	end
else
	begin
	cf_count<=cf_count+1;
	end
if (mov<0)
	begin
	mov<= ((nc*8)-1-2);//256
	end
else
	begin
	mov<= mov - 2;
	end
end
end
// Code starts here
//*******************************************************************
always@(negedge iVGA_CLK)
 begin
//Update the value of oldValforVGA
//Display the Coordinate Y of the current Coordinate X
oldValforVGA<=ValforVGA;

if (CY==ValforVGA)
	begin
	g_data<=8'hFF;
	end
	if ((CY==ValforVGA-10)&&(CY==ValforVGA+10))
	begin
	g_data<=8'hFF;
	end
//Connect points with vertical lines (old value of Y < current value of Y)
else if ( (CY<oldValforVGA) && (CY>ValforVGA) )
	begin
	g_data<=8'hFF;
	end
//connect points with vertical lines (old value of Y> current value of Y)
else if ( (CY>oldValforVGA) && (CY<ValforVGA) )
	begin
	g_data<=8'hFF;
	end
//display the vertical guide lines
else if (CX==63||CX==127||CX==191||CX==255||CX==319||CX==383||CX==447||CX==511||CX==575||CX==639)
	begin
		b_data<=8'hFF;
		g_data<=8'hFF;
		r_data<=8'hFF;
	end
//display the horizontal guide lines
else if (CY==59||CY==119||CY==179||CY==239||CY==299||CY==359||CY==419||CY==479)
	begin
      b_data<=8'hFF;
		g_data<=8'hFF;
		r_data<=8'hFF;
	end
//Everything else is black
else
	begin
		b_data<=8'h00;
		g_data<=8'h00;
		r_data<=8'h00;
	end
 end
 
// 25 MHz clock for the VGA clock

always @(posedge CLOCK_50)
begin
	vga_clk_reg =~vga_clk_reg;
end	
assign iVGA_CLK = vga_clk_reg;

assign oVGA_CLK = ~iVGA_CLK;


// instance VGA controller

VGA_Controller VGA_ins
(
.vga_clk(iVGA_CLK),
.reset(1'b0),
.BLANK_n(cBLANK_n),
.HS(cHS),
.VS(cVS),
.CoorX(CX),
.CoorY(CY)
);
						

// Store input signal in a vector (Section 6.1)			

always@(negedge CLOCK_50)
begin
      if (i==((nc*8)-1))//256
			begin
			i<= 0;
			end
		else
			begin
			i<= i+1;
			end
		capturedVals[i]<= ifft_I;
end


// Read the correct point of the signal stored in the vector and calculate the pixel associated given the amplitude and the parameters of the oscilloscope (Section 6.2)

always@(negedge iVGA_CLK)
begin
	if(cBLANK_n==1'b1)
		begin
		if (j>((nc*8)-1-2))//256
			begin
			j<= 0;
			end
		else
			begin
			j<=j+2;
			end
		end
	else
		begin
			j<=mov;
		end
	ValforVGA <= (239 + Apixels) - ((2*Apixels*capturedVals[j])>>8) ;//16
end
					

// Calculate the RGB values

/*
always@(negedge iVGA_CLK)
begin 
	//display the vertical guide lines
	if(CX==63||CX==127||CX==191||CX==255||CX==319||CX==383||CX==447||CX==511||CX==575||CX==639)
		begin
		b_data=8'hFF;
		g_data=8'hFF;
		r_data=8'hFF;
		end
	//display the horizontal guide lines
	else if(CY==59||CY==119||CY==179||CY==239||CY==299||CY==359||CY==419||CY==479)
		begin
      b_data=8'hFF;
		g_data=8'hFF;
		r_data=8'hFF;
		end
	//Everything else is black
	else 
		begin
		b_data=8'h00;
		g_data=8'h00;
		r_data=8'h00;
	
		end
end
*/

//Assign the internal signals to the output ports

reg [4:0] delay_bus;
reg [4:0] delay_busv;
reg [4:0] delay_bush;

always@(posedge iVGA_CLK)
begin

	delay_bus <= {delay_bus[3:0],cBLANK_n};
	delay_bush <= {delay_bush[3:0],cHS};
	delay_busv <= {delay_busv[3:0],cVS};

end

assign oBLANK_n = delay_bus[1];
assign oHS = delay_bush[1];
assign oVS = delay_busv[1];


endmodule
