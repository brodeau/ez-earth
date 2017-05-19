#!/bin/bash

#DEFLAT_LEVEL=7

VAR_TO_KEEP="SSTK,LSP,CP,SSHF,SLHF,SSR,STR,EWSS,NSSS,E,MSL,U10M,V10M,T2M,D2M"

if [ "$1" = "" ]; then
    echo "USAGE: ${0} EXPNAME"; exit
fi

export HERE=`pwd`

EXTRCT="cdo -t ecmwf -selvar,${VAR_TO_KEEP}"

chst=`hostname | cut -c1-6`

cs="tmp_keep_icmgg.sh"

rm -f ${cs}

cat > ${cs} <<EOF
#!/bin/bash
#
#######
EOF
if [ "${chst}" = "trioli" ]; then
    cat >> ${cs} <<EOF
#SBATCH -A snic2014-10-3
#SBATCH --reservation=dcs
#SBATCH -N 1
#SBATCH -n 2
#SBATCH -J =IFSLGHT=
#SBATCH -t 23:00:00
#SBATCH -o out_ifslght.out
#SBATCH -e err_ifslght.err
EOF
elif [ "${chst}" = "login1" ]; then
    cat >> ${cs} <<EOF
#BSUB -q sequential
#BSUB -n 2
#BSUB -J =IFSLGHT=
#BSUB -W 23:50
#BSUB -oo out_ifslght.out
#BSUB -eo err_ifslght.err
#####
echo
module load gcc/4.7.2 intel/13.0.1 openmpi/1.8.1 NETCDF/4.1.3 HDF5/1.8.10 UDUNITS/2.1.24 CDO/1.7.0
echo
EOF
else
    echo "Don't know host ${chst} !"; exit
fi

cat >> ${cs} <<EOF
########
#
cd ${HERE}/
list=\`find -name 'ICMSH${1}+??????' | grep -v '+000000'\`
for ff in \$list; do
  rm -f \${ff}
done
#
list=""
#
list=\`find -name 'ICMGG${1}+??????' | grep -v '+000000'\`
echo
echo " Files to consider:"
echo "\${list}"
echo
for ff in \$list; do
  if [ ! -f ./\${ff}.done ]; then
     echo " *** doing \${ff}"
     mv -f \${ff} \${ff}.old
     ${EXTRCT} \${ff}.old \${ff}
  else
     echo " *** \${ff} was done!!!"
  fi
  touch \${ff}.done
done
#
EOF

cd ${HERE}/

chmod +x ${cs}

if [ "${chst}" = "trioli" ]; then sbatch ./${cs} ; fi

if [ "${chst}" = "login1" ]; then bsub   < ${cs} ; fi


