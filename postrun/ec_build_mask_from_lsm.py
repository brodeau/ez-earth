#!/home/x_laubr/bin/python
#
# L. Brodeau, Feb.2011

import sys
import numpy as nmp
from netCDF4 import Dataset

import barakuda_tool as bt

cf_ud  = ''
cv_lsm ='LSM'




if len(sys.argv) == 1 or len(sys.argv) < 3 and len(sys.argv) > 4:
    print 'Usage: '+sys.argv[0]+' <FILE_LSM.nc> <FILE_OUT.nc> (<"ud">)'
    sys.exit(0)

cf_lsm = sys.argv[1]
cf_out = sys.argv[2]

if len(sys.argv) == 4: cf_ud = sys.argv[3]



bt.chck4f(cf_lsm) ; f_lsm_in = Dataset(cf_lsm)

# Extracting the longitude and 1D array:
vlon     = f_lsm_in.variables['lon'][:]
clnm_lon = f_lsm_in.variables['lon'].long_name ; cunt_lon = f_lsm_in.variables['lon'].units
csnm_lon = f_lsm_in.variables['lon'].standard_name
print 'LONGITUDE: ', clnm_lon, cunt_lon, csnm_lon

# Extracting the longitude 1D array:
vlat     = f_lsm_in.variables['lat'][:]
clnm_lat = f_lsm_in.variables['lat'].long_name ; cunt_lat = f_lsm_in.variables['lat'].units
csnm_lat = f_lsm_in.variables['lat'].standard_name
print 'LATGITUDE: ', clnm_lat, cunt_lat, csnm_lat

# Extracting a variable, ex: "t" the 3D+T field of temperature:
xlsm     = f_lsm_in.variables[cv_lsm][0,:,:]
code_lsm = f_lsm_in.variables[cv_lsm].code
ctab_lsm = f_lsm_in.variables[cv_lsm].table
print cv_lsm+': ', code_lsm, ctab_lsm, '\n'
f_lsm_in.close()





# Checking dimensions
# ~~~~~~~~~~~~~~~~~~~
print '\n'
dim_lsm = xlsm.shape
( nj, ni ) = dim_lsm
print 'ni, nj = ', ni, nj


# Building msk
# ~~~~~~~~~~~

xmsk = nmp.zeros(nj*ni) ; xmsk.shape = dim_lsm

idx_oce = nmp.where(xlsm[:,:] <  0.4)

xmsk[idx_oce] = 1.0






# Creating output file
# ~~~~~~~~~~~~~~~~~~~~
f_out = Dataset(cf_out, 'w', format='NETCDF3_CLASSIC')

# Dimensions:
f_out.createDimension('lon', ni)
f_out.createDimension('lat', nj)

# Variables
id_lon = f_out.createVariable('lon','f4',('lon',))
id_lat = f_out.createVariable('lat','f4',('lat',))
id_msk  = f_out.createVariable('lsm','f4',('lat','lon',))

id_lat.long_name     = clnm_lat
id_lat.units         = cunt_lat
id_lat.standard_name = csnm_lat

id_lon.long_name     = clnm_lon
id_lon.units         = cunt_lon
id_lon.standard_name = csnm_lon

id_msk.long_name = 'Land sea mask'
id_msk.table = '128'

f_out.About = 'Created by L. Brodeau using original lsm...'

# Filling variables:

if cf_ud == 'ud':
    id_lat[:]    = nmp.flipud(vlat[:])
    print '\n Flipping UD !!! \n'
else:
    id_lat[:] = vlat[:]


id_lon[:] = vlon[:]


if cf_ud == 'ud':
    id_msk[:,:]  = xmsk[::-1,:]
else:
    id_msk[:,:]  = xmsk[:,:] 



f_out.close()

print 'Bye!'

