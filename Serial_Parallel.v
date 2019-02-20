module Serial_parallel(
CLOCK_50,
I_Signal,
Q_Signal,
);

input CLOCK_50;
output I_Signal;
output Q_Signal;

reg [15:0] data=16'b1011010000011110;
reg signed [1:0] I_Signal;
reg signed [1:0] Q_Signal;
//reg [3:0] bit_ctl = 4'd0;//counting the position of the bits in the input data stream

integer bit_ctl = 0;
integer nxt_bit = 0;

always@(posedge CLOCK_50)
begin
if(bit_ctl<16)
	begin
	nxt_bit = bit_ctl+1;
	
	if(data[bit_ctl] == 1'b1 && data[nxt_bit]==1'b1)
		begin
		I_Signal<=-1;
		Q_Signal<=-1;
		end
	if(data[bit_ctl] == 1'b1 && data[nxt_bit]==1'b0)
		begin
		I_Signal<=1;
		Q_Signal<=-1;
		end
	if(data[bit_ctl] == 1'b0 && data[nxt_bit]==1'b0)
		begin
		I_Signal<=1;
		Q_Signal<=1;
		end
	if(data[bit_ctl] == 1'b0 && data[nxt_bit]==1'b1)
		begin
		I_Signal<=-1;
		Q_Signal<=1;
		end
	//bit_ctl<=bit_ctl+2;
	end
else
	begin
	bit_ctl<=4'b0;
	end
bit_ctl<=bit_ctl+2;
end

endmodule
