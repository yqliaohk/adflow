   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.6 (r4512) -  3 Aug 2012 15:11
   !
   !  Differentiation of forcesandmoments in forward (tangent) mode (with options i4 dr8 r8):
   !   variations   of useful results: *(*bcdata.f) *(*bcdata.m) cfp
   !                cfv cmp cmv
   !   with respect to varying inputs: *p *x *si *sj *sk *(*viscsubface.tau)
   !                pinf pref lengthref surfaceref machcoef pointref
   !   Plus diff mem management of: p:in x:in si:in sj:in sk:in viscsubface:in
   !                *viscsubface.tau:in bcdata:in *bcdata.f:in *bcdata.m:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          forcesAndMoments.f90                            *
   !      * Author:        Edwin van der Weide                             *
   !      * Starting date: 04-01-2003                                      *
   !      * Last modified: 06-12-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE FORCESANDMOMENTS_D(cfp, cfpd, cfv, cfvd, cmp, cmpd, cmv, cmvd&
   &  , yplusmax)
   USE FLOWVARREFSTATE
   USE BLOCKPOINTERS_D
   USE BCTYPES
   USE INPUTPHYSICS
   USE DIFFSIZES
   !  Hint: ISIZE1OFDrfbcdata should be the size of dimension 1 of array *bcdata
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * forcesAndMoments computes the contribution of the block        *
   !      * given by the pointers in blockPointers to the force and        *
   !      * moment coefficients of the geometry. A distinction is made     *
   !      * between the inviscid and viscous parts. In case the maximum    *
   !      * yplus value must be monitored (only possible for rans), this   *
   !      * value is also computed.                                        *
   !      *                                                                *
   !      ******************************************************************
   !
   !
   !      Subroutine arguments
   !
   REAL(kind=realtype), DIMENSION(3), INTENT(OUT) :: cfp, cfv
   REAL(kind=realtype), DIMENSION(3), INTENT(OUT) :: cfpd, cfvd
   REAL(kind=realtype), DIMENSION(3), INTENT(OUT) :: cmp, cmv
   REAL(kind=realtype), DIMENSION(3), INTENT(OUT) :: cmpd, cmvd
   REAL(kind=realtype), INTENT(OUT) :: yplusmax
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: nn, i, j
   REAL(kind=realtype) :: pm1, fx, fy, fz, fn
   REAL(kind=realtype) :: pm1d, fxd, fyd, fzd
   REAL(kind=realtype) :: xc, yc, zc
   REAL(kind=realtype) :: xcd, ycd, zcd
   REAL(kind=realtype) :: fact, rho, mul, yplus, dwall
   REAL(kind=realtype) :: factd
   REAL(kind=realtype) :: scaledim
   REAL(kind=realtype) :: scaledimd
   REAL(kind=realtype) :: tauxx, tauyy, tauzz
   REAL(kind=realtype) :: tauxxd, tauyyd, tauzzd
   REAL(kind=realtype) :: tauxy, tauxz, tauyz
   REAL(kind=realtype) :: tauxyd, tauxzd, tauyzd
   REAL(kind=realtype), DIMENSION(3) :: refpoint
   REAL(kind=realtype), DIMENSION(3) :: refpointd
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: pp2, pp1
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: pp2d, pp1d
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rho2, rho1
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rlv2, rlv1
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: dd2wall
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ss, xx
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ssd, xxd
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: norm
   REAL(kind=realtype) :: mx, my, mz
   REAL(kind=realtype) :: mxd, myd, mzd
   LOGICAL :: viscoussubface
   REAL(kind=realtype) :: arg1
   REAL(kind=realtype) :: result1
   REAL(kind=realtype) :: arg2
   REAL(kind=realtype) :: result2
   INTRINSIC MAX
   INTEGER :: ii1
   INTRINSIC SQRT
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Set the actual scaling factor such that ACTUAL forces are computed
   scaledimd = (prefd*pinf-pref*pinfd)/pinf**2
   scaledim = pref/pinf
   refpointd = 0.0_8
   ! Determine the reference point for the moment computation in
   ! meters.
   refpointd(1) = lref*pointrefd(1)
   refpoint(1) = lref*pointref(1)
   refpointd(2) = lref*pointrefd(2)
   refpoint(2) = lref*pointref(2)
   refpointd(3) = lref*pointrefd(3)
   refpoint(3) = lref*pointref(3)
   ! Initialize the force and moment coefficients to 0 as well as
   ! yplusMax.
   cfpd(1) = 0.0_8
   cfp(1) = zero
   cfpd(2) = 0.0_8
   cfp(2) = zero
   cfpd(3) = 0.0_8
   cfp(3) = zero
   cfvd(1) = 0.0_8
   cfv(1) = zero
   cfvd(2) = 0.0_8
   cfv(2) = zero
   cfvd(3) = 0.0_8
   cfv(3) = zero
   cmpd(1) = 0.0_8
   cmp(1) = zero
   cmpd(2) = 0.0_8
   cmp(2) = zero
   cmpd(3) = 0.0_8
   cmp(3) = zero
   cmvd(1) = 0.0_8
   cmv(1) = zero
   cmvd(2) = 0.0_8
   cmv(2) = zero
   cmvd(3) = 0.0_8
   cmv(3) = zero
   yplusmax = zero
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%f = 0.0_8
   END DO
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%m = 0.0_8
   END DO
   cfpd = 0.0_8
   cfvd = 0.0_8
   cmpd = 0.0_8
   cmvd = 0.0_8
   ! Loop over the boundary subfaces of this block.
   bocos:DO nn=1,nbocos
   !
   !        ****************************************************************
   !        *                                                              *
   !        * Integrate the inviscid contribution over the solid walls,    *
   !        * either inviscid or viscous. The integration is done with     *
   !        * cp. For closed contours this is equal to the integration     *
   !        * of p; for open contours this is not the case anymore.        *
   !        * Question is whether a force for an open contour is           *
   !        * meaningful anyway.                                           *
   !        *                                                              *
   !        ****************************************************************
   !
   IF ((bctype(nn) .EQ. eulerwall .OR. bctype(nn) .EQ. nswalladiabatic)&
   &        .OR. bctype(nn) .EQ. nswallisothermal) THEN
   ! Subface is a wall. Check if it is a viscous wall.
   viscoussubface = .true.
   IF (bctype(nn) .EQ. eulerwall) viscoussubface = .false.
   ! Set a bunch of pointers depending on the face id to make
   ! a generic treatment possible. The routine setBcPointers
   ! is not used, because quite a few other ones are needed.
   SELECT CASE  (bcfaceid(nn)) 
   CASE (imin) 
   pp2d => pd(2, 1:, 1:)
   pp2 => p(2, 1:, 1:)
   pp1d => pd(1, 1:, 1:)
   pp1 => p(1, 1:, 1:)
   rho2 => w(2, 1:, 1:, irho)
   rho1 => w(1, 1:, 1:, irho)
   ssd => sid(1, :, :, :)
   ss => si(1, :, :, :)
   xxd => xd(1, :, :, :)
   xx => x(1, :, :, :)
   fact = -one
   IF (equations .EQ. ransequations) THEN
   dd2wall => d2wall(2, :, :)
   END IF
   IF (viscoussubface) THEN
   rlv2 => rlv(2, 1:, 1:)
   rlv1 => rlv(1, 1:, 1:)
   END IF
   CASE (imax) 
   !===========================================================
   pp2d => pd(il, 1:, 1:)
   pp2 => p(il, 1:, 1:)
   pp1d => pd(ie, 1:, 1:)
   pp1 => p(ie, 1:, 1:)
   rho2 => w(il, 1:, 1:, irho)
   rho1 => w(ie, 1:, 1:, irho)
   ssd => sid(il, :, :, :)
   ss => si(il, :, :, :)
   xxd => xd(il, :, :, :)
   xx => x(il, :, :, :)
   fact = one
   IF (equations .EQ. ransequations) THEN
   dd2wall => d2wall(il, :, :)
   END IF
   IF (viscoussubface) THEN
   rlv2 => rlv(il, 1:, 1:)
   rlv1 => rlv(ie, 1:, 1:)
   END IF
   CASE (jmin) 
   !===========================================================
   pp2d => pd(1:, 2, 1:)
   pp2 => p(1:, 2, 1:)
   pp1d => pd(1:, 1, 1:)
   pp1 => p(1:, 1, 1:)
   rho2 => w(1:, 2, 1:, irho)
   rho1 => w(1:, 1, 1:, irho)
   ssd => sjd(:, 1, :, :)
   ss => sj(:, 1, :, :)
   xxd => xd(:, 1, :, :)
   xx => x(:, 1, :, :)
   fact = -one
   IF (equations .EQ. ransequations) THEN
   dd2wall => d2wall(:, 2, :)
   END IF
   IF (viscoussubface) THEN
   rlv2 => rlv(1:, 2, 1:)
   rlv1 => rlv(1:, 1, 1:)
   END IF
   CASE (jmax) 
   !===========================================================
   pp2d => pd(1:, jl, 1:)
   pp2 => p(1:, jl, 1:)
   pp1d => pd(1:, je, 1:)
   pp1 => p(1:, je, 1:)
   rho2 => w(1:, jl, 1:, irho)
   rho1 => w(1:, je, 1:, irho)
   ssd => sjd(:, jl, :, :)
   ss => sj(:, jl, :, :)
   xxd => xd(:, jl, :, :)
   xx => x(:, jl, :, :)
   fact = one
   IF (equations .EQ. ransequations) THEN
   dd2wall => d2wall(:, jl, :)
   END IF
   IF (viscoussubface) THEN
   rlv2 => rlv(1:, jl, 1:)
   rlv1 => rlv(1:, je, 1:)
   END IF
   CASE (kmin) 
   !===========================================================
   pp2d => pd(1:, 1:, 2)
   pp2 => p(1:, 1:, 2)
   pp1d => pd(1:, 1:, 1)
   pp1 => p(1:, 1:, 1)
   rho2 => w(1:, 1:, 2, irho)
   rho1 => w(1:, 1:, 1, irho)
   ssd => skd(:, :, 1, :)
   ss => sk(:, :, 1, :)
   xxd => xd(:, :, 1, :)
   xx => x(:, :, 1, :)
   fact = -one
   IF (equations .EQ. ransequations) THEN
   dd2wall => d2wall(:, :, 2)
   END IF
   IF (viscoussubface) THEN
   rlv2 => rlv(1:, 1:, 2)
   rlv1 => rlv(1:, 1:, 1)
   END IF
   CASE (kmax) 
   !===========================================================
   pp2d => pd(1:, 1:, kl)
   pp2 => p(1:, 1:, kl)
   pp1d => pd(1:, 1:, ke)
   pp1 => p(1:, 1:, ke)
   rho2 => w(1:, 1:, kl, irho)
   rho1 => w(1:, 1:, ke, irho)
   ssd => skd(:, :, kl, :)
   ss => sk(:, :, kl, :)
   xxd => xd(:, :, kl, :)
   xx => x(:, :, kl, :)
   fact = one
   IF (equations .EQ. ransequations) THEN
   dd2wall => d2wall(:, :, kl)
   END IF
   IF (viscoussubface) THEN
   rlv2 => rlv(1:, 1:, kl)
   rlv1 => rlv(1:, 1:, ke)
   END IF
   END SELECT
   ! Loop over the quadrilateral faces of the subface. Note
   ! that the nodal range of BCData must be used and not the
   ! cell range, because the latter may include the halo's in i
   ! and j-direction. The offset +1 is there, because inBeg and
   ! jnBeg refer to nodal ranges and not to cell ranges.
   DO j=bcdata(nn)%jnbeg+1,bcdata(nn)%jnend
   DO i=bcdata(nn)%inbeg+1,bcdata(nn)%inend
   ! Compute the average pressure minus 1 and the coordinates
   ! of the centroid of the face relative from from the
   ! moment reference point. Due to the usage of pointers for
   ! the coordinates, whose original array starts at 0, an
   ! offset of 1 must be used. The pressure is multipled by
   ! fact to account for the possibility of an inward or
   ! outward pointing normal.
   pm1d = fact*((half*(pp2d(i, j)+pp1d(i, j))-pinfd)*scaledim+(&
   &            half*(pp2(i, j)+pp1(i, j))-pinf)*scaledimd)
   pm1 = fact*(half*(pp2(i, j)+pp1(i, j))-pinf)*scaledim
   xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd(i&
   &            +1, j+1, 1)) - refpointd(1)
   xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j&
   &            +1, 1)) - refpoint(1)
   ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd(i&
   &            +1, j+1, 2)) - refpointd(2)
   yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j&
   &            +1, 2)) - refpoint(2)
   zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd(i&
   &            +1, j+1, 3)) - refpointd(3)
   zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j&
   &            +1, 3)) - refpoint(3)
   ! Compute the force components.
   fxd = pm1d*ss(i, j, 1) + pm1*ssd(i, j, 1)
   fx = pm1*ss(i, j, 1)
   fyd = pm1d*ss(i, j, 2) + pm1*ssd(i, j, 2)
   fy = pm1*ss(i, j, 2)
   fzd = pm1d*ss(i, j, 3) + pm1*ssd(i, j, 3)
   fz = pm1*ss(i, j, 3)
   ! Store Force data on face
   bcdatad(nn)%f(i, j, 1) = fxd
   bcdata(nn)%f(i, j, 1) = fx
   bcdatad(nn)%f(i, j, 2) = fyd
   bcdata(nn)%f(i, j, 2) = fy
   bcdatad(nn)%f(i, j, 3) = fzd
   bcdata(nn)%f(i, j, 3) = fz
   ! Update the inviscid force and moment coefficients.
   cfpd(1) = cfpd(1) + fxd
   cfp(1) = cfp(1) + fx
   cfpd(2) = cfpd(2) + fyd
   cfp(2) = cfp(2) + fy
   cfpd(3) = cfpd(3) + fzd
   cfp(3) = cfp(3) + fz
   mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
   mx = yc*fz - zc*fy
   myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
   my = zc*fx - xc*fz
   mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
   mz = xc*fy - yc*fx
   cmpd(1) = cmpd(1) + mxd
   cmp(1) = cmp(1) + mx
   cmpd(2) = cmpd(2) + myd
   cmp(2) = cmp(2) + my
   cmpd(3) = cmpd(3) + mzd
   cmp(3) = cmp(3) + mz
   ! Store Moment data on face
   bcdatad(nn)%m(i, j, 1) = mxd
   bcdata(nn)%m(i, j, 1) = mx
   bcdatad(nn)%m(i, j, 2) = myd
   bcdata(nn)%m(i, j, 2) = my
   bcdatad(nn)%m(i, j, 3) = mzd
   bcdata(nn)%m(i, j, 3) = mz
   END DO
   END DO
   !
   !          **************************************************************
   !          *                                                            *
   !          * Integration of the viscous forces.                         *
   !          * Only for viscous boundaries.                               *
   !          *                                                            *
   !          **************************************************************
   !
   IF (viscoussubface) THEN
   ! Initialize dwall for the laminar case and set the pointer
   ! for the unit normals.
   dwall = zero
   norm => bcdata(nn)%norm
   ! Loop over the quadrilateral faces of the subface and
   ! compute the viscous contribution to the force and
   ! moment and update the maximum value of y+.
   DO j=bcdata(nn)%jnbeg+1,bcdata(nn)%jnend
   DO i=bcdata(nn)%inbeg+1,bcdata(nn)%inend
   ! Store the viscous stress tensor a bit easier.
   tauxxd = viscsubfaced(nn)%tau(i, j, 1)
   tauxx = viscsubface(nn)%tau(i, j, 1)
   tauyyd = viscsubfaced(nn)%tau(i, j, 2)
   tauyy = viscsubface(nn)%tau(i, j, 2)
   tauzzd = viscsubfaced(nn)%tau(i, j, 3)
   tauzz = viscsubface(nn)%tau(i, j, 3)
   tauxyd = viscsubfaced(nn)%tau(i, j, 4)
   tauxy = viscsubface(nn)%tau(i, j, 4)
   tauxzd = viscsubfaced(nn)%tau(i, j, 5)
   tauxz = viscsubface(nn)%tau(i, j, 5)
   tauyzd = viscsubfaced(nn)%tau(i, j, 6)
   tauyz = viscsubface(nn)%tau(i, j, 6)
   ! Compute the viscous force on the face. A minus sign
   ! is now present, due to the definition of this force.
   fxd = -(fact*(tauxxd*ss(i, j, 1)+tauxx*ssd(i, j, 1)+tauxyd*&
   &              ss(i, j, 2)+tauxy*ssd(i, j, 2)+tauxzd*ss(i, j, 3)+tauxz*&
   &              ssd(i, j, 3)))
   fx = -(fact*(tauxx*ss(i, j, 1)+tauxy*ss(i, j, 2)+tauxz*ss(i&
   &              , j, 3)))
   fyd = -(fact*(tauxyd*ss(i, j, 1)+tauxy*ssd(i, j, 1)+tauyyd*&
   &              ss(i, j, 2)+tauyy*ssd(i, j, 2)+tauyzd*ss(i, j, 3)+tauyz*&
   &              ssd(i, j, 3)))
   fy = -(fact*(tauxy*ss(i, j, 1)+tauyy*ss(i, j, 2)+tauyz*ss(i&
   &              , j, 3)))
   fzd = -(fact*(tauxzd*ss(i, j, 1)+tauxz*ssd(i, j, 1)+tauyzd*&
   &              ss(i, j, 2)+tauyz*ssd(i, j, 2)+tauzzd*ss(i, j, 3)+tauzz*&
   &              ssd(i, j, 3)))
   fz = -(fact*(tauxz*ss(i, j, 1)+tauyz*ss(i, j, 2)+tauzz*ss(i&
   &              , j, 3)))
   ! Compute the coordinates of the centroid of the face
   ! relative from the moment reference point. Due to the
   ! usage of pointers for xx and offset of 1 is present,
   ! because x originally starts at 0.
   xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd&
   &              (i+1, j+1, 1)) - refpointd(1)
   xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1&
   &              , j+1, 1)) - refpoint(1)
   ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd&
   &              (i+1, j+1, 2)) - refpointd(2)
   yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1&
   &              , j+1, 2)) - refpoint(2)
   zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd&
   &              (i+1, j+1, 3)) - refpointd(3)
   zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1&
   &              , j+1, 3)) - refpoint(3)
   ! Update the viscous force and moment coefficients.
   cfvd(1) = cfvd(1) + fxd
   cfv(1) = cfv(1) + fx
   cfvd(2) = cfvd(2) + fyd
   cfv(2) = cfv(2) + fy
   cfvd(3) = cfvd(3) + fzd
   cfv(3) = cfv(3) + fz
   ! Store Force data on face
   bcdatad(nn)%f(i, j, 1) = bcdatad(nn)%f(i, j, 1) + fxd
   bcdata(nn)%f(i, j, 1) = bcdata(nn)%f(i, j, 1) + fx
   bcdatad(nn)%f(i, j, 2) = bcdatad(nn)%f(i, j, 2) + fyd
   bcdata(nn)%f(i, j, 2) = bcdata(nn)%f(i, j, 2) + fy
   bcdatad(nn)%f(i, j, 3) = bcdatad(nn)%f(i, j, 3) + fzd
   bcdata(nn)%f(i, j, 3) = bcdata(nn)%f(i, j, 3) + fz
   mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
   mx = yc*fz - zc*fy
   myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
   my = zc*fx - xc*fz
   mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
   mz = xc*fy - yc*fx
   cmvd(1) = cmvd(1) + mxd
   cmv(1) = cmv(1) + mx
   cmvd(2) = cmvd(2) + myd
   cmv(2) = cmv(2) + my
   cmvd(3) = cmvd(3) + mzd
   cmv(3) = cmv(3) + mz
   ! Store Moment data on face
   bcdatad(nn)%m(i, j, 1) = bcdatad(nn)%m(i, j, 1) + mxd
   bcdata(nn)%m(i, j, 1) = bcdata(nn)%m(i, j, 1) + mx
   bcdatad(nn)%m(i, j, 2) = bcdatad(nn)%m(i, j, 2) + myd
   bcdata(nn)%m(i, j, 2) = bcdata(nn)%m(i, j, 2) + my
   bcdatad(nn)%m(i, j, 3) = bcdatad(nn)%m(i, j, 3) + mzd
   bcdata(nn)%m(i, j, 3) = bcdata(nn)%m(i, j, 3) + mz
   ! Compute the tangential component of the stress tensor,
   ! which is needed to monitor y+. The result is stored
   ! in fx, fy, fz, although it is not really a force.
   ! As later on only the magnitude of the tangential
   ! component is important, there is no need to take the
   ! sign into account (it should be a minus sign).
   fx = tauxx*norm(i, j, 1) + tauxy*norm(i, j, 2) + tauxz*norm(&
   &              i, j, 3)*scaledim
   fy = tauxy*norm(i, j, 1) + tauyy*norm(i, j, 2) + tauyz*norm(&
   &              i, j, 3)*scaledim
   fz = tauxz*norm(i, j, 1) + tauyz*norm(i, j, 2) + tauzz*norm(&
   &              i, j, 3)*scaledim
   fn = fx*norm(i, j, 1) + fy*norm(i, j, 2) + fz*norm(i, j, 3)
   fx = fx - fn*norm(i, j, 1)
   fy = fy - fn*norm(i, j, 2)
   fz = fz - fn*norm(i, j, 3)
   ! Compute the local value of y+. Due to the usage
   ! of pointers there is on offset of -1 in dd2Wall..
   IF (equations .EQ. ransequations) dwall = dd2wall(i-1, j-1)
   rho = half*(rho2(i, j)+rho1(i, j))
   mul = half*(rlv2(i, j)+rlv1(i, j))
   arg1 = fx*fx + fy*fy + fz*fz
   result1 = SQRT(arg1)
   arg2 = rho*result1
   result2 = SQRT(arg2)
   yplus = result2*dwall/mul
   IF (yplusmax .LT. yplus) THEN
   yplusmax = yplus
   ELSE
   yplusmax = yplusmax
   END IF
   END DO
   END DO
   END IF
   END IF
   END DO bocos
   ! Currently the coefficients only contain the surface integral
   ! of the pressure tensor. These values must be scaled to
   ! obtain the correct coefficients.
   factd = -(two*gammainf*lref**2*(((pinfd*machcoef+pinf*machcoefd)*&
   &    scaledim+pinf*machcoef*scaledimd)*machcoef*surfaceref+pinf*machcoef*&
   &    scaledim*(machcoefd*surfaceref+machcoef*surfacerefd))/(gammainf*pinf&
   &    *machcoef*machcoef*surfaceref*lref*lref*scaledim)**2)
   fact = two/(gammainf*pinf*machcoef*machcoef*surfaceref*lref*lref*&
   &    scaledim)
   cfpd(1) = cfpd(1)*fact + cfp(1)*factd
   cfp(1) = cfp(1)*fact
   cfpd(2) = cfpd(2)*fact + cfp(2)*factd
   cfp(2) = cfp(2)*fact
   cfpd(3) = cfpd(3)*fact + cfp(3)*factd
   cfp(3) = cfp(3)*fact
   cfvd(1) = cfvd(1)*fact + cfv(1)*factd
   cfv(1) = cfv(1)*fact
   cfvd(2) = cfvd(2)*fact + cfv(2)*factd
   cfv(2) = cfv(2)*fact
   cfvd(3) = cfvd(3)*fact + cfv(3)*factd
   cfv(3) = cfv(3)*fact
   factd = (factd*lengthref*lref-fact*lref*lengthrefd)/(lengthref*lref)**&
   &    2
   fact = fact/(lengthref*lref)
   cmpd(1) = cmpd(1)*fact + cmp(1)*factd
   cmp(1) = cmp(1)*fact
   cmpd(2) = cmpd(2)*fact + cmp(2)*factd
   cmp(2) = cmp(2)*fact
   cmpd(3) = cmpd(3)*fact + cmp(3)*factd
   cmp(3) = cmp(3)*fact
   cmvd(1) = cmvd(1)*fact + cmv(1)*factd
   cmv(1) = cmv(1)*fact
   cmvd(2) = cmvd(2)*fact + cmv(2)*factd
   cmv(2) = cmv(2)*fact
   cmvd(3) = cmvd(3)*fact + cmv(3)*factd
   cmv(3) = cmv(3)*fact
   END SUBROUTINE FORCESANDMOMENTS_D
