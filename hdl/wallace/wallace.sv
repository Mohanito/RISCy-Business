// Wallace Tree Multiplier
module wallace
#(parameter width = 32)
(
  input logic [(width-1):0] a,
  input logic [(width-1):0] b,
  output logic [(2*width-1):0] product
);

// Partial Products [row#][bit#]
logic [(width-1):0][(width*2-1):0] p;

// initialize 32 * 64-bit lines
always_comb begin
  for(int i = 0; i < width; i++)    // pick the i-th bit from b
    for(int j = 0; j < width; j++)  // AND it with all 32 bits in a
	   p[i][j + i] = a[j] & b[i];
end
/* an example of 4 * 4partial product
     XXXX1001
	  XXX0000X		p[X][width - 1] will be 0 for now
	  XX0000XX
	  X1001XXX
*/
logic [(2*width-1):0] f1, f2;
wallace_reduction wr(.p(p), .f1(f1), .f2(f2));

assign product = f1 + f2;

endmodule: wallace







/*
10 * (group of 3 rows) + (group of 2 rows) 
=> 22 rows after reduction => 7 * (group of 3 rows) + (group of 1 row) 
=> 15 rows after reduction => 5 * (group of 3 rows)
=> 10 rows after reduction => 3 * (group of 3 rows) + (group of 1 row) 
=> 7 rows after reduction => 2 * (group of 3 rows) + (group of 1 row) 
=> 5 rows after reduction => 1 * (group of 3 rows) + (group of 2 rows) 
=> 4 rows after reduction => 1 * (group of 3 rows) + (group of 1 row) 
=> 3 rows after reduction => 1 * (group of 3 rows)
=> 2 rows after reduction => Final addition! (64-bit Carry Propagate Adder)
*/

/*
	1st stage:
	     00000000000000000000000000000000
	    10001000100010001000100010001000
	   10001000100010001000100010001000
		
		X100.........................1000X
		00000000000000000000000000000000
		
	  00000000000000000000000000000000
	 10001000100010001000100010001000
	10001000100010001000100010001000
	2 direct assign, 2 half adders, 30 full adders - repeat 10 times.
*/

/*
	End of 1st stage: pp2[22rows][32bits]
	10 * 32-bit partial product, 10 * 32-bit carry array, 2 * 32-bit unused arrays
	  00000000000000000000000000000000		 10001000100010001000100010001000 sum
	 10001000100010001000100010001000	-> 10001000100010001000100010001000  carry
	10001000100010001000100010001000
	
  00000000000000000000000000000000		 10001000100010001000100010001000 sum
 10001000100010001000100010001000	-> 10001000100010001000100010001000  carry
10001000100010001000100010001000
*/

/*
	2nd stage:
	2 direct assign, 2 half adders, 30 full adders - repeat 7 times.
*/
// Group 1: row 0-2
// Group 2: row 3-5
// Group 3: row 6-8
// Group 4: row 9-11
// Group 5: row 12-14
// Group 6: row 15-17
// Group 7: row 18-20
// Group 8: row 21

/*
	End of 2nd stage: pp3[15rows][32bits]
	7 * 32-bit partial product, 7 * 32-bit carry array, 1 * 32-bit unused arrays
*/

/*
	3rd stage:
	2 direct assign, 2 half adders, 30 full adders - repeat 5 times.
*/
// Group 1: row 0-2
// Group 2: row 3-5
// Group 3: row 6-8
// Group 4: row 9-11
// Group 5: row 12-14

/*
	End of 3rd stage: pp4[10rows][32bits]
	5 * 32-bit partial product, 5 * 32-bit carry array, 0 * 32-bit unused arrays
*/

/*
	4th stage:
	2 direct assign, 2 half adders, 30 full adders - repeat 3 times.
*/
// Group 1: row 0-2
// Group 2: row 3-5
// Group 3: row 6-8
// Group 4: row 9

/*
	End of 4th stage: pp5[7rows][32bits]
	3 * 32-bit partial product, 3 * 32-bit carry array, 1 * 32-bit unused arrays
*/

/*
	5th stage:
	2 direct assign, 2 half adders, 30 full adders - repeat 2 times.
*/
// Group 1: row 0-2
// Group 2: row 3-5
// Group 3: row 6

/*
	End of 5th stage: pp6[5rows][32bits]
	2 * 32-bit partial product, 2 * 32-bit carry array, 1 * 32-bit unused arrays
*/

/*
	6th stage:
	2 direct assign, 2 half adders, 30 full adders - repeat 1 times.
*/
// Group 1: row 0-2
// Group 2: row 3-4

/*
	End of 6th stage: pp7[4rows][32bits]
	1 * 32-bit partial product, 1 * 32-bit carry array, 2 * 32-bit unused arrays
*/

/*
	7th stage:
	2 direct assign, 2 half adders, 30 full adders - repeat 1 times.
*/
// Group 1: row 0-2
// Group 2: row 3

/*
	End of 7th stage: pp8[3rows][32bits]
	1 * 32-bit partial product, 1 * 32-bit carry array, 1 * 32-bit unused arrays
*/

/*
	8th stage:
	2 direct assign, 2 half adders, 30 full adders - repeat 1 times.
*/
// Group 1: row 0-2

/*
	End of 8th stage: pp9[2rows][32bits] RENAME
	1 * 32-bit partial product, 1 * 32-bit carry array
*/

// Final Stage:
// use 64-bit CLA to add the final results together


