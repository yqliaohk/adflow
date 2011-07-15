!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
!
!
!      ******************************************************************
!      *                                                                *
!      * File:          inviscidUpwindFlux.f90                          *
!      * Author:        Edwin van der Weide                             *
!      * Starting date: 03-25-2003                                      *
!      * Last modified: 10-29-2007                                      *
!      *                                                                *
!      ******************************************************************
!
SUBROUTINE INVISCIDUPWINDFLUX_CD(finegrid)
  USE INPUTPHYSICS_SPATIAL_D
  USE ITERATION_SPATIAL_D
  USE CGNSGRID_SPATIAL_D
  USE INPUTDISCRETIZATION_SPATIAL_D
  USE CONSTANTS_SPATIAL_D
  USE BLOCKPOINTERS_SPATIAL_D
  USE FLOWVARREFSTATE_SPATIAL_D
  IMPLICIT NONE
!
!      ******************************************************************
!      *                                                                *
!      * inviscidUpwindFlux computes the artificial dissipation part of *
!      * the Euler fluxes by means of an approximate solution of the 1D *
!      * Riemann problem on the face. For first order schemes,          *
!      * fineGrid == .false., the states in the cells are assumed to    *
!      * be constant; for the second order schemes on the fine grid a   *
!      * nonlinear reconstruction of the left and right state is done   *
!      * for which several options exist.                               *
!      * It is assumed that the pointers in blockPointers already       *
!      * point to the correct block.                                    *
!      *                                                                *
!      ******************************************************************
!
!
!      Subroutine arguments.
!
  LOGICAL, INTENT(IN) :: finegrid
!
!      Local variables.
!
  INTEGER(kind=portype) :: por
  INTEGER(kind=inttype) :: nwint
  INTEGER(kind=inttype) :: i, j, k, ind
  INTEGER(kind=inttype) :: limused, riemannused
  REAL(kind=realtype) :: sx, sy, sz, omk, opk, sfil, gammaface
  REAL(kind=realtype) :: factminmod, sface
  REAL(kind=realtype), DIMENSION(nw) :: left, right
  REAL(kind=realtype), DIMENSION(nw) :: du1, du2, du3
  REAL(kind=realtype), DIMENSION(nwf) :: flux
  LOGICAL :: firstorderk, correctfork, rotationalperiodic
  INTRINSIC MAX
  INTRINSIC ASSOCIATED
  REAL(realType) :: max1
!
!      ******************************************************************
!      *                                                                *
!      * Begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! Check if rFil == 0. If so, the dissipative flux needs not to
! be computed.
  IF (rfil .EQ. zero) THEN
    RETURN
  ELSE
! Check if the formulation for rotational periodic problems
! must be used.
    IF (ASSOCIATED(rotmatrixi)) THEN
      rotationalperiodic = .true.
    ELSE
      rotationalperiodic = .false.
    END IF
! Initialize the dissipative residual to a certain times,
! possibly zero, the previously stored value. Owned cells
! only, because the halo values do not matter.
    sfil = one - rfil
    DO k=2,kl
      DO j=2,jl
        DO i=2,il
          fw(i, j, k, irho) = sfil*fw(i, j, k, irho)
          fw(i, j, k, imx) = sfil*fw(i, j, k, imx)
          fw(i, j, k, imy) = sfil*fw(i, j, k, imy)
          fw(i, j, k, imz) = sfil*fw(i, j, k, imz)
          fw(i, j, k, irhoe) = sfil*fw(i, j, k, irhoe)
        END DO
      END DO
    END DO
! Determine whether or not the total energy must be corrected
! for the presence of the turbulent kinetic energy.
    IF (kpresent) THEN
      IF (currentlevel .EQ. groundlevel .OR. turbcoupled) THEN
        correctfork = .true.
      ELSE
        correctfork = .false.
      END IF
    ELSE
      correctfork = .false.
    END IF
    IF (1.e-10_realType .LT. one - kappacoef) THEN
      max1 = one - kappacoef
    ELSE
      max1 = 1.e-10_realType
    END IF
! Compute the factor used in the minmod limiter.
    factminmod = (three-kappacoef)/max1
! Determine the limiter scheme to be used. On the fine grid the
! user specified scheme is used; on the coarse grid a first order
! scheme is computed.
    limused = firstorder
    IF (finegrid) limused = limiter
! Lumped diss is true for doing approx PC
    IF (lumpeddiss) limused = firstorder
! Determine the riemann solver which must be used.
    riemannused = riemanncoarse
    IF (finegrid) riemannused = riemann
! Store 1-kappa and 1+kappa a bit easier and multiply it by 0.25.
    omk = fourth*(one-kappacoef)
    opk = fourth*(one+kappacoef)
! Initialize sFace to zero. This value will be used if the
! block is not moving.
    sface = zero
! Set the number of variables to be interpolated depending
! whether or not a k-equation is present. If a k-equation is
! present also set the logical firstOrderK. This indicates
! whether or not only a first order approximation is to be used
! for the turbulent kinetic energy.
    IF (correctfork) THEN
      IF (orderturb .EQ. firstorder) THEN
        nwint = nwf
        firstorderk = .true.
      ELSE
        nwint = itu1
        firstorderk = .false.
      END IF
    ELSE
      nwint = nwf
      firstorderk = .false.
    END IF
!
!      ******************************************************************
!      *                                                                *
!      * Flux computation. A distinction is made between first and      *
!      * second order schemes to avoid the overhead for the first order *
!      * scheme.                                                        *
!      *                                                                *
!      ******************************************************************
!
    IF (limused .EQ. firstorder) THEN
!
!        ****************************************************************
!        *                                                              *
!        * First order reconstruction. The states in the cells are      *
!        * constant. The left and right states are constructed easily.  *
!        *                                                              *
!        ****************************************************************
!
! Fluxes in the i-direction.
      DO k=2,kl
        DO j=2,jl
          DO i=1,il
! Store the normal vector, the porosity and the
! mesh velocity if present.
            sx = si(i, j, k, 1)
            sy = si(i, j, k, 2)
            sz = si(i, j, k, 3)
            por = pori(i, j, k)
            IF (addgridvelocities) sface = sfacei(i, j, k)
! Determine the left and right state.
            left(irho) = w(i, j, k, irho)
            left(ivx) = w(i, j, k, ivx)
            left(ivy) = w(i, j, k, ivy)
            left(ivz) = w(i, j, k, ivz)
            left(irhoe) = p(i, j, k)
            IF (correctfork) left(itu1) = w(i, j, k, itu1)
            right(irho) = w(i+1, j, k, irho)
            right(ivx) = w(i+1, j, k, ivx)
            right(ivy) = w(i+1, j, k, ivy)
            right(ivz) = w(i+1, j, k, ivz)
            right(irhoe) = p(i+1, j, k)
            IF (correctfork) right(itu1) = w(i+1, j, k, itu1)
! Compute the value of gamma on the face. Take an
! arithmetic average of the two states.
            gammaface = half*(gamma(i, j, k)+gamma(i+1, j, k))
! Compute the dissipative flux across the interface.
            CALL RIEMANNFLUX(left, right, flux)
! And scatter it to the left and right.
            fw(i, j, k, irho) = fw(i, j, k, irho) + flux(irho)
            fw(i, j, k, imx) = fw(i, j, k, imx) + flux(imx)
            fw(i, j, k, imy) = fw(i, j, k, imy) + flux(imy)
            fw(i, j, k, imz) = fw(i, j, k, imz) + flux(imz)
            fw(i, j, k, irhoe) = fw(i, j, k, irhoe) + flux(irhoe)
            fw(i+1, j, k, irho) = fw(i+1, j, k, irho) - flux(irho)
            fw(i+1, j, k, imx) = fw(i+1, j, k, imx) - flux(imx)
            fw(i+1, j, k, imy) = fw(i+1, j, k, imy) - flux(imy)
            fw(i+1, j, k, imz) = fw(i+1, j, k, imz) - flux(imz)
            fw(i+1, j, k, irhoe) = fw(i+1, j, k, irhoe) - flux(irhoe)
! Store the density flux in the mass flow of the
! appropriate sliding mesh interface.
            ind = indfamilyi(i, j, k)
            massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(&
&              ind, spectralsol) + factfamilyi(i, j, k)*flux(irho)
          END DO
        END DO
      END DO
! Fluxes in j-direction.
      DO k=2,kl
        DO j=1,jl
          DO i=2,il
! Store the normal vector, the porosity and the
! mesh velocity if present.
            sx = sj(i, j, k, 1)
            sy = sj(i, j, k, 2)
            sz = sj(i, j, k, 3)
            por = porj(i, j, k)
            IF (addgridvelocities) sface = sfacej(i, j, k)
! Determine the left and right state.
            left(irho) = w(i, j, k, irho)
            left(ivx) = w(i, j, k, ivx)
            left(ivy) = w(i, j, k, ivy)
            left(ivz) = w(i, j, k, ivz)
            left(irhoe) = p(i, j, k)
            IF (correctfork) left(itu1) = w(i, j, k, itu1)
            right(irho) = w(i, j+1, k, irho)
            right(ivx) = w(i, j+1, k, ivx)
            right(ivy) = w(i, j+1, k, ivy)
            right(ivz) = w(i, j+1, k, ivz)
            right(irhoe) = p(i, j+1, k)
            IF (correctfork) right(itu1) = w(i, j+1, k, itu1)
! Compute the value of gamma on the face. Take an
! arithmetic average of the two states.
            gammaface = half*(gamma(i, j, k)+gamma(i, j+1, k))
! Compute the dissipative flux across the interface.
            CALL RIEMANNFLUX(left, right, flux)
! And scatter it to the left and right.
            fw(i, j, k, irho) = fw(i, j, k, irho) + flux(irho)
            fw(i, j, k, imx) = fw(i, j, k, imx) + flux(imx)
            fw(i, j, k, imy) = fw(i, j, k, imy) + flux(imy)
            fw(i, j, k, imz) = fw(i, j, k, imz) + flux(imz)
            fw(i, j, k, irhoe) = fw(i, j, k, irhoe) + flux(irhoe)
            fw(i, j+1, k, irho) = fw(i, j+1, k, irho) - flux(irho)
            fw(i, j+1, k, imx) = fw(i, j+1, k, imx) - flux(imx)
            fw(i, j+1, k, imy) = fw(i, j+1, k, imy) - flux(imy)
            fw(i, j+1, k, imz) = fw(i, j+1, k, imz) - flux(imz)
            fw(i, j+1, k, irhoe) = fw(i, j+1, k, irhoe) - flux(irhoe)
! Store the density flux in the mass flow of the
! appropriate sliding mesh interface.
            ind = indfamilyj(i, j, k)
            massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(&
&              ind, spectralsol) + factfamilyj(i, j, k)*flux(irho)
          END DO
        END DO
      END DO
! Fluxes in k-direction.
      DO k=1,kl
        DO j=2,jl
          DO i=2,il
! Store the normal vector, the porosity and the
! mesh velocity if present.
            sx = sk(i, j, k, 1)
            sy = sk(i, j, k, 2)
            sz = sk(i, j, k, 3)
            por = pork(i, j, k)
            IF (addgridvelocities) sface = sfacek(i, j, k)
! Determine the left and right state.
            left(irho) = w(i, j, k, irho)
            left(ivx) = w(i, j, k, ivx)
            left(ivy) = w(i, j, k, ivy)
            left(ivz) = w(i, j, k, ivz)
            left(irhoe) = p(i, j, k)
            IF (correctfork) left(itu1) = w(i, j, k, itu1)
            right(irho) = w(i, j, k+1, irho)
            right(ivx) = w(i, j, k+1, ivx)
            right(ivy) = w(i, j, k+1, ivy)
            right(ivz) = w(i, j, k+1, ivz)
            right(irhoe) = p(i, j, k+1)
            IF (correctfork) right(itu1) = w(i, j, k+1, itu1)
! Compute the value of gamma on the face. Take an
! arithmetic average of the two states.
            gammaface = half*(gamma(i, j, k)+gamma(i, j, k+1))
! Compute the dissipative flux across the interface.
            CALL RIEMANNFLUX(left, right, flux)
! And scatter it the left and right.
            fw(i, j, k, irho) = fw(i, j, k, irho) + flux(irho)
            fw(i, j, k, imx) = fw(i, j, k, imx) + flux(imx)
            fw(i, j, k, imy) = fw(i, j, k, imy) + flux(imy)
            fw(i, j, k, imz) = fw(i, j, k, imz) + flux(imz)
            fw(i, j, k, irhoe) = fw(i, j, k, irhoe) + flux(irhoe)
            fw(i, j, k+1, irho) = fw(i, j, k+1, irho) - flux(irho)
            fw(i, j, k+1, imx) = fw(i, j, k+1, imx) - flux(imx)
            fw(i, j, k+1, imy) = fw(i, j, k+1, imy) - flux(imy)
            fw(i, j, k+1, imz) = fw(i, j, k+1, imz) - flux(imz)
            fw(i, j, k+1, irhoe) = fw(i, j, k+1, irhoe) - flux(irhoe)
! Store the density flux in the mass flow of the
! appropriate sliding mesh interface.
            ind = indfamilyk(i, j, k)
            massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(&
&              ind, spectralsol) + factfamilyk(i, j, k)*flux(irho)
          END DO
        END DO
      END DO
    ELSE
!      ==================================================================
!      ==================================================================
!
!        ****************************************************************
!        *                                                              *
!        * Second order reconstruction of the left and right state.     *
!        * The three differences used in the, possibly nonlinear,       *
!        * interpolation are constructed here; the actual left and      *
!        * right states, or at least the differences from the first     *
!        * order interpolation, are computed in the subroutine          *
!        * leftRightState.                                              *
!        *                                                              *
!        ****************************************************************
!
! Fluxes in the i-direction.
      DO k=2,kl
        DO j=2,jl
          DO i=1,il
! Store the three differences used in the interpolation
! in du1, du2, du3.
            du1(irho) = w(i, j, k, irho) - w(i-1, j, k, irho)
            du2(irho) = w(i+1, j, k, irho) - w(i, j, k, irho)
            du3(irho) = w(i+2, j, k, irho) - w(i+1, j, k, irho)
            du1(ivx) = w(i, j, k, ivx) - w(i-1, j, k, ivx)
            du2(ivx) = w(i+1, j, k, ivx) - w(i, j, k, ivx)
            du3(ivx) = w(i+2, j, k, ivx) - w(i+1, j, k, ivx)
            du1(ivy) = w(i, j, k, ivy) - w(i-1, j, k, ivy)
            du2(ivy) = w(i+1, j, k, ivy) - w(i, j, k, ivy)
            du3(ivy) = w(i+2, j, k, ivy) - w(i+1, j, k, ivy)
            du1(ivz) = w(i, j, k, ivz) - w(i-1, j, k, ivz)
            du2(ivz) = w(i+1, j, k, ivz) - w(i, j, k, ivz)
            du3(ivz) = w(i+2, j, k, ivz) - w(i+1, j, k, ivz)
            du1(irhoe) = p(i, j, k) - p(i-1, j, k)
            du2(irhoe) = p(i+1, j, k) - p(i, j, k)
            du3(irhoe) = p(i+2, j, k) - p(i+1, j, k)
            IF (correctfork) THEN
              du1(itu1) = w(i, j, k, itu1) - w(i-1, j, k, itu1)
              du2(itu1) = w(i+1, j, k, itu1) - w(i, j, k, itu1)
              du3(itu1) = w(i+2, j, k, itu1) - w(i+1, j, k, itu1)
            END IF
! Compute the differences from the first order scheme.
            CALL LEFTRIGHTSTATE(du1, du2, du3, rotmatrixi, left, right)
! Add the first order part to the currently stored
! differences, such that the correct state vector
! is stored.
            left(irho) = left(irho) + w(i, j, k, irho)
            left(ivx) = left(ivx) + w(i, j, k, ivx)
            left(ivy) = left(ivy) + w(i, j, k, ivy)
            left(ivz) = left(ivz) + w(i, j, k, ivz)
            left(irhoe) = left(irhoe) + p(i, j, k)
            right(irho) = right(irho) + w(i+1, j, k, irho)
            right(ivx) = right(ivx) + w(i+1, j, k, ivx)
            right(ivy) = right(ivy) + w(i+1, j, k, ivy)
            right(ivz) = right(ivz) + w(i+1, j, k, ivz)
            right(irhoe) = right(irhoe) + p(i+1, j, k)
            IF (correctfork) THEN
              left(itu1) = left(itu1) + w(i, j, k, itu1)
              right(itu1) = right(itu1) + w(i+1, j, k, itu1)
            END IF
! Store the normal vector, the porosity and the
! mesh velocity if present.
            sx = si(i, j, k, 1)
            sy = si(i, j, k, 2)
            sz = si(i, j, k, 3)
            por = pori(i, j, k)
            IF (addgridvelocities) sface = sfacei(i, j, k)
! Compute the value of gamma on the face. Take an
! arithmetic average of the two states.
            gammaface = half*(gamma(i, j, k)+gamma(i+1, j, k))
! Compute the dissipative flux across the interface.
            CALL RIEMANNFLUX(left, right, flux)
! And scatter it to the left and right.
            fw(i, j, k, irho) = fw(i, j, k, irho) + flux(irho)
            fw(i, j, k, imx) = fw(i, j, k, imx) + flux(imx)
            fw(i, j, k, imy) = fw(i, j, k, imy) + flux(imy)
            fw(i, j, k, imz) = fw(i, j, k, imz) + flux(imz)
            fw(i, j, k, irhoe) = fw(i, j, k, irhoe) + flux(irhoe)
            fw(i+1, j, k, irho) = fw(i+1, j, k, irho) - flux(irho)
            fw(i+1, j, k, imx) = fw(i+1, j, k, imx) - flux(imx)
            fw(i+1, j, k, imy) = fw(i+1, j, k, imy) - flux(imy)
            fw(i+1, j, k, imz) = fw(i+1, j, k, imz) - flux(imz)
            fw(i+1, j, k, irhoe) = fw(i+1, j, k, irhoe) - flux(irhoe)
! Store the density flux in the mass flow of the
! appropriate sliding mesh interface.
            ind = indfamilyi(i, j, k)
            massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(&
&              ind, spectralsol) + factfamilyi(i, j, k)*flux(irho)
          END DO
        END DO
      END DO
! Fluxes in the j-direction.
      DO k=2,kl
        DO j=1,jl
          DO i=2,il
! Store the three differences used in the interpolation
! in du1, du2, du3.
            du1(irho) = w(i, j, k, irho) - w(i, j-1, k, irho)
            du2(irho) = w(i, j+1, k, irho) - w(i, j, k, irho)
            du3(irho) = w(i, j+2, k, irho) - w(i, j+1, k, irho)
            du1(ivx) = w(i, j, k, ivx) - w(i, j-1, k, ivx)
            du2(ivx) = w(i, j+1, k, ivx) - w(i, j, k, ivx)
            du3(ivx) = w(i, j+2, k, ivx) - w(i, j+1, k, ivx)
            du1(ivy) = w(i, j, k, ivy) - w(i, j-1, k, ivy)
            du2(ivy) = w(i, j+1, k, ivy) - w(i, j, k, ivy)
            du3(ivy) = w(i, j+2, k, ivy) - w(i, j+1, k, ivy)
            du1(ivz) = w(i, j, k, ivz) - w(i, j-1, k, ivz)
            du2(ivz) = w(i, j+1, k, ivz) - w(i, j, k, ivz)
            du3(ivz) = w(i, j+2, k, ivz) - w(i, j+1, k, ivz)
            du1(irhoe) = p(i, j, k) - p(i, j-1, k)
            du2(irhoe) = p(i, j+1, k) - p(i, j, k)
            du3(irhoe) = p(i, j+2, k) - p(i, j+1, k)
            IF (correctfork) THEN
              du1(itu1) = w(i, j, k, itu1) - w(i, j-1, k, itu1)
              du2(itu1) = w(i, j+1, k, itu1) - w(i, j, k, itu1)
              du3(itu1) = w(i, j+2, k, itu1) - w(i, j+1, k, itu1)
            END IF
! Compute the differences from the first order scheme.
            CALL LEFTRIGHTSTATE(du1, du2, du3, rotmatrixj, left, right)
! Add the first order part to the currently stored
! differences, such that the correct state vector
! is stored.
            left(irho) = left(irho) + w(i, j, k, irho)
            left(ivx) = left(ivx) + w(i, j, k, ivx)
            left(ivy) = left(ivy) + w(i, j, k, ivy)
            left(ivz) = left(ivz) + w(i, j, k, ivz)
            left(irhoe) = left(irhoe) + p(i, j, k)
            right(irho) = right(irho) + w(i, j+1, k, irho)
            right(ivx) = right(ivx) + w(i, j+1, k, ivx)
            right(ivy) = right(ivy) + w(i, j+1, k, ivy)
            right(ivz) = right(ivz) + w(i, j+1, k, ivz)
            right(irhoe) = right(irhoe) + p(i, j+1, k)
            IF (correctfork) THEN
              left(itu1) = left(itu1) + w(i, j, k, itu1)
              right(itu1) = right(itu1) + w(i, j+1, k, itu1)
            END IF
! Store the normal vector, the porosity and the
! mesh velocity if present.
            sx = sj(i, j, k, 1)
            sy = sj(i, j, k, 2)
            sz = sj(i, j, k, 3)
            por = porj(i, j, k)
            IF (addgridvelocities) sface = sfacej(i, j, k)
! Compute the value of gamma on the face. Take an
! arithmetic average of the two states.
            gammaface = half*(gamma(i, j, k)+gamma(i, j+1, k))
! Compute the dissipative flux across the interface.
            CALL RIEMANNFLUX(left, right, flux)
! And scatter it to the left and right.
            fw(i, j, k, irho) = fw(i, j, k, irho) + flux(irho)
            fw(i, j, k, imx) = fw(i, j, k, imx) + flux(imx)
            fw(i, j, k, imy) = fw(i, j, k, imy) + flux(imy)
            fw(i, j, k, imz) = fw(i, j, k, imz) + flux(imz)
            fw(i, j, k, irhoe) = fw(i, j, k, irhoe) + flux(irhoe)
            fw(i, j+1, k, irho) = fw(i, j+1, k, irho) - flux(irho)
            fw(i, j+1, k, imx) = fw(i, j+1, k, imx) - flux(imx)
            fw(i, j+1, k, imy) = fw(i, j+1, k, imy) - flux(imy)
            fw(i, j+1, k, imz) = fw(i, j+1, k, imz) - flux(imz)
            fw(i, j+1, k, irhoe) = fw(i, j+1, k, irhoe) - flux(irhoe)
! Store the density flux in the mass flow of the
! appropriate sliding mesh interface.
            ind = indfamilyj(i, j, k)
            massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(&
&              ind, spectralsol) + factfamilyj(i, j, k)*flux(irho)
          END DO
        END DO
      END DO
! Fluxes in the k-direction.
      DO k=1,kl
        DO j=2,jl
          DO i=2,il
! Store the three differences used in the interpolation
! in du1, du2, du3.
            du1(irho) = w(i, j, k, irho) - w(i, j, k-1, irho)
            du2(irho) = w(i, j, k+1, irho) - w(i, j, k, irho)
            du3(irho) = w(i, j, k+2, irho) - w(i, j, k+1, irho)
            du1(ivx) = w(i, j, k, ivx) - w(i, j, k-1, ivx)
            du2(ivx) = w(i, j, k+1, ivx) - w(i, j, k, ivx)
            du3(ivx) = w(i, j, k+2, ivx) - w(i, j, k+1, ivx)
            du1(ivy) = w(i, j, k, ivy) - w(i, j, k-1, ivy)
            du2(ivy) = w(i, j, k+1, ivy) - w(i, j, k, ivy)
            du3(ivy) = w(i, j, k+2, ivy) - w(i, j, k+1, ivy)
            du1(ivz) = w(i, j, k, ivz) - w(i, j, k-1, ivz)
            du2(ivz) = w(i, j, k+1, ivz) - w(i, j, k, ivz)
            du3(ivz) = w(i, j, k+2, ivz) - w(i, j, k+1, ivz)
            du1(irhoe) = p(i, j, k) - p(i, j, k-1)
            du2(irhoe) = p(i, j, k+1) - p(i, j, k)
            du3(irhoe) = p(i, j, k+2) - p(i, j, k+1)
            IF (correctfork) THEN
              du1(itu1) = w(i, j, k, itu1) - w(i, j, k-1, itu1)
              du2(itu1) = w(i, j, k+1, itu1) - w(i, j, k, itu1)
              du3(itu1) = w(i, j, k+2, itu1) - w(i, j, k+1, itu1)
            END IF
! Compute the differences from the first order scheme.
            CALL LEFTRIGHTSTATE(du1, du2, du3, rotmatrixk, left, right)
! Add the first order part to the currently stored
! differences, such that the correct state vector
! is stored.
            left(irho) = left(irho) + w(i, j, k, irho)
            left(ivx) = left(ivx) + w(i, j, k, ivx)
            left(ivy) = left(ivy) + w(i, j, k, ivy)
            left(ivz) = left(ivz) + w(i, j, k, ivz)
            left(irhoe) = left(irhoe) + p(i, j, k)
            right(irho) = right(irho) + w(i, j, k+1, irho)
            right(ivx) = right(ivx) + w(i, j, k+1, ivx)
            right(ivy) = right(ivy) + w(i, j, k+1, ivy)
            right(ivz) = right(ivz) + w(i, j, k+1, ivz)
            right(irhoe) = right(irhoe) + p(i, j, k+1)
            IF (correctfork) THEN
              left(itu1) = left(itu1) + w(i, j, k, itu1)
              right(itu1) = right(itu1) + w(i, j, k+1, itu1)
            END IF
! Store the normal vector, the porosity and the
! mesh velocity if present.
            sx = sk(i, j, k, 1)
            sy = sk(i, j, k, 2)
            sz = sk(i, j, k, 3)
            por = pork(i, j, k)
            IF (addgridvelocities) sface = sfacek(i, j, k)
! Compute the value of gamma on the face. Take an
! arithmetic average of the two states.
            gammaface = half*(gamma(i, j, k)+gamma(i, j, k+1))
! Compute the dissipative flux across the interface.
            CALL RIEMANNFLUX(left, right, flux)
! And scatter it to the left and right.
            fw(i, j, k, irho) = fw(i, j, k, irho) + flux(irho)
            fw(i, j, k, imx) = fw(i, j, k, imx) + flux(imx)
            fw(i, j, k, imy) = fw(i, j, k, imy) + flux(imy)
            fw(i, j, k, imz) = fw(i, j, k, imz) + flux(imz)
            fw(i, j, k, irhoe) = fw(i, j, k, irhoe) + flux(irhoe)
            fw(i, j, k+1, irho) = fw(i, j, k+1, irho) - flux(irho)
            fw(i, j, k+1, imx) = fw(i, j, k+1, imx) - flux(imx)
            fw(i, j, k+1, imy) = fw(i, j, k+1, imy) - flux(imy)
            fw(i, j, k+1, imz) = fw(i, j, k+1, imz) - flux(imz)
            fw(i, j, k+1, irhoe) = fw(i, j, k+1, irhoe) - flux(irhoe)
! Store the density flux in the mass flow of the
! appropriate sliding mesh interface.
            ind = indfamilyk(i, j, k)
            massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(&
&              ind, spectralsol) + factfamilyk(i, j, k)*flux(irho)
          END DO
        END DO
      END DO
    END IF
  END IF
END SUBROUTINE INVISCIDUPWINDFLUX_CD
