#!/bin/bash

#######
#BSUB -q sequential
#BSUB -n 3
#BSUB -J EX-CURL
#BSUB -W 11:50
#BSUB -oo out_extract_curl_nemo_%J.out
#BSUB -eo err_extract_curl_nemo%J.err
########

#######
#SBATCH -w gustafson
#SBATCH -n 3
#SBATCH -J EX-CURL
#SBATCH -t 05:50:00
#SBATCH -o out_extract_curl_nemo_%J.out
#SBATCH -e err_extract_curl_nemo%J.err
########


ref_year=1990

year=1990

expname="CHR0"

CDFTOOLS_PATH="/home/Earth/lbrodeau/DEV/barakuda/cdftools_light/bin"

VU=ssu ; VV=ssv ; ilev=0
#l_do_qsum=false
#VVAR="SSTK,T2M,D2M,U10M,V10M,MSL"
#VVAR="T2M"
#VFLX="SSHF,SLHF,SSR,STR,EWSS,NSSS"
#VFLX="SSHF,SLHF,SSR"
#VFLX="EWSS,NSSS"
#VFLX=""

rm -f curl.nc

NEMO_OUT=/scratch/Earth/lbrodeau/ORCA12-T1279/${expname}/nemo

#yece=$((${year}-${ref_year}+1))



nccopy -k 4 -d 9 ${expname}_1d_${year}_CURL.nc ${expname}_1d_${year}_CURL.nc4

exit 0



for jm in 1 2 3 4 5 6 7 8 9 10 11 12; do

    #subdir=`printf "%03d" ${yece}`
    cm=`printf "%02d" ${jm}`
    subdir=`printf "%03d" ${jm}`

    fu=`\ls ${NEMO_OUT}/${subdir}/${expname}_1d_${year}${cm}01_${year}${cm}??_grid_U.nc4`
    fv=`\ls ${NEMO_OUT}/${subdir}/${expname}_1d_${year}${cm}01_${year}${cm}??_grid_V.nc4`

    ca=`basename ${fu}`
    fout=`echo ${ca} | sed -e s/"grid_U"/"CURL"/g -e s/".nc4"/".nc"/g`

    echo ${fout}

    echo
    echo "${CDFTOOLS_PATH}/cdfcurl.x ${fu} ${fv} ${VU} ${VV} 0" ; sleep 2
    ${CDFTOOLS_PATH}/cdfcurl.x ${fu} ${fv} ${VU} ${VV} 0
    echo

    mv -f curl.nc ${fout}

done

ncrcat -O ${expname}_1d_${year}*_CURL.nc -o ${expname}_1d_${year}_CURL.nc

nccopy -k 4 -d 9 ${expname}_1d_${year}_CURL.nc ${expname}_1d_${year}_CURL.nc4

exit 0
