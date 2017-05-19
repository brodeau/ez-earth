#!/bin/bash

export HERE=`pwd`

#QUEUE=sequential ; TJOB="11:59"
QUEUE=bsc_debug ; TJOB="00:59"

NBP=6

MODULES_TO_LOAD_2="openmpi/1.8.1 NETCDF/4.3.2-parallel"


if [ "$1" = "" ]; then
    echo "USAGE: ${0} <output_root>"
fi

noutput="$1"



ii=`\ls ${noutput}_0000.nc | wc -l`

if [ ! ${ii} -eq 1 ]; then
    echo "PROBLEM: seems like something is wrong #1 !" ; exit
fi

nbc=`\ls ${noutput}_*.nc | wc -l`

echo ; echo "Number of chuncks: ${nbc}" ; echo

CMD="rebuild_nemo -t ${NBP} ${noutput} ${nbc}"




cscript=tmp_rbld_oa
rm -f ${cscript}.sh
cat > ${cscript}.sh <<EOF
#!/bin/sh
#
#######
#BSUB -q ${QUEUE}
#BSUB -n ${NBP}
#BSUB -J RBLDOA
#BSUB -W ${TJOB}
#BSUB -oo out_rbldOA_%J.out
#BSUB -eo err_rbldOA_%J.err
########

cd ${HERE}/
rm -f ${noutput}.nc

${CMD} > rbld_oa.out 

EOF
chmod +x ${cscript}.sh
bsub < ${cscript}.sh

sleep 2
