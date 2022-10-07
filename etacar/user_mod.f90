!=======================================================================
!> @file user_mod.f90
!> @brief User input module
!> @author  A. Esquivel  & Isaac Carbajal
!> @date 4/Nov/2021

! Copyright (c) 2021 Guacho Co-Op
!
! This file is part of Guacho-3D.
!
! Guacho-3D is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see http://www.gnu.org/licenses/.
!=======================================================================

!> @brief User imput module
!> @details  This is an attempt to have all input neede from user in a
!! single file
!!!  This module should load additional modules (i.e. star, jet, sn), to
!!  impose initial and boundary conditions (such as sources)

module user_mod

  ! load auxiliary modules
  use two_winds

  implicit none

contains

!> @brief Initializes variables in the module, as well as other
!> modules loaded by user.
!> @n It has to be present, even if empty
subroutine init_user_mod()

  implicit none
  !  initialize modules loaded by user
  call init_two_winds()

end subroutine init_user_mod

!=====================================================================
!> @brief Here the domain is initialized at t=0
!> @param real [out] u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax) :
!! conserved variables
!> @param real [in] time : time in the simulation (code units)
subroutine initial_conditions(u)

  use parameters, only : neq, nxmin, nxmax, nymin, nymax, nzmin, nzmax, &
                         neqdyn, Tempsc, rsc, vsc, rhosc, Psc
  use constants,  only : Kb
  use globals,    only: coords, dx ,dy ,dz

  implicit none
  real, intent(out) :: u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax)

  ! medio uniforme y estatico
  u(1,:,:,:) = 1.66e-24 /rhosc
  u(2,:,:,:) = 0.0
  u(3,:,:,:) = 0.0
  u(4,:,:,:) = 0.0
  u(5,:,:,:) = 1.0e4 * 1.0 * Kb /Psc

  u(6,:,:,:) = 1e-4 * u(1,:,:,:)
  u(7,:,:,:) = 1.0e-5

  call impose_two_winds(u,0.0)

end subroutine initial_conditions

!=====================================================================
!> @brief User Defined Boundary conditions
!> @param real [out] u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax) :
!! conserved variables
!> @param real [in] time : time in the simulation (code units)
!> @param integer [in] order : order (mum of cells to be filled in case
!> domain boundaries are being set)
subroutine impose_user_bc(u,order)

  use parameters, only: neq, nxmin, nxmax, nymin, nymax, nzmin, nzmax
  use globals,    only: time, rank
  implicit none
  real, intent(out) :: u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax)
  integer, intent(in) :: order

  !  In this case the boundary is the same for 1st and second order)
  !  hack to avoid warnings at compile time
  if (order >= 1) then
    call impose_two_winds(u,time)
  end if

end subroutine impose_user_bc

!=======================================================================
!> @brief User Defined source terms
!> This is a generic interrface to add a source term S in the equation
!> of the form:  dU/dt+dF/dx+dG/dy+dH/dz=S
!> @param real [in] pp(neq) : vector of primitive variables
!> @param real [inout] s(neq) : vector with source terms, has to add to
!>  whatever is there, as other modules can add their own sources
!> @param integer [in] i : cell index in the X direction
!> @param integer [in] j : cell index in the Y direction
!> @param integer [in] k : cell index in the Z direction
subroutine get_user_source_terms(pp,s, i, j , k)

  ! Adds the Rad Pressure according to the Beta profile of Bourrier
  use constants,  only : Ggrav
  use parameters, only : nx, ny, nz, nxtot, nytot, nztot, rsc, vsc2,&
                         vsc, neq
  use globals,    only : dx, dy, dz, coords


  implicit none
  integer, intent(in) :: i, j, k
  real, intent(in)    :: pp(neq)
  real, intent(inout) :: s(neq)

  real :: x(Nsources), y(Nsources), z(Nsources), GM(Nsources),       &
          rad2(Nsources), xc, yc, zc
  integer :: l

  GM(:) = Ggrav*Mass(:) / rsc /vsc2

  !   get cell position
  xc=(real(i+coords(0)*nx-nxtot/2)-0.5)*dx
  yc=(real(j+coords(1)*ny-nytot/2)-0.5)*dy
  zc=(real(k+coords(2)*nz-nztot/2)-0.5)*dz

  ! calculate distance from the sources
  x(1)=xc-xp(1)
  y(1)=yc-yp(1)
  z(1)=zc-zp(1)
  rad2(1) = x(1)**2 +y(1)**2 + z(1)**2

  x(2)=xc-xp(2)
  y(2)=yc-yp(2)
  z(2)=zc-zp(2)
  rad2(2) = x(2)**2 +y(2)**2 + z(2)**2

  !  update spurce terms with gravity
  do l=1, Nsources
    ! momenta
    s(2)= s(2)-pp(1)*GM(l)*x(l)/(rad2(l)**1.5)
    s(3)= s(3)-pp(1)*GM(l)*y(l)/(rad2(l)**1.5)
    s(4)= s(4)-pp(1)*GM(l)*z(l)/(rad2(l)**1.5)
    ! energy
    s(5)= s(5)-pp(1)*GM(l)*( pp(2)*x(l) +pp(3)*y(l) +pp(4)*z(l) )  &
          /(rad2(l)**1.5 )
  end do



end subroutine get_user_source_terms


!=======================================================================

end module user_mod