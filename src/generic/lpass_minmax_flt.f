***s/r lpass_minmax_flt - Low pass filter of topography field
*                     
*
      SUBROUTINE lpass_filter(me,mask,ni,nj,
     *                        rc,p,
     *                        maskoper,threshold,applyminmax)
      IMPLICIT NONE
*
      INTEGER ni,nj
      REAL    me(NI,NJ)
      REAL    mask(NI,NJ)
      REAL    rc
      INTEGER p
      REAL    threshold
      INTEGER maskoper
      LOGICAL applyminmax
*
*author - Ayrton Zadra
*
*object
*       See above ID.
*
*arguments
*
*_____________________________________________________________________
* NAME         | DESCRIPTION
*--------------|------------------------------------------------------
* me           | input/output topography field 
*              | (input: non-filtered | output: filtered field)
* mask         | input mask field 
*              |
* ni           | number of grid points along x axis
*              |
* nj           | number of grid points along y axis
*
*--------------|------------------------------------------------------
* applyminmax  | if .true.  then me is 'clipped' to nearest neighbour
*              | if .false. then no clipping is done
* rc           | filter parameter delta x
* p            | filter parameter
* threshold    | threshold to compare with mask values
* maskoper     | operator to use for mask threshold
*              |    <0 for LT, >0 for GT, ==0 NA (Not Apply)
*______________|______________________________________________________
*
      INTEGER i,j,k
*     
      INTEGER n,im,ip,jm,jp
      REAL    c1,c2,aux,pi
      REAL    h1(ni,nj),h2(ni,nj),lmin(ni,nj),lmax(ni,nj)
*
C     (defaults should be rc = 3, p = 20, threshold = 100.)
C
C     Internal parameters
C
      if (rc .eq. 0) then 
         rc = 3
      endif
*
      c1 = 2.0/rc
      pi = 3.14159265359
*
      do j=1,nj
        do i=1,ni
          im = max(i-1,1)
          ip = min(i+1,ni)
          jm = max(j-1,1)
          jp = min(j+1,nj)        
          lmin(i,j) = min(min(  me(i,j),me(im,j )),me(ip,j ))
          lmin(i,j) = min(min(lmin(i,j),me(i ,jm)),me(i ,jp))
          lmin(i,j) = min(min(lmin(i,j),me(im,jm)),me(im,jp))
          lmin(i,j) = min(min(lmin(i,j),me(ip,jm)),me(ip,jp))
          lmax(i,j) = max(max(  me(i,j),me(im,j )),me(ip,j ))
          lmax(i,j) = max(max(lmax(i,j),me(i ,jm)),me(i ,jp))
          lmax(i,j) = max(max(lmax(i,j),me(im,jm)),me(im,jp))
          lmax(i,j) = max(max(lmax(i,j),me(ip,jm)),me(ip,jp))
        enddo
      enddo
*      
      do j=1,nj
        do i=1,ni
          h1(i,j) = c1*me(i,j)
          aux     = c1
          do n=1,(p-1)
            c2 = (2./rc)*((sin(2*pi*n/rc))/(2*pi*n/rc))*
     X                 ((sin(2*pi*n/p ))/(2*pi*n/p ))
            im = i-n
            ip = i+n
            if ( im.ge.1 .and. ip.le.ni  ) then
              h1(i,j) = h1(i,j) + c2*( me(im,j) + me(ip,j) )
              aux = aux + 2.*c2
            endif
          enddo
          h1(i,j) = h1(i,j)/aux      
        enddo
      enddo
*      
      do i=1,ni
        do j=1,nj
          h2(i,j) = c1*h1(i,j)
          aux     = c1
          do n=1,(p-1)
            c2 = (2./rc)*((sin(2*pi*n/rc))/(2*pi*n/rc))*
     X                 ((sin(2*pi*n/p ))/(2*pi*n/p ))
            jm = j-n
            jp = j+n
            if ( jm.ge.1 .and. jp.le.nj  ) then
              h2(i,j) = h2(i,j) + c2*( h1(i,jm) + h1(i,jp) )
              aux = aux + 2.*c2
            endif
          enddo
          h2(i,j) = h2(i,j)/aux
*       
          if (applyminmax)  then
            h2(i,j) = min(max(h2(i,j),lmin(i,j)),lmax(i,j))
          endif
*
          if (maskoper .gt. 0) then
            if ( mask(i,j) .gt. threshold ) then
              me(i,j) = h2(i,j)
            endif
          else if (maskoper .lt. 0) then
            if ( mask(i,j) .lt. threshold ) then
              me(i,j) = h2(i,j)
            endif
          else
            me(i,j) = h2(i,j)
          endif
*
        enddo
      enddo       
* 
 999  continue
      return
      end
