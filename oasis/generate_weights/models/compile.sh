#module rm intel/16.0.0
#module load intel/2017.0.098

ifort -V

sleep 1

#make clean

make

##make BUILD_ARCH=ecconf -f TopMakefileOasis3
