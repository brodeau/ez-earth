#!/bin/bash

NFIELDS=1 ; # grid t,u,v of NEMO...
LAG=0
CPL_PERIOD=60

QUEUE="snic2014-10-3" ; TIME="00:30:00"
CONF1=O1 ; CONF2=RnfO ; CNAME="T159-ORCA1" ; NE="0"



#CONF1=O2t0 ; CONF2=080 ; CNAME="T159-ORCA2"
#CONF1=Ot25 ; CONF2=256 ; CNAME="T511-ORCA025"
#CONF1=O12t ; CONF2=128 ; CNAME="T255-ORCA12"
#CONF1=O12t ; CONF2=256 ; CNAME="T511-ORCA12"
#CONF1=O12t ; CONF2=640 ; CNAME="T1279-ORCA12"


## - Name of the executables
# Directories where the executables contained into "ez-earth/oasis/generate_weights/models/"
# have been compiled (generally in the original oasis3-mct/examples of official OASIS....
DIR_EXE="`pwd`/models"

exe1=model1_rcv_only
exe2=model2_snd_only

nproc_exe1=${NFIELDS}
nproc_exe2=${NFIELDS}

NBCORES=$((${nproc_exe1}+${nproc_exe2}))


DIR_GRIDS=/proj/bolinc/users/x_laubr/brodeau_ece32_setup/oasis/${CNAME}

GRID_AREAS=${DIR_GRIDS}/areas.nc
GRID_GRIDS=${DIR_GRIDS}/grids.nc
GRID_MASKS=${DIR_GRIDS}/masks.nc
RST_MODEL2=${DIR_GRIDS}/rst/rstrn.nc

echo ''
echo '*****************************************************************'
echo '*** '$casename' : '$run
echo ''
echo $exe1' runs on '$nproc_exe1 'processes'
echo $exe2' runs on '$nproc_exe2 'processes'
echo ''
echo ''
######################################################################



    CC=${CONF2}-${CONF1}t${NE}

    export TMP_DIR=/proj/bolinc/users/x_laubr/tmp/OASIS_WEIGHTS/${CC}_ifs_to_nemo
    mkdir -p ${TMP_DIR}

# Copying nc files!
    for ff in ${GRID_MODEL1} ${GRID_MODEL2} ${RST_MODEL2} ${GRID_AREAS} ${GRID_GRIDS} ${GRID_MASKS} ; do
        rsync -L -avP ${ff} ${TMP_DIR}/
    done

# Copying exexutables:
    for fe in ${exe1} ${exe2}; do
        rsync -L -avP ${DIR_EXE}/${fe} ${TMP_DIR}/
    done


    cd ${TMP_DIR}/

    FR2=`basename ${RST_MODEL2}` ; echo "${FR2} !"
    #
    if [ ! -f ./fdrnf.nc ]; then
        ncks  -O -v R_Runoff_oce ${FR2} -o fdrnf.nc
        ncrename -v R_Runoff_oce,FSENDATM  fdrnf.nc
    fi
    rm -f ${FR2}


    cat > namcouple <<EOF
 \$NFIELDS
    ${NFIELDS}
 \$END
# -------------------------------------------------------------------------------------------------
 \$RUNTIME
     60
 \$END
# -------------------------------------------------------------------------------------------------
 \$NLOGPRT
    1
 \$END
# -------------------------------------------------------------------------------------------------
 \$STRINGS
#
# ==========================================================
#  Field 1: model2 to model1 => 512x256 to NEMO ( ${CNAME} )
# ==========================================================
  FSENDATM FRECVOCN 1 ${CPL_PERIOD} 2 fdrnf.nc EXPORTED
  ${CONF2} ${CONF1}t${NE} LAG=${LAG}
  P  0  P  2
  SCRIPR CONSERV
   GAUSWGT LR SCALAR LATITUDE 1 9 2.0
   GLBPOS opt
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
cl_grd_src='${CONF1}t${NE}'
\$end
\$grid_target_characteristics
cl_grd_tgt='${CONF2}'
\$end
EOF

echo
echo "sbatch ./${fscript}"
sbatch ./${fscript}
echo




echo  "Check into: ${TMP_DIR}/ "
