!=======================================================================
!> @file network.f90
!> @brief chemical network module
!> @author P. Rivera, A. Rodriguez, A. Castellanos,  A. Raga and A. Esquivel
!> @date 4/May/2016

! Copyright (c) 2020 Guacho Co-Op
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
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see http://www.gnu.org/licenses/.
!=======================================================================

!> @brief Chemical/atomic network module
!> @details this module should be generated by an interface code.

 module network

  implicit none

 ! number of species
  integer, parameter :: n_spec = 5

  ! number of equilibrium species
  integer, parameter:: nequil = 2

  ! number of total elements
  integer, parameter :: n_elem = 1

  ! number of non-equilibrium equations
  integer, parameter :: n_nequ = n_spec - nequil

  !  first index for the species in the global array
  integer, parameter :: n1_chem = 7

  ! indexes of the different species
  integer, parameter :: Hsp = 1  ! star ionized H
  integer, parameter :: Hs0 = 2  ! star neutral H
  integer, parameter :: Hpp = 3  !  ionized H
  integer, parameter :: Hp0 = 4  !  n1eutral H
  integer, parameter :: ie  = 5  ! electron density

  ! indexes of the equilibrium species
  integer, parameter :: Ht = 1

  ! number of reaction rates
  integer, parameter :: n_reac = 5

  ! indexes of the different rates
  integer, parameter :: alpha = 1
  integer, parameter :: coll  = 2
  integer, parameter :: beta  = 3
  integer, parameter :: phiH  = 4
  integer, parameter :: phiC  = 5

 contains

!=======================================================================

subroutine derv(y,rate,dydt,y0)

  implicit none
  real (kind=8), intent(in)  ::   y0(n_elem)
  real (kind=8), intent(in)  ::    y(n_spec)
  real (kind=8), intent(out) :: dydt(n_spec)
  real (kind=8), intent(in)  :: rate(n_reac)

  dydt(Hsp)= rate(coll)*y(Hs0)*y(ie)  - rate(alpha)*y(Hsp)*y(ie) + &
             rate(beta)*y(Hs0)*y(Hpp) - rate(beta)*y(Hsp)*y(Hp0) + &
             rate(phiH)*y(Hs0)

  dydt(Hs0) = - dydt(Hsp)

  dydt(Hpp)= rate(coll)*y(Hp0)*y(ie)  - rate(alpha)*y(Hpp)*y(ie) + &
             rate(beta)*y(Hp0)*y(Hsp) - rate(beta)*y(Hpp)*y(Hs0) + &
             rate(phiC)*y(Hp0)

  !conservation species
  dydt(Hp0) = - y0(Ht) + y(Hsp)+ y(Hs0)+ y(Hpp)+ y(Hp0)
  dydt(ie ) = - y(ie) + y(Hsp) + y(Hpp)

   end subroutine derv

!=======================================================================

subroutine get_jacobian(y,jacobian,rate)

  implicit none
  real (kind=8), intent(in)  :: y(n_spec)
  real (kind=8), intent(out) :: jacobian(n_spec,n_spec)
  real (kind=8), intent(in)  :: rate(n_reac)

  !Hsp
  jacobian(Hsp, Hsp) = - rate(alpha)*y(ie ) - rate(beta)*y(Hp0)
  jacobian(Hsp, Hs0) =   rate(coll )*y(ie ) + rate(beta)*y(Hpp) + rate(phiH)
  jacobian(Hsp, Hpp) =   rate(beta )*y(Hs0)
  jacobian(Hsp, Hp0) = - rate(beta )*y(Hsp)
  jacobian(Hsp, ie ) =   rate(coll )*y(Hs0) - rate(alpha)*y(Hsp)

  !Hs0
  jacobian(Hs0, Hsp) = - jacobian(Hsp, Hsp)
  jacobian(Hs0, Hs0) = - jacobian(Hsp, Hs0)
  jacobian(Hs0, Hpp) = - jacobian(Hsp, Hpp)
  jacobian(Hs0, Hp0) = - jacobian(Hsp, Hp0)
  jacobian(Hs0, ie ) = - jacobian(Hsp, ie )

  !Hpp
  jacobian(Hpp, Hsp) =   rate(beta )*y(Hp0)
  jacobian(Hpp, Hs0) = - rate(beta )*y(Hpp)
  jacobian(Hpp, Hpp) = - rate(alpha)*y(ie ) - rate(beta)*y(Hs0)
  jacobian(Hpp, Hp0) =   rate(coll )*y(ie ) + rate(beta)*y(Hsp) + rate(phiC)
  jacobian(Hpp, ie ) =   rate(coll )*y(Hp0) - rate(alpha)*y(Hpp)

  !Htot
  jacobian(Hp0, Hsp) = 1.
  jacobian(Hp0, Hs0) = 1.
  jacobian(Hp0, Hpp) = 1.
  jacobian(Hp0, Hp0) = 1.
  jacobian(Hp0, ie ) = 0.

  !ne
  jacobian(ie , Hsp) =  1.
  jacobian(ie , Hs0) =  0.
  jacobian(ie , Hpp) =  1.
  jacobian(ie , Hp0) =  0.
  jacobian(ie , ie ) = -1.

end subroutine get_jacobian

!=======================================================================

subroutine get_reaction_rates(rate,T,phiHot,phiCold)
  implicit none
  real (kind=8), intent(in)                    :: T, phiHot, phiCold
  real (kind=8), dimension(n_reac),intent(out) ::rate

  rate(alpha) = 2.55e-13*(1.e4/T)**0.79
  rate(coll ) = 5.83e-11*sqrt(T)*exp(-157828./T)
  rate(beta ) = 4.0E-08
  rate(phiH ) = phiHot
  rate(phiC ) = phiCold

end subroutine get_reaction_rates

!=======================================================================

subroutine nr_init(y,y0)
  implicit none
  real, intent(out) :: y(n_spec)
  real, intent(in ) :: y0(n_elem)
  real :: yhi

  yhi=y0(Ht)

  y(Hsp) = 0.49* yhi
  y(Hs0) = 0.01*yhi
  y(Hpp) = 0.25*yhi
  y(Hp0) = 0.25*yhi
  y(ie ) = y(Hsp) + y(Hpp)

  return
end subroutine nr_init

!=======================================================================

logical function check_no_conservation(y,y0_in)
  implicit none
  real, intent(in)  :: y(n_spec)
  real, intent(in ) :: y0_in  (n_elem)
  real              :: y0_calc(n_elem)
  integer           :: i

  check_no_conservation = .false.

  y0_calc(Ht)= y(Hsp) + y(Hs0) + y(Hpp) + y(Hp0)

  do i = 1, n_elem
    if ( y0_calc(i) > 1.001*y0_in(i) ) check_no_conservation = .true.
  end do

end function check_no_conservation

!=======================================================================

end module network

!=======================================================================