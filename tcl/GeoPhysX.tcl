#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : GeoPhysX.tcl
# Creation   : September 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Description: Definitions of functions related to geo-physical fields
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#   GeoPhysX::AverageAspect        { Grid }
#   GeoPhysX::AverageGradient      { Grid }
#
#   GeoPhysX::AverageTopo          { Grid }
#   GeoPhysX::AverageTopoLow       { Grid }
#   GeoPhysX::AverageTopoUSGS      { Grid }
#   GeoPhysX::AverageTopoCDED      { Grid { Res 250 } }
#   GeoPhysX::AverageTopoSRTM      { Grid }
#   GeoPhysX::AverageTopoASTERGDEM { Grid }
#   GeoPhysX::AverageTopoGMTED2010 { Grid { Res 30 } }
#
#   GeoPhysX::AverageMask          { Grid }
#   GeoPhysX::AverageMaskUSNavy    { Grid } 
#   GeoPhysX::AverageMaskUSGS      { Grid }
#   GeoPhysX::AverageMaskUSGS_R    { Grid }
#   GeoPhysX::AverageMaskCANVEC    { Grid }
#   GeoPhysX::AverageMaskGLOBCOVER { Grid }
#
#   GeoPhysX::AverageGeoMaskCANADA { Grid }
#
#   GeoPhysX::AverageVege          { Grid }
#   GeoPhysX::AverageVegeUSGS      { Grid }
#   GeoPhysX::AverageVegeEOSD      { Grid }
#   GeoPhysX::AverageVegeCORINE    { Grid }
#   GeoPhysX::AverageVegeGLOBCOVER { Grid }
#   GeoPhysX::AverageVegeCCRS      { Grid }
#   GeoPhysX::AverageVegeLCC2000V  { Grid }
#   GeoPhysX::DominantVege         { Grid }
#
#   GeoPhysX::AverageSoil          { Grid }
#   GeoPhysX::AverageSand          { Grid }
#   GeoPhysX::AverageClay          { Grid }
#   GeoPhysX::AverageSoilHWSD      { Grid }
#   GeoPhysX::AverageSoilJPL       { Grid }
#
#   GeoPhysX::SubCorrectionFilter  { FieldRes FieldDX FieldDY DBR C1 C2 }
#   GeoPhysX::SubCorrectionFactor  { }
#   GeoPhysX::SubTopoFilter        { }
#   GeoPhysX::SubLaunchingHeight   { }
#   GeoPhysX::SubLaunchingHeightSplit { }
#   GeoPhysX::SubY789              { }
#   GeoPhysX::SubY789Split         { }
#   GeoPhysX::SubRoughnessLength   { }
#
#   GeoPhysX::CheckConsistencyStandard { }
#   GeoPhysX::Diag                     { }
#============================================================================

namespace eval GeoPhysX { } {
   variable Param
   variable Const
   global env

   set Param(Version)   1.4

   #----- Specific data information

   set Param(SandTypes)    { 1 2 3 4 5 }
   set Param(ClayTypes)    { 1 2 3 4 5 }
   set Param(VegeTypes)    { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 }
   set Param(VegeCrops)    { 15 16 17 18 19 20 }
   set Param(VegeTree)     { 4 5 6 7 8 9 25 26 }
#   set Param(VegeTree_Eco) { 4 5 6 7 8 9 18 25 26 }
   #  new VF18 represent tropical & sub trop mixed forest shrubs
   #  new VF19 represent temperate grassland evergreen needle leafs trees
   set Param(VegeTree_Eco) { 4 5 6 7 8 9 18 19 25 26 }

   set Param(VegeZ0vTypes) { 0.001 0.0003 0.001 1.5 3.5 1.0 2.0 3.0 0.8 0.05 0.15 0.15 0.02
                            0.08 0.08 0.08 0.35 0.25 0.1 0.08 1.35 0.01 0.05 0.05 1.5 0.05 }
   # values decided by Stephane Belair for local Z0 computation using GLAS tree height   27/03/2015
   # pour CANOPY_LT seul.
   set Param(Z0M_VegeZ0)  {0.001 0.001 0.001 1.75 2.0 1.0 2.0 3.0 0.8 0.1  0.2  0.2  0.1  0.1  0.15 0.15 0.35 0.25 0.10 0.25 0.75  0.1  0.1  0.1  1.75 0.5}
#   set Param(Z0M_VegeZ0_Eco)  {0.001 0.001 0.001 1.75 2.0 1.0 2.0 3.0 0.8 0.1  0.2  0.2  0.1  0.15  0.15 0.15 0.15 1.75 0.10 0.25 0.75  0.1  0.1  0.1  1.75 0.5}
   set Param(Z0M_VegeZ0_Eco)  {0.001 0.001 0.001 1.75 2.0 1.0 2.0 3.0 0.8 0.1  0.2  0.2  0.1  0.15  0.15 0.15 0.15 1.75 1.75 0.25 0.75  0.1  0.1  0.1  1.75 0.5}
   set Param(Z0M_VegeZ0_CCILCWE) {0.001 0.001 0.001 1.75 2.0 1.0 2.0 3.0 0.8 0.1 0.1 0.2 0.05 0.2 0.10 0.15 0.15 0.25 0.10 0.25 0.75 0.01 0.1 0.1 1.75 0.5}

   #----- Constants definitions

   set Const(beta)    2.          ;# Slope of the orographic power spectrum
   set Const(lhmin)   3.0         ;# Minimum value acceptable for launching height field LH
                                   #   in meters, used in the calculation of LH, Y7, Y8 and Y9
                                   #   (if LH < lhmin, these fields are set to zero)
   set Const(mgmin)   0.001       ;# Threshold value of land-water mask field (MG), used in the
                                   #   calculation of the topographic component of the roughness
                                   #   length
   set Const(gamin)   0.001       ;# Threshold value of glacier fraction (GA), used in the
                                   #   calculation of the roughness length over soil and glacier
   set Const(z0min)   0.0001      ;# Threshold value of roughness length in meters, used to identify
                                   #   some "gaps" in the roughness length field
   set Const(z0minUr) 0.75      ;# minimal urban value of roughness length in meters, when VCH is nil
   set Const(gaz0)    0.0003      ;# Roughness length for glacier-type surfaces
   set Const(waz0)    0.001       ;# Roughness length for water
   set Const(lres)    5000.0      ;# Horizontal reference scale (5000 m) for topography features,
                                   #   used to separate subgrid scales among the fields:
                                   #     - LH,Y7,Y8,Y9 (which should use scales > 5000 m)
                                   #     - Z0,ZP       (which should use scales < 5000 m)
   set Const(drgcoef) 0.40        ;# Drag coefficient used in the formula of roughness length
   set Const(karman)  0.40        ;# von Karman constant
   set Const(slpmin)  0.001       ;# Threshold value for slope parameter, used in the calculation
                                   #   of the topographic component of the roughness length
   set Const(sssmin)  20.0        ;# Threshold value of the standard deviation of the
                                   #   small-scale subgrid (< 5000 m)topography
   set Const(zrefmin) 10.0        ;# Threshold value for reference height, used in the calculation
                                   #   of the roughness length
   set Const(z0def)   0.00001     ;# Default value of the roughness length in meters, used to
                                   #   fill in some "gaps" in the roughness length field
   set Const(zpdef)   -11.51      ;# = ln(z0def)
   set Const(largec0) 8.0         ;# Large scale resolution dependent correction factor
   set Const(largec1) 16.0        ;# Large scale resolution dependent correction factor
   set Const(smallc0) 2.0         ;# Small scale resolution dependent correction factor
   set Const(smallc1) 15.0        ;# Small scale resolution dependent correction factor

   set Const(ResoUSGS) [expr 1./120]
   set Const(ResoGTOPO30) [expr 30.0/3600]
   set Const(Deg2Rad)  [expr atan(1)*8/360.0]

   #----- Correspondance de Camille Garnaud de Fevrier 2015 pour la conversion des classes AAFC CROP vers les classes RPN
#   set Const(AAFC2RPN) { {   0  10  20 30 34 50 80 110 120 122 130 131 132 133 135 136 137 138 139 140 147 150 151 152 153 154 155 156 157 158 162 167 174 175 180 193 194 195 196 197 198 199 200 210 220 230 }
#                         { -99 -99   3 24 21 10 23  14  15  13  23  14  15  15  18  15  15  15  15  15  18  15  15  15  15  15  15  15  15  15  20  20  20  20  20  20  15  15  15  15  15  15  25   4   7  25 } }
   #----- Correspondance de Camille Garnaud de Mars 2015 pour la conversion des classes AAFC CROP 2014 vers les classes RPN
   set Const(AAFC2RPN) { {   0  10 19 20 30 34 35 50 80 110 120 121 122 130 131 132 133 134 135 136 137 138 139 140 141 145 146 147 148 149 150 151 152 153 154 155 156 157 158 160 161 162 167 174 175 176 177 178 179 180 181 183 188  189 190 191 192 193 194 196 197 198 199 200 210 220 230 }
                         { -99 -99  2  3 24 21 21 11 23  14  15  15  13  23  14  15  15  15  15  15  15  15  15  15  14  15  15  15  15  15  15  15  15  15  15  15  15  15  15  15  15  20  20  15  20  20  20  20  20  20  20  20   7   20  11  15  15  20  20  20  15  15  15  25   4   7  25 } }


   #----- Correspondance de St�phane B�lair de Novembre 2007 pour la conversion des classes EOSD vers les classes RPN
#   set Const(EOSD2RPN) { {   0  11  12 20 21 31 32 33 40 51 52 81 82 83 100 211 212 213 221 222 223 231 232 233 }
#                         { -99 -99 -99  3  1  2 24 24 22 10 10 25 10 13  14   4   4   4   7   7   7  25  25  25 } }

   #----- Correspondance de St�phane B�lair revisee Mars 2015 pour la conversion des classes EOSD vers les classes RPN
   set Const(EOSD2RPN) { {   0   10  11  12 20 21 30 31 32 33 34 40 50 51 52 80 81 82 83 100 110 120 121 122 200 210 211 212 213 220 221 222 223 230 231 232 233 }
                         { -99  -99 -99 -99  3  1 24  2 24 24 21 22 10 10 10 23 25 10 13  14  14  15  15  15  25   4   4   4   4   7   7   7   7  25  25  25  25 } }

   #----- Correspondance de Janna Lindenberg de Decembre 2007 pour la conversion des classes CORINE vers les classes RPN
   set Const(CORINE2RPN) { {  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 }
                           { 21 21 21 21 21 21 24 24 24 14 20 20 20 16 18 18 18 18 18 18 18 18  5  5 25 14 14 14 14 14 24 10 10  2 11 11  1  1  1  1  1  1  1  1 } }

   #----- Correspondance de Stephane Belair Decembre 2008 pour la conversion des classes GlobCover vers les classes RPN
   set Const(GLOBCOVER2RPN) { { 220 210 70 40 90 50 60 30 120 230 14 20 11 190 150 160 170 180 200 100 110 130 }
                              {   2   3  4  5  6  7  7 14  14  14 15 15 20  21  22  23  23  23  24  25  26  26 } }
   #----- Correspondance de Douglas Chan Juin 2009 pour la conversion des classes GlobCover vers les classes RPN
   set Const(GLOBCOVER2RPN) { { 220 210 70 40 90 50 60 30 120 140 230 14 20 11 190 150 160 170 180 200 100 110 130 }
                              {   2   3  4  5  4  7  7 14  14  14  24 15 15 20  21  24  23  23  23  24  25  26  26 } }

   #----- Sept 2015 : en se basant sur GlobCover, pour la conversion des classes ESA CCI LC 2010 vers les classes RPN (released 2014-10-01)
#   set Const(CCI_LC2RPN) { {  0 220 210 70 71 50 72 80 81 82 60 61 62 40 130 10 11 12 30 20 190 140 150 152 153 160 170 180 200 201 202 90 100 110 120 121 122 } 
#                           {-99   2   3  4  4  5  6  6  6  6  7  7  7 14  13 15 13 15 15 20  21  22  22  22  22  23  23  23  24  24  24 25  26  26  26  10  11 } }
   #------ Dec 2016 : Correspondance revue par Sylvie Leroyer
#   set Const(CCI_LC2RPN) { {  0 220 210 70 71 50 72 80 81 82 60 61 62 40 130 10 11 12 30 20 190 140 150 152 153 160 170 180 200 201 202 90 100 110 120 121 122 } 
#                           {-99   2   3  4  4  5  4  6  6  6  7  7  7 14  13 15 15 15 15 20  21  22  22  22  22  23  23  23  24  24  24 25  26  26  11  10  11 } }
   # ajoute 151 en prevision de la version 2.0.7 et 211 pour inclusion de Ocean and Inland Water Body v4.0
   set Const(CCI_LC2RPN) { {  0 211 220 210 70 71 72 50 80 81 82 60 61 62 40 130 10 11 12 30 20 190 140 150 151 152 153 160 170 180 200 201 202 90 100 110 120 121 122 123 }
                           {-99   1   2   3  4  4  4  5  6  6  6  7  7  7 14  13 15 15 15 15 20  21  22  22  22  22  22  23  23  23  24  24  24 25  26  26  11  10  11  12 } }

   set Const(CCI_LC2RPN-WE) { {  0 211 220 210 70 71 72 50 80 81 82 60 61 62 40 130 10 11 12 16 17 30 20 190 140 150 151 152 153 160 170 180 200 201 202 90 100 110 120 121 122 123 }
                             {-99   1   2   3  4  4  4  5  6  6  6  7  7  7 14  13 15 15 15 16 17  15  20  21  22  22  22  22  22  23  23  23  24  24  24 25  26  26  11  10  11  12 } }

   #----- Correspondance de Douglas Chan Mai 2010 pour la conversion des classes GCL2000 vers les classes RPN
   set Const(GLC20002RPN) { { 1 2 3 4 5 6   7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22  23 200}
                            { 5 7 7 4 6 25 23 23 25 25 26 11 13 13 23 15 15 15 24  3  2 21 -99 1 } }

   #----- Correspondance de Stephane Belair decembre 2008 pour la conversion des classes CCRS vers les classes RPN
   set Const(CCRS2RPN) { { 39 37 38 1 3 4 6 7 8 9 10 5 2 11 12 16 20 18 17 26 27 28 29 36 21 22 23 24 25 19 32 30 33 34 35 13 14 15 31 }
                         {  2  3  3 4 4 4 4 4 4 4  4 6 7  7  7 11 12 13 14 15 15 15 15 21 22 22 22 22 22 23 23 24 24 24 24 25 25 25 26 } }
   #----- Correspondance de Douglas Chan Juin 2009 pour la conversion des classes CCRS vers les classes RPN
   set Const(CCRS2RPN) { { 39 37 38 1  3  4  5 6 7  8  9 10 2 11 12 16 20 18 17 26 27 28 29 36 21 22 23 24 25 19 32 30 33 34 35 13 14 15 31 }
                         {  2  3  3 4 25 25 25 4 4 26 22 23 7  7  7 11 14 13 14 15 15 15 15 21 13 13 13 13 13 23 23 22 24 24 24 25 25 25 23 } }

   #----- Correspondance de Sylvie Leroyer Decembre 2010 pour la conversion des classes LCC2000V vers les classes RPN
   set Const(LCC2000V2RPN) { {   0   10  11  12 20 30 31 32 33 34 35 36 37 40 50 51 52 53 80   81        82        83      100 101 102 103 104 110 121 122  123     200 210 211 212 213 220 221 222 223 230 231 232 233 }
                             { -99 -99  -99 -99  3 24  2 24 24 21 24 24 24 22 26 11 11 22 23 { 25 23 } { 26 23 } { 13 23 }  13  22  14  22  22  14  15  15 { 15 13 } 25   4   4   4   4  7    7   7   7  25  25  25  24 } }

   #----- Correspondance de Shailesh Kharol fevrier 2015 pour la conversion de classes MCD12Q1 IGBP Land Cover Type 1 vers les classes RPN
   #----- New MCD12Q1 correspondance table based on Shailesh recommendation
   set Const(MODIS2RPN) { { 0 1 2 3 4  5  6  7  8  9 10 11 12 13 14 15 16 254 255 }
                          { 3 4 5 6 7 25 10 26  4 26 13 23 15 21 15  2 24 -99 -99 } }

   #----- Juin 2016 : en se basant sur la meme correspondance utilise pour creer USGS en format RPN par Judith St-James
   set Const(USGS_BATS2RPN) { {  1  2  3  4  5  6  7  8   9  10  11  12  13  14  15  16  17  18  19  20  21  99 100 }
                              { 15 13  4  6  7  5 14  24 22  20  24   2  23   3   1  10  11  25  26  23  21 -99 -99 } }

   #----- New NALCMS correspondance table, very similar to MODIS
   set Const(NALCMS2RPN) { {   0 1  2 3 4 5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 }
                           {   1 4 26 5 7 7 25 11 11 14 13 11 22 22 23 15 24 21  3  2 } }

   set Const(SLOP_MAX_ANGLE)    45.          ;# Max angle of Slope in computation of SLOP field

   #----- Options
   set Opt(SubSplit)     False
   set Opt(LegacyMode)   False
   set Opt(SlopOnly)     False
   set Opt(LinearNodata) True
   
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopo>
# Creation : Octobre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography on multiple grids (staggering) through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topo
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopo { Grid } {
   variable Opt

   GenX::Procs

   fstdfield copy GPXME  $Grid
   fstdfield copy GPXRMS $Grid
   fstdfield copy GPXRES $Grid
   fstdfield copy GPXTSK $Grid
   
   GenX::GridClear GPXME  0.0
   GenX::GridClear GPXRES 0.0
   GenX::GridClear GPXRMS 0.0
   GenX::GridClear GPXTSK 1.0

   fstdfield  configure GPXME  -rendertexture 1 -interpdegree NEAREST

   if { $Opt(SubSplit) } {
      fstdfield copy GPXGXX  $Grid
      fstdfield copy GPXGYY  $Grid
      fstdfield copy GPXGXY  $Grid
      GenX::GridClear GPXGXX  0.0
      GenX::GridClear GPXGYY  0.0
      GenX::GridClear GPXGXY  0.0
   }

   # we need accuracy of real*8 as what's found in Genesis 
   if { $Opt(LegacyMode) } {
      Log::Print INFO "Averaging topography using Legacy weighted averaging (Genesis)"
      GenX::CreateTypedField  GPXWESUM $Grid Float64 0.0
      GenX::CreateTypedField  GPXMESUM $Grid Float64 0.0
#      fstdfield  configure GPXWESUM  -rendertexture 1 -interpdegree NEAREST
   }

   foreach topo $GenX::Param(Topo) {
      switch $topo {
         "USGS"      { GeoPhysX::AverageTopoUSGS      GPXME     ;#----- USGS topograhy averaging method (Global 900m) }
         "SRTM"      { GeoPhysX::AverageTopoSRTM      GPXME $topo  ;#----- STRMv4 topograhy averaging method (Latitude -60,60 90m or 30m) }
         "SRTM30"    { GeoPhysX::AverageTopoSRTM      GPXME $topo  ;#----- STRMv4 topograhy averaging method (Latitude -60,60 30m) }
         "SRTM90"    { GeoPhysX::AverageTopoSRTM      GPXME $topo  ;#----- STRMv4 topograhy averaging method (Latitude -60,60 90m) }
         "CDED50"    { GeoPhysX::AverageTopoCDED      GPXME 50  ;#----- CDED50 topograhy averaging method (Canada 90m) }
         "CDED250"   { GeoPhysX::AverageTopoCDED      GPXME 250 ;#----- CDED250 topograhy averaging method (Canada 25m) }
         "ASTERGDEM" { GeoPhysX::AverageTopoASTERGDEM GPXME     ;#----- ASTERGDEM topograhy averaging method (Global but south pole 25m) }
         "GTOPO30"   { GeoPhysX::AverageTopoGTOPO30   GPXME     ;#----- GTOPO30 topograhy averaging method (Global  900m) }
         "GMTED30"   { GeoPhysX::AverageTopoGMTED2010 GPXME 30  ;#----- GMTED2010 topograhy averaging method (Global  900m) }
         "GMTED15"   { GeoPhysX::AverageTopoGMTED2010 GPXME 15  ;#----- GMTED2010 topograhy averaging method (Global  450m) }
         "GMTED75"   { GeoPhysX::AverageTopoGMTED2010 GPXME 75  ;#----- GMTED2010 topograhy averaging method (Global  225m) }
         "CDEM"      { GeoPhysX::AverageTopoCDEM      GPXME     ;#----- CDEM topograhy averaging method (Canada 25m) }
         "FABDEM"    { GeoPhysX::AverageTopoFABDEM    GPXME     ;#----- FABDEM topograhy averaging method (Global 30m) }
      }
   }

   fstdfield gridinterp GPXME - NOP True

   if { $Opt(LegacyMode) } {
      vexpr (Float64)GPXMEWE  "ifelse(GPXWESUM>0.0,GPXMESUM/GPXWESUM,0.0)"
      fstdfield stats GPXME -datacopy GPXMEWE
      fstdfield free GPXMEWE  GPXMESUM GPXWESUM
   }

   #----- avoid saving the mask, that would appears as 2nd MENF field
   fstdfield stats GPXME -mask ""
   #----- Save output
   fstdfield define GPXME -NOMVAR MENF -ETIKET $GenX::Param(ETIKET) -IP2 0
   fstdfield write GPXME GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Process RMS and resolution only for unstaggered grids
   if { !$GenX::Param(TopoStag) || $GenX::Param(Process)==0 } {
   
      #----- Save RMS
      fstdfield gridinterp GPXRMS - NOP True
      vexpr GPXRMS sqrt(GPXRMS)
      fstdfield define GPXRMS -NOMVAR MRMS -ETIKET $GenX::Param(ETIKET) -IP1 1200
      fstdfield write GPXRMS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

      #----- Save resolution
      fstdfield define GPXRES -NOMVAR MRES -ETIKET $GenX::Param(ETIKET) -IP1 1200
      fstdfield write GPXRES GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   #----- Finalize derivatives if applicable
   if { $Opt(SubSplit) } {
      fstdfield gridinterp GPXGXX - NOP True
      fstdfield gridinterp GPXGYY - NOP True
      fstdfield gridinterp GPXGXY - NOP True
      fstdfield define GPXGXX -NOMVAR GXX -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield define GPXGYY -NOMVAR GYY -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield define GPXGXY -NOMVAR GXY -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXGXX GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXGYY GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXGXY GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   fstdfield free GPXRMS GPXRES GPXTSK
   if { $Opt(SubSplit) } {
      fstdfield free GPXGXX GPXGYY GPXGXY
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoUSGS>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography using USGS.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoUSGS { Grid } {
   variable Opt
   variable Param
   variable Const

   GenX::Procs TopoUSGS
   Log::Print INFO "Averaging topography using USGS database"

   set  has_data  0
   #----- Loop over files
   foreach file [glob $GenX::Param(DBase)/$GenX::Path(TopoUSGS)/*] {
      Log::Print DEBUG "   Processing USGS file : $file"

      fstdfile open GPXTOPOFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXTOPOFILE -1 "" -1 -1 -1 "" "ME"] {

         Log::Print DEBUG "      Processing field : $field"
         fstdfield read USGSTILE GPXTOPOFILE $field

         if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [fstdfield define USGSTILE -georef]]]] } {
            continue
         }

         fstdfield stats USGSTILE -nodata -99.0 -celldim $GenX::Param(Cell)
         set  has_data  1
         if { $Opt(LegacyMode) } {
            vexpr  (Float64)WEIGHTTILE  "cos(dlat(USGSTILE)*$Const(Deg2Rad))*$Const(ResoUSGS)*$Const(ResoUSGS)"
            # avoid missing values -99 found in the data
            vexpr  (Float64)WTOPOTILE   "ifelse(USGSTILE!=-99.0,USGSTILE*WEIGHTTILE,0.0)"
            fstdfield gridinterp GPXMESUM WTOPOTILE  SUM
            fstdfield gridinterp GPXWESUM WEIGHTTILE SUM
            fstdfield free WTOPOTILE WEIGHTTILE
         } else {
            fstdfield gridinterp $Grid USGSTILE AVERAGE False         
         }

         if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
            Log::Print DEBUG "      Generating Subgrid  with field : $field"
            fstdfield gridinterp $Grid USGSTILE SUBLINEAR 11
         }
         
         fstdfield gridinterp GPXRMS USGSTILE AVERAGE_SQUARE False

         # Compute tile derivatives on request
         if { $Opt(SubSplit) } {
            GeoPhysX::AverageDerivTile $Grid USGSTILE
         }

      }
      fstdfile close GPXTOPOFILE
   }
   fstdfield free USGSTILE 

   if { $has_data == 0 } {
      if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
         Log::Print WARNING " No USGS Data found for this Grid, Will use GTOPO30 to initialize needed subgrid field in LegacySub"
         GeoPhysX::AverageTopoGTOPO30 $Grid
      }
   }

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),900.0,GPXRES)
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoGTOPO30>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography using GTOPO30.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoGTOPO30 { Grid } {
   variable Opt
   variable Const

   GenX::Procs GTOPO30
   Log::Print INFO "Averaging topography using GTOPO30 database"

   #----- Loop over files
   foreach file [glob $GenX::Param(DBase)/$GenX::Path(GTOPO30)/*.DEM] {
      Log::Print DEBUG "   Processing GTOPO30 file : $file"
      set bands [gdalfile open GTOPO30FILE read $file]
      if { [llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GTOPO30FILE]]]] } {
         gdalband read GTOPO30TILE $bands
         gdalband stats GTOPO30TILE -celldim $GenX::Param(Cell)

         #----- Replace nodata value with 0 meters
         vexpr GTOPO30TILE ifelse(GTOPO30TILE==-9999,0,GTOPO30TILE)

         if { $Opt(LegacyMode) } {
            vexpr  (Float64)WEIGHTTILE  "cos(dlat(GTOPO30TILE)*$Const(Deg2Rad))*$Const(ResoGTOPO30)*$Const(ResoGTOPO30)"
            # avoid missing values -9999 found in the data
            vexpr  (Float64)WTOPOTILE   "ifelse(GTOPO30TILE!=-9999,GTOPO30TILE*WEIGHTTILE,0.0)"
            fstdfield gridinterp GPXMESUM WTOPOTILE  SUM
            fstdfield gridinterp GPXWESUM WEIGHTTILE SUM
            fstdfield free WTOPOTILE WEIGHTTILE
         } else {
            fstdfield gridinterp $Grid GTOPO30TILE AVERAGE False         
         }
         if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
            fstdfield gridinterp $Grid GTOPO30TILE SUBLINEAR 11
         }
         
         fstdfield gridinterp GPXRMS GTOPO30TILE AVERAGE_SQUARE False

           # Compute tile derivatives on request
         if { $Opt(SubSplit) } {
             GeoPhysX::AverageDerivTile $Grid GTOPO30TILE
         }

      }
      gdalfile close GTOPO30FILE
   }
   gdalband free GTOPO30TILE

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),900.0,GPXRES)
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoASTERGDEM>
# Creation : Octobre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography using ASTER GDEM.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoASTERGDEM { Grid } {
   variable Param
   variable Opt

   GenX::Procs ASTERGDEM
   Log::Print INFO "Averaging topography using ATSERGDEM database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]

   foreach file [GenX::ASTERGDEMFindFiles $la0 $lo0 $la1 $lo1] {
      Log::Print DEBUG "   Processing ATSERGDEM file $file"
      gdalband read ATSERGDEMTILE [gdalfile open ATSERGDEMFILE read $file]
      gdalband stats ATSERGDEMTILE -nodata -9999 -celldim $GenX::Param(Cell)

      fstdfield gridinterp $Grid ATSERGDEMTILE AVERAGE False
      if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
         fstdfield gridinterp $Grid ATSERGDEMTILE SUBLINEAR 11
      }
      
      fstdfield gridinterp GPXRMS ATSERGDEMTILE AVERAGE_SQUARE False
 
      # Compute tile derivatives on request
      if { $Opt(SubSplit) } {
          GeoPhysX::AverageDerivTile $Grid ASTERGDEMTILE
      }

      gdalfile close ATSERGDEMFILE
   }
   gdalband free ATSERGDEMTILE

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),25,GPXRES)

   #----- Use accumulator to figure out coverage in destination
   #----- But remove border of coverage since it will not be full
   #----- Apply coverage mask for next resolution
   fstdfield gridinterp $Grid - ACCUM
   vexpr GPXTSK !fpeel($Grid)
   fstdfield stats $Grid -mask GPXTSK
   fstdfield stats GPXRMS -mask GPXTSK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoSRTM>
# Creation : Octobre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography using SRTM.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoSRTM { Grid {db SRTM} } {
   variable Param
   variable Opt

   Log::Print INFO "Averaging topography using $db database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]

   GenX::SRTMsetSelection  $db

   if { [GenX::SRTMuseVersion3] } {
      set d 30
      GenX::Procs SRTM30
   } else {
      set d 90
      GenX::Procs SRTM90
   }

   foreach file [GenX::SRTMFindFiles $la0 $lo0 $la1 $lo1] {
      Log::Print DEBUG "   Processing SRTM file $file"
      gdalband read SRTMTILE [gdalfile open SRTMFILE read $file]

      gdalband stats SRTMTILE -celldim $GenX::Param(Cell)

      fstdfield gridinterp $Grid SRTMTILE AVERAGE False
      if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
         fstdfield gridinterp $Grid SRTMTILE SUBLINEAR 11
      }
      
      fstdfield gridinterp GPXRMS SRTMTILE AVERAGE_SQUARE False

      # Compute tile derivatives on request
      if { $Opt(SubSplit) } {
          GeoPhysX::AverageDerivTile $Grid SRTMTILE
      }

      gdalfile close SRTMFILE
   }
   gdalband free SRTMTILE

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),$d,GPXRES)

   #----- Use accumulator to figure out coverage in destination
   #----- But remove border of coverage since it will not be full
   #----- Apply coverage mask for next resolution
   fstdfield gridinterp $Grid - ACCUM
   vexpr GPXTSK !fpeel($Grid)
   fstdfield stats $Grid -mask GPXTSK
   fstdfield stats GPXRMS -mask GPXTSK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoCDED>
# Creation : Octobre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography using CDED.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoCDED { Grid { Res 250 } } {
   variable Param
   variable Opt

   GenX::Procs CDED
   Log::Print INFO "Averaging topography using CDED(1:${Res}000) database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"

   set  nodata [expr $Res==50?-32767:0]
   foreach file [GenX::CDEDFindFiles $la0 $lo0 $la1 $lo1 $Res] {
      Log::Print DEBUG "   Processing CDED file $file"
      gdalband read CDEDTILE [gdalfile open CDEDFILE read $file]
      #gdalband stats CDEDTILE -nodata [expr $Res==50?-32767:0] -celldim $GenX::Param(Cell)
      gdalband stats CDEDTILE -nodata $nodata -celldim $GenX::Param(Cell)
      # for 250k, nodata are not always 0, many tiles are also -32767, and file's meta info on nodata
      # is unreliable, which makes it unusable. 
      # And we know there could be some topo height that could be up to hundreds meters below sea level
      # So we have no choice but to filter out all values below some threshold (-32000)
      if { $nodata == 0 } {
         vexpr CDEDTILE  "ifelse(CDEDTILE<-32000,0,CDEDTILE)"
      }

      fstdfield gridinterp $Grid CDEDTILE AVERAGE False
      if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
         fstdfield gridinterp $Grid CDEDTILE SUBLINEAR 11
      }
      
      fstdfield gridinterp GPXRMS CDEDTILE AVERAGE_SQUARE False

        # Compute tile derivatives on request
      if { $Opt(SubSplit) } {
          GeoPhysX::AverageDerivTile $Grid CDEDTILE
      }


      gdalfile close CDEDFILE
   }
   gdalband free CDEDTILE

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),[expr $Res==250?90:25],GPXRES)

   #----- Use accumulator to figure out coverage in destination
   #----- But remove border of coverage since it will not be full
   #----- Apply coverage mask for next resolution
   fstdfield gridinterp $Grid - ACCUM
   vexpr GPXTSK !fpeel($Grid)
   fstdfield stats $Grid -mask GPXTSK
   fstdfield stats GPXRMS -mask GPXTSK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoCDEM>
# Creation : March 2015 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Generate the topography using CDEM.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoCDEM { Grid } {
   variable Param
   variable Opt

   GenX::Procs CDEM
   Log::Print INFO "Averaging topography using CDEM database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"

   foreach file [GenX::CDEMFindFiles $la0 $lo0 $la1 $lo1] {
      Log::Print DEBUG "   Processing CDEM file $file"
      gdalband read CDEMTILE [gdalfile open CDEMFILE read $file]
      gdalband stats CDEMTILE -nodata -32767 -celldim $GenX::Param(Cell)

      fstdfield gridinterp $Grid CDEMTILE AVERAGE False
      if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
         fstdfield gridinterp $Grid CDEMTILE SUBLINEAR 11
      }
      
      fstdfield gridinterp GPXRMS CDEMTILE AVERAGE_SQUARE False

      # Compute tile derivatives on request
      if { $Opt(SubSplit) } {
          GeoPhysX::AverageDerivTile $Grid CDEMTILE
      }

      gdalfile close CDEMFILE
   }
   gdalband free CDEMTILE

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),25,GPXRES)

   #----- Use accumulator to figure out coverage in destination
   #----- But remove border of coverage since it will not be full
   #----- Apply coverage mask for next resolution
   fstdfield gridinterp $Grid - ACCUM
   vexpr GPXTSK !fpeel($Grid)
   fstdfield stats $Grid -mask GPXTSK
   fstdfield stats GPXRMS -mask GPXTSK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoGMTED2010>
# Creation : September 2013 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Generate the topography using GMTED2010
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#   <Res>    : resolution of dataset to use
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoGMTED2010 { Grid {Res 30} } {
   variable Opt
   variable Const

   GenX::Procs GMTED2010
   Log::Print INFO "Averaging topography using GMTED2010 md${Res} database"

   switch $Res {
     30 { set ResoTopo [expr 30.0/3600] }
     15 { set ResoTopo [expr 30.0/3600] }
     75 { set ResoTopo [expr 7.5/3600] }
   }

   # we use the mean instead of median because Antarctica and Groenland is missing in median products
   #----- Open the file
   gdalfile open GMTEDFILE read $GenX::Param(DBase)/$GenX::Path(GMTED2010)/products/mean/mn${Res}_grd.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GMTEDFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GMTED2010 database, topo will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with GMTED2010 database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read GMTEDTILE { { GMTEDFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats GMTEDTILE -celldim $GenX::Param(Cell)

            if { $Opt(LegacyMode) } {
               vexpr  (Float64)WEIGHTTILE  "cos(dlat(GMTEDTILE)*$Const(Deg2Rad))*$ResoTopo*$ResoTopo"
               # avoid missing values -9999 found in the data
               vexpr  (Float64)WTOPOTILE   "ifelse(GMTEDTILE!=-9999,GMTEDTILE*WEIGHTTILE,0.0)"
               fstdfield gridinterp GPXMESUM WTOPOTILE  SUM
               fstdfield gridinterp GPXWESUM WEIGHTTILE SUM
               fstdfield free WTOPOTILE WEIGHTTILE
            } else {
               fstdfield gridinterp $Grid GMTEDTILE AVERAGE False
            }
            if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
               fstdfield gridinterp $Grid GMTEDTILE SUBLINEAR 11
            }
            
            fstdfield gridinterp GPXRMS GMTEDTILE AVERAGE_SQUARE False
             
            # Compute tile derivatives on request
            if { $Opt(SubSplit) } {
                GeoPhysX::AverageDerivTile $Grid GMTEDTILE
            }

         }
      }
      gdalband free GMTEDTILE
   }
   gdalfile close GMTEDFILE

   #----- Create source resolution used in destination
   switch $Res {
      30 { set d  900.0 }
      15 { set d  450.0 }
      75 { set d  225.0 }
   }
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),$d,GPXRES)
   #----- Use accumulator to figure out coverage in destination
   #----- But remove border of coverage since it will not be full
   #----- Apply coverage mask for next resolution
   fstdfield gridinterp $Grid - ACCUM
   vexpr GPXTSK !fpeel($Grid)
   fstdfield stats $Grid -mask GPXTSK
   fstdfield stats GPXRMS -mask GPXTSK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoFABDEM>
# Creation : July 2022 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the topography using FABDEM
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :  Only partial coverage on southern part of Canada
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoFABDEM { Grid } {
   variable Param
   variable Const
   variable Opt

   GenX::Procs FABDEM
   Log::Print INFO "Averaging topography using FABDEM database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   set dbdir  $GenX::Param(DBase)/$GenX::Path(FABDEM)
   set files [GenX::FindFiles $dbdir/Index/Index.shp $Grid]

   #----- Loop over files
   if { [set nb [llength $files]] } {

      foreach file $files {
         Log::Print DEBUG "   Processing file ([incr n]/$nb) $dbdir/$file"

         gdalband read FABDEMTILE [gdalfile open FABDEMFILE read $dbdir/$file]

         gdalband stats FABDEMTILE -celldim $GenX::Param(Cell)

         if { $Opt(LegacyMode) } {
            vexpr  (Float64)WEIGHTTILE  "cos(dlat(FABDEMTILE)*$Const(Deg2Rad))*$Const(ResoUSGS)*$Const(ResoUSGS)"
            # avoid missing values -9999 found in the data
            vexpr  (Float64)WTOPOTILE   "ifelse(FABDEMTILE!=-9999.0,FABDEMTILE*WEIGHTTILE,0.0)"
            fstdfield gridinterp GPXMESUM WTOPOTILE  SUM
            fstdfield gridinterp GPXWESUM WEIGHTTILE SUM
            fstdfield free WTOPOTILE WEIGHTTILE
         } else {
            fstdfield gridinterp $Grid FABDEMTILE AVERAGE False
         }

         if { ($GenX::Param(Sub)=="LEGACY") || ($GenX::Param(Z0Topo)=="LEGACY") } {
            fstdfield gridinterp $Grid FABDEMTILE SUBLINEAR 11
         }
      
         fstdfield gridinterp GPXRMS FABDEMTILE AVERAGE_SQUARE False

      # Compute tile derivatives on request
         if { $Opt(SubSplit) } {
            GeoPhysX::AverageDerivTile $Grid FABDEMTILE
         }
         gdalfile close FABDEMFILE
      }
   } else {
      Log::Print WARNING "The grid is not within FABDEM limits"
   }
   gdalband free FABDEMTILE

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),30,GPXRES)

   #----- Use accumulator to figure out coverage in destination
   #----- But remove border of coverage since it will not be full
   #----- Apply coverage mask for next resolution
   fstdfield gridinterp $Grid - ACCUM
   vexpr GPXTSK !fpeel($Grid)
   fstdfield stats $Grid -mask GPXTSK
   fstdfield stats GPXRMS -mask GPXTSK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageAspect>
# Creation : June 2006 - Alexandre Leroux, J.P. Gauthier - CMC/CMOE
# Revision : March 2015 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Generate the slope and aspect through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topography
#
# Return:
#
# Remarks :
#     NVAR     IP3      Desc
#     FSA0     0        Average aspect
#     FSA      0        Fraction of aspect north quadrant oriented
#     FSA      90       Fraction of aspect east quadrant oriented
#     FSA      180      Fraction of aspect south quadrant oriented
#     FSA      270      Fraction of aspect west quadrant oriented
#
#     SLA0     0        Average slope
#     SLA      0        Average slope with aspect north quadrant oriented
#     SLA      90       Average slope with aspect east quadrant oriented
#     SLA      180      Average slope with aspect south quadrant oriented
#     SLA      270      Average slope with aspect west quadrant oriented
#----------------------------------------------------------------------------
proc GeoPhysX::AverageAspect { Grid } {
   variable Param
   variable Const
   variable Opt

   Log::Print INFO "Computing slope and aspect"
   if { $Opt(SlopOnly) } {
      Log::Print INFO "Opt(SlopOnly)=$Opt(SlopOnly) : Will generate SLOP only"
   }

   set  dbused {}

   set SRTM  0
   set CDED 0
   set CDEM 0
   set GTOPO30 0
   set USGS 0
   set GMTED 0

   if { [GenX::SRTMsetSelection $GenX::Param(Aspect)] } {
      if { [GenX::SRTMuseVersion3] } {
         set SRTM  30
         lappend dbused SRTM30
      } else {
         set SRTM  90
         lappend dbused SRTM90
      }
   }

   if { [lsearch -exact $GenX::Param(Aspect) CDED250]!=-1 } {
      set CDED 250
      lappend dbused CDED250
   }
   if { [lsearch -exact $GenX::Param(Aspect) CDED50]!=-1 } {
      set CDED 50
      lappend dbused CDED50
   }
   if { [lsearch -exact $GenX::Param(Aspect) CDEM]!=-1 } {
      set CDEM 1
      lappend dbused CDEM
   }
   if { [lsearch -exact $GenX::Param(Aspect) GTOPO30]!=-1 } {
      set GTOPO30 1
      lappend dbused GTOPO30
   }
   if { [lsearch -exact $GenX::Param(Aspect) USGS]!=-1 } {
      set USGS 1
      lappend dbused USGS
   }
   if { [lsearch -exact $GenX::Param(Aspect) GMTED30]!=-1 } {
      set GMTED 30
      lappend dbused GMTED30
   }
   if { [lsearch -exact $GenX::Param(Aspect) GMTED15]!=-1 } {
      set GMTED 15
      lappend dbused GMTED15
   }
   if { [lsearch -exact $GenX::Param(Aspect) GMTED75]!=-1 } {
      set GMTED 75
      lappend dbused GMTED75
   }

   GenX::Procs $dbused

   fstdfield copy GPXSLA  $Grid
if { ! $Opt(SlopOnly) } {
   fstdfield copy GPXFSA  $Grid
   fstdfield copy GPXFSAN $Grid
   fstdfield copy GPXFSAE $Grid
   fstdfield copy GPXFSAS $Grid
   fstdfield copy GPXFSAW $Grid
   fstdfield copy GPXSLAN $Grid
   fstdfield copy GPXSLAE $Grid
   fstdfield copy GPXSLAS $Grid
   fstdfield copy GPXSLAW $Grid
}

   GenX::GridClear GPXSLA  -1
if { ! $Opt(SlopOnly) } {
   GenX::GridClear [list GPXFSA GPXFSAN GPXFSAE GPXFSAS GPXFSAW GPXSLAN GPXSLAE GPXSLAS GPXSLAW] -1
}

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   #----- Work tile resolution
   if { $CDEM && [llength [GenX::CDEMFindFiles $lat0 $lon0 $lat1 $lon1]] } {
      set res [expr (0.75/3600.0)]  ;# 0.75 arc-secondes CDED
   } elseif { $CDED==50 && [llength [GenX::CDEDFindFiles $lat0 $lon0 $lat1 $lon1]] } {
      set res [expr (0.75/3600.0)]  ;# 0.75 arc-secondes CDED
   } elseif { $SRTM } {
      if { [GenX::SRTMuseVersion3] } {
         set res [expr (1.0/3600.0)]   ;# 1 arc-secondes SRTM
      } else {
         set res [expr (3.0/3600.0)]   ;# 3 arc-secondes SRTM
      }
   } elseif { $CDED==250 } {
      set res [expr (3.75/3600.0)]  ;# 0.75 arc-secondes CDED
   } elseif { $USGS } {
      set res [expr (30.0/3600.0)]  ;# 30 arc-secondes GTOPO30
   } elseif { $GTOPO30 } {
      set res [expr (30.0/3600.0)]  ;# 30 arc-secondes GTOPO30
   } elseif { $GMTED==75 } {
      set res [expr (7.5/3600.0)]  ;# 7.5 arc-secondes CDED
   } elseif { $GMTED==15 } {
      set res [expr (15.0/3600.0)]  ;# 15 arc-secondes CDED
   } elseif { $GMTED==30 } {
      set res [expr (30.0/3600.0)]  ;# 30 arc-secondes CDED
   }

   set dpix [expr $GenX::Param(TileSize)*$res]
   Log::Print DEBUG "   Processing limits  $lat0,$lon0 to $lat1,$lon1 at resolution $res"

   #----- Create latlon referential since original data is in latlon
   georef create LLREF
   eval georef define LLREF -projection \{GEOGCS\[\"WGS 84\",DATUM\[\"WGS_1984\",SPHEROID\[\"WGS 84\",6378137,298.2572235629972,AUTHORITY\[\"EPSG\",\"7030\"\]\],AUTHORITY\[\"EPSG\",\"6326\"\]\],PRIMEM\[\"Greenwich\",0\],UNIT\[\"degree\",0.0174532925199433\],AUTHORITY\[\"EPSG\",\"4326\"\]\]\}

   set  nodata0  0
   #----- Create work tile with border included
   gdalband create DEMTILE [expr $GenX::Param(TileSize)+2] [expr $GenX::Param(TileSize)+2] 1 Int16
   gdalband define DEMTILE -georef LLREF
   gdalband stats DEMTILE -nodata $nodata0 -celldim $GenX::Param(Cell)

   #----- Create buffer tile for reading
   gdalband create DEMTILE2 [expr $GenX::Param(TileSize)+2] [expr $GenX::Param(TileSize)+2] 1 Int16
   gdalband define DEMTILE2 -georef LLREF
   gdalband stats  DEMTILE2 -nodata $nodata0 -celldim $GenX::Param(Cell)

   #----- Loop en grid data at tile resolution
   set xlo 0
   for { set lon $lon0 } { $lon<$lon1 } { set lon [expr $lon0+($xlo*$dpix)] } {
      incr xlo
      set xla 0
      for { set lat $lat0 } { $lat<$lat1 } { set lat [expr $lat0+($xla*$dpix)] }  {
         incr xla
         set la0 [expr $lat-$res]
         set lo0 [expr $lon-$res]
         set la1 [expr $lat+$dpix+$res]
         set lo1 [expr $lon+$dpix+$res]
         set data False
         gdalband clear DEMTILE
         gdalband define DEMTILE -transform [list $lo0 $res 0.0 $la0 0.0 $res]
         Log::Print DEBUG "   Processing area from $la0,$lo0 to $la1,$lo1"

         gdalband clear DEMTILE2
         gdalband define DEMTILE2 -transform [list $lo0 $res 0.0 $la0 0.0 $res]

         #----- Process STRM first, if asked for
         if { $SRTM && [llength [set srtmfiles [GenX::SRTMFindFiles $la0 $lo0 $la1 $lo1]]] } {
            foreach file $srtmfiles {
               GenX::CacheGet $file -32768
               Log::Print DEBUG "      Processing SRTM DEM file $file"
               gdalband gridinterp DEMTILE2 $file NEAREST
               vexpr DEMTILE  "ifelse(DEMTILE2!=$nodata0,DEMTILE2,DEMTILE)"
            }
            set data True
         }

         #----- Process CDED, if asked for
         if { $CDED && [llength [set dnecfiles [GenX::CDEDFindFiles $la0 $lo0 $la1 $lo1 $CDED]]] } {
            set nodata [expr $CDED==50?-32767:0]
            foreach file $dnecfiles {
               GenX::CacheGet $file $nodata
               Log::Print DEBUG "      Processing CDED DEM file $file"
               gdalband gridinterp DEMTILE2 $file NEAREST
            }
            set data True
            # nodata are not always 0, many tiles are also -32767, so need to filter them out
            vexpr DEMTILE2  "ifelse(DEMTILE2<-32000,0,DEMTILE2)"
            vexpr DEMTILE  "ifelse(DEMTILE2!=$nodata0,DEMTILE2,DEMTILE)"
            gdalband clear DEMTILE2
         }

         #----- Process CDEM, if asked for
         if { $CDEM && [llength [set cdemfiles [GenX::CDEMFindFiles $la0 $lo0 $la1 $lo1]]] } {
            foreach file $cdemfiles {
               GenX::CacheGet $file -32767
               Log::Print DEBUG "      Processing CDEM DEM file $file"
               gdalband gridinterp DEMTILE2 $file NEAREST
            }
            set data True
            vexpr DEMTILE  "ifelse(DEMTILE2!=$nodata0,DEMTILE2,DEMTILE)"
            gdalband clear DEMTILE2
         }

         #----- Process CDED, if asked for
         if { $GMTED } {
            set nodata  -32768
            gdalfile open GMTEDFILE read $GenX::Param(DBase)/$GenX::Path(GMTED2010)/products/mean/mn${GMTED}_grd.tif
            if { ![llength [set limits [georef intersect [gdalband define DEMTILE2 -georef] [gdalfile georef GMTEDFILE]]]] } {
               Log::Print WARNING "Specified grid does not intersect with GMTED2010 database, topo will not be calculated"
            } else {
               Log::Print INFO "Grid intersection with GMTED2010 database is { $limits }"
               set x0 [lindex $limits 0]
               set x1 [lindex $limits 2]
               set y0 [lindex $limits 1]
               set y1 [lindex $limits 3]
               #----- Loop over the data by tiles since it's too big to fit in memory
               for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
                  for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
                     Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
                     gdalband read GMTEDTILE { { GMTEDFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
                     gdalband stats GMTEDTILE -celldim $GenX::Param(Cell)
                     gdalband gridinterp DEMTILE2 GMTEDTILE NEAREST
		     vexpr DEMTILE  "ifelse(DEMTILE2!=$nodata0,DEMTILE2,DEMTILE)"
                  }
               }
               set data True
               #vexpr DEMTILE  "ifelse(DEMTILE2!=$nodata,DEMTILE2,DEMTILE)"
               gdalband clear DEMTILE2
            }
            gdalfile close GMTEDFILE
         }

         #----- Process GTOPO30, if asked for
         if { $GTOPO30 } {
            set nodata -9999
            foreach file [glob $GenX::Param(DBase)/$GenX::Path(GTOPO30)/*.DEM] {
               set bands [gdalfile open GTOPO30FILE read $file]
               if { ![llength [set limits [georef intersect [gdalband define DEMTILE2 -georef] [gdalfile georef GTOPO30FILE]]]] } {
                  gdalfile close GTOPO30FILE
                  continue
               } else {
                  gdalfile close GTOPO30FILE
               }
               GenX::CacheGet $file $nodata
               Log::Print DEBUG "   Processing GTOPO30 file : $file"
               gdalband gridinterp DEMTILE2 $file NEAREST
            }
            set data True
            vexpr DEMTILE2 "ifelse(DEMTILE2!=$nodata,DEMTILE2,0)"
            vexpr DEMTILE  "ifelse(DEMTILE2!=$nodata0,DEMTILE2,DEMTILE)"
            gdalband clear DEMTILE2
         }

   #----- Loop over files
         if { $USGS } {
            foreach file [glob $GenX::Param(DBase)/$GenX::Path(TopoUSGS)/*] {
               Log::Print DEBUG "   Processing USGS file : $file"
               fstdfile open GPXTOPOFILE read $file

               #----- Loop over fields (tiles)
               foreach field [fstdfield find GPXTOPOFILE -1 "" -1 -1 -1 "" "ME"] {
                  Log::Print DEBUG "   Checking field : $field"
                  fstdfield read USGSTILE GPXTOPOFILE $field
                  fstdfield  configure USGSTILE  -rendertexture 1 -interpdegree NEAREST
                  if { ![llength [set limits [georef intersect [gdalband define DEMTILE -georef] [fstdfield define USGSTILE -georef]]]] } {
                     continue
                  }
                  Log::Print DEBUG "      Processing field : $field"
                  fstdfield stats USGSTILE -nodata -99.0 -celldim $GenX::Param(Cell)
                  gdalband gridinterp DEMTILE2 USGSTILE NEAREST
               }
               vexpr DEMTILE  "ifelse(DEMTILE2!=$nodata0,DEMTILE2,DEMTILE)"
               gdalband clear DEMTILE2
               fstdfile close GPXTOPOFILE
            }
            set data True
         }

         #----- If the tile has data, process on destination grid
         if { $data } {
#set outfile gdal.$xla.$xlo.tif
#Log::Print DEBUG "      Saving DEMTILE: $outfile"
#file delete -force  $outfile
#gdalfile open FILEOUT write $outfile "GeoTIFF"
#gdalband write { DEMTILE } FILEOUT
#gdalfile close FILEOUT
            Log::Print DEBUG "   Computing slope and aspect per quadrant"
            georef define LLREF -border 1 
            GeoPhysX::AverageAspectTile $Grid DEMTILE
            georef define LLREF -border 0 
         }
      }
   }
   GenX::CacheFree
   fstdfield free USGSTILE

   #----- Finalize Aspect and Slope
   fstdfield gridinterp GPXSLA  - NOP True
   vexpr GPXSLA  max(GPXSLA,0);
if { ! $Opt(SlopOnly) } {
   fstdfield gridinterp GPXFSA  - NOP True
   fstdfield gridinterp GPXFSAN - NOP True
   fstdfield gridinterp GPXFSAE - NOP True
   fstdfield gridinterp GPXFSAS - NOP True
   fstdfield gridinterp GPXFSAW - NOP True

   fstdfield gridinterp GPXSLAN - NOP True
   fstdfield gridinterp GPXSLAE - NOP True
   fstdfield gridinterp GPXSLAS - NOP True
   fstdfield gridinterp GPXSLAW - NOP True

   vexpr GPXSLAN max(GPXSLAN,0);
   vexpr GPXSLAE max(GPXSLAE,0);
   vexpr GPXSLAS max(GPXSLAS,0);
   vexpr GPXSLAW max(GPXSLAW,0);

   vexpr GPXFSAN max(GPXFSAN,0);
   vexpr GPXFSAE max(GPXFSAE,0);
   vexpr GPXFSAS max(GPXFSAS,0);
   vexpr GPXFSAW max(GPXFSAW,0);
}

# filters out border artifact on lakes and Ocean, when other Topo are mixed with CDED or CDEM
#
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
      vexpr  GPXSLA  "ifelse(GPXMG==0,0.0,GPXSLA)"
if { ! $Opt(SlopOnly) } {
      vexpr  GPXFSA  "ifelse(GPXMG==0,-1.0,GPXFSA)"
      vexpr  GPXFSAN "ifelse(GPXMG==0,0.0,GPXFSAN)"
      vexpr  GPXFSAE "ifelse(GPXMG==0,0.0,GPXFSAE)"
      vexpr  GPXFSAS "ifelse(GPXMG==0,0.0,GPXFSAS)"
      vexpr  GPXFSAW "ifelse(GPXMG==0,0.0,GPXFSAW)"
      vexpr  GPXSLAN "ifelse(GPXMG==0,0.0,GPXSLAN)"
      vexpr  GPXSLAE "ifelse(GPXMG==0,0.0,GPXSLAE)"
      vexpr  GPXSLAS "ifelse(GPXMG==0,0.0,GPXSLAS)"
      vexpr  GPXSLAW "ifelse(GPXMG==0,0.0,GPXSLAW)"
}
      fstdfield free GPXMG
   }

# compute SLOP field as needed by SVS
# limit to max of 45 degree to avoid numerical problem
   vexpr GPXSLOP "tan(min(GPXSLA,$Const(SLOP_MAX_ANGLE))*$Const(Deg2Rad))"

   #----- Save everything
   fstdfield define GPXSLOP -NOMVAR SLOP -ETIKET $GenX::Param(ETIKET) -IP2 0
   fstdfield write GPXSLOP GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
if { ! $Opt(SlopOnly) } {
   fstdfield define GPXFSA  -NOMVAR FSA0 -ETIKET $GenX::Param(ETIKET) -IP2 0
   fstdfield define GPXFSAN -NOMVAR FSA  -ETIKET $GenX::Param(ETIKET) -IP2 0
   fstdfield define GPXFSAE -NOMVAR FSA  -ETIKET $GenX::Param(ETIKET) -IP2 90
   fstdfield define GPXFSAS -NOMVAR FSA  -ETIKET $GenX::Param(ETIKET) -IP2 180
   fstdfield define GPXFSAW -NOMVAR FSA  -ETIKET $GenX::Param(ETIKET) -IP2 270

   fstdfield define GPXSLA  -NOMVAR SLA0 -ETIKET $GenX::Param(ETIKET) -IP2 0
   fstdfield define GPXSLAN -NOMVAR SLA  -ETIKET $GenX::Param(ETIKET) -IP2 0
   fstdfield define GPXSLAE -NOMVAR SLA  -ETIKET $GenX::Param(ETIKET) -IP2 90
   fstdfield define GPXSLAS -NOMVAR SLA  -ETIKET $GenX::Param(ETIKET) -IP2 180
   fstdfield define GPXSLAW -NOMVAR SLA  -ETIKET $GenX::Param(ETIKET) -IP2 270

   fstdfield write GPXFSA  GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXFSAN GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXFSAE GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXFSAS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXFSAW GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield write GPXSLA  GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXSLAN GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXSLAE GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXSLAS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXSLAW GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
}

   fstdfield free GPXSLA GPXSLAN GPXSLAE GPXSLAS GPXSLAW GPXFSA GPXFSAN GPXFSAE GPXFSAS GPXFSAW GPXSLOP
   gdalband free DEMTILE DEMTILE2
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageDerivTile>
# Creation : 
#
# Goal     : Generate the directional derivatives of orography
#
# Parameters :
#   <Grid>   : Grid on which to generate the data.
#   <Band>   : Topo data.
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageDerivTile { Grid Band } {

   #----- Set constants
   set dgtord 3.14159265/180.

   #----- Calculate slope and aspect for the tile
   vexpr (Float32)SLOPE tan(dslopedeg($Band)*$dgtord)
   vexpr (Float32)ASP daspect($Band)*$dgtord

   #----- Calculate the derivatives in each geographic direction
   vexpr DHDNS SLOPE*cos(ASP)
   vexpr DHDEW SLOPE*sin(ASP)
   vexpr DHCROSS DHDNS*DHDEW

   #----- Average onto destination grid
   fstdfield gridinterp GPXGXX DHDEW AVERAGE_SQUARE False
   fstdfield gridinterp GPXGYY DHDNS AVERAGE_SQUARE False
   fstdfield gridinterp GPXGXY DHCROSS AVERAGE False
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageAspectTile>
# Creation : Septembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the aspect ratio and mean slope.
#
# Parameters :
#   <Grid>   : Grid on which to generate the data.
#   <Band>   : Topo data.
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageAspectTile { Grid Band } {
   variable Opt

   #----- Calculate slope and aspect for the tile
   vexpr (Int16)SLATILE dslopedeg($Band)
   vexpr (Int16)FSATILE daspect($Band)

if { ! $Opt(SlopOnly) } {
   #----- Define aspect ranges
   vexpr FSAN ifelse((FSATILE>315 || FSATILE<=45)  && SLATILE!=0.0,1,-1)
   vexpr FSAE ifelse((FSATILE>45  && FSATILE<=135) && SLATILE!=0.0,1,-1)
   vexpr FSAS ifelse((FSATILE>135 && FSATILE<=225) && SLATILE!=0.0,1,-1)
   vexpr FSAW ifelse((FSATILE>225 && FSATILE<=315) && SLATILE!=0.0,1,-1)

   #----- Set slope mask on the aspect ranges
   vexpr SLAN  ifelse(FSAN!=-1,SLATILE,-1)
   vexpr SLAE  ifelse(FSAE!=-1,SLATILE,-1)
   vexpr SLAS  ifelse(FSAS!=-1,SLATILE,-1)
   vexpr SLAW  ifelse(FSAW!=-1,SLATILE,-1)

   gdalband stats FSAN -nodata -1
   gdalband stats FSAE -nodata -1
   gdalband stats FSAS -nodata -1
   gdalband stats FSAW -nodata -1
   gdalband stats SLAN -nodata -1
   gdalband stats SLAE -nodata -1
   gdalband stats SLAS -nodata -1
   gdalband stats SLAW -nodata -1

   #----- Do the averaging on destination grid
   fstdfield gridinterp GPXFSAN FSAN COUNT False
   fstdfield gridinterp GPXFSAE FSAE COUNT False
   fstdfield gridinterp GPXFSAS FSAS COUNT False
   fstdfield gridinterp GPXFSAW FSAW COUNT False

   fstdfield gridinterp GPXSLAN SLAN AVERAGE False
   fstdfield gridinterp GPXSLAE SLAE AVERAGE False
   fstdfield gridinterp GPXSLAS SLAS AVERAGE False
   fstdfield gridinterp GPXSLAW SLAW AVERAGE False

   fstdfield gridinterp GPXFSA FSATILE VECTOR_AVERAGE False
}
   fstdfield gridinterp GPXSLA SLATILE AVERAGE False
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMask>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMask { Grid } {
   variable Param

   GenX::Procs

   switch $GenX::Param(Mask) {
      "USNAVY"    { GeoPhysX::AverageMaskUSNavy    $Grid }
      "USGS"      { GeoPhysX::AverageMaskUSGS      $Grid }
      "CANVEC"    { GeoPhysX::AverageMaskCANVEC    $Grid }
      "GLOBCOVER" { GeoPhysX::AverageMaskGLOBCOVER $Grid }
      "GLC2000"   { GeoPhysX::AverageMaskGLC2000   $Grid }
      "MCD12Q1"   { GeoPhysX::AverageMaskMCD12Q1   $Grid }
      "CCI_LC"    { GeoPhysX::AverageMaskCCI_LC    $Grid $GenX::Param(Mask) }
      "CCILC2015-ECO2017" { GeoPhysX::AverageMaskCCI_LC    $Grid $GenX::Param(Mask) }
      "CCILC2015-1" { GeoPhysX::AverageMaskCCI_LC    $Grid $GenX::Param(Mask) }
      "CCILC2015-3" { GeoPhysX::AverageMaskCCI_LC    $Grid $GenX::Param(Mask) }
      "CCILC2015-WE" { GeoPhysX::AverageMaskCCI_LC    $Grid $GenX::Param(Mask) }
      "CCILC2015" { GeoPhysX::AverageMaskCCI_LC    $Grid $GenX::Param(Mask) }
      "CCILC2010" { GeoPhysX::AverageMaskCCI_LC    $Grid $GenX::Param(Mask) }
      "AAFC"      { GeoPhysX::AverageMaskAAFC      $Grid }
      "USGS_R"    { GeoPhysX::AverageMaskUSGS_R    $Grid }
      "NALCMS"    { GeoPhysX::AverageMaskNALCMS    $Grid }
      "OSM"       { GeoPhysX::AverageMaskOSM       $Grid }
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskUSGS>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskUSGS { Grid } {

   GenX::Procs MaskUSGS
   Log::Print INFO "Averaging mask using USGS database"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

   #----- Loop over files
   foreach file [glob $GenX::Param(DBase)/$GenX::Path(MaskUSGS)/*] { 
      Log::Print DEBUG "   Processing file : $file"
      fstdfile open GPXMASKFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXMASKFILE -1 "" -1 -1 -1 "" "MG"] {
         Log::Print DEBUG "      Processing field : $field"
         fstdfield read MASKTILE GPXMASKFILE $field
         fstdfield stats MASKTILE -nodata -99.0 -celldim $GenX::Param(Cell)

         #----- Average on output grid
         fstdfield gridinterp GPXMASK MASKTILE AVERAGE False
      }
      fstdfile close GPXMASKFILE
   }

   #----- Save output
   fstdfield gridinterp GPXMASK - NOP True
   vexpr GPXMASK ifelse(GPXMASK==-99.0,0.0,GPXMASK/100.0)
   fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield free MASKTILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskUSNavy>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskUSNavy { Grid } {

   GenX::Procs MaskUSGS
   Log::Print INFO "Averaging mask using USNAVY database"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

   fstdfile open GPXMASKFILE read $GenX::Param(DBase)/$GenX::Path(MaskUSNavy)/masq_us.fst

   #----- Loop over fields (tiles)
   foreach field [fstdfield find GPXMASKFILE -1 "" -1 -1 -1 "" "MG"] {
      Log::Print DEBUG "      Processing field : $field"
      fstdfield read MASKTILE GPXMASKFILE $field
      fstdfield stats MASKTILE -nodata -99.0 -celldim $GenX::Param(Cell)

      #----- Average on output grid
      fstdfield gridinterp GPXMASK MASKTILE AVERAGE False
   }
   fstdfile close GPXMASKFILE

   #----- Save output
   fstdfield gridinterp GPXMASK - NOP True
   vexpr GPXMASK ifelse(GPXMASK==-99.0,0.0,GPXMASK/100.0)
   fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield free MASKTILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskGLOBCOVER>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskGLOBCOVER { Grid } {

   GenX::Procs GlobCover
   Log::Print INFO "Averaging mask using GLOBCOVER database"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

   #----- Open the file
   gdalfile open GLOBFILE read $GenX::Param(DBase)/$GenX::Path(GlobCover)/GLOBCOVER_L4_200901_200912_V2.3.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GLOBFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GLOBCOVER database, mask will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with GLOBCOVER database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read GLOBTILE { { GLOBFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats GLOBTILE -nodata 255 -celldim $GenX::Param(Cell)

            vexpr GLOBTILE ifelse(GLOBTILE==210,0.0,1.0)
            fstdfield gridinterp GPXMASK GLOBTILE AVERAGE False
         }
      }

      #----- Save output
      fstdfield gridinterp GPXMASK - NOP True
      fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      fstdfield free MASKTILE

      gdalband free GLOBTILE
   }
   gdalfile close GLOBFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskGLC2000>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskGLC2000 { Grid } {

   GenX::Procs GLC2000
   Log::Print INFO "Averaging mask using GLC2000 database"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

   #----- Open the file
   gdalfile open GLCFILE read $GenX::Param(DBase)/$GenX::Path(GLC2000)/glc2000_v1_1-glcc_bats.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GLCFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GLC2000 database, mask will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with GLC2000 database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read GLCTILE { { GLCFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats GLCTILE -nodata 255 -celldim $GenX::Param(Cell)

            vexpr GLCTILE ifelse(GLCTILE==20 || GLCTILE==200,0.0,1.0)
            fstdfield gridinterp GPXMASK GLCTILE AVERAGE False
         }
      }

      #----- Save output
      fstdfield gridinterp GPXMASK - NOP True
      fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

      gdalband free GCLTILE
   }
   gdalfile close GLCFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskCANVEC>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging using vectorial data.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskCANVEC { Grid } {
   variable Path
   variable Param

   GenX::Procs CANVEC
   Log::Print INFO "Averaging mask using CANVEC database"

#  complete CANVEC mask with a precomputed mask given by $Path(FallbackMask) 
#  or a mask to be computed as defined by $Param(FallbackMask) if available
#  use fallback mask where no value available == -999.0
#
   set has_fallback [GetFallbackMask $Grid GPXMGFB]

   if { [llength [set idx [fstdfield find GPXAUXFILE -1 "" -1 -1 -1 "" "MGGO"]]] } {
      Log::Print INFO "Found previous MGGO field, will use it."
      fstdfield read GPXMASK GPXAUXFILE $idx
   } else {
      Log::Print INFO "Cannot find previous MGGO field, rasterizing it."

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   fstdfield copy GPXMASK $Grid
   GenX::GridClear GPXMASK -999.0

   #----- Loop over files
   foreach file [GenX::CANVECFindFiles $lat0 $lon0 $lat1 $lon1 { HD_1480009_2 } ] {
      Log::Print DEBUG "   Processing file $file"
      ogrfile open CANVECFILE read $file
      ogrlayer read CANVECTILE CANVECFILE 0
      fstdfield gridinterp GPXMASK CANVECTILE ALIASED 1.0 "" SUM
      ogrfile close CANVECFILE
   }

   #----- Save a geographic mask with a nodata value
   fstdfield define GPXMASK -NOMVAR MGGO -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXMASK GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   }
   
   #----- Use whatever we have for US
#   ogrfile open USLAKESFILE read $GenX::Param(DBase)/$GenX::Path(Various)/mjwater.shp
#   ogrlayer read USLAKES USLAKESFILE 0
#   fstdfield gridinterp GPXMASK USLAKES ALIASED 1.0
#   ogrfile close USLAKESFILE

   if { $has_fallback } {
      vexpr GPXMASK ifelse(GPXMASK>=0.0,1.0-clamp(GPXMASK,0.0,1.0),GPXMGFB)
      fstdfield free GPXMGFB
   } else {
      vexpr GPXMASK 1.0-clamp(GPXMASK,0.0,1.0)
   }

   if { [fstdfield is GPXME] } {
      if { [lindex [fstdfield stats GPXME -max] 0]>0.0 } {
         vexpr GPXMASK ifelse(GPXMASK>0.0 && GPXME==0.0,0.0,GPXMASK)
      }
   }

   fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   ogrlayer free USLAKES CANVECTILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskCCI_LC>
# Creation : August 2015 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the land/sea mask through averaging.
#            using Climate Research Data Package Water Bodies (from ESA CCI)
#            CCI_LC Sea Water normally come in seperate file but it had been
#            previously merge into vege file for speedup.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskCCI_LC { Grid  dbid } {

   set  dbdir "$GenX::Param(DBase)/$GenX::Path($dbid)"
   set  link [file readlink  $dbdir/CCI_LC.tif]
   set  year [file tail $dbdir]

   switch $dbid {
   "CCILC2015-ECO2017" {
      GenX::Procs $dbid
      }
   "CCILC2015-1" {
      GenX::Procs $dbid
      }
   "CCILC2015-3" {
      GenX::Procs $dbid
      }
   "CCILC2015-WE" {
      GenX::Procs $dbid
      }
   "CCILC2015" {
      GenX::Procs $dbid
      }
   "CCILC2010" {
      GenX::Procs $dbid
      }
   default  {
      GenX::Procs "CCILC${year}"
      }
   }

   Log::Print INFO "Averaging mask using ESA CCI LC Water Bodies database $year"
 
   set  datafile "$dbdir/$link"
   Log::Print INFO "Will use data file: $datafile"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

# when Mask and Vege is not the same, means we are trying to mix 2 databases
# in that case, Mask, SeaWater and (Urban if requested have priority)
   if { $GenX::Param(Mask) != $GenX::Param(Vege) } {
      fstdfield copy GPXVF1MG  $Grid
      GenX::GridClear GPXVF1MG 0.0
      fstdfield copy GPXVF3MG  $Grid
      GenX::GridClear GPXVF3MG 0.0
      fstdfield copy GPXVF21MG  $Grid
      GenX::GridClear GPXVF21MG 0.0
      set has_mask_VF1 1
   } else {
      set has_mask_VF1 0
   }

   #----- Open the file
   gdalfile open CCIFILE read $GenX::Param(DBase)/$GenX::Path($dbid)/CCI_LC.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef CCIFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with ESA CCI LC database, mask will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with ESA CCI Water Bodies database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read CCITILE { { CCIFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]

            # the CCI_LC raster no_data value is 0, but because we are remapping everything to 1 or 0 for water
            # we have to change it to something else, otherwise, the averaging that follows will not be correct
            gdalband stats CCITILE -nodata 255 -celldim $GenX::Param(Cell)

            # avoid reading data again by obtaining Sea Water Mask and Urban data here
            if { $has_mask_VF1 } {
               vexpr VFTILE ifelse(CCITILE==211,1.0,0.0)
               fstdfield gridinterp GPXVF1MG VFTILE AVERAGE False
               vexpr VFTILE ifelse(CCITILE==210,1.0,0.0)
               fstdfield gridinterp GPXVF3MG VFTILE AVERAGE False
               vexpr VFTILE ifelse(CCITILE==190,1.0,0.0)
               fstdfield gridinterp GPXVF21MG VFTILE AVERAGE False
            }
            vexpr CCITILE ifelse((CCITILE==210)||(CCITILE==211),0.0,1.0)
            gdalband stats CCITILE -nodata 255 -celldim $GenX::Param(Cell)
            fstdfield gridinterp GPXMASK CCITILE AVERAGE False
         }
      }

      #----- Save output
      fstdfield gridinterp GPXMASK - NOP True
      fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      fstdfield free GPXMASK

      if { $has_mask_VF1 } {
         fstdfield gridinterp GPXVF1MG - NOP True
         fstdfield define GPXVF1MG -NOMVAR VF -ETIKET $GenX::Param(ETIKET) -IP1 1199 -DATYP $GenX::Param(Datyp)
         fstdfield write GPXVF1MG GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
         fstdfield free GPXVF1MG
         fstdfield gridinterp GPXVF21MG - NOP True
         fstdfield define GPXVF21MG -NOMVAR VF -ETIKET $GenX::Param(ETIKET) -IP1 1179 -DATYP $GenX::Param(Datyp)
         fstdfield write GPXVF21MG GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
         fstdfield free GPXVF21MG
         fstdfield gridinterp GPXVF3MG - NOP True
         fstdfield define GPXVF3MG -NOMVAR VF -ETIKET $GenX::Param(ETIKET) -IP1 1197 -DATYP $GenX::Param(Datyp)
         fstdfield write GPXVF3MG GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
         fstdfield free GPXVF3MG
      }
      gdalband free CCITILE
   }
   gdalfile close CCIFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskUSGS_R>
# Creation : 
#
# Goal     : Generate the land/sea mask through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskUSGS_R { Grid } {

   GenX::Procs USGS_R
   Log::Print INFO "Averaging mask using USGS GLCC BATS database"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

   #----- Open the file
   gdalfile open USGSFILE read $GenX::Param(DBase)/$GenX::Path(USGS_R)/gbats2_0ll.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef USGSFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with USGS GLCC BATS database, mask will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with USGS GLCC BATS database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read USGSTILE { { USGSFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats USGSTILE -nodata 255 -celldim $GenX::Param(Cell)

            vexpr USGSTILE ifelse(USGSTILE==14||USGSTILE==15,0.0,1.0)
            fstdfield gridinterp GPXMASK USGSTILE AVERAGE False
         }
      }

      #----- Save output
      fstdfield gridinterp GPXMASK - NOP True
      fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      fstdfield free MASKTILE

      gdalband free USGSTILE
   }
   gdalfile close USGSFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskAAFC>
# Creation : Jan 2017 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the land/sea mask through averaging.
#            using AAFC Crop data
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskAAFC { Grid } {

   GenX::Procs AAFC
   Log::Print INFO "Averaging mask using AAFC"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

#
# Use user's Geotiff files if provided by specifying  GenX::Path(AAFC_FILES)
#
   set files  {}
   set  lcdir  $GenX::Path(AAFC_FILES)
   Log::Print INFO "AAFC_FILES: $lcdir"
   catch "glob $lcdir/*.tif" lfiles
   foreach  file $lfiles {
      Log::Print INFO "$file"
      if { [file exist $file] } {
         lappend files [file tail $file]
      }
   }
#
# otherwise use default AAFC db files
#
   if { [llength $files] == 0 } {
      set lcdir  $GenX::Param(DBase)/$GenX::Path(AAFC_CROP)
      set files [GenX::FindFiles $lcdir/Index/Index.shp $Grid]
   }

   #----- Loop over files
   if { [set nb [llength $files]] } {

      foreach file $files {
         Log::Print DEBUG "   Processing file ([incr n]/$nb) $file"

         gdalfile open AAFCFILE read $lcdir/$file
   
         if { [llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef AAFCFILE]]]] } {
   
            Log::Print INFO "Grid intersection with AAFC Crop file is { $limits }"
            set x0 [lindex $limits 0]
            set x1 [lindex $limits 2]
            set y0 [lindex $limits 1]
            set y1 [lindex $limits 3]
   
         #----- Loop over the data by tiles since it's too big to fit in memory
            for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
               for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
                  Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
                  gdalband read AAFCTILE { { AAFCFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
                  gdalband stats AAFCTILE -celldim $GenX::Param(Cell)
   
                  # the AAFC raster no_data value is 0, but because we are remapping everything to 1 or 0 for water
                  # we have to change it to something else, otherwise, the averaging that follows will not be correct
                  gdalband stats AAFCTILE -nodata 255 -celldim $GenX::Param(Cell)
                  vexpr AAFCTILE ifelse(AAFCTILE==20,0.0,1.0)
                  fstdfield gridinterp GPXMASK AAFCTILE AVERAGE False
                  gdalband free AAFCTILE
               }
            }
         }
         gdalfile close AAFCFILE
      }
      #----- Save output
      fstdfield gridinterp GPXMASK - NOP True
      fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      fstdfield free MASKTILE
   } else {
      Log::Print WARNING "The grid is not within AAFC limits"
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskNALCMS>
# Creation : Nov 2018 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the land/sea mask through averaging.
#            using NALCMS
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskNALCMS { Grid } {

   GenX::Procs CEC_NALCMS
   Log::Print INFO "Averaging mask using NALCMS vegetation database"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"

   set lcdir  $GenX::Param(DBase)/$GenX::Path(NALCMS)
   set files  [glob -nocomplain $lcdir/*.tif]

   #----- Loop over files
   if { [set nb [llength $files]] } {

      foreach file $files {
         Log::Print INFO "   Processing file ([incr n]/$nb) $file"

         gdalfile open NALCMSFILE read $file
   
         if { [llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef NALCMSFILE]]]] } {
   
            Log::Print INFO "Grid intersection with NALCMS file is { $limits }"
            set x0 [lindex $limits 0]
            set x1 [lindex $limits 2]
            set y0 [lindex $limits 1]
            set y1 [lindex $limits 3]
   
         #----- Loop over the data by tiles since it's too big to fit in memory
            for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
               for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
                  Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
                  gdalband read NALCMSTILE { { NALCMSFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
                  gdalband stats NALCMSTILE -celldim $GenX::Param(Cell)
   
                  # the NALCMS raster no_data value is 0, but because we are remapping everything to 1 or 0 for water
                  # we have to change it to something else, otherwise, the averaging that follows will not be correct
                  gdalband stats NALCMSTILE -nodata 255 -celldim $GenX::Param(Cell)
                  vexpr NALCMSTILE ifelse(NALCMSTILE==18||NALCMSTILE==0,0.0,1.0)
                  fstdfield gridinterp GPXMASK NALCMSTILE AVERAGE False
                  gdalband free NALCMSTILE
               }
            }
         }
         gdalfile close NALCMSFILE
      }
      #----- Save output
      fstdfield gridinterp GPXMASK - NOP True
      fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      fstdfield free MASKTILE
   } else {
      Log::Print WARNING "The grid is not within NALCMS limits"
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskOSM>
# Creation : Nov 2018
#
# Goal     :  generates land mask using OSM data
#            
#
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskOSM { Grid } {
   variable Param

   GenX::Procs OSM
   Log::Print INFO "Averaging mask using OSM database"

   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0

   fstdfield copy GPXVF3  $Grid
   GenX::GridClear GPXVF3 0.0

   fstdfield copy GPXVF1  $Grid
   GenX::GridClear GPXVF1 0.0

   #---- First generate sea water using water-polygons-split-4326
   set shp_dir  "$GenX::Param(DBase)/$GenX::Path(OSM)/water/water-polygons-tiled"
   set regfiles [GenX::FindFiles $shp_dir/Index/Index.shp $Grid]
   foreach file  $regfiles {
      set shp_file "$shp_dir$file"
      Log::Print INFO "Using shapefile : $shp_dir$file"
      set layer [ogrfile open LAYERFILE read $shp_file]
      ogrlayer read FEATURES LAYERFILE 0
      fstdfield gridinterp GPXVF1 FEATURES ALIASED 1 "" SUM
      ogrfile close LAYERFILE
   }

   #----- now generate VF3  using OSM Hydrography from 2016 snapshot
   #----- if hydrolakes will be added also, then use the version that 
   #----- had hydrolakes portion cut out, to avoid double counting
   if { $GenX::Param(AddHydroLakesToMask) } {
      set shp_dir  "$GenX::Param(DBase)/$GenX::Path(OSM)/water/hydrography-cut-hydrolakes-tiled"
   } else {
      set shp_dir  "$GenX::Param(DBase)/$GenX::Path(OSM)/water/hydrography-tiled"
   }
   set regfiles [GenX::FindFiles $shp_dir/Index/Index.shp $Grid]
   foreach file  $regfiles {
      set shp_file "$shp_dir$file"
      Log::Print INFO "Using shapefile : $shp_dir$file"
      set layer [ogrfile open LAYERFILE read $shp_file]
      ogrlayer read FEATURES LAYERFILE 0
      fstdfield gridinterp GPXVF3 FEATURES ALIASED 1 "" SUM
      ogrfile close LAYERFILE
   }

   if { $GenX::Param(AddHydroLakesToMask) } {
      if { [catch {
         fstdfield read GPXLAKEF   GPXAUXFILE -1 "" -1   -1 -1 "" "LACF"
         } ] } {
         Log::Print INFO "LACF field not found, will generate it using HydroLakes"
         fstdfield copy GPXLAKEF $Grid
         GenX::GridClear GPXLAKEF 0.0
         HydroX::HydroLakesDepth $Grid GPXLAKEF
      }

      vexpr GPXVF3  "GPXVF3 + GPXLAKEF"
      fstdfield free GPXLAKEF
   }

   vexpr GPXVF3  "ifelse(GPXVF3>1.0,1.0,GPXVF3)"
   vexpr GPXVF1  "ifelse(GPXVF1>1.0,1.0,GPXVF1)"
   vexpr GPXMASK  "1.0 - GPXVF1 - GPXVF3"

   #----- Save output
   fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield free MASKTILE

   fstdfield define GPXVF3 -NOMVAR VF -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-3] -DATYP $GenX::Param(Datyp)
   fstdfield write GPXVF3 GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield free GPXVF3

   fstdfield define GPXVF1 -NOMVAR VF -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-1] -DATYP $GenX::Param(Datyp)
   fstdfield write GPXVF1 GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield free GPXVF1
}


#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageGeoMask>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageGeoMask { Grid } {
   variable Param

   GenX::Procs

   switch $GenX::Param(GeoMask) {
      "CANADA"    { GeoPhysX::AverageGeoMaskCANADA  $Grid }
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageGeoMaskCANADA>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the land/sea mask through averaging using vectorial data.
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageGeoMaskCANADA { Grid } {
   variable Path
   variable Param

   GenX::Procs CanadaProv
   Log::Print INFO "Averaging geopolitical mask using CANADA database"

   fstdfield copy GPXMASK $Grid
   GenX::GridClear GPXMASK 0.0

   #----- Loop over files

   ogrfile open CANPROVFILE read $Path(CanadaProv)/Provinces.shp
   ogrlayer read CANPROV CANPROVFILE 0
   fstdfield gridinterp GPXMASK CANPROV INTERSECT
   ogrfile close CANPROVFILE

   fstdfield define GPXMASK -NOMVAR MGGO -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXMASK GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   ogrlayer free CANPROV
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::GetFallbackMask>
# Creation : August 2015 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Read a mask from existing file or generate the land/sea mask through averaging.
#            of a specified mask identifier
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#   <MGFB>   : id of fallback mask
#
# Return:  1  if success
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::GetFallbackMask { Grid MGFB } {

# if the fallback mask is not a file, check if it there is a valid id for mask to be generate
   set has_fallback  0
   if { [file exist $GenX::Path(FallbackMask)] } {
      Log::Print INFO "Has a mask fallback file : $GenX::Path(FallbackMask)"
      fstdfile open GPXMSKFILE  read $GenX::Path(FallbackMask)
      if { [llength [set idx [fstdfield find GPXMSKFILE -1 "" -1 -1 -1 "" "MG"]]] } {
         fstdfield read $MGFB GPXMSKFILE $idx
         Log::Print INFO "Got a fallback mask field"
         set has_fallback  1
      } else {
         Log::Print WARNING "Unable to load MG from mask fallback file"
      }
      fstdfile close GPXMSKFILE
   } else {
      if { [lsearch -exact $GenX::Param(Masks) $GenX::Param(FallbackMask)]>=0 } {
         if { [string compare $GenX::Param(FallbackMask) CANVEC] == 0 } {
            Log::Print WARNING "$GenX::Param(FallbackMask) cannot be used for fallback mask"
            return
         } else {
            Log::Print INFO "Generating fallback mask : $GenX::Param(FallbackMask)"
            set old_maskid $GenX::Param(Mask)
            set GenX::Param(Mask) $GenX::Param(FallbackMask)
            GeoPhysX::AverageMask $Grid
            if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
               fstdfield read $MGFB GPXOUTFILE $idx
               Log::Print INFO "Got a fallback mask field"
               set has_fallback  1
            }
            set GenX::Param(Mask) $old_maskid
         }
      }
   }
   return $has_fallback
}


#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageIndexedLayers>
# Creation : Mai 2019 - V. Souvanlasy - CMC/CMDS
#
# Goal     :  averaging shapefiles to a grid
#            
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#   <shp>    : files or path to shapefiles
#
# Return:  
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageIndexedLayers { Grid  shp_dir {operators "INTERSECT 1 {} SUM"} } {

   if { [file exist $shp_dir/Index/Index.shp] } {
      set files [GenX::FindFiles $shp_dir/Index/Index.shp $Grid]
   } else {
      if { [file isdir $shp_dir] } {
         set files [exec glob $shp_dir/*.shp]
      } else {
         if { [file exist $shp_dir] } {
            set files $shp_dir
         }
      }
   }

   foreach shp_file $files {
      set layer [ogrfile open LAYERFILE read $shp_dir/$shp_file]
      ogrlayer read FEATURES LAYERFILE 0
      Log::Print INFO "Processing : $shp_file"
      eval "fstdfield gridinterp $Grid FEATURES $operators"
      ogrfile close LAYERFILE
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVege>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVege { Grid } {
   variable Param

   GenX::Procs

   fstdfield copy GPXVF $Grid
   GenX::GridClear [list GPXVF $Grid] 0.0

   foreach vege $GenX::Param(Vege) {
      switch $vege {
         "USGS"      { GeoPhysX::AverageVegeUSGS      GPXVF ;#----- USGS global vege averaging method }
         "GLOBCOVER" { GeoPhysX::AverageVegeGLOBCOVER GPXVF ;#----- GLOBCOVER global vege averaging method }
         "GLC2000"   { GeoPhysX::AverageVegeGLC2000   GPXVF ;#----- GLC2000 global vege averaging method }
         "CCRS"      { GeoPhysX::AverageVegeCCRS      GPXVF ;#----- CCRS over Canada only vege averaging method }
         "EOSD"      { GeoPhysX::AverageVegeEOSD      GPXVF ;#----- EOSD over Canada only vege averaging method }
         "LCC2000V"  { GeoPhysX::AverageVegeLCC2000V  GPXVF ;#----- LCC2000V over Canada only vege averaging method }
         "CORINE"    { GeoPhysX::AverageVegeCORINE    GPXVF ;#----- CORINE over Europe only vege averaging method }
         "MCD12Q1"   { GeoPhysX::AverageVegeMCD12Q1   GPXVF ;#----- MODIS MCD12Q1 IGBP global vegetation }
         "AAFC"      { GeoPhysX::AverageVegeAAFC      GPXVF ;#----- AAFC Crop over Canada only vege averaging method }
         "CCI_LC"    { GeoPhysX::AverageVegeCCI_LC    GPXVF $vege ;#----- ESA CCI CRDP Land cover }
         "CCILC2015-ECO2017" { GeoPhysX::AverageVegeCCI_LC    GPXVF $vege ;#----- ESA CCI CRDP Land cover }
         "CCILC2015-1" { GeoPhysX::AverageVegeCCI_LC    GPXVF $vege ;#----- ESA CCI CRDP Land cover }
         "CCILC2015-3" { GeoPhysX::AverageVegeCCI_LC    GPXVF $vege ;#----- ESA CCI CRDP Land cover }
         "CCILC2015-WE" { GeoPhysX::AverageVegeCCI_LC    GPXVF $vege ;#----- ESA CCI CRDP Land cover }
         "CCILC2015" { GeoPhysX::AverageVegeCCI_LC    GPXVF $vege ;#----- ESA CCI CRDP Land cover }
         "CCILC2010" { GeoPhysX::AverageVegeCCI_LC    GPXVF $vege ;#----- ESA CCI CRDP Land cover }
         "USGS_R"    { GeoPhysX::AverageVegeUSGS_R    GPXVF ;#----- USGS global vege raster averaging method }
         "NALCMS"    { GeoPhysX::AverageVegeNALCMS    GPXVF ;#----- NALCMS North America Land Cover vege raster averaging method }
      }
   }
   fstdfield free GPXVSK
   fstdfield gridinterp GPXVF - NOP True

   fstdfield stats GPXVF -mask ""

   #----- Save the 26 Vege types
   fstdfield define GPXVF -NOMVAR VF -ETIKET $GenX::Param(ETIKET) -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield stats GPXVF -levels $Param(VegeTypes) -leveltype UNDEFINED
   fstdfield write GPXVF GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   fstdfield free GPXVF
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeUSGS>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types using USGS.
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeUSGS { Grid } {
   variable Param

   GenX::Procs VegeUSGS
   Log::Print INFO "Averaging vegetation type using USGS database"

   #----- Loop over files
   foreach file [glob $GenX::Param(DBase)/$GenX::Path(VegeUSGS)/*] {
      Log::Print DEBUG "   Processing file : $file"
      fstdfile open GPXVEGEFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXVEGEFILE -1 "" -1 -1 -1 "" "VG"] {
         Log::Print DEBUG "      Processing field : $field"
         fstdfield read VEGETILE GPXVEGEFILE $field
         fstdfield stats VEGETILE -nodata -99.0 -celldim $GenX::Param(Cell)

         #----- Count percentage for each type
         fstdfield gridinterp $Grid VEGETILE NORMALIZED_COUNT $Param(VegeTypes) False
      }
      fstdfile close GPXVEGEFILE
   }
   fstdfield free VEGETILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeEOSD>
# Creation : June 2007 - Alexandre Leroux, J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using EOSD Database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeEOSD { Grid } {
   variable Param
   variable Const

   GenX::Procs EOSD
   Log::Print INFO "Averaging vegetation type using EOSD database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]
   set n    0

   #----- Loop over files
   if { [set nb [llength [set files [GenX::EOSDFindFiles $lat0 $lon0 $lat1 $lon1]]]] } {

      Log::Print INFO "Using correspondance table\n   From:[lindex $Const(EOSD2RPN) 0]\n   To  :[lindex $Const(EOSD2RPN) 1]"
      vector create FROMEOSD [lindex $Const(EOSD2RPN) 0]
      vector create TORPN    [lindex $Const(EOSD2RPN) 1]

      foreach file $files {
         Log::Print DEBUG "   Processing file ([incr n]/$nb) $file"
         gdalband read EOSDTILE [gdalfile open EOSDFILE read $file]
         gdalband stats EOSDTILE -nodata -99 -celldim $GenX::Param(Cell)

         #----- We have to maks some data since they might overlap a bit
         gdalband copy EOSDMASK EOSDTILE
         gdalband clear EOSDMASK 0.0

         #----- Burn NTS limits and mask EOSD
         set nts [string range [file tail $file] 0 3]
         Log::Print DEBUG "      Applying NTS($nts) Limit mask"
         ogrlayer define NTSLAYER250K -featureselect [list [list IDENTIFIAN == $nts]]
         gdalband gridinterp EOSDMASK NTSLAYER250K FAST 1
         vexpr EOSDTILE ifelse(EOSDMASK,EOSDTILE,0)

         #----- Apply Table conversion
         vexpr EOSDTILE lut(EOSDTILE,FROMEOSD,TORPN)

         fstdfield gridinterp $Grid EOSDTILE NORMALIZED_COUNT $Param(VegeTypes) False
         gdalband free EOSDTILE EOSDMASK
         gdalfile close EOSDFILE
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) EOSD]<[expr [llength $GenX::Param(Vege)]-1] } {

         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         fstdfield gridinterp $Grid - ACCUM
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }

      gdalband free EOSDTILE
      vector free FROMEOSD TORPN
      ogrlayer define NTSLAYER250K -featureselect {}
   } else {
      Log::Print WARNING "The grid is not within EOSD limits"
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeLCC2000V>
# Creation : Novembre 2010 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using LCC2000V Database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeLCC2000V { Grid } {
   variable Param
   variable Const

   GenX::Procs LCC2000V
   Log::Print INFO "Averaging vegetation type using LCC2000V database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   #----- Force NK to 26 by doing noop on gridinterp
   fstdfield gridinterp $Grid $Grid NOP $Param(VegeTypes) False

   #----- Create temporary per class field
   vexpr GPXVG ${Grid}()()(0)
   GenX::GridClear GPXVG 0.0

   foreach rpns [lsort -unique [lindex $Const(LCC2000V2RPN) 1]] {
      foreach rpn $rpns {
         if { $rpn!=-99 && ![fstdfield is GPXVG$rpn] } {
            fstdfield copy GPXVG$rpn GPXVG
         }
      }
   }

   #----- Loop over files
   if { [set nb [llength [set files [GenX::LCC2000VFindFiles $lat0 $lon0 $lat1 $lon1]]]] } {

      Log::Print INFO "Using correspondance table\n   From:[lindex $Const(LCC2000V2RPN) 0]\n   To  :[lindex $Const(LCC2000V2RPN) 1]"
      foreach file $files {
         Log::Print DEBUG "   Processing file ([incr n]/$nb) $file"
         ogrfile open LCC2000VFILE read $file
         eval ogrlayer read LCC2000VTILE LCC2000VFILE 0

         #----- Loop on vege types and corresponding RPN classes
         foreach vg [lindex $Const(LCC2000V2RPN) 0] rpns [lindex $Const(LCC2000V2RPN) 1] {
            if { $rpns!=-99 && [set nbf [llength [ogrlayer define LCC2000VTILE -featureselect [list [list COVTYPE == $vg]]]]] } {
               Log::Print DEBUG "      Averaging $nbf features ($vg -> $rpns)"

               #----- Rasterize using alias mode
               fstdfield clear GPXVG
               fstdfield gridinterp GPXVG LCC2000VTILE ALIAS 1.0

               #----- Add and split if neccassary to RPN classification
               foreach rpn $rpns {
                  vexpr GPXVG$rpn GPXVG$rpn+(GPXVG/[llength $rpn])
               }
            }
         }
         ogrlayer free LCC2000VTILE
         ogrfile close LCC2000VFILE
      }

      #----- Put back the per class field into the 3D field
      foreach rpns [lsort -unique [lindex $Const(LCC2000V2RPN) 1]] {
         foreach rpn $rpns {
            if { $rpn!=-99 && [fstdfield is GPXVG$rpn] } {
               set k [expr $rpn-1]
               vexpr $Grid ${Grid}()()($k)=GPXVG$rpn
            }
            fstdfield free GPXVG$rpn
         }
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) LCC2000V]<[expr [llength $GenX::Param(Vege)]-1] } {
         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }
   } else {
      Log::Print WARNING "The grid is not within LCC2000V limits"
   }
   fstdfield free GPXVG
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeCORINE>
# Creation : Decembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using CORINE Database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeCORINE { Grid } {
   variable Param
   variable Const

   GenX::Procs CORINE
   Log::Print INFO "Averaging vegetation type using CORINE database"

   #----- Open the file
   gdalfile open CORINEFILE read $GenX::Param(DBase)/$GenX::Path(CORINE)/lceugr100_00_pct.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef CORINEFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with CORINE database, vegetation will not be calculated"
   } else {
      Log::Print INFO "Using correspondance table\n   From:[lindex $Const(CORINE2RPN) 0]\n   To  :[lindex $Const(CORINE2RPN) 1]"
      vector create FROMCORINE [lindex $Const(CORINE2RPN) 0]
      vector create TORPN      [lindex $Const(CORINE2RPN) 1]

      Log::Print INFO "Grid intersection with CORINE database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read CORINETILE { { CORINEFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats CORINETILE -nodata 255 -celldim $GenX::Param(Cell)

            vexpr CORINETILE lut(CORINETILE,FROMCORINE,TORPN)
            fstdfield gridinterp $Grid CORINETILE NORMALIZED_COUNT $Param(VegeTypes) False
         }
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) CORINE]<[expr [llength $GenX::Param(Vege)]-1] } {
         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         fstdfield gridinterp $Grid - ACCUM
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }

      gdalband free CORINETILE
      vector free FROMCORINE TORPN
   }
   gdalfile close CORINEFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeGLOBCOVER>
# Creation : Janvier 2009 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using GlobCover Database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeGLOBCOVER { Grid } {
   variable Param
   variable Const

   GenX::Procs GlobCover
   Log::Print INFO "Averaging vegetation type using GlobCover database"

   #----- Open the file
   gdalfile open GLOBFILE read $GenX::Param(DBase)/$GenX::Path(GlobCover)/GLOBCOVER_L4_200901_200912_V2.3.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GLOBFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GLOBCOVER database, vegetation will not be calculated"
   } else {
      Log::Print INFO "Using correspondance table\n   From:[lindex $Const(GLOBCOVER2RPN) 0]\n   To  :[lindex $Const(GLOBCOVER2RPN) 1]"
      vector create FROMGLOB [lindex $Const(GLOBCOVER2RPN) 0]
      vector create TORPN    [lindex $Const(GLOBCOVER2RPN) 1]

      Log::Print INFO "Grid intersection with GLOBCOVER database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read GLOBTILE { { GLOBFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats GLOBTILE -nodata 255 -celldim $GenX::Param(Cell)

            vexpr GLOBTILE lut(GLOBTILE,FROMGLOB,TORPN)
            fstdfield gridinterp $Grid GLOBTILE NORMALIZED_COUNT $Param(VegeTypes) False
         }
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) GLOBCOVER]<[expr [llength $GenX::Param(Vege)]-1] } {
         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         fstdfield gridinterp $Grid - ACCUM
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }

      gdalband free GLOBTILE
      vector free FROMGLOB TORPN
   }
   gdalfile close GLOBFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeAAFC>
# Creation : February 2015 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the CCRN vegetation (26 classes)
#            using AESB CROP Database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :  Only partial coverage on southern part of Canada
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeAAFC { Grid } {
   variable Param
   variable Const

   GenX::Procs AAFC
   Log::Print INFO "Averaging vegetation type using AESB CROP database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]
   set n    0

#
# Use user's Geotiff files if provided by specifying  GenX::Path(AAFC_FILES)
#
   set files  {}
   set  lcdir  $GenX::Path(AAFC_FILES)
   catch "glob $lcdir/*.tif" lfiles
   foreach  file $lfiles {
      Log::Print INFO "$file"
      if { [file exist $file] } {
         lappend files [file tail $file]
      }
   }
#
# otherwise use default AAFC db files
#
   if { [llength $files] == 0 } {
      set lcdir  $GenX::Param(DBase)/$GenX::Path(AAFC_CROP)
      set files [GenX::FindFiles $lcdir/Index/Index.shp $Grid]
   }

# first see if there is a override table set, if not, see if database contains a table, if not, use default
   set  ctable  $Const(AAFC2RPN)
   if { [file exist $GenX::Path(AAFC2RPN)] } {
      set  ltable [GenX::Load_CCRN_Table $GenX::Path(AAFC2RPN)]
      if { [llength $ltable] == 2 } {
         Log::Print INFO "Overloading correspondance table with :$GenX::Path(AAFC2RPN)"
         set  ctable  $ltable
      } 
   }

   #----- Loop over files
   if { [set nb [llength $files]] } {
      Log::Print INFO "Using correspondance table\n   From:[lindex $ctable 0]\n   To  :[lindex $ctable 1]"
      vector create FROMAAFC [lindex $ctable 0]
      vector create TORPN    [lindex $ctable 1]

      foreach file $files {
         Log::Print DEBUG "   Processing file ([incr n]/$nb) $file"

         gdalfile open AAFCFILE read $lcdir/$file
   
         if { [llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef AAFCFILE]]]] } {
   
            Log::Print INFO "Grid intersection with AAFC Crop file is { $limits }"
            set x0 [lindex $limits 0]
            set x1 [lindex $limits 2]
            set y0 [lindex $limits 1]
            set y1 [lindex $limits 3]
   
         #----- Loop over the data by tiles since it's too big to fit in memory
            for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
               for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
                  Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
                  gdalband read AAFCTILE { { AAFCFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
                  gdalband stats AAFCTILE -celldim $GenX::Param(Cell)
   
                  #----- Apply Table conversion
                  vexpr AAFCTILE lut(AAFCTILE,FROMAAFC,TORPN)
                  gdalband stats AAFCTILE -nodata -99 -celldim $GenX::Param(Cell)

                  fstdfield gridinterp $Grid AAFCTILE NORMALIZED_COUNT $Param(VegeTypes) False
                  gdalband free AAFCTILE
               }
            }
         gdalfile close AAFCFILE
         } else {
            Log::Print WARNING "The grid is not within AAFC limits"
         }

         #----- If there is other DB to process
         if { [lsearch -exact $GenX::Param(Vege) AAFC]<[expr [llength $GenX::Param(Vege)]-1] } {

            #----- Use accumulator to figure out coverage in destination
            #      But remove border of coverage since it will not be full
            fstdfield gridinterp $Grid - ACCUM
            vexpr GPXVSK !fpeel($Grid)
            fstdfield stats $Grid -mask GPXVSK
         }
      }
      vector free FROMAAFC TORPN
   } else {
      Log::Print WARNING "The grid is not within AAFC limits"
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeCCI_LC>
# Creation : August 2015 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the CCRN vegetation (26 classes)
#            using Climate Research Data Package Land Cover (from ESA CCI)
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeCCI_LC { Grid dbid } {
   variable Param
   variable Const

   set  dbdir "$GenX::Param(DBase)/$GenX::Path($dbid)"
   set  link [file readlink  $dbdir/CCI_LC.tif]
   set  year [file tail $dbdir]

   Log::Print INFO "Averaging vegetation type using ESA CCI CRDP Land cover $year"

   switch $dbid {
   "CCILC2015-ECO2017" {
      GenX::Procs $dbid
      Log::Print INFO "Using CCILC2015 with Ecoregions2017 already added"
      set GenX::Param(UseVegeLUT)     True
      set CCI_LC2RPN $Const(CCI_LC2RPN)
      }
   "CCILC2015-WE" {
      GenX::Procs $dbid
      set CCI_LC2RPN $Const(CCI_LC2RPN-WE)
      }
   default  {
      GenX::Procs "CCILC${year}"
      set CCI_LC2RPN $Const(CCI_LC2RPN)
      }
   }

   if { $GenX::Param(UseVegeLUT) } {
      if { [string compare $GenX::Path(CCILC_LUT_CSV) ""] == 0 } {
         set GenX::Path(CCILC_LUT_CSV)   "$GenX::Param(DBase)/$GenX::Path($dbid)/CCI_LC_lut.csv"
         Log::Print INFO "GenX::Path(CCILC_LUT_CSV) not defined, Will use default CSV LUT"
      }
   }

   set  datafile "$dbdir/$link"
   Log::Print INFO "Will use data file: $datafile"

   #----- Open the file
   gdalfile open CCIFILE read $GenX::Param(DBase)/$GenX::Path($dbid)/CCI_LC.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef CCIFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with CCI_LC database, vegetation will not be calculated"
   } else {
      set has_lut     0
      if { $GenX::Param(UseVegeLUT) && [info exist GenX::Path(CCILC_LUT_CSV)] } {
         set  ccilc_lut  [GenX::Load_CSV_Vector $GenX::Path(CCILC_LUT_CSV) CCILC_LUT]
         if { $ccilc_lut == "" } {
            Log::Print ERROR "Specified LUT $GenX::Path(CCILC_LUT_CSV) is invalid"
            exit
         }
         set  values     [vector get $ccilc_lut 0]
         set  len        [vector length $ccilc_lut]
         set has_lut     [llength $values]
         if { [lindex $values 0] != [llength $Param(VegeTypes)] } {
            Log::Print ERROR "Specified LUT $GenX::Path(CCILC_LUT_CSV) is invalid, Nb Vege Types not equal to [llength $Param(VegeTypes)], vegetation will not be calculated"
            exit
         }
         Log::Print INFO "Using CSV correspondance table file: $GenX::Path(CCILC_LUT_CSV)"
         set lutstr "[vector dim $ccilc_lut]\n"
         for {set l 0} {$l < $len} {incr l} {
            append lutstr "       [vector get $ccilc_lut $l]\n"
         }
         Log::Print INFO $lutstr
      }
 
      if { $has_lut == 0 } {
         Log::Print INFO "Using correspondance table\n   From:[lindex $CCI_LC2RPN 0]\n   To  :[lindex $CCI_LC2RPN 1]"
         vector create FROMCCI  [lindex $CCI_LC2RPN 0]
         vector create TORPN    [lindex $CCI_LC2RPN 1]
      }

      Log::Print INFO "Grid intersection with CCI_LC database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read CCITILE { { CCIFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats CCITILE -nodata 0 -celldim $GenX::Param(Cell)

            if { $has_lut } {
               fstdfield gridinterp $Grid CCITILE NORMALIZED_COUNT $ccilc_lut False
            } else {
               vexpr CCITILE lut(CCITILE,FROMCCI,TORPN)
               fstdfield gridinterp $Grid CCITILE NORMALIZED_COUNT $Param(VegeTypes) False
            }
         }
      }

      if { $has_lut } {
          vector free $ccilc_lut
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) CCI_LC]<[expr [llength $GenX::Param(Vege)]-1] } {
         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         fstdfield gridinterp $Grid - ACCUM
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }

      gdalband free CCITILE
      if { $has_lut == 0 } {
         vector free FROMCCI TORPN
      }
   }
   gdalfile close CCIFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeUSGS_R>
# Creation : June 2016 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the CCRN vegetation (26 classes)
#            using hybrid raster of USGS BATS + USGS GOGE + CCI_LC as filler for nodata islands
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeUSGS_R { Grid } {
   variable Param
   variable Const

   GenX::Procs USGS_R
   Log::Print INFO "Averaging vegetation type using USGS BATS (raster) Land cover"

   #----- Open the file
   gdalfile open USGSFILE read $GenX::Param(DBase)/$GenX::Path(USGS_R)/gbats2_0ll.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef USGSFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with USGS_R database, vegetation will not be calculated"
   } else {
      set has_lut     0
      if { $GenX::Param(UseVegeLUT) && [info exist GenX::Path(USGS_GLCC_LUT_CSV)] } {
         set  usgs_lut  [GenX::Load_CSV_Vector $GenX::Path(USGS_GLCC_LUT_CSV) USGS_LUT]
         if { $usgs_lut == "" } {
            Log::Print ERROR "Specified LUT $GenX::Path(USGS_GLCC_LUT_CSV) is invalid"
            exit
         }
         set  values     [vector get $usgs_lut 0]
         set  len        [vector length $usgs_lut]
         set  has_lut    [llength $values]
         if { [lindex $values 0] != [llength $Param(VegeTypes)] } {
            Log::Print ERROR "Specified LUT $GenX::Path(USGS_GLCC_LUT_CSV) is invalid, Nb Vege Types not equal to [llength $Param(VegeTypes)], vegetation will not be calculated"
            exit
         }
         Log::Print INFO "Using CSV correspondance table file: $GenX::Path(USGS_GLCC_LUT_CSV)"
         set lutstr "[vector dim $usgs_lut]\n"
         for {set l 0} {$l < $len} {incr l} {
            append lutstr "       [vector get $usgs_lut $l]\n"
         }
         Log::Print INFO $lutstr
      }
 
      if { $has_lut == 0 } {
         Log::Print INFO "Using correspondance table\n   From:[lindex $Const(USGS_BATS2RPN) 0]\n   To  :[lindex $Const(USGS_BATS2RPN) 1]"
         vector create FROMUSGS  [lindex $Const(USGS_BATS2RPN) 0]
         vector create TORPN    [lindex $Const(USGS_BATS2RPN) 1]
      }

      Log::Print INFO "Grid intersection with USGS_R database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read USGSTILE { { USGSFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats USGSTILE -nodata 0 -celldim $GenX::Param(Cell)

            if { $has_lut } {
               fstdfield gridinterp $Grid USGSTILE NORMALIZED_COUNT $usgs_lut  False
            } else {
               vexpr USGSTILE lut(USGSTILE,FROMUSGS,TORPN)
               fstdfield gridinterp $Grid USGSTILE NORMALIZED_COUNT $Param(VegeTypes) False
            }
         }
      }

      if { $has_lut } {
          vector free $usgs_lut
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) USGS_R]<[expr [llength $GenX::Param(Vege)]-1] } {
         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         fstdfield gridinterp $Grid - ACCUM
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }

      gdalband free USGSTILE
      vector free FROMUSGS TORPN
   }
   gdalfile close USGSFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeNALCMS>
# Creation : Sept 2016 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using North American Land Cover data (NALCMS) as vegetation 
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeNALCMS { Grid } {
   variable Param
   variable Const

   GenX::Procs CEC_NALCMS
   Log::Print INFO "Averaging vegetation type using NALCMS vegetation database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"

   set lcdir  $GenX::Param(DBase)/$GenX::Path(NALCMS)
   set files  [glob -nocomplain $lcdir/*.tif]

   foreach file  $files {
      Log::Print INFO "Processing file : $file"
      gdalfile open NALCMSFILE read $file
   
      if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef NALCMSFILE]]]] } {
         Log::Print INFO "Specified grid does not intersect with NALCMS file: $file"
      } else {
         set has_lut     0
         if { $GenX::Param(UseVegeLUT) && [info exist GenX::Path(NALCMS_LUT_CSV)] } {
            set  nalcms_lut  [GenX::Load_CSV_Vector $GenX::Path(NALCMS_LUT_CSV) NALCMS_LUT]
            if { $nalcms_lut == "" } {
               Log::Print ERROR "Specified LUT $GenX::Path(NALCMS_LUT_CSV) is invalid"
               exit
            }
            set  values     [vector get $nalcms_lut 0]
            set  len        [vector length $nalcms_lut]
            set  has_lut    [llength $values]
            if { [lindex $values 0] != [llength $Param(VegeTypes)] } {
               Log::Print ERROR "Specified LUT $GenX::Path(NALCMS_LUT_CSV) is invalid, Nb Vege Types not equal to [llength $Param(VegeTypes)], vegetation will not be calculated"
               exit
            }
            Log::Print INFO "Using CSV correspondance table file: $GenX::Path(NALCMS_LUT_CSV)"
            set lutstr "[vector dim $nalcms_lut]\n"
            for {set l 0} {$l < $len} {incr l} {
               append lutstr "       [vector get $nalcms_lut $l]\n"
            }
            Log::Print INFO $lutstr
         }
    
         if { $has_lut == 0 } {
            Log::Print INFO "Using correspondance table\n   From:[lindex $Const(NALCMS2RPN) 0]\n   To  :[lindex $Const(NALCMS2RPN) 1]"
            vector create FROMNALCMS  [lindex $Const(NALCMS2RPN) 0]
            vector create TORPN    [lindex $Const(NALCMS2RPN) 1]
         }
   
         Log::Print INFO "Grid intersection with NALCMS database is { $limits }"
         set x0 [lindex $limits 0]
         set x1 [lindex $limits 2]
         set y0 [lindex $limits 1]
         set y1 [lindex $limits 3]
   
         #----- Loop over the data by tiles since it's too big to fit in memory
         for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
            for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
               Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
               gdalband read LCTILE { { NALCMSFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
               gdalband stats LCTILE -nodata 255 -celldim $GenX::Param(Cell)
   
               if { $has_lut } {
                  fstdfield gridinterp $Grid LCTILE NORMALIZED_COUNT $nalcms_lut False
               } else {
                  vexpr LCTILE lut(LCTILE,FROMNALCMS,TORPN)
               # the NALCMS2RPN table change NoData value from 255 to -99
                  gdalband stats LCTILE -nodata 255
                  fstdfield gridinterp $Grid LCTILE NORMALIZED_COUNT $Param(VegeTypes) False
               }
            }
         }
   
         if { $has_lut } {
            vector free $nalcms_lut
         }

         #----- If there is other DB to process
         if { [lsearch -exact $GenX::Param(Vege) NEAE]<[expr [llength $GenX::Param(Vege)]-1] } {
            #----- Use accumulator to figure out coverage in destination
            #      But remove border of coverage since it will not be full
            fstdfield gridinterp $Grid - ACCUM
            vexpr GPXVSK !fpeel($Grid)
            fstdfield stats $Grid -mask GPXVSK
         }
   
         gdalband free LCTILE
         vector free FROMNALCMS TORPN
      }
      gdalfile close NALCMSFILE
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVCH>
# Creation : Janvier 2009 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Average vegetation canopy height 
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVCH { Grid {do_z0vh 0} } {
   variable Param
   variable Const

   GenX::Procs $GenX::Param(VCH)
   Log::Print INFO "Averaging vegetation canopy height using $GenX::Param(VCH) database"

   fstdfield copy GPXVCH $Grid
   GenX::GridClear GPXVCH  0.0

   if { $do_z0vh } {
      fstdfield copy GPXLNZ0 $Grid
      GenX::GridClear GPXLNZ0 -99.0
   }

   if { $GenX::Param(VCH) == "GFCH2019" } {
      set vchdir "$GenX::Param(DBase)/$GenX::Path(GFCH2019)"
      if { $do_z0vh } {
         GeoPhysX::AverageIndexedBands  GPXVCH  GFCH_2019 "$vchdir" {GPXLNZ0 LogTreeHeight} 101 101
      } else {
         GeoPhysX::AverageIndexedBands  GPXVCH  GFCH_2019 "$vchdir" {} 101 101
      }
   } elseif { $GenX::Param(VCH) == "GFCH2020" } {
      set vchdir "$GenX::Param(DBase)/$GenX::Path(GFCH2020)"
      if { $do_z0vh } {
         GeoPhysX::AverageIndexedBands  GPXVCH  GFCH_2020 "$vchdir" {GPXLNZ0 LogTreeHeight} 0
      } else {
         GeoPhysX::AverageIndexedBands  GPXVCH  GFCH_2020 "$vchdir" {} 0
      }
   } elseif { $GenX::Param(VCH) == "HRCH2020" } {
      set vchdir "$GenX::Param(DBase)/$GenX::Path(HRCH2020)"
      if { $do_z0vh } {
         GeoPhysX::AverageIndexedBands  GPXVCH  HRCH_2020 "$vchdir" {GPXLNZ0 LogTreeHeight} 0
      } else {
         GeoPhysX::AverageIndexedBands  GPXVCH  HRCH_2020 "$vchdir" {} 0
      }
   } else {
      set files {}
      lappend files "$GenX::Param(DBase)/$GenX::Path(GLAS)/Simard_Pinto_3DGlobalVeg_JGR.tif"
      if { $do_z0vh } {
         GeoPhysX::AverageRastersFiles2rpnGrid GPXVCH $files VCH 255 0 "$GenX::Param(ETIKET)" "Vegetation Canopy Height" 0 {GPXLNZ0 LogTreeHeight}
      } else {
         GeoPhysX::AverageRastersFiles2rpnGrid GPXVCH $files VCH 255 0 "$GenX::Param(ETIKET)" "Vegetation Canopy Height" 0
      }
   }

   #----- Save output
   fstdfield define GPXVCH -NOMVAR VCH -ETIKET $GenX::Param(ETIKET) -IP1 0
   fstdfield write GPXVCH GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   if { $do_z0vh } {
      Log::Print INFO "Saving Z0VH to GPXAUXFILE"
      vexpr GPXZ0VH ifelse(GPXLNZ0>-99.0,exp(GPXLNZ0),0.0)
      fstdfield define GPXZ0VH -NOMVAR Z0VH -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0VH GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield free GPXZ0VH
      fstdfield free GPXLNZ0
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageGSRS_DBRK>
# Creation : Feb 2016 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Average Depth to bedrock Soil Thickness using GSRS database
#
# Parameters :
#   <Grid>   : Grid on which to generate DBRK
#
# Return:
#
# Remarks :
#       it is better to use upland hill slope soil thickness for values below 5, its value is in float and range from 0 to 4.2
#       average soil are for value above 4 and is only available as integer
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageGSRS_DBRK { Grid } {
   variable Param
   variable Const

   GenX::Procs GSRS
   Log::Print INFO "Averaging Global Soil Regolith Sediment database for Depth to bedrock Soil Thickness DBRK"

   fstdfield copy GPXDBRK  $Grid
   GenX::GridClear GPXDBRK 0.0

   #----- Open the file
   gdalfile open ASSDFILE read $GenX::Param(DBase)/$GenX::Path(GSRS)/average_soil_and_sedimentary-deposit_thickness.tif
   gdalfile open UHSSFILE read $GenX::Param(DBase)/$GenX::Path(GSRS)/upland_hill-slope_soil_thickness.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef ASSDFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GSRS database, DBRK will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with GSRS database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read ASSDTILE { { ASSDFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats ASSDTILE -nodata 255 -celldim $GenX::Param(Cell)
            gdalband read UHSSTILE { { UHSSFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats UHSSTILE -nodata 255 -celldim $GenX::Param(Cell)
            vexpr GSRSTILE  ifelse(ASSDTILE<5 && UHSSTILE>0.0,UHSSTILE,ASSDTILE)
            fstdfield gridinterp GPXDBRK GSRSTILE AVERAGE False
         }
      }

      gdalband free GSRSTILE  UHSSTILE ASSDTILE
   }
   gdalfile close ASSDFILE
   gdalfile close UHSSFILE

   #----- Save output
   fstdfield gridinterp GPXDBRK - NOP True
   fstdfield define GPXDBRK -NOMVAR DBRK -ETIKET $GenX::Param(ETIKET) -IP1 0
   fstdfield write GPXDBRK GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield free GPXDBRK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeGLC2000>
# Creation : Janvier 2009 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using GlobCover Database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeGLC2000 { Grid } {
   variable Param
   variable Const

   GenX::Procs GLC2000
   Log::Print INFO "Averaging vegetation type using GLC2000 database"

   #----- Open the file
   gdalfile open GLCFILE read $GenX::Param(DBase)/$GenX::Path(GLC2000)/glc2000_v1_1-glcc_bats.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GLCFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GLC2000 database, vegetation will not be calculated"
   } else {
      Log::Print INFO "Using correspondance table\n   From:[lindex $Const(GLC20002RPN) 0]\n   To  :[lindex $Const(GLC20002RPN) 1]"
      vector create FROMGLC  [lindex $Const(GLC20002RPN) 0]
      vector create TORPN    [lindex $Const(GLC20002RPN) 1]

      Log::Print INFO "Grid intersection with GLC2000 database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read GLCTILE { { GLCFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats GLCTILE -nodata 255 -celldim $GenX::Param(Cell)

            vexpr GLCTILE lut(GLCTILE,FROMGLC,TORPN)
            fstdfield gridinterp $Grid GLCTILE NORMALIZED_COUNT $Param(VegeTypes) False
         }
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) GLC2000]<[expr [llength $GenX::Param(Vege)]-1] } {
         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         fstdfield gridinterp $Grid - ACCUM
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }

      gdalband free GLCTILE
      vector free FROMGLC TORPN
   }
   gdalfile close GLCFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeMCD12Q1>
# Creation : June 2014 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using USGS MODIS MCD12Q1 IGBP global vegetation 
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeMCD12Q1 { Grid } {
   variable Param
   variable Const

   GenX::Procs MODIS_MCD12Q1
   Log::Print INFO "Averaging vegetation type using MODIS MCD12Q1 IGBP global vegetation database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"

   set lcdir  $GenX::Param(DBase)/$GenX::Path(MODIS_IGBP)
   set files [GenX::FindFiles $lcdir/Index/Index.shp $Grid]

   foreach file  $files {
      Log::Print INFO "Processing file : $file"
      gdalfile open MODISFILE read $lcdir$file
   
      if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef MODISFILE]]]] } {
         Log::Print WARNING "Specified grid does not intersect with MCD12Q1 database, vegetation will not be calculated"
      } else {
         Log::Print INFO "Using correspondance table\n   From:[lindex $Const(MODIS2RPN) 0]\n   To  :[lindex $Const(MODIS2RPN) 1]"
         vector create FROMMODIS  [lindex $Const(MODIS2RPN) 0]
         vector create TORPN    [lindex $Const(MODIS2RPN) 1]
   
         Log::Print INFO "Grid intersection with MODIS MCD12Q1 database is { $limits }"
         set x0 [lindex $limits 0]
         set x1 [lindex $limits 2]
         set y0 [lindex $limits 1]
         set y1 [lindex $limits 3]
   
         #----- Loop over the data by tiles since it's too big to fit in memory
         for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
            for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
               Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
               gdalband read LCTILE { { MODISFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
               gdalband stats LCTILE -nodata 255 -celldim $GenX::Param(Cell)
   
               vexpr LCTILE lut(LCTILE,FROMMODIS,TORPN)
# the MODIS2RPN table change NoData value from 255 to -99
               gdalband stats LCTILE -nodata -99
               fstdfield gridinterp $Grid LCTILE NORMALIZED_COUNT $Param(VegeTypes) False
            }
         }
   
         #----- If there is other DB to process
         if { [lsearch -exact $GenX::Param(Vege) MCD12Q1]<[expr [llength $GenX::Param(Vege)]-1] } {
            #----- Use accumulator to figure out coverage in destination
            #      But remove border of coverage since it will not be full
            fstdfield gridinterp $Grid - ACCUM
            vexpr GPXVSK !fpeel($Grid)
            fstdfield stats $Grid -mask GPXVSK
         }
   
         gdalband free LCTILE
         vector free FROMMODIS TORPN
      }
      gdalfile close MODISFILE
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageMaskMCD12Q1>
# Creation : June 2014 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using USGS MODIS MCD12Q1 IGBP global vegetation 
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageMaskMCD12Q1 { Grid } {
   variable Param
   variable Const

   GenX::Procs MODIS_MCD12Q1
   Log::Print INFO "Averaging mask type using MODIS MCD12Q1 IGBP global vegetation database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"
                  
   GenX::GridClear $Grid 0.0
   fstdfield copy GPXMASK  $Grid
   GenX::GridClear GPXMASK 0.0


   set lcdir  $GenX::Param(DBase)/$GenX::Path(MODIS_IGBP)
   set files [GenX::FindFiles $lcdir/Index/Index.shp $Grid]

   foreach file  $files {

      Log::Print INFO "Processing file : $file"
      gdalfile open MCDFILE read $lcdir$file
   
      if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef MCDFILE]]]] } {
         Log::Print WARNING "Specified grid does not intersect with MODIS MCD12Q1 database, vegetation will not be calculated"
      } else {
         Log::Print INFO "Grid intersection with MODIS MCD12Q1 database is { $limits }"
         set x0 [lindex $limits 0]
         set x1 [lindex $limits 2]
         set y0 [lindex $limits 1]
         set y1 [lindex $limits 3]
   
         #----- Loop over the data by tiles since it's too big to fit in memory
         for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
            for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
               Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
               gdalband read MODISTILE { { MCDFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
   
               vexpr MODISTILE ifelse(MODISTILE==255||MODISTILE==0,MODISTILE,1.0)
               gdalband stats MODISTILE -nodata 255 -celldim $GenX::Param(Cell)
               fstdfield gridinterp GPXMASK MODISTILE AVERAGE False
            }
         }
   
         gdalband free MODISTILE WKTILE
      }
      gdalfile close MCDFILE
   }

   #----- Save output
   fstdfield gridinterp GPXMASK - NOP True
   fstdfield define GPXMASK -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXMASK GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   fstdfield free GPXMASK
}
#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageVegeCCRS>
# Creation : Janvier 2009 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the 20 something vegetation types through averaging.
#            using CCRS Database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageVegeCCRS { Grid } {
   variable Param
   variable Const

   GenX::Procs CCRS
   Log::Print INFO "Averaging vegetation type using CCRS database"

   #----- Open the file
   gdalfile open CCRSFILE read $GenX::Param(DBase)/$GenX::Path(CCRS)/LCC2005_V1_3.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef CCRSFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with CCRS database, vegetation will not be calculated"
   } else {
      Log::Print INFO "Using correspondance table\n   From:[lindex $Const(CCRS2RPN) 0]\n   To  :[lindex $Const(CCRS2RPN) 1]"
      vector create FROMCCRS [lindex $Const(CCRS2RPN) 0]
      vector create TORPN    [lindex $Const(CCRS2RPN) 1]

      Log::Print INFO "Grid intersection with CCRS database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read CCRSTILE { { CCRSFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats CCRSTILE -nodata 255 -celldim $GenX::Param(Cell)

            vexpr CCRSTILE lut(CCRSTILE,FROMCCRS,TORPN)
            fstdfield gridinterp $Grid CCRSTILE NORMALIZED_COUNT $Param(VegeTypes) False
         }
      }

      #----- If there is other DB to process
      if { [lsearch -exact $GenX::Param(Vege) CCRS]<[expr [llength $GenX::Param(Vege)]-1] } {
         #----- Use accumulator to figure out coverage in destination
         #      But remove border of coverage since it will not be full
         fstdfield gridinterp $Grid - ACCUM
         vexpr GPXVSK !fpeel($Grid)
         fstdfield stats $Grid -mask GPXVSK
      }

      gdalband free CCRSTILE
      vector free FROMCCRS TORPN
   }
   gdalfile close CCRSFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoil>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the soil types types through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the soil
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------

proc GeoPhysX::AverageSoil { Grid } {
   variable Param

   GenX::Procs

   if { [lindex $GenX::Param(Soil) 0]=="HWSD" } {
      GeoPhysX::AverageSoilHWSD $Grid
   } elseif { [lindex $GenX::Param(Soil) 0]=="JPL" } {
      GeoPhysX::AverageSoilJPL $Grid
   } elseif { [lindex $GenX::Param(Soil) 0]=="BNU" } {
      GeoPhysX::AverageSoilBNU $Grid
   } elseif { [lindex $GenX::Param(Soil) 0]=="CANSIS" } {
      GeoPhysX::AverageSoilCANSIS $Grid
   } elseif { [lindex $GenX::Param(Soil) 0]=="SLC" } {
      GeoPhysX::AverageSoilGriddedSLC $Grid
   } elseif { [lindex $GenX::Param(Soil) 0]=="SOILGRIDS" } {
      GeoPhysX::AverageSoil_SoilGrids $Grid
   } else {
      GeoPhysX::AverageSand $Grid
      GeoPhysX::AverageClay $Grid
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSand>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the sand percentage through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the sand percentage
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageSand { Grid } {
   variable Param

   GenX::Procs SandUSDA SandFAO SandAGRC
   fstdfield copy GPXJ1 $Grid

   #----- Boucle sur les types
   foreach type $Param(SandTypes) {
      Log::Print INFO "Averaging sand ($type)"
      GenX::GridClear GPXJ1 0.0
      fstdfield stats GPXJ1 -mask ""

      #----- Loop over datasets
      foreach db $GenX::Param(Soil) {
         Log::Print DEBUG "   Processing database $db"

         foreach file [glob $GenX::Param(DBase)/$GenX::Path(Sand$db)/*] {
            GenX::Procs Sand$db
            Log::Print DEBUG "      Processing file : $file"
            fstdfile open GPXSANDFILE read $file

            #----- Loop over fields (tiles)
            foreach field [fstdfield find GPXSANDFILE -1 "" -1 -1 $type "" "SB"] {
               Log::Print DEBUG "         Processing field : $field"
               fstdfield read SANDTILE GPXSANDFILE $field
               vexpr SANDTILE max(SANDTILE,0.0)
               fstdfield stats SANDTILE -nodata 0.0 -celldim $GenX::Param(Cell)

               #----- Average on each output grid
               fstdfield gridinterp GPXJ1 SANDTILE AVERAGE False
            }
            fstdfile close GPXSANDFILE
         }
         fstdfield gridinterp GPXJ1 - ACCUM
         vexpr GPXJ1SK !fpeel(GPXJ1)
         fstdfield stats GPXJ1 -mask GPXJ1SK
      }
      fstdfield gridinterp GPXJ1 - NOP True

      #----- avoid saving the mask
      fstdfield stats GPXJ1 -mask ""
      #----- Save output
      fstdfield define GPXJ1 -NOMVAR J1 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
      fstdfield write GPXJ1 GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   }
   fstdfield free SANDTILE GPXJ1 GPXJ1SK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoilJPL>
# Creation : July 2011 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the sand percentage through averaging based on JPL
#
# Parameters :
#   <Grid>   : Grid on which to generate the sand percentage
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------

proc GeoPhysX::AverageSoilJPL { Grid } {
   variable Param

   GenX::Procs JPL
   fstdfield copy GPXJ1 $Grid
   fstdfield copy GPXJ2 $Grid

   GenX::GridClear { GPXJ1 GPXJ2 } 0.0

   #----- Open the file
   gdalfile open JPLFILE read $GenX::Param(DBase)/$GenX::Path(JPL)/sand_M03.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef JPLFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with JPL database, mask will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with JPL database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read JPLTILE { { JPLFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats JPLTILE -nodata -999900 -celldim $GenX::Param(Cell)
            vexpr JPLTILE JPLTILE*100.0

            fstdfield gridinterp GPXJ1 JPLTILE AVERAGE False
         }
      }
      fstdfield gridinterp GPXJ1 - NOP True

      #----- Save output (Same for all layers)
      foreach type $Param(SandTypes) {
         fstdfield define GPXJ1 -NOMVAR J1 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
         fstdfield write GPXJ1 GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      }
      gdalband free JPLTILE
   }
   gdalfile close JPLFILE

   #----- Open the file
   gdalfile open JPLFILE read $GenX::Param(DBase)/$GenX::Path(JPL)/clay_M03.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef JPLFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with JPL database, mask will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with JPL database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read JPLTILE { { JPLFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats JPLTILE -nodata -999900 -celldim $GenX::Param(Cell)
            vexpr JPLTILE JPLTILE*100.0

            fstdfield gridinterp GPXJ2 JPLTILE AVERAGE False
         }
      }
      fstdfield gridinterp GPXJ2 - NOP True

      #----- Save output (Same for all layers)
      foreach type $Param(SandTypes) {
         fstdfield define GPXJ2 -NOMVAR J2 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
         fstdfield write GPXJ2 GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      }
      gdalband free JPLTILE
   }
   gdalfile close JPLFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoilHWSD>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the sand percentage through averaging based on HWSD.
#
# Parameters :
#   <Grid>   : Grid on which to generate the sand percentage
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------

proc GeoPhysX::AverageSoilHWSD { Grid } {
   variable Param

   GenX::Procs HWSD

   set fields { GPXGRAVT GPXSANDT GPXCLAYT GPXBULKT GPXOCT GPXGRAVS GPXSANDS GPXCLAYS GPXBULKS GPXOCS }
   set types  { tgrav tsand tclay tref toc sgrav ssand sclay sref soc }
   set idxs   { 2 3 5 6 7 8 9 11 12 13 }

   #----- Create the RPN fields
   foreach field $fields {
      fstdfield copy $field $Grid
   }
   GenX::GridClear $fields 0.0

   #----- Open the file
   gdalfile open HWSDFILE read $GenX::Param(DBase)/$GenX::Path(HWSD)/hwsd.bil

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef HWSDFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with HWSD database, vegetation will not be calculated"
   } else {

      #----- Create lookup table (LUT) for the various types
      vector create HWSDTABLE
      vector dim HWSDTABLE { mu tgrav tsand tclay tref toc sgrav ssand sclay sref soc }

      #----- Set max memory right now, it'll speed up the allocation
      vector mem HWSDTABLE 20000

      Log::Print INFO "Reading HWSD correspondance table"
      set f [open $GenX::Param(DBase)/$GenX::Path(HWSD)/hwsd.csv]

      gets $f line
      while { ![eof $f] } {
         set line [split [gets $f] ,]

         #----- Skip empty lines
         if { [lindex $line 0]!="" } {
            lappend params([lindex $line 0]) [lrange $line 1 end]
         }
      }
      close $f

      Log::Print INFO "Building HWSD lookup table"
      lappend params(0) { 0 0 0 0 0 0 0 0 0 0 0 0 }
      foreach name [lsort -integer -increasing [array names params]] {

         #----- Reset counts
         foreach type $types {
            set $type 0
         }

         #----- There might be multiple types so we have to calculate the % per types
         #      ex: SAND = [SHARE(1)*SAND(1) + SHARE(2)*SAND(2) + SHARE(3)*SAND(3) ...]/100.
         foreach param $params($name) {
            set per   [lindex $param 0]
            foreach type $types idx $idxs {
               if { [set p [lindex $param $idx]]!="" } {
                  eval set $type \[expr \$$type+$per*$p\]
               }
            }
         }
         foreach type $types {
            eval set $type \[expr \$$type/100.0\]
         }
         vector append HWSDTABLE [list $name $tgrav $tsand $tclay $tref $toc $sgrav $ssand $sclay $sref $soc]
      }

      Log::Print INFO "Grid intersection with HWSD database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read HWSDTILE { { HWSDFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            foreach type $types field $fields {

               #----- Apply lookup table for soil type (Cast to Float since HWSDTILE is Integer and we need %)
               vexpr (Float32)$type slut(HWSDTILE,HWSDTABLE.mu,HWSDTABLE.$type)
               gdalband stats $type -nodata 0 -celldim $GenX::Param(Cell)

               #----- If the tile contains soil of this type then average it
               Log::Print DEBUG "      Processing $type (max: [lindex [lindex [gdalband stats $type -max] 0] 0])"
               if { [lindex [lindex [gdalband stats $type -max] 0] 0]>0.0 } {
                  fstdfield gridinterp $field $type AVERAGE False
               }
            }
         }
      }
   }
   gdalfile close HWSDFILE

   #----- Finalize the averaging
   foreach field $fields {
      fstdfield gridinterp $field - NOP True
   }

   #----- Save output
   fstdfield define GPXSANDT -NOMVAR J1 -ETIKET $GenX::Param(ETIKET) -IP1 1199 -DATYP $GenX::Param(Datyp)
   fstdfield define GPXCLAYT -NOMVAR J2 -ETIKET $GenX::Param(ETIKET) -IP1 1199 -DATYP $GenX::Param(Datyp)
   fstdfield define GPXGRAVT -NOMVAR J3 -ETIKET $GenX::Param(ETIKET) -IP1 1199 -DATYP $GenX::Param(Datyp)
   fstdfield define GPXBULKT -NOMVAR J4 -ETIKET $GenX::Param(ETIKET) -IP1 1199 -DATYP $GenX::Param(Datyp)
   fstdfield define GPXOCT   -NOMVAR SOC -ETIKET $GenX::Param(ETIKET) -IP1 1199 -DATYP $GenX::Param(Datyp)

   fstdfield write GPXSANDT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXCLAYT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXGRAVT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXBULKT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXOCT   GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Copy sub-surface data into 4 layers (needed by GEM)
   foreach ip1 { 1198 1197 1196 1195 } {
      fstdfield define GPXSANDS -NOMVAR J1 -ETIKET $GenX::Param(ETIKET) -IP1 $ip1 -DATYP $GenX::Param(Datyp)
      fstdfield define GPXCLAYS -NOMVAR J2 -ETIKET $GenX::Param(ETIKET) -IP1 $ip1 -DATYP $GenX::Param(Datyp)
      fstdfield define GPXGRAVS -NOMVAR J3 -ETIKET $GenX::Param(ETIKET) -IP1 $ip1 -DATYP $GenX::Param(Datyp)
      fstdfield define GPXBULKS -NOMVAR J4 -ETIKET $GenX::Param(ETIKET) -IP1 $ip1 -DATYP $GenX::Param(Datyp)
      fstdfield define GPXOCS   -NOMVAR SOC -ETIKET $GenX::Param(ETIKET) -IP1 $ip1 -DATYP $GenX::Param(Datyp)

      fstdfield write GPXSANDS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXCLAYS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXGRAVS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXBULKS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXOCS   GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   vector free HWSDTABLE
   eval fstdfield free $fields
   eval gdalband free HWSDTILE $types
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoilBNU>
# Creation : June 2014 - V.Souvanlasy - CMC/CMDS
#
# Goal     : Generate the soil percentage through averaging based on BNU/GSDE
#
# Parameters :
#   <Grid>   : Grid on which to generate the sand percentage
#
# Return:
#
# Remarks : This database has 8 layers splitted in 2 files, 4 each.
#      layer    depth(m)
#        1      0     - 0.045, 
#        2      0.045 - 0.091, 
#        3      0.091 - 0.166, 
#        4      0.166 - 0.289, 
#        5      0.289 - 0.493, 
#        6      0.493 - 0.829, 
#        7      0.829 - 1.383 
#        8      1.383 - 2.296
#           
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageSoilBNU { Grid } {
   variable Param

   GenX::Procs BNU

   fstdfield copy GPXJ $Grid

   #----- Force sand and clay type to 8 layers 
   set Param(SandTypes)    { 1 2 3 4 5 6 7 8 }
   set Param(ClayTypes)    { 1 2 3 4 5 6 7 8 }

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
      set has_MG 1
   } else {
      Log::Print WARNING "Could not find mask field MG"
      set has_MG 0
   }

   set files  {}
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/SAND1.nc
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/SAND2.nc
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J1 -100 $has_MG  "$GenX::Param(ETIKET)" "Sand Percentage"

   set files  {}
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/CLAY1.nc
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/CLAY2.nc
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J2 -100 $has_MG  "$GenX::Param(ETIKET)" "Clay Percentage"

   set files  {}
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/GRAV1.nc
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/GRAV2.nc
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J3 -100 $has_MG  "$GenX::Param(ETIKET)" "Gravel Percentage"

   set files  {}
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/BD1.nc
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/BD2.nc
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J4 -999 $has_MG  "$GenX::Param(ETIKET)" "Bulk Density"

   set files  {}
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/OC1.tif
   lappend files $GenX::Param(DBase)/$GenX::Path(BNU)/GSDE/OC2.nc
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files SOC -999 $has_MG  "$GenX::Param(ETIKET)" "Organic Carbon"

   fstdfield free GPXMG GPXJ
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoilHydraulic>
# Creation : June 2014 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Average Soil Hydraulic Parameters using BNU database
#              Beijing Normal University
#              Global Dataset of Soil Hydraulic and Thermal Parameters 
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageSoilHydraulic { Grid } {

   GenX::Procs BNU
   Log::Print INFO "Averaging Soil Hydraulic parameters using BNU/GDSHTP database"

   set Datasets   {k_s     psi_s  theta_s  lambda}
   set VarNames   {K_S     PSIS   W_S      PSDI}
   set Descs      {}
   lappend Descs  {Saturated Hydraulic Conductivity}
   lappend Descs  {Saturated Capillary Potential}
   lappend Descs  {Saturated Water Content}
   lappend Descs  {Pore Size distribution Index}

   fstdfield copy GPXHFLD $Grid

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
      set has_MG 1
   } else {
      Log::Print WARNING "Could not find mask field MG"
      set has_MG 0
   }
   # loop through all available levels

   foreach  dataname $Datasets varname $VarNames desc $Descs {
      set files  {}
      foreach  level {1 2 3 4 5 6 7 8} {
         lappend  files  $GenX::Param(DBase)/$GenX::Path(BNU)/GDSHTP/${dataname}_l${level}.nc
      }
      GeoPhysX::AverageRastersFiles2rpnGrid GPXHFLD $files $varname -9999 $has_MG  "$GenX::Param(ETIKET)" "$desc"
   }
   fstdfield free GPXHFLD
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoilCANSIS>
# Creation : June 2014 - V.Souvanlasy - CMC/CMDS
#
# Goal     : Generate the soil percentage through averaging based on CANSIS
#
# Parameters :
#   <Grid>   : Grid on which to generate the sand percentage
#
# Return:
#
# Remarks : This database has 3 layers at 1km resolution 
#           and is available for North America only

#      layer    thickness(cm)
#        1      10 
#        2      25 
#        3      375
#
# There are 2 types of files, randomly distributed or dominant. We use the dominant type.
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageSoilCANSIS { Grid } {
   variable Param

   GenX::Procs CANSIS

   fstdfield copy GPXJ $Grid

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
      set has_MG 1
   } else {
      Log::Print WARNING "Could not find mask field MG"
      set has_MG 0
   }
#   fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG"

   set files  {}
   lappend files $GenX::Param(DBase)/$GenX::Path(CANSIS)/NA_RANDOM_SAND1_1KM.tif
   lappend files $GenX::Param(DBase)/$GenX::Path(CANSIS)/NA_RANDOM_SAND2_1KM.tif
   lappend files $GenX::Param(DBase)/$GenX::Path(CANSIS)/NA_RANDOM_SAND3_1KM.tif
   set types [GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J1 700 $has_MG  "$GenX::Param(ETIKET)" "Sand Percentage"]
# copying last bottom layer of sand (3)  to 4 and 5
   set nst [llength $Param(SandTypes)]
   set n   [expr [llength $types] + 1]
   for { set type $n } { $type <= $nst } { incr type }  {
      fstdfield define GPXJ -NOMVAR J1 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
      fstdfield write GPXJ GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   }

   set files  {}
   lappend files $GenX::Param(DBase)/$GenX::Path(CANSIS)/NA_RANDOM_CLAY1_1KM.tif
   lappend files $GenX::Param(DBase)/$GenX::Path(CANSIS)/NA_RANDOM_CLAY2_1KM.tif
   lappend files $GenX::Param(DBase)/$GenX::Path(CANSIS)/NA_RANDOM_CLAY3_1KM.tif
   set types [GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J2 700 $has_MG "$GenX::Param(ETIKET)" "Clay Percentage"]
# copying last bottom layer of clay (3)  to 4 and 5
   set nct [llength $Param(ClayTypes)]
   set n   [expr [llength $types] + 1]
   for { set type $n } { $type <= $nct } {incr type } {
      fstdfield define GPXJ -NOMVAR J2 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
      fstdfield write GPXJ GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   }

   set files {}
   lappend files  $GenX::Param(DBase)/$GenX::Path(CANSIS)/NA_TEXTR_DEPTH_1KM.tif
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files DBR 700 $has_MG "$GenX::Param(ETIKET)" "Bed Rock Depth"

   fstdfield free GPXMG GPXJ
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoilGriddedSLC>
# Creation : Jan 2017 - V.Souvanlasy - CMC/CMDS
#
# Goal     : Generate the soil percentage through averaging based on gridded SLC 90M
#
# Parameters :
#   <Grid>   : Grid on which to generate the sand percentage
#
# Return:
#
# Remarks : This database has 6 layers at 90m resolution 
#
#      layer    thickness(cm)
#        1      0-5
#        2      5-15      
#        3      15-30
#        4      30-60
#        5      60-100
#        6      100-200
#
# There are 2 types of files, randomly distributed or dominant. We use the dominant type.
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageSoilGriddedSLC { Grid } {
   variable Param

   GenX::Procs SLCG
   Log::Print INFO "Averaging Soil Texture using Gridded SLC 90M database"

   #----- Force sand and clay type to 6 layers 
   set  Param(SandTypes)    { 1 2 3 4 5 6 }
   set  Param(ClayTypes)    { 1 2 3 4 5 6 }

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
      set has_MG 1
   } else {
      Log::Print WARNING "Could not find mask field MG"
      set has_MG 0
   }

   #-----  create LUT from SLC pyramid database
   set  slcshp   "$GenX::Param(DBase)/$GenX::Path(SLC)/Gridded/gridded_slc_90m.tif.vat.dbf"
   set  sands    {SAND5 SAND15 SAND30 SAND60 SAND100 SAND200}
   set  clays    {CLAY5 CLAY15 CLAY30 CLAY60 CLAY100 CLAY200}
   set  soils    "$sands $clays"
   set  attribs  "POLY_ID $soils"
   
   foreach  attrib $attribs {
      set  LUT($attrib) {}
   }
   set layers  [ogrfile open SLCINDEXFILE read $slcshp]
   set slctablename [lindex [lindex $layers 0] 2]
   eval ogrlayer read SLCINDEX [lindex $layers 0]
   set nb [ogrlayer define SLCINDEX -nb]
   for { set n 0 } { $n< $nb } { incr n } {
      set polyid [ogrlayer define SLCINDEX -feature $n POLY_ID]
      foreach  attrib $attribs {
         set  val  [ogrlayer define SLCINDEX -feature $n $attrib]
         lappend LUT($attrib)  $val
      }
   }
   ogrfile close SLCINDEXFILE

   vector create FROMPID  $LUT(POLY_ID)
   foreach  attrib $sands {
      vector create TOSOIL${attrib} $LUT($attrib)
      fstdfield copy GPXJ1${attrib} $Grid
      GenX::GridClear GPXJ1${attrib} 0.0
   }
   foreach  attrib $clays {
      vector create TOSOIL${attrib} $LUT($attrib)
      fstdfield copy GPXJ2${attrib} $Grid
      GenX::GridClear GPXJ2${attrib} 0.0
   }

   #----- Open the file
   gdalfile open SLCFILE read $GenX::Param(DBase)/$GenX::Path(SLC)/Gridded/gridded_slc_90m.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef SLCFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with Gridded SLC 90M database, J1 and J2 not be calculated"
   } else {
      Log::Print INFO "Grid intersection with gridded SLC 90M database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read SLCTILE { { SLCFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats SLCTILE -celldim $GenX::Param(Cell)

            foreach attrib $sands {
               set  tosoil  TOSOIL${attrib}
               vexpr SOILTILE lut(SLCTILE,FROMPID,$tosoil)
               fstdfield gridinterp GPXJ1${attrib} SOILTILE AVERAGE False
            }
            foreach attrib $clays {
               set  tosoil  TOSOIL${attrib}
               vexpr SOILTILE lut(SLCTILE,FROMPID,$tosoil)
               fstdfield gridinterp GPXJ2${attrib} SOILTILE AVERAGE False
            }
         }
      }
      gdalband free SLCTILE
      gdalfile close SLCFILE

      foreach attrib $sands {
         fstdfield gridinterp GPXJ1${attrib} - NOP True
         if { $has_MG } {
            vexpr  GPXJ1${attrib} "ifelse(GPXMG>0.0, GPXJ1${attrib}, 0.0)"
         }
      }
      foreach attrib $clays {
         fstdfield gridinterp GPXJ2${attrib} - NOP True
         if { $has_MG } {
            vexpr  GPXJ2${attrib} "ifelse(GPXMG>0.0, GPXJ2${attrib}, 0.0)"
         }
      }

      set etiket  "$GenX::Param(ETIKET)"
      set type  1
      foreach attrib $sands {
         fstdfield define GPXJ1${attrib} -NOMVAR J1 -IP1 [expr 1200-$type] -ETIKET "$etiket"
         fstdfield write GPXJ1${attrib} GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
         fstdfield free GPXJ1${attrib}
         incr type
      }
      set type  1
      foreach attrib $clays {
         fstdfield define GPXJ2${attrib} -NOMVAR J2 -IP1 [expr 1200-$type] -ETIKET "$etiket"
         fstdfield write GPXJ2${attrib} GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
         fstdfield free GPXJ2${attrib}
         incr type
      }
   }

   vector free FROMPID
   foreach  attrib $soils {
      vector free TOSOIL${attrib}
   }
   fstdfield free GPXMG
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageSoil_SoilGrids>
# Creation : May 2017 - V.Souvanlasy - CMC/CMDD
#
# Goal     : Generate the soil percentage through averaging based on SoilsGrid
#
# Parameters :
#   <Grid>   : Grid on which to generate the sand percentage
#
# Return:
#
# Remarks : This database has 7 layers 
#      layer    depth(m)
#        1      0    - 0.04, 
#        2      0.05 - 0.14, 
#        3      0.15 - 0.29, 
#        4      0.30 - 0.59, 
#        5      0.60 - 0.99, 
#        6      1.00 - 1.99, 
#        7      2.00
#           
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageSoil_SoilGrids { Grid } {
   variable Param

   GenX::Procs SoilGrids
   Log::Print INFO "Averaging Soil Texture using SoilGrids database"

   fstdfield copy GPXJ $Grid

   #----- Force sand and clay type to 7 layers 
   set Param(SandTypes)    { 1 2 3 4 5 6 7 }
   set Param(ClayTypes)    { 1 2 3 4 5 6 7 }

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
      set has_MG 1
   } else {
      Log::Print WARNING "Could not find mask field MG"
      set has_MG 0
   }

   set files [glob  $GenX::Param(DBase)/$GenX::Path(SOILGRIDS)/SNDPPT_M_sl*_250m_ll.tif]
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J1 255 $has_MG  "$GenX::Param(ETIKET)" "Sand Percentage"

   set files [glob  $GenX::Param(DBase)/$GenX::Path(SOILGRIDS)/CLYPPT_M_sl*_250m_ll.tif]
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files J2 255 $has_MG  "$GenX::Param(ETIKET)" "Clay Percentage"

   set files $GenX::Param(DBase)/$GenX::Path(SOILGRIDS)/BDRICM_M_250m_ll.tif
   GeoPhysX::AverageRastersFiles2rpnGrid GPXJ $files DBR 255 $has_MG "$GenX::Param(ETIKET)" "Bed Rock Depth"

   fstdfield free GPXMG GPXJ
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTreeCover>
# Creation : June 2023 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the Tree Cover Density
#            using TCC_2010, GFCC30TC_2015 and GFCH_2019 as mask
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTreeCover { Grid } {

   variable  Param


   GenX::Procs TreeCover

   Log::Print INFO "Averaging Tree Cover using $GenX::Param(TreeCover)"
   fstdfield copy GPXCCNW  $Grid
   fstdfield copy GPXCCL  $Grid
   fstdfield copy GPXCCG  $Grid
   fstdfield copy GPXVFH  $Grid
   GenX::GridClear GPXCCNW 0.0
   GenX::GridClear GPXCCL 0.0
   GenX::GridClear GPXCCG 0.0
   GenX::GridClear GPXVFH 0.0

   foreach treecover $GenX::Param(TreeCover) {
      GenX::GridClear GPXCCG 0.0
      switch $treecover {
         "TCC_2010" {
            set nomvar "CCG"
            GeoPhysX::AverageIndexedBands  GPXCCG   $GenX::Path(TCC) "$GenX::Param(DBase)/$GenX::Path(TCC)"
         }
         "TCC_2010-NW" {
            set nomvar "CCNW"
            GeoPhysX::AverageIndexedBands  GPXCCG   $GenX::Path(TCC_NW) "$GenX::Param(DBase)/$GenX::Path(TCC_NW)"
         }
         "TCC_2010-LO" {
            set nomvar "CCLO"
            GeoPhysX::AverageIndexedBands  GPXCCG   $GenX::Path(TCC_LO) "$GenX::Param(DBase)/$GenX::Path(TCC_LO)"
         }
         "TCC_2010-VL" {
            set nomvar "CCVL"
            GeoPhysX::AverageIndexedBands  GPXCCG   $GenX::Path(TCC_VL) "$GenX::Param(DBase)/$GenX::Path(TCC_VL)"
         }
         "TCC_2010-VH" {
            set nomvar "CCVH"
            GeoPhysX::AverageIndexedBands  GPXCCG   $GenX::Path(TCC_VH) "$GenX::Param(DBase)/$GenX::Path(TCC_VH)"
         }
         "GFCC30TC_2015" {
            set nomvar "CCG"
            GeoPhysX::AverageIndexedBands  GPXCCG   $GenX::Path(GFCC30TC) "$GenX::Param(DBase)/$GenX::Path(GFCC30TC)" "" 255 100
         }
         default {
            Log::Print WARNING "Unsupported TreeCover : treecover"
         }
      }
      vexpr  GPXCCG  "GPXCCG * 0.01"
      fstdfield define GPXCCG -NOMVAR $nomvar -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXCCG GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   #----- check for needed fields
   foreach type {4 5 6 7 8 9 25 26} {
      if { ![catch { fstdfield read GPXVF GPXAUXFILE -1 "" [expr 1200-$type] -1 -1 "" "VF" }] } {
         vexpr GPXVFH  GPXVFH+GPXVF
      } else {
         Log::Print WARNING "Could not find VF($type) field while processing High Vegetation field"
      }
   }

   fstdfield read GPXVF1   GPXAUXFILE -1 ""  1199  -1 -1 "" "VF"
   fstdfield read GPXVF2   GPXAUXFILE -1 ""  1198  -1 -1 "" "VF"
   fstdfield read GPXVF3   GPXAUXFILE -1 ""  1197  -1 -1 "" "VF"
   fstdfield read GPXVF21  GPXAUXFILE -1 ""  1179  -1 -1 "" "VF"

   vexpr GPXVFNT  "GPXVF1+GPXVF3+GPXVF2+GPXVF21"

   vexpr GPXCCL  "ifelse(GPXVFNT<1.0,GPXCCG/(1-GPXVFNT),0.0)"
   vexpr GPXCCL  "ifelse(GPXVFH>0.0,GPXCCL,0.0)"

   fstdfield define GPXCCL -NOMVAR CCL -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXCCL GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield define GPXVFNT -NOMVAR VFNT -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXVFNT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield define GPXVFH -NOMVAR VFH -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXVFH GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield free GPXCCL GPXCCG GPXCCNW GPXVFNT GPXVFH GPXVF1 GPXVF2 GPXVF3 GPXVF21

}


#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageGeoidHeight>
# Creation : Aug 2017 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the Geoid Height through averaging.
#            using NGA EGM96 or EGM2008 datafiles
#
# Parameters :
#   <Grid>   : Grid on which to generate the mask
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageGeoidHeight { Grid } {

   variable  Param
#
# make sure EGMGH is valid, if not, set it to default EGM96
#
   switch $GenX::Param(EGMGH) {
      "EGM96" { }
      "EGM2008" { }
      default {
         set  GenX::Param(EGMGH)  "EGM96"
      }
   }
   set GenX::Path(EGMGH)  $GenX::Path($GenX::Param(EGMGH))

   GenX::Procs $GenX::Param(EGMGH)

   Log::Print INFO "Averaging Geoid Height using $GenX::Param(EGMGH)"
   fstdfield copy GPXGH  $Grid
   GenX::GridClear GPXGH 0.0

   GeoPhysX::AverageIndexedBands  GPXGH  $GenX::Param(EGMGH) "$GenX::Param(DBase)/$GenX::Path(EGMGH)/data"

   fstdfield define GPXGH -NOMVAR GH -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXGH GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield free GPXGH
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageBathymetry>
# Creation : Octobre 2018 - V. Souvanlasy - CMC/CMDS
#
# Goal     : Generate the bathymetry through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the bathy
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageBathymetry { Grid } {
   variable Param
   variable Opt

   GenX::Procs $GenX::Param(Bathy)

   fstdfield copy GPXGEBCO $Grid
   fstdfield copy GPXBATHY $Grid
   fstdfield copy GPXDEPTH $Grid
 
   GenX::GridClear {GPXBATHY} 0.0
   set nodata 999 
   GenX::GridClear {GPXDEPTH GPXGEBCO} $nodata

   #----- check for needed fields
   set Has_TOPO 1
   if { [catch {
      fstdfield read GPXTOPO   GPXOUTFILE -1 "" -1   -1 -1 "" "MENF"
      } ] } {
      Log::Print WARNING "Missing topo field"
      set Has_TOPO 0
   }
   set Has_MG 1
   if { [catch {
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1   -1 -1 "" "MG"
      } ] } {
      set Has_MG 0
   }

   # the GEBCO bathymetry field is leveled according to sea levels = 0
   if { [lsearch -exact $GenX::Param(Bathy) GEBCO]!=-1 } {
      GeoPhysX::AverageBathymetryGEBCO  GPXGEBCO
      vexpr  GPXDEPTH  "ifelse(GPXGEBCO<0.0,GPXGEBCO,0.0)"
      set Has_GEBCO  1
   } else {
      set Has_GEBCO  0
   }

   set Has_HL 1
   if { [catch {
      fstdfield read GPXLAKED   GPXAUXFILE -1 "" -1   -1 -1 "" "LACD"
      fstdfield read GPXLAKEF   GPXAUXFILE -1 "" -1   -1 -1 "" "LACF"
      Log::Print INFO "Will use existing LAKED and LAKEF"
      } ] } {
      set Has_HL 0
   }

   # will use lake depth data if present
   if { [lsearch -exact $GenX::Param(Bathy) HYDROLAKES]!=-1 } {
      if { $Has_HL == 0 } {
         fstdfield copy GPXLAKEF $Grid
         fstdfield copy GPXLAKED $Grid
         fstdfield copy GPXLAKES $Grid
         fstdfield copy GPXLAKEG $Grid
         GenX::GridClear {GPXLAKEF GPXLAKED GPXLAKES GPXLAKEG} 0.0
         HydroX::HydroLakesDepth $Grid GPXLAKEF GPXLAKED GPXLAKES GPXLAKEG
   
         fstdfield define GPXLAKED -NOMVAR LACD -IP1 1200 -DATYP $GenX::Param(Datyp) -ETIKET $GenX::Param(ETIKET)
         fstdfield write GPXLAKED GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
         fstdfield define GPXLAKEF -NOMVAR LACF -IP1 1200 -DATYP $GenX::Param(Datyp) -ETIKET $GenX::Param(ETIKET)
         fstdfield write GPXLAKEF GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
         fstdfield define GPXLAKES -NOMVAR LACS -IP1 1200 -DATYP $GenX::Param(Datyp) -ETIKET $GenX::Param(ETIKET)
         fstdfield write GPXLAKES GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
         fstdfield define GPXLAKEG -NOMVAR LACG -IP1 1200 -DATYP $GenX::Param(Datyp) -ETIKET $GenX::Param(ETIKET)
         fstdfield write GPXLAKEG GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   
         fstdfield free GPXLAKEA GPXLAKES GPXLAKEG
         set Has_HL  1
      }
   } else {
      set Has_HL  0
   }

   # the CHS bathymetry is simply water depth
   if { [lsearch -exact $GenX::Param(Bathy) CHS]!=-1 } {

      Log::Print INFO "Averaging CHS bathymetry data"
      GenX::GridClear GPXBATHY $nodata
      GeoPhysX::AverageIndexedBands  GPXBATHY CHS "$GenX::Param(DBase)/$GenX::Path(CHS)" "" $nodata

      vexpr  GPXDEPTH  "ifelse(GPXBATHY<$nodata,GPXBATHY,GPXDEPTH)"
   }

   # the NCEI bathymetry is simply water depth
   if { [lsearch -exact $GenX::Param(Bathy) NCEI]!=-1 } {
      Log::Print INFO "Averaging NCEI Great Lakes bathymetry data"
      set ncei_nodata -9999
      GenX::GridClear GPXBATHY 0.0
      GeoPhysX::AverageIndexedBands  GPXBATHY NCEI "$GenX::Param(DBase)/$GenX::Path(NCEI)" "" $ncei_nodata 0.0

      if { $Has_HL } {
         fstdfield copy GREATLAKES $Grid
         GenX::GridClear GREATLAKES 0.0

         set shp_dir   "$GenX::Param(DBase)/$GenX::Path(GREATLAKES)"

         GeoPhysX::AverageIndexedLayers GREATLAKES $shp_dir
         vexpr GPXLAKED  "ifelse(GREATLAKES>0,GPXLAKED*GPXLAKEF,GPXLAKED)"
         vexpr GPXDEPTH  "ifelse(GPXLAKED<0.0,GPXLAKED,GPXDEPTH)"
         vexpr GPXDEPTH  "ifelse(GPXBATHY<0,GPXBATHY,GPXDEPTH)"
         fstdfield free GREATLAKES
      } else {
         vexpr  GPXDEPTH  "ifelse(GPXBATHY<0,GPXBATHY,GPXDEPTH)"
      }
   } else {
      if { $Has_HL } {
         vexpr GPXDEPTH  "ifelse(GPXLAKED<0.0,GPXLAKED,GPXDEPTH)"
      }
   }

   if { $Has_HL } {
      fstdfield free GPXLAKED GPXLAKEF
   }

   if { $Has_MG } {
      vexpr  GPXDEPTH  "ifelse(GPXMG<1.0,GPXDEPTH,0.0)"
   }
   vexpr GPXDEPTH  "ifelse(GPXDEPTH>0.0,0.0,GPXDEPTH)"

   if { $Has_TOPO } {
      vexpr GPXBATHY  "GPXDEPTH+GPXTOPO"
   } elseif { $Has_GEBCO } {
      vexpr  GPXBATHY  "ifelse(GPXGEBCO>0.0,GPXGEBCO+GPXDEPTH,GPXDEPTH)"
   } else {
      vexpr GPXBATHY  "GPXDEPTH"
   }

   fstdfield define GPXBATHY -NOMVAR BMSL -IP1 1200 -DATYP $GenX::Param(Datyp) -ETIKET $GenX::Param(ETIKET)
   fstdfield write GPXBATHY GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield define GPXDEPTH -NOMVAR DEEP -IP1 1200 -DATYP $GenX::Param(Datyp) -ETIKET $GenX::Param(ETIKET)
   fstdfield write GPXDEPTH GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Save output

   fstdfield free GPXBATHY GPXDEPTH GPXGEBCO
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageBathymetryGEBCO>
# Creation : October 2018 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Generate the bathymetry using GEBCO
#
# Parameters :
#   <Grid>   : Grid on which to generate the bathymetry
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageBathymetryGEBCO { Grid } {
   variable Param
   variable Opt

   GenX::Procs GEBCO
   Log::Print INFO "Averaging bathymetry using GEBCO database"

   set file  "$GenX::Param(DBase)/$GenX::Path(GEBCO)/GEBCO_2014_1D.nc"
   set bands [gdalfile open GEBCOFILE read $file]

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GEBCOFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GEBCO bathymetry database"
      return
   } else {
      Log::Print INFO "Grid intersection with GEBCO bathymetry database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]
   }

   #----- Loop over the data by tiles since it's too big to fit in memory
   for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
      for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
         Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
         gdalband read GEBCOTILE { { GEBCOFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
         gdalband stats GEBCOTILE -nodata 0 -celldim $GenX::Param(Cell)

         fstdfield gridinterp $Grid GEBCOTILE AVERAGE False
      }
   }

   fstdfield gridinterp $Grid - NOP True
   gdalfile close GEBCOFILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageIndexedBands>
# Creation : October 2018 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Average bands into field
#
# Parameters :
#   <Grid>   : Grid on which to generate the field
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageIndexedBands { Grid dbname basedir {CALLPROCFLD ""} {nodata ""} {maxvalue  3.4e38} } {
   variable Param

   GenX::Procs $dbname
   Log::Print INFO "Averaging field using bands from $dbname database"

   set has_CallProc 0
   if { [llength $CALLPROCFLD] == 2 } {
      set CALLPROC [lindex $CALLPROCFLD 1]
      set PROCFLD  [lindex $CALLPROCFLD 0]
      if { [fstdfield is $PROCFLD] } {
         set has_CallProc 1
      }
   }

   # choose  the right mode for interpolation
   set grid_reso [GenX::Get_Grid_Reso $Grid]
   Log::Print INFO "   Estimated target grid resolution=$grid_reso"
   set  inter_mode  "$GenX::Param(Interpolation)"
   switch $inter_mode {
      "LINEAR" {
      }
      "AVERAGE" {
      }
      "NEAREST" {
      }
      default {
         set inter_mode ""
      }
   }
   if { $inter_mode != "" } {
      Log::Print INFO "   Will use interpolation mode $inter_mode"
   } else {
      Log::Print INFO "   Will choose interpolation mode for each tile"
   }

   set indexfile "$basedir/Index/Index.shp"
   set files [GenX::FindFiles $indexfile $Grid]
   #----- Loop over files
   if { [set nb [llength $files]] } {

      foreach file $files {
         set  filename $basedir/$file
         Log::Print INFO "   Processing file ([incr n]/$nb) $filename"

         gdalfile open BDBFILE read $filename
         set georef [gdalfile  georef BDBFILE]

         if { $inter_mode == "" } {
            set file_reso [GenX::Get_GDFile_Reso BDBFILE]
            Log::Print INFO "   GDAL File Reso=$file_reso"
            if { $grid_reso <= $file_reso } {
               set mode "LINEAR"
            } else {
               set mode "AVERAGE"
            }
            Log::Print INFO "   Using interpolation mode $mode"
         } else {
            set mode  $inter_mode
         }

         if { [llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef BDBFILE]]]] } {
            Log::Print INFO "   Grid intersection with data file is { $limits }"
            set x0 [lindex $limits 0]
            set x1 [lindex $limits 2]
            set y0 [lindex $limits 1]
            set y1 [lindex $limits 3]
   
         #----- Loop over the data by tiles since it's too big to fit in memory
            for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
               for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
                  Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
                  gdalband read BDBTILE { { BDBFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]

                  # using default file's nodata or specify a new one
                  if { "$nodata" != "" } {
                     vexpr BDBTILE "ifelse(BDBTILE>$maxvalue,$nodata,BDBTILE)"
                     gdalband stats BDBTILE -nodata $nodata -celldim $GenX::Param(Cell)
                  } else {
                     gdalband stats BDBTILE -celldim $GenX::Param(Cell)
                  }

                  if { $has_CallProc } {
                     $CALLPROC $PROCFLD BDBTILE $nodata
	          }
   
                  if { [string compare $mode "AVERAGE"] == 0 } {
                     fstdfield gridinterp $Grid BDBTILE AVERAGE False
                  } else {
                     fstdfield gridinterp $Grid BDBTILE $mode
                  }
                  gdalband free BDBTILE

               }
            }
         }
         gdalfile close BDBFILE
      }
      if { [string compare $mode "AVERAGE"] == 0 } {
         fstdfield gridinterp $Grid - NOP True
      }
      if { $has_CallProc } {
         fstdfield gridinterp $PROCFLD - NOP True
      }

   } else {
      Log::Print WARNING "The grid is not within $dbname limits"
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageRastersFiles2rpnGrid>
# Creation : June 2014 
#
# Goal     : Generate the fields using 
#            rasterized bands from files
#
# Parameters :
#   <Grid>   : Grid on which to generate the fields
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageRastersFiles2rpnGrid { Grid files varname nodata has_MG etiket description {write_fld 1} {CALLPROCFLD ""} } {

   set types {}

   set has_CallProc 0
   if { [llength $CALLPROCFLD] == 2 } {
      set CALLPROC [lindex $CALLPROCFLD 1]
      set PROCFLD  [lindex $CALLPROCFLD 0]
      if { [fstdfield is $PROCFLD] } {
         set has_CallProc 1
      }
   }

   #----- Open the files
   set fntype  1
   foreach file $files {
      Log::Print INFO "Averaging $varname ($description) using database: $file"
      set type $fntype
      set bands [gdalfile open BFRFILE read $file]
      set nbands [llength $bands]
      if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef BFRFILE]]]] } {
         Log::Print WARNING "Specified grid does not intersect with database, $varname will be saved as empty"
         set  intersect 0
      } else {
         Log::Print INFO "Grid intersection with database is { $limits }"
         set x0 [lindex $limits 0]
         set x1 [lindex $limits 2]
         set y0 [lindex $limits 1]
         set y1 [lindex $limits 3]
         set  intersect 1
      }

      foreach  band $bands {

         GenX::GridClear  $Grid  0.0
         if { $intersect } {
         #----- Loop over the data by tiles since it's too big to fit in memory
            for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
               for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
                  Log::Print DEBUG "   Processing tile: $band $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
                  set lband [lrange $band 0 1]
                  gdalband read BFRTILE "{ $lband }" $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]

                  if { $has_CallProc } {
                     $CALLPROC $PROCFLD BFRTILE $nodata
	          }

                  gdalband stats BFRTILE -nodata $nodata -celldim $GenX::Param(Cell)
                  fstdfield gridinterp $Grid BFRTILE AVERAGE False
               }
            }
   
            fstdfield gridinterp $Grid - NOP True

            if { $has_CallProc } {
               fstdfield gridinterp $PROCFLD - NOP True
            }

            if { $has_MG } {
               vexpr  $Grid "ifelse(GPXMG>0.0, $Grid, 0.0)"
            }
         }
   
         #----- Save output (Same for all layers)
         lappend types $type
	 if { $write_fld } {
            fstdfield define $Grid -NOMVAR $varname -IP1 [expr 1200-$type] -ETIKET "$etiket"
            fstdfield write $Grid GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
         }
         gdalband free BFRTILE

         incr type
      }
      gdalfile close BFRFILE
      set fntype [expr $fntype + $nbands]
   }
   return $types
}

proc LogTreeHeight { FLD Tile nodata } {

    if { $nodata != 0 } {
      set Tile2 ${Tile}ZM
      vexpr $Tile2 "ifelse($Tile==$nodata,0,$Tile)"
      set Tile $Tile2
    } else {
      set Tile2 ""
    }

    gdalband stats $Tile -nodata 0
    vexpr LOGTILE "ifelse($Tile>0,ln($Tile/10.0),-99)"
    gdalband stats LOGTILE -nodata -99 -celldim $GenX::Param(Cell)
    fstdfield gridinterp $FLD LOGTILE AVERAGE False
    gdalband free LOGTILE

    if { $Tile2 != "" } {
       gdalband free $Tile2
    }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageClay>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the clay percentage through averaging.
#
# Parameters :
#   <Grid>   : Grid on which to generate the clay percentage
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageClay { Grid } {
   variable Param

   GenX::Procs ClayUSDA ClayFAO ClayAGRC
   fstdfield copy GPXJ2 $Grid

   #----- Loop over types
   foreach type $Param(ClayTypes) {
      Log::Print INFO "Averaging clay ($type)"
      GenX::GridClear GPXJ2 0.0
      fstdfield stats GPXJ2 -mask ""

      #----- Loop over datasets
      foreach db $GenX::Param(Soil) {
         Log::Print DEBUG "   Processing database $db"

         #----- Loop over files
         foreach file [glob $GenX::Param(DBase)/$GenX::Path(Clay$db)/*] {
            GenX::Procs Clay$db
            Log::Print DEBUG "      Processing file : $file"
            fstdfile open GPXCLAYFILE read $file

            #----- Loop over fields (tiles)
            foreach field [fstdfield find GPXCLAYFILE -1 "" -1 -1 $type "" "AG"] {
               Log::Print DEBUG "         Processing field : $field"
               fstdfield read CLAYTILE GPXCLAYFILE $field
               vexpr CLAYTILE max(CLAYTILE,0.0)
               fstdfield stats CLAYTILE -nodata 0.0 -celldim $GenX::Param(Cell)

               #----- Average on each output grid
               fstdfield gridinterp GPXJ2 CLAYTILE AVERAGE False
            }
            fstdfile close GPXCLAYFILE
         }
         fstdfield gridinterp GPXJ2 - ACCUM
         vexpr GPXJ2SK !fpeel(GPXJ2)
         fstdfield stats GPXJ2 -mask GPXJ2SK
      }
      fstdfield gridinterp GPXJ2 - NOP True

      #----- avoid saving the mask
      fstdfield stats GPXJ2 -mask ""
      #----- Save output
      fstdfield define GPXJ2 -NOMVAR J2 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
      fstdfield write GPXJ2 GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   }
   fstdfield free CLAYTILE GPXJ2 GPXJ2SK
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoLow>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Generate the topo from low and high res data sampling for scale separation.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topo
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoLow { Grid } {

   GenX::Procs TopoLow
   Log::Print INFO "Averaging low resolution topography"

   fstdfield copy GPXLRMS $Grid
   fstdfield copy GPXLOW  $Grid
   GenX::GridClear [list GPXLOW GPXLRMS] 0.0

   #----- Loop over files
   foreach file [glob $GenX::Param(DBase)/$GenX::Path(TopoLow)/*] {
      Log::Print DEBUG "   Processing file : $file"
      fstdfile open GPXLOWFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXLOWFILE -1 "" -1 -1 -1 "" "ME"] {
         Log::Print DEBUG "      Processing field : $field"
         fstdfield read LOWTILE GPXLOWFILE $field
         fstdfield stats LOWTILE -nodata 0.0 -celldim $GenX::Param(Cell)

         #----- compute average of <Hhr^2>ij on target grid
         vexpr LOWTILE2 (LOWTILE*LOWTILE)
         fstdfield gridinterp GPXLRMS LOWTILE2 AVERAGE False
         fstdfield gridinterp GPXLOW LOWTILE AVERAGE False
      }
      fstdfile close GPXLOWFILE
   }

   #----- Save output
   fstdfield gridinterp GPXLOW - NOP True
   vexpr GPXLOW ifelse(GPXLOW==-99.0,0.0,GPXLOW)
   fstdfield define GPXLOW -NOMVAR MEL -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXLOW GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   #----- save <Hhr^2>ij
   fstdfield gridinterp GPXLRMS - NOP True
   vexpr GPXLRMS ifelse(GPXLRMS>0.0,GPXLRMS^0.5,0.0)
   fstdfield define GPXLRMS -NOMVAR LRMS -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXLRMS GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   fstdfield free LOWTILE LOWTILE2 GPXLRMS
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageGradient>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Generate the Gradient Correlation from Y789.
#
# Parameters :
#   <Grid>   : Grid on which to generate the correlation gradient.
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageGradient { Grid } {

   GenX::Procs Grad
   Log::Print INFO "Averaging gradient correlation"

   fstdfield copy GPXGXX $Grid
   fstdfield copy GPXGYY $Grid
   fstdfield copy GPXGXY $Grid

   GenX::GridClear [list GPXGXX GPXGYY GPXGXY] 0.0

   #----- compute Gxx, Gyy, Gxy
   foreach file [glob $GenX::Param(DBase)/$GenX::Path(Grad)/*] {
      Log::Print DEBUG "   Processing file: $file "
      fstdfile open GPXGXYFILE read $file
      foreach field_gx [fstdfield find GPXGXYFILE -1 "" -1 -1 -1 "" "GX"] \
              field_gy [fstdfield find GPXGXYFILE -1 "" -1 -1 -1 "" "GY"] {
          Log::Print DEBUG "      Processing field : $field_gx"
          fstdfield read GXYTILE1 GPXGXYFILE $field_gx
          fstdfield stats GXYTILE1 -nodata 0 -celldim $GenX::Param(Cell)

          Log::Print DEBUG "      Processing field : $field_gy"
          fstdfield read GXYTILE2 GPXGXYFILE $field_gy
          fstdfield stats GXYTILE2 -nodata 0 -celldim $GenX::Param(Cell)

          #----- Compute correlation Gxx
          vexpr GXYTILE1X (GXYTILE1*GXYTILE1)
          fstdfield gridinterp GPXGXX GXYTILE1X AVERAGE False

          #----- Compute correlation Gyy
          vexpr GXYTILE2Y (GXYTILE2*GXYTILE2)
          fstdfield gridinterp GPXGYY GXYTILE2Y AVERAGE False

          #----- Compute correlation Gxy
          vexpr GXYTILE (GXYTILE1*GXYTILE2)
          fstdfield gridinterp GPXGXY GXYTILE AVERAGE False
      }
      fstdfile close GPXGXYFILE
   }

   #----- Save output
   fstdfield gridinterp GPXGXX - NOP True
   fstdfield define GPXGXX -NOMVAR GXX -ETIKET $GenX::Param(ETIKET) -IP1 0
   fstdfield write GPXGXX GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield gridinterp GPXGYY - NOP True
   fstdfield define GPXGYY -NOMVAR GYY -ETIKET $GenX::Param(ETIKET) -IP1 0
   fstdfield write GPXGYY GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield gridinterp GPXGXY - NOP True
   fstdfield define GPXGXY -NOMVAR GXY -ETIKET $GenX::Param(ETIKET) -IP1 0
   fstdfield write GPXGXY GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GXYTILE GXYTILE1 GXYTILE2 GXYTILE1X GXYTILE2Y GPXGXX GPXGYY GPXGXY
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubCorrectionFilter>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Generate a correction filter.
#
# Parameters   :
#   <FieldRes> : Riled to filter.
#   <FieldDX>  : X Cell length
#   <FieldDY>  : Y Cell length
#   <DBR>      :
#   <C1>       :
#   <C2>       :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubCorrectionFilter { FieldRes FieldDX FieldDY DBR C1 C2 } {

   vexpr GPXDD sqrt($FieldDX*$FieldDY)
   vexpr GPXAN exp(-1.0*($C1*(GPXDD/$DBR)-$C2))
   vexpr $FieldRes 0.5*(1.0+(1.0-GPXAN)/(1.0+GPXAN))

   fstdfield free GPXAN GPXDD
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubCorrectionFactor>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Apply a correction factor from low and high res topo.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubCorrectionFactor { } {
   variable Const

   GenX::Procs
   fstdfield read GPXMG GPXOUTFILE -1 "" -1 -1 -1 "" "MG"
   fstdfield read GPXMRES GPXAUXFILE -1 "" -1 -1 -1 "" "MRES"

   #----- For low-res and hi-res
   Log::Print INFO "Computing low and high res fields"

   vexpr GPXDX ddx(GPXMG)
   vexpr GPXDY ddy(GPXMG)

   GeoPhysX::SubCorrectionFilter GPXFLR GPXDX GPXDY $Const(lres) $Const(largec0) $Const(largec1)
   GeoPhysX::SubCorrectionFilter GPXFHR GPXDX GPXDY GPXMRES $Const(smallc0) $Const(smallc1)

   fstdfield define GPXFLR -NOMVAR FLR -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXFLR GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield define GPXFHR -NOMVAR FHR -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXFHR GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   #----- For low-res and hi-res (over land only)
   Log::Print INFO "Computing low and high res fields over land only"

   vexpr GPXDX GPXDX*sqrt(GPXMG)
   vexpr GPXDY GPXDY*sqrt(GPXMG)

   GeoPhysX::SubCorrectionFilter GPXFLR GPXDX GPXDY $Const(lres) $Const(largec0) $Const(largec1)
   GeoPhysX::SubCorrectionFilter GPXFHR GPXDX GPXDY GPXMRES $Const(smallc0) $Const(smallc1)

   fstdfield define GPXFLR -NOMVAR FLRP -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXFLR GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
   fstdfield define GPXFHR -NOMVAR FHRP -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXFHR GPXAUXFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   fstdfield free GPXMG GPXDX GPXDY GPXFLR GPXFHR
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubTopoFilter>
# Creation : Septembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Apply the GEM or LPass topo filter to previously generated topo.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubTopoFilter { } {

   GenX::Procs
   
   fstdfield read GPXMF GPXOUTFILE -1 "" -1 -1 -1 "" "MENF"

   Log::Print INFO "Filtering ME"

   switch $GenX::Param(MEFilter) {
      "LPASS" {
         GeoPhysX::LowPassFilter GPXMF
      }
      default {
         Log::Print INFO "   using default GEM filter"
         geophy zfilter GPXMF GenX::Settings 
      }
   }

   fstdfield define GPXMF -NOMVAR ME -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXMF GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXMF
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::LowPassFilter>
# Creation : Septembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Apply the GEM or LPass topo filter to previously generated topo.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::LowPassFilter { Grid } {

   if { $GenX::Settings(LPASSFLT_MASK_OPERATOR) != 0 } {
      if { [catch { fstdfield read GPXSSS GPXOUTFILE -1 "" -1 -1 -1 "" "SSS" } ] } {
         Log::Print WARNING "   Missing SSS field, using LPass filter without mask"
         geophy lpass_filter $Grid GenX::Settings
      } else {
         Log::Print INFO "   using LPass filter with SSS mask"
         geophy lpass_filter $Grid GenX::Settings GPXSSS
      }
      fstdfield free GPXSSS
   } else {
      Log::Print INFO "   using LPass filter"
      geophy lpass_filter $Grid GenX::Settings
   }
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::LegacySub>
# Creation : ?
#
# Goal     : Calculates subgrid fields as in "genesis".
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::LegacySub { Grid } {
   variable Param
   variable Const

   GenX::Procs
 
   #----- check for needed fields
   if { $GenX::Settings(TOPO_RUGV_ZVG2) } {
      if {$GenX::Param(TOPO_ZVG2_TYPE) == "CANOPY_LT"} {
         set  varname Z0VG
         set  infile  GPXAUXFILE
      } else {
         set  varname ZVG2
         set  infile  GPXOUTFILE
      }
   } else {
      set  varname VG
   }
   if { [catch { fstdfield read GPXZVG $infile -1 "" -1 -1 -1 "" $varname } ] } {
      Log::Print WARNING "Missing field: $varname, will not calculate legacy sub grid fields"
      return
   }

   #----- if MG is used to set water roughness
   if { $GenX::Settings(TOPO_RUGV_ZVG2) } {
      if { $GenX::Settings(TOPO_RUGV_MG) } {
         if { [catch { fstdfield read GPXMG GPXOUTFILE -1 "" -1 -1 -1 "" MG } ] } {
            Log::Print WARNING "Missing field: MG, will not calculate legacy sub grid fields"
            return
         }
         if { [info exists GenX::Settings(TOPO_WATER_RUGV)] } {
            set  zwater $GenX::Settings(TOPO_WATER_RUGV)
         } else {
            set  zwater 0.001
         }
         vexpr GPXZVG  "ifelse(GPXMG>0.0,GPXZVG,$zwater)"
         fstdfield free GPXMG
      }
   }
  
   fstdfield copy GPXZ0 $Grid
   fstdfield copy GPXLH $Grid
   fstdfield copy GPXDH $Grid
   fstdfield copy GPXY7 $Grid
   fstdfield copy GPXY8 $Grid
   fstdfield copy GPXY9 $Grid
   GenX::GridClear { GPXLH GPXDH GPXY7 GPXY8 GPXY9 } 0.0
   GenX::GridClear { GPXZ0 } 0.001
 
   Log::Print INFO "Computing legacy sub grid fields Z0 ZP LH DH Y7 Y8 Y9"

   switch $GenX::Param(MEFilterForZ0) {
      "LPASS" {
         GeoPhysX::LowPassFilter GPXME
      }
      "STD" {
         geophy zfilter GPXME GenX::Settings
      }
      default {
      }
   }


   set  smax  [vexpr a "smax(GPXME)"]
   if { $smax > 0.0 } {
      if { $GenX::Settings(TOPO_RUGV_ZVG2) } {
         Log::Print INFO "Computing Z0 Using field $varname"
         geophy subgrid_legacy GPXME GPXZVG GPXZ0 GPXLH GPXDH GPXY7 GPXY8 GPXY9 GenX::Settings
      } else {
         Log::Print INFO "Computing Z0 Using field VG with Look up Table"
         geophy subgrid_legacy GPXME GPXZVG GPXZ0 GPXLH GPXDH GPXY7 GPXY8 GPXY9 GenX::Settings
      }
   } else {
      Log::Print INFO "Will not calculate Z0, using default because ME field maximum value is $smax, subgrid field may not be available"
   }
   
   if { $GenX::Param(Z0Topo)=="LEGACY" } {
      Log::Print INFO "Saving legacy sub grid fields Z0 ZP"
      vexpr GPXZ0 ifelse(GPXZ0>$Const(z0def),GPXZ0,$Const(z0def) )
      vexpr GPXZP ifelse(GPXZ0>$Const(z0def),ln(GPXZ0),$Const(zpdef))

      #------ Filter roughness length
      if { $GenX::Param(Z0Filter) } {
         puts stderr [fstdfield is GPXZ0]
         geophy zfilter GPXZ0 GenX::Settings
      }

      fstdfield define GPXZ0 -NOMVAR Z0 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield define GPXZP -NOMVAR ZP -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXZP GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }
   if { $GenX::Param(Sub)=="LEGACY" } {
      Log::Print INFO "Saving legacy sub grid fields LH DH Y7 Y8 Y9"
      fstdfield define GPXLH -NOMVAR LH -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield define GPXDH -NOMVAR DH -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield define GPXY7 -NOMVAR Y7 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield define GPXY8 -NOMVAR Y8 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield define GPXY9 -NOMVAR Y9 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0

      fstdfield write GPXLH GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXDH GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXY7 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXY8 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      fstdfield write GPXY9 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   fstdfield free GPXVG GPXZVG2 GPXZ0 GPXZP GPXLH GPXDH GPXY7 GPXY8 GPXY9
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubLaunchingHeight>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Calculates the launching height.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubLaunchingHeight { } {
   variable Const

   GenX::Procs
   if { [catch {
      fstdfield read GPXMEL  GPXAUXFILE -1 "" -1 -1 -1 "" "MEL"
      fstdfield read GPXLRMS GPXAUXFILE -1 "" -1 -1 -1 "" "LRMS"
      fstdfield read GPXFLR  GPXAUXFILE -1 "" -1 -1 -1 "" "FLR"
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG" } ] } {
    
      Log::Print WARNING "Missing fields, will not calculate launching height"
      return
   }

   #----- Corrected fields (based on resolution criteria)
   vexpr GPXMEL  GPXMEL *GPXFLR
   vexpr GPXLRMS GPXLRMS*GPXFLR

   Log::Print INFO "Computing launching height LH"
   vexpr GPXLH 2.0*GPXMG*((GPXLRMS^2 - GPXMEL^2)^0.5)
   vexpr GPXLH ifelse(GPXLH>=$Const(lhmin),GPXLH,0.0)
   fstdfield define GPXLH -NOMVAR LH -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXLH GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXLH GPXMEL GPXLRMS GPXMG GPXFLR
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubLaunchingHeightSplit>
# Creation : Septembre 2007 - Ron McTaggart-Cowan and Ayrton Zadra - RPN
#
# Goal     : Calculates the launching height, decomposed into "short" and "long" length scales
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubLaunchingHeightSplit { } {
   variable Const

   GenX::Procs

   if { [catch {
      fstdfield read GPXMRMS GPXAUXFILE -1 "" -1 -1 -1 "" "MRMS"
      fstdfield read GPXMRES GPXAUXFILE -1 "" -1 -1 -1 "" "MRES"
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG" } ] } {
    
      Log::Print WARNING "Missing fields, will not separate subgrid variance"
      return
   }
   Log::Print INFO "Launching height using separated scales of subgrid variance"

   #----- Compute subgrid varaiance of database
   vexpr GPXVAR  max(GPXMRMS^2 - GPXME^2,0.0)

   #----- Compute scaling terms based on resolution ratios
   vexpr GPXDX ddx(GPXMG)
   vexpr GPXDY ddy(GPXMG)
   vexpr GPXDD sqrt(GPXDX*GPXDY)
   vexpr GPXWMB ((GPXMRES/GPXDD)^($GeoPhysX::Const(beta)-1))
   vexpr GPXWMS (min($GeoPhysX::Const(lres)/GPXDD,1.)^($GeoPhysX::Const(beta)-1))

   #----- Compute small-scale variance as a "launching height"
   vexpr GPX1_WMB  "1.-GPXWMB"
   vexpr GPXVARS ifelse(GPX1_WMB!=0.0,((GPXWMS) / (1.-GPXWMB))*GPXVAR,0.0)
   vexpr GPXSSS ifelse(GPXVARS>0.0,GPXMG*sqrt(GPXVARS),0.0)

   #----- Compute large-scale variance as a "launching height"
   vexpr GPXVARL ifelse(GPX1_WMB!=0.0,((1-GPXWMS) / (1.-GPXWMB))*GPXVAR,0.0)
   vexpr GPXLHL ifelse(GPXVARL>0.0,2.*GPXMG*sqrt(GPXVARL),0.0)

   #----- Write results to output files
   fstdfield define GPXSSS -NOMVAR SSS -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXSSS GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield define GPXLHL -NOMVAR LH -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXLHL GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Garbage collection
   fstdfield free GPX1_WMB GPXVARL GPXVARS GPXWMS GPXWMB GPXDD GPXDX GPXDY
   fstdfield free GPXMRMS GPXMRES GPXMG GPXSSS GPXLHL

}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubY789>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Calculates the Y789 fields.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubY789 { } {
   variable Const

   GenX::Procs

   #----- check for needed fields
   if { [catch {
      fstdfield read GPXGXX  GPXAUXFILE -1 "" -1 -1 -1 "" "GXX"
      fstdfield read GPXGYY  GPXAUXFILE -1 "" -1 -1 -1 "" "GYY"
      fstdfield read GPXGXY  GPXAUXFILE -1 "" -1 -1 -1 "" "GXY"
      fstdfield read GPXFLR  GPXAUXFILE -1 "" -1 -1 -1 "" "FLR"
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG"
      fstdfield read GPXLH   GPXOUTFILE -1 "" -1 -1 -1 "" "LH" } ] } {
    
      Log::Print WARNING "Missing fields, will not calculate Y789 fields"
      return
   }

   #----- Corrected fields (based on resolution criteria)
   vexpr GPXGXX GPXGXX*GPXFLR
   vexpr GPXGYY GPXGYY*GPXFLR
   vexpr GPXGXY GPXGXY*GPXFLR

   #----- Compute angle and angle factors
   vexpr GPXALP  (-dangle(GPXGXX))*3.14159265/180.
   vexpr GPXCOSA cos(GPXALP)
   vexpr GPXSINA sin(GPXALP)

   Log::Print INFO "Computing Y7"
   vexpr GPXY789 GPXMG*(GPXGXX*(GPXCOSA^2) + GPXGYY*(GPXSINA^2) - 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y7 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   Log::Print INFO "Computing Y8"
   vexpr GPXY789 GPXMG*(GPXGXX*(GPXSINA^2) + GPXGYY*(GPXCOSA^2) + 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y8 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   Log::Print INFO "Computing Y9"
   vexpr GPXY789 GPXMG*((GPXGXX-GPXGYY)*GPXSINA*GPXCOSA + GPXGXY*(GPXCOSA^2-GPXSINA^2))
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y9 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXGXX GPXGYY GPXGXY GPXMG GPXFLR GPXALP GPXCOSA GPXSINA GPXMG GPXLH GPXY789
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubY789Split>
# Creation : Fall 2016 - Ron McTaggart-Cowan and Ayrton Zadra - RPN
#
# Goal     : Calculates the Y789 fields.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubY789Split { } {
   variable Const

   GenX::Procs

   #----- check for needed fields
   if { [catch {
      fstdfield read GPXGXX  GPXAUXFILE -1 "" -1 -1 -1 "" "GXX"
      fstdfield read GPXGYY  GPXAUXFILE -1 "" -1 -1 -1 "" "GYY"
      fstdfield read GPXGXY  GPXAUXFILE -1 "" -1 -1 -1 "" "GXY"
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG"
      fstdfield read GPXMRES GPXAUXFILE -1 "" -1 -1 -1 "" "MRES"
      fstdfield read GPXLH   GPXOUTFILE -1 "" -1 -1 -1 "" "LH" } ] } {
    
      Log::Print WARNING "Missing fields, will not calculate Y789 fields"
      return
   }

   #----- Compute angle and angle factors
   vexpr GPXALP  (-dangle(GPXGXX))*3.14159265/180.
   vexpr GPXCOSA cos(GPXALP)
   vexpr GPXSINA sin(GPXALP)

   #----- Compute rescaling factor for length scale separation
   vexpr GPXDX ddx(GPXMG)
   vexpr GPXDY ddy(GPXMG)
   vexpr GPXDD sqrt(GPXDX*GPXDY)
   vexpr GPXRNUM (GPXDD/$GeoPhysX::Const(lres))^(3.-$GeoPhysX::Const(beta))-1.
   vexpr GPXRDENOM (GPXDD/max(GPXMRES,1.))^(3.-$GeoPhysX::Const(beta))-1.
   vexpr GPXR GPXRNUM / GPXRDENOM

   fstdfield define GPXR -NOMVAR R -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXR GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   Log::Print INFO "Computing Y7"
   vexpr GPXY789 GPXR*GPXMG*(GPXGXX*(GPXCOSA^2) + GPXGYY*(GPXSINA^2) - 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y7 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   Log::Print INFO "Computing Y8"
   vexpr GPXY789 GPXR*GPXMG*(GPXGXX*(GPXSINA^2) + GPXGYY*(GPXCOSA^2) + 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y8 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   Log::Print INFO "Computing Y9"
   vexpr GPXY789 GPXR*GPXMG*((GPXGXX-GPXGYY)*GPXSINA*GPXCOSA + GPXGXY*(GPXCOSA^2-GPXSINA^2))
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y9 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXGXX GPXGYY GPXGXY GPXMG GPXFLR GPXALP GPXCOSA GPXSINA GPXMG GPXLH GPXY789
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubRoughnessLength>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Calculates the roughness length.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::SubRoughnessLength { } {
   variable Param
   variable Const
   variable Opt

   GenX::Procs

   #----- check for needed fields
   if { [catch {
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1   -1 -1 "" "MG"
      fstdfield read GPXMRMS GPXAUXFILE -1 "" -1   -1 -1 "" "MRMS"
      fstdfield read GPXMF   GPXOUTFILE -1 "" -1   -1 -1 "" "MENF"
      if { $Opt(SubSplit) } {
         fstdfield read GPXSSS GPXOUTFILE -1 "" -1   -1 -1 "" "SSS"
      } else {
         fstdfield read GPXMEL  GPXAUXFILE -1 "" -1   -1 -1 "" "MEL"
         fstdfield read GPXLRMS GPXAUXFILE -1 "" -1   -1 -1 "" "LRMS"
         fstdfield read GPXFHR  GPXAUXFILE -1 "" -1   -1 -1 "" "FHR"
         fstdfield read GPXFLR  GPXAUXFILE -1 "" -1   -1 -1 "" "FLR"
      }
      fstdfield read GPXZ0V1 GPXOUTFILE -1 "" 1199 -1 -1 "" "VF" } ] } {
    
      Log::Print WARNING "Missing fields, will not calculate roughness length"
      return
   }
   
   if { !$Opt(SubSplit) } {
      Log::Print INFO "Computing subgrid-scale variance"
      vexpr GPXMF   GPXMF  *GPXFHR
      vexpr GPXMRMS GPXMRMS*GPXFHR
      vexpr GPXMEL  GPXMEL *GPXFLR
      vexpr GPXLRMS GPXLRMS*GPXFLR
      vexpr GPXSSS (GPXMRMS^2 - GPXMF^2)-(GPXLRMS^2 - GPXMEL^2)
      vexpr GPXSSS ifelse(GPXSSS>0.0,GPXSSS^0.5,0.0)
      vexpr GPXSSS ifelse(GPXMG>$Const(mgmin),GPXSSS,0.0)
      fstdfield define GPXSSS -NOMVAR SSS -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXSSS GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   vexpr GPXHCOEF (1.5 - 0.5*(GPXSSS-20.0)/680.0)
   vexpr GPXHCOEF ifelse(GPXSSS>700.0,1.0,GPXHCOEF)
    
   vexpr GPXZREF (GPXHCOEF*GPXSSS)
   vexpr GPXZREF ifelse(GPXZREF<$Const(zrefmin),$Const(zrefmin),GPXZREF)
   vexpr GPXZREF ifelse(GPXZREF>1500.0,1500.0,GPXZREF)
    
   fstdfield define GPXZREF -NOMVAR ZREF -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXZREF GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
    
   vexpr GPXSLP (GPXHCOEF*GPXHCOEF*GPXSSS/$Const(lres))
    
   Log::Print INFO "Computing Z0_topo"
   vexpr GPXZTP ifelse(GPXSLP>$Const(slpmin) || GPXZREF>$Const(zrefmin),1.0+GPXZREF*exp(-$Const(karman)/sqrt(0.5*$Const(drgcoef)*GPXSLP)),0.0)
   vexpr GPXZTP ifelse(GPXSSS<=$Const(sssmin),0.1*GPXSSS,GPXZTP)
   fstdfield define GPXZTP -NOMVAR ZTOP -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXZTP GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Local (vegetation) roughness length
   fstdfield read GPXZ0V1 GPXOUTFILE -1 "" 1199 -1 -1 "" "VF"
   fstdfield copy GPXZ0V2 GPXZ0V1
   GenX::GridClear { GPXZ0V1 GPXZ0V2 } 0.0

   foreach element $Param(VegeTypes) zzov $Param(VegeZ0vTypes) {
      set ip1 [expr 1200-$element]
      fstdfield read GPXVF GPXOUTFILE -1 "" $ip1 -1 -1 "" "VF"

      vexpr GPXZ0V1 (GPXZ0V1+GPXVF*$zzov)
      vexpr GPXZ0V2 (GPXZ0V2+GPXVF)
   }
   vexpr GPXZ0V1 ifelse(GPXZ0V2>0.001,GPXZ0V1/GPXZ0V2,0.0)
   fstdfield define GPXZ0V1 -NOMVAR ZVG1 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXZ0V1 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   GenX::GridClear { GPXZ0V1 GPXZ0V2 } 0.0
   foreach element [lrange $Param(VegeTypes) 3 end] zzov [lrange $Param(VegeZ0vTypes) 3 end] {
      set ip1 [expr 1200-$element]
      fstdfield read GPXVF GPXOUTFILE -1 "" $ip1 -1 -1 "" "VF"
      vexpr GPXZ0V1 (GPXZ0V1+GPXVF*$zzov)
      vexpr GPXZ0V2 (GPXZ0V2+GPXVF)
   }

   Log::Print INFO "Computing Z0V1 (save as ZVG2) using Lookup Table VegeZ0vTypes : $Param(VegeZ0vTypes)"
   vexpr GPXZ0V1 ifelse(GPXZ0V2>0.001,GPXZ0V1/GPXZ0V2,0.0)
   fstdfield define GPXZ0V1 -NOMVAR ZVG2 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
   fstdfield write GPXZ0V1 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Local (vegetation) roughness length from canopy height  
   if { $GenX::Param(Z0NoTopo) == "CANOPY" } {
      if { [catch { fstdfield read GPXVCH  GPXAUXFILE -1 "" -1 -1 -1 "" "VCH" }] } {
         Log::Print WARNING "Missing fields, will not calculate roughness length from canopy height"
         return
      }
      vexpr GPXZ0VG ifelse(GPXMG>0.0,max(GPXVCH*0.1,$Const(z0minUr)),0.0)
      fstdfield define GPXZ0VG -NOMVAR Z0VG -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0VG GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

      #------ roughness length without topographic contribution and Z0VG
      Log::Print INFO "Generating Z0 without topographic contribution from canopy height"
      #------ because vegetation height where crop are dominant are too low (zero)
      #------ compensate with crop's Z0 using lookup table
      if { $GenX::Param(CropZ0) > 0.0 } {
         if { $GenX::Param(Vege) == "CCILC2015-ECO2017" } { 
            set Param(VegeCrops)    { 15 16 17 20 }
         }

         fstdfield copy GPXZ0CROP GPXZ0V1
         fstdfield copy GPXVFCROP GPXZ0V1
         GenX::GridClear { GPXZ0CROP GPXVFCROP } 0.0
         foreach element $Param(VegeTypes) zzov $Param(VegeZ0vTypes)  {
            set ip1 [expr 1200-$element]
            if { [lsearch $Param(VegeCrops) $element]!=-1 } {
               fstdfield read GPXVF GPXOUTFILE -1 "" $ip1 -1 -1 "" "VF"
               vexpr GPXZ0CROP (GPXZ0CROP+GPXVF*$zzov)
               vexpr GPXVFCROP (GPXVFCROP+GPXVF)
            }
         }
         vexpr GPXZ0  "ifelse(GPXVFCROP > $GenX::Param(CropZ0),GPXZ0CROP,GPXZ0VG)"
         vexpr GPXZ0  "max(GPXZ0,$Const(waz0))"
         fstdfield free GPXZ0CROP GPXVFCROP
      } else {
         vexpr GPXZ0  "max(GPXZ0VG,$Const(waz0))"
      }
      fstdfield define GPXZ0 -NOMVAR Z0 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   	 
      vexpr GPXZP  ifelse(GPXZ0>$Const(z0def),ln(GPXZ0),$Const(zpdef))
      fstdfield define GPXZP -NOMVAR ZP -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZP GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   } elseif { ($GenX::Param(Z0NoTopo) == "CANOPY_LT") || ($GenX::Param(TOPO_ZVG2_TYPE) == "CANOPY_LT") } {
      Log::Print INFO "Computing Local Vegetation Roughness"
      if { [catch { fstdfield read GPXZ0VH  GPXAUXFILE -1 "" -1 -1 -1 "" "Z0VH" }] } {
         Log::Print WARNING "Missing fields, will not calculate local roughness length from canopy height"
         return
      }

      switch $GenX::Param(Vege) {
         "CCILC2015-ECO2017"    { 
         set VegeTree  $Param(VegeTree_Eco)
         set Z0M_VegeZ0  $Param(Z0M_VegeZ0_Eco)
         }
         "CCILC2015-WE"    { 
         set VegeTree  $Param(VegeTree)
         set Z0M_VegeZ0  $Param(Z0M_VegeZ0_CCILCWE)
         }
      default {
         set VegeTree  $Param(VegeTree)
         set Z0M_VegeZ0  $Param(Z0M_VegeZ0)
         }
      }

      fstdfield copy GPXZ0V3 GPXZ0VH
      fstdfield copy GPXVFT GPXZ0VH
      GenX::GridClear { GPXZ0V1 GPXZ0V2 GPXZ0V3 GPXVFT } 0.0
      foreach element $Param(VegeTypes) zomv $Z0M_VegeZ0  {
         Log::Print DEBUG "  Processing LN(Z0) with VF $element"
         set ip1 [expr 1200-$element]
         fstdfield read GPXVF GPXOUTFILE -1 "" $ip1 -1 -1 "" "VF"
         if { [lsearch $VegeTree $element]!=-1 } {
            # remplace LN(Z0) from VF and LUT with Z0VH if available
            Log::Print DEBUG "Using Tree Height for VF=$element"
            vexpr GPXZ0V1 ifelse(GPXZ0VH>0.0,GPXZ0V1+GPXVF*ln(GPXZ0VH),GPXZ0V1+GPXVF*ln($zomv))
            vexpr GPXVFT (GPXVFT+GPXVF)
         } else {
            if { $element >= 4 } {
               Log::Print DEBUG "Using LUT only for VF=$element"
               vexpr GPXZ0V1 (GPXZ0V1+GPXVF*ln($zomv))
               vexpr GPXVFT (GPXVFT+GPXVF)
            } else {
               vexpr GPXZ0V2 (GPXZ0V2+GPXVF*ln($zomv))
            }
         }
      }
      vexpr GPXZ0V3 (GPXZ0V1+GPXZ0V2)
      # z0v1 is used for Z0 for land/vegetation+glacier only (VF=4,26)
      vexpr GPXZ0V1 ifelse(GPXVFT>0.0,GPXZ0V1/GPXVFT,ln($Const(waz0)))

      fstdfield define GPXZ0V1 -NOMVAR ZPVG -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0V1 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      vexpr GPXZ0V1   exp(GPXZ0V1)
      fstdfield define GPXZ0V1 -NOMVAR Z0VG -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0V1 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

      # z0v3 is used for Z0 for all surface types ... VF=1,26 -- No need to divide by Vfs as sum=1.0

      fstdfield define GPXZ0V3 -NOMVAR ZPLC -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0V3 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
      vexpr GPXZ0V3   exp(GPXZ0V3)
      fstdfield define GPXZ0V3 -NOMVAR Z0LC -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0V3 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   } elseif { $GenX::Param(Z0NoTopo) == "STD" } {
      Log::Print INFO "Generating Z0 without topographic contribution from vegetation type"
      vexpr GPXZ0  "max(GPXZ0V1,$Const(waz0))"
      fstdfield define GPXZ0 -NOMVAR Z0 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZ0 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

      vexpr GPXZP ifelse(GPXZ0>$Const(z0def),ln(GPXZ0),$Const(zpdef))
      fstdfield define GPXZP -NOMVAR ZP -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
      fstdfield write GPXZP GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   } 

   if { ($GenX::Param(Z0NoTopo) == "") && ($GenX::Param(Z0Topo) == "STD") } {
       #------ roughness length with topographic contribution and lookup table
       #------ Filter roughness length

       #----- Roughness length over soil
       fstdfield read GPXGA GPXOUTFILE -1 "" 1198 -1 -1 "" "VF"
       
       vexpr GPXW1  ifelse(GPXZTP >0.0 && GPXZREF>GPXZTP     , (1.0/ln(GPXZREF/GPXZTP ))^2.0        , 0.0)
       vexpr GPXW2  ifelse(GPXZ0V1>0.0 && GPXZREF>GPXZ0V1    , (1.0/ln(GPXZREF/GPXZ0V1))^2.0        , 0.0)
       vexpr GPXZ0S ifelse((GPXW1+GPXW2)>0.0                 , GPXZREF*exp( -1.0/sqrt(GPXW1+GPXW2)) , 0.0)
       vexpr GPXZ0S ifelse(GPXZREF<=$Const(zrefmin)          , GPXZ0V1                              , GPXZ0S)
       vexpr GPXZ0S ifelse(GPXZ0S<$Const(z0def)              , $Const(z0def)                        , GPXZ0S)
       vexpr GPXZ0S ifelse(GPXGA>=(1.0-$Const(gamin))        , $Const(z0def)                        , GPXZ0S)
       fstdfield define GPXZ0S -NOMVAR Z0S -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZ0S GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
       
       vexpr GPXZPS ifelse(GPXZ0S>0.0,ln(GPXZ0S),$Const(zpdef))
       fstdfield define GPXZPS -NOMVAR ZPS -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZPS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
       
       #----- Roughness length over glaciers
       vexpr GPXW1  ifelse(GPXZTP>0.0 && GPXZREF>GPXZTP, (1.0/ln(GPXZREF/GPXZTP      ))^2.0 , 0.0)
       vexpr GPXW2  ifelse(GPXZREF>$Const(gaz0)        , (1.0/ln(GPXZREF/$Const(gaz0)))^2.0 , 0.0)
       vexpr GPXZ0G ifelse((GPXW1+GPXW2)>0.0           , GPXZREF*exp(-1.0/sqrt(GPXW1+GPXW2)), 0.0)
       vexpr GPXZ0G ifelse(GPXZREF<=$Const(zrefmin)    , $Const(gaz0)                       , GPXZ0G)
       vexpr GPXZ0G ifelse(GPXZ0G<$Const(z0def)        , $Const(z0def)                      , GPXZ0G)
       vexpr GPXZ0G ifelse(GPXGA<=$Const(gamin)        , $Const(z0def)                      , GPXZ0G)
       fstdfield define GPXZ0G -NOMVAR Z0G -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZ0G GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

       vexpr GPXZPG ifelse(GPXZ0G>0.0,ln(GPXZ0G),$Const(zpdef) )
       fstdfield define GPXZPG -NOMVAR ZPG -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZPG GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

       #----- Roughness length over water
       vexpr GPXW1  ifelse(GPXZTP>0.0 && GPXZREF>GPXZTP, (1.0/ln(GPXZREF/GPXZTP      ))^2.0 , 0.0)
       vexpr GPXW2  ifelse(GPXZREF>0.001               , (1.0/ln(GPXZREF/0.001))^2.0        , 0.0)
       vexpr GPXZ0W ifelse((GPXW1+GPXW2)>0.0           , GPXZREF*exp(-1.0/sqrt(GPXW1+GPXW2)), 0.0)
       vexpr GPXZ0W ifelse(GPXZREF<=$Const(zrefmin)    , 0.001                              , GPXZ0W)
       vexpr GPXZ0W ifelse(GPXZ0W<$Const(z0def)        , $Const(z0def)                      , GPXZ0W)
       vexpr GPXZ0W ifelse((1.0-GPXMG)<=$Const(mgmin)  , $Const(z0def)                      , GPXZ0W)
       fstdfield define GPXZ0W -NOMVAR Z0W -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZ0W GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

       vexpr GPXZPW ifelse(GPXZ0W>0.0,ln(GPXZ0W),$Const(zpdef) )
       fstdfield define GPXZPW -NOMVAR ZPW -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZPW GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

       #----- Fill some gaps
       vexpr GPXZ0S ifelse(GPXMG>$Const(mgmin) && GPXZTP<$Const(z0min) && GPXZ0V1<$Const(z0min) && GPXZ0G<$Const(z0min),$Const(z0def),GPXZ0S)
       fstdfield define GPXZ0S -NOMVAR Z0S -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZ0S GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
       vexpr GPXZPS ifelse(GPXZ0S>0.0,ln(GPXZ0S),$Const(zpdef) )
       fstdfield define GPXZPS -NOMVAR ZPS -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZPS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

       #----- Total roughness length
       GeoPhysX::Compute_GA GPXGA GPXGA
       vexpr GPXZP GPXMG*((1.0-GPXGA)*GPXZPS+GPXGA*GPXZPG)+(1.0-GPXMG)*GPXZPW

       fstdfield define GPXZP -NOMVAR ZP0 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZP GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

       vexpr GPXZ0 exp(GPXZP)
       fstdfield define GPXZ0 -NOMVAR Z00 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZ0 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

       Log::Print INFO "Generating Z0 with topographic contribution"
       if { $GenX::Param(Z0Filter) } {
           Log::Print INFO "Filtering Z0"
           geophy zfilter GPXZ0 GenX::Settings
       }
       vexpr GPXZ0 ifelse(GPXZ0>$Const(z0def),GPXZ0,$Const(z0def) )
       fstdfield define GPXZ0 -NOMVAR Z0 -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZ0 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   
       vexpr GPXZP ifelse(GPXZ0>$Const(z0def),ln(GPXZ0),$Const(zpdef))
       fstdfield define GPXZP -NOMVAR ZP -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0
       fstdfield write GPXZP GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   } elseif { ($GenX::Param(Z0NoTopo) == "") && ($GenX::Param(Z0Topo) == "LEGACY") } {
       # nothing to do here, Z0 will be calculated in GeoPhysX::LegacySub
   } elseif { $GenX::Param(Z0NoTopo) == "CANOPY_LT" } {
   } else {
       Log::Print WARNING "Invalid Z0 option(s) provided"
       Log::Print WARNING "   GenX::Param(Z0NoTopo)=$GenX::Param(Z0NoTopo)"
       Log::Print WARNING "   GenX::Param(Z0Topo)  =$GenX::Param(Z0Topo)"
   }

   fstdfield free GPXLH GPXSSS GPXHCOEF GPXZREF GPXSLP GPXZTP GPXZ0S GPXZ0W GPXZPW \
       GPXZ0V2 GPXZ0VG GPXZPS GPXGA GPXZ0G GPXZPG GPXZ0 GPXZ0V1 GPXZ0V2 GPXZP GPXMG GPXVF GPXVCH
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::CheckMaskVegeConsistency
# Creation : May 2018 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Make sure mask and Vege is consistent
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::CheckMaskVegeConsistency {} {

   GenX::Procs
   Log::Print INFO "Applying Mask versus Vege consistency checks"

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GRDMG GPXOUTFILE $idx
      set has_MG  1
   } else {
      Log::Print INFO "Could not find mask field MG, will create it using VF1 and VF3"
      set has_MG  0
   }

   #----- Read Urban VF(21)
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" 1179 -1 -1 "" "VF"]]] } {
      fstdfield read GRDVF21 GPXOUTFILE $idx
   } elseif { [llength [set idx [fstdfield find GPXAUXFILE -1 "" 1179 -1 -1 "" "VF"]]] } {
      fstdfield read GRDVF21 GPXAUXFILE $idx
   } else {
      Log::Print WARNING "Could not find water field VF(21)"
      return
   }

   #----- Read water coverage VF(3)
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" 1197 -1 -1 "" "VF"]]] } {
      Log::Print INFO "Reading VF3 from GPXOUTFILE"
      fstdfield read GRDVF3 GPXOUTFILE $idx
   } elseif { [llength [set idx [fstdfield find GPXAUXFILE -1 "" 1197 -1 -1 "" "VF"]]] } {
      Log::Print INFO "Reading VF3 from GPXAUXFILE"
      fstdfield read GRDVF3 GPXAUXFILE $idx
   } else {
      Log::Print WARNING "Could not find water field VF(3)"
      return
   }

   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" 1199 -1 -1 "" "VF"]]] } {
      Log::Print INFO "Reading VF1 from GPXOUTFILE"
      fstdfield read GRDVF1 GPXOUTFILE $idx
   } elseif { [llength [set idx [fstdfield find GPXAUXFILE -1 "" 1199 -1 -1 "" "VF"]]] } {
      Log::Print INFO "Reading VF1 from GPXAUXFILE"
      fstdfield read GRDVF1 GPXAUXFILE $idx
   } else {
      Log::Print WARNING "Could not find water field VF(1)"
      return
   }

   set max  [lindex [fstdfield stats GRDVF1 -max] 0]
   set has_SaltWater  [expr $max > 0.9]

# Obtain VF3 from MG and VF1 if any
   if {$has_MG} {
      vexpr WATER "1.0-GRDMG"
      if { $has_SaltWater } {
         vexpr GRDVF1 "ifelse(GRDVF1>=WATER,WATER,GRDVF1)"
         vexpr GRDVF3 "1.0-GRDVF1-GRDMG"
      } else {
         vexpr GRDVF3 "ifelse(GRDVF3>=WATER,WATER,GRDVF3)"
         if { $max > 0.0 } {
            vexpr GRDVF1 "1.0-GRDVF3-GRDMG"
         }
      }
   } else {
      vexpr GRDMG "1.0-GRDVF3-GRDVF1"
      fstdfield define GRDMG -NOMVAR MG -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GRDMG GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      Log::Print INFO "Since MG is created from VF1 and VF3, no need to rebalance VF fields"
      fstdfield free GRDVF3 GRDVF1 GRDMG WATER
      return
   }

   vexpr VFfixed "GRDVF1+GRDVF3+GRDVF21"
   vexpr VFT     "GRDVF1+GRDVF3"

# make sure fixed part is under 1.0
   vexpr GRDVF21 "ifelse(VFfixed<=1.0,GRDVF21,1.0-VFT)"
   vexpr VFfixed "GRDVF1+GRDVF3+GRDVF21"

# now we have to balance remaining VF

   fstdfield copy SUM_VF GRDMG
   fstdfield stats SUM_VF -nodata 0
   fstdfield clear SUM_VF

   # compute temporary VG field here just for use by filler
   fstdfield copy GPXVG GRDMG
   fstdfield copy GPXTP GRDMG
   GenX::GridClear [list GPXVG GPXTP] 0.0

   set kks    { 2 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 22 23 24 25 26 }
   foreach  kk  $kks {
      set  ip1  [expr 1200-$kk]
      fstdfield read VF${kk}FLD   GPXAUXFILE   -1 "" $ip1 -1 -1 "" "VF"
      vexpr GPXVG ifelse(GPXTP>=VF${kk}FLD,GPXVG,$kk)
      vexpr GPXTP ifelse(GPXTP>=VF${kk}FLD,GPXTP,VF${kk}FLD)
      vexpr  SUM_VF  "SUM_VF + VF${kk}FLD"
   }

   vexpr SUM_VF  "SUM_VF + GRDVF21"
   vexpr FILLER "ifelse(SUM_VF<GRDMG,GRDMG-SUM_VF,0.0)"
# either use VF24 and VF25 as filler or try searching for nearest VF type

   # VG is better compared as Integer
   #
   vexpr (Byte)GPXVGI  "round(GPXVG)"
   set  ni  [fstdfield define GPXVG -NI]
   set  nj  [fstdfield define GPXVG -NJ]
   set  thresm  0.0001

   for { set j 0 } { $j < $nj } { incr j } {
      for { set i 0 } { $i < $ni } { incr i } {
         set svf  [fstdfield stats SUM_VF -gridvalue $i $j]
         set val  [fstdfield stats FILLER -gridvalue $i $j]
         if { $val > 0.0 && $svf < $thresm } {
# replace filler when possible with nearest vg
            set vg [expr int([Fetch_Grid_Nearest GPXVGI $i $j])]
            if { $vg > 0 } {
               if { [fstdfield is VF${vg}FLD] } {
                  fstdfield stats FILLER -gridvalue $i $j 0.0
                  set val0 [fstdfield stats VF${vg}FLD -gridvalue $i $j]
                  set val1 [expr $val0 + $val]
                  fstdfield stats VF${vg}FLD -gridvalue $i $j $val1
               } else {
                  Log::Print WARNING "cannot replace filler, VG=$vg and VF${vg}FLD not exist"
               }
            }
         }
      }
   }

   vexpr VF24FLD  "VF24FLD + FILLER*0.5"
   vexpr VF25FLD  "VF25FLD + FILLER*0.5"
   vexpr  SUM_VF  "SUM_VF + VFT + FILLER"

   vexpr  VFA  "1 - VFfixed"
   vexpr  VFT  "SUM_VF - VFfixed"

   vexpr  SUM_VF2  "VFfixed"
   foreach  kk  $kks {
      vexpr PPVF  "ifelse(VFT==0,0.0,VF${kk}FLD*VFA/VFT)"
      vexpr SUM_VF2  "SUM_VF2 + PPVF"
      Log::Print INFO "Overwriting VF$kk"
      fstdfield define PPVF -IP1 [expr 1200-$kk] -NOMVAR VF
      fstdfield write PPVF  GPXAUXFILE -32 True
      fstdfield free VF${kk}FLD
   }

   fstdfield define SUM_VF2 -NOMVAR SMVF -IP1 0
   fstdfield write SUM_VF2  GPXAUXFILE -32 True

   fstdfield define GRDVF21 -NOMVAR VF -IP1 1179
   fstdfield write GRDVF21  GPXAUXFILE -32 True

   Log::Print INFO "Overwriting VF3"
   fstdfield define GRDVF3 -NOMVAR VF -IP1 1197
   fstdfield write GRDVF3  GPXAUXFILE -32 True

   Log::Print INFO "Overwriting VF1"
   fstdfield define GRDVF1 -NOMVAR VF -IP1 1199
   fstdfield write GRDVF1  GPXAUXFILE -32 True

   fstdfield define GRDMG -NOMVAR MG -IP1 0
   fstdfield write GRDMG  GPXAUXFILE -32 True

   fstdfield free GRDVF3 GRDVF1 GRDMG GPXVF GPXVGI
   fstdfield free SUM_VF SUM_VF2 VFA VFT WATER
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::CheckConsistencyStandard>
# Creation : Octobre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Do consistncy checks.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::CheckConsistencyStandard { } {
   variable Param

   GenX::Procs
   Log::Print INFO "Applying consistency checks"

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
   } else {
      Log::Print WARNING "Could not find mask field MG"
   }

   #----- Read ice coverage VF(2)
   if { [llength [set idx [fstdfield find GPXAUXFILE -1 "" 1198 -1 -1 "" "VF"]]] } {
      fstdfield read GPXVF2 GPXAUXFILE $idx
   } else {
      Log::Print WARNING "Could not find ice field VF(2)"
   }

   #----- Read water coverage VF(3)
   if { [llength [set idx [fstdfield find GPXAUXFILE -1 "" 1197 -1 -1 "" "VF"]]] } {
      fstdfield read GPXVF3 GPXAUXFILE $idx
   } else {
      Log::Print WARNING "Could not find water field VF(3)"
   }

   #----- Check consistency for VF
   foreach type $Param(VegeTypes) {
      if { ![catch { fstdfield read GPXVF GPXAUXFILE -1 "" [expr 1200-$type] -1 -1 "" "VF" }] } {
         if { [fstdfield is GPXVF3] && [fstdfield is GPXMG] } {
            if { $type==1 } {
               vexpr GPXVF ifelse(GPXMG==0.0 && GPXVF3==0.0,1.0,GPXVF)
            } else {
               vexpr GPXVF ifelse(GPXMG==0.0 && GPXVF3==0.0,0.0,GPXVF)
            }
         } else {
            Log::Print WARNING "Could not find VF(3) and/or MG field(s), will not do the consistency check on VF($type)"
            break
         }
         fstdfield define GPXVF -NOMVAR VF -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
         fstdfield write GPXVF GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      } else {
         Log::Print WARNING "Could not find VF($type) field while checking VF"
         break
      }
   }

   if { [fstdfield is GPXVF2] } {
      GeoPhysX::Compute_GA GPXGA GPXVF2
      fstdfield define GPXGA -NOMVAR GA -ETIKET $GenX::Param(ETIKET) -IP1 0 -DATYP $GenX::Param(Datyp)
      fstdfield write GPXGA GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

      #----- Calculate Dominant type and save
      GeoPhysX::DominantVege GPXVF2
   } else {
      Log::Print WARNING "Could not find VF(2), will not write GA field and calculate dominant vegetation"
   }

   #----- Check consistency for J1 and J2
   foreach type $Param(SandTypes) {
      if { ![catch { fstdfield read GPXJ1 GPXAUXFILE -1 "" [expr 1200-$type] -1 -1 "" "J1" }] } {
         if { [fstdfield is GPXVF2] } {
            vexpr GPXJ1 ifelse(GPXVF2==1.0,43.0,GPXJ1)
         } else {
            Log::Print WARNING "Could not find VF(2) field, will not do the consistency check between VF(2) and J1"
            break
         }
         if { [fstdfield is GPXMG] } {
            vexpr GPXJ1 ifelse(GPXMG<0.001,0.0,ifelse(GPXJ1==0.0,43.0,GPXJ1))
         } else {
            Log::Print WARNING "Could not find MG field, will not do the consistency check between MG and J1"
         }
         fstdfield define GPXJ1 -NOMVAR J1 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
         fstdfield write GPXJ1 GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      } else {
         Log::Print WARNING "Could not find J1($type) field, will not do the consistency check on J1($type)"
      }
   }

   foreach type $Param(ClayTypes) {
      if { ![catch { fstdfield read GPXJ2 GPXAUXFILE -1 "" [expr 1200-$type] -1 -1 "" "J2" }] } {
         if { [fstdfield is GPXVF2] } {
            vexpr GPXJ2 ifelse(GPXVF2==1.0,19.0,GPXJ2)
         } else {
            Log::Print WARNING "Could not find VF(2) field, will not do the consistency check between VF(2) and J2"
            break
         }
         if { [fstdfield is GPXMG] } {
            vexpr GPXJ2 ifelse(GPXMG<0.001,0.0,ifelse(GPXJ2==0.0,19.0,GPXJ2))
         } else {
            Log::Print WARNING "Could not find MG field, will not do the consistency check between MG and J2"
            break
         }
         fstdfield define GPXJ2 -NOMVAR J2 -ETIKET $GenX::Param(ETIKET) -IP1 [expr 1200-$type] -DATYP $GenX::Param(Datyp)
         fstdfield write GPXJ2 GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)
      } else {
         Log::Print WARNING "Could not find J2($type) field, will not do the consistency check on J2($type)"
      }
   }

   fstdfield free GPXJ1 GPXJ2 GPXMG GPXVF GPXVF2 GPXVF3 GPXGA
}

#----------------------------------------------------------------------------
# Name     : CheckLegacyVG
# Creation : January 2016 - V. Souvanlasy - CMC/CMDS
#
# Goal     : ASSURE LA CONSISTANCE
#            ENTRE LA TOPOGRAPHIE ET LE MASQUE TERRE-MER
#            EN MODIFIANT VG
#
# Parameters :
#
# Return:
#
# Remarks :
#    extrait de conseq.f de genesis. 
#
#----------------------------------------------------------------------------
proc GeoPhysX::CheckLegacyVG { } {
   variable Opt

   GenX::Procs
   Log::Print INFO "Applying Legacy consistency checks on ME, MG and VG "
   #----- Check consistency for ME
   #----- Read ME
   if { [catch {
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG"
      fstdfield read GPXVG   GPXOUTFILE -1 "" -1 -1 -1 "" "VG" } ] } {
      Log::Print WARNING "Missing fields, will not check ME consistency with MG"
      return
   }

   # this is what make difference between released version and current dev version
   if { $Opt(LinearNodata) } {
      fstdfield stats GPXME -nodata 0
      fstdfield  configure GPXME  -rendertexture 0 -interpdegree LINEAR
   }


   # VG is better compared as Integer
   #
   vexpr (Byte)GPXVGI  "round(GPXVG)"
   set  ni  [fstdfield define GPXVG -NI]
   set  nj  [fstdfield define GPXVG -NJ]
   set  thresm  0.001

   for { set j 0 } { $j < $nj } { incr j } {
      for { set i 0 } { $i < $ni } { incr i } {
         set val_me  [fstdfield stats GPXME -gridvalue $i $j]
         set val_mg  [fstdfield stats GPXMG -gridvalue $i $j]
         set val_vg  [fstdfield stats GPXVGI -gridvalue $i $j]
         if { ($val_me >= 0.0)&&($val_mg >= $thresm) } {
            if { $val_vg == 1 || $val_vg == 3 } { # is Water
               set val_vg [expr int([Fetch_Grid_Nearest GPXVGI $i $j])]
               if { $val_vg > 0 } {
                  fstdfield stats GPXVG -gridvalue $i $j $val_vg
               }
            }
         }
         if { ($val_me == 0.0)&&($val_mg < $thresm) } {
           if { $val_vg != 1 && $val_vg != 2 } { # is Not Sea or Not Ice
               fstdfield stats GPXVG -gridvalue $i $j 1
           }
         }
      }
   }

#   rewrite VG
   fstdfield write GPXVG GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   fstdfield free GPXVG GPXMG
}

#----------------------------------------------------------------------------
# Name     : Fetch_Grid_Nearest
# Creation : January 2016 - V. Souvanlasy - CMC/CMDS
#
# Goal     : chercher dans le voisinage d'un PG la vegetation
#            la plus pres 
#
# Parameters :
#   <Grid>  : la tuile source
#   <i, j>  : position initiale
#
# Return:
#
# Remarks :
#    L'algorithme de la recherche de vegetation dans le voisinage 
#    est extrait de conseq.f de genesis. 
#
#----------------------------------------------------------------------------
proc  GeoPhysX::Fetch_Grid_Nearest { Grid i j } {

   set  ni  [fstdfield define $Grid -NI]
   set  nj  [fstdfield define $Grid -NJ]

   set ninj [expr $ni + $nj]

   for { set k 1 } { $k < $ninj } { incr k } {
      set n0 [expr $j-$k]
      if { $n0 < 0 } { set n0 0 }
      set n1 [expr $j+$k]
      if { $n1 >= $nj } { set n1 [expr $nj-1] }
      set  i1 [expr $i-$k]
      set  i2 [expr $i+$k]
      if { $i1 >= 0 } {
         for { set n $n0 } { $n <= $n1 } {incr n } {
            set val  [fstdfield stats $Grid -gridvalue $i1 $n]
            if { $val != 1 && $val != 3 } {
               return $val
            }
         }
      }
      if { $i2 < $ni } {
         for { set n $n0 } { $n <= $n1 } {incr n } {
            set val  [fstdfield stats $Grid -gridvalue $i2 $n]
            if { $val != 1 && $val != 3 } {
               return $val
            }
         }
      }

      set m0 [expr $i-$k]
      if { $m0 < 0 } { set m0 0 }
      set m1 [expr $i+$k]
      if { $m1 >= $ni } { set m1 [expr $ni-1] }
      set  j1 [expr $j-$k]
      set  j2 [expr $j+$k]
      if { $j1 >= 0 } {
         for { set m $m0 } { $m <= $m1 } {incr m } {
            set val  [fstdfield stats $Grid -gridvalue $m $j1]
            if { $val != 1 && $val != 3 } {
               return $val
            }
         }
      } 
      if { $j2 < $nj } {
         for { set m $m0 } { $m <= $m1 } {incr m } {
            set val  [fstdfield stats $Grid -gridvalue $m $j2]
            if { $val != 1 && $val != 3 } {
               return $val
            }
         }
      }
   }
   return -1
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::Compute_GA>
# Creation : Aout 2011 - Nathalie Gauthier/Vahn Souvanlasy -
#
# Goal     : Calculates GA
#
# Parameters   :
#
#    <GPXGA>   : result field containing GA
#    <VF2>     : VF2 input field
#
# Return:
#
# Remarks : GA is glacier fraction relative to continental surface only
#
#    GA =  VF2 / SUM(VF 4..26 + VF2)
#
#----------------------------------------------------------------------------
proc GeoPhysX::Compute_GA  { GPXGA VF2 } {
   variable Param

   fstdfield copy  SUMVF4_26 $VF2
   GenX::GridClear SUMVF4_26 0.0

   foreach type [lrange $Param(VegeTypes) 3 end] {
      if { ![catch { fstdfield read GPXVF GPXOUTFILE -1 "" [expr 1200-$type] -1 -1 "" "VF" }] } {
         vexpr SUMVF4_26  SUMVF4_26+GPXVF
      } else {
         Log::Print WARNING "Could not find VF($type) field while processing VG"
      }
   }

   vexpr SUMVFGA  SUMVF4_26+$VF2
   vexpr $GPXGA ifelse(SUMVFGA>0.001,($VF2/SUMVFGA),0.0)
   fstdfield free SUMVFGA SUMVF4_26
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::DominantVege>
# Creation : Decembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Caclulates the dominant vege type and saves every vege fields.
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::DominantVege { Grid } {
   variable Param

   GenX::Procs
   Log::Print INFO "Calculating dominant vegetation"

   fstdfield copy GPXVG $Grid
   fstdfield copy GPXTP $Grid
   GenX::GridClear [list GPXVG GPXTP] 0.0

   #----- Generate VG field (Dominant type per cell)
   foreach type $Param(VegeTypes) {
      if { ![catch { fstdfield read GPXVF GPXOUTFILE -1 "" [expr 1200-$type] -1 -1 "" "VF" }] } {
         vexpr GPXVG ifelse(GPXTP>=GPXVF,GPXVG,$type)
         vexpr GPXTP ifelse(GPXTP>=GPXVF,GPXTP,GPXVF)
      } else {
         Log::Print WARNING "Could not find VF($type) field while processing VG"
      }
   }
   fstdfield define GPXVG -NOMVAR VG -ETIKET $GenX::Param(ETIKET) -IP1 0 -IP2 0 -DATYP $GenX::Param(Datyp)
   fstdfield write GPXVG GPXOUTFILE -$GenX::Param(CappedNBits) True $GenX::Param(Compress)

   fstdfield free GPXVF GPXVG GPXTP
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::Diag>
# Creation : Octobre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Caclculates diagnostics.
#
# Parameters   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::Diag { } {

   GenX::Procs

   Log::Print INFO "(TODO)" 0
}
