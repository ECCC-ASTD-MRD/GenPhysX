#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : GeoPhysX.tcl
# Version    : 0.10
# Creation   : Septembre 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Description: Definitions of fonctions related to geo-physical fields
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#   GeoPhysX::AverageTopo          { Grids }
#   GeoPhysX::AverageTopoDEM       { Grid SRTM DNEC Aspect }
#   GeoPhysX::AverageMask          { Grid }
#   GeoPhysX::AverageMaskCANVEC    { Grid }
#   GeoPhysX::DominantVege         { Grid }
#   GeoPhysX::AverageVege          { Grid }
#   GeoPhysX::AverageVegeEOSD      { Grid }
#   GeoPhysX::AverageVegeCORINE    { Grid }
#   GeoPhysX::AverageSand          { Grid }
#   GeoPhysX::AverageClay          { Grid }
#   GeoPhysX::AverageTopoLD        { Grids Type }
#   GeoPhysX::AverageGradient      { Grid }
#   GeoPhysX::AverageAspect        { Grid }
#   GeoPhysX::PostCorrectionFilter { FieldRes FieldDX FieldDY DBR C1 C2 C3 }
#   GeoPhysX::PostCorrectionFactor { }
#   GeoPhysX::PostTopoFilter       { }
#   GeoPhysX::PostLaunchingHeight  { }
#   GeoPhysX::PostY789             { }
#   GeoPhysX::PostRoughnessLength  { }
#
#============================================================================

namespace eval GeoPhysX { } {
   variable Data
   variable Const
   global env

   set Data(Version)   0.14

   #----- Specific data information

   set Data(SandTypes)    { 1 2 3 4 5 }
   set Data(ClayTypes)    { 1 2 3 4 5 }
   set Data(VegeTypes)    { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 }
   set Data(VegeZ0vTypes) { 0.001 0.0003 0.001 1.5 3.5 1.0 2.0 3.0 0.8 0.05 0.15 0.15 0.02
                            0.08 0.08 0.08 0.35 0.25 0.1 0.08 1.35 0.01 0.05 0.05 1.5 0.05 }

   #----- constant definitions

   set Const(lhmin)   3.0
   set Const(mgmin)   0.001
   set Const(z0min)   0.0001
   set Const(z0def)   0.05
   set Const(gaz0)    0.0003
   set Const(dbl)     5000.0
   set Const(drgcoef) 0.40
   set Const(karman)  0.40
   set Const(slpmin)  0.01
   set Const(zrefmin) 15.0
   set Const(lres)    5000.0
   set Const(hres)    900.0
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopo>
# Creation : June 2006 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography on multiple grids (staggering) through averaging.
#
# Parameters :
#   <Grids>  : Grids on which to generate the topography
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopo { Grids } {

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageTopo Start" 1
   GenX::GridClear $Grids -99.0

   #----- Loop over files
   foreach file [glob $GenX::Path(DBase)/$GenX::Path(Topo)/*] {
      GenX::Trace "   Processing file : $file" 2
      fstdfile open GPXTOPOFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXTOPOFILE -1 "" -1 -1 -1 "" "ME"] {
         GenX::Trace "      Processing field : $field" 2
         fstdfield read GPXTILE GPXTOPOFILE $field
         fstdfield stats GPXTILE -nodata -99.0

         #----- Average on each output grids

         foreach grid $Grids {
            fstdfield gridinterp $grid GPXTILE AVERAGE False
         }
      }
      fstdfile close GPXTOPOFILE
   }

   #----- Save output
   foreach grid $Grids {
      fstdfield define $grid -NOMVAR ME -IP2 0 -IP3 0
      fstdfield gridinterp $grid - NOP True
      vexpr $grid ifelse($grid==-99.0,0.0,$grid)
      fstdfield write $grid GPXOUTFILE -24 True
   }
   fstdfield free GPXTILE
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoDEM>
# Creation : June 2006 - Alexandre Leroux, J.P. Gauthier - CMC/CMOE
#
# Goal     : Generate the topography on multiple grids (staggering) through averaging.
#
# Parameters :
#   <Grids>  : Grids on which to generate the topography
#   <SRTM>   : Use SRTM data
#   <DNEC>   : Use DNEC data
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoDEM { Grid { SRTM 0 } { DNEC 0 } { Aspect True } } {
   variable Data

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageTopoDEM: Computing topography, slope and aspect from original source" 1

   if { $Aspect } {
      fstdfield copy GPXASPEC  $Grid
      fstdfield copy GPXASPECN $Grid
      fstdfield copy GPXASPECE $Grid
      fstdfield copy GPXASPECS $Grid
      fstdfield copy GPXASPECW $Grid
      fstdfield copy GPXSLOPE  $Grid
      fstdfield copy GPXSLOPEN $Grid
      fstdfield copy GPXSLOPEE $Grid
      fstdfield copy GPXSLOPES $Grid
      fstdfield copy GPXSLOPEW $Grid

      GenX::GridClear [list GPXASPEC GPXASPECN GPXASPECE GPXASPECS GPXASPECW GPXSLOPE GPXSLOPEN GPXSLOPEE GPXSLOPES GPXSLOPEW] -1
   }
   fstdfield copy GPXRMS $Grid
   GenX::GridClear [list $Grid GPXRMS] 0.0

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   #----- Work tile resolution
   if { $DNEC==50 && [llength [GenX::DNECFindFiles $lat0 $lon0 $lat1 $lon1]] } {
      set res [expr (0.75/3600.0)]  ;# 0.75 arc-secondes DNEC
   } elseif { $SRTM } {
      set res [expr (3.0/3600.0)]   ;# 3 arc-secondes SRTM
   } else {
      set res [expr (3.75/3600.0)]  ;# 0.75 arc-secondes DNEC
   }

   set dpix [expr $GenX::Data(TileSize)*$res]
   GenX::Trace "   Processing limits  $lat0,$lon0 to $lat1,$lon1 at resolution $res" 2

   #----- Create latlon referential since original data is in latlon
   georef create LLREF
   eval georef define LLREF -border 1 -projection \{GEOGCS\[\"WGS 84\",DATUM\[\"WGS_1984\",SPHEROID\[\"WGS 84\",6378137,298.2572235629972,AUTHORITY\[\"EPSG\",\"7030\"\]\],AUTHORITY\[\"EPSG\",\"6326\"\]\],PRIMEM\[\"Greenwich\",0\],UNIT\[\"degree\",0.0174532925199433\],AUTHORITY\[\"EPSG\",\"4326\"\]\]\}

   #----- Create work tile with border included
   gdalband create DEMTILE [expr $GenX::Data(TileSize)+2] [expr $GenX::Data(TileSize)+2] 1 Int16
   gdalband define DEMTILE -georef LLREF
   gdalband stats DEMTILE -nodata 0.0

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
         gdalband define DEMTILE -transform [list $lo0 $res 0.0 $la1 0.0 -$res]
         GenX::Trace "   Processing area from $la0,$lo0 to $la1,$lo1" 2

         #----- Process STRM first, if asked for
         if { $SRTM && [llength [set srtmfiles [GenX::SRTMFindFiles $la0 $lo0 $la1 $lo1]]] } {
            foreach file $srtmfiles {
               GenX::CacheGet $file -32768
               GenX::Trace "      Processing SRTM DEM file $file" 2
               gdalband gridinterp DEMTILE $file
            }
            set data True
         }

         #----- Process DNEC, if asked for
         if { $DNEC && [llength [set dnecfiles [GenX::DNECFindFiles $la0 $lo0 $la1 $lo1 $DNEC]]] } {
            foreach file $dnecfiles {
               GenX::CacheGet $file [expr $DNEC==50?-32767:0]
               GenX::Trace "      Processing DNEC DEM file $file" 2
#               set ll [gdalband stats $file -gridpoint 0.0 0.0]
#               puts stderr "ll= $ll"
#               puts stderr "xy= [set xy [gdalband stats DEMTILE -coordpoint [lindex $ll 0] [lindex $ll 1] True]]"
#               gdalband tile DEMTILE $file [expr int([lindex $xy 0])] [expr int([lindex $xy 1])]
               gdalband gridinterp DEMTILE $file
            }
            set data True
         }

         #----- If the tile has data, process on destination grid
         if { $data } {
            #----- Calcul de l'average sur la grille cible
            GenX::Trace "   Computing topography on target grid" 2
            fstdfield gridinterp $Grid DEMTILE AVERAGE False
            GenX::Trace "   Computing squared topography on target grid" 2
            fstdfield gridinterp GPXRMS DEMTILE AVERAGE_SQUARE False

            #----- Calcul des aspects - petites modifs à la proc Aspect nécessaires
            if { $Aspect } {
               GenX::Trace "   Computing slope and aspect per quadrant" 2
               GeoPhysX::AverageAspect $Grid DEMTILE
            }
         }
      }
   }
   GenX::CacheFree

   #----- Finalize Topo

   fstdfield gridinterp $Grid - NOP True
   fstdfield define $Grid -NOMVAR ME -IP1 1200
   fstdfield write $Grid GPXOUTFILE -32 True
   fstdfield define $Grid -NOMVAR MED -IP1 1200
   fstdfield write $Grid GPXSECFILE -32 True

   fstdfield gridinterp GPXRMS - NOP True
   vexpr GPXRMS sqrt(GPXRMS)
   fstdfield define GPXRMS -NOMVAR MED2 -IP1 1200
   fstdfield write GPXRMS GPXSECFILE -32 True

   #----- Finalize Aspect and Slope
   if { $Aspect } {
      fstdfield gridinterp GPXASPEC  - NOP True
      fstdfield gridinterp GPXASPECN - NOP True
      fstdfield gridinterp GPXASPECE - NOP True
      fstdfield gridinterp GPXASPECS - NOP True
      fstdfield gridinterp GPXASPECW - NOP True

      fstdfield gridinterp GPXSLOPE  - NOP True
      fstdfield gridinterp GPXSLOPEN - NOP True
      fstdfield gridinterp GPXSLOPEE - NOP True
      fstdfield gridinterp GPXSLOPES - NOP True
      fstdfield gridinterp GPXSLOPEW - NOP True

      vexpr GPXSLOPEN max(GPXSLOPEN,0);
      vexpr GPXSLOPEE max(GPXSLOPEE,0);
      vexpr GPXSLOPES max(GPXSLOPES,0);
      vexpr GPXSLOPEW max(GPXSLOPEW,0);

      #----- Save everything
      fstdfield define GPXASPEC  -NOMVAR ASP0 -IP1 0
      fstdfield define GPXASPECN -NOMVAR ASP  -IP1 0
      fstdfield define GPXASPECE -NOMVAR ASP  -IP1 90
      fstdfield define GPXASPECS -NOMVAR ASP  -IP1 180
      fstdfield define GPXASPECW -NOMVAR ASP  -IP1 270

      fstdfield define GPXSLOPE  -NOMVAR SLP0 -IP1 0
      fstdfield define GPXSLOPEN -NOMVAR SLP  -IP1 0
      fstdfield define GPXSLOPEE -NOMVAR SLP  -IP1 90
      fstdfield define GPXSLOPES -NOMVAR SLP  -IP1 180
      fstdfield define GPXSLOPEW -NOMVAR SLP  -IP1 270

      fstdfield write GPXASPEC  GPXSECFILE -24 True
      fstdfield write GPXASPECN GPXSECFILE -24 True
      fstdfield write GPXASPECE GPXSECFILE -24 True
      fstdfield write GPXASPECS GPXSECFILE -24 True
      fstdfield write GPXASPECW GPXSECFILE -24 True

      fstdfield write GPXSLOPE  GPXSECFILE -24 True
      fstdfield write GPXSLOPEN GPXSECFILE -24 True
      fstdfield write GPXSLOPEE GPXSECFILE -24 True
      fstdfield write GPXSLOPES GPXSECFILE -24 True
      fstdfield write GPXSLOPEW GPXSECFILE -24 True
   }

   fstdfield free GPXSLOPE GPXSLOPEN GPXSLOPEE GPXSLOPES GPXSLOPEW GPXASPEC GPXASPECN GPXASPECE GPXASPECS GPXASPECW
   gdalband free DEMTILE
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

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageMask Start" 1
   GenX::GridClear $Grid 0.0

   #----- Loop over files
   foreach file [glob $GenX::Path(DBase)/$GenX::Path(Mask)/*] {
      GenX::Trace "   Processing file : $file" 2
      fstdfile open GPXMASKFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXMASKFILE -1 "" -1 -1 -1 "" "MG"] {
         GenX::Trace "      Processing field : $field" 2
         fstdfield read GPXTILE GPXMASKFILE $field
         fstdfield stats GPXTILE -nodata -99.0

         #----- Average on output grid
         fstdfield gridinterp $Grid GPXTILE AVERAGE False
      }
      fstdfile close GPXMASKFILE
   }

   #----- Save output
   fstdfield gridinterp $Grid - NOP True
   fstdfield define $Grid -NOMVAR MG -IP1 0
   vexpr $Grid ifelse($Grid==-99.0,0.0,$Grid/100.0)
   fstdfield write $Grid GPXOUTFILE -24 True
   fstdfield free GPXTILE
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
   variable Data

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageMaskCANVEC: Averaging Mask" 1

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   GenX::GridClear $Grid 0.0

   #----- Loop over files
   foreach file [GenX::CANVECFindFiles $lat0 $lon0 $lat1 $lon1 { HD_1480009_2 } ] {
      GenX::Trace "   Processing file $file" 2
      ogrfile open CANVECFILE read $file
      ogrlayer read CANVECTILE CANVECFILE 0
      fstdfield gridinterp $Grid CANVECTILE ALIASED 1.0
      ogrfile close CANVECFILE
   }

   #----- Use whatever we have for US
   ogrfile open USLAKESFILE read $GenX::Path(Various)/mjwater.shp
   ogrlayer read USLAKES USLAKESFILE 0
   fstdfield gridinterp $Grid USLAKES ALIASED 1.0
   ogrfile close USLAKESFILE

   vexpr $Grid 1.0-clamp($Grid,0.0,1.0)

   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" 1200 -1 -1 "" "ME"]]] } {
      fstdfield read GPXME GPXOUTFILE $idx
      if { [lindex [fstdfield stats GPXME -max] 0]>0.0 } {
         vexpr $Grid ifelse($Grid>0.0 && GPXME==0.0,0.0,$Grid)
      }
      fstdfield free GPXME
   }

   fstdfield define $Grid -NOMVAR MG -IP1 0 -IP2 0 -IP3 0
   fstdfield write $Grid GPXOUTFILE -24 True

   ogrlayer free USLAKES CANVECTILE
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
   variable Data

   #----- Fix Consistency between MG and VF type 1
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
      vexpr GPXX GPXVF()()(0)=ifelse(GPXMG==0.0 && GPXVF()()(2)==0.0,1.0,GPXVF()()(0))
   } else {
      GenX::Trace "GeoPhysX::DominantVege: (Warning) Could not find mask field MG, will not do the conscitency check between MG and VF(1)" 0
   }

   #----- Save the 26 Vege types
   fstdfield define GPXVF -NOMVAR VF -IP2 0 -IP3 0
   fstdfield stats GPXVF -levels $Data(VegeTypes) -leveltype UNDEFINED
   fstdfield write GPXVF GPXOUTFILE -24 True

   #----- Generate VG field (Dominant type per cell)
   fstdfield copy GPXVG $Grid
   GenX::GridClear [list GPXVG $Grid] 0.0
   foreach type $Data(VegeTypes) {
      set k [expr $type-1]
      vexpr GPXK  GPXVF()()($k)
      vexpr GPXVG ifelse($Grid>=GPXK,GPXVG,$type)
      vexpr $Grid ifelse($Grid>=GPXK,$Grid,GPXK)
   }
   fstdfield define GPXVG -NOMVAR VG -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXVG GPXOUTFILE -24 True

   #----- Generate GA field (glacier = VF type 2 = VF level 1)
   vexpr GPXGA GPXVF()()(1)
   fstdfield define GPXGA -NOMVAR GA -IP1 0 -IP2 0 -IP3 0
   fstdfield write  GPXGA GPXOUTFILE -24 True

   fstdfield free GPXVG GPXK GPXMG GPXGA
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
   variable Data

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageVege Start" 1
   fstdfield copy GPXVF $Grid
   GenX::GridClear [list GPXVF $Grid] 0.0

   #----- Loop over files
   foreach file [glob $GenX::Path(DBase)/$GenX::Path(Vege)/*] {
      GenX::Trace "   Processing file : $file" 2
      fstdfile open GPXVEGEFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXVEGEFILE -1 "" -1 -1 -1 "" "VG"] {
         GenX::Trace "      Processing field : $field" 2
         fstdfield read GPXTILE GPXVEGEFILE $field
         fstdfield stats GPXTILE -nodata -99.0

         #----- Count percentage for each type
         fstdfield gridinterp GPXVF GPXTILE NORMALIZED_COUNT $Data(VegeTypes) False
      }
      fstdfile close GPXVEGEFILE
   }

   fstdfield gridinterp GPXVF - NOP True

   #----- Calculate Dominant type and save
   GeoPhysX::DominantVege $Grid

   fstdfield free GPXTILE GPXVF
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
   variable Data

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageVegeEOSD: Averaging EOSD vegetation data" 1

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]

   #----- Pour la conversion des classes EOSD vers les classes RPN
   vector create FROMEOSD { 0 11 12 20 21 31 32 33 40 51 52 81 82 83 100 211 212 213 221 222 223 231 232 233 }
   #----- Correspondance de Stéphane Bélair du 6 novembre 2007
   vector create TORPN  { -99 -99 -99 3 1 2 24 24 22 10 10 25 10 13 14 4 4 4 7 7 7 25 25 25 }

   fstdfield copy GPXVF $Grid
   GenX::GridClear [list GPXVF $Grid] 0.0

#   ogrfile open COASTALFILE read $GenX::Path(Various)/ghy_000f06a_e.shp
#   eval ogrlayer read COASTAL COASTALFILE 0

   #----- Loop over files

   if { [llength [set files [GenX::EOSDFindFiles $lat0 $lon0 $lat1 $lon1]]] } {
      foreach file $files {
         GenX::Trace "   Processing file $file" 2
         gdalband read EOSDTILE [gdalfile open EOSDFILE read $file]
         gdalband stats EOSDTILE -nodata -99

         #----- We have to maks some data since they might overlap a bit
         gdalband copy EOSDMASK EOSDTILE
         vexpr EOSDMASK EOSDMASK<<0

         #----- Burn NTS limits and mask EOSD
         set nts [string range [file tail $file] 0 3]
         GenX::Trace "      Applying NTS($nts) Limit mask" 2
         ogrlayer define NTSLAYER250K -featureselect [list [list SNRC == $nts]]
         gdalband gridinterp EOSDMASK NTSLAYER250K FAST 1
         vexpr EOSDTILE ifelse(EOSDMASK,EOSDTILE,0)

         #----- Burn COASTAL Waters mask EOSD to Salt water
#         GenX::Trace "      Burning Coastal Water" 2
#         vexpr EOSDMASK EOSDMASK<<0
#         gdalband gridinterp EOSDMASK COASTAL FAST 1

#         GenX::Trace "      Applying Sea water mask" 2
#         vexpr EOSDTILE ifelse(EOSDTILE==20 && EOSDMASK==1,21,EOSDTILE)

         vexpr EOSDTILE lut(EOSDTILE,FROMEOSD,TORPN)
         fstdfield gridinterp GPXVF EOSDTILE NORMALIZED_COUNT $Data(VegeTypes) False
         gdalband free EOSDTILE EOSDMASK
         gdalfile close EOSDFILE
      }
      gdalband free EOSDTILE
      vector free FROMEOSD TORPN
      ogrlayer define NTSLAYER250K -featureselect {}
#      ogrlayer free COASTAL
#      ogrfile close COASTALFILE

      fstdfield gridinterp GPXVF - NOP True

      #----- Calculate Dominant type and save
      GeoPhysX::DominantVege $Grid
   } else {
      GenX::Trace "GeoPhysX::AverageVegeEOSD: (Warning) The grid is not within EOSD limits, Vege fields will not be generated" 0
   }
   fstdfield free GPXVF GPXK
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
   variable Data

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageVegeCORINE: Averaging CORINE vegetation data" 1

   #----- Pour la conversion des classes CORINE vers les classes RPN
   vector create FROMCORINE { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 }
   #----- Correspondance de Janna Lindenberg de decembre 2007
   vector create TORPN  { 21 21 21 21 21 21 24 24 24 14 20 20 20 16 18 18 18 18 18 18 18 18 5 5 25 14 14 14 14 14 24 10 10 2 11 11 1 1 1 1 1 1 1 1 }

   fstdfield copy GPXVF $Grid
   GenX::GridClear [list GPXVF $Grid] 0.0

   #----- Open the file
   gdalfile open CORINEFILE read $GenX::Path(CORINE)/lceugr100_00_pct.tif

   #----- Loop over the data by tiles since it's too big to fit in memory
   for { set x 0 } { $x<[gdalfile width CORINEFILE] } { incr x $GenX::Data(TileSize) } {
      for { set y 0 } { $y<[gdalfile height CORINEFILE] } { incr y $GenX::Data(TileSize) } {
         GenX::Trace "   Processing tile $x $y [expr $x+$GenX::Data(TileSize)] [expr $y+$GenX::Data(TileSize)]" 2
         gdalband read CORINETILE { { CORINEFILE 1 } } $x $y [expr $x+$GenX::Data(TileSize)] [expr $y+$GenX::Data(TileSize)]
         gdalband stats CORINETILE -nodata 255

         vexpr CORINETILE lut(CORINETILE,FROMCORINE,TORPN)
         fstdfield gridinterp GPXVF CORINETILE NORMALIZED_COUNT $Data(VegeTypes) False
      }
   }
   fstdfield gridinterp GPXVF - NOP True

   #----- Calculate Dominant type and save
   GeoPhysX::DominantVege $Grid

   gdalband free CORINETILE
   gdalfile close CORINEFILE
   vector free FROMECORINE TORPN
   fstdfield free GPXVF
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
   variable Data

   GenX::Procs
   fstdfield copy GPXTMP $Grid
   fstdfield read GPXGA GPXOUTFILE -1 "" -1 -1 -1 "" "GA"

   #----- Boucle sur les types
   foreach type $Data(SandTypes) {
      GenX::Trace "   GeoPhysX::AverageSand Start ($type)" 1
      GenX::GridClear [list $Grid GPXTMP] 0.0

      #----- Loop over datasets
      foreach path $GenX::Path(Sand) {
         fstdfield clear GPXTMP

         #----- Loop over files
         foreach file [glob $GenX::Path(DBase)/$path/*] {
            GenX::Trace "      Processing file : $file" 2
            fstdfile open GPXSANDFILE read $file

            #----- Loop over fields (tiles)
            foreach field [fstdfield find GPXSANDFILE -1 "" -1 -1 $type "" "SB"] {
               GenX::Trace "         Processing field : $field" 2
               fstdfield read GPXTILE GPXSANDFILE $field
               vexpr GPXTILE max(GPXTILE,0.0)
               fstdfield stats GPXTILE -nodata 0.0

               #----- Average on each output grid
               fstdfield gridinterp GPXTMP GPXTILE AVERAGE False
            }
            fstdfile close GPXSANDFILE
         }
         fstdfield gridinterp GPXTMP - NOP True
         vexpr $Grid ifelse($Grid==0.0,GPXTMP,$Grid)
      }

      #----- Save output
      vexpr $Grid ifelse(GPXGA==1.0,43.0,$Grid)
      fstdfield define $Grid -NOMVAR J1 -IP1 [expr 1200-$type]
      fstdfield write $Grid GPXOUTFILE -24 True
   }
   fstdfield free GPXTMP GPXTILE GPXGA
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
   variable Data

   GenX::Procs
   fstdfield copy GPXTMP $Grid
   fstdfield read GPXGA GPXOUTFILE -1 "" -1 -1 -1 "" "GA"

   #----- Loop over types
   foreach type $Data(ClayTypes) {
      GenX::Trace "   GeoPhysX::AverageClay Start ($type)" 1
      GenX::GridClear [list $Grid GPXTMP] 0.0

      #----- Loop over datasets
      foreach path $GenX::Path(Clay) {
         fstdfield clear GPXTMP

         #----- Loop over files
         foreach file [glob $GenX::Path(DBase)/$path/*] {
            GenX::Trace "      Processing file : $file" 2
            fstdfile open GPXCLAYFILE read $file

            #----- Loop over fields (tiles)
            foreach field [fstdfield find GPXCLAYFILE -1 "" -1 -1 $type "" "AG"] {
               GenX::Trace "         Processing field : $field" 2
               fstdfield read GPXTILE GPXCLAYFILE $field
               vexpr GPXTILE max(GPXTILE,0.0)
               fstdfield stats GPXTILE -nodata 0.0

               #----- Average on each output grid
               fstdfield gridinterp GPXTMP GPXTILE AVERAGE False
            }
            fstdfile close GPXCLAYFILE
         }
         fstdfield gridinterp GPXTMP - NOP True
         vexpr $Grid ifelse($Grid==0.0,GPXTMP,$Grid)
      }

      #----- Save output
      vexpr $Grid ifelse(GPXGA==1.0,19.0,$Grid)
      fstdfield define $Grid -NOMVAR J2 -IP1 [expr 1200-$type]
      fstdfield write $Grid GPXOUTFILE -24 True
   }
   fstdfield free GPXTMP GPXTILE GPXGA
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::AverageTopoLD>
# Creation : Septembre 2007 - Ayrton Zadra - CMC/CMOE
#
# Goal     : Generate the topo from low and high res data sampling for scale separation.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topo
#   <Type>   : Type of sampling to use
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::AverageTopoLD { Grids Type } {

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageTopoLD Start" 1
   GenX::GridClear $Grids -99.0
   fstdfield copy GPXHME [lindex $Grids 0]
   GenX::GridClear [list GPXHME] 0.0

   #----- Loop over files
   foreach file [glob $GenX::Path(DBase)/$GenX::Path(Topo$Type)/*] {
      GenX::Trace "   Processing file : $file" 2
      fstdfile open GPXTOPOFILE read $file

      #----- Loop over fields (tiles)
      foreach field [fstdfield find GPXTOPOFILE -1 "" -1 -1 -1 "" "ME"] {
         GenX::Trace "      Processing field : $field" 2
         fstdfield read GPXTILE GPXTOPOFILE $field
         fstdfield stats GPXTILE -nodata 0.0

         #----- compute average of <Hhr^2>ij on target grid
         vexpr GPXTILE1 (GPXTILE*GPXTILE)
         fstdfield gridinterp GPXHME GPXTILE1 AVERAGE False

         #----- Average on each output grid
         foreach grid $Grids {
            fstdfield gridinterp $grid GPXTILE AVERAGE False
         }
      }
      fstdfile close GPXTOPOFILE
   }

   #----- Save output
   foreach grid $Grids {
      fstdfield gridinterp $grid - NOP True
      vexpr $grid ifelse($grid==-99.0,0.0,$grid)
      fstdfield define $grid -NOMVAR ME${Type} -IP1 0 -IP2 0 -IP3 0
      fstdfield write $grid GPXSECFILE -24 True
   }

   #----- save <Hhr^2>ij
   fstdfield gridinterp GPXHME - NOP True
   vexpr GPXHME ifelse(GPXHME>0.0,GPXHME^0.5,0.0)
   fstdfield define GPXHME -NOMVAR ME${Type}2 -IP1 0
   fstdfield write GPXHME GPXSECFILE -24 True

   fstdfield free GPXTILE GPXTILE1 GPXHME
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

   GenX::Procs
   GenX::Trace "GeoPhysX::AverageGradient Correlation(Y789) Start" 1
   fstdfield copy GPXGXX $Grid
   fstdfield copy GPXGYY $Grid
   fstdfield copy GPXGXY $Grid

   GenX::GridClear [list GPXGXX GPXGYY GPXGXY $Grid] 0.0

   #----- compute Gxx, Gyy, Gxy
   foreach file [glob $GenX::Path(DBase)/$GenX::Path(Gxy)/*] {
      GenX::Trace "   Processing file: $file " 2
      fstdfile open GPXGXYFILE read $file
      foreach field_gx [fstdfield find GPXGXYFILE -1 "" -1 -1 -1 "" "GX"] \
              field_gy [fstdfield find GPXGXYFILE -1 "" -1 -1 -1 "" "GY"] {
          GenX::Trace "      Processing field : $field_gx" 2
          fstdfield read GPXTILE1 GPXGXYFILE $field_gx
          fstdfield stats GPXTILE1 -nodata 0

          GenX::Trace "      Processing field : $field_gy" 2
          fstdfield read GPXTILE2 GPXGXYFILE $field_gy
          fstdfield stats GPXTILE2 -nodata 0

          #----- Compute correlation Gxx
          vexpr GPXTILE1X (GPXTILE1*GPXTILE1)
          fstdfield gridinterp GPXGXX GPXTILE1X AVERAGE False

          #----- Compute correlation Gyy
          vexpr GPXTILE2Y (GPXTILE2*GPXTILE2)
          fstdfield gridinterp GPXGYY GPXTILE2Y AVERAGE False

          #----- Compute correlation Gxy
          vexpr GPXTILE (GPXTILE1*GPXTILE2)
          fstdfield gridinterp GPXGXY GPXTILE AVERAGE False
      }
      fstdfile close GPXGXYFILE
   }

   #----- Save output
   fstdfield gridinterp GPXGXX - NOP True
   fstdfield define GPXGXX -NOMVAR GXX -IP1 0
   fstdfield write GPXGXX GPXSECFILE -32 True

   fstdfield gridinterp GPXGYY - NOP True
   fstdfield define GPXGYY -NOMVAR GYY -IP1 0
   fstdfield write GPXGYY GPXSECFILE -32 True

   fstdfield gridinterp GPXGXY - NOP True
   fstdfield define GPXGXY -NOMVAR GXY -IP1 0
   fstdfield write GPXGXY GPXSECFILE -32 True

   fstdfield free GPXTILE GPXTILE1 GPXTILE2 GPXTILE1X GPXTILE2Y GPXGXX GPXGYY GPXGXY
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

proc GeoPhysX::AverageAspect { Grid Band } {

   #----- Calculate slope and aspect for the tile
   vexpr SLOPETILE dslopedeg($Band)
   vexpr ASPECTILE daspect($Band)

   #----- Define aspect ranges
   vexpr ASPECN ifelse(ASPECTILE>315 || ASPECTILE<=45,SLOPETILE!=0.0,-1)
   vexpr ASPECE ifelse(ASPECTILE>45 && ASPECTILE<=135,SLOPETILE!=0.0,-1)
   vexpr ASPECS ifelse(ASPECTILE>135 && ASPECTILE<=225,SLOPETILE!=0.0,-1)
   vexpr ASPECW ifelse(ASPECTILE>225 && ASPECTILE<=315,SLOPETILE!=0.0,-1)

   #----- Set slope mask on the aspect ranges
   vexpr SLOPEN  ifelse(ASPECN!=-1,SLOPETILE,-1)
   vexpr SLOPEE  ifelse(ASPECE!=-1,SLOPETILE,-1)
   vexpr SLOPES  ifelse(ASPECS!=-1,SLOPETILE,-1)
   vexpr SLOPEW  ifelse(ASPECW!=-1,SLOPETILE,-1)

   gdalband stats ASPECN -nodata -1
   gdalband stats ASPECE -nodata -1
   gdalband stats ASPECS -nodata -1
   gdalband stats ASPECW -nodata -1
   gdalband stats SLOPEN -nodata -1
   gdalband stats SLOPEE -nodata -1
   gdalband stats SLOPES -nodata -1
   gdalband stats SLOPEW -nodata -1

   #----- Do the averaging on destination grid
   fstdfield gridinterp GPXASPECN ASPECN COUNT False
   fstdfield gridinterp GPXASPECE ASPECE COUNT False
   fstdfield gridinterp GPXASPECS ASPECS COUNT False
   fstdfield gridinterp GPXASPECW ASPECW COUNT False

   fstdfield gridinterp GPXSLOPEN SLOPEN AVERAGE False
   fstdfield gridinterp GPXSLOPEE SLOPEE AVERAGE False
   fstdfield gridinterp GPXSLOPES SLOPES AVERAGE False
   fstdfield gridinterp GPXSLOPEW SLOPEW AVERAGE False

   fstdfield gridinterp GPXASPEC  ASPECTILE AVERAGE False
   fstdfield gridinterp GPXSLOPE  SLOPETILE AVERAGE False
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::PostCorrectionFilter>
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
#   <C3>       :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GeoPhysX::PostCorrectionFilter { FieldRes FieldDX FieldDY DBR C1 C2 C3 } {

   GenX::Procs
   vexpr GPXAN exp(-1.0*$C1*($C2*($FieldDX/$DBR)-$C3))
   vexpr GPXFX 0.5*(1.0+(1.0-GPXAN)/(1.0+GPXAN))

   vexpr GPXAN exp(-1.0*$C1*($C2*($FieldDY/$DBR)-$C3))
   vexpr GPXFY 0.5*(1.0+(1.0-GPXAN)/(1.0+GPXAN))

   vexpr $FieldRes 0.5*(GPXFX+GPXFY)

   fstdfield free GPXAN GPXFX GPXFY
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::PostCorrectionFactor>
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
proc GeoPhysX::PostCorrectionFactor { } {
   variable Const

   GenX::Procs
   fstdfield read GPXMG GPXOUTFILE -1 "" -1 -1 -1 "" "MG"

   #----- For low-res and hi-res
   GenX::Trace "GeoPhysX::PostCorrectionFactor Computing low and high res fields" 1

   vexpr GPXDX ddx(GPXMG)
   vexpr GPXDY ddy(GPXMG)

   GeoPhysX::PostCorrectionFilter GPXFLR GPXDX GPXDY $Const(lres) 2.0 4.0 8.0
   GeoPhysX::PostCorrectionFilter GPXFHR GPXDX GPXDY $Const(hres) 2.0 1.0 7.5

   fstdfield define GPXFLR -NOMVAR FLR -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXFLR GPXSECFILE -24 True
   fstdfield define GPXFHR -NOMVAR FHR -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXFHR GPXSECFILE -24 True

   #----- For low-res and hi-res (over land only)
   GenX::Trace "GeoPhysX::PostCorrectionFactor Computing low and high res fields over land only" 1

   vexpr GPXDX GPXDX*sqrt(GPXMG)
   vexpr GPXDY GPXDY*sqrt(GPXMG)

   GeoPhysX::PostCorrectionFilter GPXFLR GPXDX GPXDY $Const(lres) 2.0 4.0 8.0
   GeoPhysX::PostCorrectionFilter GPXFHR GPXDX GPXDY $Const(hres) 2.0 1.0 7.5

   fstdfield define GPXFLR -NOMVAR FLRP -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXFLR GPXSECFILE -24 True
   fstdfield define GPXFHR -NOMVAR FHRP -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXFHR GPXSECFILE -24 True

   fstdfield free GPXMG GPXDX GPXDY GPXFLR GPXFHR
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::PostTopoFilter>
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
proc GeoPhysX::PostTopoFilter { } {

   GenX::Procs
   fstdfield read GPXMF GPXOUTFILE -1 "" 1200 -1 -1 "" "ME"

   GenX::Trace "GeoPhysX::PostTopoFilter Filtering ME" 1
   fstdgrid zfilter GPXMF GenX::Settings
   fstdfield define GPXMF -NOMVAR MF -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXMF GPXOUTFILE -24 True

   fstdfield free GPXMF
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::PostLaunchingHeight>
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
proc GeoPhysX::PostLaunchingHeight { } {
   variable Const

   GenX::Procs
   fstdfield read GPXMEL  GPXSECFILE -1 "" -1 -1 -1 "" "MEL"
   fstdfield read GPXMEL2 GPXSECFILE -1 "" -1 -1 -1 "" "MEL2"
   fstdfield read GPXFLR  GPXSECFILE -1 "" -1 -1 -1 "" "FLR"
   fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG"

   vexpr GPXMEL  GPXMEL *GPXFLR
   vexpr GPXMEL2 GPXMEL2*GPXFLR

#  Corrected fields (based on resolution criteria)
#  TODO

   GenX::Trace "GeoPhysX::PostLaunchingHeight Computing launching height LH" 1
   vexpr GPXLH 2.0*GPXMG*((GPXMEL2^2 - GPXMEL^2)^0.5)
   vexpr GPXLH ifelse(GPXLH>=$Const(lhmin),GPXLH,0.0)
   fstdfield define GPXLH -NOMVAR LH -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXLH GPXOUTFILE -32 True

   fstdfield free GPXLH GPXMEL GPXMEL2 GPXMG GPXFLR
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::PostY789>
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
proc GeoPhysX::PostY789 { } {
   variable Const

   GenX::Procs
   fstdfield read GPXGXX  GPXSECFILE -1 "" -1 -1 -1 "" "GXX"
   fstdfield read GPXGYY  GPXSECFILE -1 "" -1 -1 -1 "" "GYY"
   fstdfield read GPXGXY  GPXSECFILE -1 "" -1 -1 -1 "" "GXY"
   fstdfield read GPXFLR  GPXSECFILE -1 "" -1 -1 -1 "" "FLR"
   fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG"
   fstdfield read GPXLH   GPXOUTFILE -1 "" -1 -1 -1 "" "LH"

   vexpr GPXGXX GPXGXX*GPXFLR
   vexpr GPXGYY GPXGYY*GPXFLR
   vexpr GPXGXY GPXGXY*GPXFLR

#  Corrected fields (based on resolution criteria)
#  TODO

   #----- Compute angle and angle factors

   vexpr GPXALP  (dangle(GPXGXX))*3.14159265/180.
   vexpr GPXCOSA cos(GPXALP)
   vexpr GPXSINA sin(GPXALP)

   fstdfield define GPXALP -NOMVAR ALP -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXALP GPXSECFILE -32 True

   GenX::Trace "GeoPhysX::PostY789 Computing Y7" 1
   vexpr GPXY789 GPXMG*(GPXGXX*(GPXCOSA^2) + GPXGYY*(GPXSINA^2) - 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y7 -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXY789 GPXOUTFILE -32 True

   GenX::Trace "GeoPhysX::PostY789 Computing Y8" 1
   vexpr GPXY789 GPXMG*(GPXGXX*(GPXSINA^2) + GPXGYY*(GPXCOSA^2) + 2.0*GPXGXY*GPXSINA*GPXCOSA)
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y8 -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXY789 GPXOUTFILE -32 True

   GenX::Trace "GeoPhysX::PostY789 Computing Y9" 1
   vexpr GPXY789 GPXMG*((GPXGXX-GPXGYY)*GPXSINA*GPXCOSA + GPXGXY*(GPXCOSA^2-GPXSINA^2))
   vexpr GPXY789 ifelse(GPXLH>$Const(lhmin),GPXY789,0.0)
   fstdfield define GPXY789 -NOMVAR Y9 -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXY789 GPXOUTFILE -32 True

   fstdfield free GPXGXX GPXGYY GPXGXY GPXMG GPXFLR GPXALP GPXCOSA GPXSINA GPXMG GPXLH GPXY789
}

#----------------------------------------------------------------------------
# Name     : <GeoPhysX::PostRoughnessLength>
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
proc GeoPhysX::PostRoughnessLength { } {
   variable Data
   variable Const

   GenX::Procs
   fstdfield read GPXMED  GPXSECFILE -1 "" -1 -1 -1 "" "MED"
   fstdfield read GPXMED2 GPXSECFILE -1 "" -1 -1 -1 "" "MED2"
   fstdfield read GPXFHR  GPXSECFILE -1 "" -1 -1 -1 "" "FHR"
   fstdfield read GPXFHRP GPXSECFILE -1 "" -1 -1 -1 "" "FHRP"
   fstdfield read GPXMG   GPXOUTFILE -1 "" -1 -1 -1 "" "MG"

   vexpr GPXMED  GPXMED *GPXFHRP
   vexpr GPXMED2 GPXMED2*GPXFHRP

   GenX::Trace "GeoPhysX::PostRoughnessLength Computing subgrid-scale variance" 1
   vexpr GPXSSS (GPXMED2^2 - GPXMED^2)
   vexpr GPXSSS ifelse(GPXSSS>0.0,GPXSSS^0.5,0.0)

#  to be tested...?

   vexpr GPXSSS ifelse(GPXMG>$Const(mgmin),GPXSSS/GPXMG,0.0)
   fstdfield define GPXSSS -NOMVAR SSS -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXSSS GPXSECFILE -32 True

   GenX::Trace "GeoPhysX::PostRoughnessLength Computing h_coef" 1
   vexpr GPXHCOEF (1.5 - 0.5*(GPXSSS-20.0)/680.0)
   vexpr GPXHCOEF ifelse(GPXSSS>700.0,1.0,GPXHCOEF)
   fstdfield define GPXHCOEF -NOMVAR HCOF -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXHCOEF GPXSECFILE -32 True

   GenX::Trace "GeoPhysX::PostRoughnessLength Computing z_ref" 1
   vexpr GPXZREF (GPXHCOEF*GPXSSS)
   vexpr GPXZREF ifelse(GPXZREF<10.0,0.0,GPXZREF)
   vexpr GPXZREF ifelse(GPXZREF>1500.0,1500.0,GPXZREF)
   fstdfield define GPXZREF -NOMVAR ZREF -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZREF GPXSECFILE -32 True

   GenX::Trace "GeoPhysX::PostRoughnessLength Computing slope factor" 1
   vexpr GPXSLP (GPXHCOEF*GPXHCOEF*GPXSSS/$Const(dbl))
   fstdfield define GPXSLP -NOMVAR SLP -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXSLP GPXSECFILE -32 True

   GenX::Trace "GeoPhysX::PostRoughnessLength Computing Z0_topo" 1
   vexpr GPXZTP ifelse(GPXSLP>$Const(slpmin) || GPXZREF>$Const(zrefmin),1.0+GPXZREF*exp(-$Const(karman)/sqrt(0.5*$Const(drgcoef)*GPXSLP)),0.0)
   fstdfield define GPXZTP -NOMVAR ZTOP -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZTP GPXSECFILE -32 True

   #----- Local (vegetation) roughness length
   fstdfield read GPXZ0V1 GPXOUTFILE -1 "" 1199 -1 -1 "" "VF"
   fstdfield copy GPXZ0V2 GPXZ0V1
   GenX::GridClear { GPXZ0V1 GPXZ0V2 } 0.0

   GenX::Trace "GeoPhysX::PostRoughnessLength Computing overall vege roughness" 1
   foreach element $Data(VegeTypes) zzov $Data(VegeZ0vTypes) {
      set ip1 [expr 1200-$element]
      fstdfield read GPXVF GPXOUTFILE -1 "" $ip1 -1 -1 "" "VF"
      vexpr GPXZ0V1 (GPXZ0V1+GPXVF*$zzov)
      vexpr GPXZ0V2 (GPXZ0V2+GPXVF)
   }
   vexpr GPXZ0V1 ifelse(GPXZ0V2>0.001,GPXZ0V1/GPXZ0V2,0.0)
   fstdfield define GPXZ0V1 -NOMVAR ZVG1 -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZ0V1 GPXSECFILE -32 True

   GenX::Trace "GeoPhysX::PostRoughnessLength Computing local vege roughness" 1
   GenX::GridClear { GPXZ0V1 GPXZ0V2 } 0.0
   foreach element [lrange $Data(VegeTypes) 3 end] zzov [lrange $Data(VegeZ0vTypes) 3 end] {
      set ip1 [expr 1200-$element]
      fstdfield read GPXVF GPXOUTFILE -1 "" $ip1 -1 -1 "" "VF"
      vexpr GPXZ0V1 (GPXZ0V1+GPXVF*$zzov)
      vexpr GPXZ0V2 (GPXZ0V2+GPXVF)
   }
   vexpr GPXZ0V1 ifelse(GPXZ0V2>0.001,GPXZ0V1/GPXZ0V2,0.0)
   fstdfield define GPXZ0V1 -NOMVAR ZVG2 -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZ0V1 GPXSECFILE -32 True

   #----- Roughness length over soil
   fstdfield read GPXGA GPXOUTFILE -1 "" 1198 -1 -1 "" "VF"

   vexpr GPXW1  ifelse(GPXZTP>0.0  && GPXZREF>GPXZTP , ((1.0-GPXGA)/ln(GPXZREF/GPXZTP))^2.0, 0.0)
   vexpr GPXW2  ifelse(GPXZ0V1>0.0 && GPXZREF>GPXZ0V1, (1.0/ln(GPXZREF/GPXZ0V1))^2.0       , 0.0)
   vexpr GPXZ0S ifelse((GPXW1+GPXW2)>0.0             , GPXZREF*exp( -1.0/sqrt(GPXW1+GPXW2)), 0.0)
   vexpr GPXZ0S ifelse(GPXZREF<10.0                  , GPXZ0V1                             , GPXZ0S)
   fstdfield define GPXZ0S -NOMVAR Z0S -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZ0S GPXSECFILE -32 True

   vexpr GPXZPS ifelse(GPXZ0S>0.0,ln(GPXZ0S),0.0)
   fstdfield define GPXZPS -NOMVAR ZPS -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZPS GPXSECFILE -32 True

   #----- Roughness length over glaciers
   vexpr GPXW1  ifelse(GPXZTP>0.0 && GPXZREF>GPXZTP, (GPXGA/ln(GPXZREF/GPXZTP))^2.0     , 0.0)
   vexpr GPXW2  ifelse(GPXZREF>$Const(gaz0)        , (1.0/ln(GPXZREF/$Const(gaz0)))^2.0 , 0.0)
   vexpr GPXZ0G ifelse((GPXW1+GPXW2)>0.0           , GPXZREF*exp(-1.0/sqrt(GPXW1+GPXW2)), 0.0)
   vexpr GPXZ0G ifelse(GPXZREF<10.0                , $Const(gaz0)                       , GPXZ0G)
   vexpr GPXZ0G ifelse(GPXGA>0.0                   , GPXZ0G                             , 0.0)
   fstdfield define GPXZ0G -NOMVAR Z0G -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZ0G GPXSECFILE -32 True

   vexpr GPXZPG ifelse(GPXZ0G>0.0,ln(GPXZ0G),0.0)
   fstdfield define GPXZPG -NOMVAR ZPG -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZPG GPXSECFILE -32 True

   #----- Fill some gaps
   vexpr GPXZ0S ifelse(GPXMG>$Const(mgmin) && GPXZTP<$Const(z0min) && GPXZ0V1<$Const(z0min) && GPXZ0G<$Const(z0min),$Const(z0def),GPXZ0S)
   fstdfield define GPXZ0S -NOMVAR Z0S -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZ0S GPXSECFILE -32 True
   vexpr GPXZPS ifelse(GPXZ0S>0.0,ln(GPXZ0S),0.0)
   fstdfield define GPXZPS -NOMVAR ZPS -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZPS GPXSECFILE -32 True

   #----- Total roughness length
   vexpr GPXZP GPXMG*((1.0-GPXGA)*GPXZPS+GPXGA*GPXZPG)+(1.0-GPXMG)*ln(0.001)
   fstdfield define GPXZP -NOMVAR ZP -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZP GPXOUTFILE -32 True

   vexpr GPXZ0 exp(GPXZP)
   fstdfield define GPXZ0 -NOMVAR Z0 -IP1 0 -IP2 0 -IP3 0
   fstdfield write GPXZ0 GPXOUTFILE -32 True

   fstdfield free GPXLH GPXSSS GPXHCOEF GPXZREF GPXSLP GPXZTP GPXZ0S \
       GPXZ0V2 GPXZPS GPXGA GPXZ0G GPXZPG GPXZ0 GPXZ0V1 GPXZ0V2 GPXZP GPXMG GPXVF
}

proc GeoPhysX::PostCheckConsistency { } {

}