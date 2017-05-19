#!/bin/bash

export HERE=`pwd`

DIR_OUT=${HERE}/ZOOMs

mkdir -p ${DIR_OUT}

QUEUE=sequential ; NBP=1 ; TJOB="0:59"

MODULES_TO_LOAD_1="NCO/4.6.1"
MODULES_TO_LOAD_2="openmpi/1.8.1 NETCDF/4.3.2-parallel"

FILES_TO_DO="grid_T grid_U grid_V icemod"


if [ "$1" = "" ]; then
    echo "USAGE: ${0} <FILE_ROOT>" ; exit
fi


FILE_ROOT="${1}"

BOXNM=( "NAtl" "MedS" "GulfS" "SGL"  "Agul" "Wede" "GINS" )
BOXI1=( "2460" "3322" "2500"  "2720" "3500" "2732" "3087" )
BOXJ1=( "1900" "1846" "1800"  "2220"  "870"    "0" "2545" )
BOXI2=( "3550" "3962" "2950"  "3200" "3915" "3150" "3501" )
BOXJ2=( "2900" "2181" "2220"  "2580" "1170"  "280" "2857" )

BOXNM=( "NAtl"  )
BOXI1=( "2460"  )
BOXJ1=( "1900"  )
BOXI2=( "3550"  )
BOXJ2=( "2900"  )

icpt=0

for cnm in ${BOXNM[*]}; do

    i1=${BOXI1[${icpt}]}
    j1=${BOXJ1[${icpt}]}
    i2=${BOXI2[${icpt}]}
    j2=${BOXJ2[${icpt}]}

    echo
    echo " Doing box ${cnm} "
    echo ${i1} ${j1} ${i2} ${j2}


    LIST_F_T=`find . -name ${FILE_ROOT}*_grid_T.nc*`

    
    echo ${LIST_F_T}

    for f2t in ${LIST_F_T}; do
        
        THERE=`dirname ${f2t}`
        cd ${THERE} ;# THERE=`pwd`
        LIST_SD=`\ls ${FILE_ROOT}*.nc*`
        cd ${HERE}
        
        for ff in ${LIST_SD}; do
            CT=`echo ${ff} | sed -e s/"${FILE_ROOT}"/""/g -e s/".nc"/""/g`
            cscript=tmp_extract_${ff}_${cnm}.job
            rm -f ${cscript}
            cat > ${cscript} <<EOF
#!/bin/bash
#
#######
#BSUB -q ${QUEUE}
#BSUB -n ${NBP}
#BSUB -J ${cnm}_${CT}
#BSUB -W ${TJOB}
#BSUB -oo out_${cnm}_${CT}_%J.out
#BSUB -eo err_${cnm}_${CT}_%J.err
########
#
cd ${HERE}/
#
module load ${MODULES_TO_LOAD_1}
#
ncks -O -d x,${i1},${i2} -d y,${j1},${j2} ${THERE}/${ff} \\
        -o ${DIR_OUT}/${cnm}_${ff}
#
module rm ${MODULES_TO_LOAD_1}
exit
EOF
            
            chmod +x ${cscript}
            bsub < ${cscript}

            sleep 2

        done
    done
    icpt=`expr ${icpt} + 1`
done
