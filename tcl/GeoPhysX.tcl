#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : GeoPhysX.tcl
# Creation   : September 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Revision   : $Id$
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
#   GeoPhysX::AverageMaskUSGS      { Grid }
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
#   GeoPhysX::SubY789              { }
#   GeoPhysX::SubRoughnessLength   { }
#
#   GeoPhysX::CheckConsistencyStandard { }
#   GeoPhysX::Diag                     { }
#============================================================================

namespace eval GeoPhysX { } {
   variable Param
   variable Const
   global env

   set Param(Version)   1.2

   #----- Specific data information

   set Param(SandTypes)    { 1 2 3 4 5 }
   set Param(ClayTypes)    { 1 2 3 4 5 }
   set Param(VegeTypes)    { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 }
   set Param(VegeZ0vTypes) { 0.001 0.0003 0.001 1.5 3.5 1.0 2.0 3.0 0.8 0.05 0.15 0.15 0.02
                            0.08 0.08 0.08 0.35 0.25 0.1 0.08 1.35 0.01 0.05 0.05 1.5 0.05 }

   #----- Constants definitions

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
   set Const(gaz0)    0.0003      ;# Roughness length for glacier-type surfaces
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

   #----- Correspondance de St�phane B�lair de Novembre 2007 pour la conversion des classes EOSD vers les classes RPN
   set Const(EOSD2RPN) { {   0  11  12 20 21 31 32 33 40 51 52 81 82 83 100 211 212 213 221 222 223 231 232 233 }
                         { -99 -99 -99  3  1  2 24 24 22 10 10 25 10 13  14   4   4   4   7   7   7  25  25  25 } }

   #----- Correspondance de Janna Lindenberg de Decembre 2007 pour la conversion des classes CORINE vers les classes RPN
   set Const(CORINE2RPN) { {  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 }
                           { 21 21 21 21 21 21 24 24 24 14 20 20 20 16 18 18 18 18 18 18 18 18  5  5 25 14 14 14 14 14 24 10 10  2 11 11  1  1  1  1  1  1  1  1 } }

   #----- Correspondance de Stephane Belair Decembre 2008 pour la conversion des classes GlobCover vers les classes RPN
   set Const(GLOBCOVER2RPN) { { 220 210 70 40 90 50 60 30 120 230 14 20 11 190 150 160 170 180 200 100 110 130 }
                              {   2   3  4  5  6  7  7 14  14  14 15 15 20  21  22  23  23  23  24  25  26  26 } }
   #----- Correspondance de Douglas Chan Juin 2009 pour la conversion des classes GlobCover vers les classes RPN
   set Const(GLOBCOVER2RPN) { { 220 210 70 40 90 50 60 30 120 140 230 14 20 11 190 150 160 170 180 200 100 110 130 }
                              {   2   3  4  5  4  7  7 14  14  14  24 15 15 20  21  24  23  23  23  24  25  26  26 } }

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
   variable Param

   GenX::Procs

   fstdfield copy GPXME  $Grid
   fstdfield copy GPXRMS $Grid
   fstdfield copy GPXRES $Grid
   fstdfield copy GPXTSK $Grid
   
   GenX::GridClear GPXME  0.0
   GenX::GridClear GPXRES 0.0
   GenX::GridClear GPXRMS 0.0
   GenX::GridClear GPXTSK 1.0

   foreach topo $GenX::Param(Topo) {
      switch $topo {
         "USGS"      { GeoPhysX::AverageTopoUSGS      GPXME     ;#----- USGS topograhy averaging method (Global 900m) }
         "SRTM"      { GeoPhysX::AverageTopoSRTM      GPXME     ;#----- STRMv4 topograhy averaging method (Latitude -60,60 90m) }
         "CDED50"    { GeoPhysX::AverageTopoCDED      GPXME 50  ;#----- CDED50 topograhy averaging method (Canada 90m) }
         "CDED250"   { GeoPhysX::AverageTopoCDED      GPXME 250 ;#----- CDED250 topograhy averaging method (Canada 25m) }
         "ASTERGDEM" { GeoPhysX::AverageTopoASTERGDEM GPXME     ;#----- ASTERGDEM topograhy averaging method (Global but south pole 25m) }
         "GTOPO30"   { GeoPhysX::AverageTopoGTOPO30   GPXME     ;#----- GTOPO30 topograhy averaging method (Global  900m) }
         "GMTED30"   { GeoPhysX::AverageTopoGMTED2010 GPXME 30  ;#----- GMTED2010 topograhy averaging method (Global  900m) }
         "GMTED15"   { GeoPhysX::AverageTopoGMTED2010 GPXME 15  ;#----- GMTED2010 topograhy averaging method (Global  450m) }
         "GMTED75"   { GeoPhysX::AverageTopoGMTED2010 GPXME 75  ;#----- GMTED2010 topograhy averaging method (Global  225m) }
      }
   }

   #----- Save output
   fstdfield gridinterp GPXME - NOP True
   fstdfield define GPXME -NOMVAR ME -IP2 0
   fstdfield write GPXME GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Process RMS and resolution only for unstaggered grids
   if { !$GenX::Param(TopoStag) || $GenX::Param(Process)==0 } {
   
      #----- Save RMS
      fstdfield gridinterp GPXRMS - NOP True
      vexpr GPXRMS sqrt(GPXRMS)
      fstdfield define GPXRMS -NOMVAR MRMS -IP1 1200
      fstdfield write GPXRMS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

      #----- Save resolution
      fstdfield define GPXRES -NOMVAR MRES -IP1 1200
      fstdfield write GPXRES GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   fstdfield free GPXRMS GPXRES GPXTSK
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

   GenX::Procs TopoUSGS
   Log::Print INFO "Averaging topography using USGS database"

   #----- Loop over files
   foreach file [glob $GenX::Param(DBase)/$GenX::Path(TopoUSGS)/*] {
      Log::Print DEBUG "   Processing USGS file : $file"
      fstdfile open GPXTOPOFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXTOPOFILE -1 "" -1 -1 -1 "" "ME"] {
         Log::Print DEBUG "      Processing field : $field"
         fstdfield read USGSTILE GPXTOPOFILE $field
         fstdfield stats USGSTILE -nodata -99.0 -celldim $GenX::Param(Cell)

         fstdfield gridinterp $Grid USGSTILE AVERAGE False         
         if { $GenX::Param(Sub)=="LEGACY" } {
            fstdfield gridinterp $Grid USGSTILE SUBLINEAR 11
         }
         
         fstdfield gridinterp GPXRMS USGSTILE AVERAGE_SQUARE False
      }
      fstdfile close GPXTOPOFILE
   }
   fstdfield free USGSTILE

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

         fstdfield gridinterp $Grid GTOPO30TILE AVERAGE False         
         if { $GenX::Param(Sub)=="LEGACY" } {
            fstdfield gridinterp $Grid GTOPO30TILE SUBLINEAR 11
         }
         
         fstdfield gridinterp GPXRMS GTOPO30TILE AVERAGE_SQUARE False
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
      if { $GenX::Param(Sub)=="LEGACY" } {
         fstdfield gridinterp $Grid ATSERGDEMTILE SUBLINEAR 11
      }
      
      fstdfield gridinterp GPXRMS ATSERGDEMTILE AVERAGE_SQUARE False
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
proc GeoPhysX::AverageTopoSRTM { Grid } {
   variable Param

   GenX::Procs SRTM
   Log::Print INFO "Averaging topography using SRTM database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]

   foreach file [GenX::SRTMFindFiles $la0 $lo0 $la1 $lo1] {
      Log::Print DEBUG "   Processing SRTM file $file"
      gdalband read SRTMTILE [gdalfile open SRTMFILE read $file]

      gdalband stats SRTMTILE -celldim $GenX::Param(Cell)

      fstdfield gridinterp $Grid SRTMTILE AVERAGE False
      if { $GenX::Param(Sub)=="LEGACY" } {
         fstdfield gridinterp $Grid SRTMTILE SUBLINEAR 11
      }
      
      fstdfield gridinterp GPXRMS SRTMTILE AVERAGE_SQUARE False

      gdalfile close SRTMFILE
   }
   gdalband free SRTMTILE

   #----- Create source resolution used in destination
   fstdfield gridinterp GPXRMS - ACCUM
   vexpr GPXRES ifelse((GPXTSK && GPXRMS),90,GPXRES)

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

   GenX::Procs CDED
   Log::Print INFO "Averaging topography using CDED(1:${Res}000) database"

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"

   foreach file [GenX::CDEDFindFiles $la0 $lo0 $la1 $lo1 $Res] {
      Log::Print DEBUG "   Processing CDED file $file"
      gdalband read CDEDTILE [gdalfile open CDEDFILE read $file]
      gdalband stats CDEDTILE -nodata [expr $Res==50?-32767:0] -celldim $GenX::Param(Cell)

      fstdfield gridinterp $Grid CDEDTILE AVERAGE False
      if { $GenX::Param(Sub)=="LEGACY" } {
         fstdfield gridinterp $Grid CDEDTILE SUBLINEAR 11
      }
      
      fstdfield gridinterp GPXRMS CDEDTILE AVERAGE_SQUARE False
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

   GenX::Procs GMTED2010
   Log::Print INFO "Averaging topography using GMTED2010 md${Res} database"

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

            fstdfield gridinterp $Grid GMTEDTILE AVERAGE False
            if { $GenX::Param(Sub)=="LEGACY" } {
               fstdfield gridinterp $Grid GMTEDTILE SUBLINEAR 11
            }
            
            fstdfield gridinterp GPXRMS GMTEDTILE AVERAGE_SQUARE False
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
# Name     : <GeoPhysX::AverageAspect>
# Creation : June 2006 - Alexandre Leroux, J.P. Gauthier - CMC/CMOE
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

   GenX::Procs SRTM CDED
   Log::Print INFO "Computing slope and aspect"

   set SRTM [expr [lsearch -exact $GenX::Param(Aspect) SRTM]!=-1]
   set CDED 0

   if { [lsearch -exact $GenX::Param(Aspect) CDED250]!=-1 } {
      set CDED 250
   }
   if { [lsearch -exact $GenX::Param(Aspect) CDED50]!=-1 } {
      set CDED 50
   }

   fstdfield copy GPXFSA  $Grid
   fstdfield copy GPXFSAN $Grid
   fstdfield copy GPXFSAE $Grid
   fstdfield copy GPXFSAS $Grid
   fstdfield copy GPXFSAW $Grid
   fstdfield copy GPXSLA  $Grid
   fstdfield copy GPXSLAN $Grid
   fstdfield copy GPXSLAE $Grid
   fstdfield copy GPXSLAS $Grid
   fstdfield copy GPXSLAW $Grid

   GenX::GridClear [list GPXFSA GPXFSAN GPXFSAE GPXFSAS GPXFSAW GPXSLA GPXSLAN GPXSLAE GPXSLAS GPXSLAW] -1

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   #----- Work tile resolution
   if { $CDED==50 && [llength [GenX::CDEDFindFiles $lat0 $lon0 $lat1 $lon1]] } {
      set res [expr (0.75/3600.0)]  ;# 0.75 arc-secondes CDED
   } elseif { $SRTM } {
      set res [expr (3.0/3600.0)]   ;# 3 arc-secondes SRTM
   } else {
      set res [expr (3.75/3600.0)]  ;# 0.75 arc-secondes CDED
   }

   set dpix [expr $GenX::Param(TileSize)*$res]
   Log::Print DEBUG "   Processing limits  $lat0,$lon0 to $lat1,$lon1 at resolution $res"

   #----- Create latlon referential since original data is in latlon
   georef create LLREF
   eval georef define LLREF -projection \{GEOGCS\[\"WGS 84\",DATUM\[\"WGS_1984\",SPHEROID\[\"WGS 84\",6378137,298.2572235629972,AUTHORITY\[\"EPSG\",\"7030\"\]\],AUTHORITY\[\"EPSG\",\"6326\"\]\],PRIMEM\[\"Greenwich\",0\],UNIT\[\"degree\",0.0174532925199433\],AUTHORITY\[\"EPSG\",\"4326\"\]\]\}

   #----- Create work tile with border included
   gdalband create DEMTILE [expr $GenX::Param(TileSize)+2] [expr $GenX::Param(TileSize)+2] 1 Int16
   gdalband define DEMTILE -georef LLREF
   gdalband stats DEMTILE -nodata 0.0 -celldim $GenX::Param(Cell)

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

         #----- Process STRM first, if asked for
         if { $SRTM && [llength [set srtmfiles [GenX::SRTMFindFiles $la0 $lo0 $la1 $lo1]]] } {
            foreach file $srtmfiles {
               GenX::CacheGet $file -32768
               Log::Print DEBUG "      Processing SRTM DEM file $file"
               gdalband gridinterp DEMTILE $file NEAREST
            }
            set data True
         }

         #----- Process CDED, if asked for
         if { $CDED && [llength [set dnecfiles [GenX::CDEDFindFiles $la0 $lo0 $la1 $lo1 $CDED]]] } {
            foreach file $dnecfiles {
               GenX::CacheGet $file [expr $CDED==50?-32767:0]
               Log::Print DEBUG "      Processing CDED DEM file $file"
               gdalband gridinterp DEMTILE $file NEAREST
            }
            set data True
         }

         #----- If the tile has data, process on destination grid
         if { $data } {
#file delete -force  gdal.$xla.$xlo.tif
#gdalfile open FILEOUT write gdal.$xla.$xlo.tif "GeoTIFF"
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

   #----- Finalize Aspect and Slope
   fstdfield gridinterp GPXFSA  - NOP True
   fstdfield gridinterp GPXFSAN - NOP True
   fstdfield gridinterp GPXFSAE - NOP True
   fstdfield gridinterp GPXFSAS - NOP True
   fstdfield gridinterp GPXFSAW - NOP True

   fstdfield gridinterp GPXSLA  - NOP True
   fstdfield gridinterp GPXSLAN - NOP True
   fstdfield gridinterp GPXSLAE - NOP True
   fstdfield gridinterp GPXSLAS - NOP True
   fstdfield gridinterp GPXSLAW - NOP True

   vexpr GPXSLA  max(GPXSLA,0);
   vexpr GPXSLAN max(GPXSLAN,0);
   vexpr GPXSLAE max(GPXSLAE,0);
   vexpr GPXSLAS max(GPXSLAS,0);
   vexpr GPXSLAW max(GPXSLAW,0);

   vexpr GPXFSAN max(GPXFSAN,0);
   vexpr GPXFSAE max(GPXFSAE,0);
   vexpr GPXFSAS max(GPXFSAS,0);
   vexpr GPXFSAW max(GPXFSAW,0);

   #----- Save everything
   fstdfield define GPXFSA  -NOMVAR FSA0 -IP2 0
   fstdfield define GPXFSAN -NOMVAR FSA  -IP2 0
   fstdfield define GPXFSAE -NOMVAR FSA  -IP2 90
   fstdfield define GPXFSAS -NOMVAR FSA  -IP2 180
   fstdfield define GPXFSAW -NOMVAR FSA  -IP2 270

   fstdfield define GPXSLA  -NOMVAR SLA0 -IP2 0
   fstdfield define GPXSLAN -NOMVAR SLA  -IP2 0
   fstdfield define GPXSLAE -NOMVAR SLA  -IP2 90
   fstdfield define GPXSLAS -NOMVAR SLA  -IP2 180
   fstdfield define GPXSLAW -NOMVAR SLA  -IP2 270

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

   fstdfield free GPXSLA GPXSLAN GPXSLAE GPXSLAS GPXSLAW GPXFSA GPXFSAN GPXFSAE GPXFSAS GPXFSAW
   gdalband free DEMTILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageAspect>
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

   #----- Calculate slope and aspect for the tile
   vexpr SLATILE dslopedeg($Band)
   vexpr FSATILE daspect($Band)

   #----- Define aspect ranges
   vexpr FSAN ifelse((FSATILE>315 || FSATILE<=45)  && SLATILE!=0.0,1,-1)
   vexpr FSAE ifelse((FSATILE>45 && FSATILE<=135)  && SLATILE!=0.0,1,-1)
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

   fstdfield gridinterp GPXFSA  FSATILE AVERAGE False
   fstdfield gridinterp GPXSLA  SLATILE AVERAGE False
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
      "USGS"      { GeoPhysX::AverageMaskUSGS      $Grid }
      "CANVEC"    { GeoPhysX::AverageMaskCANVEC    $Grid }
      "GLOBCOVER" { GeoPhysX::AverageMaskGLOBCOVER $Grid }
      "GLC2000"   { GeoPhysX::AverageMaskGLC2000   $Grid }
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
   fstdfield define GPXMASK -NOMVAR MG -IP1 0
   vexpr GPXMASK ifelse(GPXMASK==-99.0,0.0,GPXMASK/100.0)
   fstdfield write GPXMASK GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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
      fstdfield define GPXMASK -NOMVAR MG -IP1 0
      fstdfield write GPXMASK GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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
      Log::Print INFO "Grid intersection with GLOBCOVER database is { $limits }"
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
      fstdfield define GPXMASK -NOMVAR MG -IP1 0
      fstdfield write GPXMASK GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

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

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   fstdfield copy GPXMASK $Grid
   GenX::GridClear GPXMASK 0.0

   #----- Loop over files
   foreach file [GenX::CANVECFindFiles $lat0 $lon0 $lat1 $lon1 { HD_1480009_2 } ] {
      Log::Print DEBUG "   Processing file $file"
      ogrfile open CANVECFILE read $file
      ogrlayer read CANVECTILE CANVECFILE 0
      fstdfield gridinterp GPXMASK CANVECTILE ALIASED 1.0
      ogrfile close CANVECFILE
   }

   #----- Use whatever we have for US
#   ogrfile open USLAKESFILE read $GenX::Param(DBase)/$GenX::Path(Various)/mjwater.shp
#   ogrlayer read USLAKES USLAKESFILE 0
#   fstdfield gridinterp GPXMASK USLAKES ALIASED 1.0
#   ogrfile close USLAKESFILE

   vexpr GPXMASK 1.0-clamp(GPXMASK,0.0,1.0)

   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" 1200 -1 -1 "" "ME"]]] } {
      fstdfield read GPXME GPXOUTFILE $idx
      if { [lindex [fstdfield stats GPXME -max] 0]>0.0 } {
         vexpr GPXMASK ifelse(GPXMASK>0.0 && GPXME==0.0,0.0,GPXMASK)
      }
#      fstdfield free GPXME
   }

   fstdfield define GPXMASK -NOMVAR MG -IP1 0 -IP2 0
   fstdfield write GPXMASK GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

   ogrlayer free USLAKES CANVECTILE
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

   GenX::Procs
   Log::Print INFO "Averaging geopolitical mask using CANADA database"

   fstdfield copy GPXMASK $Grid
   GenX::GridClear GPXMASK 0.0

   #----- Loop over files

   ogrfile open CANPROVFILE read /data/cmoe/afsr005/Data/Vector/Country/Canada/Provinces.shp
   ogrlayer read CANPROV CANPROVFILE 0
   fstdfield gridinterp GPXMASK CANPROV INTERSECT
   ogrfile close CANPROVFILE

   fstdfield define GPXMASK -NOMVAR MGGO -IP1 0 -IP2 0
   fstdfield write GPXMASK GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

   ogrlayer free CANPROV
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
      }
   }
   fstdfield free GPXVSK
   fstdfield gridinterp GPXVF - NOP True

   #----- Save the 26 Vege types
   fstdfield define GPXVF -NOMVAR VF -IP2 0
   fstdfield stats GPXVF -levels $Param(VegeTypes) -leveltype UNDEFINED
   fstdfield write GPXVF GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

   fstdfield free GPXVF

   #----- Vegetation canopy height
   if { $GenX::Param(Sub)!="LEGACY" } {
      GeoPhysX::AverageGLAS $Grid
   }
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
         vexpr EOSDMASK EOSDMASK<<0

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
# Name     : <GeoPhysX::AverageGLAS>
# Creation : Janvier 2009 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Average vegetation canopy height using GLAS database
#
# Parameters :
#   <Grid>   : Grid on which to generate the vegetation
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageGLAS { Grid } {
   variable Param
   variable Const

   GenX::Procs AverageGLAS
   Log::Print INFO "Averaging vegetation canopy height using GLAS database"

   #----- Open the file
   gdalfile open GLASFILE read $GenX::Param(DBase)/$GenX::Path(GLAS)/Simard_Pinto_3DGlobalVeg_JGR.tif

   if { ![llength [set limits [georef intersect [fstdfield define $Grid -georef] [gdalfile georef GLASFILE]]]] } {
      Log::Print WARNING "Specified grid does not intersect with GLAS database, vegetation will not be calculated"
   } else {
      Log::Print INFO "Grid intersection with GLAS database is { $limits }"
      set x0 [lindex $limits 0]
      set x1 [lindex $limits 2]
      set y0 [lindex $limits 1]
      set y1 [lindex $limits 3]

      #----- Loop over the data by tiles since it's too big to fit in memory
      for { set x $x0 } { $x<$x1 } { incr x $GenX::Param(TileSize) } {
         for { set y $y0 } { $y<$y1 } { incr y $GenX::Param(TileSize) } {
            Log::Print DEBUG "   Processing tile $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]"
            gdalband read GLASTILE { { GLASFILE 1 } } $x $y [expr $x+$GenX::Param(TileSize)-1] [expr $y+$GenX::Param(TileSize)-1]
            gdalband stats GLASTILE -nodata 255 -celldim $GenX::Param(Cell)

            fstdfield gridinterp $Grid GLASTILE AVERAGE False
         }
      }

      gdalband free GLASTILE
   }
   gdalfile close GLASFILE

   #----- Save output
   fstdfield gridinterp $Grid - NOP True
   fstdfield define $Grid -NOMVAR VCH -IP1 0
   fstdfield write $Grid GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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

   GenX::Procs
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

      #----- Save output
      fstdfield define GPXJ1 -NOMVAR J1 -IP1 [expr 1200-$type]
      fstdfield write GPXJ1 GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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

   GenX::Procs
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
         fstdfield define GPXJ1 -NOMVAR J1 -IP1 [expr 1200-$type]
         fstdfield write GPXJ1 GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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
         fstdfield define GPXJ2 -NOMVAR J2 -IP1 [expr 1200-$type]
         fstdfield write GPXJ2 GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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
   fstdfield define GPXSANDT -NOMVAR J1 -IP1 1199
   fstdfield define GPXCLAYT -NOMVAR J2 -IP1 1199
   fstdfield define GPXGRAVT -NOMVAR J3 -IP1 1199
   fstdfield define GPXBULKT -NOMVAR J4 -IP1 1199
   fstdfield define GPXOCT   -NOMVAR J5 -IP1 1199

   fstdfield write GPXSANDT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXCLAYT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXGRAVT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXBULKT GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXOCT   GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Copy sub-surface data into 4 layers (needed by GEM)
   foreach ip1 { 1198 1197 1196 1195 } {
      fstdfield define GPXSANDS -NOMVAR J1 -IP1 $ip1
      fstdfield define GPXCLAYS -NOMVAR J2 -IP1 $ip1
      fstdfield define GPXGRAVS -NOMVAR J3 -IP1 $ip1
      fstdfield define GPXBULKS -NOMVAR J4 -IP1 $ip1
      fstdfield define GPXOCS   -NOMVAR J5 -IP1 $ip1

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

   GenX::Procs
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

      #----- Save output
      fstdfield define GPXJ2 -NOMVAR J2 -IP1 [expr 1200-$type]
      fstdfield write GPXJ2 GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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
   fstdfield define GPXLOW -NOMVAR MEL -IP1 0 -IP2 0
   fstdfield write GPXLOW GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

   #----- save <Hhr^2>ij
   fstdfield gridinterp GPXLRMS - NOP True
   vexpr GPXLRMS ifelse(GPXLRMS>0.0,GPXLRMS^0.5,0.0)
   fstdfield define GPXLRMS -NOMVAR LRMS -IP1 0
   fstdfield write GPXLRMS GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

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
   fstdfield define GPXGXX -NOMVAR GXX -IP1 0
   fstdfield write GPXGXX GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield gridinterp GPXGYY - NOP True
   fstdfield define GPXGYY -NOMVAR GYY -IP1 0
   fstdfield write GPXGYY GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield gridinterp GPXGXY - NOP True
   fstdfield define GPXGXY -NOMVAR GXY -IP1 0
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

   fstdfield define GPXFLR -NOMVAR FLR -IP1 0 -IP2 0
   fstdfield write GPXFLR GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
   fstdfield define GPXFHR -NOMVAR FHR -IP1 0 -IP2 0
   fstdfield write GPXFHR GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

   #----- For low-res and hi-res (over land only)
   Log::Print INFO "Computing low and high res fields over land only"

   vexpr GPXDX GPXDX*sqrt(GPXMG)
   vexpr GPXDY GPXDY*sqrt(GPXMG)

   GeoPhysX::SubCorrectionFilter GPXFLR GPXDX GPXDY $Const(lres) $Const(largec0) $Const(largec1)
   GeoPhysX::SubCorrectionFilter GPXFHR GPXDX GPXDY GPXMRES $Const(smallc0) $Const(smallc1)

   fstdfield define GPXFLR -NOMVAR FLRP -IP1 0 -IP2 0
   fstdfield write GPXFLR GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
   fstdfield define GPXFHR -NOMVAR FHRP -IP1 0 -IP2 0
   fstdfield write GPXFHR GPXAUXFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

   fstdfield free GPXMG GPXDX GPXDY GPXFLR GPXFHR
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::SubTopoFilter>
# Creation : Septembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Apply the GEM topo filter to the previously generated topo.
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
   
   fstdfield read GPXMF GPXOUTFILE -1 "" -1 -1 -1 "" "ME"

   Log::Print INFO "Filtering ME"

   geophy zfilter GPXMF GenX::Settings
   fstdfield define GPXMF -NOMVAR MF -IP1 0 -IP2 0
   fstdfield write GPXMF GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXMF
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

proc GeoPhysX::LegacySub { Grid } {
   variable Param
   variable Const

   GenX::Procs
   
   #----- check for needed fields
   if { [catch {
      fstdfield read GPXVG GPXOUTFILE -1 "" -1 -1 -1 "" "VG" } ] } {
    
      Log::Print WARNING "Missing fields, will not calculate legacy sub grid fields"
      return
   }
   
   fstdfield copy GPXZ0 $Grid
   fstdfield copy GPXLH $Grid
   fstdfield copy GPXDH $Grid
   fstdfield copy GPXY7 $Grid
   fstdfield copy GPXY8 $Grid
   fstdfield copy GPXY9 $Grid
  
   Log::Print INFO "Computing legacy sub grid fields Z0 ZP LH DH Y7 Y8 Y9"
   
   geophy zfilter GPXME GenX::Settings
   geophy subgrid_legacy GPXME GPXVG GPXZ0 GPXLH GPXDH GPXY7 GPXY8 GPXY9
   
   vexpr GPXZ0 ifelse(GPXZ0>$Const(z0def),GPXZ0,$Const(z0def) )
   vexpr GPXZP ifelse(GPXZ0>$Const(z0def),ln(GPXZ0),$Const(zpdef))

   #------ Filter roughness length
   if { $GenX::Param(Z0Filter) } {
      Log::Print INFO "Filtering Z0"
      geophy zfilter GPXZ0 GenX::Settings
   }

   fstdfield define GPXZ0 -NOMVAR Z0 -IP1 0 -IP2 0
   fstdfield define GPXZP -NOMVAR ZP -IP1 0 -IP2 0
   fstdfield define GPXLH -NOMVAR LH -IP1 0 -IP2 0
   fstdfield define GPXDH -NOMVAR DH -IP1 0 -IP2 0
   fstdfield define GPXY7 -NOMVAR Y7 -IP1 0 -IP2 0
   fstdfield define GPXY8 -NOMVAR Y8 -IP1 0 -IP2 0
   fstdfield define GPXY9 -NOMVAR Y9 -IP1 0 -IP2 0

   fstdfield write GPXZ0 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXZP GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXLH GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXDH GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXY7 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXY8 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield write GPXY9 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXVG GPXZ0 GPXZP GPXLH GPXDH GPXY7 GPXY8 GPXY9
}

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
   fstdfield define GPXLH -NOMVAR LH -IP1 0 -IP2 0
   fstdfield write GPXLH GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXLH GPXMEL GPXLRMS GPXMG GPXFLR
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
   vexpr GPXALP  (dangle(GPXGXX))*3.14159265/180.
   vexpr GPXCOSA cos(GPXALP)
   vexpr GPXSINA sin(GPXALP)

   Log::Print INFO "Computing Y7"
   vexpr GPXY789 GPXMG*(GPXGXX*(GPXCOSA^2) + GPXGYY*(GPXSINA^2) - 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y7 -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   Log::Print INFO "Computing Y8"
   vexpr GPXY789 GPXMG*(GPXGXX*(GPXSINA^2) + GPXGYY*(GPXCOSA^2) + 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y8 -IP1 0 -IP2 0
   fstdfield write GPXY789 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   Log::Print INFO "Computing Y9"
   vexpr GPXY789 GPXMG*((GPXGXX-GPXGYY)*GPXSINA*GPXCOSA + GPXGXY*(GPXCOSA^2-GPXSINA^2))
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y9 -IP1 0 -IP2 0
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

   GenX::Procs
   
   #----- check for needed fields
   if { [catch {
      fstdfield read GPXME   GPXOUTFILE -1 "" -1   -1 -1 "" "ME"
      fstdfield read GPXMG   GPXOUTFILE -1 "" -1   -1 -1 "" "MG"
      fstdfield read GPXMRMS GPXAUXFILE -1 "" -1   -1 -1 "" "MRMS"
      fstdfield read GPXMEL  GPXAUXFILE -1 "" -1   -1 -1 "" "MEL"
      fstdfield read GPXLRMS GPXAUXFILE -1 "" -1   -1 -1 "" "LRMS"
      fstdfield read GPXFHR  GPXAUXFILE -1 "" -1   -1 -1 "" "FHR"
      fstdfield read GPXFLR  GPXAUXFILE -1 "" -1   -1 -1 "" "FLR"
      fstdfield read GPXZ0V1 GPXOUTFILE -1 "" 1199 -1 -1 "" "VF" } ] } {
    
      Log::Print WARNING "Missing fields, will not calculate roughness length"
      return
   }
   
   vexpr GPXME   GPXME  *GPXFHR
   vexpr GPXMRMS GPXMRMS*GPXFHR
   vexpr GPXMEL  GPXMEL *GPXFLR
   vexpr GPXLRMS GPXLRMS*GPXFLR

   Log::Print INFO "Computing subgrid-scale variance"
   vexpr GPXSSS (GPXMRMS^2 - GPXME^2)-(GPXLRMS^2 - GPXMEL^2)
   vexpr GPXSSS ifelse(GPXSSS>0.0,GPXSSS^0.5,0.0)
   vexpr GPXSSS ifelse(GPXMG>$Const(mgmin),GPXSSS,0.0)
   fstdfield define GPXSSS -NOMVAR SSS -IP1 0 -IP2 0
   fstdfield write GPXSSS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr GPXHCOEF (1.5 - 0.5*(GPXSSS-20.0)/680.0)
   vexpr GPXHCOEF ifelse(GPXSSS>700.0,1.0,GPXHCOEF)

   vexpr GPXZREF (GPXHCOEF*GPXSSS)
   vexpr GPXZREF ifelse(GPXZREF<$Const(zrefmin),$Const(zrefmin),GPXZREF)
   vexpr GPXZREF ifelse(GPXZREF>1500.0,1500.0,GPXZREF)

   fstdfield define GPXZREF -NOMVAR ZREF -IP1 0 -IP2 0
   fstdfield write GPXZREF GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr GPXSLP (GPXHCOEF*GPXHCOEF*GPXSSS/$Const(lres))

   Log::Print INFO "Computing Z0_topo"
   vexpr GPXZTP ifelse(GPXSLP>$Const(slpmin) || GPXZREF>$Const(zrefmin),1.0+GPXZREF*exp(-$Const(karman)/sqrt(0.5*$Const(drgcoef)*GPXSLP)),0.0)
   vexpr GPXZTP ifelse(GPXSSS<=$Const(sssmin),0.1*GPXSSS,GPXZTP)
   fstdfield define GPXZTP -NOMVAR ZTOP -IP1 0 -IP2 0
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
   fstdfield define GPXZ0V1 -NOMVAR ZVG1 -IP1 0 -IP2 0
   fstdfield write GPXZ0V1 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   GenX::GridClear { GPXZ0V1 GPXZ0V2 } 0.0
   foreach element [lrange $Param(VegeTypes) 3 end] zzov [lrange $Param(VegeZ0vTypes) 3 end] {
      set ip1 [expr 1200-$element]
      fstdfield read GPXVF GPXOUTFILE -1 "" $ip1 -1 -1 "" "VF"
      vexpr GPXZ0V1 (GPXZ0V1+GPXVF*$zzov)
      vexpr GPXZ0V2 (GPXZ0V2+GPXVF)
   }
   vexpr GPXZ0V1 ifelse(GPXZ0V2>0.001,GPXZ0V1/GPXZ0V2,0.0)
   fstdfield define GPXZ0V1 -NOMVAR ZVG2 -IP1 0 -IP2 0
   fstdfield write GPXZ0V1 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Local (vegetation) roughness length from canopy height
   
   if { ![catch { fstdfield read GPXVCH  GPXAUXFILE -1 "" -1 -1 -1 "" "VCH" }] } {
      vexpr GPXZ0VG ifelse(GPXMG>0.0,max(GPXVCH*0.1,0.01),0.0)
      fstdfield define GPXZ0VG -NOMVAR Z0VG -IP1 0 -IP2 0
      fstdfield write GPXZ0VG GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   } else {
      Log::Print WARNING "Missing VCH, could not calculate Local (vegetation) roughness length from canopy height (Z0VG)"
   }

   #----- Roughness length over soil
   fstdfield read GPXGA GPXOUTFILE -1 "" 1198 -1 -1 "" "VF"

   vexpr GPXW1  ifelse(GPXZTP >0.0 && GPXZREF>GPXZTP     , (1.0/ln(GPXZREF/GPXZTP ))^2.0        , 0.0)
   vexpr GPXW2  ifelse(GPXZ0V1>0.0 && GPXZREF>GPXZ0V1    , (1.0/ln(GPXZREF/GPXZ0V1))^2.0        , 0.0)
   vexpr GPXZ0S ifelse((GPXW1+GPXW2)>0.0                 , GPXZREF*exp( -1.0/sqrt(GPXW1+GPXW2)) , 0.0)
   vexpr GPXZ0S ifelse(GPXZREF<=$Const(zrefmin)          , GPXZ0V1                              , GPXZ0S)
   vexpr GPXZ0S ifelse(GPXZ0S<$Const(z0def)              , $Const(z0def)                        , GPXZ0S)
   vexpr GPXZ0S ifelse(GPXGA>=(1.0-$Const(gamin))        , $Const(z0def)                        , GPXZ0S)
   fstdfield define GPXZ0S -NOMVAR Z0S -IP1 0 -IP2 0
   fstdfield write GPXZ0S GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr GPXZPS ifelse(GPXZ0S>0.0,ln(GPXZ0S),$Const(zpdef))
   fstdfield define GPXZPS -NOMVAR ZPS -IP1 0 -IP2 0
   fstdfield write GPXZPS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Roughness length over glaciers
   vexpr GPXW1  ifelse(GPXZTP>0.0 && GPXZREF>GPXZTP, (1.0/ln(GPXZREF/GPXZTP      ))^2.0 , 0.0)
   vexpr GPXW2  ifelse(GPXZREF>$Const(gaz0)        , (1.0/ln(GPXZREF/$Const(gaz0)))^2.0 , 0.0)
   vexpr GPXZ0G ifelse((GPXW1+GPXW2)>0.0           , GPXZREF*exp(-1.0/sqrt(GPXW1+GPXW2)), 0.0)
   vexpr GPXZ0G ifelse(GPXZREF<=$Const(zrefmin)    , $Const(gaz0)                       , GPXZ0G)
   vexpr GPXZ0G ifelse(GPXZ0G<$Const(z0def)        , $Const(z0def)                      , GPXZ0G)
   vexpr GPXZ0G ifelse(GPXGA<=$Const(gamin)        , $Const(z0def)                      , GPXZ0G)
   fstdfield define GPXZ0G -NOMVAR Z0G -IP1 0 -IP2 0
   fstdfield write GPXZ0G GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr GPXZPG ifelse(GPXZ0G>0.0,ln(GPXZ0G),$Const(zpdef) )
   fstdfield define GPXZPG -NOMVAR ZPG -IP1 0 -IP2 0
   fstdfield write GPXZPG GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Roughness length over water
   vexpr GPXW1  ifelse(GPXZTP>0.0 && GPXZREF>GPXZTP, (1.0/ln(GPXZREF/GPXZTP      ))^2.0 , 0.0)
   vexpr GPXW2  ifelse(GPXZREF>0.001               , (1.0/ln(GPXZREF/0.001))^2.0        , 0.0)
   vexpr GPXZ0W ifelse((GPXW1+GPXW2)>0.0           , GPXZREF*exp(-1.0/sqrt(GPXW1+GPXW2)), 0.0)
   vexpr GPXZ0W ifelse(GPXZREF<=$Const(zrefmin)    , 0.001                              , GPXZ0W)
   vexpr GPXZ0W ifelse(GPXZ0W<$Const(z0def)        , $Const(z0def)                      , GPXZ0W)
   vexpr GPXZ0W ifelse((1.0-GPXMG)<=$Const(mgmin)  , $Const(z0def)                      , GPXZ0W)
   fstdfield define GPXZ0W -NOMVAR Z0W -IP1 0 -IP2 0
   fstdfield write GPXZ0W GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr GPXZPW ifelse(GPXZ0W>0.0,ln(GPXZ0W),$Const(zpdef) )
   fstdfield define GPXZPW -NOMVAR ZPW -IP1 0 -IP2 0
   fstdfield write GPXZPW GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Fill some gaps
   vexpr GPXZ0S ifelse(GPXMG>$Const(mgmin) && GPXZTP<$Const(z0min) && GPXZ0V1<$Const(z0min) && GPXZ0G<$Const(z0min),$Const(z0def),GPXZ0S)
   fstdfield define GPXZ0S -NOMVAR Z0S -IP1 0 -IP2 0
   fstdfield write GPXZ0S GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   vexpr GPXZPS ifelse(GPXZ0S>0.0,ln(GPXZ0S),$Const(zpdef) )
   fstdfield define GPXZPS -NOMVAR ZPS -IP1 0 -IP2 0
   fstdfield write GPXZPS GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #----- Total roughness length
   GeoPhysX::Compute_GA GPXGA GPXGA
   vexpr GPXZP GPXMG*((1.0-GPXGA)*GPXZPS+GPXGA*GPXZPG)+(1.0-GPXMG)*GPXZPW

   fstdfield define GPXZP -NOMVAR ZP0 -IP1 0 -IP2 0
   fstdfield write GPXZP GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr GPXZ0 exp(GPXZP)
   fstdfield define GPXZ0 -NOMVAR Z00 -IP1 0 -IP2 0
   fstdfield write GPXZ0 GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   #------ Filter roughness length
   if { $GenX::Param(Z0Filter) } {
      Log::Print INFO "Filtering Z0"
      geophy zfilter GPXZ0 GenX::Settings
   }
   vexpr GPXZ0 ifelse(GPXZ0>$Const(z0def),GPXZ0,$Const(z0def) )
   fstdfield define GPXZ0 -NOMVAR Z0 -IP1 0 -IP2 0
   fstdfield write GPXZ0 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr GPXZP ifelse(GPXZ0>$Const(z0def),ln(GPXZ0),$Const(zpdef))
   fstdfield define GPXZP -NOMVAR ZP -IP1 0 -IP2 0
   fstdfield write GPXZP GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXLH GPXSSS GPXHCOEF GPXZREF GPXSLP GPXZTP GPXZ0S GPXZ0W GPXZPW \
       GPXZ0V2 GPXZ0VG GPXZPS GPXGA GPXZ0G GPXZPG GPXZ0 GPXZ0V1 GPXZ0V2 GPXZP GPXMG GPXVF GPXVCH
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
         fstdfield define GPXVF -NOMVAR VF -IP1 [expr 1200-$type]
         fstdfield write GPXVF GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
      } else {
         Log::Print WARNING "Could not find VF($type) field while checking VF"
         break
      }
   }

   if { [fstdfield is GPXVF2] } {
      GeoPhysX::Compute_GA GPXGA GPXVF2
      fstdfield define GPXGA -NOMVAR GA -IP1 0
      fstdfield write GPXGA GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

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
         fstdfield define GPXJ1 -NOMVAR J1 -IP1 [expr 1200-$type]
         fstdfield write GPXJ1 GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
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
         fstdfield define GPXJ2 -NOMVAR J2 -IP1 [expr 1200-$type]
         fstdfield write GPXJ2 GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)
      } else {
         Log::Print WARNING "Could not find J2($type) field, will not do the consistency check on J2($type)"
      }
   }
   fstdfield free GPXJ1 GPXJ2 GPXMG GPXVF GPXVF2 GPXVF3 GPXGA
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
   fstdfield define GPXVG -NOMVAR VG -IP1 0 -IP2 0
   fstdfield write GPXVG GPXOUTFILE -[expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24] True $GenX::Param(Compress)

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