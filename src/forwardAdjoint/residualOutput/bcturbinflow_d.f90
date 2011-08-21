   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !  Differentiation of bcturbinflow in forward (tangent) mode:
   !   variations   of useful results: *bvtj1 *bvtj2 *bmtk1 *bmtk2
   !                *bvtk1 *bvtk2 *bmti1 *bmti2 *bvti1 *bvti2 *bmtj1
   !                *bmtj2
   !   with respect to varying inputs: *bvtj1 *bvtj2 *bmtk1 *bmtk2
   !                *bvtk1 *bvtk2 *bmti1 *bmti2 *bvti1 *bvti2 *bmtj1
   !                *bmtj2
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          bcTurbInflow.f90                                *
   !      * Author:        Georgi Kalitzin, Edwin van der Weide            *
   !      * Starting date: 06-11-2003                                      *
   !      * Last modified: 06-12-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE BCTURBINFLOW_D(nn)
   USE FLOWVARREFSTATE
   USE BLOCKPOINTERS_D
   USE BCTYPES
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * bcTurbInflow applies the implicit treatment of the inflow      *
   !      * boundary conditions to subface nn. As the inflow boundary      *
   !      * condition is independent of the turbulence model, this routine *
   !      * is valid for all models. It is assumed that the pointers in    *
   !      * blockPointers are already set to the correct block on the      *
   !      * correct grid level.                                            *
   !      *                                                                *
   !      ******************************************************************
   !
   !
   !      Subroutine arguments.
   !
   INTEGER(kind=inttype), INTENT(IN) :: nn
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: i, j, l
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: bvt
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: bvtd
   REAL(kind=realtype), DIMENSION(:, :, :, :), POINTER :: bmt
   REAL(kind=realtype), DIMENSION(:, :, :, :), POINTER :: bmtd
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Set the pointers for bmt and bvt, depending on the block face
   ! on which the subface is located.
   SELECT CASE  (bcfaceid(nn)) 
   CASE (imin) 
   bmtd => bmti1d
   bmt => bmti1
   bvtd => bvti1d
   bvt => bvti1
   CASE (imax) 
   bmtd => bmti2d
   bmt => bmti2
   bvtd => bvti2d
   bvt => bvti2
   CASE (jmin) 
   bmtd => bmtj1d
   bmt => bmtj1
   bvtd => bvtj1d
   bvt => bvtj1
   CASE (jmax) 
   bmtd => bmtj2d
   bmt => bmtj2
   bvtd => bvtj2d
   bvt => bvtj2
   CASE (kmin) 
   bmtd => bmtk1d
   bmt => bmtk1
   bvtd => bvtk1d
   bvt => bvtk1
   CASE (kmax) 
   bmtd => bmtk2d
   bmt => bmtk2
   bvtd => bvtk2d
   bvt => bvtk2
   END SELECT
   ! Loop over the faces of the subfaces and set the values of
   ! bvt and bmt such that the inflow state is linearly extrapolated
   ! with a fixed state at the face.
   DO j=bcdata(nn)%jcbeg,bcdata(nn)%jcend
   DO i=bcdata(nn)%icbeg,bcdata(nn)%icend
   ! Loop over the number of turbulent variables.
   DO l=nt1,nt2
   bvtd(i, j, l) = 0.0
   bvt(i, j, l) = two*bcdata(nn)%turbinlet(i, j, l)
   bmtd(i, j, l, l) = 0.0
   bmt(i, j, l, l) = one
   END DO
   END DO
   END DO
   END SUBROUTINE BCTURBINFLOW_D