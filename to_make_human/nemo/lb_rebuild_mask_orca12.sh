#!/bin/bash

export HERE=`pwd`


ROOT="mesh_mask"

if [ "$1" = "r" ]; then
    ROOT=runoffs
fi

QUEUE=sequential ; TJOB="23:59"

NBP=6

MODULES_TO_LOAD_2="openmpi/1.8.1 NETCDF/4.3.2-parallel"


ii=`\ls ${ROOT}_0000.nc | wc -l`

if [ ! ${ii} -eq 1 ]; then
    echo "PROBLEM: seems like something is wrong #1 !" ; exit
fi

nbc=`\ls ${ROOT}_*.nc | wc -l`

echo ; echo "Number of chuncks: ${nbc}" ; echo

CMD="rebuild_nemo -t ${NBP} ${ROOT} ${nbc}"




cscript=tmp_rbld_mm
rm -f ${cscript}.sh
cat > ${cscript}.sh <<EOF
#!/bin/sh
#
#######
#BSUB -q ${QUEUE}
#BSUB -n ${NBP}
#BSUB -J RBLDMM
#BSUB -W ${TJOB}
#BSUB -oo out_rbldMM_%J.out
#BSUB -eo err_rbldMM_%J.err
########

cd ${HERE}/
rm -f ${ROOT}.nc

${CMD} > rbld_mm.out 

sleep 2
exit
EOF
chmod +x ${cscript}.sh
bsub < ${cscript}.sh

sleep 2
