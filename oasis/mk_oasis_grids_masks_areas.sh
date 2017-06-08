#!/bin/bash
#
#
# Generates the following files required by OASIS for coupling NEMO-IFS
#
# - masks.nc
# - grids.nc
# - areas.nc
#
#
# Dependencies:
# - NCO 
#
#
# Author: L. Brodeau, 2017

PATH_EC_OASIS=/proj/bolinc/users/x_laubr/brodeau_ece32_setup/oasis


# Config:
#RATM=159 ; GATM=080 ; TORCA=1 ;  l_do_areas=true
#RATM=1279 ; GATM=640 ; TORCA=12 ;  l_do_areas=true
RATM=255 ; GATM=128 ; TORCA=1 ;  l_do_areas=true

#RATM=511 ; GATM=256 ; TORCA=025




TOCE=ORCA${TORCA}


# NEMO conf label:
OT="O${TORCA}"
NE="0"
if [ ${TORCA} -eq 12 ]; then NE=""; fi

# Path to proper NEMO mesh_mask.nc:
NEMO_MESHMASK=/proj/bolinc/users/x_laubr/ORCA${TORCA}/mesh_mask.nc4

fta="./areas.nc"
ftg="./grids.nc"
ftm="./masks.nc"

# Template/original files to get IFS T${RATM} fields and Runoffs from:

if [ "${RATM}" = "159" ]; then
    # IFS T159:
    A_RATM="./back/areas.nc"
    G_RATM="./back/grids.nc"
    M_RATM="./back/masks.nc"
    # Rnf 512x256:
    A_RNFF="${PATH_EC_OASIS}/T255-ORCA1/areas.nc"
    G_RNFF="${PATH_EC_OASIS}/T255-ORCA1/grids.nc"
    M_RNFF="${PATH_EC_OASIS}/T255-ORCA1/masks.nc"

elif [ "${RATM}" = "255" ]; then
    A_RATM="${PATH_EC_OASIS}/T255-ORCA1/areas.nc"
    G_RATM="${PATH_EC_OASIS}/T255-ORCA1/grids.nc"
    M_RATM="${PATH_EC_OASIS}/T255-ORCA1/masks.nc"
    # Rnf 512x256:
    A_RNFF="${PATH_EC_OASIS}/T255-ORCA1/areas.nc"
    G_RNFF="${PATH_EC_OASIS}/T255-ORCA1/grids.nc"
    M_RNFF="${PATH_EC_OASIS}/T255-ORCA1/masks.nc"

elif [ "${RATM}" = "1279" ]; then
    A_RATM="./back/areas_T1279.nc"
    G_RATM="./back/grids_T1279.nc"
    M_RATM="./back/masks_T1279.nc"
    # Rnf 512x256:
    A_RNFF="${PATH_EC_OASIS}/T255-ORCA1/areas.nc"
    G_RNFF="${PATH_EC_OASIS}/T255-ORCA1/grids.nc"
    M_RNFF="${PATH_EC_OASIS}/T255-ORCA1/masks.nc"

else
    echo " Fix me !"; exit
fi

echo
echo " We shall steal IFS T${RATM} / atmospheric setup in:"
for cc in ${A_RATM} ${G_RATM} ${M_RATM}; do ls -l ${cc} ; done
echo
echo " We shall steal Runoff setup in:"
for cc in ${A_RNFF} ${G_RNFF} ${M_RNFF}; do ls -l ${cc} ; done
echo
echo " NEMO info into:"
for cc in ${NEMO_MESHMASK} ; do ls -l ${cc} ; done
echo
sleep 4



for ff in ${NEMO_MESHMASK} ; do
    if [ ! -f ${ff} ]; then
        echo "ERROR: ${ff} not found !" ; exit
    fi
done


rm -f ${fta} ${ftg} ${ftm}

# NEMO area:
if ${l_do_areas}; then
    rm -f e1e2.nc orca${TORCA}_areas.nc
    for tt in t u v; do
        for ee in e1 e2; do
            ncks -A -v ${ee}${tt} ${NEMO_MESHMASK} -o e1e2.nc
        done
        ncap2 -A -s "${OT}${tt}${NE}=e1${tt}*e2${tt}" e1e2.nc -o orca${TORCA}_areas.nc
        rm -f e1e2.nc
    done
fi

# NEMO grid:
rm -f orca${TORCA}_grids.nc
for tt in t u v; do
    # In mesh_mask glam* and gphi* are floats...
    ncks -O -v glam${tt},gphi${tt} ${NEMO_MESHMASK} -o coor.nc
    for gv in glam gphi; do
        ncap2 -O -s "Vtmp=double(${gv}${tt})" coor.nc -o dcoor.tmp
        ncwa -O -a t dcoor.tmp -o dcoor.tmp
        ncatted -h -O -a "cell_methods",Vtmp,d,c, dcoor.tmp  ; # deleting attribute
        ncks -O -v Vtmp dcoor.tmp -o coor.tmp ; rm -f dcoor.tmp
        cv="${OT}${tt}${NE}.lat"
        if [ "${gv}" = "glam" ]; then cv="${OT}${tt}${NE}.lon"; fi
        ncrename -v Vtmp,${cv} coor.tmp
        ncks -A -C -v ${cv} coor.tmp -o orca${TORCA}_grids.nc
        rm -f coor.tmp
    done
    rm -f coor.nc
done

# NEMO mask"
#module rm ${NCO1}
#module load ${NCO2}
rm -f Xmask.nc mask.nc orca${TORCA}_masks.nc
for tt in t u v; do
    echo "ncks -O -d z,0 -v ${tt}mask ${NEMO_MESHMASK} -o Xmask.nc"
    ncks -A -d z,0 -v ${tt}mask ${NEMO_MESHMASK} -o Xmask.nc  ; # only keep z=0 level !
    echo
done
#module rm ${NCO2}
#module load ${NCO1}
ncwa -O -a z Xmask.nc -o Xmask.nc  ; # rm degenerate z record
for tt in t u v; do
    ncap2 -O -s "${OT}${tt}${NE}=(1 - ${tt}mask)" Xmask.nc -o Xmask.nc 
    ncks  -A -v ${OT}${tt}${NE} Xmask.nc -o orca${TORCA}_masks.nc
done
rm -f Xmask.nc
echo
echo
echo "boo1"

# Removing degenerate dimensions:
#for ft in areas grids masks; do
#module load ${NCDF}
LIST="grids masks"
if ${l_do_areas}; then LIST="grids areas masks"; fi
for ft in ${LIST}; do
    ff=orca${TORCA}_${ft}.nc
    for dd in time z t; do
        ca=`ncdump -h ${ff} | grep "${dd} = "`
        if [ ! "${ca}" = "" ]; then
            echo "ncwa -O -a ${dd} ${ff} -o ${ff}"
            ncwa -O -a ${dd} ${ff} -o ${ff}
        fi
    done
done
#module rm ${NCDF} 
echo


# Post treatment on NEMO stuff:
LIST="grids"
if ${l_do_areas}; then LIST="areas grids"; fi
for ft in ${LIST}; do
    ncrename -d x,x_3 orca${TORCA}_${ft}.nc
    ncrename -d y,y_3 orca${TORCA}_${ft}.nc
done
ncrename -d x,x_3 orca${TORCA}_masks.nc
ncrename -d y,y_3 orca${TORCA}_masks.nc

LIST="masks"
if ${l_do_areas}; then LIST="areas masks"; fi
for ft in ${LIST}; do
    for tt in t u v; do
        ncatted -h -O -a cell_methods,${OT}${tt}${NE},d,c, orca${TORCA}_${ft}.nc
    done
done
if ${l_do_areas}; then
    for tt in t u v; do
        ncrename -v ${OT}${tt}${NE},${OT}${tt}${NE}.srf orca${TORCA}_areas.nc
    done
fi

for tt in t u v; do
    ncrename -v ${OT}${tt}${NE},${OT}${tt}${NE}.msk orca${TORCA}_masks.nc
done

for tt in t u v; do
    for vv in lon lat; do
        ncatted -h -O -a missing_value,${OT}${tt}${NE}.${vv},d,c, orca${TORCA}_grids.nc
    done
done

LIST="grids masks"
if ${l_do_areas}; then LIST="grids areas masks"; fi
for ff in ${LIST}; do
    for ga in "file_name" "TimeStamp" "history" "NCO" "history_of_appended_files" "nco_openmp_thread_number"; do
        ncatted -h -O -a ${ga},global,d,c, orca${TORCA}_${ff}.nc
    done
done

# IFS

# Need to convert all IFS masks from Float to Integer:
rm -f msk.tmp imsk.tmp ; #lulu
for gg in "A${GATM}" "L${GATM}" "R${GATM}"; do
    ncks  -h -A -v ${gg}.msk     ${M_RATM} -o msk.tmp
    ncrename -h -v ${gg}.msk,${gg}            msk.tmp
    ncap2 -h -A -s "I${gg}=int(${gg})" msk.tmp -o imsk.tmp
    ncrename -h -v I${gg},${gg}.msk  imsk.tmp
done
rm -f msk.tmp


for gg in "A${GATM}" "L${GATM}" "R${GATM}"; do
    if ${l_do_areas}; then ncks -A -v ${gg}.srf ${A_RATM} -o ${fta} ; fi
    ncks -A -v ${gg}.lat,${gg}.lon              ${G_RATM} -o ${ftg}
    ncks -A -v ${gg}.msk                        imsk.tmp  -o ${ftm}
done
rm -f imsk.tmp




################
# Runoffs:
################
for vv in "RnfA" "RnfO"; do
    ncks -A -v ${vv}.msk ${M_RNFF} -o ${ftm}
    if ${l_do_areas}; then
        #echo "ncks -A -v ${vv}.srf ${A_RNFF}    -o ${fta}"
        ncks -A -v ${vv}.srf ${A_RNFF}    -o ${fta}
        #echo "Done!"; echo
    fi
    #echo "ncks -A -v ${vv}.lat,${vv}.lon ${G_RNFF} -o ${ftg}"
    ncks -A -v ${vv}.lat,${vv}.lon ${G_RNFF}    -o ${ftg}
    #echo "Done!"; echo
done






##########
# NEMO:
##########
if ${l_do_areas}; then
    for tt in t u v; do
        ncks -A -v ${OT}${tt}${NE}.srf orca${TORCA}_areas.nc -o ${fta}
    done
    rm -f orca${TORCA}_areas.nc
fi

for tt in t u v; do
    ncks -A -v ${OT}${tt}${NE}.lat,${OT}${tt}${NE}.lon orca${TORCA}_grids.nc -o ${ftg}
done
rm -f orca${TORCA}_grids.nc


echo "Boo1!"
for tt in t u v; do
    echo "ncks -A -v ${OT}${tt}${NE}.msk orca${TORCA}_masks.nc -o ${ftm}"
    ncks -A -v ${OT}${tt}${NE}.msk orca${TORCA}_masks.nc -o ${ftm}
    echo
done

rm -f orca${TORCA}_masks.nc

echo "Boo2!"





# IFS GRIDDED:
if ${l_do_areas}; then
    ncks -A -v R${GATM}.srf ${A_RATM}    -o ${fta}
fi
ncks -A -v R${GATM}.lat,R${GATM}.lon ${G_RATM}    -o ${ftg}




if ! ${l_do_areas}; then
    fta=""
fi

for ff in ${fta} ${ftg} ${ftm}; do
    for ga in "history" "NCO" "CDO" "history_of_appended_files"; do
        ncatted -h -O -a ${ga},global,d,c, ${ff}
    done
    ncatted -h -O -a ece-origin,global,o,c,"Laurent Brodeau (BSC) for EC-Earth" ${ff}
done

