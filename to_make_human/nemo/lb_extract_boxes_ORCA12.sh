
#!/bin/bash

export HERE=`pwd`

DIR_OUT=${HERE}/ZOOMs

mkdir -p ${DIR_OUT}

QUEUE=sequential ; NBP=1 ; TJOB="5:59"

MODULES_TO_LOAD_1="NCO/4.6.1"
MODULES_TO_LOAD_2="openmpi/1.8.1 NETCDF/4.3.2-parallel"

FILES_TO_DO="grid_T grid_U grid_V icemod"


if [ "$1" = "" ]; then
    echo "USAGE: ${0} <FILE_ROOT>" ; exit
fi

#ldomask=false
#if [ "$1" = "-m" ]; then
#    ldomask=true
#    FILES_TO_DO="mask"
#    if [ "$2" = "" ]; then
#        echo "USAGE: ${0} (-m) <FILE_ROOT>" ; exit
#    fi
#fi

FILE_ROOT="${1}"

if [ "${FILE_ROOT}" = "output.abort" ]; then FILES_TO_DO="abort"; fi
if [ "${FILE_ROOT}" = "mesh_mask"    ]; then FILES_TO_DO="mask"; fi

# 2268,3945 -d y,1585,3029

BOXNM=( "NAtl" "MedS" "GulfS" "SGL"  "Agul" "Wede" "GINS" )
BOXI1=( "2460" "3322" "2500"  "2720" "3500" "2732" "3087" )
BOXJ1=( "1900" "1846" "1800"  "2220"  "870"    "0" "2545" )
BOXI2=( "3550" "3962" "2950"  "3200" "3915" "3150" "3501" )
BOXJ2=( "2900" "2181" "2220"  "2580" "1170"  "280" "2857" )

#BOXNM=( "NAtl"  )
#BOXI1=( "2460"  )
#BOXJ1=( "1900"  )
#BOXI2=( "3550"  )
#BOXJ2=( "2900"  )

icpt=0

for cnm in ${BOXNM[*]}; do

    i1=${BOXI1[${icpt}]}
    j1=${BOXJ1[${icpt}]}
    i2=${BOXI2[${icpt}]}
    j2=${BOXJ2[${icpt}]}

    echo
    echo " Doing box ${cnm} "
    echo ${i1} ${j1} ${i2} ${j2}


    for gt in ${FILES_TO_DO}; do

        lnc4=false ; NC="nc"

        ctest="${FILE_ROOT}_${gt}"
        
        if [ "${gt}" = "abort" ]; then ctest="output.abort"; fi
        if [ "${gt}" = "mask"  ]; then ctest="mesh_mask"; fi
        
        if [ ! -f ${ctest}.nc ]; then
            if [ -f ${ctest}.nc4 ]; then
                lnc4=true ; NC="nc4"
            else
                echo "PROBLEM: ${ctest}.nc* not found"; exit
            fi
        fi



        if [ "${gt}" = "icemod" ]; then
            CT="I"
        else
            CT=`echo "${gt}" | cut -d _ -f2`
        fi


        cfc="${FILE_ROOT}_${gt}"

        if [ "${gt}" = "abort" ]; then
            CT="OA"
            cfc="output.abort"
        fi
        if [ "${gt}" = "mask" ]; then
            CT="MM"
            cfc="mesh_mask"
        fi
            

        cscript=tmp_extract_${gt}_${cnm}
        rm -f ${cscript}.sh
        cat > ${cscript}.sh <<EOF
#!/bin/sh
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

module load ${MODULES_TO_LOAD_1}
#
cfc="${cfc}"
#
ncks -O -d x,${i1},${i2} -d y,${j1},${j2} \${cfc}.${NC} -o ${DIR_OUT}/${cnm}_\${cfc}.${NC}
#
module rm ${MODULES_TO_LOAD_1}

if ! ${lnc4} ; then
    module load ${MODULES_TO_LOAD_2}
    cd ${DIR_OUT}/
    rm -f ${cnm}_\${cfc}.nc4
    nccopy -k 4 -d 9 ${cnm}_\${cfc}.nc ${cnm}_\${cfc}.nc4
    mv -f ${cnm}_\${cfc}.nc ${cnm}_\${cfc}.nc_old
    module rm ${MODULES_TO_LOAD_2}
fi

exit
EOF

        chmod +x ${cscript}.sh
        bsub < ${cscript}.sh

        sleep 2

    done

    icpt=`expr ${icpt} + 1`

done