# Makefile for de0Board		ajm	01-jan-2010
#
#	-prototyping designs	-- without Nios2 processor	--------------
#	-add project related files to PROJ_SRC:
#	 	vhdl-sources, wizard generated files ...
#-----------------------------------------------------------------------------
PROJECT		= de0Board
PROJ_SRC	= cDisp14x6.vhd cDispPkg.vhd pll rom
DOC_SRC		= doc README.txt arduino misc
SRC_FILES	= de0Board.qsf de0Board.qpf de0Board.vhd de0Board.sdc 

QUARTUS		= quartus_sh
COMPILE		= --flow compile
PROG		= quartus_pgm
PROG_ARG	= -c USB-Blaster -m JTAG -o p\;

E		= echo \\\# `date +%Y.%m.%d\ %H:%M:%S`:
#-----------------------------------------------------------------------------

default : synthesis

%.sof : %.vhd
	@$(E) $* -- RTL synthesis
	@$(QUARTUS) $(COMPILE) $*.qpf

synthesis : $(PROJECT).sof

program : $(PROJECT).sof
	@$(E) $(PROJECT) -- programming
	@$(PROG) $(PROG_ARG)$(PROJECT).sof

all : synthesis program

clean :
	-@mkdir +++
	-@rm -r work/* work/.[A-Z,a-z]*				>/dev/null 2>&1
	-@mv Makefile README* $(SRC_FILES) $(PROJ_SRC) $(DOC_SRC) +++	\
								>/dev/null 2>&1
	-@rm -r .[A-Z,a-z]* [A-Z,a-z]*				>/dev/null 2>&1
	-@mv +++/* .						>/dev/null 2>&1
	-@rm -r +++

#-----------------------------------------------------------------------------
help:
	@echo
	@echo "available targets:  synthesis -- Quartus synthesis: $(PROJECT)"
	@echo "                    program   -- board programming"
	@echo "                    clean     -- remove (most) generated files"
	@echo
	@echo "                    all       -> synthesis+program"
	@echo "                    default   -> synthesis"
	@echo
