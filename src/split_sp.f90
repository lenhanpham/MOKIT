! written by jxzou at 20220817: move 'SP'/'L' related subroutines here

! diagonal elements of overlap matrix using Cartesian functions (6D 10F)
! this module is used in fch2py, py2fch and chk2py
module Sdiag_parameter
 implicit none
 real(kind=8), parameter :: PI = 4d0*DATAN(1d0)
 real(kind=8), parameter :: p1 = 2d0*DSQRT(PI/15d0)
 real(kind=8), parameter :: p2 = 2d0*DSQRT(PI/5d0)
 real(kind=8), parameter :: p3 = 2d0*DSQRT(PI/7d0)
 real(kind=8), parameter :: p4 = 2d0*DSQRT(PI/35d0)
 real(kind=8), parameter :: p5 = 2d0*DSQRT(PI/105d0)
 real(kind=8), parameter :: p6 = (2d0/3d0)*DSQRT(PI)
 real(kind=8), parameter :: p7 = (2d0/3d0)*DSQRT(PI/7d0)
 real(kind=8), parameter :: p8 = (2d0/3d0)*DSQRT(PI/35d0)
 real(kind=8), parameter :: p9 = 2d0*DSQRT(PI/11d0)
 real(kind=8), parameter :: p10 = (2d0/3d0)*DSQRT(PI/11d0)
 real(kind=8), parameter :: p11 = 2d0*DSQRT(PI/231d0)
 real(kind=8), parameter :: p12 = (2d0/3d0)*DSQRT(PI/77d0)
 real(kind=8), parameter :: p13 = 2d0*DSQRT(PI/1155d0)
 real(kind=8), parameter :: Sdiag_d(6)  = [p2,p1,p1,p2,p1,p2]
 real(kind=8), parameter :: Sdiag_f(10) = [p3,p4,p4,p4,p5,p4,p3,p4,p4,p3]
 real(kind=8), parameter :: Sdiag_g(15) = [p6,p7,p7,p5,p8,p5,p7,p8,p8,p7,p6,p7,p5,p7,p6]
 real(kind=8), parameter :: Sdiag_h(21) = &
  [p9,p10,p10,p11,p12,p11,p11,p13,p13,p11,p10,p12,p13,p12,p10,p9,p10,p11,p11,p10,p9]
end module Sdiag_parameter

module root_parameter
 implicit none
 real(kind=8), parameter :: root3   = DSQRT(3d0)     ! SQRT(3)
 real(kind=8), parameter :: root9   = 3d0            ! SQRT(9)
 real(kind=8), parameter :: root15  = DSQRT(15d0)    ! SQRT(15)
 real(kind=8), parameter :: root45  = DSQRT(45d0)    ! SQRT(45)
 real(kind=8), parameter :: root105 = DSQRT(105d0)   ! SQRT(105)
 real(kind=8), parameter :: root945 = DSQRT(945d0)   ! SQRT(945)
end module root_parameter

! split the 'L' into 'S' and 'P'
subroutine split_L_func(k, shell_type, shell_to_atom_map, length)
 implicit none
 integer i, k0
 integer,intent(in) :: k
 integer,intent(inout) :: shell_type(2*k), shell_to_atom_map(2*k)
 integer,intent(out) :: length
 integer,allocatable :: temp1(:), temp2(:)

 k0 = 2*k
 length = k
 ! set initial values for arrays shell_type, assume 15 will not be used
 shell_type(k+1:k0) = 15
 i = 1

 do while(shell_type(i) /= 15)
  if(shell_type(i) /= -1) then
   i = i + 1
   cycle
  end if
  shell_type(i) = 0
  allocate( temp1(i+1 : k0-1), temp2(i+1 : k0-1) )
  temp1(i+1 : k0-1) = shell_type(i+1 : k0-1)
  shell_type(i+2 : k0) = temp1(i+1 : k0-1)
  temp2(i+1 : k0-1) = shell_to_atom_map(i+1 : k0-1)
  shell_to_atom_map(i+2 : k0) = temp2(i+1 : k0-1)
  deallocate(temp1, temp2)
  shell_type(i+1) = 1
  shell_to_atom_map(i+1) = shell_to_atom_map(i)
  i = i + 2
 end do ! for while

 length = i - 1
 shell_type(i : k0) = 0
end subroutine split_L_func

! sort the shell_type, shell_to_atom_map by ascending order
! MOs will be adjusted accordingly
subroutine sort_shell_and_mo(ilen, shell_type, shell_to_atom_map, nbf, nif, coeff2)
 implicit none
 integer :: i, j, k, natom
 integer :: ibegin, iend, jbegin, jend
 integer, parameter :: ntype = 10
 integer, parameter :: num0(ntype) = [0, 1, -2, 2, -3, 3, -4, 4, -5, 5]
 integer, parameter :: num1(ntype) = [1, 3, 5, 6, 7, 10, 9, 15, 11, 21]
 !                                    S  P  5D 6D 7F 10F 9G 15G 11H 21H
 integer :: num(ntype)
 integer,intent(in) :: ilen, nbf, nif
 integer,intent(inout) :: shell_type(ilen), shell_to_atom_map(ilen)
 integer,allocatable :: ith(:), ith_bas(:), tmp_type(:)
 real(kind=8),intent(inout) :: coeff2(nbf,nif)

 ! find the number of atoms
 natom = shell_to_atom_map(ilen)

 allocate(ith(0:natom), ith_bas(0:natom))
 ith = 0
 ith_bas = 0

 ! find the end position of each atom in array shell_to_atom_map
 do i = 1, natom, 1
  ith(i) = count(shell_to_atom_map==i) + ith(i-1)
 end do ! for i

 ! find the end position of basis functions between two atoms
 do i = 1, natom, 1
  ibegin = ith(i-1) + 1
  iend = ith(i)
  allocate(tmp_type(ibegin:iend))
  tmp_type = 0
  tmp_type = shell_type(ibegin:iend)
  num = 0
  do j = 1, ntype, 1
   num(j) = count(tmp_type == num0(j))
  end do ! for j
  k = 0
  do j = 1, ntype, 1
   k = k + num(j)*num1(j)
  end do ! for j
  ith_bas(i) = ith_bas(i-1) + k
  deallocate(tmp_type)
 end do ! for i

 ! adjust the MOs in each atom
 do i = 1, natom, 1
  ibegin = ith(i-1) + 1
  iend = ith(i)
  jbegin = ith_bas(i-1) + 1
  jend = ith_bas(i)
  call sort_shell_and_mo_in_each_atom(iend-ibegin+1, shell_type(ibegin:iend), &
                                      jend-jbegin+1, nif, coeff2(jbegin:jend,1:nif))
 end do ! for i
 ! adjust the MOs in each atom done

 deallocate(ith, ith_bas)
end subroutine sort_shell_and_mo

subroutine sort_shell_and_mo_in_each_atom(ilen1, shell_type, ilen2, nif, coeff2)
 implicit none
 integer :: i, tmp_type
 integer :: ibegin, iend, jbegin, jend
 integer,parameter :: ntype = 10
 integer,parameter :: num1(ntype) = [1, 3, 5, 6, 7, 10, 9, 15, 11, 21]
 !                                   S  P  5D 6D 7F 10F 9G 15G 11H 21H
 integer,parameter :: rnum(-5:5) = [9, 7, 5, 3, 0, 1, 2, 4, 6, 8, 10]

 integer,intent(in) :: nif, ilen1, ilen2
 integer,intent(inout) :: shell_type(ilen1)
 integer,allocatable :: ith_bas(:)
 real(kind=8),intent(inout) :: coeff2(ilen2,nif)
 real(kind=8),allocatable :: tmp_coeff1(:,:), tmp_coeff2(:,:)
 logical :: sort_done

 tmp_type = 0

 ! find the end position of basis functions within an atom
 allocate(ith_bas(0:ilen1))
 ith_bas = 0
 do i = 1, ilen1, 1
  ith_bas(i) = ith_bas(i-1) + num1(rnum(shell_type(i)))
 end do ! for i

 sort_done = .false.
 do while(.not. sort_done)
  sort_done = .true.
  do i = 1, ilen1-1, 1
    if(shell_type(i) == 0) cycle
    if(ABS(shell_type(i+1)) >= ABS(shell_type(i))) cycle
    sort_done = .false.
    tmp_type = shell_type(i+1)
    shell_type(i+1) = shell_type(i)
    shell_type(i) = tmp_type
    ibegin = ith_bas(i-1) + 1
    iend = ith_bas(i)
    jbegin = ith_bas(i) + 1
    jend = ith_bas(i+1)
    allocate(tmp_coeff1(ibegin:iend,nif), tmp_coeff2(jbegin:jend,nif))
    tmp_coeff1 = 0d0
    tmp_coeff2 = 0d0
    tmp_coeff1 = coeff2(ibegin:iend,:)
    tmp_coeff2 = coeff2(jbegin:jend,:)
    ith_bas(i) = ibegin+jend-jbegin
    coeff2(ibegin: ith_bas(i),:) = tmp_coeff2
    ith_bas(i+1) = jend+iend-jbegin+1
    coeff2(ibegin+jend-jbegin+1: ith_bas(i+1),:) = tmp_coeff1
    deallocate(tmp_coeff1, tmp_coeff2)
  end do ! for i
 end do ! for while

 deallocate(ith_bas)
end subroutine sort_shell_and_mo_in_each_atom

! sort the shell_type, shell2atom_map by ascending order,
! indices of MOs will be adjusted accordingly
subroutine sort_shell_and_mo_idx(ilen, shell_type, shell2atom_map, nbf, idx)
 implicit none
 integer :: i, j, k
 integer :: ibegin, iend, natom
 integer :: jbegin, jend
 integer, parameter :: ntype = 10
 integer, parameter :: num0(ntype) = [0, 1, -2, 2, -3, 3, -4, 4, -5, 5]
 integer, parameter :: num1(ntype) = [1, 3, 5, 6, 7, 10, 9, 15, 11, 21]
 !                                    S  P  5D 6D 7F 10F 9G 15G 11H 21H
 integer :: num(ntype)
 integer, intent(in) :: ilen, nbf
 integer, intent(inout) :: shell_type(ilen), shell2atom_map(ilen)
 integer, intent(inout) :: idx(nbf)
 integer, allocatable :: ith(:), ith_bas(:), tmp_type(:)

 ! find the number of atoms
 natom = shell2atom_map(ilen)

 allocate(ith(0:natom), ith_bas(0:natom))
 ith = 0
 ith_bas = 0

 ! find the end position of each atom in array shell2atom_map
 do i = 1, natom, 1
  ith(i) = count(shell2atom_map==i) + ith(i-1)
 end do

 ! find the end position of basis functions between two atoms
 do i = 1, natom, 1
  ibegin = ith(i-1) + 1
  iend = ith(i)
  allocate(tmp_type(ibegin:iend), source=0)
  tmp_type = shell_type(ibegin:iend)
  num = 0

  do j = 1, ntype, 1
   num(j) = count(tmp_type == num0(j))
  end do ! for j

  k = 0
  do j = 1, ntype, 1
   k = k + num(j)*num1(j)
  end do ! for j

  ith_bas(i) = ith_bas(i-1) + k
  deallocate(tmp_type)
 end do ! for i

 ! adjust the indices of MOs in each atom
 do i = 1, natom, 1
  ibegin = ith(i-1) + 1
  iend = ith(i)
  jbegin = ith_bas(i-1) + 1
  jend = ith_bas(i)
  call sort_shell_and_mo_in_each_atom_idx(iend-ibegin+1, shell_type(ibegin:iend),&
  & jend-jbegin+1, idx(jbegin:jend))
 end do ! for i

 deallocate(ith, ith_bas)
end subroutine sort_shell_and_mo_idx

subroutine sort_shell_and_mo_in_each_atom_idx(ilen1, shell_type, ilen2, idx)
 implicit none
 integer :: i, tmp_type, ibegin, iend, jbegin, jend
 integer, parameter :: ntype = 10
 integer, parameter :: num1(ntype) = [1, 3, 5, 6, 7, 10, 9, 15, 11, 21]
 !                                   S  P  5D 6D 7F 10F 9G 15G 11H 21H
 integer, parameter :: rnum(-5:5) = [9, 7, 5, 3, 0, 1, 2, 4, 6, 8, 10]
 integer, intent(in) :: ilen1, ilen2
 integer, intent(inout) :: shell_type(ilen1), idx(ilen2)
 integer, allocatable :: ith_bas(:), idx1(:), idx2(:)
 logical :: sort_done

 tmp_type = 0

 ! find the end position of basis functions within an atom
 allocate(ith_bas(0:ilen1), source=0)
 do i = 1, ilen1, 1
  ith_bas(i) = ith_bas(i-1) + num1(rnum(shell_type(i)))
 end do ! for i

 sort_done = .false.

 do while(.not. sort_done)
  sort_done = .true.

  do i = 1, ilen1-1, 1
    if(shell_type(i) == 0) cycle
    if(ABS(shell_type(i+1)) >= ABS(shell_type(i))) cycle

    sort_done = .false.
    tmp_type = shell_type(i+1)
    shell_type(i+1) = shell_type(i)
    shell_type(i) = tmp_type
    ibegin = ith_bas(i-1) + 1; iend = ith_bas(i)
    jbegin = ith_bas(i) + 1  ; jend = ith_bas(i+1)
    allocate(idx1(ibegin:iend), source=idx(ibegin:iend))
    allocate(idx2(jbegin:jend), source=idx(jbegin:jend))
    ith_bas(i) = ibegin + jend - jbegin
    idx(ibegin:ith_bas(i)) = idx2
    ith_bas(i+1) = jend + iend - jbegin + 1
    idx(ith_bas(i)+1: ith_bas(i+1)) = idx1
    deallocate(idx1, idx2)
  end do ! for i
 end do ! for while

 deallocate(ith_bas)
end subroutine sort_shell_and_mo_in_each_atom_idx

subroutine fch2inporb_permute_5d(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(5) = [5, 3, 1, 2, 4]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(5,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical d functions in Gaussian
! To: the order of spherical d functions in Molcas
! 1    2    3    4    5
! d0 , d+1, d-1, d+2, d-2
! d-2, d-1, d0 , d+1, d+2

 allocate(coeff2(5,nif), source=coeff)
 forall(i = 1:5) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_5d

subroutine fch2inporb_permute_6d(nif,coeff)
 use root_parameter, only: root3
 implicit none
 integer :: i
 integer, parameter :: order(6) = [1, 4, 5, 2, 6, 3]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(6,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian d functions in Gaussian
! To: the order of Cartesian d functions in Molcas
! 1  2  3  4  5  6
! XX,YY,ZZ,XY,XZ,YZ
! XX,XY,XZ,YY,YZ,ZZ

 forall(i = 1:3) coeff(i,:) = coeff(i,:)/root3
 allocate(coeff2(6,nif), source=coeff)
 forall(i = 1:6) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_6d

subroutine fch2inporb_permute_7f(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(7) = [7, 5, 3, 1, 2, 4, 6]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(7,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical f functions in Gaussian
! To: the order of spherical f functions in Molcas
! 1    2    3    4    5    6    7
! f0 , f+1, f-1, f+2, f-2, f+3, f-3
! f-3, f-2, f-1, f0 , f+1, f+2, f+3

 allocate(coeff2(7,nif), source=coeff)
 forall(i = 1:7) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_7f

subroutine fch2inporb_permute_10f(nif,coeff)
 use root_parameter, only: root3, root15
 implicit none
 integer :: i
 integer, parameter :: order(10) = [1, 5, 6, 4, 10, 7, 2, 9, 8, 3]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(10,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian f functions in Gaussian
! To: the order of Cartesian f functions in Molcas
! 1   2   3   4   5   6   7   8   9   10
! XXX,YYY,ZZZ,XYY,XXY,XXZ,XZZ,YZZ,YYZ,XYZ
! XXX,XXY,XXZ,XYY,XYZ,XZZ,YYY,YYZ,YZZ,ZZZ

 forall(i = 1:3) coeff(i,:) = coeff(i,:)/root15
 forall(i = 4:9) coeff(i,:) = coeff(i,:)/root3
 allocate(coeff2(10,nif), source=coeff)
 forall(i = 1:10) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_10f

subroutine fch2inporb_permute_9g(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(9) = [9, 7, 5, 3, 1, 2, 4, 6, 8]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(9,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical g functions in Gaussian
! To: the order of spherical g functions in Molcas
! 1    2    3    4    5    6    7    8    9
! g0 , g+1, g-1, g+2, g-2, g+3, g-3, g+4, g-4
! g-4, g-3, g-2, g-1, g0 , g+1, g+2, g+3, g+4

 allocate(coeff2(9,nif), source=coeff)
 forall(i = 1:9) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_9g

subroutine fch2inporb_permute_15g(nif,coeff)
 use root_parameter, only: root3, root9, root15, root105
 implicit none
 integer :: i
 integer, intent(in) :: nif
 real(kind=8), parameter :: ratio(15) = [root105, root15, root9, root15, root105, &
  root15, root3, root3, root15, root9, root3, root9, root15, root15, root105]
 real(kind=8), intent(inout) :: coeff(15,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian g functions in Gaussian
! To: the order of Cartesian g functions in Molcas
! 1    2    3    4    5    6    7    8    9    10   11   12   13   14   15
! ZZZZ,YZZZ,YYZZ,YYYZ,YYYY,XZZZ,XYZZ,XYYZ,XYYY,XXZZ,XXYZ,XXYY,XXXZ,XXXY,XXXX
! xxxx,xxxy,xxxz,xxyy,xxyz,xxzz,xyyy,xyyz,xyzz,xzzz,yyyy,yyyz,yyzz,yzzz,zzzz

 forall(i = 1:15) coeff(i,:) = coeff(i,:)/ratio(i)
 allocate(coeff2(15,nif), source=coeff)
 forall(i = 1:15) coeff(i,:) = coeff2(16-i,:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_15g

subroutine fch2inporb_permute_11h(nif,coeff)
 implicit none
 integer :: i
 integer, parameter :: order(11) = [11, 9, 7, 5, 3, 1, 2, 4, 6, 8, 10]
 integer, intent(in) :: nif
 real(kind=8), intent(inout) :: coeff(11,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of spherical h functions in Gaussian
! To: the order of spherical h functions in Molcas
! 1    2    3    4    5    6    7    8    9    10   11
! h0 , h+1, h-1, h+2, h-2, h+3, h-3, h+4, h-4, h+5, h-5
! h-5, h-4, h-3, h-2, h-1, h0 , h+1, h+2, h+3, h+4, h+5

 allocate(coeff2(11,nif), source=coeff)
 forall(i = 1:11) coeff(i,:) = coeff2(order(i),:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_11h

subroutine fch2inporb_permute_21h(nif,coeff)
 use root_parameter
 implicit none
 integer :: i
 integer, intent(in) :: nif
 real(kind=8), parameter :: ratio(21) = [root945, root105, root45, root45, root105, &
  root945, root105, root15, root9, root15, root105, root45, root9, root9, root45, &
  root45, root15, root45, root105, root105, root945]
 real(kind=8), intent(inout) :: coeff(21,nif)
 real(kind=8), allocatable :: coeff2(:,:)
! From: the order of Cartesian h functions in Gaussian
! To: the order of Cartesian h functions in Molcas
! 1     2     3     4     5     6     7     8     9     10    11    12    13    14    15    16    17    18    19    20    21
! ZZZZZ,YZZZZ,YYZZZ,YYYZZ,YYYYZ,YYYYY,XZZZZ,XYZZZ,XYYZZ,XYYYZ,XYYYY,XXZZZ,XXYZZ,XXYYZ,XXYYY,XXXZZ,XXXYZ,XXXYY,XXXXZ,XXXXY,XXXXX
! xxxxx,xxxxy,xxxxz,xxxyy,xxxyz,xxxzz,xxyyy,xxyyz,xxyzz,xxzzz,xyyyy,xyyyz,xyyzz,xyzzz,xzzzz,yyyyy,yyyyz,yyyzz,yyzzz,yzzzz,zzzzz

 forall(i = 1:21) coeff(i,:) = coeff(i,:)/ratio(i)
 allocate(coeff2(21,nif), source=coeff)
 forall(i = 1:21) coeff(i,:) = coeff2(22-i,:)
 deallocate(coeff2)
end subroutine fch2inporb_permute_21h

subroutine fch2inporb_permute_sph(n5dmark, n7fmark, n9gmark, n11hmark, k, d_mark, &
                                  f_mark, g_mark, h_mark, nbf, nif, coeff)
 implicit none
 integer :: i
 integer, intent(in) :: n5dmark, n7fmark, n9gmark, n11hmark, k, nbf, nif
 integer, intent(in) :: d_mark(k), f_mark(k), g_mark(k), h_mark(k)
 real(kind=8), intent(inout) :: coeff(nbf,nif)

 if(n5dmark==0 .and. n7fmark==0 .and. n9gmark==0 .and. n11hmark==0) return

 do i = 1, n5dmark, 1
  call fch2inporb_permute_5d(nif, coeff(d_mark(i):d_mark(i)+4,:))
 end do
 do i = 1, n7fmark, 1
  call fch2inporb_permute_7f(nif, coeff(f_mark(i):f_mark(i)+6,:))
 end do
 do i = 1, n9gmark, 1
  call fch2inporb_permute_9g(nif, coeff(g_mark(i):g_mark(i)+8,:))
 end do
 do i = 1, n11hmark, 1
  call fch2inporb_permute_11h(nif, coeff(h_mark(i):h_mark(i)+10,:))
 end do
end subroutine fch2inporb_permute_sph

subroutine fch2inporb_permute_cart(n6dmark, n10fmark, n15gmark, n21hmark, k, d_mark, &
                                   f_mark, g_mark, h_mark, nbf, nif, coeff)
 implicit none
 integer :: i
 integer, intent(in) :: n6dmark, n10fmark, n15gmark, n21hmark, k, nbf, nif
 integer, intent(in) :: d_mark(k), f_mark(k), g_mark(k), h_mark(k)
 real(kind=8), intent(inout) :: coeff(nbf,nif)

 if(n6dmark==0 .and. n10fmark==0 .and. n15gmark==0 .and. n21hmark==0) return

 do i = 1, n6dmark, 1
  call fch2inporb_permute_6d(nif,coeff(d_mark(i):d_mark(i)+5,:))
 end do
 do i = 1, n10fmark, 1
  call fch2inporb_permute_10f(nif,coeff(f_mark(i):f_mark(i)+9,:))
 end do
 do i = 1, n15gmark, 1
  call fch2inporb_permute_15g(nif,coeff(g_mark(i):g_mark(i)+14,:))
 end do
 do i = 1, n21hmark, 1
  call fch2inporb_permute_21h(nif,coeff(h_mark(i):h_mark(i)+20,:))
 end do
end subroutine fch2inporb_permute_cart

