#!/bin/bash

EXP="CHR0"
VAR="sosstsst"
YEAR="1990"

if [ "$2" = "" ]; then
    echo "USAGE: `basename ${0}` <NAME EXP> <VAR to extract>"; exit
fi
EXP="$1"
VAR="$2"


cs="extract.job"

cat > ${cs} <<EOF
#!/bin/sh
#
#######
#BSUB -q sequential
#BSUB -n 6
#BSUB -J ExtrO12
#BSUB -W 2:50
#BSUB -oo out_ExtrO12_%J.out
#BSUB -eo err_ExtrO12_%J.err
########

echo ; module load NCO/4.6.1 ; echo

fr="${VAR}_${EXP}_${YEAR}"

for cm in "001" "003" "005" "007" "009" "011"; do
    echo
    cf_t=\`find ./\${cm} -name ${EXP}_1d_${YEAR}*_grid_T.nc*\`
    echo "ncks -O -h -v ${VAR} \${cf_t} -o \${fr}_\${cm}.tmp &"
          ncks -O -h -v ${VAR} \${cf_t} -o \${fr}_\${cm}.tmp &
    echo
done

wait

for cm in "002" "004" "006" "008" "010" "012"; do
    echo
    cf_t=\`find ./\${cm} -name ${EXP}_1d_${YEAR}*_grid_T.nc*\`
    echo "ncks -O -h -v ${VAR} \${cf_t} -o \${fr}_\${cm}.tmp &"
          ncks -O -h -v ${VAR} \${cf_t} -o \${fr}_\${cm}.tmp &
    echo
done

wait

for cm in "001" "003" "005" "007" "009" "011"; do
    echo "ncra -O -h  \${fr}_\${cm}.tmp -o mean_\${fr}_\${cm}.tmp &"
          ncra -O -h  \${fr}_\${cm}.tmp -o mean_\${fr}_\${cm}.tmp &
    echo
done
for cm in "002" "004" "006" "008" "010" "012"; do
    echo "ncra -O -h  \${fr}_\${cm}.tmp -o mean_\${fr}_\${cm}.tmp &"
          ncra -O -h  \${fr}_\${cm}.tmp -o mean_\${fr}_\${cm}.tmp &
    echo
done

wait

echo "ncrcat -O \${fr}_???.tmp -o \${fr}.nc &"
      ncrcat -O \${fr}_???.tmp -o \${fr}.nc &
echo

echo "ncrcat -O mean_\${fr}_???.tmp -o \${fr}_monthly.nc &"
      ncrcat -O mean_\${fr}_???.tmp -o \${fr}_monthly.nc &
      pid_A=\$!
echo

wait \${pid_A}
echo
echo "ncra -O -h \${fr}_monthly.nc -o \${fr}_annual.nc"
      ncra -O -h \${fr}_monthly.nc -o \${fr}_annual.nc
echo

wait
rm -f \${fr}_???.tmp mean_\${fr}_???.tmp

EOF

chmod +x ${cs}
bsub < ${cs}