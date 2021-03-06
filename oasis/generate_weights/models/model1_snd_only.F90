!------------------------------------------------------------------------
! Copyright 2010, CERFACS, Toulouse, France.
! All rights reserved. Use is subject to OASIS3 license terms.
!=============================================================================
!
!
PROGRAM model1
  !
  ! Use for netCDF library
  USE netcdf
  ! Use for OASIS communication library
  USE mod_oasis
  !
  ! Use module to read the data
  USE read_all_data
  !
  ! Use module to write the data
  USE write_all_fields
  !
  IMPLICIT NONE

  INCLUDE 'mpif.h'
  !
  ! By default OASIS3 exchanges data in double precision.
  ! To exchange data in single precision with OASIS3, 
  ! the coupler has to be compiled with CPP key "use_realtype_single" 
  ! and the model with CPP key "NO_USE_DOUBLE_PRECISION"
#ifdef NO_USE_DOUBLE_PRECISION
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(6,37)   ! real
#elif defined USE_DOUBLE_PRECISION
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(12,307) ! double
#endif
  !
  CHARACTER(len=30), PARAMETER   :: data_gridname='grids.nc' ! file with the grids
  CHARACTER(len=30), PARAMETER   :: data_maskname='masks.nc' ! file with the masks
  CHARACTER(len=30)              :: data_filename, field_name
  !
  ! Component name (6 characters) same as in the namcouple
  CHARACTER(len=6)   :: comp_name = 'model1'
  CHARACTER(len=128) :: comp_out ! name of the output log file 
  CHARACTER(len=3)   :: chout
  CHARACTER(len=4)   :: cl_grd_src ! name of the source grid
  CHARACTER(len=4)   :: cl_grd_tgt ! name of the target grid
  NAMELIST /grid_source_characteristics/cl_grd_src
  NAMELIST /grid_target_characteristics/cl_grd_tgt
  !
  ! Global grid parameters : 
  INTEGER :: nlon, nlat     ! dimensions in the 2 directions of space
  INTEGER :: ntot           ! total dimension
  INTEGER :: il_paral_size
  INTEGER :: nc             ! number of corners
  INTEGER :: indi_beg, indi_end, indj_beg, indj_end
  !
  DOUBLE PRECISION, DIMENSION(:,:), POINTER   :: globalgrid_lon,globalgrid_lat ! lon, lat of the points
  INTEGER, DIMENSION(:,:), POINTER            :: indice_mask ! mask, 0 == valid point, 1 == masked point  
  !
  INTEGER :: mype, npes ! rank and  number of pe
  INTEGER :: localComm  ! local MPI communicator and Initialized
  INTEGER :: comp_id    ! component identification
  !
  INTEGER, DIMENSION(:), ALLOCATABLE :: il_paral ! Decomposition for each proc
  !
  INTEGER :: ierror, rank, w_unit
  INTEGER :: i, j
  INTEGER :: FILE_Debug=2
  !
  ! Names of exchanged Fields
  CHARACTER(len=8), PARAMETER :: var_name1 = 'FSENDOCN' ! 8 characters field sent by model1 to model2
  !CHARACTER(len=8), PARAMETER :: var_name2 = 'FRECVOCN' ! 8 characters field received by model1 from model2
  !
  ! Used in oasis_def_var and oasis_def_var
  INTEGER                   :: var_id
  INTEGER                   :: var_nodims(2) 
  INTEGER                   :: var_type
  !
  REAL (kind=wp), PARAMETER :: field_ini = -1. ! initialisation of received fields
  !
  INTEGER               ::  ib
  INTEGER, PARAMETER    ::  il_nb_time_steps = 6 ! number of time steps
  INTEGER, PARAMETER    ::  delta_t = 3600       ! time step
  !
  INTEGER                 :: il_flag  ! Flag for grid writing by proc 0
  !
  INTEGER                 :: itap_sec ! Time used in oasis_put/get
  !
  ! Grid parameters definition
  INTEGER                 :: part_id  ! use to connect the partition to the variables
                                      ! in oasis_def_var
  INTEGER                 :: var_actual_shape(4) ! local dimensions of the arrays to the pe
                                                 ! 2 x field rank (= 4 because fields are of rank = 2)
  !
  ! Exchanged local fields arrays
  ! used in routines oasis_put and oasis_get
  REAL (kind=wp), POINTER :: field1_send(:,:)
  !REAL (kind=wp), POINTER :: field2_recv(:,:)
  !
  !++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !   INITIALISATION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  !!!!!!!!!!!!!!!!! OASIS_INIT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  CALL oasis_init_comp (comp_id, comp_name, ierror )
  IF (ierror /= 0) THEN
      WRITE(0,*) 'oasis_init_comp abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id, comp_name,'Problem at line 98')
  ENDIF
  !
  ! Unit for output messages : one file for each process
  CALL MPI_Comm_Rank ( MPI_COMM_WORLD, rank, ierror )
  IF (ierror /= 0) THEN
      WRITE(0,*) 'MPI_Comm_Rank abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 105')
  ENDIF
  !
  w_unit = 100 + rank
  WRITE(chout,'(I3)') w_unit
  comp_out=comp_name//'.out_'//chout
  !
  OPEN(w_unit,file=TRIM(comp_out),form='formatted')
  WRITE (w_unit,*) '-----------------------------------------------------------'
  WRITE (w_unit,*) 'MPI_COMM_WORLD is :',MPI_COMM_WORLD
  WRITE (w_unit,*) TRIM(comp_name), ' Running with reals compiled as kind =',wp
  WRITE (w_unit,*) 'I am component ', TRIM(comp_name), ' rank :',rank
  WRITE (w_unit,*) '----------------------------------------------------------'
  CALL flush(w_unit)
  !      
  !!!!!!!!!!!!!!!!! OASIS_GET_LOCALCOMM !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  CALL oasis_get_localcomm ( localComm, ierror )
  IF (ierror /= 0) THEN
      WRITE (w_unit,*) 'oasis_get_localcomm abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 124')
  ENDIF
  !
  ! Get MPI size and rank
  CALL MPI_Comm_Size ( localComm, npes, ierror )
  IF (ierror /= 0) THEN
      WRITE(w_unit,*) 'MPI_comm_size abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 131')
  ENDIF
  !
  CALL MPI_Comm_Rank ( localComm, mype, ierror )
  IF (ierror /= 0) THEN
      WRITE (w_unit,*) 'MPI_Comm_Rank abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 137')
  ENDIF
  !
  WRITE(w_unit,*) 'I am the ', TRIM(comp_name), ' ', 'comp', comp_id, 'local rank', mype
  WRITE (w_unit,*) 'Number of processors :',npes
  WRITE (w_unit,*) 'Local communicator :', localComm
  CALL flush(w_unit)
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  GRID DEFINITION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  ! Reading global grids.nc and masks.nc netcdf files
  ! Get arguments giving source grid acronym and field type
  ! 
  OPEN(UNIT=70,FILE='name_grids.dat',FORM='FORMATTED')
  READ(UNIT=70,NML=grid_source_characteristics)
  READ(UNIT=70,NML=grid_target_characteristics)
  CLOSE(70)
  !
  !
  ! Reading dimensions of the global grid
  CALL read_dimgrid(nlon,nlat,data_gridname,cl_grd_src,w_unit,FILE_Debug)
  nc=4
  !
  ! Allocation
  ALLOCATE(globalgrid_lon(nlon,nlat), STAT=ierror )
  IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating globalgrid_lon'
  ALLOCATE(globalgrid_lat(nlon,nlat), STAT=ierror )
  IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating globalgrid_lat'
  ALLOCATE(indice_mask(nlon,nlat), STAT=ierror )
  IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating indice_mask'
  !
  ! Read global grid longitudes, latitudes and mask 
  CALL read_grid(nlon,nlat, data_gridname, cl_grd_src, w_unit, FILE_Debug, &
                 globalgrid_lon,globalgrid_lat)
  CALL read_mask(nlon,nlat, data_maskname, cl_grd_src, w_unit, FILE_Debug, &
                 indice_mask)
  !
  WRITE(w_unit,*) 'After grids writing'
  call flush(w_unit)
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  PARTITION DEFINITION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ !
  !
  ! Definition of the partition of the grid (calling oasis_def_partition)
  ntot=nlon*nlat
#ifdef DECOMP_APPLE
  il_paral_size = 3
#elif defined DECOMP_BOX
  il_paral_size = 5
#endif
  ALLOCATE(il_paral(il_paral_size))
  WRITE(w_unit,*) 'After allocate il_paral, il_paral_size', il_paral_size
  call flush(w_unit)
  !
  CALL decomp_def (il_paral,il_paral_size,nlon,nlat,mype,npes,w_unit)
  WRITE(w_unit,*) 'After decomp_def, il_paral = ', il_paral(:)
  call flush(w_unit)
  ! The data are exchanged in the global grid so you do not need to pass 
  ! isize to oasis_def_partition
  CALL oasis_def_partition (part_id, il_paral, ierror)
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ! DEFINITION OF THE LOCAL FIELDS  
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  !!!!!!!!!!!!!!! !!!!!!!!! OASIS_DEF_VAR !!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  !  Define transient variables
  !
  var_nodims(1) = 2    ! Rank of the field array is 2
  var_nodims(2) = 1    ! Bundles always 1 for OASIS3
  var_type = OASIS_Real
  !
  var_actual_shape(1) = 1
  var_actual_shape(2) = il_paral(3)
  var_actual_shape(3) = 1 
#ifdef DECOMP_APPLE
  var_actual_shape(4) = 1
#elif defined DECOMP_BOX
  var_actual_shape(4) = il_paral(4)
#endif
  !
  ! Declaration of the field associated with the partition
  CALL oasis_def_var (var_id,var_name1, part_id, &
     var_nodims, OASIS_Out, var_actual_shape, var_type, ierror)
  IF (ierror /= 0) THEN
      WRITE (w_unit,*) 'oasis_def_var abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 243')
  ENDIF
  !
  !CALL oasis_def_var (var_id,var_name2, part_id, &
  !   var_nodims, OASIS_In, var_actual_shape, var_type, ierror)
  !IF (ierror /= 0) THEN
  !    WRITE (w_unit,*) 'oasis_def_var abort by model1 compid ',comp_id
  !    CALL oasis_abort(comp_id,comp_name,'Problem at line 250')
  !ENDIF
  !
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !         TERMINATION OF DEFINITION PHASE 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !  All processes involved in the coupling must call oasis_enddef; 
  !  here all processes are involved in coupling
  !
  !!!!!!!!!!!!!!!!!! OASIS_ENDDEF !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  CALL oasis_enddef ( ierror )
  IF (ierror /= 0) THEN
      WRITE (w_unit,*) 'oasis_enddef abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 265')
  ENDIF
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ! SEND AND RECEIVE ARRAYS 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  ! Allocate the fields send and received by the model
  !
  !
  ALLOCATE(field1_send(var_actual_shape(2), var_actual_shape(4)), STAT=ierror )
  IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating field1_send'
  !
  !ALLOCATE(field2_recv(var_actual_shape(2), var_actual_shape(4)), STAT=ierror )
  !IF ( ierror /= 0 ) WRITE(w_unit,*) 'Error allocating field2_recv'
  !
  DEALLOCATE(il_paral)
  !
  !!!!!!!!!!!!!!!!!!!!!!!!OASIS_PUT/OASIS_GET !!!!!!!!!!!!!!!!!!!!!! 
  !
  indi_beg=1 ; indi_end=nlon
  indj_beg=((nlat/npes)*mype)+1 
  !
  IF (mype .LT. npes - 1) THEN
      indj_end = (nlat/npes)*(mype+1)
  ELSE
      indj_end = nlat 
  ENDIF
  !
  ! Data exchange 
  ! 
  ! Time loop
  DO ib=1, il_nb_time_steps
    itap_sec = delta_t * (ib-1) ! Time
    !
    ! Get FRECVOCN
    !field2_recv=field_ini
    !CALL oasis_get(var_id,itap_sec, field2_recv, ierror)
    !write(w_unit,*) 'tcx recvf2 ',itap_sec,minval(field2_recv),maxval(field2_recv)
    !IF ( ierror .NE. OASIS_Ok .AND. ierror .LT. OASIS_Recvd) THEN
    !    WRITE (w_unit,*) 'oasis_get abort by model1 compid ',comp_id
    !    CALL oasis_abort(comp_id,comp_name,'Problem at line 309')
    !ENDIF
    !
    CALL function_sent(var_actual_shape(2), var_actual_shape(4), &
       RESHAPE(globalgrid_lon(indi_beg:indi_end,indj_beg:indj_end),&
       (/ var_actual_shape(2), var_actual_shape(4) /)), &
       RESHAPE(globalgrid_lat(indi_beg:indi_end,indj_beg:indj_end),&
       (/ var_actual_shape(2), var_actual_shape(4) /)), &
       field1_send,ib)
    !
    ! Send FSENDOCN
    write(w_unit,*) 'tcx sendf1 ',itap_sec,minval(field1_send),maxval(field1_send)
    CALL oasis_put(var_id,itap_sec, field1_send, ierror)
    IF ( ierror .NE. OASIS_Ok .AND. ierror .LT. OASIS_Sent) THEN
      WRITE (w_unit,*) 'oasis_put abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 320')
    ENDIF
    !
    !
  ENDDO
  !
  WRITE (w_unit,*) 'End of the program'
  CALL flush(w_unit)
  CLOSE (w_unit)
  !
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !         TERMINATION 
  !+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  !
  !!!!!!!!!!!!!!!!!! OASIS_TERMINATE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !
  ! Collective call to terminate the coupling exchanges
  !
  CALL oasis_terminate (ierror)
  IF (ierror /= 0) THEN
      WRITE (w_unit,*) 'oasis_terminate abort by model1 compid ',comp_id
      CALL oasis_abort(comp_id,comp_name,'Problem at line 341')
  ENDIF
  !
END PROGRAM MODEL1
!
