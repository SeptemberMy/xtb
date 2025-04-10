! This file is part of xtb.
!
! Copyright (C) 2017-2020 Stefan Grimme
!
! xtb is free software: you can redistribute it and/or modify it under
! the terms of the GNU Lesser General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! xtb is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public License
! along with xtb.  If not, see <https://www.gnu.org/licenses/>.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! implemented by SG, 9/2018
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine rabguess(n,at,xyz,cn,dcn,nsrb,srblist,shift,rab,grab)
   implicit none
   integer n                 ! number of atoms
   integer at(n)             ! ordinal numbers
   real*8  xyz(3,n)          ! Cartesian coords in Bohr
   real*8  cn(n)             ! D3 CN
   real*8  dcn(3,n,n)        ! D3 CN derivatives
   integer nsrb              ! # of pairs
   integer*2 srblist(2,nsrb) ! list of atom pairs
   real*8 shift              ! shift fitted values for GFN0 adjustmen
   real*8 rab(nsrb)          ! output bond lengths estimates
   real*8 grab(3,n,nsrb)     ! output bond lengths gradients

   !     local variables
   integer m,i,j,k,ii,jj,ati,atj,ir,jr
   INTEGER iTabRow4 ! row in PSE for given ordinal number, values > 4

   real*8 cnfak(86),r0(86),en(86)
   real*8 ra,rb,k1,k2,den,ff,p(4,2)

   !     fitted on PBExa-3c geom set by SG, 9/2018
   !     H B C N O F SI P S CL GE AS SE BR SN SB TE I together (and for glob par)
   !     and rest one element at a time, LN taken as av. of La and Hf
   !     about 15-20 reference molecules per element (about 30-40 data points per fit
   !     parameter)
   ! electronegativity (started from Pauling values)
   ! base radius
   ! CN dep. lin
   ! CN dep. quadratic (not used, only slightly better)
   data en /&
      & 2.30085633, 2.78445145, 1.52956084, 1.51714704, 2.20568300,&
      & 2.49640820, 2.81007174, 4.51078438, 4.67476223, 3.29383610,&
      & 2.84505365, 2.20047950, 2.31739628, 2.03636974, 1.97558064,&
      & 2.13446570, 2.91638164, 1.54098156, 2.91656301, 2.26312147,&
      & 2.25621439, 1.32628677, 2.27050569, 1.86790977, 2.44759456,&
      & 2.49480042, 2.91545568, 3.25897750, 2.68723778, 1.86132251,&
      & 2.01200832, 1.97030722, 1.95495427, 2.68920990, 2.84503857,&
      & 2.61591858, 2.64188286, 2.28442252, 1.33011187, 1.19809388,&
      & 1.89181390, 2.40186898, 1.89282464, 3.09963488, 2.50677823,&
      & 2.61196704, 2.09943450, 2.66930105, 1.78349472, 2.09634533,&
      & 2.00028974, 1.99869908, 2.59072029, 2.54497829, 2.52387890,&
      & 2.30204667, 1.60119300, 2.00000000, 2.00000000, 2.00000000,&
      & 2.00000000, 2.00000000, 2.00000000, 2.00000000, 2.00000000,&
      & 2.00000000, 2.00000000, 2.00000000, 2.00000000, 2.00000000,&
      & 2.00000000, 2.30089349, 1.75039077, 1.51785130, 2.62972945,&
      & 2.75372921, 2.62540906, 2.55860939, 3.32492356, 2.65140898,&
      & 1.52014458, 2.54984804, 1.72021963, 2.69303422, 1.81031095,&
      & 2.34224386&
      &/
   data r0 /&
      & 0.55682207, 0.80966997, 2.49092101, 1.91705642, 1.35974851,&
      & 0.98310699, 0.98423007, 0.76716063, 1.06139799, 1.17736822,&
      & 2.85570926, 2.56149012, 2.31673425, 2.03181740, 1.82568535,&
      & 1.73685958, 1.97498207, 2.00136196, 3.58772537, 2.68096221,&
      & 2.23355957, 2.33135502, 2.15870365, 2.10522128, 2.16376162,&
      & 2.10804037, 1.96460045, 2.00476257, 2.22628712, 2.43846700,&
      & 2.39408483, 2.24245792, 2.05751204, 2.15427677, 2.27191920,&
      & 2.19722638, 3.80910350, 3.26020971, 2.99716916, 2.71707818,&
      & 2.34950167, 2.11644818, 2.47180659, 2.32198800, 2.32809515,&
      & 2.15244869, 2.55958313, 2.59141300, 2.62030465, 2.39935278,&
      & 2.56912355, 2.54374096, 2.56914830, 2.53680807, 4.24537037,&
      & 3.66542289, 3.19903011, 2.80000000, 2.80000000, 2.80000000,&
      & 2.80000000, 2.80000000, 2.80000000, 2.80000000, 2.80000000,&
      & 2.80000000, 2.80000000, 2.80000000, 2.80000000, 2.80000000,&
      & 2.80000000, 2.34880037, 2.37597108, 2.49067697, 2.14100577,&
      & 2.33473532, 2.19498900, 2.12678348, 2.34895048, 2.33422774,&
      & 2.86560827, 2.62488837, 2.88376127, 2.75174124, 2.83054552,&
      & 2.63264944&
      &/
   data cnfak /&
      & 0.17957827, 0.25584045,-0.02485871, 0.00374217, 0.05646607,&
      & 0.10514203, 0.09753494, 0.30470380, 0.23261783, 0.36752208,&
      & 0.00131819,-0.00368122,-0.01364510, 0.04265789, 0.07583916,&
      & 0.08973207,-0.00589677, 0.13689929,-0.01861307, 0.11061699,&
      & 0.10201137, 0.05426229, 0.06014681, 0.05667719, 0.02992924,&
      & 0.03764312, 0.06140790, 0.08563465, 0.03707679, 0.03053526,&
      &-0.00843454, 0.01887497, 0.06876354, 0.01370795,-0.01129196,&
      & 0.07226529, 0.01005367, 0.01541506, 0.05301365, 0.07066571,&
      & 0.07637611, 0.07873977, 0.02997732, 0.04745400, 0.04582912,&
      & 0.10557321, 0.02167468, 0.05463616, 0.05370913, 0.05985441,&
      & 0.02793994, 0.02922983, 0.02220438, 0.03340460,-0.04110969,&
      &-0.01987240, 0.07260201, 0.07700000, 0.07700000, 0.07700000,&
      & 0.07700000, 0.07700000, 0.07700000, 0.07700000, 0.07700000,&
      & 0.07700000, 0.07700000, 0.07700000, 0.07700000, 0.07700000,&
      & 0.07700000, 0.08379100, 0.07314553, 0.05318438, 0.06799334,&
      & 0.04671159, 0.06758819, 0.09488437, 0.07556405, 0.13384502,&
      & 0.03203572, 0.04235009, 0.03153769,-0.00152488, 0.02714675,&
      & 0.04800662&
      &/

   ! parameter input for fit
   !     open(unit=11,file='~/.param')
   !     do i=1,86
   !        read(11,*) r0(i),cnfak(i),en(i) ! r0, CN dep
   !     enddo
   !     do j=1,2
   !     do i=1,4
   !        read(11,*) p(i,j)
   !     enddo
   !     enddo
   !     close(11)

   !     global EN polynominal parameters x 10^3
   p(1,1)=    29.84522887
   p(2,1)=    -1.70549806
   p(3,1)=     6.54013762
   p(4,1)=     6.39169003
   p(1,2)=    -8.87843763
   p(2,2)=     2.10878369
   p(3,2)=     0.08009374
   p(4,2)=    -0.85808076

   do k=1,nsrb
      i=srblist(1,k)
      j=srblist(2,k)
      ati=at(i)
      atj=at(j)
      ir=itabrow4(ati)
      jr=itabrow4(atj)
      !--------
      ra=r0(ati)+cnfak(ati)*cn(i)+shift
      rb=r0(atj)+cnfak(atj)*cn(j)+shift
      den=abs(en(ati)-en(atj))
      k1=0.005d0*(p(ir,1)+p(jr,1))
      k2=0.005d0*(p(ir,2)+p(jr,2))
      ff=1.0d0-k1*den-k2*den**2
      rab(k) =(ra+rb)*ff
      do m=1,n
         grab(1:3,m,k)=ff*(cnfak(ati)*dcn(1:3,i,m)&
            &                       +cnfak(atj)*dcn(1:3,j,m))
      enddo
      !--------
   enddo

end subroutine

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

INTEGER FUNCTION iTabRow4(i)
   implicit none
   INTEGER i

   iTabRow4=0
   If (i.gt. 0 .and. i.le. 2) Then
      iTabRow4=1
   Else If (i.gt. 2 .and. i.le.10) Then
      iTabRow4=2
   Else If (i.gt.10 .and. i.le.18) Then
      iTabRow4=3
   Else If (i.gt.18) Then
      iTabRow4=4
   End If

   Return
End function
