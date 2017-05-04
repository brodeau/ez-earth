#
O3DIR = /home/x_laubr/DEV/oasis3-mct
include $(O3DIR)/util/make_dir/make.inc
#
LIBPSMILE = $(ARCHDIR)/lib/libpsmile.${CHAN}.a $(ARCHDIR)/lib/libmct.a $(ARCHDIR)/lib/libmpeu.a $(ARCHDIR)/lib/libscrip.a
#
##### User configurable options #####
#
# CPP keys for model 1 (_M1) and for model 2 (_M2)
# type of decomposition :
# DECOMP_APPLE for 1D decomposition
# DECOMP_BOX for 2D decomposition
CPPKEYDECOMP_M1=DECOMP_APPLE
CPPKEYDECOMP_M2=DECOMP_APPLE
#
# Precision for REAL: USE_DOUBLE_PRECISION or NO_USE_DOUBLE_PRECISION
# Management of the precision of the example
CPPKEYDP=USE_DOUBLE_PRECISION
CPPLOCAL_M1 = -D${CPPKEYDP} -D${CPPKEYDECOMP_M1}
CPPLOCAL_M2 = -D${CPPKEYDP} -D${CPPKEYDECOMP_M2}
#
### End User configurable options ###
#
OBJ_M1 =  routine_hdlerr.o read_all_data.o \
          decomp_def.o \
          function_ana.o write_all_fields.o \
          function_sent.o
OBJ_M2 =  routine_hdlerr.o read_all_data.o \
          decomp_def_m2.o \
          function_ana.o  write_all_fields.o \
          function_sent.o
#-------------------------------------------------------------------------------
# General rules
#-------------------------------------------------------------------------------
#
default: all
#
all: oasis3_psmile model1_rcv_only model2_snd_only model1_snd_only model2_rcv_only
#
# Compile and link libaries
oasis3_psmile:
	(cd $(O3DIR)/util/make_dir ; $(MAKE) oasis3_psmile -f TopMakefileOasis3)
#
#
#-------------------------------------------------------------------------------
# Rules for executables
#-------------------------------------------------------------------------------
#
model1_rcv_only: $(OBJ_M1) model1_rcv_only.o $(LIBPSMILE) Makefile
	$(LD) $(LDFLAGS) -o $@ $(OBJ_M1) model1_rcv_only.o $(LIBPSMILE) $(FLIBS)
model2_snd_only: $(OBJ_M2) model2_snd_only.o $(LIBPSMILE) Makefile
	$(LD) $(LDFLAGS) -o $@ $(OBJ_M2) model2_snd_only.o $(LIBPSMILE) $(FLIBS)

model1_snd_only: $(OBJ_M1) model1_snd_only.o $(LIBPSMILE) Makefile
	$(LD) $(LDFLAGS) -o $@ $(OBJ_M1) model1_snd_only.o $(LIBPSMILE) $(FLIBS)
model2_rcv_only: $(OBJ_M2) model2_rcv_only.o $(LIBPSMILE) Makefile
	$(LD) $(LDFLAGS) -o $@ $(OBJ_M2) model2_rcv_only.o $(LIBPSMILE) $(FLIBS)


#
#-------------------------------------------------------------------------------
# Rules for compilation
#-------------------------------------------------------------------------------
#
routine_hdlerr.o :		routine_hdlerr.F90
				$(F90) $(F90FLAGS) -c routine_hdlerr.F90
read_all_data.o :		read_all_data.F90
				$(F90) $(F90FLAGS) -D${CPPKEYDP} -c read_all_data.F90
write_all_fields.o :		write_all_fields.F90
				$(F90) $(F90FLAGS) -D${CPPKEYDP} -c write_all_fields.F90
function_ana.o :		function_ana.F90
				$(F90) $(F90FLAGS) -D${CPPKEYDP} -c function_ana.F90
decomp_def.o : 			decomp_def.F90
				$(F90) $(F90FLAGS) $(CPPLOCAL_M1) -c decomp_def.F90
function_sent.o : 		function_sent.F90
				$(F90) $(F90FLAGS) $(CPPLOCAL_M1) -c function_sent.F90
decomp_def_m2.o : 		decomp_def.F90
				$(F90) $(F90FLAGS) $(CPPLOCAL_M2) -o decomp_def_m2.o -c decomp_def.F90
function_sent_m2.o : 		function_sent.F90
				$(F90) $(F90FLAGS) $(CPPLOCAL_M2) -o function_sent_m2.o -c function_sent.F90

model1_rcv_only.o :	model1_rcv_only.F90 Makefile
		$(F90) $(F90FLAGS) $(CPPLOCAL_M1) -c model1_rcv_only.F90
model2_snd_only.o :	model2_snd_only.F90 Makefile
		$(F90) $(F90FLAGS) $(CPPLOCAL_M2) -c model2_snd_only.F90

model1_snd_only.o :	model1_snd_only.F90 Makefile
		$(F90) $(F90FLAGS) $(CPPLOCAL_M1) -c model1_snd_only.F90
model2_rcv_only.o :	model2_rcv_only.F90 Makefile
		$(F90) $(F90FLAGS) $(CPPLOCAL_M2) -c model2_rcv_only.F90


#
#-------------------------------------------------------------------------------
# Utilities
#-------------------------------------------------------------------------------
#
help:
	more Make.help
#
# Clean directory
#
clean:
	-rm -f *.o *.mod *.MOD model1_rcv_only model2_snd_only model1_snd_only model2_rcv_only
	-rm -f i.*.F90 *.L
	-rm -f core core.* 
#
# Make sure to recompile everything
#
realclean: clean remove
remove:
	(cd $(O3DIR)/util/make_dir ; $(MAKE) realclean -f TopMakefileOasis3)
