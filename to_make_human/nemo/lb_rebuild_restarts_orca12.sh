#!/bin/bash

if [ "$1" = "" ]; then 
    echo "USAGE: ${0} <begining files>"
    exit
fi

export HERE=`pwd`

QUEUE=sequential ; TJOB="20:59"

NBPO=10
NBPI=6

MODULES_TO_LOAD_2="openmpi/1.8.1 NETCDF/4.3.2-parallel"


ii=`\ls ${1}*_0000.nc | wc -l` ; echo ${ii}

if [ ! ${ii} -eq 2 ]; then
    echo "PROBLEM: seems like something is wrong #1 !" ; exit
fi

ca=`\ls ${1}*_restart_ice_0000.nc`

# Common root name:
r_root=`echo ${ca} | sed -e "s/_restart_ice_0000.nc//g"`


fr_oce0=${r_root}_restart_oce_0000.nc

if [ ! -f ${fr_oce0} ]; then
    echo "PROBLEM: seems like something is wrong #2 !" ; exit
fi

nbp=`\ls ${r_root}_restart_ice_*.nc | wc -l`

echo ; echo "Number of chuncks: ${nbp}" ; echo

CMD_ICE="rebuild_nemo -t ${NBPI}  ${r_root}_restart_ice ${nbp}"
CMD_OCE="rebuild_nemo -t ${NBPO}  ${r_root}_restart_oce ${nbp}"

echo " CMD_ICE = ${CMD_ICE} "
echo " CMD_OCE = ${CMD_OCE} "


fri=${r_root}_restart_ice.nc
fro=${r_root}_restart_oce.nc


cscript=tmp_rbld_ice
rm -f ${cscript}.sh
cat > ${cscript}.sh <<EOF
#!/bin/sh
#
#######
#BSUB -q ${QUEUE}
#BSUB -n ${NBPI}
#BSUB -J RBLDICE
#BSUB -W ${TJOB}
#BSUB -oo out_rbldICE_%J.out
#BSUB -eo err_rbldICE_%J.err
########
cd ${HERE}/
rm -f ${fri}

rm -rf rbld_ice
mkdir rbld_ice
cd rbld_ice/
ln -sf ../${r_root}_restart_ice_[0123456789]*.nc .

${CMD_ICE} > rbld_ice.out 

sleep 2

rm -rf ${r_root}_restart_ice_[0123456789]*.nc

module load ${MODULES_TO_LOAD_2}
rm -f ${fri}4
nccopy -k 4 -d 9 ${fri} ${fri}4 
###mv -f ${fri} ${fri}_old

EOF
chmod +x ${cscript}.sh
bsub < ${cscript}.sh

sleep 2



cscript=tmp_rbld_oce
rm -f ${cscript}.sh
cat > ${cscript}.sh <<EOF
#!/bin/sh
#
#######
#BSUB -q ${QUEUE}
#BSUB -n ${NBPO}
#BSUB -J RBLDOCE
#BSUB -W ${TJOB}
#BSUB -oo out_rbldOCE_%J.out
#BSUB -eo err_rbldOCE_%J.err
########
cd ${HERE}/
rm -f ${fro}

rm -rf rbld_oce
mkdir rbld_oce
cd rbld_oce/
ln -sf ../${r_root}_restart_oce_[0123456789]*.nc .

${CMD_OCE} > rbld_oce.out 

sleep 2

rm -rf ${r_root}_restart_oce_[0123456789]*.nc

###module load openmpi/1.8.1
###module load NETCDF/4.1.3
###export NCCOPY="nccopy"

###rm -f ${fro}4
###\${NCCOPY} -k 4 -d 9 ${fro} ${fro}4 
###mv -f ${fro} ${fro}_old

EOF
chmod +x ${cscript}.sh
bsub < ${cscript}.sh

sleep 2
