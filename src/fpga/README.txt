README.txt	ajm					23-jun-2015
------------------------------------------------------------------------------

Makefile	-non graphical compilation and programming
cDisp14x6.vhd	-display controller FSM
cDispPkg.vhd	-component: cDisp14x6, pllClk	type: cmdTy
		 => for external use
		 components and types used in cDisp14x6

de0Board.vhd	-sample design on how to use: cDisp14x6
de0Board.qpf	-files for Altera Quartus
de0Board.qsf	-
de0Board.sdc	-

pll/		-pll to generate 2MHz clocks from 50MHz input on DE0-board
		 must be used within de0Board.vhd, see example
rom/		-character ROM for cDisp14x6
		 internally used in cDisp14x6
doc/		-additional datasheets: DE0-board, PCD8544, etc.
misc/		-temporary design files, samples etc.

------------------------------------------------------------------------------
README.txt - end
