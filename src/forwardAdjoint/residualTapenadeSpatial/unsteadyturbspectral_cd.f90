!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
!
!
!      ******************************************************************
!      *                                                                *
!      * File:          unsteadyTurbSpectral.f90                        *
!      * Author:        Edwin van der Weide                             *
!      * Starting date: 08-22-2004                                      *
!      * Last modified: 06-28-2005                                      *
!      *                                                                *
!      ******************************************************************
!
SUBROUTINE UNSTEADYTURBSPECTRAL_CD(ntu1, ntu2)
  USE INPUTPHYSICS_SPATIAL_D
  USE ITERATION_SPATIAL_D
  USE INPUTTIMESPECTRAL_SPATIAL_D
  USE BLOCKPOINTERS_SPATIAL_D
  IMPLICIT NONE
!
!      ******************************************************************
!      *                                                                *
!      * unsteadyTurbSpectral determines the spectral time derivative   *
!      * for all owned cells. This routine is called before the actual  *
!      * solve routines, such that the treatment is identical for all   *
!      * spectral solutions. The results is stored in the corresponding *
!      * entry in dw.                                                   *
!      *                                                                *
!      ******************************************************************
!
!
!      Subroutine arguments.
!
  INTEGER(kind=inttype), INTENT(IN) :: ntu1, ntu2
!
!      Local variables.
!
  INTEGER(kind=inttype) :: ii, mm, nn, sps, i, j, k
  EXTERNAL SETPOINTERS
  EXTERNAL FLOWDOMS
  TYPE(UNKNOWNDERIVEDTYPE2) :: FLOWDOMS
!
!      ******************************************************************
!      *                                                                *
!      * Begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! Return immediately if not the time spectral equations are to
! be solved.
  IF (equationmode .NE. timespectral) THEN
    RETURN
  ELSE
! Loop over the number of spectral modes and local blocks.
spectralloop:DO sps=1,ntimeintervalsspectral
domains:DO nn=1,ndom
! Set the pointers for this block.
        CALL SETPOINTERS(nn, currentlevel, sps)
! Loop over the number of turbulent transport equations.
nadvloop:DO ii=ntu1,ntu2
! Initialize the time derivative to zero for the owned
! cell centers.
          DO k=2,kl
            DO j=2,jl
              DO i=2,il
                dw(i, j, k, ii) = zero
              END DO
            END DO
          END DO
! Loop over the number of terms which contribute to the
! time derivative.
          DO mm=1,ntimeintervalsspectral
! Add the contribution to the time derivative for
! all owned cells.
            DO k=2,kl
              DO j=2,jl
                DO i=2,il
                  dw(i, j, k, ii) = dw(i, j, k, ii) + dscalar(sectionid&
&                    , sps, mm)*FLOWDOMS(nn, currentlevel, mm)%w(i, j, k&
&                    , ii)
                END DO
              END DO
            END DO
          END DO
        END DO nadvloop
      END DO domains
    END DO spectralloop
  END IF
END SUBROUTINE UNSTEADYTURBSPECTRAL_CD
