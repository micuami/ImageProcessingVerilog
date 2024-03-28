`timescale 1ns / 1ps

module process(
	input clk,				// clock 
	input [23:0] in_pix,	// valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
	output reg [5:0] row, col, 	// selecteaza un rand si o coloana din imagine
	output reg out_we, 			// activeaza scrierea pentru imaginea de iesire (write enable)
	output reg [23:0] out_pix,	// valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
	output reg mirror_done,		// semnaleaza terminarea actiunii de oglindire (activ pe 1)
	output reg gray_done,		// semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
	output reg filter_done);	// semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)

// TODO add your finite state machines here
reg [5:0] state, next_state = 0;
reg [5:0] next_row, next_col = 0;
reg [23:0] pixel_aux1, pixel_aux2 = 0; //in ele pastrez valorile pixelilor pentru oglindire
reg [7:0] r, g, b; //in ele extrag culorile din fiecare in_pix
reg [12:0] old_pix, new_pix = 0; //in ele calculez noul pixel la sharpen

`define MIRROR 0
`define GRAY 7
`define SHARP 10

//partea secventiala
	 always @(posedge clk) begin
		state <= next_state;
		col <= next_col;
		row <= next_row;
		old_pix <= new_pix;
	 end

//partea combinationala
	 always @(*) begin
			 case(state)
					 `MIRROR: begin //incep mirror cu initializarile sale
						next_row = 0;
						next_col = 0;
						mirror_done = 0;
						out_we = 0;
						next_state = `MIRROR + 1;
					 end
					 `MIRROR + 1: begin //selectez pixelul curent si il pastrez in variabila auxiliara 1
						pixel_aux1 = in_pix;
						next_state = `MIRROR + 2;
					 end
					 `MIRROR + 2: begin
						if(row < 32) begin //pentru pixelii din jumatatea superioara a matricei aleg oglinditul
							next_row = 63 - row;
							next_state = `MIRROR + 3;
						end
						else begin //daca am trecut de jumatate inseamna ca am terminat de aplicat mirror
							mirror_done = 1;
							next_state = `GRAY;
						end
					 end
					 `MIRROR + 3: begin //selectez pixelul curent si il pastrez in variabila auxiliara 2
						out_we = 1;
						pixel_aux2 = in_pix;
						out_pix = pixel_aux1; //pe cel din variabila auxiliara 1 il pun pe iesire
						next_state = `MIRROR + 4;
					 end
					 `MIRROR + 4: begin //ma intorc inapoi in pixelul din care am plecat
						out_we = 0;
						next_row = 63 - row;
						next_state = `MIRROR + 5;
					 end
					 `MIRROR + 5: begin //pun ce am in variabila auxiliara 2 pe iesire
						out_we = 1;
						out_pix = pixel_aux2;
						next_state = `MIRROR + 6;
					 end
					 `MIRROR + 6: begin //trec la urmatorul pixel si repet procedura
					   out_we = 0;
						if(col < 63) begin
							next_col = col + 1;
						end
						else begin
							next_row = row + 1;
							next_col = 0;
						end
						next_state = `MIRROR + 1;
					 end
					 `GRAY: begin //incep grayscale cu initializarile sale
						next_row = 0;
						next_col = 0;
						gray_done = 0;
						out_we = 0;
						next_state = `GRAY + 1;
					 end
					 `GRAY + 1: begin //aplic grayscale punand noua valoare in out_pix[15:8] (la jumatate)
						b = in_pix[7:0];
						g = in_pix[15:8];
						r = in_pix[23:16];
						out_pix = 0;
						if((b <= g && g <= r) || (r <= g && g <= b))
							out_pix[15:8] = (r + b)/2;
						if((g <= r && r <= b) || (b <= r && r <= g))
							out_pix[15:8] = (g + b)/2;
						if((r <= b && b <= g) || (g <= b && b <= r))
							out_pix[15:8] = (r + g)/2;
						out_we = 1;
						next_state = `GRAY + 2;
					 end
					 `GRAY + 2: begin //trec la urmatorul pixel si repet procedura
						out_we = 0;
						if(row == 63 && col == 63) begin
							gray_done = 1;
							next_state = 10;
						end
						else begin
							if (row < 63) begin
								if (col < 63) 
									next_col = col + 1;
								else begin
									next_row = row + 1;
									next_col = 0;
								end
							end
							else next_col = col + 1;
							next_state = `GRAY + 1;
						end
					end
					
/*

Fie o matrice 3x3 pentru care notam pozitiile elementelor de la 1 la 9 astfel:

1 2 3
4 5 6
7 8 9

Pixelul de pe pozitia 5 este cel pe care il prelucram la un moment de timp.
De exemplu, daca pixelul curent este pe pozitia (0,0) atunci vecinii lui vor fi pe pozitiile 8, 9 si 6.
Voi parcurge vecinii pixelului in sens trigonometric (3, 2, 1, 4, 7, 8, 9, 6)

*/
					
					`SHARP: begin //incep sharpness cu initializarile sale
						next_row = 0;
						next_col = 0;
						filter_done = 0;
						out_we = 0;
						next_state = `SHARP + 1;
					end
					`SHARP + 1: begin //prelucrez pixelul din mijloc si apoi verific pe ce linie ma aflu
						new_pix = in_pix[15:8] * 9;
						if(row == 0) next_state = `SHARP + 2;
						else if(row == 63) next_state = `SHARP + 14;
						else next_state = `SHARP + 10;
					end
					`SHARP + 2: begin //linia este 0 si verific pe ce coloana ma aflu
						if(col == 0) begin
							next_row = row + 1;
							next_state = `SHARP + 3; //ma duc pe pozitia 8
						end
						else begin
							next_col = col - 1; 
							next_state = `SHARP + 8; //ma duc pe pozitia 4
						end
					end
					`SHARP + 3: begin //ma aflu pe pozitia 8
						new_pix = old_pix - in_pix[15:8];
						if (col == 63) begin
							next_row = row - 1;
							next_state = `SHARP + 6; //ma duc pe pozitia 5 (ma intorc de unde am plecat)
						end
						else begin
							next_col = col + 1;
							next_state = `SHARP + 4; //ma duc pe pozitia 9
						end
					end
					`SHARP + 4: begin //ma aflu pe pozitia 9
						next_row = row - 1;
						new_pix = old_pix - in_pix[15:8];
						next_state = `SHARP + 5; //ma duc pe pozitia 6
					end
					`SHARP + 5: begin //ma aflu pe pozitia 6
						new_pix = old_pix - in_pix[15:8];
						if (row == 0) begin
							next_col = col - 1;
							next_state = `SHARP + 6; //ma duc pe pozitia 5 (ma intorc de unde am plecat)
						end
						else if (row == 63) begin
							next_row = row - 1; //ma duc pe pozitia 3
							next_state = `SHARP + 11;
						end
						else if (row > 0 && col == 1) begin
							next_row = row - 1; //ma duc pe pozitia 3
							next_state = `SHARP + 11;
						end
						else begin
							next_col = col - 1;
							next_state = `SHARP + 6; //ma duc pe pozitia 5 (ma intorc de unde am plecat)
						end
					end
					`SHARP + 6: begin //ma aflu pe pozitia 5 (revin de unde am plecat)
						if (old_pix > 255) new_pix = 255;
						if (old_pix < 0) new_pix = 0;
						next_state = `SHARP + 17;
					end
					`SHARP + 7: begin //trec la urmatorul pixel
						out_we = 0;
						new_pix = 0;
						if(row == 63 && col == 63) begin
							next_row = 0;
							next_col = 0;
							next_state = `SHARP + 15;
						end
						else begin
							if (row < 63) begin
								if (col < 63) 
									next_col = col + 1;
								else begin
									next_row = row + 1;
									next_col = 0;
								end
							end
							else next_col = col + 1;
							next_state = `SHARP + 1;
						end
					end
					`SHARP + 8: begin //ma aflu pe pozitia 4
						new_pix = old_pix - in_pix[15:8];
						if (row == 63) begin
							next_col = col + 1;
							next_state = `SHARP + 6; //ma duc in pe pozitia 5 (ma intorc de unde am plecat)
						end
						else begin
							next_row = row + 1;
							next_state = `SHARP + 9; //ma duc pe pozitia 7
						end
					end
					`SHARP + 9: begin //ma aflu pe pozitia 7
						next_col = col + 1; 
						new_pix = old_pix - in_pix[15:8];
						next_state = `SHARP + 3; //ma duc pe pozitia 8
					end
					`SHARP + 10: begin //linia este de mijloc si verific pe ce coloana ma aflu
						if(col == 0) begin
							next_row = row + 1;
							next_state = `SHARP + 3; //ma duc pe pozitia 8
						end
						else if(col == 63) begin
							next_row = row - 1;
							next_state = `SHARP + 12; //ma duc pe pozitia 2
						end
						else begin
							next_row = row - 1; 
							next_col = col + 1;
							next_state = `SHARP + 11; //ma duc pe pozitia 3
						end
					end
					`SHARP + 11: begin //ma aflu pe pozitia 3
						next_col = col - 1;
						new_pix = old_pix - in_pix[15:8];
						next_state = `SHARP + 12; //ma duc pe pozitia 2
					end
					`SHARP + 12: begin //ma aflu pe pozitia 2
						new_pix = old_pix - in_pix[15:8];
						if (col == 0) begin
							next_row = row + 1;
							next_state = `SHARP + 6; //ma duc pe pozitia 5 (ma intorc de unde am plecat)
						end
						else begin
							next_col = col - 1;
							next_state = `SHARP + 13; //ma duc pe pozitia 1
						end
					end
					`SHARP + 13: begin //ma aflu pe pozitia 1
						next_row = row + 1;
						new_pix = old_pix - in_pix[15:8];
						next_state = `SHARP + 8; //ma duc pe pozitia 4
					end
					`SHARP + 14: begin //linia este 63 si verific pe ce coloana ma aflu
						if(col == 0) begin
							next_col = col + 1;
							next_state = `SHARP + 5; //ma duc pe pozitia 6
						end
						else if(col == 63) begin
							next_row = row - 1;
							next_state = `SHARP + 12; //ma duc pe pozitia 2
						end
						else begin
							next_col = col + 1;
							next_state = `SHARP + 5; //ma duc pe pozitia 6
						end
					end
					`SHARP + 15: begin //las doar partea filtrata in pixel si o mut pe mijloc
						out_pix[15:8] = in_pix[7:0];
						out_pix[7:0] = 0;
						next_state = `SHARP + 16;
						out_we = 1;
					end
					`SHARP + 16: begin //trec la urmatorul pixel
						out_we = 0;
						if(row == 63 && col == 63) begin
							filter_done = 1;
							next_state = 0;
						end
						else begin
							if (row < 63) begin
								if (col < 63) 
									next_col = col + 1;
								else begin
									next_row = row + 1;
									next_col = 0;
								end
							end
							else next_col = col + 1;
							next_state = `SHARP + 15;
						end
					end
					`SHARP + 17: begin //pun pixelul pe iesire dupa ce am verificat daca e numar pozitiv pe 8 biti
						out_pix[7:0] = old_pix;
						out_we = 1;
						next_state = `SHARP + 7;
					end
			 endcase
	 end
	 
endmodule
