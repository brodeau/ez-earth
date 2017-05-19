#!/bin/bash


module load NCO/4.6.1

fo=`echo $1 | sed -e s/'eORCA12'/'ORCA12'/g -e s/'.nc'/'_cut.nc'/g`

echo $fo

echo "ncks -O -d y,547,3605 ${1} -o ${fo}"

ncks -O -d y,547,3605 ${1} -o ${fo}

echo

module rm NCO/4.6.1