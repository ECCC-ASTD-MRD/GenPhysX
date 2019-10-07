#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Urban geophysical field generator
# File       : UrbanX.tcl
# Creation   : Janvier 2006- Alexandre Leroux / J.P. Gauthier - CMC/CMOE
# Description: Classification urbaine automatisée, principalement à partir de
#              données CanVec 1:50000, StatCan (population) LCC2000-V (vegetation)
#              et bâtiments 3D pour alimenter le modèle TEB
#
# Remarks  :
#		Full documentation found on https://wiki.cmc.ec.gc.ca/wiki/UrbanX and subpages
#
# Functions :
#
#============================================================================

namespace eval UrbanX { } {
   global env
   variable Param
   variable Const
   variable Meta
   variable Path
   variable GeoRef

   set Param(Version)       	 0.95   ;# UrbanX version number
   set Param(CULUCVersion)       0.9.2  ;# CULUC version number
   set Param(Resolution)         5      ;# Spatial rez of rasterization and outputs, leave at 5m unless for testing purposes
   set Param(Mode)               FAST   ;# Rasterization mode: INCLUDED or FAST - fast is... much much faster!
   set Param(HeightGain)         0      ;# Default value if proc HeightGain is not ran
   set Param(Width)              0      ;# Largeur du domaine, set based on CITYNAME or GRIDFILE
   set Param(Height)             0      ;# Hauteur du domaine, set based on CITYNAME or GRIDFILE
   set Param(Lon1)               0.0    ;# Top right longitude, set based on CITYNAME or GRIDFILE
   set Param(Lat1)               0.0    ;# Top right latitude, set based on CITYNAME or GRIDFILE
   set Param(Lon0)               0.0    ;# Lower left longitude, set based on CITYNAME or GRIDFILE
   set Param(Lat0)               0.0    ;# Lower Left latitude, set based on CITYNAME or GRIDFILE
   set Param(Files)   		 ""	;# List of CanVec files to process, with full path to the files
   set Param(HeightFile)         ""     ;# Set by CITYNAME
   set Param(HeightMaskFile)     ""     ;# Set by CITYNAME
   set Param(BuildingsShapefile) ""     ;# 2.5D buildings shapefile for CITYNAME
   set Param(BuildingsHgtField)  ""     ;# Name of the height attribute of the 2.5D buildings shapefile

   # Optional TEB parameters - they are not computed by default in order to reduce processing time
   # According to Sylvie and Maria, optional TEB parameters are: SUMF DPBH Z0H BLDW HVAR HMIN HMAX
   # There's only BLDW that is still computed since required by WHOR param
   set Param(OptionalTEBParams) 0          ;# By default, we don't process optional TEB parameters


   # added at Serge's request ;-) will use the CULUC_PATH provided by the user if any
   if { [info exists env(CULUC_PATH)] } {
      set Param(CULUCPath) $env(CULUC_PATH)
   } else {
      set Param(CULUCPath)       "$GenX::Param(DBase)/CULUC/CA" ;# Path to the permanent CULUC repository
   }

   set Param(WULUCPath) ""
   if { [info exists env(WULUC_PATH)] } {
      set Param(WULUCPath)  "$env(WULUC_PATH)"
   } else {
      set Param(WULUCPath)  "$GenX::Param(DBase)/CULUC/US" ;# Path to the permanent WULUC repository
   }

   if { [info exists env(BLDH_PATH)] } {
      set Param(BLDH_PATH) $env(BLDH_PATH)
   } else {
      set Param(BLDH_PATH) ""
   }

   #----- Directory where to find processing procs
   source $env(GENPHYSX_PATH)/tcl/UrbanX-ClassesLUT.tcl

   set Param(Entities)   	[UrbanX-ClassesLUT::SetParamEntities]
   set Param(Priorities) 	[UrbanX-ClassesLUT::SetParamPriorities]
   set Param(TEBClasses)	[UrbanX-ClassesLUT::SetParamTEBClasses]
   set Param(TEBClassesOrdered)	[UrbanX-ClassesLUT::SetParamTEBClassesOrdered]
   set Param(CULUCClasses)	[UrbanX-ClassesLUT::SetParamCULUCClasses]

   # 1 deg of latitude in meters: 0.000008993216059187306
   # 1 deg of longitude in meters varies a lot, up to a factor 3 in Canada - the dist proc could be used to evaluate a value considering the longitude too
   # Next line is overwritten in the main proc
   # set Param(Deg2M) 0.000008993216059187306

   # CanVec layers requiring postprocessing. No specific sorting of this list is required
   set Param(LayersPostPro)    { BS_1370009_2 BS_2010009_0 BS_2010009_2 BS_2060009_0 BS_2240009_1 BS_2310009_1 EN_1180009_1 HD_1450009_0 HD_1450009_1 HD_1450009_2 HD_1460009_0 HD_1460009_1 HD_1460009_2 HD_1470009_1 HD_1480009_2 IC_2600009_0 TR_1020009_1 TR_1190009_0 TR_1190009_2 TR_1760009_1 QC_TR_1760009_1 }

   # SMOKE Classes for CanVec
   # Ces valeurs sont associées aux entitées CanVec.  Elles doivent être dans le même ordre que Param(Entities) et Param(Priorities), pour l'association de LUT
   set Param(SMOKEClasses)       { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 3 4 5 43 0 0 30 29 0 28 27 0 0 0 0 22 0 0 0 0 33 0 26 0 0 36 37 34 35 39 40 41 32 31 42 74 73 67 66 71 70 68 69 72 64 65 0 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 23 0 63 61 62 58 59 60 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 26 25 0 0 0 0 0 0 0 0 21 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 24 0 43 0 28 29 0 28 0 0 0 0 36 37 0 38 39 42 22 23 47 31 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 0 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 0 0 24 0 44 45 46 0 0 }

   # Validation of LUT lengths
   if {$GenX::Param(SMOKE)!="" } {
      if { !(([llength $Param(Priorities)] == [llength $Param(SMOKEClasses)]) && ([llength $Param(Priorities)] == [llength $Param(TEBClasses)])) } {
         Log::Print ERROR "ERROR: Param(Priorities) = [llength $Param(Priorities)], Param(TEBClasses) = [llength $Param(TEBClasses)], Param(SMOKEClasses) = [llength $Param(SMOKEClasses)]"
         Log::End 1;
      }
   } else {
      if { !(([llength $Param(Priorities)] == [llength $Param(Entities)]) && ([llength $Param(Priorities)] == [llength $Param(TEBClasses)])) } {
         Log::Print ERROR "ERROR: Param(Priorities) = [llength $Param(Priorities)], Param(TEBClasses) = [llength $Param(TEBClasses)], Param(Entities) = [llength $Param(Entities)]"
         Log::End 1;
      }
   }

   set Param(VegeFilterType) LOWPASS
   set Param(VegeFilterSize) 99

   # NOTE : les paths des fichiers suivants devront être modifiés lorsqu'il aura été décidé où ces fichiers seront localisés
   # Fichier contenant les polygones de dissemination area de StatCan, découpés selon l'index NTS 1:50000 et contenant la population ajustée aux nouveaux polygones
   set Param(PopFile2006SMOKE) $GenX::Path(StatCan)/SMOKE_FILLED/da2006-nts_lcc-nad83.shp
   # Next path needs to be updated and added to GenX
   set Param(Census2006File) $GenX::Path(StatCan)/da2006_pop_labour.shp

   # Next file should be moved to the data repertory with $GenX::Path()
   set Param(TEBParamsLUTCSVFile) $env(GENPHYSX_PATH)/doc/TEB-Params_LUT.csv

   # Pour IndustrX seulement : fichier contenant 1 polygone pour chaque province ou territoire du Canada - pourrait être déplacé dans IndustrX
   set Param(ProvincesGeom) $GenX::Path(StatCan)/Provinces_lcc-nad83.shp

   # À déplacer dans IndustrX - Fichier contenant l'index NTS à l'échelle 1:50000
   # Attention : s'assurer qu'il s'agit bien de l'index ayant servi au découpage du fichier PopFile2006SMOKE
   set Param(NTSFile) $GenX::Param(DBase)/$GenX::Path(NTS)/decoupage50k_2.shp
   # À déplacer dans IndustrX - entité CanVec déterminant la bordure des polygones NTS 50K
   set Param(NTSLayer) { LI_1210009_2 }

   # Vector 1: LCC2000 classes, vector 2: SMOKE LUT by Lucie in October 2010, vector 3: UrbanX LUT by Alex in February 2011
   # For the UrbanX LUT, values given are those of the ISBA LUT on the wiki at LCC2000-V/Classes PLUS 700
   set Const(LCC2000LUT) {
      { 0 10 11 12 20  30  31 32  33 34  35  36  37  40  50  51  52  53  80  81  82  83 100 101 102 103 104 110 121 122 123 200 210 211 212 213 220 221 222 223 230 231 232 233 }
      { 0  0  0  0  0 500   0  0 501  0 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 }
      { 0  0  0  0  0   0 702  0   0  0 724 724 724 722 726 711 711 722 723 723 723 723 713 722 714 722 722 714 715 715 715 725 704 704 704 704 707 707 707 707 725 725 725 725 } }


   # Lookup Table for redistribution of PAVF and BLDF into other TEB parameters
   set  Param(BLDFvsLUT)  {
              {BLDH 0 7.0}
              {BLDW 0 14.0}
              {Z0RF 0 0.15}
              {ALRF 0 0.15}
              {ALWL 0 0.25}
              {EMRF 0 0.91}
              {EMWL 0 0.85}
              {HCRF 1 3000000}
              {HCWL 1 1550000}
              {HCRF 2 1500000}
              {HCWL 2 1550000}
              {HCRF 3 290000}
              {HCWL 3 290000}
              {TCRF 1 1.51}
              {TCWL 1 0.9338}
              {TCRF 2 0.15}
              {TCWL 2 0.9338}
              {TCRF 3 0.04}
              {TCWL 3 0.05}
              {DPRF 1 0.05}
              {DPWL 1 0.02}
              {DPRF 2 0.4}
              {DPWL 2 0.125}
              {DPRF 3 0.1}
              {DPWL 3 0.05}
              }

   set  Param(PAVFvsLUT)  {
              {Z0RD 0 0.05}
              {ALRD 0 0.16}
              {EMRD 0 0.93}
              {HCRD 1 1000000}
              {HCRD 2 3000000}
              {HCRD 3 1300000}
              {TCRD 1 0.7}
              {TCRD 2 1.8}
              {TCRD 3 0.3}
              {DPRD 1 0.08}
              {DPRD 2 0.2}
              {DPRD 3 1.0}
              }
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::AreaDefine>
# Creation : June 2006 - Alexandre Leroux - CMC/CMOE
# Revision : April 2011 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Define raster coverage based on coverage name
#            Set the lat long bounding box for the city specified at launch
#
# Parameters :
#   <Coverage>   : zone to process, either city or province, "-urban" argument ( default settings on Quebec City)
#
# Return:
#   <..>         : Code de reussite (True ou False)
#
# Remarks :
#   Param(HeightFile) and Param(HeightMaskFile) will need to be removed or updated
#   Lat lon coordinates are used when no GRIDFILE is specified, otherwise, coordinates are overwritten by target grid extent
#
#----------------------------------------------------------------------------
proc UrbanX::AreaDefine { Coverage Grid } {
   variable Param

   #----- If no OutFile specified for -urban, then use the city name. Only OutFile_aux.fst and OutFile.fst aren't overwritten.
   if { $GenX::Param(OutFile)=="genphysx" } {
      Log::Print INFO "No \"-result\" option defined, using $Coverage for the output file filename"
      set GenX::Param(OutFile) $Coverage
   }

# CAREFUL: APPARENTLY, WE DON'T NEED THOSE LAT LONG ANYMORE SINCE THEY COME FROM NTS SHEETS... I NEED TO VALIDATE THIS AND DELETE BELOW
   switch $Coverage {
      "TEST" {
         #----- For testing purposes, small region near carrière Miron (overwritten if -gridfile is specified)
         set Param(Lon1)   -73.60
         set Param(Lat1)    45.57
         set Param(Lon0)   -73.65
         set Param(Lat0)    45.50
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Montreal/bat_2d_st.shp
         set Param(BuildingsHgtField) hauteur
         set Param(HeightFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped
         set Param(HeightMaskFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped_wmask
      }
      "VANCOUVER" {
         set Param(Lon1)   -122.50
         set Param(Lat1)    49.40
         set Param(Lon0)   -123.30
         set Param(Lat0)    49.01
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Vancouver/out.shp
         set Param(BuildingsHgtField) hgt
         set Param(HeightFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
         set Param(HeightMaskFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong_wmask
      }
      "MONTREAL" {
         set Param(Lon1)   -73.35
         set Param(Lat1)    45.70
         set Param(Lon0)   -73.98
         set Param(Lat0)    45.30
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Montreal/bat_2d_st.shp
         set Param(BuildingsHgtField) hauteur
         set Param(HeightFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped
         set Param(HeightMaskFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped_wmask
      }
      "TORONTO" {
         set Param(Lon1)   -79.12
         set Param(Lat1)    43.92
         set Param(Lon0)   -79.85
         set Param(Lat0)    43.49
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Toronto/Toronto.shp
         set Param(BuildingsHgtField) Elevation
      }
      "OTTAWA" {
         set Param(Lon1)   -75.56
         set Param(Lat1)    45.52
         set Param(Lon0)   -75.87
         set Param(Lat0)    45.30
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Ottawa/buildings.shp
         set Param(BuildingsHgtField) height
         set Param(HeightFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
         set Param(HeightMaskFile) /cnfs/dev/cmoe/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
      }
      "WINNIPEG" {
         set Param(Lon1)   -96.95
         set Param(Lat1)    49.98
         set Param(Lon0)   -97.34
         set Param(Lat0)    49.75
      }
      "CALGARY" {
         set Param(Lon1)   -113.90
         set Param(Lat1)    51.18
         set Param(Lon0)   -114.28
         set Param(Lat0)    50.87
      }
      "HALIFAX" {
         set Param(Lon1)   -63.36
         set Param(Lat1)    44.83
         set Param(Lon0)   -63.80
         set Param(Lat0)    44.56
      }
      "REGINA" {
         set Param(Lon1)   -104.50
         set Param(Lat1)    50.54
         set Param(Lon0)   -104.72
         set Param(Lat0)    50.38
      }
      "EDMONTON" {
         set Param(Lon1)   -113.19
         set Param(Lat1)    53.70
         set Param(Lon0)   -113.73
         set Param(Lat0)    53.38
      }
      "VICTORIA" {
         set Param(Lon1)   -123.22
         set Param(Lat1)    48.55
         set Param(Lon0)   -123.54
         set Param(Lat0)    48.39
      }
      "QUEBEC" {
         set Param(Lon1)   -71.10
         set Param(Lat1)    46.94
         set Param(Lon0)   -71.47
         set Param(Lat0)    46.68
      }
      "TN" {
         set Param(Lon1)   -52.5
         set Param(Lat1)    46.5
         set Param(Lon0)   -68.0
         set Param(Lat0)    60.8
         set Param(ProvinceCode) 10 ;# PR code from StatCan
      }
      "PEI" {
         set Param(Lon1)   -61.98
         set Param(Lat1)    47.06
         set Param(Lon0)   -64.42
         set Param(Lat0)    45.94
         set Param(ProvinceCode) 11 ;# PR code from StatCan
      }
      "NS" {
         set Param(Lon1)   -59.5
         set Param(Lat1)    47.5
         set Param(Lon0)   -67.0
         set Param(Lat0)    43.0
         set Param(ProvinceCode) 12 ;# PR code from StatCan
      }
      "NB" {
         set Param(Lon1)   -63.5
         set Param(Lat1)    48.5
         set Param(Lon0)   -69.5
         set Param(Lat0)    44.5
         set Param(ProvinceCode) 13 ;# PR code from StatCan
      }
      "QC" {
         set Param(Lon1)   -56.5
         set Param(Lat1)    63.0
         set Param(Lon0)   -80.0
         set Param(Lat0)    44.5
         set Param(ProvinceCode) 24 ;# PR code from StatCan
      }
      "ON" {
         set Param(Lon1)   -74.0
         set Param(Lat1)    57.0
         set Param(Lon0)   -96.0
         set Param(Lat0)    41.0
         set Param(ProvinceCode) 35 ;# PR code from StatCan
      }
      "MN" {
         set Param(Lon1)   -88.5
         set Param(Lat1)    60.5
         set Param(Lon0)   -102.5
         set Param(Lat0)    48.5
         set Param(ProvinceCode) 46 ;# PR code from StatCan
      }
      "SK" {
         set Param(Lon1)   -101.0
         set Param(Lat1)    60.5
         set Param(Lon0)   -110.5
         set Param(Lat0)    48.5
         set Param(ProvinceCode) 47 ;# PR code from StatCan
      }
      "AB" {
         set Param(Lon1)   -109.5
         set Param(Lat1)    60.5
         set Param(Lon0)   -120.5
         set Param(Lat0)    48.5
         set Param(ProvinceCode) 48 ;# PR code from StatCan
      }
      "BC" {
         set Param(Lon1)   -113.5
         set Param(Lat1)    60.5
         set Param(Lon0)   -140
         set Param(Lat0)    47.0
         set Param(ProvinceCode) 59 ;# PR code from StatCan
      }
      "YK" {
         set Param(Lon1)   -123.0
         set Param(Lat1)    70.0
         set Param(Lon0)   -142.0
         set Param(Lat0)    59.5
         set Param(ProvinceCode) 60 ;# PR code from StatCan
      }
      "TNO" {
         set Param(Lon1)   -101.5
         set Param(Lat1)    79.0
         set Param(Lon0)   -137.5
         set Param(Lat0)    59.5
         set Param(ProvinceCode) 61 ;# PR code from StatCan
      }
      "NV" {
         set Param(Lon1)   -60.0
         set Param(Lat1)    85.0
         set Param(Lon0)   -122.0
         set Param(Lat0)    51.0
         set Param(ProvinceCode) 62 ;# PR code from StatCan
      }
      default {
         if { ![fstdfield is $Grid] } {
            Log::Print ERROR "No grid definition provided, will not process urban parameters"
            return False
         }
         Log::Print INFO "Using spatial extent of the $GenX::Param(GridFile) file"
         set limits [georef limit [fstdfield define $Grid -georef]]
         set Param(Lat0) [lindex $limits 0]
         set Param(Lon0) [lindex $limits 1]
         set Param(Lat1) [lindex $limits 2]
         set Param(Lon1) [lindex $limits 3]
      }
   }
   if { $GenX::Param(GridFile)!="" && $Coverage!="True" } {
      Log::Print INFO "Using spatial extent of the $GenX::Param(GridFile) file"
      set limits [georef limit [fstdfield define $Grid -georef]]
      set Param(Lat0) [lindex $limits 0]
      set Param(Lon0) [lindex $limits 1]
      set Param(Lat1) [lindex $limits 2]
      set Param(Lon1) [lindex $limits 3]
   }

   # Adding buffer around grid in case extent of the grid is right on the NTS sheet limit - without it, there will be missing values for the averaging
   set Param(Lat0) [expr $Param(Lat0) - 0.01]
   set Param(Lon0) [expr $Param(Lon0) - 0.01]
   set Param(Lat1) [expr $Param(Lat1) + 0.01]
   set Param(Lon1) [expr $Param(Lon1) + 0.01]

   return True
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Sandwich>
# Creation : date? - Alexandre Leroux - CMC/CMOE
# Revision : July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Finds CanVec Files
#            Rasterize and flatten CanVec layers, either with a general
#            procedure or with some post-processing
#
# Parameters :
#
# Return: output genphysx_sandwich.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Sandwich { indexCouverture } {
   variable Param
   variable Data

   GenX::Procs
   Log::Print INFO "Rasterizing, flattening and post-processing CanVec layers over the raster of size $Param(Width)x$Param(Height) at a $Param(Resolution)m spatial resolution"

   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef $Param(SheetGeoRef)

   #----- Rasterization of CanVec layers
   foreach file $Param(Files) {
      # Adjusting variables lenght if the layer contains the additionnal _QC_ identifier
      if { [lsearch $file "*_QC_*"] !=-1 } {
         # Case of a _QC_ layer
         # entity contains an element of the form QC_AA_9999999_9
         set entity [string range [file tail $file] 11 25] ;# strip full file path to keep layer name only
         # filename contains an element of the form 999a99_9_9_QC_AA_9999999_9
         set filename [string range [file tail $file] 0 25] ;# required by ogrlayer sqlselect
      } else {
         # entity contains an element of the form AA_9999999_9
         set entity [string range [file tail $file] 11 22] ;# strip full file path to keep layer name only
         # filename contains an element of the form 999a99_9_9_AA_9999999_9
         set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
      }
      set priority [lindex $Param(Priorities) [lsearch -exact $Param(Entities) $entity]]
      Log::Print DEBUG "Processing entity: $entity, priority: $priority, filename: $filename, file: $file"

      # Value contains the nth element of the list Param(Priorities), where n is the index of layer in the list Param(Entities)
      ogrfile open SHAPE read $file

      # The following if/else evaluates if the layer requires some post-processing prior to rasterization or if it is rasterized with the generic procedure
      if { [lsearch -exact $Param(LayersPostPro) $entity] !=-1 } {

         switch $entity {
            BS_1370009_2 {
            # Residential areas
            # Lors de la procédure sandwich, l'entité prend entièrement les valeurs suivantes : PRI = 218 ; TEB = 210 ; SMO = 1
            # Lors de la procédure PopDens2Builtup, l'entité est découpée selon des seuils de densité de population
               Log::Print DEBUG "Post-processing for Residential area, area"
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename'"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity as FEATURES with priority value 218"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 218
            }
            BS_2010009_0 {
               # entity : Building, points
               Log::Print DEBUG "Post-processing for buildings, points buffered to 12m"

               set types { "arena" "armoury" "city hall" "coast guard station" "community center" "courthouse" "custom post" "electric power station" "fire station" "highway service center" \
                           "hospital" "medical center" "municipal hall" "gas and oil facilities building" "parliament building" "police station" "railway station" "satellite-tracking station" \
                           "sportsplex" "industrial building" "religious building" "penal building" "educational building" }
               set funcs {  1  2  5  6  7  8  9 11 12 16 17 19 20 23 25 26 27 29 32 37 38 39 41 }
               set vals  { 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (function = $func)"
                  ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*6] 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE function NOT IN ([join $funcs ,])"
               ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*6] 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 33"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 33
            }
            BS_2010009_2 {
               Log::Print DEBUG "Post-processing for buildings, areas"
               set types { "arena" "armoury" "city hall" "coast guard station" "community center" "courthouse" "custom post" "electric power station" "fire station" "highway service center" \
                           "hospital" "medical center" "municipal hall" "gas and oil facilities building" "parliament building" "police station" "railway station" "satellite-tracking station" \
                           "sportsplex" "industrial building" "religious building" "penal building" "educational building" }
               set funcs {   1   2   5   6  7  8  9 11 12 16 17 19 20 23 25 26 27 29 32 37 38 39 41 }
               set vals  { 103 102 101 100 99 98 97 96 95 94 93 92 91 90 89 88 87 86 85 84 83 82 81 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE FUNCTION = $func"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE function NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 104"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 104
            }
            BS_2060009_0 {
               #entity : Chimney, points
               Log::Print DEBUG "Post-processing for Chimneys, points"
               set types { "Chimneys - burners" "Chimneys - industrial" "Chimneys - flare stack" }
               set funcs { 1 2 3 }
               set vals  { 5 4 3 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 6"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 6
            }
            BS_2240009_1 {
               # Entity: Wall/fence, line
               Log::Print DEBUG "Post-processing for Wall / fences, lines"
               set types { "Wall / fence - fences" "Wall / fence - fences" }
               set funcs {   1   2 }
               set vals  { 114 113 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }
            }
            BS_2310009_1 {
               # Entity: Pipeline (Sewage / liquid waste), line
               Log::Print DEBUG "Post-processing for Pipelines (sewage / liquid waste), lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (aboveground sewage pipeline entity) as FEATURES with priority value $priority"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
            }
            EN_1180009_1 {
               # Entity: Pipeline, line
               Log::Print DEBUG "Post-processing for Pipelines, lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (aboveground pipeline entity) as FEATURES with priority value $priority"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
            }
            HD_1450009_0 {
               # Entity: Manmade hydrographic entity [Geobase], point
               Log::Print DEBUG "Post-processing for Manmade hydrographic entities, points"
               set types { "dam" "dock" "wharf" "breakwater" "dike/levee" "lock gate" "boat ramp" "fish ladder" "slip" "breakwater in the ocean" }
               set funcs {  1  2  3  4  5  6  7  8  9  104 }
               set vals  { 43 42 41 44 45 37 40 38 39   46 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 47"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 47
            }
            HD_1450009_1 {
               # Entity: Manmade hydrographic entity [Geobase], line
               Log::Print DEBUG "Post-processing for Manmade hydrographic entities, lines"
               set types { "dam" "dock" "wharf" "breakwater" "dike/levee" "lock gate" "boat ramp" "fish ladder" "slip" "breakwater in the ocean" }
               set funcs {   1   2   3   4   5   6   7   8   9 104 }
               set vals  { 124 123 122 125 126 118 121 119 120 127 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 128"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 128
            }
            HD_1450009_2 {
               # Entity: Manmade hydrographic entity [Geobase], area
               Log::Print DEBUG "Post-processing for Manmade hydrographic entities, area"
               set types { "dam" "dock" "wharf" "breakwater" "dike/levee" "lock gate" "boat ramp" "fish ladder" "slip" "breakwater in the ocean" }
               set funcs {   1   2   3   4   5   6   7   8   9 104 }
               set vals  { 154 153 152 155 156 148 151 149 150 157 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 128"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 158
            }
            HD_1460009_0 {
               # entity: Hydrographic obstacle entity [Geobase], point
               Log::Print DEBUG "Post-processing for Hydrographic obstacle entities, points"
               set types { "fall" "rapids" "reef" "rocks" "disappearing stream" "exposed shipwreck" "ford" "reef in the ocean" "rocks in the ocean" "exposed shipwreck in the ocean" }
               set funcs {  1  2  3  4  5  6  7 103 104 106 }
               set vals  { 56 57 53 52 48 50 49  55  54  51 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 58"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 58
            }
            HD_1460009_1 {
               # entity: Hydrographic obstacle entity [Geobase], line
               Log::Print DEBUG "Post-processing for Hydrographic obstacle entities, lines"
               set types { "fall" "rapids" "reef" "rocks" "disappearing stream" "exposed shipwreck" "ford" "reef in the ocean" "rocks in the ocean" "exposed shipwreck in the ocean" }
               set funcs {   1   2   3   4   5   6   7 103 104 106 }
               set vals  { 137 138 134 133 129 131 130 136 135 132 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 58"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 139
            }
            HD_1460009_2 {
               # entity: Hydrographic obstacle entity [Geobase], area
               Log::Print DEBUG "Post-processing for Hydrographic obstacle entities, areas"
               set types { "fall" "rapids" "reef" "rocks" "disappearing stream" "exposed shipwreck" "ford" "reef in the ocean" "rocks in the ocean" "exposed shipwreck in the ocean" }
               set funcs {   1   2   3   4   5   6   7 103 104 106 }
               set vals  { 167 168 164 163 159 161 160 166 165 162 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 169"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 169
            }
            HD_1470009_1 {
               # Entity: Single line watercourse [Geobase], line
               Log::Print DEBUG "Post-processing for Single line watercourse, line"
               set types { "canal" "conduit" "ditch" "watercourse" "tidal river" }
               set funcs {   1   2   3   6   7 }
               set vals  { 142 141 140 144 143 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (definition = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE definition NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 145"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 145
            }
            HD_1480009_2 {
              # Entity: Waterbody [Geobase], polygon
               Log::Print DEBUG "Post-processing for Waterbody, polygon"
               set types { "canal" "ditch" "lake" "reservoir" "watercourse" "tidal river" "liquid waste" "pond" "side channel" "ocean" }
               set funcs {   1   3   4   5   6   7   8   9  10 100 }
               set vals  { 172 171 178 179 175 173 176 177 173 180 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (definition = $func)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE definition NOT IN ([join $funcs ,])"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 181"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 181
            }
            IC_2600009_0 {
               # Entity: Mining area, point
               Log::Print DEBUG "Post-processing for Mining area, point"
               # status = 1 : mines opérationnelles
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (status = 1)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (operational mines) as FEATURES with priority value 65"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 65
               # status != 1 : mines non opérationnelles
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (status != 1)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (non operational mines) as FEATURES with priority value 66"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 66
            }
            TR_1020009_1 {
               # Entity: Railway, line
               Log::Print DEBUG "Post-processing for Railway, line"
               # support = 3: bridge
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (support = 3)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge railway) as FEATURES with priority value 2"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 2
               # support != 3 ou 4: not bridge, not tunnel
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE support NOT IN (3,4)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge railway) as FEATURES with priority value 111"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 111
            }
            TR_1190009_0 {
               # Entity: Runway, point
               Log::Print DEBUG "Post-processing for Runway, point"
               #type = 1 : airport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1 )"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (airport runway) as FEATURES with priority value 62"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 62
               # type = 2 ou 3: heliport, hospital heliport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type IN (2,3)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (heliport or hospital heliport runway) as FEATURES with priority value 7"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 7
               # type = 4: water aerodrome
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 4 )"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (water aerodrome runway) as FEATURES with priority value 61"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 61
            }
            TR_1190009_2 {
               # Entity: Runway, area
               Log::Print DEBUG "Post-processing for Runway, areas"
               # type = 1: airport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1 )"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (airport runway) as FEATURES with priority value 201"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 201
               # type = 2 ou 3: heliport, hospital heliport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type IN (2,3)"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (heliport or hospital heliport runway) as FEATURES with priority value 80"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 80
               # type = 4 : water aerodrome
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 4 )"
               Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (water aerodrome runway) as FEATURES with priority value 147"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 147
            }
            TR_1760009_1 {
               if { $indexCouverture=="MONTREAL" || $indexCouverture=="QUEBEC" || $indexCouverture=="QC"} {
                  Log::Print DEBUG "Ignoring the TR_1760009_1 layer for $indexCouverture to avoid duplicated roads with QC_TR_1760009_1"
               } else {
                  # Entity: Road segment [Geobase], line
                  Log::Print DEBUG "Post-processing for Road segment, lines"

                  # exclusions des structype 5 (tunnel) et 6 (snowshed), association de la valeur générale à tout le reste des routes pavées
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus != 2) AND structype NOT IN (5,6)"
                  ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*6] 8 ;# 6m x 2
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general road segments) as FEATURES with priority value 109"
                  Log::Print INFO "Buffering general road segments to 12m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 109

                  # pavstatus = 2: unpaved: routes non pavées n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus = 2) AND structype NOT IN (5,6)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (unpaved road segments) as FEATURES with priority value 110"
                  # pas de buffer sur les routes non pavées
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 110

                  # roadclass in (1,2): freeway, expressway/highway n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE roadclass in (1,2) AND structype NOT IN (5,6)"
                  ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*11] 8 ;# 11m x 2
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (highways road segments) as FEATURES with priority value 108"
                  Log::Print INFO "Buffering highway road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 108

                  # structype in (1,2,3,4) : bridge (tous les types de ponts)
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE structype IN (1,2,3,4)"
                  ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*11] 8 ;# 11m x 2
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge road segments) as FEATURES with priority value 1"
                  Log::Print INFO "Buffering bridge road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 1
               }
            }
            QC_TR_1760009_1 {
               # This has been added to support CanVec-R7's new QC_TR layers, it may need revision for R8 (May 2011) or R9
               if { $indexCouverture=="OTTAWA"} {
                  Log::Print DEBUG "Ignoring the QC_TR_1760009_1 layer for Ottawa to avoid duplicated roads with TR_1760009_1"
               } else {
                  # Thus for MONTREAL, QUEBEC and QC (IndustrX)
                  Log::Print DEBUG "Rasterizing QC_TR_1760009_1 for $indexCouverture"
                  # entity : Road segment [Geobase], line
                  Log::Print DEBUG "Post-processing for Road segment, lines"

                  # exclusions des structype 5 (tunnel) et 6 (snowshed), association de la valeur générale à tout le reste des routes pavées
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus != 2) AND structype NOT IN (5,6)"
                  ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*6] 8 ;# 6m x 2
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general road segments) as FEATURES with priority value 109"
                  Log::Print INFO "Buffering general road segments to 12m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 109

                  # pavstatus = 2: unpaved : routes non pavées n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus = 2) AND structype NOT IN (5,6)"
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (unpaved road segments) as FEATURES with priority value 110"
                  # pas de buffer sur les routes non pavées
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 110

                  # roadclass in (1,2): freeway, expressway/highway n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE roadclass in (1,2) AND structype NOT IN (5,6)"
                  ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*11] 8 ;# 11m x 2
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (highways road segments) as FEATURES with priority value 108"
                  Log::Print INFO "Buffering highway road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 108

                  # structype in (1,2,3,4) : bridge (tous les types de ponts)
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE structype IN (1,2,3,4)"
                  ogrlayer stats FEATURES -buffer [expr $Param(Deg2M)*11] 8 ;# 11m x 2
                  Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge road segments) as FEATURES with priority value 1"
                  Log::Print INFO "Buffering bridge road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 1
               }
            }
            default {
               # The layer is part of Param(LayersPostPro) but no case has been defined for it
               Log::Print WARNING "Post-processing for $file not found. The layer has not been rasterized"
            }
         }
      } else {

         # Generic rasterization: entities that are not part of Param(LayersPostPro)
         eval ogrlayer read FEATURES SHAPE 0
         Log::Print DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from file $file as FEATURES with priority value $priority, general procedure"
         gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
      }

      ogrlayer free FEATURES
      ogrfile close SHAPE
   }

   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT
   gdalfile close FILEOUT
   Log::Print INFO "The file $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif has been generated"

   gdalband free RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::ChampsBuffers>
# Creation : Circa 2005 - Alexandre Leroux - CMC/CMOE
# Revision : January 2011 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Create the fields and building vicinity output using spatial buffers
#
# Parameters :
#      <indexCouverture>      : index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :  BUG on the buffer generation due to GEOS 3.2.2.  Should be fixed
#           with 3.3.0
#
#----------------------------------------------------------------------------
proc UrbanX::ChampsBuffers { indexCouverture } {
   variable Param
   variable Data

   GenX::Procs
   Log::Print INFO "Buffer zone processing for grass and fields identification"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif]

   gdalband create RBUFFER $Param(Width) $Param(Height) 1 Byte
   eval gdalband define RBUFFER -georef $Param(SheetGeoRef)

   set i 0
   foreach file $Param(Files) {
      #----- entity contains an element of the form AA_9999999_9
      set entity [string range [file tail $file] 11 22] ;# strip full file path to keep layer name only
      if { $entity=="BS_2010009_0" || $entity=="BS_2010009_2" } {
         #----- filename contains an element of the form 999a99_9_9_AA_9999999_9
         set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
         ogrfile open SHAPE read $file
         switch $entity {
            BS_2010009_0 {
            Log::Print DEBUG "Buffering ponctual buildings (25m buffer)"
            set priority 666
            ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM '$filename' WHERE function NOT IN (3,4,14,36) "
            ogrlayer stats LAYER$i -buffer [expr $Param(Deg2M)*25] 8 ;# buffer of 25m
            }
            BS_2010009_2 {
            Log::Print DEBUG "Buffering 2D buildings (100m buffer)"
            set priority 667
            ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM '$filename' WHERE function NOT IN (3,4,14,36) "
            ogrlayer stats LAYER$i -buffer [expr $Param(Deg2M)*100] 8 ;# buffer of 100m
            }
         }
         Log::Print DEBUG "Buffering [ogrlayer define LAYER$i -nb] features from $filename as LAYER$i with buffer #priority $priority"
         gdalband gridinterp RBUFFER LAYER$i $Param(Mode) $priority
         ogrlayer free LAYER$i
         ogrfile close SHAPE
         incr i
      }
   }

   Log::Print INFO "Cookie cutting grass and fields buffers and setting grass and fields and building vicinity values"
   gdalband create RBUFFERCUT $Param(Width) $Param(Height) 1 UInt16
   gdalband define RBUFFERCUT -georef $Param(SheetGeoRef)
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER==0)),820,RBUFFERCUT)
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER!=0)),510,RBUFFERCUT)

   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_champs-only+building-vicinity.tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_champs-only+building-vicinity.tif GeoTiff
   gdalband write RBUFFERCUT FILEOUT

   gdalfile close FILEOUT FSANDWICH
   gdalband free RBUFFER RBUFFERCUT RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::PopDens2Builtup>
# Creation : Circa 2005 - Alexandre Leroux - CMC/CMOE
# Revision : July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Reclassify the builtup areas with several thresholds related
#            to population density
#
# Parameters :
#      <indexCouverture>      : index à appliquer à la référence UTMREF
#
# Return: output files :
#             genphysx_popdens.tif
#             genphysx_popdens-builtup.tif
#
# Remarks : see Census documentation on CMC's wiki
#
#----------------------------------------------------------------------------
proc UrbanX::PopDens2Builtup { indexCouverture } {
   variable Param

   GenX::Procs
   Log::Print INFO "Reclassifying residential builtup areas using population density"

   Log::Print DEBUG "Reading Sandwich file"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif]

   Log::Print DEBUG "Open and read the Canada-wide dissemination area polygons file"
   if {$GenX::Param(SMOKE)!="" } {
      set layer [lindex [ogrfile open SHAPE read $Param(PopFile2006SMOKE)] 0]
   } else {
      set layer [lindex [ogrfile open SHAPE read $Param(Census2006File)] 0]
   }
   eval ogrlayer read VPOPDENS $layer

   #----- Selecting only the required StatCan polygons - next is only useful to improve the speed of the layer substraction
   Log::Print DEBUG "Select the appropriate dissemination area polygons"
   set da_select [ogrlayer pick VPOPDENS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   ogrlayer define VPOPDENS -featureselect [list [list index # $da_select]]

   #----- Clear la colonne POP_DENS pour les polygones de DA sélectionnés, au lieu de POP_DENS, on peut utiliser n'importe quel attribut inutilisé
   ogrlayer clear VPOPDENS CSDUID

   #----- Création d'un fichier de rasterization des polygones de DA
   gdalband create RDA $Param(Width) $Param(Height) 1 Int32
   gdalband clear RDA -1
   gdalband define RDA -georef $Param(SheetGeoRef)

   Log::Print DEBUG "Rasterize the selected Dissemination Area (DA) polygons"
   gdalband gridinterp RDA VPOPDENS FAST FEATURE_ID

   #----- Comptage des pixels de la residential area pour chaque polygone de DA : increment de la table et buildings generals (ponctuels et surfaciques)
   Log::Print DEBUG "Counting pixels for residential areas and general function buildings for each Dissemination Area polygon"
   vexpr VPOPDENS.CSDUID tcount(VPOPDENS.CSDUID, ifelse(RSANDWICH==218 || RSANDWICH==104 || RSANDWICH==33,RDA,-1))

   Log::Print INFO "Calculating population density values and adjustments if required"
   foreach n $da_select {
      #----- Récupération de la valeur de population
      if {$GenX::Param(SMOKE)!="" } {
         set pop [ogrlayer define VPOPDENS -feature $n POP_NEW]
      } else  {
         #----- Could use DAPOP2006 instead, but generates a few problems of missing data
         set pop [ogrlayer define VPOPDENS -feature $n POP]
      }
      #----- Calcul de l'aire de la residential area à l'aide du nombre de pixels comptés précédemment
      set nbrpixels [ogrlayer define VPOPDENS -feature $n CSDUID]
      set area_pixels [expr ($nbrpixels*pow($Param(Resolution),2)/1000000.0)] ;#nbr de pixels * (5m*5m) de résolution / 1000000 m² par km² = area en km²
      #----- Calcul de la densité de population : dentité = pop/aire_pixels
      if {$area_pixels != 0} {
         set densite_pixels [expr $pop/$area_pixels]
      } else {
         set densite_pixels 0
      }

      #----- Calcul de l'aire à l'aide de la géométrie vectorielle
      set geom [ogrlayer define VPOPDENS -geometry $n]
      set area_vect [expr ([ogrgeometry stats $geom -area]/1000000.0)]
      #----- Calcul de la densité de population : dentité = pop/aire_vect
      if {$area_vect != 0} {
         set densite_vect [expr $pop/$area_vect]
      } else {
         set densite_vect 0
      }

      #----- Comparaison entre les deux densités calculées
      if {$densite_pixels != 0} {
         set densite_div [expr ($densite_pixels/$densite_vect)]
      } else {
         set densite_div 0
      }

      # Affectation de la densité appropriée
      # Note : la densité est généralement plus précise lorsque calculée à partir des pixels.
      # Toutefois, il arrive que certains endoits reçoivent des valeurs extrêmes puisque, notamment,
      # les polygones de DA ne sont pas snappés avec les zones résidentielles, ce qui peut entraîner
      # des cas où toute la population d'un polygone se retrouve concentrée sur 1 ou 2 pixels.
      # Afin d'éviter ces problèmes, si le ratio entre la densité calculée à l'aide des pixels et la densité
      # calculée à l'aide de la géométrie dépasse un seuil, nous conserverons la deuxième option, qui
      # répartit la population sur l'ensemble du territoire plutôt que sur 1 ou 2 pixels, et la multiplions par
      # 2 pour tenir compte du fait que l'ensemble du polygones n'est probablement pas résidentiel
      # (présence de parcs, de bâtiments non résidentiels, d'industries, etc.).  Le seuil choisi est de 20, ce
      # qui signifie que 95% du polygone n'est pas recouvert par les entités residential area ou bâtiments de
      # fonction générale.
      if { $densite_div > 20} {
         set densite_choisie [expr ($densite_vect * 2.0)]
         Log::Print DEBUG "Adjustment of population density for polygon ID $n"
      } else {
         set densite_choisie $densite_pixels
      }
      ogrlayer define VPOPDENS -feature $n CSDUID $densite_choisie
   }
   unset da_select

   Log::Print DEBUG "Conversion of population density in a raster file"
   gdalband create RPOPDENS $Param(Width) $Param(Height) 1 Float32
   eval gdalband define RPOPDENS -georef $Param(SheetGeoRef)
   gdalband gridinterp RPOPDENS VPOPDENS $Param(Mode) CSDUID

   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens.tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens.tif GeoTiff
   gdalband write RPOPDENS FILEOUT
   gdalfile close FILEOUT
   Log::Print INFO "The file $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens.tif has been generated"
   ogrfile close SHAPE

   ogrlayer free VPOPDENS
   gdalband free RDA

   Log::Print DEBUG "Cookie cutting population density and setting SMOKE/TEB values"
   gdalband create RPOPDENSCUT $Param(Width) $Param(Height) 1 Byte
   gdalband define RPOPDENSCUT -georef $Param(SheetGeoRef)
   vexpr RRESIDENTIAL RSANDWICH==218
   gdalband free RSANDWICH

   if { $GenX::Param(SMOKE)!="" } {
      #----- Seuils de densité de population associés à SMOKE (IndustrX)
      Log::Print INFO "Applying thresholds for IndustrX"
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS<100),1,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && (RPOPDENS>=100 && RPOPDENS<1000)),2,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS>=1000 && RPOPDENS<4000),3,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS>=4000),4,RPOPDENSCUT)
   } else {
      Log::Print INFO "Creating residential area classes based on population density"
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS<100000),round(200+RPOPDENS/1000),RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS>=100000),299,RPOPDENSCUT)
   }

   Log::Print DEBUG "Generating output file, result of the cookie cutting"
   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens-builtup.tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens-builtup.tif GeoTiff
   gdalband write RPOPDENSCUT FILEOUT
   gdalfile close FSANDWICH FILEOUT
   Log::Print INFO "The file $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens-builtup.tif has been generated"

   gdalband free RPOPDENS RRESIDENTIAL RPOPDENSCUT
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::HeightGain>
# Creation : Circa 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Estimate DEM height gain from the STM-DEM minus CDED data substraction
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::HeightGain { indexCouverture } {
   variable Param

   GenX::Procs
   Log::Print INFO "Evaluating height gain"

   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(TMPDIR)/$Param(NTSSheet)_champs-only+building-vicinity.tif]
   gdalband create RHAUTEURPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURPROJ -georef $Param(SheetGeoRef)
   gdalband stats RHAUTEURPROJ -nodata -9999

   #----- La vérification pourrait être fait dans un proc avec vérification des 4 points de la source
   gdalband read RHAUTEUR [gdalfile open FHAUTEUR read $Param(HeightFile)]
   Log::Print WARNING "Next line crashes for Montreal, probably a real memory fault. The whole 2006 substraction should be re-coded to use GenPhysX and compute the output directly on the final grid"
   gdalband gridinterp RHAUTEURPROJ RHAUTEUR
   gdalband free RHAUTEUR
   gdalfile close FHAUTEUR

   set min [gdalband stats RHAUTEURPROJ -min]
   if { [lindex $min 0] == -9999 } {
      Log::Print WARNING "Heights does not overlap entirely the area, average won't be good, absent values will be set to 0"
      vexpr RHAUTEURPROJ ifelse(RHAUTEURPROJ==-9999,0,RHAUTEURPROJ)
   }
   vexpr RHEIGHTCHAMPS ifelse(RCHAMPS==820,RHAUTEURPROJ,0)

   #----- Average est calculé (pour le moment) que pour les valeurs != 0 dans le code en C
   #      Pour avec les 0: set Param(HeightGain) [vexpr XX savg(RHEIGHTCHAMPS)]
   gdalband stats RHEIGHTCHAMPS -nodata 0
   set Param(HeightGain) [gdalband stats RHEIGHTCHAMPS -avg]

   Log::Print INFO "Average gain calculated over defined areas = $Param(HeightGain)"
   if {($Param(HeightGain)>=10 || $Param(HeightGain)<=-10) || $Param(HeightGain)==0 } {
      Log::Print WARNING "Strange value for Param(HeightGain): $Param(HeightGain)"
   }

   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_hauteur-classes.tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_hauteur-classes.tif GeoTiff
   gdalband write RHEIGHTCHAMPS FILEOUT
   gdalfile close FILEOUT FCHAMPS
   Log::Print INFO "The file $GenX::Param(TMPDIR)/$Param(NTSSheet)_hauteur-classes.tif has been generated"

   gdalband free RCHAMPS RHEIGHTCHAMPS RHAUTEURPROJ
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::BuildingHeight>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#      <indexCouverture>      : index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::BuildingHeight { indexCouverture } {
   variable Param

   GenX::Procs
   Log::Print INFO "Cookie cutting building heights and adding gain"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif]
   gdalband read RHAUTEURWMASK [gdalfile open FHAUTEUR read $Param(HeightMaskFile)]

   gdalband create RHAUTEURWMASKPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURWMASKPROJ -georef $Param(SheetGeoRef)

   gdalband gridinterp RHAUTEURWMASKPROJ RHAUTEURWMASK
   gdalband free RHAUTEURWMASK
   gdalfile close FHAUTEUR
   vexpr RHAUTEURWMASKPROJ RHAUTEURWMASKPROJ+$Param(HeightGain)

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM { 300 600 810 302 301 }
   vector set LUT.TO   { 120 120 120 122 121 }
   vexpr RHAUTEURCLASS lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector set LUT.FROM { 300 600 810 605 302 301 }
   vector set LUT.TO   { 130 130 130 135 132 131 }
   vexpr RHAUTEURCLASS ifelse(RHAUTEURWMASKPROJ>=10,lut(RSANDWICH,LUT.FROM,LUT.TO),RHAUTEURCLASS)
   vector set LUT.TO   { 140 140 140 145 142 141 }
   vexpr RHAUTEURCLASS ifelse(RHAUTEURWMASKPROJ>=20,lut(RSANDWICH,LUT.FROM,LUT.TO),RHAUTEURCLASS)
   vector set LUT.TO   { 150 150 150 155 152 151 }
   vexpr RHAUTEURCLASS ifelse(RHAUTEURWMASKPROJ>=30,lut(RSANDWICH,LUT.FROM,LUT.TO),RHAUTEURCLASS)
   gdalband free RHAUTEURWMASKPROJ
   vector free LUT

   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_hauteur-classes.tif GeoTiff
   gdalband write RHAUTEURCLASS FILEOUT
   gdalfile close FILEOUT FSANDWICH
   Log::Print INFO "The file $GenX::Param(TMPDIR)/$Param(NTSSheet)_hauteur-classes.tif has been generated"

   gdalband free RHAUTEURCLASS RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::LCC2000V>
# Creation : October 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :  Rasterize data from LCC2000-V dataset.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::LCC2000V { } {
   variable Param
   variable Const

   GenX::Procs
   Log::Print INFO "Integrating LCC2000-V data for vegetated areas"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif]
   gdalband copy RLCC2000V RSANDWICH
   vexpr RLCC2000V RLCC2000V << 0

   set j 0 ;# Increment of LAYERLCC2000V$j required to re-use the object
   foreach file [GenX::LCC2000VFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)] {
      Log::Print DEBUG "Processing LCC2000-V file $file"
      ogrfile open SHAPELCC2000V read $file
      eval ogrlayer read LAYERLCC2000V$j SHAPELCC2000V 0

      Log::Print DEBUG "Rasterizing the selected LCC2000-V 1:250k NTS sheet"
      set t_gridinterp [clock seconds]
      gdalband gridinterp RLCC2000V LAYERLCC2000V$j $Param(Mode) COVTYPE
      Log::Print DEBUG "Time required for LCC2000V rasterization: [expr [clock seconds]-$t_gridinterp] seconds"

      ogrlayer free LAYERLCC2000V$j
      ogrfile close SHAPELCC2000V
      incr j ;# Increment of VFEATURE2KEEP$j required to re-use the object
   }
   vector create LUT.FROM [lindex $Const(LCC2000LUT) 0]
   if {$GenX::Param(SMOKE)!="" } {
      Log::Print INFO "Associating LCC2000-V values to SMOKE classes"
      vector create LUT.TO     [lindex $Const(LCC2000LUT) 1]
   } else {
      Log::Print INFO "Associating LCC2000-V values to TEB classes"
      vector create LUT.TO     [lindex $Const(LCC2000LUT) 2]
   }
   vexpr RLCC2000VSMOKE lut(RLCC2000V,LUT.FROM,LUT.TO)
   vector free LUT.FROM LUT.TO

   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_LCC2000V-LUT.tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_LCC2000V-LUT.tif GeoTiff
   gdalband write RLCC2000VSMOKE FILEOUT
   gdalfile close FLCC2000V FILEOUT FSANDWICH
   Log::Print INFO "The file $GenX::Param(TMPDIR)/$Param(NTSSheet)_LCC2000V-LUT.tif has been generated"

   gdalband free RLCC2000V RLCC2000VSMOKE RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Priorities2TEB>
# Creation : Circa 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Applies LUT to all processing results to generate TEB classes
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Priorities2TEB { } {
   global   env
   variable Param

   GenX::Procs
   Log::Print INFO "Aggregating rasters into CULUC classes"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens-builtup.tif]
   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(TMPDIR)/$Param(NTSSheet)_champs-only+building-vicinity.tif]
   gdalband read RLCC2000V [gdalfile open FLCC2000V read $GenX::Param(TMPDIR)/$Param(NTSSheet)_LCC2000V-LUT.tif]
   # gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(TMPDIR)/$Param(NTSSheet)_hauteur-classes.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Priorities)
   vector set LUT.TO $Param(TEBClasses)
   vexpr RTEB lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   vexpr RTEB ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RTEB)
   #----- Next rasters are not generated at the moment
   # vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
   vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RTEB)
   # Rasters must now be closed otherwise we blow up memory for large cities
   gdalfile close FSANDWICH FPOPDENSCUT FCHAMPS FHAUTEURCLASS
   gdalband free RSANDWICH RPOPDENSCUT RCHAMPS RHAUTEURCLASS

   vexpr RTEB ifelse((RLCC2000V!=0 && (RTEB==0 || RTEB==810 || RTEB==820 || RTEB==840)),RLCC2000V,RTEB)
   gdalband free RLCC2000V

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(TEBClassesOrdered)
   vector set LUT.TO $Param(CULUCClasses)
   vexpr (UByte)RTEB lut(RTEB,LUT.FROM,LUT.TO)
   vector free LUT

   Log::Print DEBUG "Masking area outside of NTS sheet $Param(NTSSheet)"
   # Using limits to burn NoData 0 values outside of NTS sheet, where data is incomplete
   eval ogrlayer read NTSMASKLAYER$Param(NTSSheet) [lindex [ogrfile open NTSMASKSHAPE$Param(NTSSheet) read [glob -nocomplain $Param(NTSSheetPath)/$Param(NTSSheet)*_LI_1210009_2.shp]] 0]
   gdalband create RNTSMASK $Param(Width) $Param(Height) 1 Byte
   gdalband define RNTSMASK -georef $Param(SheetGeoRef)
   gdalband gridinterp RNTSMASK NTSMASKLAYER$Param(NTSSheet) $Param(Mode) 1
   vexpr (UByte)RTEB ifelse(RNTSMASK==1,RTEB,0)
   gdalband stats RTEB -nodata 0
   ogrlayer free NTSMASKLAYER$Param(NTSSheet)
   ogrfile close NTSMASKSHAPE$Param(NTSSheet)
   gdalband free RNTSMASK

   Log::Print INFO "Applying TIFF colormap to the CULUC classes"
   # The colormap id needs the $Param(NTSSheet) because it makes conflicts even after the colormap free
   colormap create CULUCCOLORMAP$Param(NTSSheet)
   colormap read CULUCCOLORMAP$Param(NTSSheet) $$env(GENPHYSX_PATH)/doc/CULUC-colormap.rgba

   gdalband define RTEB -indexed True
   gdalband configure RTEB -colormap CULUCCOLORMAP$Param(NTSSheet)

   file delete -force $GenX::Param(TMPDIR)/CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif GeoTiff
   gdalband write RTEB FILEOUT { COMPRESS=LZW }
   gdalfile close FILEOUT FLCC2000V
   Log::Print INFO "The file $GenX::Param(TMPDIR)/CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif has been generated"

   colormap free CULUCCOLORMAP$Param(NTSSheet)
   gdalband free RTEB
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::VegeMask>
# Creation : Circa 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Generate and apply vegetation mask
#
# Parameters :
#
# Return:
#
# Remarks :
#    This proc is probably useless now that urban vegetation classes are managed by ISBA
#
#----------------------------------------------------------------------------
proc UrbanX::VegeMask { } {
   variable Param

   GenX::Procs
   Log::Print INFO "Generating vegetation mask"

   gdalband read RTEB [gdalfile open FTEB read $GenX::Param(TMPDIR)/CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif]

   vexpr RTEBWMASK ifelse(RTEB>800,100,0)

   set fileRTEBfilter $GenX::Param(OutFile)_vegemask-$Param(VegeFilterType)$Param(VegeFilterSize).tif

   if { ![file exists $fileRTEBfilter] } {
      if { $Param(VegeFilterSize) > 20 } {
         Log::Print INFO "Generating this $Param(VegeFilterType)$Param(VegeFilterSize) vegetation mask may require hours to process"
      }
      vector create FILTER [UrbanX::FilterGen $Param(VegeFilterType) $Param(VegeFilterSize)]
      #----- Le nodata sert à simuler l'application d'un mask au filtre qui suit
      vexpr RTEBWMASK ifelse(RTEB==901,901,RTEBWMASK)
      gdalband stats RTEBWMASK -nodata 901
      vexpr VEGEMASK fkernel(RTEBWMASK,FILTER)
      # vexpr VEGEMASK fcentile(RTEBWMASK,3,0.5) ;# fcentile is fmedian, fmax, fmin à la fois

      file delete -force $fileRTEBfilter
      gdalfile open FILEOUT write $fileRTEBfilter GeoTiff
      gdalband write VEGEMASK FILEOUT
      gdalfile close FILEOUT
   } else {
      Log::Print INFO "Using previously computed filtered data $fileRTEBfilter"
      gdalband read VEGEMASK [gdalfile open FVEGEMASK read ./$fileRTEBfilter]
   }

   #----- Seuil sur le filtre et rajout des non-nature et de l'eau
   vexpr RTEBWMASK ifelse((VEGEMASK>85 && RTEB>800 && RTEB!=901),0,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB-wVegeMask.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB-wVegeMask.tif GeoTiff
   gdalband write RTEBWMASK FILEOUT

   gdalfile close FILEOUT
   gdalband free RTEBWMASK VEGEMASK
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::CreateGridIJTile>
# Creation : 
# Revision : 
#
# Goal     :
#
# Parameters :
#   <Grid>   : the Target grid
#   <bands>  : file info of opened band file
#   <georef> : projection of opened band file
#   <Tile>   : name of output Tile
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::CreateGridIJTile { Tile bands georef Grid } {
   set info   [lindex $bands 0]
puts $info
   set Width  [lindex $info 3]
   set Height [lindex $info 4]
   set ni     [fstdfield define $Grid -NI]
   set nj     [fstdfield define $Grid -NJ]

   gdalband free $Tile
   if { $ni < 255 && $nj < 255 } {
      gdalband create $Tile $Width $Height 2 Byte
      gdalband define $Tile -georef $georef
      gdalband stats  $Tile -nodata 255
   } else {
      gdalband create $Tile $Width $Height 2 UInt16
      gdalband define $Tile -georef $georef
      gdalband stats  $Tile -nodata 65535
   }
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::GetULUCFilename>
# Creation : 
# Revision : 
#
# Goal     :  return the filename of an existing CULUC sheet or 
#             a to be generate filename
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::GetULUCFilename { sheet } {
   variable Param

   set s250 [string range $sheet 0 2]
   set sl   [string tolower [string range $sheet 3 3]]
   set s50  [string range $sheet 4 5]
   set clfilename "$s250/$sl/CULUC_${sheet}_v$Param(CULUCVersion).tif"
   set filename  $Param(CULUCPath)/$clfilename
   if { [file exists $filename] } {
      return $filename
   }

   set paths [split $Param(WULUCPath) ":"]
   foreach  WULUCPath  $paths {
      set filename $WULUCPath/$clfilename
      if { [file exists $filename] } {
         return $filename
      }
   }

#   Log::Print DEBUG "Param(TMPDIR) is : $GenX::Param(TMPDIR)"
   set clfilename "CULUC_${sheet}_v$Param(CULUCVersion).tif"
   set filename $GenX::Param(TMPDIR)/$clfilename
   return $filename
}

proc UrbanX::GetBldHgtShpfile { Tile } {
   variable Param

   if { ($Param(BuildingsHgtShpDir)!="") } {
      set limits [georef limit [gdalband define $Tile -georef]]
      set la0 [lindex $limits 0]
      set lo0 [lindex $limits 1]
      set la1 [lindex $limits 2]
      set lo1 [lindex $limits 3]
      puts "$la0 $lo0 $la1 $lo1"

      set  indexfile $Param(BuildingsHgtShpDir)/Index/Index.shp
      set items [GenX::Fetch_Shpfile_Index $indexfile $la0 $lo0 $la1 $lo1]
      set files {}
      foreach item $items {
         lappend files "$Param(BuildingsHgtShpDir)/${item}-buildings_H.shp"
      }
      return $files
   }
   return {}
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::tebparam2nomvarip1>
# Creation : Circa 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Computing TEB parameters on the target RPN fstd grid
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::tebparam2nomvarip1 { tebparam } {

#----- Fixing NOMVAR names from unique values to their RPN value
   set nomvar_5lettres { HCRF1 HCRD1 HCWL1 TCRF1 TCRD1 TCWL1 DPRF1 DPRD1 DPWL1 HCRF2 HCRD2 HCWL2 TCRF2 TCRD2 TCWL2 DPRF2 DPRD2 DPWL2 HCRF3 HCRD3 HCWL3 TCRF3 TCRD3 TCWL3 DPRF3 DPRD3 DPWL3 VF_1 VF_2 VF_3 VF_4 VF_5 VF_6 VF_7 VF_8 VF_9 VF10 VF11 VF12 VF13 VF14 VF15 VF16 VF17 VF18 VF19 VF20 VF21 VF22 VF23 VF24 VF25 VF26 }

   set nomvar_fixed    { HCRF HCRD HCWL TCRF TCRD TCWL DPRF DPRD DPWL HCRF HCRD HCWL TCRF TCRD TCWL DPRF DPRD DPWL HCRF HCRD HCWL TCRF TCRD TCWL DPRF DPRD DPWL VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF }

   set ip1 [vector get CSVTEBPARAMS.$tebparam 0]
   set ip1 [expr int($ip1)] ;# IP1 must be an integer

	if { [lsearch $nomvar_5lettres $tebparam ] !=-1} {
	   set nomvar [lindex $nomvar_fixed [lsearch $nomvar_5lettres $tebparam]]
	} else {
	   set nomvar $tebparam
	}
   if { $nomvar == "VEGF"} {
	   set nomvar "NATF"
	}
   return "$nomvar $ip1"
}


#----------------------------------------------------------------------------
# Name     : <UrbanX::TEB2FSTD>
# Creation : Circa 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Computing TEB parameters on the target RPN fstd grid
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::TEB2FSTD { Grid } {
   variable Param

   GenX::Procs
   Log::Print INFO "Computing TEB parameters on the target RPN fstd grid: $GenX::Param(GridFile)"

   Log::Print DEBUG "Reading the TEB parameters LUT in csv exported from the TEB-Params_LUT.xls file"

   set csvfile [open $Param(TEBParamsLUTCSVFile) r]

   vector create CSVTEBPARAMS
   gets $csvfile head ;# Setting the dimension of the vector
   set head [split $head ,]
   vector dim CSVTEBPARAMS $head

   while { ![eof $csvfile] } {
      gets $csvfile line
      if { $line!="" } {
         set line [split $line ,]
         vector append CSVTEBPARAMS $line
      }
   }
   close $csvfile

   fstdfield stats $Grid -nodata 0 ;# Required to avoid NaN in the gridinterp AVERAGE over nodata-only values

# concatanate NTS and US UTM Sheets together
   set all_sheets  "$Param(WTSSheets) $Param(NTSSheets)"
#TEST
#   set all_sheets   "040p01 040p08 040p09"
#   set all_sheets   "040p01"

   set tmpdir $GenX::Param(TMPDIR)

# first create all fields to be processed
   set tebparams_list {}
   foreach tebparam [lrange [vector dim CSVTEBPARAMS] 1 end] {

      set   nomvar [tebparam2nomvarip1 $tebparam]
      set   ip1     [lindex $nomvar 1]
      set   nomvar  [lindex $nomvar 0]

# check if the result was done already, then we can skip to next
      if { $nomvar == "VF"} {
         set fields [fstdfield find GPXOUTFILE -1 "" $ip1 -1 -1 "" "$nomvar"]
#         if { [llength $fields] > 0 } {
#            Log::Print INFO "$nomvar $ip1: found existing record, will not redo"
#            continue
#         }
      } else {
         set fields [fstdfield find GPXAUXFILE -1 "" $ip1 -1 -1 "" "$nomvar"]
#         if { [llength $fields] > 0 } {
#            if { $nomvar != "BLDH" && $nomvar != "BLDF" } {
#               continue
#            }
#            Log::Print INFO "$nomvar $ip1: found existing record, will not redo"
#               continue
#            if { $nomvar != "QETR" && $nomvar != "QHTR" } {
#            }
#         }
      }

      lappend tebparams_list $tebparam

      if { [llength $fields] > 0 } {
         if { $nomvar == "PAVF" || $nomvar == "BLDF" || $nomvar == "VEGF" || $nomvar == "BLDH"} {
            set LoadedField($tebparam)  False
            fstdfield copy $Grid.$tebparam $Grid
            GenX::GridClear $Grid.$tebparam 0.0
         } else {
            Log::Print INFO "Loading $nomvar $ip1 existing record"
            if { $nomvar == "VF"} {
               fstdfield read $Grid.$tebparam GPXOUTFILE -1 "" $ip1 -1 -1 "" "$nomvar"
            } else {
               fstdfield read $Grid.$tebparam GPXAUXFILE -1 "" $ip1 -1 -1 "" "$nomvar"
            }
            set LoadedField($tebparam)  True
         }
      } else {
         fstdfield copy $Grid.$tebparam $Grid
         GenX::GridClear $Grid.$tebparam 0.0
         set LoadedField($tebparam)  False
      }

      # pour NATF,BLDF,PAVF seulement
      switch $nomvar {
         NATF  { set no_zero 1 }
         BLDF  { set no_zero 1 }
         PAVF  { set no_zero 1 }
         default { set no_zero 0 } 
      }
#      if { $no_zero } {
#         fstdfield stats $Grid.$tebparam -nodata -9999 ;# Required to avoid account of zero in the gridinterp AVERAGE over nodata-only values
#      }
   }

# TEST
    puts $tebparams_list

#    set tebparams_list {BLDH}
#   set tebparams_list {BLDF PAVF BLDH NATF}

# see if option HMIN, HMAX and HVAR are requested and already exist
   if { $Param(OptionalTEBParams) } {
      set need_opt_tebparams ""
      foreach nomvar { HMIN HMAX BLDH HVAR } {
         set fields [fstdfield find GPXAUXFILE -1 "" $ip1 -1 -1 "" "$nomvar"]
         if { [llength $fields] > 0 } {
            Log::Print INFO "$nomvar $ip1: found existing record, will not redo"
         } else {
            lappend need_opt_tebparams $nomvar
         }
      }
      set  NeedBLDH 0
      if { [lsearch $need_opt_tebparams "HMIN"]>=0 } {
         Log::Print INFO "Creating storage for HMIN"
         fstdfield copy $Grid.HMIN $Grid
         GenX::GridClear $Grid.HMIN 0.0
         set NeedHMIN 1
         set NeedBLDH 1
      } else {
         set NeedHMIN 0
      }
      if { [lsearch $need_opt_tebparams "HMAX"]>=0 } {
         Log::Print INFO "Creating storage for HMAX"
         fstdfield copy $Grid.HMAX $Grid
         GenX::GridClear $Grid.HMAX 0.0
         set NeedHMAX 1
         set NeedBLDH 1
      } else {
         set NeedHMAX 0
      }
      if { [lsearch $need_opt_tebparams "BLDH"]>=0 } {
         set  HasBLDH  0
      } else {
         set  HasBLDH  1
      }
      if { [lsearch $need_opt_tebparams "HVAR"]>=0 } {
         set NeedHVAR 1
         if { $HasBLDH == 0 } {
# BLDH field is needed to compute HVAR
            set NeedBLDH 1
         }
      } else {
         set NeedHVAR 0
      }
# BLDH is essential to computation of HMIN HMAX HVAR
      if { $NeedBLDH && ([lsearch $tebparams_list "BLDH"]<0) } {
         lappend tebparams_list BLDH
         fstdfield copy $Grid.BLDH $Grid
         GenX::GridClear $Grid.BLDH 0.0
      }
   }

   Log::Print INFO "Will Compute TEB parameters: $tebparams_list"
   if { [llength $tebparams_list] == 0 } {
      set NeedProcessSheets  0
   } else {
      set NeedProcessSheets  1
   }

   if { [lsearch $tebparams_list "BLDH"]>=0 } {
      fstdfield copy $Grid.B3DH $Grid
      GenX::GridClear $Grid.B3DH 0.0
   }

# Load all NTS sheets only once or twice by moving it to outside loop
if { $NeedProcessSheets } {
   foreach sheet $all_sheets {
      set Param(NTSSheet) $sheet

      set  culucfilename [UrbanX::GetULUCFilename $sheet]
      puts "$culucfilename"
      if { [file exists $culucfilename] } {
      Log::Print INFO "Loading $culucfilename"
      set bands [gdalfile open FCULUC read $culucfilename]
      if { [catch { gdalband read RCULUC $bands }] } {
         gdalfile close FCULUC
         Log::Print ERROR "ERROR: Can't read: $culucfilename"
         Log::End 1;
      }
      Log::Print INFO "Loaded $culucfilename"
         vexpr RCULUC ifelse(RCULUC==22, 35, RCULUC)
         set Param(Width)  [gdalfile width  FCULUC]
         set Param(Height) [gdalfile height FCULUC]
         set georef [gdalfile georef FCULUC]
#         georef copy UTMREF$Param(NTSSheet) $georef
         set  Param(SheetGeoRef) $georef
      } else {
         continue
      }

      Log::Print INFO "Making IJCULUC"
      set culuc_IJ   "$tmpdir/$sheet-IJ.tif"
      if { [file exists $culuc_IJ] } {
         if { [catch { gdalband read IJCULUC [gdalfile open FCULUCIJ read $culuc_IJ] }] } {
            Log::Print ERROR "ERROR: Can't read: $culuc_IJ"
            Log::End 1;
         }
         gdalfile close FCULUCIJ
      } else {
         Log::Print INFO "Generating Grid Scanline cache over $Param(NTSSheet)"
         set georef [gdalfile georef FCULUC]

         Log::Print INFO "Creating IJCULUC"
         UrbanX::CreateGridIJTile IJCULUC $bands $georef $Grid
         set cnt [gdalband stats IJCULUC -grid2grid $Grid]
         if { $cnt <= 0 } {
            Log::Print INFO "Tile $Param(NTSSheet) not inside grid"
            gdalfile close FCULUC
            continue
         }
      }

      foreach tebparam $tebparams_list {

         set   nomvar [tebparam2nomvarip1 $tebparam]
         set   ip1     [lindex $nomvar 1]
         set   nomvar  [lindex $nomvar 0]

         if { $LoadedField($tebparam)  == False } {
            Log::Print DEBUG "Copying the $tebparam values to the 5m raster with LUT over $Param(NTSSheet)"
	         vexpr (Float32)RTEBPARAM lut(RCULUC,CSVTEBPARAMS.CULUC_Class,CSVTEBPARAMS.$tebparam)
            # Transfert the RCULUC nodata to the same nodata value in RTEBPARAM (-9999 from the csv file, can't be 0)
            vexpr RTEBPARAM ifelse(RCULUC==0, -9999, RTEBPARAM)
            gdalband stats RTEBPARAM -nodata -9999 ;# memory fault if this comes after the gdalband write

	 # Don't waste time averaging VF21, must leave it as 0.0, it is available as BLDF+PAVF
            if { $tebparam != "VF21" } {
               Log::Print INFO "Averaging TEB parameter $tebparam (IP1=$ip1) values over $Param(NTSSheet)"
               fstdfield fromband $Grid.$tebparam RTEBPARAM IJCULUC AVERAGE
            }
         }

         if { $nomvar == "BLDH" } {
#            set bld_height_file "$GenX::Param(TMPDIR)/$Param(NTSSheet)_Building-heights.tif"
            set bld_height_file "$Param(BLDH_PATH)/$Param(NTSSheet)_Building-heights.tif"
            Log::Print INFO "Need Buildings Height Raster file: $bld_height_file"
            if { ![file exist $bld_height_file] } {
               if { $Param(BuildingsHgtShpDir)!="" } {
                  Log::Print INFO "Looking for Buildings Height Shapefiles in: $Param(BuildingsHgtShpDir)"
                  set shpfiles  [UrbanX::GetBldHgtShpfile RCULUC]
                  Log::Print INFO "Using Buildings Height Shapefile(s): $shpfiles"
                  UrbanX::BuildingHeights2Raster  $shpfiles  ;# Rasterizes building heights
               } elseif { $Param(BuildingsShapefile)!="" } {
                  Log::Print INFO "Using Buildings Height Shapefile(s): $Param(BuildingsShapefile)"
                  UrbanX::BuildingHeights2Raster  $Param(BuildingsShapefile) ;# Rasterizes building heights
               }
            }
            if { [file exist $bld_height_file] } {
               Log::Print INFO "Adjusting BLDH with Buildings Height Raster"
               gdalband read RHAUTEURBLD [gdalfile open FHAUTEURBLD read $bld_height_file]
               gdalband stats RHAUTEURBLD -nodata 0;# memory fault if this comes after the gdalband write
               vexpr RHAUTEURBLD "ifelse(RHAUTEURBLD>0 && RHAUTEURBLD < 4.5,4.5,RHAUTEURBLD)"

               fstdfield fromband $Grid.B3DH RHAUTEURBLD IJCULUC AVERAGE
               gdalband free RHAUTEURBLD
               gdalfile close FHAUTEURBLD
            } else {
               Log::Print WARNING "Buildings Height Raster file not found: $bld_height_file"
            }
         }
         if { $nomvar == "BLDH" && $Param(OptionalTEBParams) } {
            if  { $NeedHMIN } {
               #----- Building height min computation
               Log::Print INFO "Computing Building Height Minimum HMIN (IP1=0) values over $Param(NTSSheet)"
               fstdfield fromband $Grid.HMIN RTEBPARAM IJCULUC MINIMUM

            }

            if  { $NeedHMAX } {
               #----- Building height max computation
               Log::Print INFO "Computing Building Height Maximum HMAX (IP1=0) values over $Param(NTSSheet)"
               fstdfield fromband $Grid.HMAX RTEBPARAM IJCULUC MAXIMUM
            }
         }

         gdalband free RTEBPARAM
      }
      gdalband free RCULUC IJCULUC
      gdalfile close FCULUC
   }

   # Computing the teb fields with all NTS sheets
   foreach tebparam $tebparams_list {

      set   nomvar [tebparam2nomvarip1 $tebparam]
      set   ip1     [lindex $nomvar 1]
      set   nomvar  [lindex $nomvar 0]

      if { $LoadedField($tebparam)  == False } {
         fstdfield gridinterp $Grid.$tebparam - NOP True ;# to conclude the AVERAGE computations on all NTS sheets
      }

# UGLY PATCH for NATF, set all 0 "zero" to 1.0 , where no data is available
      if { [string compare $nomvar "NATF"] == 0 } {
         vexpr $Grid.$tebparam "ifelse($Grid.$tebparam==0,1,$Grid.$tebparam)"
      }
      if { [string compare $nomvar "BLDH"] == 0 } {
         fstdfield gridinterp $Grid.B3DH - NOP True ;# to conclude the AVERAGE computations on all NTS sheets
         fstdfield define $Grid.B3DH -NOMVAR B3DH -IP1 $ip1
         fstdfield write $Grid.B3DH GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress) ;
         vexpr $Grid.$tebparam "ifelse($Grid.B3DH > 4.0 && $Grid.BLDF>0.0,$Grid.B3DH,$Grid.$tebparam)"
#         vexpr $Grid.$tebparam "ifelse($Grid.$tebparam < 8.0 && $Grid.$tebparam>0.0,8.0,$Grid.$tebparam)"
         fstdfield free $Grid.B3DH
if { 0 } {
         vexpr $Grid.$tebparam "ifelse($Grid.B3DH > 0.0,$Grid.B3DH,$Grid.$tebparam)"
         vexpr $Grid.$tebparam "max($Grid.B3DH, $Grid.$tebparam)"
}
      }

      # Writing result to gridfile
      fstdfield define $Grid.$tebparam -NOMVAR $nomvar -IP1 $ip1 -ETIKET $Param(RevisionETIKET)
      if { $nomvar == "VF"} {
         fstdfield write $Grid.$tebparam GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress) ;# Writing VF fields to the OutFile
      } else {
         fstdfield write $Grid.$tebparam GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress) ;# Writing TEB-only fields to the AuxFile
      }
   }
}

# free all fields in a loop after the previous one because BLDF is needed when finalizing BLDH
   foreach tebparam $tebparams_list {
      fstdfield free $Grid.$tebparam
   }

   if { $Param(OptionalTEBParams) } {
      set  list {}
      if  { $NeedHMIN } {
         lappend list HMIN
      }
      if  { $NeedHMAX } {
         lappend list HMAX
      }
      foreach  tebparam $list {
         set   ip1     0
         set   nomvar  $tebparam

         fstdfield gridinterp $Grid.$tebparam - NOP True ;# to conclude the AVERAGE computations on all NTS sheets
      # Writing result to gridfile
         fstdfield define $Grid.$tebparam -NOMVAR $nomvar -IP1 $ip1 -ETIKET $Param(RevisionETIKET)
         fstdfield write $Grid.$tebparam GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress) ;# Writing TEB-only fields to the AuxFile
         fstdfield free $Grid.$tebparam
      }
   }

# HVAR calculation, we can't do it in the same foreach NTSSheet because of a gridinterp False conflict
   if { $Param(OptionalTEBParams) && $NeedHVAR } {
      # Building height variance computation
      # the factor 5x is for the internal buffers of the AVERAGE_VARIANCE fct... is this formulae right?
      set memoryrequired [expr 5*$Param(Width)*$Param(Height)*8/(1024*1024)] ;
      # -1 means that we don't even try to do it at the moment... will need to test on a 64 bits OS...
      if { $memoryrequired > -1 } {
      # Changed test to systematically bypass HVAR (was > 1600) since it's causing trouble to some
         Log::Print INFO "HVAR: target grid size too large, memory requirements over $memoryrequired megs. Until we compile 64 bits, can't compute Building Height Variance (HVAR) $Param(NTSSheet)"
      } else {
         fstdfield copy $Grid.HVAR $Grid
         GenX::GridClear $Grid.HVAR 0.0

         fstdfield read BLDHFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDH"

         set tebparam "BLDH"
         foreach sheet $all_sheets {
            set Param(NTSSheet) $sheet
            set  culucfilename [UrbanX::GetULUCFilename $sheet]
            if { [file exists $culucfilename] } {
               if { [catch { gdalband read RCULUC [gdalfile open FCULUC read $culucfilename] }] } {
                  Log::Print ERROR "ERROR: Can't read: $culucfilename"
                  Log::End 1;
               }
               gdalfile close FCULUC
            } else {
               continue
            }

            Log::Print DEBUG "Copying the $tebparam values to the 5m raster with LUT over $Param(NTSSheet)"
            vexpr (Float32)RTEBPARAM lut(RCULUC,CSVTEBPARAMS.CULUC_Class,CSVTEBPARAMS.$tebparam)
            vexpr RTEBPARAM ifelse(RCULUC==0, -9999, RTEBPARAM)
            gdalband stats RTEBPARAM -nodata -9999 ;# memory fault if this comes after the gdalband write

            Log::Print INFO "Computing Building Height Variance HVAR (IP1=0) values over $Param(NTSSheet) (RAM needed: $memoryrequired)"
            fstdfield gridinterp $Grid.HVAR RTEBPARAM AVERAGE_VARIANCE BLDHFIELD False

            gdalband free RTEBPARAM
            gdalband free RCULUC
            }

         fstdfield gridinterp $Grid.HVAR - NOP True ;# to conclude the AVERAGE_VARIANCE computations on all NTS sheets
         fstdfield define $Grid.HVAR -NOMVAR HVAR -IP1 0 -ETIKET $Param(RevisionETIKET)
         fstdfield write $Grid.HVAR GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress) ;# Writing TEB-only fields to the AuxFile
         fstdfield free $Grid.HVAR
         fstdfield free BLDHFIELD
      }
   }

   vector free CSVTEBPARAMS

# temporary 3 lines followed is for Fixing NATF problem
   set fields [fstdfield find GPXAUXFILE -1 "" -1 -1 -1 "" "NATF"]
   if { [llength $fields] > 0 } {
      fstdfield read NATFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "NATF"
      vexpr NATFFIELD  "ifelse(NATFFIELD==0,1,NATFFIELD)"
      fstdfield write NATFFIELD GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   # Balancing BLDF versus PAVF values and redistribute the other parameters accordingly
#   UrbanX::Balance_BLDFvsPAVF

   # Need to re-normalize VF due to changes made to PAVF and BLDF
#   UrbanX::NormalizeVFvsPAVFBLDF
#   return

   fstdfield read Z0RDFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "Z0RD"
   fstdfield read Z0RFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "Z0RF"
   fstdfield read BLDHFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDH"
   fstdfield read BLDWFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDW"
   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF"
   fstdfield read NATFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "NATF"

   # WALL-O-HOR formulae provided by Sylvie Leroyer
   # bldw ---> mean width of building (BLDWFIELD)  --> add column 

   # Wall-O-Hor calculation
   Log::Print INFO "Computing geometric TEB parameter Wall-O-Hor WHOR (IP1=0) values over target grid"
   GenX::GridClear $Grid 0.0
   # WALL-O-HOR formulae provided by SL in wich the vegetation surface is withdrawn
   Log::Print INFO "Computing geometric TEB parameter Wall-O-Hor WHOR (IP1=0) values over target grid"
   vexpr WHORFIELD "ifelse(NATFFIELD==1||BLDWFIELD==0,0,BLDHFIELD*2.0*BLDFFIELD/(BLDWFIELD *(1.0-NATFFIELD)))" ;#ifelse required to avoid division by 0

   fstdfield define WHORFIELD -NOMVAR WHOR -IP1 0 -ETIKET $Param(RevisionETIKET)
   fstdfield write WHORFIELD GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   # Z0_TOWN calculation
   Log::Print INFO "Computing geometric TEB parameter Z0_TOWN Z0TW (IP1=0) values with the MacDonald 1998 Model over target grid"
   GenX::GridClear $Grid 0.0

   vexpr DISPH BLDHFIELD*(1+(4.43^(BLDFFIELD*(-1.0))*(BLDFFIELD-1.0))) ;# Computing Displacement height
# Can't compute this as is because (a^(-0.5)) will give NaN if a is 0
if { 0 } {
   vexpr $Grid ifelse(BLDHFIELD==0,0, BLDHFIELD*((1.0-DISPH/BLDHFIELD)*exp(-1.0*((0.5*1.0*1.2/0.4^2*((1.0-DISPH/BLDHFIELD)*(WHORFIELD/2.0)))^( -0.5))))) ;# ifelse required to avoid dividing by 0
} else {
   vexpr TMPFIELD ifelse(BLDHFIELD==0,0, 0.5*1.0*1.2/0.4^2*((1.0-DISPH/BLDHFIELD)*(WHORFIELD/2.0)))
   vexpr TMPFIELD ifelse(TMPFIELD==0,0, TMPFIELD^(-0.5))
   vexpr $Grid ifelse(BLDHFIELD==0,0, BLDHFIELD*((1.0-DISPH/BLDHFIELD)*exp(-1.0*TMPFIELD))) ;
}
   vexpr $Grid ifelse(BLDFFIELD>0.9,max(Z0RFFIELD,$Grid),$Grid)  ;# we are on a roof surface --> use roof Z0
   vexpr $Grid ifelse(PAVFFIELD>0.9,max(Z0RDFIELD,$Grid),$Grid)  ;# we are on a paved surface --> use paved Z0
   fstdfield define $Grid -NOMVAR Z0TW -IP1 0
   fstdfield write $Grid GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   if { $Param(OptionalTEBParams) } {
      # SUMF calculation
      Log::Print INFO "Computing SUMF: sum of NATF, BLDF and PAVF, for validation purposes"
      GenX::GridClear $Grid 0.0
      vexpr $Grid NATFFIELD+BLDFFIELD+PAVFFIELD
      fstdfield define $Grid -NOMVAR SUMF -IP1 0
      fstdfield write $Grid GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   
      # DPBH calculation
      Log::Print INFO "Computing TEB parameter DISPBLDH DPBH (IP1=0) values over target grid"
      vexpr DISPBLDH ifelse(BLDHFIELD==0,0, DISPH/BLDHFIELD)
      fstdfield define DISPBLDH -NOMVAR DPBH -IP1 0
      fstdfield write DISPBLDH GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

      # Z0ZH calculation
      Log::Print INFO "Computing TEB parameter Z0ZH Z0H (IP1=0) values over target grid"
      vexpr Z0ZH ifelse(BLDHFIELD==0,0, $Grid/BLDHFIELD)
      fstdfield define Z0ZH  -NOMVAR Z0H -IP1 0
      fstdfield write Z0ZH GPXAUXFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }
   fstdfield free BLDHFIELD BLDWFIELD BLDFFIELD NATFFIELD WHORFIELD REZ SURFTILE Z0RDFIELD Z0RFFIELD PAVFFIELD WHOR2FIELD WHOR3FIELD Z0ZH DISPBLDH DISPH

   Log::Print INFO "The file $GenX::Param(OutFile)_aux.fst has been updated with TEB parameters"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::BuildingHeights2Raster>
# Creation : Circa 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Converting buildings shapefiles to raster
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::BuildingHeights2Raster { {shpfiles ""} } {
   variable Param

   GenX::Procs
   Log::Print INFO "Converting 2.5D buildings shapefile to raster"
   Log::Print INFO "Shapefiles: $shpfiles"

   if { $shpfiles == "" } {
      set shpfiles $Param(BuildingsShapefile)
   }

   gdalband create RHAUTEURBLD $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURBLD -georef $Param(SheetGeoRef)
   gdalband clear RHAUTEURBLD 0.0

   foreach shpfile $shpfiles {
      set shp_layer [lindex [ogrfile open SHAPE read $shpfile] 0]
      eval ogrlayer read LAYER $shp_layer


      gdalband gridinterp RHAUTEURBLD LAYER $Param(Mede) $Param(BuildingsHgtField)

      Log::Print INFO "All buildings shorter than 4.5m set to an height of 4.5m"
      vexpr RHAUTEURBLD ifelse(RHAUTEURBLD<4.5 && RHAUTEURBLD>0,4.5,RHAUTEURBLD)

      ogrlayer free LAYER
      ogrfile close SHAPE
   }

   set bld_height_file "$GenX::Param(TMPDIR)/$Param(NTSSheet)_Building-heights.tif"
   set bld_height_file "$Param(BLDH_PATH)/$Param(NTSSheet)_Building-heights.tif"

   file delete -force $bld_height_file
   gdalfile open FILEOUT write $bld_height_file GeoTiff
   gdalband write RHAUTEURBLD FILEOUT
   gdalfile close FILEOUT
   Log::Print INFO "The file $bld_height_file has been generated"

   gdalband free RHAUTEURBLD
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::3DBuildings2Sandwich>
# Creation : March 2011- Alexandre Leroux - CMC/CMOE
#
# Goal     : Overwriting Sandwich by adding 3D buildings data
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::3DBuildings2Sandwich { Coverage } {
   variable Param

   GenX::Procs
   Log::Print INFO "Overwriting $Coverage CanVec sandwich by adding vector 3D buildings"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif]
   gdalband read RHAUTEURBLD [gdalfile open FHAUTEURBLD read $GenX::Param(TMPDIR)/$Param(NTSSheet)_Building-heights.tif]

   Log::Print INFO "Adding new-only buildings to priority 104 (unknown or other 2D buildings)"
   #----- On ignore les priorités <= 106 puisqu'elles sont soit des bâtiments existants soit au-dessus des bâtiments
   vexpr RSANDWICH ifelse(((RHAUTEURBLD>0) && (RSANDWICH>=106)),104,RSANDWICH)

   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT
   Log::Print INFO "The file $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif was overwritten"

   gdalfile close FSANDWICH FHAUTEURBLD FILEOUT
   gdalband free RSANDWICH RHAUTEURBLD
}


#----------------------------------------------------------------------------
# Name     : <UrbanX::3DBld2TEBGeoParams>
# Creation : March 2011 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Compute TEB parameters on a 100m raster
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::3DBld2TEBGeoParams { Grid } {
   variable Param

   GenX::Procs
   Log::Print INFO "Computing TEB geometric parameters using the 2.5D buildings"

   # Building heights average
   gdalband read RHAUTEURBLD [gdalfile open RHAUTEURBLDFILE read $GenX::Param(TMPDIR)/$Param(NTSSheet)_Building-heights.tif]
   gdalband stats RHAUTEURBLD -nodata 0 ;# to average buildings without empty spaces
   fstdfield stats $Grid -nodata 0 ;# Required to avoid NaN in the gridinterp AVERAGE over nodata-only values

   Log::Print INFO "Overwriting building heights average (BLDH) where there are 2.5D buildings"
   GenX::GridClear $Grid 0.0
   fstdfield gridinterp $Grid RHAUTEURBLD AVERAGE
   fstdfield copy BLDHEXTENT $Grid ;# BLDHEXTENT is needed below

   fstdfield read BLDHFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDH" ;# BLDH before the addition of 2.5D buildings BLDH
   vexpr $Grid ifelse($Grid==0, BLDHFIELD, $Grid) ;# to overwrite only where there is 2.5D data
   fstdfield free BLDHFIELD ;# invalid field because it has been overwritten

   fstdfield define $Grid -NOMVAR BLDH -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)

   # Update HMIN and HMAX only if the optional TEB parameters are computed
   if { $Param(OptionalTEBParams) } {
      #----- Building height min computation
      Log::Print INFO "Overwriting Building Height Minimum HMIN (IP1=0) where there are 2.5D buildings"
      GenX::GridClear $Grid 0.0
      fstdfield gridinterp $Grid RHAUTEURBLD MINIMUM

      fstdfield read HMINFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "HMIN" ;# HMIN before the addition of 2.5D buildings HMIN
      vexpr $Grid ifelse($Grid==0, HMINFIELD, $Grid) ;# to overwrite only where there is 2.5D data
      fstdfield free HMINFIELD ;# invalid field because it has been overwritten

      fstdfield define $Grid -NOMVAR HMIN -IP1 0
      fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)

      #----- Building height max computation
      Log::Print INFO "Overwriting Building Height Maximum HMAX (IP1=0) where there are 2.5D buildings"
      GenX::GridClear $Grid 0.0
      fstdfield gridinterp $Grid RHAUTEURBLD MAXIMUM

      fstdfield read HMAXFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "HMAX" ;# HMAX before the addition of 2.5D buildings HMAX
      vexpr $Grid ifelse($Grid==0, HMAXFIELD, $Grid) ;# to overwrite only where there is 2.5D data
      fstdfield free HMAXFIELD ;# invalid field because it has been overwritten

      fstdfield define $Grid -NOMVAR HMAX -IP1 0
      fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)
   }

   #----- Building fraction
   Log::Print INFO "Overwriting building fraction (BLDF) where there are 2.5D buildings"
   GenX::GridClear $Grid 0.0

   vexpr REZ (ddx($Grid)+ddy($Grid))/2  ;# spatial resolution of the target grid in meters
   set res [fstdfield stats REZ -avg]
   fstdfield free REZ

   set facteurfraction [expr 1/pow($res/$Param(Resolution),2)]
   vexpr RSURFACEBLD ifelse(RHAUTEURBLD==0,0,$facteurfraction)      ;# creates RSURFACEBLD
   gdalband free RHAUTEURBLD
   # fstdfield gridinterp $Grid RSURFACEBLD SUM   ;# can't use at the moment: double-counting de tous les pixels on the edge
   fstdfield gridinterp $Grid RSURFACEBLD CONSERVATIVE 1 True

   # BUG DE DOUBLE COUNTING DES POLYGONES SE CHEVAUCHANT (reswitcher à fraction raster?)
   #         set shp_layer [lindex [ogrfile open SHAPE read $Param(BuildingsShapefile)] 0]
   #         eval ogrlayer read LAYER $shp_layer
   #         set starttime [clock seconds]
   #         gdalband gridinterp RBLDFRACTION LAYER CONSERVATIVE FEATURE_AREA
   ##         gdalband gridinterp RBLDFRACTION LAYER NORMALIZE FEATURE_AREA
   #         Log::Print DEBUG "Time taken for VECTOR CONSERVATIVE fraction [expr [clock seconds]-$starttime] seconds"
   ##         Log::Print DEBUG "Time taken for VECTOR NORMALIZE fraction [expr [clock seconds]-$starttime] seconds"
   ## normalize puis enlever next line
   #         vexpr RBLDFRACTION RBLDFRACTION/($res*$res) ;# To get a fraction between 0 and 1
   #         ogrlayer free LAYER
   #         ogrfile close SHAPE

   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   vexpr $Grid ifelse($Grid==0, BLDFFIELD, $Grid) ;# to overwrite only where there is 2.5D data
   fstdfield free BLDFFIELD ;# invalid field because it has been overwritten

   fstdfield define $Grid -NOMVAR BLDF -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)

   #----- Updating NATF and PAVF
   Log::Print INFO "Updating NATF and PAVF according to new BLDF where there are 2.5D buildings"

   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   fstdfield read NATFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "NATF"
   fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF"

   GenX::GridClear $Grid 0.0
   vexpr NEWNATFFIELD NATFFIELD/(NATFFIELD+PAVFFIELD)*(1-BLDFFIELD) ;# BLDFFIELD is the new one
   vexpr $Grid ifelse(BLDHEXTENT>0, NEWNATFFIELD, NATFFIELD) ;# Overwriting only over 2.5D buildings extent
   fstdfield free NEWNATFFIELD

   fstdfield define $Grid -NOMVAR NATF -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)

   GenX::GridClear $Grid 0.0
   vexpr NEWPAVFFIELD PAVFFIELD/(NATFFIELD+PAVFFIELD)*(1-BLDFFIELD) ;# BLDFFIELD is the new one
   vexpr $Grid ifelse(BLDHEXTENT>0, NEWPAVFFIELD, PAVFFIELD) ;# Overwriting only over 2.5D buildings extent
   fstdfield free NEWPAVFFIELD BLDHEXTENT

   fstdfield define $Grid -NOMVAR PAVF -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)
   fstdfield free NATFFIELD PAVFFIELD BLDFFIELD ;# Freeing because they don't reflect what's in the grid anymore

   # Balancing BLDF versus PAVF values and redistribute the other parameters accordingly
   UrbanX::Balance_BLDFvsPAVF

   # Need to re-normalize VF due to changes made to PAVF and BLDF
   UrbanX::NormalizeVFvsPAVFBLDF

   If { $Param(OptionalTEBParams) } {
      #----- Updating SUMF
      Log::Print INFO "Updating SUMF using the new BLDF, NATF and PAVF values"
      fstdfield read NATFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "NATF" ;# Reading the updated values
      fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF" ;# Reading the updated values
      fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"

      GenX::GridClear $Grid 0.0
      vexpr $Grid BLDFFIELD+NATFFIELD+PAVFFIELD
      fstdfield define $Grid -NOMVAR SUMF -IP1 0
      fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)
      fstdfield free PAVFFIELD NATFFIELD
   }

   #----- WALL_O_HOR
   Log::Print INFO "Overwriting WALL_O_HOR (WHOR) where there are 2.5D buildings"

   fstdfield read BLDHFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDH"
   fstdfield read NATFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "NATF" ;# Reading the updated values
   fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF" ;# Reading the updated values
   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   GenX::GridClear $Grid 0.0

   #----- WALL-O-HOR formulae provided by Sylvie Leroyer
   set facteurWoH1 [expr 2.0/pow(($res),2)]
   set facteurWoH2 [expr pow($res,2)]
   vexpr $Grid BLDHFIELD*$facteurWoH1*(sqrt(BLDFFIELD*$facteurWoH2))

   # WALL-O-HOR formulae provided by SL in wich the vegetation surface is withdrawn
   GenX::GridClear $Grid 0.0
   vexpr SURFTILE (ddx($Grid)*ddy($Grid))  ;# tile surface of the target grid in meters^2
   vexpr $Grid ifelse(NATFFIELD==1,0,BLDHFIELD*(2.0/(SURFTILE*(1.0-NATFFIELD)))*(sqrt(BLDFFIELD*SURFTILE))) ;#ifelse required to avoid division by 0

   fstdfield read WHORFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "WHOR"
   vexpr $Grid ifelse($Grid==0, WHORFIELD, $Grid) ;# to overwrite only where there is 2.5D data
   fstdfield free WHORFIELD ;# invalid field because it has been overwritten

   fstdfield define $Grid -NOMVAR WHOR -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)

   #----- Z0_TOWN
   Log::Print INFO "Overwriting Z0_TOWN (Z0TW) where there are 2.5D buildings with the MacDonald 1998 Model"
   fstdfield read WHORFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "WHOR"

   #----- Note: the ^ operator can be used in vexpr, but not in expr
   vexpr RDISPH BLDHFIELD*(1+(4.43^(BLDFFIELD*(-1.0))*(BLDFFIELD - 1.0)))
   vexpr $Grid ifelse(BLDHFIELD==0,0,BLDHFIELD*((1.0-RDISPH/BLDHFIELD)*exp( -1.0*((0.5*1.0*1.2/0.4^2*((1.0-RDISPH/BLDHFIELD)*(WHORFIELD/2.0)))^( -0.5)))))

   #Log::Print INFO "Computing Z0_TOWN at $res\m with the Raupach 1994 Model"
   #vexpr RDISPLACEMENTHEIGHT RBLDHAVG*(1+(exp(-1.0*(7.5*2.0*RWALLOHOR/2.0)^0.5-1.0)/(7.5*2.0*RWALLOHOR/2.0)^0.5))
   #vexpr RZ0TOWN RBLDHAVG*((1.0-RDISPLACEMENTHEIGHT/RBLDHAVG)*exp((-1.0)*0.4/min((0.003+0.3*RWALLOHOR/2.0)^0.5,0.3)+0.193))

   fstdfield read Z0TWFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "Z0TW"
   fstdfield read Z0RDFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "Z0RD"
   fstdfield read Z0RFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "Z0RF"

   vexpr $Grid ifelse($Grid==0, Z0TWFIELD, $Grid) ;# to overwrite only where there is 2.5D data
   vexpr $Grid ifelse(BLDFFIELD>0.9,max(Z0RFFIELD,$Grid),$Grid)
   vexpr $Grid ifelse(PAVFFIELD>0.9,max(Z0RDFIELD,$Grid),$Grid)
   fstdfield free Z0TWFIELD ;# invalid field because it has been overwritten

   fstdfield define $Grid -NOMVAR Z0TW -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)

   fstdfield free BLDHFIELD BLDFFIELD NATFFIELD PAVFFIELD WHORFIELD RDISPH SURFTILE
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FilterGen>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#   <Type>   :
#   <Size>   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::FilterGen { Type Size } {

   GenX::Procs

   #----- Est-ce cette proc maintenant dans le 'main code' de JP?
   #      Il manque les filtres median, directionel, lp/hp gaussien, Sobel/Roberts, FFT
   if { $Size%2 == 0 } {
      set Size [expr ($Size -1)]
      Log::Print WARNING "Filter size must be an odd number, decreasing filter size to $Size"
   }

   set kernel { }

   switch $Type {
      "LOWPASS" {
         for { set i 0 } { $i < $Size } {  incr i } {
            set line { }
            for { set j 0 } { $j < $Size } {  incr j } {
               lappend line 1
            }
            lappend kernel $line
         }
      }

      "HIGHPASS" {
         set mid [expr ($Size/2.0)]
         for { set i 0 } { $i < $Size } {  incr i } {
            set line { }
            for { set j 0 } { $j < $Size } {  incr j } {
               if { ($mid > $i) && ($mid < ($i + 1)) && ($mid > $j) && ($mid < ($j + 1)) } {
                  lappend line [expr ($Size * $Size - 1)]
               } else {
                  lappend line -1
               }
            }
            lappend kernel $line
         }
      }
   }

   return $kernel
}

#----------------------------------------------------------------------------
# Name     : <BLDF_Top_Filter>
# Creation : October 2011 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : replace all values greater than a threshold
#            with nearby average if any
#
# Parameters :
#   <Grid>        : Grid to process
#   <threshold>   : limit of acceptable value
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::BLDF_Top_Filter { Grid threshold } {

   set ni [fstdfield define $Grid -NI]
   set nj [fstdfield define $Grid -NJ]

   set changed 0
   for { set j 0 } { $j < $nj } {incr j} {
      for { set i 0 } { $i < $ni } {incr i} {
         set val  [fstdfield stats $Grid -gridvalue $i $j]
         switch -regexp -- $val {
            .NaN {
               set val $threshold
            }
            default {
            }
         }

         if { $val >= $threshold } {
#            puts "Averaging:  $i $j : $val"
            set value $val
            set range 1
            while {($value >= $threshold)&&($range <= 2)} {
               set value [UrbanX::Grid_NearestAverage $Grid $i $j $range]
               incr range
            }
            if { $value < $threshold } {
               fstdfield stats $Grid -gridvalue $i $j $value
#               puts "Replaced $val by $value at ($i $j) range=$range"
               incr changed
            }
         }
      }
   }
   return $changed
}

#----------------------------------------------------------------------------
# Name     : <Balance_BLDFvsPAVF>
# Creation : October 2011 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : check consistency between BLDF and PAVF
#            for case where:
#               (pavf > 0) and (bldf == 0)
#                   find avg coarser value of bldf
#                   or  bldf=0.01*pavf
#               (pavf == 0) and (bldf > 0)
#                   find avg coarser value of pavf
#                   or  pavf=0.01*bldf
#
# Parameters : none
#
# Return:
#
#----------------------------------------------------------------------------
proc UrbanX::Balance_BLDFvsPAVF { } {

   UrbanX::Preload_PavBldParams

   set GridBLDF WKBLDFFIELD
   set GridPAVF WKPAVFFIELD

   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF"

   fstdfield copy $GridBLDF BLDFFIELD
   fstdfield copy $GridPAVF PAVFFIELD

   set ni [fstdfield define $GridBLDF -NI]
   set nj [fstdfield define $GridBLDF -NJ]

   set cnt_bogus_bldf 0
   set cnt_bogus_pavf 0
   set cnt_found_bldf 0
   set cnt_found_pavf 0

   set maxrange 2
   for { set j 0 } { $j < $nj } {incr j} {
      for { set i 0 } { $i < $ni } {incr i} {

         set pavf  [fstdfield stats PAVFFIELD -gridvalue $i $j]
         set bldf  [fstdfield stats BLDFFIELD -gridvalue $i $j]

         if { ($pavf > 0.0)&&($bldf == 0) } {
            set range 0
            while {($bldf == 0)&&($range < $maxrange)} {
               incr range
               set bldf [UrbanX::Grid_NearestAverage BLDFFIELD $i $j $range]
            }
            if { $bldf == 0.0 } {
               set bldf [expr 0.01*$pavf]
               incr cnt_bogus_bldf
               # must set associated TEB params using default values from LUT
               UrbanX::Assign_DefaultPAVFBLDF $i $j $pavf
            } else {
               incr cnt_found_bldf
               # must set associated TEB params using Nearest Average also
               UrbanX::Assign_AverageParams $i $j $range $bldf $pavf
            }
            # remove from PAVF what we added to BLDF if (bldf+pavf)>1.0
            set sum [expr $pavf + $bldf]
            if  { $sum > 1.0 } {
               set pavf [expr 1.0 - $bldf]
               fstdfield stats $GridPAVF -gridvalue $i $j $pavf
            }
            fstdfield stats $GridBLDF -gridvalue $i $j $bldf
         } elseif { ($pavf == 0)&&($bldf > 0.0) } {
            set range 0
            while {($pavf == 0)&&($range < $maxrange)} {
               incr range
               set pavf [UrbanX::Grid_NearestAverage PAVFFIELD $i $j $range]
            }
            if { $pavf == 0.0 } {
               set pavf [expr 0.01*$bldf]
               incr cnt_bogus_pavf
               # must set associated TEB params using default values from LUT
               UrbanX::Assign_DefaultPAVFBLDF $i $j $pavf
            } else {
               # Impose max building fraction to avoid 0**(-0.5) in Z0_TOWN calculation
               if { $bldf > 0.99 } {
                  set bldf 0.99
                  set pavf 0.01
               }
               incr cnt_found_pavf
               # must set associated TEB params using Nearest Average also
               UrbanX::Assign_AverageParams $i $j $range $bldf $pavf
            }

            fstdfield stats $GridPAVF -gridvalue $i $j $pavf
            set sum [expr $pavf + $bldf]
            if  { $sum > 1.0 } {
               set bldf [expr 1.0 - $pavf]
               fstdfield stats $GridBLDF -gridvalue $i $j $bldf
            }
            # must set associated TEB params using Nearest Average also
            UrbanX::Assign_AverageParams $i $j $range $bldf $pavf
         } elseif { ($pavf > 0.0)&&($bldf > 0.0) } {
            set sum [expr $pavf + $bldf]
            if  { $sum > 1.0 } {
               set bldf [expr 1.0 - $pavf]
               fstdfield stats $GridBLDF -gridvalue $i $j $bldf
            }
            UrbanX::Check_HasPAVFBLDF $i $j $bldf $pavf
         }
      }
   }

   Log::Print INFO "Bogused BLDF=$cnt_bogus_bldf   Found coarser BLDF=$cnt_found_bldf"
   Log::Print INFO "Bogused PAVF=$cnt_bogus_pavf   Found coarser PAVF=$cnt_found_pavf"

   set changed [expr $cnt_bogus_pavf+$cnt_bogus_bldf+$cnt_found_bldf+$cnt_found_pavf]

   set  auxfile  GPXAUXFILE

   fstdfield define $GridPAVF -NOMVAR PAVF -IP1 0
   fstdfield write $GridPAVF $auxfile -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield define $GridBLDF -NOMVAR BLDF -IP1 0
   fstdfield write $GridBLDF $auxfile -$GenX::Param(NBits) True $GenX::Param(Compress)

   vexpr NATFFIELD  "1 - ($GridPAVF+$GridBLDF)"
   fstdfield define NATFFIELD -NOMVAR NATF -IP1 0
   fstdfield write NATFFIELD $auxfile -$GenX::Param(NBits) True $GenX::Param(Compress)
   Log::Print INFO "Rewrote NATF as 1-(BLDF+PAVF)"

   UrbanX::Save_LoadedPavBldParams $auxfile

   fstdfield free $GridPAVF $GridBLDF NATFFIELD
   UrbanX::Free_LoadedPavBLdParams

   return $changed
}

#----------------------------------------------------------------------------
# Name     : <Preload_PavBldParams>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Preloading all TEB params associated with BLDF and PAVF
#            We need to modify them at discreet grid point accordingly
#
# Parameters : none
#
# Return:
#
#----------------------------------------------------------------------------
proc UrbanX::Preload_PavBldParams { } {
   variable Param

   set    list $Param(BLDFvsLUT)
   append list $Param(PAVFvsLUT)

   foreach  p $list {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"
      if { $ip1 > 0 } {
         set ip1 [expr 1200-$ip1]
      }
      if { $nomvar == "VF" } {
         fstdfield read $PLVAR GPXOUTFILE -1 "" $ip1 -1 -1 "" "$nomvar"
      } else {
         fstdfield read $PLVAR GPXAUXFILE -1 "" $ip1 -1 -1 "" "$nomvar"
      }
   }
}

#----------------------------------------------------------------------------
# Name     : <Save_LoadedPavBldParams>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Save all TEB params associated with BLDF and PAVF
#
# Parameters :
#      auxfile   : output aux file
#
# Return:
#
#----------------------------------------------------------------------------
proc UrbanX::Save_LoadedPavBldParams { auxfile } {
   variable Param

   set    list $Param(BLDFvsLUT)
   append list $Param(PAVFvsLUT)

   foreach  p $list {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"
      fstdfield write $PLVAR $auxfile -$GenX::Param(NBits) True $GenX::Param(Compress)
   }
}

#----------------------------------------------------------------------------
# Name     : <Free_LoadedPavBLdParams>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : cleanup memory allocated for storing TEB params associated
#            with BLDF and PAVF
#
# Parameters :
#
# Return:
#
#----------------------------------------------------------------------------
proc UrbanX::Free_LoadedPavBLdParams { } {
   variable Param

   set    list $Param(BLDFvsLUT)
   append list $Param(PAVFvsLUT)

   foreach  p $list {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"
      fstdfield free $PLVAR
   }
}

#----------------------------------------------------------------------------
# Name     : <Assign_DefaultPAVFBLDF>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : assign default a value from LUT on TEB params associated
#            with BLDF and PAVF
#
# Parameters :
#      [ i  j ] :  grid point position
#
# Return:
#
#----------------------------------------------------------------------------
proc UrbanX::Assign_DefaultPAVFBLDF { i j pavf } {
   variable Param

   foreach  p $Param(BLDFvsLUT) {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"

      set value [lindex $p 2]
      # override default value of BLDW when PAVF == 1.0
      if { $pavf == 1.0 } {
         if { [string compare $nomvar "BLDW"] == 0 } {
            set value 50.0
         }
      }
      fstdfield stats $PLVAR -gridvalue $i $j $value
   }

   foreach  p $Param(PAVFvsLUT) {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"

      set value [lindex $p 2]
      fstdfield stats $PLVAR -gridvalue $i $j $value
   }
}

#----------------------------------------------------------------------------
# Name     : <Check_HasPAVFBLDF>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : check if associated TEB parameters of BLDF PAVF
#            has a value assigned, if not, assign a default from LUT
#
# Parameters :
#      [ i  j ] :  grid point position
#      bldf     :  current BLDF value
#      pavf     :  current PAVF value
#
# Return:
#
#----------------------------------------------------------------------------
proc UrbanX::Check_HasPAVFBLDF { i j bldf pavf } {
   variable Param

   set    list $Param(BLDFvsLUT)
   append list $Param(PAVFvsLUT)

   foreach  p $list {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"

      set value [fstdfield stats $PLVAR -gridvalue $i $j]
      if { $value == 0.0 } {
         set value [lindex $p 2]
         fstdfield stats $PLVAR -gridvalue $i $j $value
      }
   }
}

#----------------------------------------------------------------------------
# Name     : <Assign_AverageParams>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : assign an average value to all associated TEB parameters of BLDF PAVF
#            if no value found, assign a default from LUT
#
# Parameters :
#      [ i  j ] :  grid point position
#      range    :  Delta to look for values
#      bldf     :  current BLDF value
#      pavf     :  current PAVF value
#
# Return:
#
#----------------------------------------------------------------------------
proc UrbanX::Assign_AverageParams { i j range bldf pavf } {
   variable Param

   foreach  p $Param(BLDFvsLUT) {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"
      set value [UrbanX::Grid_NearestAverage $PLVAR $i $j $range]
# if there's nothing nearby then also use value from LUT
      if { $value <= 0 } {
         set value [lindex $p 2]
      }
      fstdfield stats $PLVAR -gridvalue $i $j $value
   }

   foreach  p $Param(PAVFvsLUT) {
      set nomvar [lindex $p 0]
      set ip1 [lindex $p 1]
      set PLVAR  "PB_$nomvar$ip1"
      set value [UrbanX::Grid_NearestAverage $PLVAR $i $j $range]
# if there's nothing nearby then also use value from LUT
      if { $value <= 0 } {
         set value [lindex $p 2]
      }
      fstdfield stats $PLVAR -gridvalue $i $j $value
   }
}

#----------------------------------------------------------------------------
# Name     : <Grid_NearestAverage>
# Creation : October 2011 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Obtain the average value near a grid point (i, j) within a range
#
# Parameters :
#   <Grid>     : Grid to process
#   <i0 j0>    : location of grid point
#   <range>    :
#
# Return: averaged value
#
# Remarks :
#    return 0.0 if no value found
#
#----------------------------------------------------------------------------
proc UrbanX::Grid_NearestAverage { Grid  i0  j0  range } {

   set ni [fstdfield define $Grid -NI]
   set nj [fstdfield define $Grid -NJ]

   set i1 [expr $i0 - $range]
   if { $i1 < 0 } {
      set i1 0
   }
   set j1 [expr $j0 - $range]
   if { $j1 < 0 } {
      set j1 0
   }
   set i2 [expr $i0 + $range]
   if { $i2 >= $ni } {
      set i2 [expr $ni-1]
   }
   set j2 [expr $j0 + $range]
   if { $j2 >= $nj } {
      set j2 [expr $nj-1]
   }

   set sum  0.0
   set cnt  0
   for { set j $j1 } { $j <= $j2 } { incr j } {
      for { set i $i1 } { $i <= $i2 } { incr i } {
         set val  [fstdfield stats $Grid -gridvalue $i $j]
         switch -regexp -- $val {
            0 {
            }
            .NaN {
            }
            default {
               set sum [expr $sum + $val]
               incr cnt
            }
         }
      }
   }

   if { $cnt == 0 } {
      return 0.0
   } else {
     return [expr $sum / $cnt]
   }
}

#----------------------------------------------------------------------------
# Name     : <NormalizeVFvsPAVFBLDF>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : make sure VF1 + VF2 + ... + VF21 + ... + VF26 + BLDF + PAVF = 1.0
#
# Parameters : none
#
# Return:
#
# Remarks :
#   BLDF and PAVF are fixed, only VF values are rescale to fit
#
#----------------------------------------------------------------------------
proc UrbanX::NormalizeVFvsPAVFBLDF { } {

   set  VegeTypes {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 22 23 24 25 26}

   fstdfield read NATFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "NATF"
   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF"

   fstdfield copy SumVF NATFFIELD
   GenX::GridClear SumVF 0.0
#
# VF21 must be 0.0 already here
#
   foreach type $GeoPhysX::Param(VegeTypes) {
      fstdfield read GPXVF GPXOUTFILE -1 "" [expr 1200-$type] -1 -1 "" "VF"
      vexpr SumVF  "SumVF + GPXVF"
   }

   vexpr KFIELD  "BLDFFIELD + PAVFFIELD"
   vexpr SFIELD  "ifelse(SumVF==0.0,1.0,(1.0-KFIELD)/SumVF)"
   GenX::GridClear SumVF 0.0

   foreach type $VegeTypes {
      fstdfield read GPXVF GPXOUTFILE -1 "" [expr 1200-$type] -1 -1 "" "VF"
      vexpr GPXVF  "GPXVF * SFIELD"
      vexpr SumVF  "SumVF + GPXVF"
      fstdfield define GPXVF -NOMVAR VF -IP1 [expr 1200-$type]
      fstdfield write GPXVF GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   }

   vexpr GPXVF  "SumVF - NATFFIELD"
   set min  [lindex [fstdfield stats GPXVF -min] 0]
   set max  [lindex [fstdfield stats GPXVF -max] 0]
   Log::Print INFO "Checking difference between NATF and normalized Sum(VF1..26): min=$min max=$max"

   vexpr SumVF  "SumVF + BLDFFIELD + PAVFFIELD"
   set min  [lindex [fstdfield stats SumVF -min] 0]
   set max  [lindex [fstdfield stats SumVF -max] 0]
   Log::Print INFO "Checking Sum(VF1..26) + BLDF + PAVF: min=$min max=$max"
   fstdfield define SumVF -NOMVAR SUMV -IP1 0
   fstdfield write SumVF GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free PAVFFIELD BLDFFIELD NATFFIELD GPXVF SumVF
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::DominantVege>
# Creation : Jan 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : generate VG field for UrbanX
#
# Parameters :
#
# Return:
#
# Remarks :
#   BLDF and PAVF are fixed, only VF values are rescale to fit
#
#----------------------------------------------------------------------------
proc UrbanX::DominantVege { Grid } {

   # generate VF21 temporary for computation of VG
   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF"

   vexpr VF21 "BLDFFIELD + PAVFFIELD"
   fstdfield define VF21 -NOMVAR VF -IP1 [expr 1200-21]
   fstdfield write VF21 GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)
   fstdfield free VF21

   GeoPhysX::DominantVege $Grid ;# Adding DominantVG "VG IP1=0"

   #  VF21 output from UrbanX must be cleared as 0.0
   fstdfield copy VF21FIELD $Grid
   GenX::GridClear VF21FIELD 0.0
   fstdfield define VF21FIELD -NOMVAR VF -IP1 [expr 1200-21]
   fstdfield write VF21FIELD GPXOUTFILE -$GenX::Param(NBits) True $GenX::Param(Compress)

   fstdfield free VF21FIELD BLDFFIELD PAVFFIELD
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::DeleteTempFiles>
# Creation : January 2011 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Delete all temporary files generated by UrbanX
#
# Parameters :
#   <Type>   :
#   <Size>   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------

proc UrbanX::DeleteTempFiles { Ntssheet } {
   variable Param
   Log::Print INFO "Deleting all $Ntssheet temporary files"

   set Param(NTSSheet) $Ntssheet ;# for global find and replaces to work properly

   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_LCC2000V-LUT.tif
   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_hauteur-classes.tif
   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens-builtup.tif
   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_popdens.tif
   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_champs-only+building-vicinity.tif
   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_sandwich.tif
   file delete -force $GenX::Param(TMPDIR)/$Param(NTSSheet)_Building-heights.tif
# WE SHOULD REMOVE THE TMPDIR ITSELF ONCE THE CULUC FILES ARE FOUND ELSEWHERE
#   file rmdir $GenX::Param(TMPDIR)
}


#----------------------------------------------------------------------------
# Name     : <UrbanX::Utilitaires>
# Creation : Octobre 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Various functions that are not commonly
#                  used in UrbanX process but might be
#                  useful before of after the main process
#
# Parameters :
#   <Type>   :
#   <Size>   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Utilitaires { } {
   variable Param

# This could be a 'switch' with the name of the Util

   #RÉINITIALISATION D'UN FICHIER DE DA
#    puts "Utilitaire pour réinitialiser toutes les colonnes SMOKE d'un fichier de polygones de DA"
#    set fichierDA /data/aqli04/afsulub/StatCan2006/SMOKE_FILLED/da2006-nts_lcc-nad83_PRECISERLENOM.shp
#    puts "Fichier à traiter : $fichierDA"
#    puts "Ouverture du fichier..."
#    set da_layer_smoke [lindex [ogrfile open SHAPEDASMOKE append $fichierDA] 0]
#    eval ogrlayer read VDASMOKE $da_layer_smoke
#    puts "Réinitialisation des colonnes"
#    #   clear les colonnes SMOKE pour les polygones de DA sélectionnés
#    for {set classeid 1} {$classeid < 96} {incr classeid 1} {
#       ogrlayer clear VDASMOKE SMOKE$classeid
#       puts "La colonne $classeid a été réinitialisée"
#    }
#    puts "Écriture et fermeture du fichier"
#    ogrlayer sync VDASMOKE ;# là pcq mode append, pas besoin en mode write, mais le mode write a un bug
#    ogrlayer free VDASMOKE
#    ogrfile close SHAPEDSMOKE
#    puts "Les colonnes SMOKE1 à SMOKE$classeid devraient être vides. Vérifier le résultat."
#    return


   #POUR TROUVER TOUS LES FICHIERS CANVEC DU CANADA POUR UNE ENTITÉ
#    puts "Utilitaire pour trouver tous les fichiers CanVec du Canada pour une entité"
#    set Param(FilesCanada) {}
#    set Param(LayerATrouver) {LX_1000079_2}
#    puts "Entité à trouver : $Param(LayerATrouver)"
#    puts "Recherche des fichiers Canvec..."
#    set Param(FilesCanada) [GenX::CANVECFindFiles 40 -50 88 -150 $Param(LayerATrouver)]
#    #Param(Files) contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp
#    set unique_filescanada [lsort -unique $Param(FilesCanada)]
#    set sort_unique_filescanada [lsort $unique_filescanada]
#    puts "Liste des fichiers trouvés :"
#    foreach file $sort_unique_filescanada {
#       set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
#       #filename contains an element of the form 999a99_9_9_AA_9999999_9
#       puts $filename
#    }
#    puts "Il y a [llength $sort_unique_filescanada] shapefiles trouvés."
#    return
}

proc deg2rad deg {expr {$deg*atan(1)*8/360}}

proc dist {lat1 lat2 lon1 lon2} {
 set R 6371
 set dLat [deg2rad [expr {($lat2 - $lat1)}]]
 set dLon [deg2rad [expr {($lon2 - $lon1)}]]
 set sdlat2 [expr {sin($dLat/2)}]
 set sdlon2 [expr {sin($dLon/2)}]
 set a [expr {$sdlat2*$sdlat2 + cos([deg2rad $lat1])*cos([deg2rad $lat2])*$sdlon2*$sdlon2}]
 set d [expr {2*$R*asin(sqrt($a))}]
 return $d

#set diagonale [expr ([dist $Param(Lat0) $Param(Lat1) $Param(Lon0) $Param(Lon1)]*1000)] ;# diagonale en metres
#set Param(Deg2M)  [expr (sqrt(($Param(Lat1)-$Param(Lat0))*($Param(Lat1)-$Param(Lat0))+($Param(Lon1)-$Param(Lon0))*($Param(Lon1)-$Param(Lon0))))]

  #set Param(Deg2M) [expr [expr ($Param(Lon1)-$Param(Lon0))]/$largeur] ;# deg par metres
  #set Param(Deg2M) [expr (1/$largeur)] ;# deg par metres
#puts "Param(Deg2M) = $Param(Deg2M)"
#break

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FindNTSSheets>
# Creation : March 2012 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Find the NTS sheets intersecting an area
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#
# Return:
#   <sheets>  : List of NTS sheets intersecting with the area
#
# Remarks :   THIS PROC COULD BE MOVED TO GenX
#
#----------------------------------------------------------------------------
proc UrbanX::FindNTSSheets { Lat0 Lon0 Lat1 Lon1 } {
   variable Path

   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read  $GenX::Param(DBase)/$GenX::Path(NTS)/decoupage50k_2.shp] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }

   set sheets ""
   set ids [ogrlayer pick NTSLAYER50K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True]

   foreach id $ids {
      set sheet [ogrlayer define NTSLAYER50K -feature $id IDENTIFIAN]
      set s250 [string range $sheet 0 2]
      set sl   [string tolower [string range $sheet 3 3]]
      set s50  [string range $sheet 4 5]
      set sheets [concat $sheets $s250$sl$s50]
   }
   return $sheets
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FindUSUTSSSheets>
# Creation : July 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Find the US UTM sheets intersecting an area
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#
# Return:
#   <sheets>  : List of sheets intersecting with the area
#
# Remarks :
#
#   US UTS are based on the UTM coordinate system
#   US UTS sheets identifiers are similar to NTS sheets identifier
#   and are compatible in the directory hierarchy and file naming in the CULUC structure
#
#       UULCRR
#
#    where  UU   is the UTM Zone ranging from 1 to 60 with 6 degree width
#            L   is the Latitude Band from letter  C to X starting at -80S, 8 degree high
#            C   is the sub column ranging from a to l at a width of DLON=0.5
#           RR   is the sub row ranging from 1 to 32 at a width of DLAT=0.25
#----------------------------------------------------------------------------
proc UrbanX::FindUSUTSSheets { Lat0 Lon0 Lat1 Lon1 } {
   variable Param

   set  udsv  "_v"
   set  sheets {}

#
# first make sure that the index file for US UTS sheets is available
#
   set  indexfile   /data/cmdd/afsm/lib/geo/NLCD2006/US_UTS/Index/Index.dbf
   if { ![file exist $indexfile] } {
      return $sheets
   }

   set layer [lindex [ogrfile open UTSINDEXFILE read $indexfile] 0]
   eval ogrlayer read UTSINDEXLAYER $layer
   set ids [ogrlayer pick UTSINDEXLAYER [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True]
   foreach id $ids {
      set sheet [ogrlayer define UTSINDEXLAYER -feature $id IDENTIFIAN]
      set s250 [string range $sheet 0 2]
      set sl   [string tolower [string range $sheet 3 3]]
      set s50  [string range $sheet 4 5]
#
# All US sheet must be pre-generate because UrbanX wont generate it on the fly like the NTS sheet
#
      if { [file exists $Param(CULUCPath)/$s250/$sl/CULUC_$sheet$udsv$Param(CULUCVersion).tif] } {
         lappend sheets $sheet
      }
   }
   ogrfile close UTSINDEXFILE
   return $sheets
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FindWTSSheets>
# Creation : July 2012 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Find the World UTM sheets intersecting an area
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude  
#
# Return:
#   <sheets>  : List of sheets intersecting with the area
#
# Remarks :   
#
#   US UTS are based on the UTM coordinate system
#   US UTS sheets identifiers are similar to NTS sheets identifier
#   and are compatible in the directory hierarchy and file naming in the CULUC structure
#
#       UULCRR
#
#    where  UU   is the UTM Zone ranging from 1 to 60 with 6 degree width
#            L   is the Latitude Band from letter  C to X starting at -80S, 8 degree high
#            C   is the sub column ranging from a to l at a width of DLON=0.5
#           RR   is the sub row ranging from 1 to 32 at a width of DLAT=0.25
#
#----------------------------------------------------------------------------
proc UrbanX::FindWTSSheets { Lat0 Lon0 Lat1 Lon1 } {
   variable Param

   set  udsv  "_v"
   set  sheets {}
   set  rejected {}

set paths [split $Param(WULUCPath) ":"]
foreach  WULUCPath  $paths {
   set  indexfile   $WULUCPath/Index/Index.shp
   Log::Print INFO "Looking up : $indexfile"
   if { ![file exist $indexfile] } {
      Log::Print WARNING "sheets index file not found: $indexfile"
      continue
   }

   set layer [lindex [ogrfile open UTSINDEXFILE read $indexfile] 0]
   eval ogrlayer read UTSINDEXLAYER $layer
   set ids [ogrlayer pick UTSINDEXLAYER [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True]
   foreach id $ids {
      set sheet [ogrlayer define UTSINDEXLAYER -feature $id IDENTIFIAN]

      set geom1 [ogrlayer define UTSINDEXLAYER -geometry $id]
      Log::Print INFO "Got geom1: $geom1"
      set intersect [ogrgeometry stats $geom1 -intersect myGridPoly]
      if { $intersect } {
         set s250 [string range $sheet 0 2]
         set sl   [string tolower [string range $sheet 3 3]]
         set s50  [string range $sheet 4 5]
#
# All sheets must be pre-generate because UrbanX wont generate it on the fly like the NTS sheet
#
         if { [file exists $WULUCPath/$s250/$sl/CULUC_$sheet$udsv$Param(CULUCVersion).tif] } {
                 if { [lsearch $sheets $sheet] ==-1 } {
               lappend sheets $sheet
            } else {
               Log::Print WARNING "Warning: duplicate sheet '$sheet' found in : $indexfile"
            }
         }
      } else {
         lappend rejected $sheet
      }
   }
   ogrfile close UTSINDEXFILE
}

   if { [llength $rejected] > 0 } {
      Log::Print INFO "Avoided processing of outside sheets: $rejected"
   }

   return $sheets
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::UTMZoneDefine>
# Creation : October 2010 - Alexandre Lerous, Lucie Boucher - CMC/AQMAS
#
# Goal     : define the UTM Zone
#
# Parameters :
#   <Lat0>   : Lower left latitude
#   <Lon0>   : Lower left longitude
#   <Lat1>   : Top right latitude
#   <Lon1>   : Top right longitude
#   <Res>    : Spatial resolution, (Default 5)
#   <Name>   : Georeference object name
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::UTMZoneDefine { Lat0 Lon0 Lat1 Lon1 { Res 5 } { Name "" } } {
   variable Param
   # This proc was moved into UrbanX and *is* an exact copy of the one in GenX, but moving it here updates Param(Width) and Param(Height) at the same time

   set zone     [expr int(ceil((180+(($Lon1+$Lon0)/2))/6))]
   set meridian [expr -((180-($zone*6))+3)]

   if { $Name=="" } {
      set Name UTMREF
   }

   eval georef create $Name \
      \{PROJCS\[\"WGS_1984_UTM_Zone_${zone}N\",\
         GEOGCS\[\"GCS_WGS_1984\",\
            DATUM\[\"D_WGS_1984\",\
               SPHEROID\[\"WGS_1984\",6378137.0,298.257223563\]\],\
            PRIMEM\[\"Greenwich\",0.0\],\
            UNIT\[\"Degree\",0.0174532925199433\]\],\
         PROJECTION\[\"Transverse_Mercator\"\],\
         PARAMETER\[\"False_Easting\",500000.0\],\
         PARAMETER\[\"False_Northing\",0.0\],\
         PARAMETER\[\"Central_Meridian\",$meridian\],\
         PARAMETER\[\"Scale_Factor\",0.9996\],\
         PARAMETER\[\"Latitude_Of_Origin\",0.0\],\
         UNIT\[\"Meter\",1.0\]\]\}

   set xy1 [georef unproject $Name $Lat1 $Lon1]
   set xy0 [georef unproject $Name $Lat0 $Lon0]
   set xy2 [georef unproject $Name $Lat0 $Lon1]
   set xy3 [georef unproject $Name $Lat1 $Lon0]

   set longmin [lindex [lsort -real [list [lindex $xy1 0] [lindex $xy0 0] [lindex $xy2 0] [lindex $xy3 0] ]] 0]
   set longmax [lindex [lsort -real [list [lindex $xy1 0] [lindex $xy0 0] [lindex $xy2 0] [lindex $xy3 0] ]] end]
   set latmin [lindex [lsort -real [list [lindex $xy1 1] [lindex $xy0 1] [lindex $xy2 1] [lindex $xy3 1] ]] 0]
   set latmax [lindex [lsort -real [list [lindex $xy1 1] [lindex $xy0 1] [lindex $xy2 1] [lindex $xy3 1] ]] end]

   set Param(Width)  [expr int(ceil(($longmax - $longmin)/$Res))]
   set Param(Height) [expr int(ceil(($latmax - $latmin)/$Res))]

# actually, they are not latitude/longitude but a projected coordinates which are
# smaller on left and bigger on right for scalex > 0
# smaller on bottom and bigger on top for scaley < 0
   set scalex        [expr abs($Res)]
   set scaley        [expr -1.0 * abs($Res)]
   set uly           $latmax
   set ulx           $longmin

   set  transform [list $ulx $scalex 0.000000000000000 $uly 0.000000000000000 $scaley]

   georef define $Name -transform $transform

   Log::Print INFO "For $Param(NTSSheet), UTM zone is $zone, with central meridian at $meridian and dimension $Param(Width)x$Param(Height)"

   return $Name
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Process>
# Creation : Circa 2005 - Alexandre Leroux - CMC/CMOE
# Revision : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :
#
# Parameters :
#   <Coverage>   : zone to process {MONTREAL VANCOUVER TORONTO OTTAWA WINNIPEG CALGARY HALIFAX REGINA EDMONTON VICTORIA QUEBEC}
#                              default settings on Quebec City
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Process { Coverage Grid } {
   variable Param
   variable Meta 	;# do we use this at all?

   Log::Print INFO "Beginning of UrbanX"
   GenX::Procs CANVEC StatCan

   if { [string compare $Param(BLDH_PATH) ""] == 0 } {
      set Param(BLDH_PATH) $GenX::Param(TMPDIR)
   }

   # Test is we're in CULUC generation mode, ie testing if it's a single NTS sheet in input
   if { [string is integer [string range $Coverage 0 0]] } {
      Log::Print INFO "Generating CULUC classification version $Param(CULUCVersion) for NTS sheet $Coverage"
      Log::Print INFO "Only users with write access to /cnfs/dev/cmdd/afsm/lib/geo/ can run create permanent CULUC classifications"
      set Param(NTSSheets) $Coverage
   } else {
      #----- Get the lat/lon and files parameters associated with the city or grid file
      if { ![UrbanX::AreaDefine $Coverage $Grid] } {
          #----- Stop UrbanX if no area or gridfile is given
          return
      }

      GenX::Create_GridGeometry $Grid myGridPoly
      set Param(NTSSheets) [UrbanX::FindNTSSheets $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)]
      set Param(WTSSheets) [UrbanX::FindWTSSheets $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)]

      Log::Print INFO "NTS sheets to process: $Param(NTSSheets)"
      if { [llength $Param(WTSSheets)] > 0 } {
         Log::Print INFO "World UTM sheets to process: $Param(WTSSheets)"
      }
   }

   # Generate the CULUC classification for the NTS sheet(s)
   set  ntssheets {}
   foreach ntssheet $Param(NTSSheets) {
      set Param(NTSSheet) $ntssheet

      # Creating the tmp directory for temporary files - required if more than GenX::Param(GridFile) contains more than one grid
      file mkdir $GenX::Param(TMPDIR)

      # Identify path components for NTS sheet
      set s250 [string range $Param(NTSSheet) 0 2]
      set sl   [string tolower [string range $Param(NTSSheet) 3 3]]
      set s50  [string range $Param(NTSSheet) 4 5]

      set culucfn  "CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif"
      set culucnd  "CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).done"

      # Don't generate the CULUC classification if it already exists
     if { ![file exists $GenX::Param(TMPDIR)/$culucfn] &&
           ![file exists $Param(CULUCPath)/$s250/$sl/$culucfn] } {

        if { [file exists $Param(CULUCPath)/$s250/$sl/$culucnd] } {
            Log::Print INFO "The file $culucfn was processed, Canvec has no data for this NTS sheet"
            continue
         }

         Log::Print INFO "The file CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif has not been found and will be created"

	 Log::Print INFO "Locating CanVec files to be processed for NTS sheet $Param(NTSSheet)"
	 # OLD WAY FOR GRID - set Param(Files) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Entities)]
         # Path structure for CanVec-7.0: set Param(NTSSheetPath)  $GenX::Param(DBase)/$GenX::Path(CANVEC)/$s250/$sl/$s250$sl$s50
         # Path structure for CanVec-9.0
         Log::Print WARNING "TEMPORARILY FORCING USING CanVec-9.0"
         set Param(NTSSheetPath) /cnfs/dev/cmdd/afsm/lib/geo/CanVec-9.0/$s250/$sl
#         set Param(NTSSheetPath)  $GenX::Param(DBase)/$GenX::Path(CANVEC)/$s250/$sl
         Log::Print DEBUG "Using CanVec files from  $GenX::Param(DBase)/$GenX::Path(CANVEC)"
	 foreach ntslayer $Param(Entities) {
	     if { [llength [set lst [glob -nocomplain $Param(NTSSheetPath)/$ntssheet*$ntslayer*.shp]]] } {
                set Param(Files) [concat $Param(Files) $lst]
	     }
	 }

# Canvec may not have file for this NTS sheet
         catch "glob -nocomplain $Param(NTSSheetPath)/$ntssheet*_LI_1210009_2.shp" sfile
         if { ![file exist $sfile] } {
             Log::Print INFO "Cannot find CanVec files for NTS sheet :  $Param(NTSSheet)"
             continue
         }

         lappend ntssheets $ntssheet

         # Find and use the extent of the NTS sheet being processed
	 eval ogrlayer read NTSLAYER$ntssheet [lindex [ogrfile open NTSSHAPE$ntssheet read $sfile] 0]
	 set extent [ogrlayer stats NTSLAYER$ntssheet -extent] ;# in lat long
	 set Param(Lat0) [lindex $extent 1]
	 set Param(Lon0) [lindex $extent 0]
	 set Param(Lat1) [lindex $extent 3]
	 set Param(Lon1) [lindex $extent 2]
	 ogrlayer free NTSLAYER$ntssheet
	 ogrfile close NTSSHAPE$ntssheet

	 # This sets UTMREF and Param(Width) and Param(Height)
         set Param(SheetGeoRef)  UTMREF$Param(NTSSheet)
	 UrbanX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) $Param(SheetGeoRef)
#         UrbanX::UTMZoneDefine $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Resolution) UTMREF$Param(NTSSheet)
#puts "Param(Lat0) Param(Lon0) Param(Lat1) Param(Lon1) = $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)"

	 # Set Param(deg2M) degree equivalence in meters based on latitude and longitude for spatial buffers - spatial buffers will still be ovals, but at least consider latitude
	 # This improves spatial buffers width accuracy by 15% over Montreal and certainly helps everywhere else
	 set Param(Deg2M) [expr (sqrt(($Param(Lat1)-$Param(Lat0))*($Param(Lat1)-$Param(Lat0))+($Param(Lon1)-$Param(Lon0))*($Param(Lon1)-$Param(Lon0))))/([dist $Param(Lat0) $Param(Lat1) $Param(Lon0) $Param(Lon1)]*1000)]

	 #----- Finds CanVec files, rasterize and flattens all CanVec layers, applies buffer on some elements
	 UrbanX::Sandwich $Coverage

	 #----- Vector building height processing - done only if data exists over the city
#	 if { $Param(BuildingsShapefile)!="" } {
#	     UrbanX::BuildingHeights2Raster  ;# Rasterizes building heights
	     # We ignore 3DBuildings2Sandwich until we find a way to generate TEB parameters accordingly
	     ## move?? next proc after TEB2FSTD and update from priority to TEB class
#	     UrbanX::3DBuildings2Sandwich $Coverage       ;# Overwrites Sandwich by adding 3D buildings data
#	 }

	 #----- Creates the fields and building vicinity output using spatial buffers
	 UrbanX::ChampsBuffers $Coverage

	 #----- StatCan Census data processing
	 UrbanX::PopDens2Builtup $Coverage     ;# Calculates the population density

	 #----- Calculates building heights from SRTM-DEM minus CDED - UNUSED
	 #UrbanX::HeightGain $Coverage
	 #UrbanX::BuildingHeight $Coverage

	 #------ Update vegetation using the LCC2000-V dataset
	 UrbanX::LCC2000V

	 #----- Applies LUT to all processing results to generate TEB classes
	 UrbanX::Priorities2TEB

	 #----- Optional vegetation mask to smooth the edges - NOT REQUIRED ANYMORE?
	 #UrbanX::VegeMask

         # Test is we're in CULUC generation mode, ie testing if it's a single NTS sheet in input
#         if { [string is integer [string range $Coverage 0 0]] }
         if { [file isdir $UrbanX::Param(CULUCPath)] && [file writable $UrbanX::Param(CULUCPath)] } {
               # Move the CULUC file to its final destination
               file mkdir $Param(CULUCPath)/$s250/$sl/
               file copy -force $GenX::Param(TMPDIR)/CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif $Param(CULUCPath)/$s250/$sl/
               Log::Print INFO "Done computing CULUC classification version $Param(CULUCVersion) for NTS sheet $Coverage"
         }
      } else {
         Log::Print INFO "An existing CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif file has been found and will be used"
      }
   }

   # Test is we're in CULUC generation mode, ie testing if it's a single NTS sheet in input
   if { ![string is integer [string range $Coverage 0 0]] } {
      #----- Computing TEB parameters on the FSTD target grid
      if { $GenX::Param(GridFile)!="" } {
          UrbanX::TEB2FSTD $Grid
          if { $Param(BuildingsShapefile)!="" } {
            # if $GenX::Param(TMPDIR)/$Param(NTSSheet)_Building-heights.tif doesn't exists than create it (ie, if the $GenX::Param(TMPDIR)/CULUC_$Param(NTSSheet)_v$Param(CULUCVersion).tif file existed)
#            if { ![file exists $GenX::Param(TMPDIR)/$Param(NTSSheet)_Building-heights.tif] } {
# IMCOMPLETE: BuildingHeight2Raster DOES NOT USE THE RIGHT EXTENT AT THE MOMENT????? --- how to do it for the grid extent????
#                UrbanX::FindNTSSheetExtent $Param(NTSSheet)
# MAKE CERTAIN THE RIGHT UTMREF is used!
#                UrbanX::BuildingHeights2Raster
#            }
            #----- Computes TEB geometric parameters from 3D buildings
# To fix and re-enable - wrong extent ?
#              UrbanX::3DBld2TEBGeoParams $Grid
          }
          UrbanX::DominantVege $Grid
      }
   }
   foreach ntssheet $Param(NTSSheets) {
       #----- Deleting all UrbanX temporary files
       UrbanX::DeleteTempFiles $ntssheet
   }
   Log::Print INFO "End of UrbanX"
}
