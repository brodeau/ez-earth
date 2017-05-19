#!/bin/bash

#BSUB -q sequential
#BSUB -J SOSIEO12                                                                                  
#BSUB -oo out_SOSIE_O12_%J.out                                                  
#BSUB -eo err_SOSIE_O12_%J.err                                                  
#BSUB -W 23:50                                                                              
#BSUB -n 16

LIST_MOD="impi/5.1.3.210 HDF5/1.8.12-mpi NETCDF/4.3.2-parallel"
module add ${LIST_MOD}


cat > namelist <<EOF
&ninput
ivect     = 0
lregin    = T
cf_in     = '/gpfs/projects/bsc32/bsc32325/ORCA_COMMON_FIELDS/Goutorbe_ghflux.nc4'
cv_in     = 'gh_flux'
cv_t_in   = 'time' 
jt1       = 0
jt2       = 0
jplev     = 1
cf_x_in   = '/gpfs/projects/bsc32/bsc32325/ORCA_COMMON_FIELDS/Goutorbe_ghflux.nc4'
cv_lon_in = 'lon'
cv_lat_in = 'lat'
cf_lsm_in = ''
cv_lsm_in = ''
ldrown    = F
ewper     = 0
vmax      = 1.E6
vmin      = 0.
/
!!
&noutput
lregout    = F
cf_x_out   = '/gpfs/projects/bsc32/bsc32325/ORCA12/mesh_mask.nc4'
cv_lon_out = 'glamt'
cv_lat_out = 'gphit'
cf_lsm_out = '/gpfs/projects/bsc32/bsc32325/ORCA12/mesh_mask.nc4'
cv_lsm_out = 'tmask'
lmout      = F
rmaskvalue = -9999.
lct        = F
t0         = 0.
t_stp      = 0.
ewper_out  = 2
/
!! 
&nnetcdf
cmethod  = 'akima'
cv_l_out = 'nav_lon'
cv_p_out = 'nav_lat'
cv_t_out = 'time_counter'
cv_out   = 'gh_flux'
cu_out   = 'mW m^{-2}'
cu_t     = 'unknown'
cln_out  = 'Geothermal heat flux from Goutorbe et al. (2011)'
cd_out   = '.'
csource  = '360x180'
ctarget  = 'ORCA12'
cextra   = 'annual'
lpcknc4  = .true.
/
EOF

/home/bsc32/bsc32325/DEV/sosie-code/trunk/bin/sosie.x -f namelist



module rm ${LIST_MOD}

