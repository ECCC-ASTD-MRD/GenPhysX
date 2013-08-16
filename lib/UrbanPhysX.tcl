#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : UrbanPhysX.tcl
# Creation   : October 2010 - J.P. Gauthier - CMC/CMOE
# Revision   : $Id$
# Description: Definitions of functions related to urban geo-physical fields
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#   UrbanPhysX::Cover      { Grid }
#============================================================================

namespace eval UrbanPhysX { } {
   variable Const
   variable Param

   set Param(Types) { BLD BLD_HEIGHT Z0_TOWN WALL_O_HOR ALB_ROOF ALB_ROAD ALB_WALL \
      EMIS_ROOF EMIS_ROAD EMIS_WALL H_TRAFFIC LE_TRAFFIC H_INDUSTRY LE_INDUSTRY \
      HC_ROOF1 HC_ROOF2 HC_ROOF3 TC_ROOF1 TC_ROOF2 TC_ROOF3 D_ROOF1 D_ROOF2 D_ROOF3 \
      HC_ROAD1 HC_ROAD2 HC_ROAD3 TC_ROAD1 TC_ROAD2 TC_ROAD3 D_ROAD1 D_ROAD2 D_ROAD3  \
      HC_WALL1 HC_WALL2 HC_WALL3 TC_WALL1 TC_WALL2 TC_WALL3 D_WALL1 D_WALL2 D_WALL3 }

   set Param(Vars) { 1T 3T 4T 5T 1N 2N 3N 4N 5N 6N 7O 8O 9O 1Q 7N 7N 7N 8N 8N 8N 9N 9N 9N 1O 1O 1O 2O 2O 2O 3O 3O 3O 4O 4O 4O 5O 5O 5O 6O 6O 6O }
   set Param(IP1s) { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1199 1198 1197 1199 1198 1197 1199 1198 1197 1199 1198 1197 1199 1198 1197 1199 1198 1197 1199 1198 1197 1199 1198 1197 1199 1198 1197 }

   #----- Fractions areas by urban class
   set Const(FracBuilt) { 0.95 0.90 0.80 0.70 0.70 0.40 0.85 0.70 0.44 0.27 0.18 0.25 }
   set Const(FracTree)  { 0.02 0.05 0.10 0.10 0.00 0.30 0.05 0.15 0.28 0.36 0.47 0.37 }
   set Const(FracGrass) { 0.03 0.05 0.10 0.20 0.00 0.30 0.10 0.15 0.28 0.37 0.35 0.38 }
   set Const(FracSoil)  { 0.00 0.00 0.00 0.00 0.30 0.00 0.00 0.00 0.00 0.00 0.00 0.00 }

   #-----Dynamic roughness length for natural classes
   set Const(Z0Veg)     { 0.001 0.001 0.001 1.5 3.5 1 1.0 2.0 3.0 0.8 0.05 0.15 0.15 0.02 0.08 0.08 0.08 0.35 0.25 0.1 0.08 1.35 0.01 0.05 0.05 1.5 0.05 }

   #----- Geometric parameters
   #----- Building density (relatively to the built-up areas)
   set Const(BLD)        { 0.60 0.50 0.50 0.50 0.40 0.80 0.10 0.10 0.55 0.40 0.40 0.40 }

   #-----  Building height
   set Const(BLD_HEIGHT) { 39.0 25.0 13.0 8.0 8.0 12.0 5.0 5.0 5.0 5.0 8.0 8.0 }

   #----- Roughness length of momentum for urban canopy
   set Const(Z0_TOWN)    { 3.9 2.5 1.3 0.8 0.8 1.2 0.5 0.5 0.5 0.5 0.8 0.8 }

   #-----Ratio between wall areas and plan built-up areas
   set Const(WALL_O_HOR) { 1.6 1.1 0.6 0.4 0.4 2.3 0.1 0.1 0.6 0.8 1.0 0.4 }

   #----- Radiative properties
   #----- Roof, road and wall albedo
   set Const(ALB_ROOF)   { 0.15 0.15 0.15 0.15 0.12 0.15 0.15 0.15 0.15 0.15 0.15 0.15 }
   set Const(ALB_ROAD)   { 0.15 0.15 0.15 0.15 0.15 0.15 0.15 0.15 0.15 0.15 0.15 0.15 }
   set Const(ALB_WALL)   { 0.25 0.25 0.25 0.25 0.50 0.25 0.25 0.25 0.25 0.25 0.25 0.25 }

   #----- Roof, road and wall emissivity
   set Const(EMIS_ROOF)  { 0.90 0.90 0.90 0.90 0.92 0.90 0.90 0.90 0.90 0.90 0.90 0.90 }
   set Const(EMIS_ROAD)  { 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 0.90 }
   set Const(EMIS_WALL)  { 0.85 0.85 0.85 0.85 0.90 0.85 0.85 0.85 0.85 0.85 0.85 0.85 }

   #----- Roof thermal properties, dense and aerated concrete + insulation (Oke 87)
   #----- Roof heat capacity
   set Const(HC_ROOF1)   { 2.11E6 2.11E6 2.11E6 2.11E6 1.76E6 2.11E6 2.11E6 2.11E6 2.11E6 2.11E6 2.11E6 2.11E6 }
   set Const(HC_ROOF2)   { 0.28E6 0.28E6 0.28E6 0.28E6 0.04E6 0.28E6 0.28E6 0.28E6 0.28E6 0.28E6 0.28E6 0.28E6 }
   set Const(HC_ROOF3)   { 0.29E6 0.29E6 0.29E6 0.29E6 2.21E6 0.29E6 0.29E6 0.29E6 0.29E6 0.29E6 0.29E6 0.29E6 }

   #----- Roof thermal conductivity
   set Const(TC_ROOF1)   { 1.51 1.51 1.51 1.51 1.40 1.51 1.51 1.51 1.51 1.51 1.51 1.51 }
   set Const(TC_ROOF2)   { 0.08 0.08 0.08 0.08 0.03 0.08 0.08 0.08 0.08 0.08 0.08 0.08 }
   set Const(TC_ROOF3)   { 0.05 0.05 0.05 0.05 1.51 0.05 0.05 0.05 0.05 0.05 0.05 0.05 }

   #----- Width of roof layers
   set Const(D_ROOF1)    { 0.05 0.05 0.05 0.05 0.03 0.05 0.05 0.05 0.05 0.05 0.05 0.05 }
   set Const(D_ROOF2)    { 0.40 0.40 0.40 0.40 0.01 0.40 0.40 0.40 0.40 0.40 0.40 0.40 }
   set Const(D_ROOF3)    { 0.10 0.10 0.10 0.10 0.03 0.10 0.10 0.10 0.10 0.10 0.10 0.10 }

   #----- Road thermal properties, asphalt + dry soil (Mill 93)
   #----- Road heat capacity
   set Const(HC_ROAD1)   { 1.94E6 1.94E6 1.94E6 1.94E6 1.70E6 1.94E6 1.94E6 1.94E6 1.94E6 1.94E6 1.94E6 1.94E6 }
   set Const(HC_ROAD2)   { 1.28E6 1.28E6 1.28E6 1.28E6 2.00E6 1.28E6 1.28E6 1.28E6 1.28E6 1.28E6 1.28E6 1.28E6 }
   set Const(HC_ROAD3)   { 1.28E6 1.28E6 1.28E6 1.28E6 1.40E6 1.28E6 1.28E6 1.28E6 1.28E6 1.28E6 1.28E6 1.28E6 }

   #----- Road thermal conductivity
   set Const(TC_ROAD1)   { 0.7454 0.7454 0.7454 0.7454 0.8200 0.7454 0.7454 0.7454 0.7454 0.7454 0.7454 0.7454 }
   set Const(TC_ROAD2)   { 0.2513 0.2513 0.2513 0.2513 2.1000 0.2513 0.2513 0.2513 0.2513 0.2513 0.2513 0.2513 }
   set Const(TC_ROAD3)   { 0.2513 0.2513 0.2513 0.2513 0.4000 0.2513 0.2513 0.2513 0.2513 0.2513 0.2513 0.2513 }

   #----- Width of road layers
   set Const(D_ROAD1)    { 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 0.05 }
   set Const(D_ROAD2)    { 0.10 0.10 0.10 0.10 0.20 0.10 0.10 0.10 0.10 0.10 0.10 0.10 }
   set Const(D_ROAD3)    { 1.00 1.00 1.00 1.00 1.00 1.00 1.00 1.00 1.00 1.00 1.00 1.00 }

   #----- Wall thermal properties, concrete + insulation (Mills 93)
   #----- Wall heat capacity
   set Const(HC_WALL1)   { 1.55E6 1.55E6 1.55E6 1.55E6 2.11E6 1.55E6 1.55E6 1.55E6 1.55E6 1.55E6 1.55E6 1.55E6 }
   set Const(HC_WALL2)   { 1.55E6 1.55E6 1.55E6 1.55E6 1.00E6 1.55E6 1.55E6 1.55E6 1.55E6 1.55E6 1.55E6 1.55E6 }
   set Const(HC_WALL3)   { 0.29E6 0.29E6 0.29E6 0.29E6 2.11E6 0.29E6 0.29E6 0.29E6 0.29E6 0.29E6 0.29E6 0.29E6 }

   #----- Wall thermal conductivity
   set Const(TC_WALL1)   { 0.9338 0.9338 0.9338 0.9338 1.5100 0.9338 0.9338 0.9338 0.9338 0.9338 0.9338 0.9338 }
   set Const(TC_WALL2)   { 0.9338 0.9338 0.9338 0.9338 0.6700 0.9338 0.9338 0.9338 0.9338 0.9338 0.9338 0.9338 }
   set Const(TC_WALL3)   { 0.0500 0.0500 0.0500 0.0500 1.5100 0.0500 0.0500 0.0500 0.0500 0.0500 0.0500 0.0500 }

   #----- Width of wall layers
   set Const(D_WALL1)    { 0.020 0.020 0.020 0.020 0.030 0.020 0.020 0.020 0.020 0.020 0.020 0.020 }
   set Const(D_WALL2)    { 0.125 0.125 0.125 0.125 0.140 0.125 0.125 0.125 0.125 0.125 0.125 0.125 }
   set Const(D_WALL3)    { 0.050 0.050 0.050 0.050 0.030 0.050 0.050 0.050 0.050 0.050 0.050 0.050 }

   #----- Anthropogenic heat fluxes
   #-----Sensible heat flux due to traffic  and  industry
   set Const(H_TRAFFIC)  { 20.0 20.0 20.0 20.0 20.0 10.0 30.0 30.0 10.0 10.0 10.0 0.0 }
   set Const(H_INDUSTRY) { 10.0 10.0 10.0 10.0 30.0  5.0  0.0  0.0  5.0  5.0  5.0 0.0 }

   #----- Latent heat flux due to traffic and  industry
   set Const(LE_TRAFFIC)  { 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0 0.0 }
   set Const(LE_INDUSTRY) { 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0 0.0 }
}

#----------------------------------------------------------------------------
# Name     : <UrbanPhysX::Cover>
# Creation : Octobre 2010 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Apply urban characteristics to VF fields.
#
# Parameters :
#   <Grid>   : Grid on which to generate the fields
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanPhysX::Cover { Grid } {
   variable Param
   variable Const

   GenX::Procs
   Log::Print INFO "Applying urban characteristics to VF"

   fstdfield copy GPXSUM $Grid
   fstdfield copy GPXZ0 $Grid
   fstdfield copy GPXAGG $Grid
   GenX::GridClear { GPXSUM GPXZ0 GPXAGG } 0.0

   #----- Read urban classification
   fstdfield read GPXUF GPXOUTFILE -1 "" -1 -1 -1 "" "UF"
   fstdfield readcube GPXUF

   #----- Read vege classification
   fstdfield read GPXVF GPXOUTFILE -1 "" -1 -1 -1 "" "VF"
   fstdfield readcube GPXVF

   #----- Calculation of urban fraction and built-up fraction
   for { set c 0 } { $c<[fstdfield define GPXUF -NK] } { incr c } {
      vexpr GPXUF GPXUF()()($c)=GPXUF()()($c)*[lindex $Const(FracBuilt) $c]
      vexpr GPXSUM GPXSUM+GPXUF()()($c)
   }
   #----- Save urban UR field
   fstdfield define GPXSUM -NOMVAR UR -IP1 0
   fstdfield write GPXSUM GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Remove urban class (21)
   vexpr GPXVF GPXVF()()(20) = 0.0

   #----- Calculation of tree(25) grass(13) and soil(24) coverage according to the urban vegetation part classes
   for { set c 0 } { $c<[fstdfield define GPXUF -NK] } { incr c } {
      vexpr GPXVF GPXVF()()(24) = GPXVF()()(24) + GPXUF()()($c)*[lindex $Const(FracTree) $c]
      vexpr GPXVF GPXVF()()(12) = GPXVF()()(12) + GPXUF()()($c)*[lindex $Const(FracGrass) $c]
      vexpr GPXVF GPXVF()()(23) = GPXVF()()(23) + GPXUF()()($c)*[lindex $Const(FracSoil) $c]
   }

   #----- Verification of fraction total
   for { set c 0 } { $c<[fstdfield define GPXVF -NK] } { incr c } {
      vexpr GPXSUM GPXSUM+GPXVF()()($c)
   }

   set min [vexpr T smin(GPXSUM)]
   set max [vexpr T smax(GPXSUM)]

   if { $max>1.006 || $min<0.9999 } {
      Log::Print WARNING "Total coverage fration exceeds valid range \[0.999,1.006\] : $min, $max"
   }

   #----- Save urban adjusted vege
   fstdfield write GPXVF GPXAUXFILE -$GenX::Param(NBits) False $GenX::Param(Compress)

   #----- Parse each urban characteristic
   foreach type $Param(Types) var $Param(Vars) ip1 $Param(IP1s) {

      Log::Print DEBUG "   Processing $type ($var $ip1)"

      GenX::GridClear { GPXAGG GPXSUM } 0.0

      #----- Apply fraction correspondance table
      for { set c 0 } { $c<[fstdfield define GPXUF -NK] } { incr c } {
         vexpr GPXSUM GPXSUM+GPXUF()()($c)
         vexpr GPXAGG GPXAGG+GPXUF()()($c)*[lindex $Const($type) $c]
      }

      #----- Normalize
      vexpr GPXAGG ifelse(GPXSUM>0,GPXAGG/GPXSUM,0)

      #----- Save urban fields
      fstdfield define GPXAGG -NOMVAR $var -IP1 $ip1
      fstdfield write GPXAGG GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

#   #----- Dynamical roughness calculation for vegetation and soils
#   for { set c 0 } { $c<[fstdfield define GPXVF -NK] } { incr c } {
#      #----- Everything but the urban class 21
#      if { $c!=20 } {
#         vexpr GPXZ0 GPXZ0 + GPXVF()()($c) * ln([lindex $Const(Z0Veg) $c])
#      }
#   }
#   vexpr GPXZ0 exp(GPXZ0)

#   fstdfield define GPXZ0 -NOMVAR Z0TO
#   fstdfield write GPXZ0 GPXOUTFILE -$GenX::Param(NBits) False  $GenX::Param(Compress)

   fstdfield free GPXSUM GPXAGG GPXVF GPXUF GPXZ0
}