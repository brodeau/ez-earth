#!/bin/bash

#NBCORES=4 ; QUEUE="snic2014-10-3" ; TIME="00:30:00"
#NBCORES=8 ; QUEUE="snic2014-10-3" ; TIME="99:00:00"
NBCORES=4 ; QUEUE="snic2014-10-3" ; TIME="167:59:00"

#CONF1=O2t0 ; CONF2=080 ; CNAME="T159-ORCA2"
#CONF1=O1t0 ; CONF2=080 ; CNAME="T159-ORCA1"
#CONF1=O1t0 ; CONF2=128 ; CNAME="T255-ORCA1"
#CONF1=Ot25 ; CONF2=256 ; CNAME="T511-ORCA025"
#CONF1=O12t ; CONF2=128 ; CNAME="T255-ORCA12"
#CONF1=O12t ; CONF2=256 ; CNAME="T511-ORCA12"

CONF1=O12t ; CONF2=640 ; CNAME="T1279-ORCA12"

CC=A${CONF2}-${CONF1}
export TMP_DIR=/proj/bolinc/users/x_laubr/tmp/OASIS_WEIGHTS/${CC}_ifs_to_nemo

## - Name of the executables
DIR_EXE=/home/x_laubr/DEV/oasis3-mct/examples/lolo

exe1=model1_rcv_only
exe2=model2_snd_only

nproc_exe1=1
nproc_exe2=1

DIR_GRIDS=/proj/bolinc/users/x_laubr/brodeau_ece32_setup/oasis/${CNAME}

GRID_GRIDS=${DIR_GRIDS}/grids.nc
GRID_MASKS=${DIR_GRIDS}/masks.nc
#RST_MODEL1=${DIR_GRIDS}/rst/rstos.nc
RST_MODEL2=${DIR_GRIDS}/rst/rstas.nc

echo ''
echo '*****************************************************************'
echo '*** '$casename' : '$run
echo ''
echo $exe1' runs on '$nproc_exe1 'processes'
echo $exe2' runs on '$nproc_exe2 'processes'
echo ''
echo ''
######################################################################


#rm -rf ${TMP_DIR} ;
mkdir -p ${TMP_DIR}

# Copying nc files!
for ff in ${GRID_MODEL1} ${GRID_MODEL2} ${RST_MODEL2} ${GRID_GRIDS} ${GRID_MASKS} ; do
    rsync -avP ${ff} ${TMP_DIR}/
done

# Copying exexutables:
for fe in ${exe1} ${exe2}; do
    rsync -avP ${DIR_EXE}/${fe} ${TMP_DIR}/
done


cd ${TMP_DIR}/

FR2=`basename ${RST_MODEL2}` ; echo "${FR2} !"
    #
if [ ! -f ./fdatm.nc ]; then
    ncks -O -v A_Qs_oce ${FR2} -o fdatm.nc
    ncrename -v A_Qs_oce,FSENDATM fdatm.nc
fi
rm -f ${FR2}



cat > namcouple <<EOF
 \$NFIELDS
    1
 \$END
# -------------------------------------------------------------------------------------------------
 \$RUNTIME
     21600
 \$END
# -------------------------------------------------------------------------------------------------
 \$NLOGPRT
    10
 \$END
# -------------------------------------------------------------------------------------------------
 \$STRINGS
# =================================================================================================
#  Field 1: model2 to model1 => T255 to orca1
# =================================================================================================
   FSENDATM FRECVOCN  1 10800  1  fdatm.nc EXPOUT
   A${CONF2} ${CONF1} LAG=2700
   P  0  P  2
   SCRIPR
   GAUSWGT D SCALAR LATITUDE 1 9 2.0
#
#
 \$END
EOF



fscript=job.sub

cat > ${fscript} <<EOF
#!/bin/bash
#
#SBATCH -A ${QUEUE}
#SBATCH -N 1
#SBATCH -n ${NBCORES}
#SBATCH -J ${CC}
#SBATCH -t ${TIME}
#SBATCH -o out_OASIS_${CC}_%J.out 
#SBATCH -e err_OASIS_${CC}_%J.err 
#
#
###module rm intel/16.0.0
###module load intel/2017.0.098
#
###export LD_LIBRARY_PATH=${MPI_HOME}/lib64:/apps/NETCDF/4.3.2/INTEL/IMPI/lib:${LD_LIBRARY_PATH}
#
cd ${TMP_DIR}/
#
ulimit -s unlimited
#
echo "mpirun -np ${nproc_exe1} ./${exe1} : -np ${nproc_exe2} ./${exe2}"
#
mpirun -np ${nproc_exe1} ./${exe1} : -np ${nproc_exe2} ./${exe2}
#
EOF

chmod +x ${fscript}


cat > name_grids.dat <<EOF
\$grid_source_characteristics
cl_grd_src='${CONF1}'
\$end
\$grid_target_characteristics
cl_grd_tgt='A${CONF2}'
\$end
EOF


sbatch ./${fscript}


echo  "Check into: ${TMP_DIR}/ "
