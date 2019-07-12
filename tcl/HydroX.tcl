#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : HydroX.tcl
# Creation   : August 2011 - J.P. Gauthier - CMC/CMOE
# Description: Definitions of functions related to hydrological fields
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#   HydroX::DrainDensity { Grid }
#
#============================================================================

namespace eval HydroX { } {
   variable Param
   variable Const
   global env

   set Param(Version)   0.1
}

#----------------------------------------------------------------------------
# Name     : <HydroX::DrainDensity>
# Creation : August 2011 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Calcule la densite de drainage sur une grille RPN en utilisant
#              des donnees vectorielles de lacs et rivieres (Shapefile)
#
#      somme(longueur cours d'eau) + somme(périmètre étendues d'eau)
#      -------------------------------------------------------------
#              aire de la maille - aire des étendues d'eau
#
# Parameters :
#   <Grid>   : Grid on which to generate the drain density
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc HydroX::DrainDensity { Grid } {
   variable Param

# see what database to use in $Param(Hydro)
   
   set NHN  0
   set NHD  0
   set HSRN 0
   set DCW  0

   foreach hdb  $GenX::Param(Hydro) {
      puts $hdb
      switch $hdb {
         "NHN"       { set  NHN  1  }
         "NHD"       { set  NHD  1  }
         "HSRN"      { set  HSRN 1  }
         "DCW"       { set  DCW  1  }
      }
   }

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
   } else {
      Log::Print WARNING "Could not find mask field MG"
   }

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   Log::Print DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)"

   #----- Creer les champs de calculs
   fstdfield copy GPXRIVERSUM $Grid
   fstdfield copy GPXLAKESUM  $Grid
   fstdfield copy GPXLAKEAREA $Grid

   GenX::GridClear [list $Grid GPXRIVERSUM GPXLAKESUM GPXLAKEAREA] 0.0

   set clipped_dcw  0
   set clipped_hsrn 0
   if { $HSRN } {
      set clipped_dcw  1
      if  { $NHD || $NHN } {
         set clipped_hsrn 1
# using either NHN or NHD would trigger the other when HSRN is used
         if { ! $NHN } {
            set NHN 1
         }
         if { ! $NHD } {
            set NHD 1
         }
      }
   }

   if { $HSRN } {
      HydroX::DrainDensityHSRN $Grid $la0 $lo0 $la1 $lo1 $clipped_hsrn
   }

# compute DCW values separately and take the maximum with HSRN
   if { $DCW } {
      fstdfield copy GPXRIVERSUM2 $Grid
      fstdfield copy GPXLAKESUM2  $Grid
      fstdfield copy GPXLAKEAREA2 $Grid

      HydroX::DrainDensityDCW $Grid $la0 $lo0 $la1 $lo1 $clipped_dcw

      vexpr GPXRIVERSUM  max(GPXRIVERSUM2,GPXRIVERSUM)
      vexpr GPXLAKESUM   max(GPXLAKESUM2,GPXLAKESUM)
      vexpr GPXLAKEAREA  max(GPXLAKEAREA2,GPXLAKEAREA)

      fstdfield free GPXRIVERSUM2 GPXLAKESUM2 GPXLAKEAREA2
   }

   if { $NHN } {
      HydroX::DrainDensityNHN  $Grid $la0 $lo0 $la1 $lo1
   }
   if { $NHD } {
      HydroX::DrainDensityNHD  $Grid $la0 $lo0 $la1 $lo1
   }

   #----- Effectuer le calculs de drainage
   if { [fstdfield is GPXMG] } {
      vexpr $Grid ifelse(GPXMG>=0.05,(GPXRIVERSUM+GPXLAKESUM)/(darea($Grid)*GPXMG),0)
      vexpr $Grid ifelse(GPXMG>0.0 && $Grid<0.00000001,0.001,$Grid)
   } else {
      vexpr $Grid (GPXRIVERSUM+GPXLAKESUM)/(darea($Grid)-GPXLAKEAREA)
   }

   if { [fstdfield is GPXMG] } {
      vexpr $Grid ifelse(GPXMG,$Grid,0)
   }

   #----- Sauvagerdons le tout

   fstdfield define $Grid -NOMVAR DRND -IP1 1200
   fstdfield write $Grid GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

#   fstdfield define GPXRIVERSUM -NOMVAR RSUM -IP1 1200
#   fstdfield write GPXRIVERSUM GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
#   fstdfield define GPXLAKESUM -NOMVAR LSUM -IP1 1200
#   fstdfield write GPXLAKESUM GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   if { ![fstdfield is GPXMG] } {
      fstdfield define GPXLAKEAREA -NOMVAR LARE -IP1 1200
      fstdfield write GPXLAKEAREA GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   fstdfield free GPXRIVERSUM GPXLAKESUM GPXLAKEAREA GPXMG
}

#----------------------------------------------------------------------------
# Name     : <HydroX::DrainDensityNHN>
# Creation : August 2011 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Calcule la densite de drainage sur une grille RPN en utilisant
#              des donnees vectorielles de lacs et rivieres (Shapefile)
#
#      somme(longueur cours d'eau) + somme(périmètre étendues d'eau)
#      -------------------------------------------------------------
#              aire de la maille - aire des étendues d'eau
#
# Parameters :
#   <Grid>   : Grid on which to generate the drain density
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc HydroX::DrainDensityNHN { Grid la0 lo0 la1 lo1 } {
   variable Param

   GenX::Procs NHN
   #----- Lire les donnees des rivieres Canadiennes de NHN

   set n 0
   set files [GenX::NHNFindFiles $la0 $lo0 $la1 $lo1]

   foreach path $files {
      Log::Print DEBUG "   Processing NHN path $path ([incr n]/[llength $files])"

      #----- Lire la donnee des rivieres
      if { [catch "glob ${path}_?_?_HD_COURSDEAU_1.shp" rivers] } {
         if { [catch "glob ${path}_?_?_RH_FILAMENT_1.shp" rivers] } {
            set rivers {}
            Log::Print DEBUG "  Cannot find river file for path $path"
         }
      }
      foreach file $rivers {
         set layers [ogrfile open FILERIVER read ${file}]
         ogrlayer read LINES FILERIVER 0

         fstdfield gridinterp GPXRIVERSUM LINES LENGTH_CONSERVATIVE FEATURE_LENGTH_METER

         ogrfile close FILERIVER
      }

      #----- Lire la donnee des lacs
      if { [catch "glob ${path}_?_?_HD_REGIONHYDRO_2.shp" lakes] } {
         set lakes {}
         Log::Print DEBUG "  Cannot find lakes file for path $path"
      }
      foreach file $lakes {
         set layers [ogrfile open FILELAKE read ${file}]
         ogrlayer read AREAS FILELAKE 0

         fstdfield gridinterp GPXLAKESUM  AREAS LENGTH_CONSERVATIVE FEATURE_LENGTH_METER

# we dont need lake area if we use MG
         if {  ![fstdfield is GPXMG] } {
            fstdfield gridinterp GPXLAKEAREA AREAS CONSERVATIVE FEATURE_AREA_METER
         }

         ogrfile close  FILELAKE
      }
   }

}

#----------------------------------------------------------------------------
# Name     : <HydroX::DrainDensityNHD>
# Creation : 
#
# Goal     : Calcule la densite de drainage sur une grille RPN en utilisant
#              des donnees vectorielles de lacs et rivieres (Shapefile)
#
#      somme(longueur cours d'eau) + somme(périmètre étendues d'eau)
#      -------------------------------------------------------------
#              aire de la maille - aire des étendues d'eau
#
# Parameters :
#   <Grid>   : Grid on which to generate the drain density
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc HydroX::DrainDensityNHD { Grid la0 lo0 la1 lo1 } {
   variable Param

   GenX::Procs NHD
   #----- Lire les donnees des rivieres USA de NHD
   set n 0
   set files  [GenX::NHDFindFiles $la0 $lo0 $la1 $lo1]

   set cnt  [llength $files]
   foreach file $files {
      Log::Print DEBUG "   Processing NHD file $file ([incr n]/$cnt)" False

      set layers [ogrfile open FILERIVER read ${file}]
      ogrlayer read LINES FILERIVER 0
      fstdfield gridinterp GPXRIVERSUM LINES LENGTH_CONSERVATIVE FEATURE_LENGTH_METER
      ogrfile close FILERIVER
   }

   ogrlayer free LINES AREAS
}

#----------------------------------------------------------------------------
# Name     : <HydroX::DrainDensityHSRN>
# Creation : 
#
# Goal     : Calcule la densite de drainage sur une grille RPN en utilisant
#              des donnees vectorielles de lacs et rivieres (Shapefile)
#
#      somme(longueur cours d'eau) + somme(périmètre étendues d'eau)
#      -------------------------------------------------------------
#              aire de la maille - aire des étendues d'eau
#
# Parameters :
#   <Grid>   : Grid on which to generate the drain density
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc HydroX::DrainDensityHSRN { Grid la0 lo0 la1 lo1 clipped } {
   variable Param

   GenX::Procs HSRN
   #----- Lire les donnees des rivieres USGS HydroSHEDS
   set n 0
   set usgsdir  $GenX::Param(DBase)/$GenX::Path(HSRN)
   if { $clipped } {
      set regions [GenX::FindFiles $usgsdir/Index/index_usgs_rn-na.shp $Grid]
   } else {
      set regions [GenX::FindFiles $usgsdir/Index/index_usgs_rn.shp $Grid]
   }
   
   set  n        0
   set  cnt      [llength $regions]
   foreach file $regions {
      Log::Print DEBUG "   Processing USGS HydroSHEDS file $file ([incr n]/$cnt)" False

      set layers [ogrfile open FILERIVER read ${usgsdir}${file}]
      ogrlayer read LINES FILERIVER 0
      fstdfield gridinterp GPXRIVERSUM LINES LENGTH_CONSERVATIVE FEATURE_LENGTH_METER
      ogrfile close FILERIVER
   }
}

#----------------------------------------------------------------------------
# Name     : <HydroX::DrainDensityDCW>
# Creation : 
#
# Goal     : Calcule la densite de drainage sur une grille RPN en utilisant
#              des donnees vectorielles de lacs et rivieres (Shapefile)
#
#      somme(longueur cours d'eau) + somme(périmètre étendues d'eau)
#      -------------------------------------------------------------
#              aire de la maille - aire des étendues d'eau
#
# Parameters :
#   <Grid>   : Grid on which to generate the drain density
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc HydroX::DrainDensityDCW { Grid la0 lo0 la1 lo1 clipped } {
   variable Param

   GenX::Procs DCW

   #----- Lire les donnees des rivieres de DCW
   set dcwdir  $GenX::Param(DBase)/$GenX::Path(DCW)

   if { $clipped } {
      set cells [GenX::FindFiles $dcwdir/Index/index_dcw_60_rivers.shp $Grid]
   } else {
      set cells [GenX::FindFiles $dcwdir/Index/index_dcw_rivers.shp $Grid]
   }
   foreach cfile $cells {
      set file  "$dcwdir/rivers/$cfile"
      Log::Print INFO "Processing : $file"
      ogrfile open RIVERFILE read $file
      ogrlayer read LINES RIVERFILE 0
      fstdfield gridinterp GPXRIVERSUM2 LINES  LENGTH_CONSERVATIVE FEATURE_LENGTH_METER
      ogrfile close RIVERFILE
   }

   if { $clipped } {
      set cells [GenX::FindFiles $dcwdir/Index/index_dcw_60_lakes.shp $Grid]
   } else {
      set cells [GenX::FindFiles $dcwdir/Index/index_dcw_lakes.shp $Grid]
   }
   foreach cfile $cells {
      set file  "$dcwdir/lakes/$cfile"
      Log::Print INFO "Processing : $file"
      ogrfile open LAKEFILE read $file
      ogrlayer read AREAS LAKEFILE 0
      fstdfield gridinterp GPXLAKESUM2 AREAS  LENGTH_CONSERVATIVE FEATURE_LENGTH_METER
# we dont need lake area if we use MG
      if {  ![fstdfield is GPXMG] } {
         fstdfield gridinterp GPXLAKEAREA2 AREAS CONSERVATIVE FEATURE_AREA_METER
      }
      ogrfile close LAKEFILE
   }
}

#----------------------------------------------------------------------------
# Name     : <HydroX::HydroLakesDepth>
# Creation : Nov 2018
#
# Goal     :  extract  lakes fraction and lakes depth from HydroLAKES
#            
#
#
# Parameters :
#   <LakeF>   : Grid on which to generate lake fraction
#   <LakeD>   : Grid on which to generate lake depth
#   <LakeA>   : Grid on which to generate lake surface
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc HydroX::HydroLakesDepth { Grid LakeF {LakeD ""} {LakeS ""} {LakeG ""} } {
   variable Param

   GenX::Procs HydroLAKES 

   if { [fstdfield is $LakeF] } {
      set Has_LakeF  1
   } else {
      set Has_LakeF  0
   }
   if { [fstdfield is $LakeD] } {
      # create a temporary LakeF to calculate LakeD
      if { $Has_LakeF == 0 } {
         set LakeF  "LakesFractionFLD"
         fstdfield copy $LakeF $Grid
         GenX::GridClear $LakeF 0.0
      }
   }

   set shp_dir  "$GenX::Param(DBase)/$GenX::Path(HYDROLAKES)"
   set regfiles [GenX::FindFiles $shp_dir/Index/Index.shp $Grid]

   set count [llength $regfiles]
   set n     0
   foreach file  $regfiles {
      set shp_file "$shp_dir$file"
      Log::Print INFO "   Processing shapefile $shp_file ([incr n]/$count)"
      set layer [ogrfile open LAYERFILE read $shp_file]
      ogrlayer read FEATURES LAYERFILE 0

      if { [fstdfield is $LakeF] } {
         Log::Print INFO "Calculating Lake fraction"
         fstdfield gridinterp $LakeF FEATURES ALIASED 1 "" SUM
      }

      if { [fstdfield is $LakeD] } {
         Log::Print INFO "Calculating Lake Average Depth"
         fstdfield gridinterp $LakeD FEATURES ALIASED Depth_avg "" SUM
      }

      if { [fstdfield is $LakeS] } {
         Log::Print INFO "Calculating Lake Surface Average"
         fstdfield gridinterp $LakeS FEATURES INTERSECT Lake_area "" AVERAGE
      }

      if { [fstdfield is $LakeG] } {
         Log::Print INFO "Calculating Lake Grid Surface Average"
         fstdfield gridinterp $LakeG FEATURES CONSERVATIVE Lake_area "" AVERAGE
      }

      ogrfile close LAYERFILE
   }

   # we want to have an uniformed negative depth values like bathymetry
   if { [fstdfield is $LakeD] && [fstdfield is $LakeF] } {
      vexpr  $LakeD "ifelse($LakeF>0.0,-1.0*$LakeD/$LakeF,0.0)"
   }

   # discard temporary created LakeF
   if { $Has_LakeF == 0 } {
      if { [fstdfield is $LakeF] } {
         fstdfield free  $LakeF
      }
   }
}
