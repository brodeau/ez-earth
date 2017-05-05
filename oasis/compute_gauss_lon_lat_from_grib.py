#!/usr/bin/env python

#       L. Brodeau, 2016

import sys
import numpy as nmp
from netCDF4 import Dataset
from os import path,system
import math

from cdo import *

l_do_areas = False

cgrid = "T1279" ; cf0 = "ICMGGa09i+000000"
#cgrid = "T255" ; cf0 = "ICMGGLBO0+000000"

cd_out = '/home/laurent/tmp'

if not path.exists(cf0):
    print cf0+' is missing!!!'
    sys.exit(0)


rPi    = 3.141592653589793
to_rad = rPi/180.
R_earth = 6.37E6

cdo = Cdo()

AA = cdo.griddes(input=cf0, options = '-t ecmwf')
Nl = len(AA)


# Getting gridsize:
ca = 'gridsize' ; jl = 0 ; istop = 0
while istop == 0:
    raw_line = AA[jl] ; vs = raw_line.split()
    if ca in raw_line and raw_line[:len(ca)]==ca : gridsize = int(vs[2]) ; istop = 1
    jl = jl+1
print '\n **** gridsize = ', gridsize, '\n'

# Getting ysize:
ca = 'ysize' ; jl = 0 ; istop = 0
while istop == 0:
    raw_line = AA[jl] ; vs = raw_line.split()
    if ca in raw_line and raw_line[:len(ca)]==ca : ysize = int(vs[2]) ; istop = 1
    jl = jl+1
print ' **** ysize = ', ysize, '\n'

# gettin yvals:
ca = 'yvals'; vyvals = [] ; icpt = 0 ; istop = 0
for jl in range(Nl):
    raw_line = AA[jl] ; vs = raw_line.split()
    if ca in raw_line and raw_line[:len(ca)]==ca :
        while istop == 0:
            icpt = icpt+1 ; i0 = 0
            if icpt==1: i0=2
            vline = map(float, vs[i0:]) ; # to a line of integer array / Ignoring the '$ca = '
            vyvals = nmp.concatenate((vyvals,vline))
            jl = jl + 1 ; # Next line until we find rowlon:
            raw_line = AA[jl] ; vs = raw_line.split()
            if vs[0] == 'rowlon': istop = 1
        print ' **** vyvals = ', vyvals, '\n'

# gettin rowlon:
ca = 'rowlon'; vrowlon = [] ; icpt = 0 ; istop = 0
for jl in range(Nl):
    raw_line = AA[jl] ; vs = raw_line.split()
    if ca in raw_line and raw_line[:len(ca)]==ca :
        while istop == 0:
            icpt = icpt+1 ; i0 = 0
            if icpt==1: i0=2
            vline = map(int, vs[i0:]) ; # to a line of integer array / Ignoring the '$ca = '
            vrowlon = nmp.concatenate((vrowlon,vline))
            jl = jl + 1 ; # Next line until we find rowlon:
            if jl < Nl:
                raw_line = AA[jl] ; vs = raw_line.split()
            else:
                istop = 1
        irowlon = vrowlon.astype(int) ; del vrowlon
        print ' **** irowlon = ', irowlon, '\n\n'



# Checking if name of config TXXX is consistent with ysize!
if cgrid[1:] != str(ysize-1):
    print 'PROBLEM: you specified config as '+cgrid+', and we find ysize='+str(ysize)+' !'
    sys.exit(0)

if ysize != len(vyvals):
    print 'PROBLEM with vyvals!'
    sys.exit(0)

if ysize != len(irowlon):
    print 'PROBLEM with irowlon!'
    sys.exit(0)


vlatG = []
vlonG = []
vareaG = []

nbp = 0

for jp in range(ysize):

    lat = vyvals[jp]

    Nlon = irowlon[jp]

    if jp == 0:
        dlat = 90. - 0.5*(vyvals[jp] + vyvals[jp+1])
        #dlat = 90. - vyvals[jp]
    elif jp == ysize-1:
        dlat = 0.5*(vyvals[ysize-2] + vyvals[ysize-1]) + 90.
        #dlat = vyvals[ysize-1] + 90.
    else:
        dlat = 0.5*(vyvals[jp-1] - vyvals[jp+1])
        #dlat = vyvals[jp] - vyvals[jp+1]

    #print ' Nlon / lat / dlat= ', Nlon, lat, dlat

    
    for jlon in range(Nlon):
        nbp = nbp + 1
        dlon = 360./float(Nlon)
        vlatG.append(lat)
        vlonG.append(float(jlon)*dlon)

        if l_do_areas:
            # xarea(:,jj) = dlat * cos(vlat(jj)*to_rad)*dlon * R_earth * R_earth
            #rr = dlat * dlon * math.cos(lat*to_rad) * 1.E-10 * R_earth * R_earth
            rr = dlat * dlon * math.cos(lat*to_rad) * 1.E10
            if jlon==0: print rr
            vareaG.append(rr)


print ' Nb points calculated / gridsize =>', nbp, gridsize


if nbp != gridsize or len(vlatG) != gridsize or len(vlonG) != gridsize: print 'PROBLEM: with number of points!'; sys.exit(0)

cstr = str(ysize/2)

cf_out = cd_out+'/grids_T'+str(ysize-1)+'.nc'
f_out = Dataset(cf_out, 'w', format='NETCDF3_CLASSIC')
f_out.createDimension('x' , nbp)
f_out.createDimension('y' , 1)
id_lat1 = f_out.createVariable('A'+cstr+'.lat','f4',('y','x',))
id_lon1 = f_out.createVariable('A'+cstr+'.lon','f4',('y','x',))
id_lat2 = f_out.createVariable('L'+cstr+'.lat','f4',('y','x',))
id_lon2 = f_out.createVariable('L'+cstr+'.lon','f4',('y','x',))
id_lat1[:] = vlatG[:]
id_lon1[:] = vlonG[:]
id_lat2[:] = vlatG[:]
id_lon2[:] = vlonG[:]
f_out.close()
print '\n file '+cf_out+' written!\n'





# Extracting LSM into a netcdf file into out folder:
cf0nc = cd_out+'/'+cf0+'.nc'
system("cdo -t ecmwf -f nc copy -selvar,LSM "+cf0+" "+cf0nc)



######################################################################################
# * A640.msk and L640.msk are identical and have 0 on the ocean right.
#
# [Klaus] No! A640.msk is 1 over land and lakes, while L640.msk is 1 over land
# and 0 over lakes. Unfortunately there is no automated way of assigning water
# bodies to lakes or ocean, the condition LSM<0.5 will get L640.msk. You then
# need to fill in all lakes manually to get the proper A640.msk.
#
# What happens if you dont have a proper A640.msk? Well, in that case you
# shouldn't use a conservation step in the coupling, otherwise you distribute
# fluxes over areas that are not meant to be identical. And it makes it
# impossible for example to check the freshwater balance between ocean and
# atmosphere.
#
#
# * R640.msk is the oposite (1 on the ocean) ?
# [Klaus] R640 is the opposite of A640 (not L640!)
#
########################################################################################

# Getting LSM from this netcdf file:
id_lsm = Dataset(cf0nc)
LSM = id_lsm.variables['LSM'][0,:]
id_lsm.close()
[ nmn ] = LSM.shape
if nmn != gridsize: print 'PROBLEM: with number of points LSM!'; sys.exit(0)
print 'Shape LSM: ', nmp.shape(LSM)

id_ocean = nmp.where(LSM <= 0.5)
LSM[:] = 1.
LSM[id_ocean] = 0.

cf_out = cd_out+'/masks_T'+str(ysize-1)+'.nc'
f_out = Dataset(cf_out, 'w', format='NETCDF3_CLASSIC')
f_out.createDimension('x' , nbp)
f_out.createDimension('y' , 1)
id_msk1 = f_out.createVariable('A'+cstr+'.msk','f4',('y','x',))
id_msk2 = f_out.createVariable('L'+cstr+'.msk','f4',('y','x',))
id_msk3 = f_out.createVariable('R'+cstr+'.msk','f4',('y','x',))
id_msk1[:] = LSM[:]
id_msk2[:] = LSM[:]
id_msk3[:] = 1. - LSM[:]
f_out.close()
print '\n file '+cf_out+' written!\n'





AREAS = nmp.zeros(gridsize)


