#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : HydroX.tcl
# Creation   : August 2011 - J.P. Gauthier - CMC/CMOE
# Revision   : $Id$
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

   GenX::Procs

   #----- Read mask
   if { [llength [set idx [fstdfield find GPXOUTFILE -1 "" -1 -1 -1 "" "MG"]]] } {
      fstdfield read GPXMG GPXOUTFILE $idx
   } else {
      GenX::Log WARNING "Could not find mask field MG"
   }

   set limits [georef limit [fstdfield define $Grid -georef]]
   set la0 [lindex $limits 0]
   set lo0 [lindex $limits 1]
   set la1 [lindex $limits 2]
   set lo1 [lindex $limits 3]
   GenX::Log DEBUG "   Grid limits are from ($la0,$lo0) to ($la1,$lo1)" False

   #----- Creer les champs de calculs
   fstdfield copy GPXRIVERSUM $Grid
   fstdfield copy GPXLAKESUM  $Grid
   fstdfield copy GPXLAKEAREA $Grid

   GenX::GridClear [list $Grid GPXRIVERSUM GPXLAKESUM GPXLAKEAREA] 0.0

   foreach path [GenX::NHNFindFiles $la0 $lo0 $la1 $lo1] {
      GenX::Log DEBUG "   Processing NHN path $path" False

      #----- Lire la donnee des rivieres
      foreach file [glob ${path}_?_?_HD_COURSDEAU_1.shp] {
         set layers [ogrfile open FILERIVER read ${file}]
         ogrlayer read LINES FILERIVER 0

         fstdfield gridinterp GPXRIVERSUM LINES LENGTH_CONSERVATIVE FEATURE_LENGTH

         ogrfile close FILERIVER
      }

      #----- Lire la donnee des lacs
      foreach file [glob ${path}_?_?_HD_REGIONHYDRO_2.shp] {
         set layers [ogrfile open FILELAKE read ${file}]
         ogrlayer read AREAS FILELAKE 0

         fstdfield gridinterp GPXLAKESUM  AREAS LENGTH_CONSERVATIVE FEATURE_LENGTH
         fstdfield gridinterp GPXLAKEAREA AREAS CONSERVATIVE FEATURE_AREA

         ogrfile close  FILELAKE
      }
   }

   ogrlayer free LINES AREAS

   #----- Effectuer le calculs de drainage
   vexpr $Grid (GPXRIVERSUM+GPXLAKESUM)/(darea($Grid)-GPXLAKEAREA)

   if { [fstdfield is GPXMG] } {
      vexpr $Grid ifelse(GPXMG,$Grid,0)
   }

   #----- Sauvagerdons le tout

   fstdfield define $Grid -NOMVAR DRND -IP1 1200
   fstdfield write $Grid GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield define GPXRIVERSUM -NOMVAR RSUM -IP1 1200
   fstdfield write GPXRIVERSUM GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield define GPXLAKESUM -NOMVAR LSUM -IP1 1200
   fstdfield write GPXLAKESUM GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield define GPXLAKEAREA -NOMVAR LARE -IP1 1200
   fstdfield write GPXLAKEAREA GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free GPXRIVERSUM GPXLAKESUM GPXLAKEAREA GPXMG
}
