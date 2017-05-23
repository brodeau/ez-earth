#!/bin/bash

#######
#BSUB -q sequential
#BSUB -n 3
#BSUB -J EX-IFS
#BSUB -W 11:50
#BSUB -oo out_extract_ifs_%J.out
#BSUB -eo err_extract_ifs_%J.err
########

#######
#SBATCH -n 3
#SBATCH -J EX-IFS
#SBATCH -t 08:50:00
#SBATCH -o out_extract_ifs_%J.out
#SBATCH -e err_extract_ifs_%J.err
########


ref_year=1990
year=1990

expname="CHR0"

l_do_qsum=false

#VVAR="SSTK,T2M,D2M,U10M,V10M,MSL"
VVAR="U10M,V10M"
#VVAR="T2M"
#VFLX="SSHF,SLHF,SSR,STR,EWSS,NSSS"
#VFLX="SSHF,SLHF,SSR"
VFLX="EWSS,NSSS"
#VFLX=""

IFS_OUT=/scratch/Earth/lbrodeau/ORCA12-T1279/${expname}/ifs


pptime=21600 # default 6-hr output timestep

div=$((${freq_ifs}*3600))


#echo ; module load gcc/4.7.2 intel/13.0.1 openmpi/1.8.1 NETCDF/4.1.3 HDF5/1.8.10 UDUNITS/2.1.24 CDO/1.7.0 ; echo
#echo ; module load NCO/4.2.3 ; echo

cd ${IFS_OUT}/

cdoR="cdo -R -t ecmwf"
cdozip="cdo -f nc4c -z zip -t ecmwf"

# reference time for the simulation (=startdate and time)
reftime="${ref_year}-01-01,00:00:00"


icpt=0
for mm in "001" "002" "003" "004" "005" "006" "007" "008" "009" "010" "011" "012"; do

    ((icpt++))
    cm=`printf "%02d" ${icpt}`

    f_grib_in="${mm}/ICMGG${expname}+${year}${cm}"

    out_6h=./${expname}_${year}${cm}_6h
    out_1d=./${expname}_${year}${cm}_1d

    # Net and turbulent heat flux:
    if ${l_do_qsum} ; then
        if [ ! -f ${out_1d}_SNHF.nc ]; then
            echo
            echo "${cdoR} -expr,\"SNHF=(SSR+STR+SLHF+SSHF)/$pptime\" ${f_grib_in} tmp_snr1.grb"
            ${cdoR} -expr,"SNHF=(SSR+STR+SLHF+SSHF)/$pptime" ${f_grib_in} tmp_snr1.grb &
            echo
            echo "${cdoR} -expr,\"STHF=(SLHF+SSHF)/$pptime\" ${f_grib_in} tmp_snr2.grb"
            ${cdoR} -expr,"STHF=(SLHF+SSHF)/$pptime" ${f_grib_in} tmp_snr2.grb &
            echo
            wait; wait
            echo
            echo "${cdozip} -setreftime,${reftime} tmp_snr1.grb ${out_6h}_SNHF.nc"
            ${cdozip} -setreftime,${reftime} tmp_snr1.grb ${out_6h}_SNHF.nc &
            echo
            echo "${cdozip} -setreftime,${reftime} tmp_snr2.grb ${out_6h}_STHF.nc"
            ${cdozip} -setreftime,${reftime} tmp_snr2.grb ${out_6h}_STHF.nc &
            echo
            wait; wait
            echo
            rm -f tmp_snr*.grb
            echo
        fi
    fi

    echo ; echo
    

    # Individual surface heat flux components:
    if [ ! -f ${out_1d}_SSR.nc ] && [ ! "${VFLX}" = "" ]; then

        vflxs=`echo ${VFLX} | sed -e s/','/' '/g`
        echo
        echo " Extracting ${vflxs} !"
        echo "${cdozip} -R splitvar -setreftime,${reftime} -divc,$pptime \
        -selvar,${VFLX}   ${f_grib_in} ${out_6h}_"
        ${cdozip} -R splitvar -setreftime,${reftime} -divc,$pptime \
            -selvar,${VFLX}   ${f_grib_in} ${out_6h}_      &
        echo
        
    fi
    if ${l_do_qsum} ; then vflxs="SNHF STHF ${vflxs}" ; fi
        
    if [ ! -f ${out_1d}_SSR.nc ] && [ ! "${VVAR}" = "" ]; then
        # Fields that are not fluxes:
        vvars=`echo ${VVAR} | sed -e s/','/' '/g`
        echo
        echo " Extracting ${vvars} !"
        echo "${cdozip} -R splitvar -setreftime,${reftime} \
        -selvar,${VVAR}   ${f_grib_in} ${out_6h}_"
        ${cdozip} -R splitvar -setreftime,${reftime} \
            -selvar,${VVAR}   ${f_grib_in} ${out_6h}_       &
        echo    
        
    fi
    
    wait; wait

    echo; ls ; echo

    if [ ! -f ${out_1d}_SSR.nc ] ; then
        # Daily version:
        LIST=`\ls ${out_6h}*.nc`
        for cf in ${LIST}; do
            co=`echo ${cf} | sed -e s/'6h'/'1d'/g`
            echo
        #echo "cdo shifttime,1sec -daymean -shifttime,-1sec ${cf} ${co}"
        #cdo shifttime,1sec -daymean -shifttime,-1sec ${cf} ${co}
            echo "cdo -daymean -shifttime,-1sec ${cf} ${co}"
            cdo -daymean -shifttime,-1sec ${cf} ${co}
            echo
        done
    fi

done


echo
for cv in ${vflxs} ${vvars}; do
    for ff in "1d" "6h"; do
        fo=${expname}_${year}_${ff}_${cv}.nc4
        rm -f ${fo}
        echo "ncrcat -O ${expname}_${year}*_${ff}_${cv}.nc -o ${fo}"
        ncrcat -O ${expname}_${year}*_${ff}_${cv}.nc -o ${fo}
        echo
        #
        if ${l_do_qsum} ; then
            if [ "${cv}" = "SNHF" ]; then ncrename -v STRF,SNHF ${fo} ; fi
            if [ "${cv}" = "STHF" ]; then ncrename -v STRF,STHF ${fo} ; fi
        fi
        #
    done
done

#rm -f *6h_*.nc

exit
