! written by jxzou at 20200623

subroutine read_natom_from_gjf(gjfname, natom)
 implicit none
 integer :: i, fid, nblank
 integer, intent(out) :: natom
 integer, parameter :: iout = 6
 character(len=240) :: buf
 character(len=240), intent(in) :: gjfname

 nblank = 0
 open(newunit=fid,file=TRIM(gjfname),status='old',position='rewind')
 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  if(LEN_TRIM(buf) == 0) nblank = nblank + 1
  if(nblank == 2) exit
 end do ! for while

 if(i /= 0) then
  write(iout,'(A)') 'ERROR in subroutine read_natom_from_gjf: incomplete file '//TRIM(gjfname)
  stop
 end if

 read(fid,'(A)') buf ! skip charge and mult

 natom = 0
 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  if(LEN_TRIM(buf) == 0) exit
  natom = natom + 1
 end do ! for while

 close(fid)
 return
end subroutine read_natom_from_gjf

subroutine read_elem_and_coor_from_gjf(gjfname, natom, elem, coor, charge, mult)
 implicit none
 integer :: i, k, fid, nblank
 integer, intent(in) :: natom
 integer, intent(out) :: charge, mult
 integer, parameter :: iout = 6
 real(kind=8), intent(out) :: coor(3,natom)
 character(len=2), intent(out) :: elem(natom)
 character(len=240) :: buf
 character(len=240), intent(in) :: gjfname

 charge = 0; mult = 1; coor = 0.0d0

 open(newunit=fid,file=TRIM(gjfname),status='old',position='rewind')
 do while(.true.)
  read(fid,'(A)',iostat=i) buf
  if(i /= 0) exit
  if(LEN_TRIM(buf) == 0) nblank = nblank + 1
  if(nblank == 2) exit
 end do ! for while

 if(i /= 0) then
  write(iout,'(A)') 'ERROR in subroutine read_elem_and_coor_from_gjf: incomplete file '//TRIM(gjfname)
  stop
 end if

 read(fid,*) charge, mult

 do i = 1, natom, 1
  read(fid,*,iostat=k) elem(i), coor(1:3,i)
  if(k /= 0) then
   write(iout,'(A)') 'ERROR in subroutine read_elem_and_coor_from_gjf: only 4-column&
                    & format is supported.'
   stop
  end if
 end do ! for i

 close(fid)
 return
end subroutine read_elem_and_coor_from_gjf

! generate a RHF/UHF .gjf file
subroutine generate_hf_gjf(gjfname, natom, elem, coor, charge, mult, basis,&
                           uhf, cart, mem, nproc)
 implicit none
 integer :: i, fid
 integer, intent(in) :: natom, charge, mult, mem, nproc
 integer, parameter :: iout = 6
 real(kind=8), intent(in) :: coor(3,natom)
 character(len=2), intent(in) :: elem(natom)
 character(len=7), intent(in) :: basis
 character(len=240) :: chkname
 character(len=240), intent(in) :: gjfname
 logical, intent(in) :: uhf, cart

 i = index(gjfname, '.gjf', back=.true.)
 chkname = gjfname(1:i-1)//'.chk'

 open(newunit=fid,file=TRIM(gjfname),status='replace')
 write(fid,'(A)') '%chk='//TRIM(chkname)
 write(fid,'(A,I0,A)') '%mem=',mem,'GB'
 write(fid,'(A,I0)') '%nprocshared=', nproc
 write(fid,'(A)',advance='no') '#p nosymm int=nobasistransform '

 if(mult == 1) then ! singlet
  if(uhf) then
   write(fid,'(A)',advance='no') 'UHF/'//TRIM(basis)//' guess=mix stable=opt '
  else
   write(fid,'(A)',advance='no') 'RHF/'//TRIM(basis)//' '
  end if
 else               ! not singlet
  if(uhf) then
   write(fid,'(A)',advance='no') 'UHF/'//TRIM(basis)//' stable=opt '
  else
   write(iout,'(A)') 'ERROR in subroutine generate_hf_gjf: this molecule is&
                    & not singlet, but UHF is not specified.'
   stop
  end if
 end if

 if(cart) then
  write(fid,'(A)') '6D 10F'
 else
  write(fid,'(A)') '5D 7F'
 end if

 write(fid,'(/,A,/)') 'HF file generated by AutoMR of MOKIT'
 write(fid,'(I0,1X,I0)') charge, mult

 do i = 1, natom, 1
  write(fid,'(A2,3X,3F15.8)') elem(i), coor(1:3,i)
 end do ! for i

 write(fid,'(/)',advance='no')
 close(fid)
 return
end subroutine generate_hf_gjf
