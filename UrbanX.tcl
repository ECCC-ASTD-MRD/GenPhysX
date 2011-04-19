#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : UrbanX.tcl
# Creation   : Janvier 2006- Alexandre Leroux / J.P. Gauthier - CMC/CMOE
# Revision   : $Id$
# Description: Classification urbaine automatisée, principalement à partir de
#              données CanVec 1:50000, StatCan (population) LCC2000-V (vegetation)
#              et bâtiments 3D pour alimenter le modèle TEB
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#============================================================================

namespace eval UrbanX { } {
   variable Param
   variable Const
   variable Meta

   set Param(Version) 0.4

   set Param(Resolution) 5       ;# Spatial rez of rasterization and outputs, leave at 5m unless for testing purposes
# Param(Buffer) is unused at the moment... delete in favor of new method for account for off-zone buffers
   set Param(Buffer)     0.001   ;# Includes about 200m buffers to account for off-zone buffers which would influence results
   set Param(Mode)       FAST    ;# Rasterization mode: INCLUDED or FAST - fast is... much much faster!
   set Param(HeightGain) 0       ;# Default value if proc HeightGain is not ran
   set Param(Width)      0       ;# Largeur du domaine
   set Param(Height)     0       ;# Hauteur du domaine
   set Param(Lon1)           0.0 ;# Top right longitude
   set Param(Lat1)           0.0 ;# Top right latitude
   set Param(Lon0)           0.0 ;# Lower left longitude
   set Param(Lat0)           0.0 ;# Lower Left latitude
   set Param(HeightFile)     ""
   set Param(HeightMaskFile) ""
   set Param(BuildingsShapefile)   "" ;# 2.5D buildings shapefile for a specific city
   set Param(BuildingsHgtField)     "" ;# Name of the height attribute of the 2.5D buildings shapefile


   #----- Directory where to find processing procs
   set dir [info script]
   while { ![catch { set dir [file normalize [file link $dir]] }] } {}
   set dir [file dirname $dir]
   source $dir/UrbanX-ClassesLUT.tcl
   set Param(Entities) [UrbanX-ClassesLUT::SetParamEntities]
   set Param(Priorities) [UrbanX-ClassesLUT::SetParamPriorities]
   set Param(TEBClasses) [UrbanX-ClassesLUT::SetParamTEBClasses]

   # CanVec layers requiring postprocessing. No specific sorting of this list is required
   set Param(LayersPostPro)    { BS_1370009_2 BS_2010009_0 BS_2010009_2 BS_2060009_0 BS_2240009_1 BS_2310009_1 EN_1180009_1 HD_1450009_0 HD_1450009_1 HD_1450009_2 HD_1460009_0 HD_1460009_1 HD_1460009_2 HD_1470009_1 HD_1480009_2 IC_2600009_0 TR_1020009_1 TR_1190009_0 TR_1190009_2 TR_1760009_1 QC_TR_1760009_1 }

   set Param(BufferLayers)     { BS_2010009_0 TR_1760009_1 } ;# Layers from CanVec required for buffer

   # SMOKE Classes for CanVec
   # Ces valeurs sont associées aux entitées CanVec.  Elles doivent être dans le même ordre que Param(Entities) et Param(Priorities), pour l'association de LUT
   set Param(SMOKEClasses)       { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 3 4 5 43 0 0 30 29 0 28 27 0 0 0 0 22 0 0 0 0 33 0 26 0 0 36 37 34 35 39 40 41 32 31 42 74 73 67 66 71 70 68 69 72 64 65 0 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 23 0 63 61 62 58 59 60 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 26 25 0 0 0 0 0 0 0 0 21 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 24 0 43 0 28 29 0 28 0 0 0 0 36 37 0 38 39 42 22 23 47 31 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 0 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 0 0 24 0 44 45 46 0 0 }

   # Making certain LUTs have the same length
   if {$GenX::Param(SMOKE)!="" } {
      if { !(([llength $Param(Priorities)] == [llength $Param(SMOKEClasses)]) && ([llength $Param(Priorities)] == [llength $Param(TEBClasses)])) } {
         GenX::Log ERROR "ERROR: Param(Priorities) = [llength $Param(Priorities)], Param(TEBClasses) = [llength $Param(TEBClasses)], Param(SMOKEClasses) = [llength $Param(SMOKEClasses)]"
         break
      }
   } else {
      if { !(([llength $Param(Priorities)] == [llength $Param(Entities)]) && ([llength $Param(Priorities)] == [llength $Param(TEBClasses)])) } {
         GenX::Log ERROR "ERROR: Param(Priorities) = [llength $Param(Priorities)], Param(TEBClasses) = [llength $Param(TEBClasses)], Param(Entities) = [llength $Param(Entities)]"
         break
      }
   }

   set Param(VegeFilterType) LOWPASS
   set Param(VegeFilterSize) 99

# NOTE : les paths des fichiers suivants devront être modifiés lorsqu'il aura été décidé où ces fichiers seront localisés
   # Fichier contenant les polygones de dissemination area de StatCan, découpés selon l'index NTS 1:50000 et contenant la population ajustée aux nouveaux polygones
   set Param(PopFile2006SMOKE) $GenX::Path(StatCan)/SMOKE_FILLED/da2006-nts_lcc-nad83.shp
# Next path needs to be updated and added to GenX
   set Param(Census2006File) /data/cmoex7/afsralx/StatCan2006/da2006_pop_labour.shp

# Next file should be moved to the data repertory with $GenX::Path()
   set Param(TEBParamsLUTCSVFile) doc/TEB-Params_LUT.csv

   # Pour IndustrX seulement : fichier contenant 1 polygone pour chaque province ou territoire du Canada - pourrait être déplacé dans IndustrX
   set Param(ProvincesGeom) $GenX::Path(StatCan)/Provinces_lcc-nad83.shp

   # À déplacer dans IndustrX - Fichier contenant l'index NTS à l'échelle 1:50000
   # Attention : s'assurer qu'il s'agit bien de l'index ayant servi au découpage du fichier PopFile2006SMOKE
   set Param(NTSFile) $GenX::Path(NTS)/decoupage50k_2.shp
   # À déplacer dans IndustrX - entité CanVec déterminant la bordure des polygones NTS 50K
   set Param(NTSLayer) { LI_1210009_2 }

   # Vector 1: LCC2000 classes, vector 2: SMOKE LUT by Lucie in October 2010, vector 3: UrbanX LUT by Alex in February 2011
   # For the UrbanX LUT, values given are those of the ISBA LUT on the wiki at LCC2000-V/Classes PLUS 700
   set Const(LCC2000LUT) {
      { 0 10 11 12 20  30  31 32  33 34  35  36  37  40  50  51  52  53  80  81  82  83 100 101 102 103 104 110 121 122 123 200 210 211 212 213 220 221 222 223 230 231 232 233 }
      { 0  0  0  0  0 500   0  0 501  0 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 }
      { 0  0  0  0  0   0 702  0   0  0 724 724 724 722 726 711 711 722 723 723 723 723 713 722 714 722 722 714 715 715 715 725 704 704 704 704 707 707 707 707 725 725 725 725 } }

   # DEG2RAD(D)           ((D)*0.017453292519943295474371680598)
   # RAD2M(R)             ((R)*6.36670701949370745569e+06)
   set Param(Deg2M) [expr (0.017453292519943295474371680598*6.36670701949370745569e+06)] ;# doesn't take into account latitude effects
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::AreaDefine>
# Creation : June 2006 - Alexandre Leroux - CMC/CMOE
# Revision : October 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Define raster coverage based on coverage name
#            Set the lat long bounding box for the city specified at launch
#
# Parameters :
#   <Coverage>   : zone to process, either city or province ( default settings on Quebec City)
#
# Return:
#
# Remarks : Param(HeightFile) and Param(HeightMaskFile) will need to be removed or updated
#
#----------------------------------------------------------------------------
proc UrbanX::AreaDefine { Coverage Grid } {
   variable Param

   #----- If no OutFile specified for -urban, then use the city name. Only OutFile_aux.fst and OutFile.fst aren't overwritten.
   if { $GenX::Param(OutFile)=="genphysx" } {
      GenX::Log INFO "No \"-result\" option defined, using $Coverage for the output file filename"
      set GenX::Param(OutFile) $Coverage
   }

# Param(HeightFile) and Param(HeightMaskFile) will need to be removed or updated
   switch $Coverage {
      "VANCOUVER" {
         set Param(Lon1)   -122.50
         set Param(Lat1)    49.40
         set Param(Lon0)   -123.30
         set Param(Lat0)    49.01
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Vancouver/out.shp
         set Param(BuildingsHgtField) hgt
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong_wmask
      }
      "MONTREAL" {
         set Param(Lon1)   -73.35
         set Param(Lat1)    45.70
         set Param(Lon0)   -73.98
         set Param(Lat0)    45.30
# For testing purposes, small region near carrière Miron (overwrited if -gridfile specified)
#set Param(Lon1)   -73.60
#set Param(Lat1)    45.57
#set Param(Lon0)   -73.65
#set Param(Lat0)    45.50
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Montreal/bat_2d_st.shp
         set Param(BuildingsHgtField) hauteur
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped_wmask
      }
      "TORONTO" {
         set Param(Lon1)   -79.12
         set Param(Lat1)    43.92
         set Param(Lon0)   -79.85
         set Param(Lat0)    43.49
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Toronto/Toronto.shp
         set Param(BuildingsHgtField) Elevation
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "OTTAWA" {
         set Param(Lon1)   -75.56
         set Param(Lat1)    45.52
         set Param(Lon0)   -75.87
         set Param(Lat0)    45.30
         set Param(BuildingsShapefile) /cnfs/ops/production/cmoe/geo/Vector/Cities/Ottawa/buildings.shp
         set Param(BuildingsHgtField) height
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
      }
      "WINNIPEG" {
         set Param(Lon1)   -96.95
         set Param(Lat1)    49.98
         set Param(Lon0)   -97.34
         set Param(Lat0)    49.75
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "CALGARY" {
         set Param(Lon1)   -113.90
         set Param(Lat1)    51.18
         set Param(Lon0)   -114.28
         set Param(Lat0)    50.87
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "HALIFAX" {
         set Param(Lon1)   -63.36
         set Param(Lat1)    44.83
         set Param(Lon0)   -63.80
         set Param(Lat0)    44.56
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "REGINA" {
         set Param(Lon1)   -104.50
         set Param(Lat1)    50.54
         set Param(Lon0)   -104.72
         set Param(Lat0)    50.38
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "EDMONTON" {
         set Param(Lon1)   -113.19
         set Param(Lat1)    53.70
         set Param(Lon0)   -113.73
         set Param(Lat0)    53.38
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "VICTORIA" {
         set Param(Lon1)   -123.22
         set Param(Lat1)    48.55
         set Param(Lon0)   -123.54
         set Param(Lat0)    48.39
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "QUEBEC" {
         set Param(Lon1)   -71.10
         set Param(Lat1)    46.94
         set Param(Lon0)   -71.47
         set Param(Lat0)    46.68
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
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
   }

   if { $GenX::Param(GridFile)!="" } {
      GenX::Log INFO "Using spatial extent of the $GenX::Param(GridFile) file"
      set limits [georef limit [fstdfield define $Grid -georef]]
      set Param(Lat0) [lindex $limits 0]
      set Param(Lon0) [lindex $limits 1]
      set Param(Lat1) [lindex $limits 2]
      set Param(Lon1) [lindex $limits 3]
   } else {
      GenX::Log ERROR "You NEED to specify -gridfile in order to generate $Param(OutFile)_aux.fst"
   }
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::CANVECFindFiles>
# Creation : date? - Alexandre Leroux - CMC/CMOE
# Revision :
#
# Goal     : Identify required CanVec files
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::CANVECFindFiles { } {
   variable Param

   #recherche des fichiers CanVec à rasteriser
   GenX::Log INFO "Locating CanVec files, extent considered: lower-left = $Param(Lat0), $Param(Lon0) top-right = $Param(Lat1), $Param(Lon1)"
#   GenX::Log DEBUG "Param(Entities): $Param(Entities)"
   set Param(Files) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Entities)]
#   GenX::Log DEBUG "CanVec Files: $Param(Files)"
   #Param(Files) contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp
   #Les paths des fichiers sont triés par feuillet NTS, puis suivant l'ordre donné dans Param(Entities).
   #On a donc, dans l'ordre: feuillet1-entité1, feuillet1-entité2... feuillet1-entitéN, feuillet2-entité1, feuillet2-entité2... feuilletM-entitéN
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
#      <indexCouverture>      : index à appliquer à la référence UTMREF
#
# Return: output genphysx_sandwich.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Sandwich { indexCouverture } {
   variable Param
   variable Data
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log INFO "Rasterizing, flattening and post-processing CanVec layers over the raster of size $Param(Width)x$Param(Height) at a $Param(Resolution)m spatial resolution"

   #création de la raster qui contiendra la LULC
   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef UTMREF$indexCouverture

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
      GenX::Log DEBUG "Processing entity: $entity, priority: $priority, filename: $filename, file: $file"

      # value contains the nth element of the list Param(Priorities), where n is the index of layer in the list Param(Entities)
      ogrfile open SHAPE read $file

      # The following if/else evaluates if the layer requires some post-processing prior to rasterization or if it is rasterized with the generic procedure
      if { [lsearch -exact $Param(LayersPostPro) $entity] !=-1 } {

         switch $entity {
            BS_1370009_2 {
            # Residential areas
            # Lors de la procédure sandwich, l'entité prend entièrement les valeurs suivantes : PRI = 218 ; TEB = 210 ; SMO = 1
            # Lors de la procédure PopDens2Builtup, l'entité est découpée selon des seuils de densité de population
               GenX::Log DEBUG "Post-processing for Residential area, area"
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename'"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity as FEATURES with priority value 218"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 218
            }
            BS_2010009_0 {
               # entity : Building, points
               GenX::Log DEBUG "Post-processing for buildings, points buffered to 12m"

               set types { "arena" "armoury" "city hall" "coast guard station" "community center" "courthouse" "custom post" "electric power station" "fire station" "highway service center" \
                           "hospital" "medical center" "municipal hall" "gas and oil facilities building" "parliament building" "police station" "railway station" "satellite-tracking station" \
                           "sportsplex" "industrial building" "religious building" "penal building" "educational building" }
               set funcs {  1  2  5  6  7  8  9 11 12 16 17 19 20 23 25 26 27 29 32 37 38 39 41 }
               set vals  { 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (function = $func)"
#                  ogrlayer stats FEATURES -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE function NOT IN ([join $funcs ,])"
#               ogrlayer stats FEATURES -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 33"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 33
            }
            BS_2010009_2 {
               GenX::Log DEBUG "Post-processing for buildings, areas"
               set types { "arena" "armoury" "city hall" "coast guard station" "community center" "courthouse" "custom post" "electric power station" "fire station" "highway service center" \
                           "hospital" "medical center" "municipal hall" "gas and oil facilities building" "parliament building" "police station" "railway station" "satellite-tracking station" \
                           "sportsplex" "industrial building" "religious building" "penal building" "educational building" }
               set funcs {   1   2   5   6  7  8  9 11 12 16 17 19 20 23 25 26 27 29 32 37 38 39 41 }
               set vals  { 103 102 101 100 99 98 97 96 95 94 93 92 91 90 89 88 87 86 85 84 83 82 81 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE FUNCTION = $func"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }
               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE function NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 104"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 104
            }
            BS_2060009_0 {
               #entity : Chimney, points
               GenX::Log DEBUG "Post-processing for Chimneys, points"
               set types { "Chimneys - burners" "Chimneys - industrial" "Chimneys - flare stack" }
               set funcs { 1 2 3 }
               set vals  { 5 4 3 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 6"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 6
            }
            BS_2240009_1 {
               #entity : Wall/fence, line
               GenX::Log DEBUG "Post-processing for Wall / fences, lines"
               set types { "Wall / fence - fences" "Wall / fence - fences" }
               set funcs {   1   2 }
               set vals  { 114 113 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }
            }
            BS_2310009_1 {
               #entity : Pipeline (Sewage / liquid waste), line
               GenX::Log DEBUG "Post-processing for Pipelines (sewage / liquid waste), lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (aboveground sewage pipeline entity) as FEATURES with priority value $priority"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
            }
            EN_1180009_1 {
               #entity : Pipeline, line
               GenX::Log DEBUG "Post-processing for Pipelines, lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (aboveground pipeline entity) as FEATURES with priority value $priority"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
            }
            HD_1450009_0 {
               # entity : Manmade hydrographic entity [Geobase], point
               GenX::Log DEBUG "Post-processing for Manmade hydrographic entities, points"
               set types { "dam" "dock" "wharf" "breakwater" "dike/levee" "lock gate" "boat ramp" "fish ladder" "slip" "breakwater in the ocean" }
               set funcs {  1  2  3  4  5  6  7  8  9  104 }
               set vals  { 43 42 41 44 45 37 40 38 39   46 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 47"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 47
            }
            HD_1450009_1 {
               # entity : Manmade hydrographic entity [Geobase], line
               GenX::Log DEBUG "Post-processing for Manmade hydrographic entities, lines"
               set types { "dam" "dock" "wharf" "breakwater" "dike/levee" "lock gate" "boat ramp" "fish ladder" "slip" "breakwater in the ocean" }
               set funcs {   1   2   3   4   5   6   7   8   9 104 }
               set vals  { 124 123 122 125 126 118 121 119 120 127 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 128"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 128
            }
            HD_1450009_2 {
               # entity : Manmade hydrographic entity [Geobase], area
               GenX::Log DEBUG "Post-processing for Manmade hydrographic entities, area"
               set types { "dam" "dock" "wharf" "breakwater" "dike/levee" "lock gate" "boat ramp" "fish ladder" "slip" "breakwater in the ocean" }
               set funcs {   1   2   3   4   5   6   7   8   9 104 }
               set vals  { 154 153 152 155 156 148 151 149 150 157 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 128"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 158
            }
            HD_1460009_0 {
               # entity : Hydrographic obstacle entity [Geobase], point
               GenX::Log DEBUG "Post-processing for Hydrographic obstacle entities, points"
               set types { "fall" "rapids" "reef" "rocks" "disappearing stream" "exposed shipwreck" "ford" "reef in the ocean" "rocks in the ocean" "exposed shipwreck in the ocean" }
               set funcs {  1  2  3  4  5  6  7 103 104 106 }
               set vals  { 56 57 53 52 48 50 49  55  54  51 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 58"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 58
            }
            HD_1460009_1 {
               # entity : Hydrographic obstacle entity [Geobase], line
               GenX::Log DEBUG "Post-processing for Hydrographic obstacle entities, lines"
               set types { "fall" "rapids" "reef" "rocks" "disappearing stream" "exposed shipwreck" "ford" "reef in the ocean" "rocks in the ocean" "exposed shipwreck in the ocean" }
               set funcs {   1   2   3   4   5   6   7 103 104 106 }
               set vals  { 137 138 134 133 129 131 130 136 135 132 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 58"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 139
            }
            HD_1460009_2 {
               # entity : Hydrographic obstacle entity [Geobase], area
               GenX::Log DEBUG "Post-processing for Hydrographic obstacle entities, areas"
               set types { "fall" "rapids" "reef" "rocks" "disappearing stream" "exposed shipwreck" "ford" "reef in the ocean" "rocks in the ocean" "exposed shipwreck in the ocean" }
               set funcs {   1   2   3   4   5   6   7 103 104 106 }
               set vals  { 167 168 164 163 159 161 160 166 165 162 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 169"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 169
            }
            HD_1470009_1 {
               # entity : Single line watercourse [Geobase], line
               GenX::Log DEBUG "Post-processing for Single line watercourse, line"
               set types { "canal" "conduit" "ditch" "watercourse" "tidal river" }
               set funcs {   1   2   3   6   7 }
               set vals  { 142 141 140 144 143 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (definition = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE definition NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 145"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 145
            }
            HD_1480009_2 {
              # entity : Waterbody [Geobase], polygon
               GenX::Log DEBUG "Post-processing for Waterbody, polygon"
               set types { "canal" "ditch" "lake" "reservoir" "watercourse" "tidal river" "liquid waste" "pond" "side channel" "ocean" }
               set funcs {   1   3   4   5   6   7   8   9  10 100 }
               set vals  { 172 171 178 179 175 173 176 177 173 180 }

               foreach type $types func $funcs val $vals {
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (definition = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE definition NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 181"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 181
            }
            IC_2600009_0 {
               # entity : Mining area, point
               GenX::Log DEBUG "Post-processing for Mining area, point"
               #status = 1 : mines opérationnelles
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (status = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (operational mines) as FEATURES with priority value 65"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 65
               #status != 1 : mines non opérationnelles
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (status != 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (non operational mines) as FEATURES with priority value 66"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 66
            }
            TR_1020009_1 {
               # entity : Railway, line
               GenX::Log DEBUG "Post-processing for Railway, line"
               # support = 3 : bridge
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (support = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge railway) as FEATURES with priority value 2"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 2
               # support != 3 ou 4 : not bridge, not tunnel
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE support NOT IN (3,4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge railway) as FEATURES with priority value 111"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 111
            }
            TR_1190009_0 {
               # entity : Runway, point
               GenX::Log DEBUG "Post-processing for Runway, point"
               #type = 1 : airport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (airport runway) as FEATURES with priority value 62"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 62
               #type = 2 ou 3 : heliport, hospital heliport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type IN (2,3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (heliport or hospital heliport runway) as FEATURES with priority value 7"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 7
               #type = 4 : water aerodrome
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 4 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (water aerodrome runway) as FEATURES with priority value 61"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 61
            }
            TR_1190009_2 {
               # entity : Runway, area
               GenX::Log DEBUG "Post-processing for Runway, areas"
               #type = 1 : airport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 1 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (airport runway) as FEATURES with priority value 201"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 201
               #type = 2 ou 3 : heliport, hospital heliport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE type IN (2,3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (heliport or hospital heliport runway) as FEATURES with priority value 80"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 80
               #type = 4 : water aerodrome
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (type = 4 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (water aerodrome runway) as FEATURES with priority value 147"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 147
            }
            TR_1760009_1 {
               if { $indexCouverture=="MONTREAL" || $indexCouverture=="QUEBEC" || $indexCouverture=="QC"} {
                  GenX::Log DEBUG "Ignoring the TR_1760009_1 layer for $indexCouverture to avoid duplicated roads with QC_TR_1760009_1"
               } else {
                  # entity : Road segment [Geobase], line
                  GenX::Log DEBUG "Post-processing for Road segment, lines"

                  #exclusions des structype 5 (tunnel) et 6 (snowshed), association de la valeur générale à tout le reste des routes pavées
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus != 2) AND structype NOT IN (5,6)"
   #               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general road segments) as FEATURES with priority value 109"
   #               GenX::Log INFO "Buffering general road segments to 12m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 109

                  #pavstatus = 2 : unpaved : routes non pavées n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus = 2) AND structype NOT IN (5,6)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (unpaved road segments) as FEATURES with priority value 110"
                  #pas de buffer sur les routes non pavées
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 110

                  #roadclass in (1,2) : freeway, expressway/highway n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE roadclass in (1,2) AND structype NOT IN (5,6)"
   #               ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (highways road segments) as FEATURES with priority value 108"
   #               GenX::Log INFO "Buffering highway road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 108

               #structype in (1,2,3,4) : bridge (tous les types de ponts)
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE structype IN (1,2,3,4)"
   #               ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge road segments) as FEATURES with priority value 1"
   #               GenX::Log INFO "Buffering bridge road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 1
               }
            }
            QC_TR_1760009_1 {
               # This has been added to support CanVec-R7's new QC_TR layers, it may need revision for R8 (May 2011) or R9
               if { $indexCouverture=="OTTAWA"} {
                  GenX::Log DEBUG "Ignoring the QC_TR_1760009_1 layer for Ottawa to avoid duplicated roads with TR_1760009_1"
               } else {
# VALIDER LES NOM D'ATTRIBUTS DANS _QC_
                  # Thus for MONTREAL, QUEBEC and QC (IndustrX)
                  GenX::Log DEBUG "Rasterizing QC_TR_1760009_1 for $indexCouverture"
                  # entity : Road segment [Geobase], line
                  GenX::Log DEBUG "Post-processing for Road segment, lines"

                  #exclusions des structype 5 (tunnel) et 6 (snowshed), association de la valeur générale à tout le reste des routes pavées
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus != 2) AND structype NOT IN (5,6)"
   #               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general road segments) as FEATURES with priority value 109"
   #               GenX::Log INFO "Buffering general road segments to 12m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 109

                  #pavstatus = 2 : unpaved : routes non pavées n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE (pavstatus = 2) AND structype NOT IN (5,6)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (unpaved road segments) as FEATURES with priority value 110"
                  #pas de buffer sur les routes non pavées
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 110

                  #roadclass in (1,2) : freeway, expressway/highway n'étant pas des tunnels ou des snowsheds
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE roadclass in (1,2) AND structype NOT IN (5,6)"
   #               ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (highways road segments) as FEATURES with priority value 108"
   #               GenX::Log INFO "Buffering highway road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 108

               #structype in (1,2,3,4) : bridge (tous les types de ponts)
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM '$filename' WHERE structype IN (1,2,3,4)"
   #               ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge road segments) as FEATURES with priority value 1"
   #               GenX::Log INFO "Buffering bridge road segments to 22m"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 1
               }
            }
            default {
               #the layer is part of Param(LayersPostPro) but no case has been defined for it
               GenX::Log WARNING "Post-processing for $file not found.  The layer was not rasterized."
            }
         }
      } else {

         # Generic rasterization: entities that are not part of Param(LayersPostPro)
         eval ogrlayer read FEATURES SHAPE 0
         GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from file $file as FEATURES with priority value $priority, general procedure"
         gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
      }

      ogrlayer free FEATURES
      ogrfile close SHAPE
   }

   #creating the output file
   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT

   gdalfile close FILEOUT
   gdalband free RSANDWICH

   GenX::Log INFO "The file $GenX::Param(OutFile)_sandwich.tif was generated"
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
proc UrbanX::ChampsBuffers {indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   variable Data

   GenX::Log INFO "Buffer zone processing for grass and fields identification"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]

   gdalband create RBUFFER $Param(Width) $Param(Height) 1 Byte
   eval gdalband define RBUFFER -georef UTMREF$indexCouverture

   set i 0
   foreach file $Param(Files) {
      #entity contains an element of the form AA_9999999_9
      set entity [string range [file tail $file] 11 22] ;# strip full file path to keep layer name only
      if { $entity=="BS_2010009_0" || $entity=="BS_2010009_2" } {
         #filename contains an element of the form 999a99_9_9_AA_9999999_9
         set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
         ogrfile open SHAPE read $file
         switch $entity {
            BS_2010009_0 {
            GenX::Log DEBUG "Buffering ponctual buildings"
            set priority 666 ;# VALUE TO UPDATE
            ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM '$filename' WHERE function NOT IN (3,4,14,36) "
# Bug in spatial buffers
#            ogrlayer stats LAYER$i -buffer 0.000224982 8
            }
            BS_2010009_2 {
            GenX::Log DEBUG "Buffering 2D buildings"
            set priority 667 ;# VALUE TO UPDATE
# need updating this sqlselect
            ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM '$filename' WHERE function NOT IN (3,4,14,36) "
# Bug in spatial buffers
#            ogrlayer stats LAYER$i -buffer 0.00089993 8
            }
         }
         GenX::Log DEBUG "Buffering [ogrlayer define LAYER$i -nb] features from $filename as LAYER$i with buffer #priority $priority"
         gdalband gridinterp RBUFFER LAYER$i $Param(Mode) $priority
         ogrlayer free LAYER$i
         ogrfile close SHAPE
         incr i
      }
   }

   GenX::Log INFO "Cookie cutting grass and fields buffers and setting grass and fields and building vicinity values"
   gdalband create RBUFFERCUT $Param(Width) $Param(Height) 1 UInt16
   gdalband define RBUFFERCUT -georef UTMREF$indexCouverture
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER==0)),820,RBUFFERCUT)
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER!=0)),510,RBUFFERCUT)

   #----- On sauvegarde le tout - Next 5 lines are commented since writing results to file is unrequired
   #file delete -force $GenX::Param(OutFile)_champs_buf100ma+25mp.tif
   #gdalfile open FILEOUT write $GenX::Param(OutFile)_champs_buf100ma+25mp.tif GeoTiff
   #gdalband write RBUFFER FILEOUT
   #gdalfile close FILEOUT

   file delete -force $GenX::Param(OutFile)_champs-only+building-vicinity.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_champs-only+building-vicinity.tif GeoTiff
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
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log INFO "Reclassifying residential builtup areas using population density"
   variable Param

   GenX::Log DEBUG "Reading Sandwich file"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]

   #récupération du fichier de données socio-économiques
   GenX::Log DEBUG "Open and read the Canada-wide dissemination area polygons file"
   if {$GenX::Param(SMOKE)!="" } {
      set layer [lindex [ogrfile open SHAPE read $Param(PopFile2006SMOKE)] 0]
   } else {
      set layer [lindex [ogrfile open SHAPE read $Param(Census2006File)] 0]
   }
   eval ogrlayer read VPOPDENS $layer

   #----- Selecting only the required StatCan polygons - next is only useful to improve the speed of the layer substraction
   GenX::Log DEBUG "Select the appropriate dissemination area polygons"
   set da_select [ogrlayer pick VPOPDENS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   ogrlayer define VPOPDENS -featureselect [list [list index # $da_select]]

   #   clear la colonne POP_DENS pour les polygones de DA sélectionnés
   # au lieu de POP_DENS, on peut utiliser n'importe quel attribut inutilisé
   ogrlayer clear VPOPDENS CSDUID

   #création d'un fichier de rasterization des polygones de DA
   gdalband create RDA $Param(Width) $Param(Height) 1 Int32
   gdalband clear RDA -1
   gdalband define RDA -georef UTMREF$indexCouverture

   #rasterization des polygones de DA
   GenX::Log DEBUG "Rasterize the selected dissemination area polygons"
   gdalband gridinterp RDA VPOPDENS FAST FEATURE_ID

   #comptage des pixels de la residential area pour chaque polygone de DA : increment de la table et buildings generals (ponctuels et surfaciques)
   GenX::Log DEBUG "Counting pixels for residential areas and general function buildings for each dissemination area polygon"
   vexpr VPOPDENS.CSDUID tcount(VPOPDENS.CSDUID, ifelse(RSANDWICH==218 || RSANDWICH==104 || RSANDWICH==33,RDA,-1))

   #Calcul de la densité de population
   GenX::Log INFO "Calculating population density values and adjustments if required"
   foreach n $da_select {
      #récupération de la valeur de population
      if {$GenX::Param(SMOKE)!="" } {
         set pop [ogrlayer define VPOPDENS -feature $n POP_NEW]
      } else  {
         # Could use DAPOP2006 instead, but generates a few problems of missing data
         set pop [ogrlayer define VPOPDENS -feature $n POP]
      }
      #calcul de l'aire de la residential area à l'aide du nombre de pixels comptés précédemment
      set nbrpixels [ogrlayer define VPOPDENS -feature $n CSDUID]
      set area_pixels [expr ($nbrpixels*pow($Param(Resolution),2)/1000000.0)] ;#nbr de pixels * (5m*5m) de résolution / 1000000 m² par km² = area en km²
#      set area_pixels [expr ($nbrpixels*25.0/1000000.0)]
      #calcul de la densité de population : dentité = pop/aire_pixels
      if {$area_pixels != 0} {
         set densite_pixels [expr $pop/$area_pixels]
      } else {
         set densite_pixels 0
      }

      #calcul de l'aire à l'aide de la géométrie vectorielle
      set geom [ogrlayer define VPOPDENS -geometry $n]
      set area_vect [expr ([ogrgeometry stats $geom -area]/1000000.0)]
      #calcul de la densité de population : dentité = pop/aire_vect
      if {$area_vect != 0} {
         set densite_vect [expr $pop/$area_vect]
      } else {
         set densite_vect 0
      }

      #comparaison entre les deux densités calculées
      if {$densite_pixels != 0} {
         set densite_div [expr ($densite_pixels/$densite_vect)]
      } else {
         set densite_div 0
      }

      #affectation de la densité appropriée
      #Note : la densité est généralement plus précise lorsque calculée à partir des pixels.
      #Toutefois, il arrive que certains endoits reçoivent des valeurs extrêmes puisque, notamment,
      #les polygones de DA ne sont pas snappés avec les zones résidentielles, ce qui peut entraîner
      #des cas où toute la population d'un polygone se retrouve concentrée sur 1 ou 2 pixels.
      #Afin d'éviter ces problèmes, si le ratio entre la densité calculée à l'aide des pixels et la densité
      #calculée à l'aide de la géométrie dépasse un seuil, nous conserverons la deuxième option, qui
      #répartit la population sur l'ensemble du territoire plutôt que sur 1 ou 2 pixels, et la multiplions par
      #2 pour tenir compte du fait que l'ensemble du polygones n'est probablement pas résidentiel
      #(présence de parcs, de bâtiments non résidentiels, d'industries, etc.).  Le seuil choisi est de 20, ce
      #qui signifie que 95% du polygone n'est pas recouvert par les entités residential area ou bâtiments de
      #fonction générale.
      if { $densite_div > 20} {
         set densite_choisie [expr ($densite_vect * 2.0)]
         GenX::Log DEBUG "Adjustment of population density for polygon ID $n"
      } else {
         set densite_choisie $densite_pixels
      }
      ogrlayer define VPOPDENS -feature $n CSDUID $densite_choisie
   }
   unset da_select

   GenX::Log DEBUG "Conversion of population density in a raster file"
   gdalband create RPOPDENS $Param(Width) $Param(Height) 1 Float32
   eval gdalband define RPOPDENS -georef UTMREF$indexCouverture
   gdalband gridinterp RPOPDENS VPOPDENS $Param(Mode) CSDUID

   file delete -force $GenX::Param(OutFile)_popdens.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens.tif GeoTiff
   gdalband write RPOPDENS FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_popdens.tif was generated"

   # Freeing some memory
   gdalfile close FILEOUT
   ogrlayer free VPOPDENS
   ogrfile close SHAPE
   gdalband free RDA

   GenX::Log DEBUG "Cookie cutting population density and setting SMOKE/TEB values"
   gdalband create RPOPDENSCUT $Param(Width) $Param(Height) 1 Byte
   gdalband define RPOPDENSCUT -georef UTMREF$indexCouverture
   vexpr RRESIDENTIAL RSANDWICH==218
   gdalband free RSANDWICH

   if {$GenX::Param(SMOKE)!="" } {
      #seuils de densité de population associés à SMOKE (IndustrX)
      GenX::Log INFO "Applying thresholds for IndustrX"
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS<100),1,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && (RPOPDENS>=100 && RPOPDENS<1000)),2,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS>=1000 && RPOPDENS<4000),3,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS>=4000),4,RPOPDENSCUT)
   } else {
      GenX::Log INFO "Creating residential area classes based on population density"
      # Original code:
            vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS<100000),round(200+RPOPDENS/1000),RPOPDENSCUT)
            vexpr RPOPDENSCUT ifelse((RRESIDENTIAL && RPOPDENS>=100000),299,RPOPDENSCUT)
   }

   GenX::Log DEBUG "Generating output file, result of the cookie cutting"
   file delete -force $GenX::Param(OutFile)_popdens-builtup.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens-builtup.tif GeoTiff
   gdalband write RPOPDENSCUT FILEOUT
#   gdalband write TEST1 FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_popdens-builtup.tif was generated"

   gdalfile close FSANDWICH FILEOUT
   gdalband free RPOPDENS RRESIDENTIAL RPOPDENSCUT
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Dwellings2Builtup>
# Creation : March 2011 - Alexandre Leroux - CMC/CMOE
# Revision :
#
# Goal     :
#
#
# Parameters :
#      <indexCouverture>      : index à appliquer à la référence UTMREF
#
# Return: output files :
#
#
#
# Remarks : see Census documentation on CMC's wiki
#
#----------------------------------------------------------------------------
proc UrbanX::Dwellings2Builtup { indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
#   GenX::Log INFO "Reclassifying residential builtup areas using population density"
   GenX::Log INFO "Calculating dwellings density"
   variable Param

   GenX::Log DEBUG "Reading Sandwich file"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]

   #récupération du fichier de données socio-économiques
   GenX::Log DEBUG "Open and read the Canada-wide dissemination area polygons file"
   set layer [lindex [ogrfile open SHAPE read $Param(Census2006File)] 0]
   eval ogrlayer read VCENSUS $layer

   #----- Selecting only the required StatCan polygons - next is only useful to improve the speed of the layer substraction
   GenX::Log DEBUG "Select the appropriate dissemination area polygons"
   set da_select [ogrlayer pick VCENSUS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   ogrlayer define VCENSUS -featureselect [list [list index # $da_select]]

   #   clear la colonne POP_DENS pour les polygones de DA sélectionnés
   ogrlayer clear VCENSUS FARMS

# use un gdalband copy à la place ?
   #création d'un fichier de rasterization des polygones de DA
   gdalband create RDA $Param(Width) $Param(Height) 1 Int32
   gdalband clear RDA -1
   gdalband define RDA -georef UTMREF$indexCouverture

   #rasterization des polygones de DA
   GenX::Log DEBUG "Rasterize the selected dissemination area polygons"
   gdalband gridinterp RDA VCENSUS FAST FEATURE_ID

   #comptage des pixels de la residential area pour chaque polygone de DA : increment de la table et buildings generals (ponctuels et surfaciques)
   GenX::Log DEBUG "Counting pixels for residential areas and general function buildings for each dissemination area polygon"
   vexpr VCENSUS.FARMS tcount(VCENSUS.FARMS,ifelse (RSANDWICH==218 || RSANDWICH==104 || RSANDWICH==33,RDA,-1))

   #Calcul de la densité de population
   GenX::Log INFO "Calculating dwellings density values and adjustments if required"
   foreach n $da_select {
      # Get the total dwelling values, there is TDWELL and DATDWELL20, but DATDWELL20 seems to have missing values
      set pop [ogrlayer define VCENSUS -feature $n TDWELL]
      #calcul de l'aire de la residential area à l'aide du nombre de pixels comptés précédemment
      set nbrpixels [ogrlayer define VCENSUS -feature $n FARMS]
      set area_pixels [expr ($nbrpixels*pow($Param(Resolution),2)/1000000.0)] ;#nbr de pixels * (5m*5m) de résolution / 1000000 m² par km² = area en km²
      #calcul de la densité de population : dentité = pop/aire_pixels
      if {$area_pixels != 0} {
         set densite_pixels [expr $pop/$area_pixels]
      } else {
         set densite_pixels 0
      }

      #calcul de l'aire à l'aide de la géométrie vectorielle
      set geom [ogrlayer define VCENSUS -geometry $n]
      set area_vect [expr ([ogrgeometry stats $geom -area]/1000000.0)]
      #calcul de la densité de population : dentité = pop/aire_vect
      if {$area_vect != 0} {
         set densite_vect [expr $pop/$area_vect]
      } else {
         set densite_vect 0
      }

      #comparaison entre les deux densités calculées
      if {$densite_pixels != 0} {
         set densite_div [expr ($densite_pixels/$densite_vect)]
      } else {
         set densite_div 0
      }

      #affectation de la densité appropriée
      #Note : la densité est généralement plus précise lorsque calculée à partir des pixels.
      #Toutefois, il arrive que certains endoits reçoivent des valeurs extrêmes puisque, notamment,
      #les polygones de DA ne sont pas snappés avec les zones résidentielles, ce qui peut entraîner
      #des cas où toute la population d'un polygone se retrouve concentrée sur 1 ou 2 pixels.
      #Afin d'éviter ces problèmes, si le ratio entre la densité calculée à l'aide des pixels et la densité
      #calculée à l'aide de la géométrie dépasse un seuil, nous conserverons la deuxième option, qui
      #répartit la population sur l'ensemble du territoire plutôt que sur 1 ou 2 pixels, et la multiplions par
      #2 pour tenir compte du fait que l'ensemble du polygones n'est probablement pas résidentiel
      #(présence de parcs, de bâtiments non résidentiels, d'industries, etc.).  Le seuil choisi est de 20, ce
      #qui signifie que 95% du polygone n'est pas recouvert par les entités residential area ou bâtiments de
      #fonction générale.
      if { $densite_div > 20} {
         set densite_choisie [expr ($densite_vect * 2.0)]
         GenX::Log DEBUG "Adjustment of dwellings density for polygon ID $n"
      } else {
         set densite_choisie $densite_pixels
      }
      ogrlayer define VCENSUS -feature $n FARMS $densite_choisie
   }

   unset da_select

# use un gdalband copy à la place ?
   #Conversion de la densité de population en raster
   GenX::Log DEBUG "Conversion of population density in a raster file"
   gdalband create RDWELLINGS $Param(Width) $Param(Height) 1 Float32
   eval gdalband define RDWELLINGS -georef UTMREF$indexCouverture
   gdalband gridinterp RDWELLINGS VCENSUS $Param(Mode) FARMS

   #écriture du fichier genphysx_popdens.tif contenant la densité de population
   file delete -force $GenX::Param(OutFile)_dwellings-density.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_dwellings-density.tif GeoTiff
   gdalband write RDWELLINGS FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_dwellings-density.tif was generated"

   gdalfile close FILEOUT
   ogrlayer free VCENSUS
   ogrfile close SHAPE
   gdalband free RDA

   gdalband read RPOPDENS [gdalfile open FPOPDENS read $GenX::Param(OutFile)_popdens.tif]

   vexpr RPOPDWERATIO RPOPDENS/RDWELLINGS


   file delete -force $GenX::Param(OutFile)_popdens-dwellings-ratio.tif
   gdalfile open FPOPDWERATIO write $GenX::Param(OutFile)_popdens-dwellings-ratio.tif GeoTiff
   gdalband write RPOPDWERATIO FPOPDWERATIO
   GenX::Log INFO "The file $GenX::Param(OutFile)_popdens-dwellings-ratio.tif was generated"

   gdalfile close FSANDWICH FILEOUT FPOPDENS FPOPDWERATIO
   gdalband free RSANDWICH RDWELLINGS
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
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log INFO "Evaluating height gain"

   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband create RHAUTEURPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURPROJ -georef UTMREF$indexCouverture
   gdalband stats RHAUTEURPROJ -nodata -9999

   #----- La vérification pourrait être fait dans un proc avec vérification des 4 points de la source
   gdalband read RHAUTEUR [gdalfile open FHAUTEUR read $Param(HeightFile)]
   GenX::Log WARNING "Next line crashes for Montreal, probably a real memory fault. The whole 2006 substraction should be re-coded to use GenPhysX and compute the output directly on the final grid"
   gdalband gridinterp RHAUTEURPROJ RHAUTEUR
   gdalband free RHAUTEUR
   gdalfile close FHAUTEUR

   set min [gdalband stats RHAUTEURPROJ -min]
   if { [lindex $min 0] == -9999 } {
      GenX::Log WARNING "Heights does not overlap entirely the area, average won't be good, absent values will be set to 0"
      vexpr RHAUTEURPROJ ifelse(RHAUTEURPROJ==-9999,0,RHAUTEURPROJ)
   }
   vexpr RHEIGHTCHAMPS ifelse(RCHAMPS==820,RHAUTEURPROJ,0)


   #----- Average est calculé (pour le moment) que pour les valeurs != 0 dans le code en C
   #      Pour avec les 0: set Param(HeightGain) [vexpr XX savg(RHEIGHTCHAMPS)]
   gdalband stats RHEIGHTCHAMPS -nodata 0
   set Param(HeightGain) [gdalband stats RHEIGHTCHAMPS -avg]

   GenX::Log INFO "Average gain calculated over defined areas = $Param(HeightGain)"
   if {($Param(HeightGain)>=10 || $Param(HeightGain)<=-10) || $Param(HeightGain)==0 } {
      GenX::Log WARNING "Strange value for Param(HeightGain): $Param(HeightGain)"
   }

   file delete -force $GenX::Param(OutFile)_hauteur-classes.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-classes.tif GeoTiff
   gdalband write RHEIGHTCHAMPS FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_hauteur-classes.tif was generated"

   gdalfile close FILEOUT FCHAMPS
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
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Cookie cutting building heights and adding gain"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RHAUTEURWMASK [gdalfile open FHAUTEUR read $Param(HeightMaskFile)]

   gdalband create RHAUTEURWMASKPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURWMASKPROJ -georef UTMREF$indexCouverture

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

#   file delete -force $GenX::Param(OutFile)_hauteur-builtup+building.tif
#   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-builtup+building.tif GeoTiff
#   gdalband write RHAUTEURCUT FILEOUT
#   gdalfile close FILEOUT
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-classes.tif GeoTiff
   gdalband write RHAUTEURCLASS FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_hauteur-classes.tif was generated"

   gdalfile close FILEOUT FSANDWICH
   gdalband free RHAUTEURCLASS RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::EOSDvegetation>
# Creation : October 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :  Replaces empty zones or wooded area zones
#                  by values from EOSD dataset
#
# Parameters :
#
# Return:
#
# Remarks : WARNING, EOST DATA DOES NOT COVER ALL CANADA
#
#----------------------------------------------------------------------------
proc UrbanX::EOSDvegetation { indexCouverture } {
# THIS PROC COULD PROBABLY BE DELETED - NOT USED BY SMOKE OR TEB
   variable Param
   variable Const
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log INFO "Beginning of procedure"

   #lecture du fichier créé précédemment lors de la proc SandwichCanVec
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]

   #recherche des fichiers EOSD
   set Param(EOSDFiles) [GenX::EOSDFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)]
   #Param(EOSDFiles) contains one element of the form /cnfs/ops/production/cmoe/geo/EOSD/999A_lc_1/999A_lc_1.tif
   GenX::Log DEBUG "The following EOSD file was found: $Param(EOSDFiles)"

   #read the EOSD file
   gdalband read REOSDTILE [gdalfile open FEOSDTILE read $Param(EOSDFiles)]

   #sélection de la zone EOSD appropriée à l'aide de la sandwich
   GenX::Log INFO "Selecting the appropriate zone on the EOSD tiles"
   gdalband copy RMASK RSANDWICH
   vexpr RMASK RMASK << 0
   gdalband gridinterp RMASK REOSDTILE NEAREST

   #conserver les valeurs EOSD lorsque la sandwich est vide ou présente une zone boisée
   GenX::Log INFO "EOSD values are kept when Sandwich is empty or covered by Wooded Area"
   vexpr RVEGE ifelse((RSANDWICH==0 || RSANDWICH==200),RMASK, 0)

   #écriture du fichier
   file delete -force $GenX::Param(OutFile)_EOSDVegetation.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_EOSDVegetation.tif GeoTiff
   gdalband write RVEGE FILEOUT
   gdalfile close FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDVegetation.tif was generated"

   #affectation des valeurs SMOKE
   GenX::Log INFO "Converting EOSD classes into SMOKE/TEB values"
   gdalband create RVEGESMOKE $Param(Width) $Param(Height) 1 Byte
   gdalband define RVEGESMOKE -georef UTMREF$indexCouverture

   vector create FROMEOSD [lindex $Const(EOSD2SMOKE) 0]
   vector create TOSMOKE  [lindex $Const(EOSD2SMOKE) 1]
   vexpr RVEGE ifelse((RSANDWICH==0 || RSANDWICH==200),lut(RVEGE,FROMEOSD,TOSMOKE),RVEGE)
   vector free FROMEOSD TOSMOKE

   #écriture du fichier
   file delete -force $GenX::Param(OutFile)_EOSDSMOKE.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_EOSDSMOKE.tif GeoTiff
   gdalband write RVEGESMOKE FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDSMOKE.tif was generated"

   gdalfile close FSANDWICH FEOSDTILE FILEOUT
   gdalband free RSANDWICH REOSDTILE RVEGE RVEGESMOKE
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
proc UrbanX::LCC2000V { indexCouverture } {
   variable Param
   variable Const
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log INFO "Integrating LCC2000-V data for vegetated areas"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband copy RLCC2000V RSANDWICH
   vexpr RLCC2000V RLCC2000V << 0

   set j 0 ;# Increment of LAYERLCC2000V$j required to re-use the object
   foreach file [GenX::LCC2000VFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)] {
      GenX::Log DEBUG "Processing LCC2000-V file $file"
      ogrfile open SHAPELCC2000V read $file
      eval ogrlayer read LAYERLCC2000V$j SHAPELCC2000V 0 ;# read the LCC2000V file

      GenX::Log DEBUG "Rasterize the selected LCC2000-V (this step can take several minutes...)"
      set t_gridinterp [clock seconds]
      gdalband gridinterp RLCC2000V LAYERLCC2000V$j $Param(Mode) COVTYPE
      GenX::Log DEBUG "Time required for LCC2000V rasterization: [expr [clock seconds]-$t_gridinterp] seconds"

      ogrlayer free LAYERLCC2000V$j
      ogrfile close SHAPELCC2000V
      incr j ;# Increment of VFEATURE2KEEP$j required to re-use the object
   }
   vector create LUT.FROM [lindex $Const(LCC2000LUT) 0]
   if {$GenX::Param(SMOKE)!="" } {
      GenX::Log INFO "Associating LCC2000-V values to SMOKE classes"
      vector create LUT.TO     [lindex $Const(LCC2000LUT) 1]
   } else {
      GenX::Log INFO "Associating LCC2000-V values to TEB classes"
      vector create LUT.TO     [lindex $Const(LCC2000LUT) 2]
   }
   vexpr RLCC2000VSMOKE lut(RLCC2000V,LUT.FROM,LUT.TO)
   vector free LUT.FROM LUT.TO

   file delete -force $GenX::Param(OutFile)_LCC2000V-LUT.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_LCC2000V-LUT.tif GeoTiff
   gdalband write RLCC2000VSMOKE FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_LCC2000V-LUT.tif was generated"
   gdalfile close FLCC2000V FILEOUT FSANDWICH
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
proc UrbanX::Priorities2TEB { indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Aggregating rasters into TEB classes"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup.tif]
#   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband read RLCC2000V [gdalfile open FLCC2000V read $GenX::Param(OutFile)_LCC2000V-LUT.tif]
#   gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(OutFile)_hauteur-classes.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Priorities)
   vector set LUT.TO $Param(TEBClasses)
   vexpr RTEB lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   vexpr RTEB ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RTEB)
# next rasters are missing
#   vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
#   vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RTEB)
   # Rasters must now be closed otherwise we blow up memory for large cities
   gdalfile close FSANDWICH FPOPDENSCUT FCHAMPS FHAUTEURCLASS
   gdalband free RSANDWICH RPOPDENSCUT RCHAMPS RHAUTEURCLASS

   vexpr RTEB ifelse((RLCC2000V!=0 && (RTEB==0 || RTEB==810 || RTEB==820 || RTEB==840)),RLCC2000V,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB.tif GeoTiff
   gdalband write RTEB FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_TEB.tif was generated"

   gdalfile close FILEOUT FLCC2000V
   gdalband free RTEB RLCC2000V
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
#
#----------------------------------------------------------------------------
proc UrbanX::VegeMask { } {
# This proc is probably useless now that urban vegetation classes are managed by ISBA
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Generating vegetation mask"

   gdalband read RTEB [gdalfile open FTEB read $GenX::Param(OutFile)_TEB.tif]

   vexpr RTEBWMASK ifelse(RTEB>800,100,0)

   set fileRTEBfilter $GenX::Param(OutFile)_vegemask-$Param(VegeFilterType)$Param(VegeFilterSize).tif

   if { ![file exists $fileRTEBfilter] } {
      if { $Param(VegeFilterSize) > 20 } {
         GenX::Log INFO "Generating this $Param(VegeFilterType)$Param(VegeFilterSize) vegetation mask may require hours to process"
      }
      vector create FILTER [UrbanX::FilterGen $Param(VegeFilterType) $Param(VegeFilterSize)]
      #----- Le nodata sert à simuler l'application d'un mask au filtre qui suit
      vexpr RTEBWMASK ifelse(RTEB==901,901,RTEBWMASK)
      gdalband stats RTEBWMASK -nodata 901
      vexpr VEGEMASK fkernel(RTEBWMASK,FILTER)
#      vexpr VEGEMASK fcentile(RTEBWMASK,3,0.5) ;# fcentile is fmedian, fmax, fmin à la fois

      file delete -force $fileRTEBfilter
      gdalfile open FILEOUT write $fileRTEBfilter GeoTiff
      gdalband write VEGEMASK FILEOUT
      gdalfile close FILEOUT
   } else {
      GenX::Log INFO "Using previously computed filtered data $fileRTEBfilter"
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
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Computing TEB parameters on the target RPN fstd grid: $GenX::Param(GridFile)"

   GenX::Log DEBUG "Reading the TEB parameters LUT in csv exported from the TEB-Params_LUT.xls file"
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

   gdalband read RTEB [gdalfile open FTEB read $GenX::Param(OutFile)_TEB.tif]
   gdalfile close FTEB

   # Normally, this shouldn't be needed, but since there are many holes in OutFile_TEB.tif at the moment
   GenX::Log INFO "Overwriting areas without any TEB class to Building vicinity (class 510) - this is a temporary fix for the spatial buffers bug"
   vexpr RTEB ifelse(RTEB==0,510,RTEB)

   fstdfield stats $Grid -nodata 0 ;# Required to avoid NaN in the gridinterp AVERAGE over nodata-only values

   foreach tebparam [lrange [vector dim CSVTEBPARAMS] 1 end] {
#   foreach tebparam [lrange [vector dim CSVTEBPARAMS] 1 4]
      GenX::Log DEBUG "Copying the $tebparam values to the 5m raster with LUT"
      vexpr RTEBPARAM lut(RTEB,CSVTEBPARAMS.TEB_Class,CSVTEBPARAMS.$tebparam)

      gdalband stats RTEBPARAM -nodata -9999 ;# memory fault if this comes after the gdalband write
      fstdfield clear $Grid 0

      # For debugging purposes, writing TEB parameter values at 5m in a file
      #file delete -force $GenX::Param(OutFile)_TEB-$tebparam.tif
      #gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB-$tebparam.tif GeoTiff
      #gdalband write RTEBPARAM FILEOUT
      #gdalfile close FILEOUT
      #GenX::Log INFO "The file $GenX::Param(OutFile)_TEB-$tebparam.tif has been saved for debugging purposes"

      set ip1 [vector get CSVTEBPARAMS.$tebparam 0]
      set ip1 [expr int($ip1)] ;# IP1 must be an integer

      # Fixing NOMVAR names from unique values to their RPN value
      set nomvar_5lettres { HCRF1 HCRD1 HCWL1 TCRF1 TCRD1 TCWL1 DPRF1 DPRD1 DPWL1 HCRF2 HCRD2 HCWL2 TCRF2 TCRD2 TCWL2 DPRF2 DPRD2 DPWL2 HCRF3 HCRD3 HCWL3 TCRF3 TCRD3 TCWL3 DPRF3 DPRD3 DPWL3 VF_1 VF_2 VF_3 VF_4 VF_5 VF_6 VF_7 VF_8 VF_9 VF10 VF11 VF12 VF13 VF14 VF15 VF16 VF17 VF18 VF19 VF20 VF21 VF22 VF23 VF24 VF25 VF26 }
      set nomvar_fixed    { HCRF HCRD HCWL TCRF TCRD TCWL DPRF DPRD DPWL HCRF HCRD HCWL TCRF TCRD TCWL DPRF DPRD DPWL HCRF HCRD HCWL TCRF TCRD TCWL DPRF DPRD DPWL VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF VF }
      if { [lsearch $nomvar_5lettres $tebparam ] !=-1} {
         set tebparam [lindex $nomvar_fixed [lsearch $nomvar_5lettres $tebparam]]
      }

      GenX::Log INFO "Averaging TEB parameter $tebparam (IP1=$ip1) values over target grid"

      fstdfield gridinterp $Grid RTEBPARAM AVERAGE True
      fstdfield define $Grid -NOMVAR $tebparam -IP1 $ip1
      if { $tebparam == "VF"} {
         fstdfield write $Grid GPXOUTFILE -32 True $GenX::Param(Compress) ;# Writing VF fields to the OutFile
      } else {
         fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress) ;# Writing TEB-only fields to the AuxFile
      }

      if { $tebparam == "BLDH"} {
        # Building height variance computation
         set memoryrequired [expr 5*$Param(Width)*$Param(Height)*8/(1024*1024)] ;# the factor 5x is for the internal buffers of the AVERAGE_VARIANCE fct... is this formulae right?
         if { $memoryrequired > 1600 } {
            GenX::Log WARNING "HVAR: target grid size too large, memory requirements over $memoryrequired megs. Until we compile 64 bits, can't compute Building Height Variance (HVAR) over target grid"
         } else {
            GenX::Log INFO "Computing Building Height Variance HVAR (IP1=0) values over target grid (RAM needed: $memoryrequired)"
            gdalband free RTEB ;# to reduce possibilities of a real memory fault
            fstdfield read BLDHFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDH"
            fstdfield clear $Grid 0
            fstdfield gridinterp $Grid RTEBPARAM AVERAGE_VARIANCE BLDHFIELD True
            fstdfield define $Grid -NOMVAR HVAR -IP1 0
            fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)
            fstdfield free BLDHFIELD

            gdalband read RTEB [gdalfile open FTEB read $GenX::Param(OutFile)_TEB.tif] ;# reopening since closed for memory purposes
            gdalfile close FTEB
         }

         # Building height min computation
         GenX::Log INFO "Computing Building Height Minimum HMIN (IP1=0) values over target grid"
         fstdfield clear $Grid 0
         fstdfield gridinterp $Grid RTEBPARAM MINIMUM
         fstdfield define $Grid -NOMVAR HMIN -IP1 0
         fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)

         # Building height max computation
         GenX::Log INFO "Computing Building Height Maximum HMAX (IP1=0) values over target grid"
         fstdfield clear $Grid 0
         fstdfield gridinterp $Grid RTEBPARAM MAXIMUM
         fstdfield define $Grid -NOMVAR HMAX -IP1 0
         fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)
      }
      gdalband free RTEBPARAM
   }
   vector free CSVTEBPARAMS
   gdalband free RTEB

   fstdfield read BLDHFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDH"
   fstdfield read BLDFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "BLDF"
   fstdfield read PAVFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "PAVF"
   fstdfield read VEGFFIELD GPXAUXFILE -1 "" 0 -1 -1 "" "VEGF"

   GenX::Log INFO "Computing SUMF: sum of VEGF, BLDF and PAVF, for validation purposes"
   fstdfield clear $Grid 0
   vexpr $Grid VEGFFIELD+BLDFFIELD+PAVFFIELD
   fstdfield define $Grid -NOMVAR SUMF -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)
   fstdfield free PAVFFIELD VEGFFIELD

   # Wall-O-Hor calculations
   GenX::Log INFO "Computing geometric TEB parameter Wall-O-Hor WHOR (IP1=0) values over target grid"
   fstdfield clear $Grid 0
   # WALL-O-HOR formulae provided by Sylvie Leroyer
   vexpr REZ (ddx($Grid)+ddy($Grid))/2  ;# spatial resolution of the target grid in meters
   vexpr WHORFIELD BLDHFIELD*(2.0/REZ^2)*(sqrt(BLDFFIELD*REZ^2))
   fstdfield define WHORFIELD -NOMVAR WHOR -IP1 0
   fstdfield write WHORFIELD GPXAUXFILE -32 True $GenX::Param(Compress)

   # Z0_TOWN calculations
   GenX::Log INFO "Computing geometric TEB parameter Z0_TOWN Z0TW (IP1=0) values with the MacDonald 1998 Model over target grid"
   fstdfield clear $Grid 0
   vexpr DISPH BLDHFIELD*(1+(4.43^(BLDFFIELD*(-1.0))*(BLDFFIELD-1.0))) ;# Computing Displacement height
# DELETE THIS LINE if next one works   vexpr $Grid BLDHFIELD*((1.0-DISPH/BLDHFIELD)*exp(-1.0*((0.5*1.0*1.2/0.4^2*((1.0-DISPH/BLDHFIELD)*(WHORFIELD/2.0)))^( -0.5))))
   vexpr $Grid ifelse(BLDHFIELD==0,0, BLDHFIELD*((1.0-DISPH/BLDHFIELD)*exp(-1.0*((0.5*1.0*1.2/0.4^2*((1.0-DISPH/BLDHFIELD)*(WHORFIELD/2.0)))^( -0.5))))) ;# ifelse required to avoid dividing by 0
   fstdfield define $Grid -NOMVAR Z0TW -IP1 0
   fstdfield write $Grid GPXAUXFILE -32 True $GenX::Param(Compress)
   fstdfield free BLDHFIELD BLDFFIELD WHORFIELD REZ

   GenX::Log INFO "The file $GenX::Param(OutFile)_aux.fst has been updated with TEB parameters"
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
proc UrbanX::BuildingHeights2Raster { indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Converting $indexCouverture buildings shapefile to raster"

   gdalband create RHAUTEURBLD $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURBLD -georef UTMREF$indexCouverture

   set shp_layer [lindex [ogrfile open SHAPE read $Param(BuildingsShapefile)] 0]
   eval ogrlayer read LAYER $shp_layer
   gdalband gridinterp RHAUTEURBLD LAYER $Param(Mode) $Param(BuildingsHgtField)

   GenX::Log INFO "All buildings shorter than 5m set to an height of 5m"
   vexpr RHAUTEURBLD ifelse(RHAUTEURBLD<5,5,RHAUTEURBLD)

   ogrlayer free LAYER
   ogrfile close SHAPE

   file delete -force $GenX::Param(OutFile)_Building-heights.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_Building-heights.tif GeoTiff
   gdalband write RHAUTEURBLD FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_Building-heights.tif was generated"

   gdalfile close FILEOUT
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
proc UrbanX::3DBuildings2Sandwich { indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Overwriting $indexCouverture CanVec sandwich by adding vector 3D buildings"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RHAUTEURBLD [gdalfile open FHAUTEURBLD read $GenX::Param(OutFile)_Building-heights.tif]

   GenX::Log INFO "Adding new-only buildings to priority 104 (unknown or other 2D buildings)"
   # On ignore les priorités <= 106 puisqu'elles sont soit des bâtiments existants soit au-dessus des bâtiments
   vexpr RSANDWICH ifelse(((RHAUTEURBLD>0) && (RSANDWICH>=106)),104,RSANDWICH)

   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_sandwich.tif was overwritten"

   gdalfile close FSANDWICH FHAUTEURBLD FILEOUT
   gdalband free RSANDWICH RHAUTEURBLD
}


#----------------------------------------------------------------------------
# Name     : <UrbanX::TEBGeoParams>
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
proc UrbanX::TEBGeoParams { indexCouverture res } {
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param

   set resdeg [expr ($res/$Param(Deg2M))] ;# in degrees
   GenX::Log INFO "Computing TEB geometric parameters on a $res\m raster"

   GenX::UTMZoneDefine [expr ($Param(Lat0)+($resdeg))] [expr ($Param(Lon0)+($resdeg))] [expr ($Param(Lat1)+($resdeg))] [expr ($Param(Lon1)+($resdeg))] $res UTMREF100M$indexCouverture

# move to local var
   set lowrezwidth  [expr int(floor($Param(Width)/($res/$Param(Resolution))))]
   set lowrezheight [expr int(floor($Param(Height)/($res/$Param(Resolution))))]
   gdalband create RTEB100M $lowrezwidth $lowrezheight 1 Float32
   gdalband define RTEB100M -georef UTMREF100M$indexCouverture

   # TEB param computations with 3D buildings
   if { $Param(BuildingsShapefile)!="" } {

      gdalband read RHAUTEURBLD [gdalfile open RHAUTEURBLDFILE read $GenX::Param(OutFile)_Building-heights.tif]
      gdalband stats RHAUTEURBLD -nodata 0 ;# to average buildings without empty spaces

      # Building heights average
      set buildingheightfile $GenX::Param(OutFile)_Building-heights-average.tif
      if { [file exists $buildingheightfile] } {
         GenX::Log INFO "Using existing buildings heights average raster: $GenX::Param(OutFile)_Building-heights-average.tif"
         gdalband read RBLDHAVG [gdalfile open FILE read $GenX::Param(OutFile)_Building-heights-average.tif]
      } else {
         GenX::Log INFO "Computing building heights average at $res\m (ignoring empty spaces)"
         gdalband copy RBLDHAVG RTEB100M     ;# to create RBLDHAVG

         gdalband gridinterp RBLDHAVG RHAUTEURBLD AVERAGE

         file delete -force $GenX::Param(OutFile)_Building-heights-average.tif
         gdalfile open FILEOUT write $GenX::Param(OutFile)_Building-heights-average.tif GeoTiff
         gdalband write RBLDHAVG FILEOUT
         GenX::Log INFO "The file $GenX::Param(OutFile)_Building-heights-average.tif was generated"
         gdalfile close FILEOUT
      }
      gdalfile close FILE

      # Building fraction
      set buildingfractionfile $GenX::Param(OutFile)_Building-fraction.tif
      if { [file exists $buildingfractionfile] } {
         GenX::Log INFO "Using existing buildings fraction raster: $GenX::Param(OutFile)_Building-fraction.tif"
         gdalband read RBLDFRACTION [gdalfile open FILE read $GenX::Param(OutFile)_Building-fraction.tif]
         gdalfile close FILE
      } else {
         GenX::Log INFO "Computing building fraction at $res\m"
         gdalband copy RBLDFRACTION RTEB100M ;# to create RBLDFRACTION

# version RASTER du calcul - à remplacer par vector ci-dessous ? (bug double counting)
         set facteurfraction [expr 1/pow($res/$Param(Resolution),2)]
         vexpr RSURFACEBLD ifelse(RHAUTEURBLD==0,0,$facteurfraction)      ;# creates RSURFACEBLD
         set starttime [clock seconds]
 ##      gdalband gridinterp RBLDFRACTION RSURFACEBLD SUM   ;# double-counting de tous les pixels on the edge
         gdalband gridinterp RBLDFRACTION RSURFACEBLD CONSERVATIVE 1 True ;# took 2691 seconds for Montreal
         GenX::Log DEBUG "Time taken for RASTER CONSERVATIVE fraction [expr [clock seconds]-$starttime] seconds"
         gdalband free RSURFACEBLD


# BUG DE DOUBLE COUNTING DES POLYGONES SE CHEVAUCHANT (reswitcher à fraction raster?)
#         set shp_layer [lindex [ogrfile open SHAPE read $Param(BuildingsShapefile)] 0]
#         eval ogrlayer read LAYER $shp_layer
#         set starttime [clock seconds]
#         gdalband gridinterp RBLDFRACTION LAYER CONSERVATIVE FEATURE_AREA
##         gdalband gridinterp RBLDFRACTION LAYER NORMALIZE FEATURE_AREA
#         GenX::Log DEBUG "Time taken for VECTOR CONSERVATIVE fraction [expr [clock seconds]-$starttime] seconds"
##         GenX::Log DEBUG "Time taken for VECTOR NORMALIZE fraction [expr [clock seconds]-$starttime] seconds"
## normalize puis enlever next line
#         vexpr RBLDFRACTION RBLDFRACTION/($res*$res) ;# To get a fraction between 0 and 1
#         ogrlayer free LAYER
#         ogrfile close SHAPE


         file delete -force $GenX::Param(OutFile)_Building-fraction.tif
         gdalfile open FILEOUT write $GenX::Param(OutFile)_Building-fraction.tif GeoTiff
         gdalband write RBLDFRACTION FILEOUT
         GenX::Log INFO "The file $GenX::Param(OutFile)_Building-fraction.tif was generated"
         gdalfile close FILEOUT
      }

      # WALL_O_HOR
      set wallohorfile $GenX::Param(OutFile)_Building-WallOHor.tif
      if { [file exists $wallohorfile] } {
         GenX::Log INFO "Using existing Wall-O-Hor raster: $GenX::Param(OutFile)_Building-WallOHor.tif"
         gdalband read RWALLOHOR [gdalfile open WALLOHORFILE read $GenX::Param(OutFile)_Building-WallOHor.tif]
         gdalfile close WALLOHORFILE
      } else {
         GenX::Log INFO "Computing WALL_O_HOR at $res\m"
         gdalband create RWALLOHOR $lowrezwidth $lowrezheight 1 Float32
         eval gdalband define RWALLOHOR -georef UTMREF100M$indexCouverture

         # WALL-O-HOR formulae provided by Sylvie Leroyer
         set facteurWoH1 [expr 2.0/pow(($res),2)]
         set facteurWoH2 [expr pow($res,2)]
         vexpr RWALLOHOR RBLDHAVG*$facteurWoH1*(sqrt(RBLDFRACTION*$facteurWoH2))

         file delete -force $GenX::Param(OutFile)_Building-WallOHor.tif
         gdalfile open FILEOUT write $GenX::Param(OutFile)_Building-WallOHor.tif GeoTiff
         gdalband write RWALLOHOR FILEOUT
         gdalfile close FILEOUT
         GenX::Log INFO "The file $GenX::Param(OutFile)_Building-WallOHor.tif was generated"
      }

      # Z0_TOWN
      set z0townfile $GenX::Param(OutFile)_Building-Z0Town.tif
      if { [file exists $z0townfile] } {
         GenX::Log INFO "Using existing Z0_Town raster: $GenX::Param(OutFile)_Building-Z0Town.tif"
         gdalband read RZ0TOWN [gdalfile open Z0TOWNFILE read $GenX::Param(OutFile)_Building-Z0Town.tif]
         gdalfile close Z0TOWNFILE
      } else {
         GenX::Log INFO "Computing Z0_TOWN at $res\m with the MacDonald 1998 Model"
         # Note: the ^ operator can be used in vexpr, but not in expr
         vexpr RDISPLACEMENTHEIGHT RBLDHAVG*(1+(4.43^(RBLDFRACTION*(-1.0))*(RBLDFRACTION - 1.0)))
         vexpr RZ0TOWN RBLDHAVG*((1.0-RDISPLACEMENTHEIGHT/RBLDHAVG)*exp( -1.0*((0.5*1.0*1.2/0.4^2*((1.0-RDISPLACEMENTHEIGHT/RBLDHAVG)*(RWALLOHOR/2.0)))^( -0.5))))

         #GenX::Log INFO "Computing Z0_TOWN at $res\m with the Raupach 1994 Model"
         #vexpr RDISPLACEMENTHEIGHT RBLDHAVG*(1+(exp(-1.0*(7.5*2.0*RWALLOHOR/2.0)^0.5-1.0)/(7.5*2.0*RWALLOHOR/2.0)^0.5))
         #vexpr RZ0TOWN RBLDHAVG*((1.0-RDISPLACEMENTHEIGHT/RBLDHAVG)*exp((-1.0)*0.4/min((0.003+0.3*RWALLOHOR/2.0)^0.5,0.3)+0.193))

         file delete -force $GenX::Param(OutFile)_Building-Z0Town.tif
         gdalfile open FILEOUT write $GenX::Param(OutFile)_Building-Z0Town.tif GeoTiff
         gdalband write RZ0TOWN FILEOUT
         gdalfile close FILEOUT
         GenX::Log INFO "The file $GenX::Param(OutFile)_Building-Z0Town.tif was generated"

         gdalband free RDISPLACEMENTHEIGHT RZ0TOWN
      }

      gdalband free RWALLOHOR RBLDHAVG RHAUTEURBLD RBLDFRACTION
      gdalfile close FILEOUT
      ogrlayer free LAYER
      ogrfile close SHAPE
   }


# RTEB100M not used at the moment...
#   file delete -force $GenX::Param(OutFile)_TEBParams-$res\m.tif
#   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEBParams-$res\m.tif GeoTiff
#   gdalband write RTEB100M FILEOUT
#   GenX::Log INFO "The file $GenX::Param(OutFile)_TEBParams-$res\m.tif was generated"
#   GenX::Log INFO "$GenX::Param(OutFile)_TEBParams-$res\m.tif is slightly smaller than $GenX::Param(OutFile)_TEB.tif to avoid missing data over boundaries"

   gdalfile close FILEOUT RHAUTEURBLDFILE
   gdalband free RTEB100M
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
   GenX::Procs ;# Adding the proc to the metadata log

   #----- Est-ce cette proc maintenant dans le 'main code' de JP?
   #      Il manque les filtres median, directionel, lp/hp gaussien, Sobel/Roberts, FFT
   if { $Size%2 == 0 } {
      set Size [expr ($Size -1)]
      GenX::Log WARNING "Filter size must be an odd number, decreasing filter size to $Size"
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
proc UrbanX::DeleteTempFiles { indexCouverture } {
   GenX::Log INFO "Deleting all temporary files"

   file delete -force $GenX::Param(OutFile)_LCC2000V-LUT.tif
   file delete -force $GenX::Param(OutFile)_EOSDSMOKE.tif
   file delete -force $GenX::Param(OutFile)_EOSDVegetation.tif
   file delete -force $GenX::Param(OutFile)_hauteur-classes.tif
   file delete -force $GenX::Param(OutFile)_popdens-builtup.tif
   file delete -force $GenX::Param(OutFile)_popdens.tif
   file delete -force $GenX::Param(OutFile)_champs-only+building-vicinity.tif
   file delete -force $GenX::Param(OutFile)_sandwich.tif
   file delete -force $GenX::Param(OutFile)_Building-heights.tif
   file delete -force $GenX::Param(OutFile)_Building-heights-average.tif
   file delete -force $GenX::Param(OutFile)_Building-WallOHor.tif
   file delete -force $GenX::Param(OutFile)_Building-fraction.tif
   file delete -force $GenX::Param(OutFile)_Building-Z0Town.tif
   file delete -force $GenX::Param(OutFile)_dwellings-density.tif
   file delete -force $GenX::Param(OutFile)_TEB.tif
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

   GenX::Procs CANVEC StatCan EOSD
   GenX::Log INFO "Beginning of UrbanX over $Coverage"

   variable Param
   variable Meta

   #----- Get the lat/lon and files parameters associated with the city or province
   UrbanX::AreaDefine $Coverage $Grid
   #----- Defines the extents of the zone to be process, the UTM Zone and set the initial UTMREF
   GenX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) UTMREF$Coverage
   set Param(Width) $GenX::Param(Width)
   set Param(Height) $GenX::Param(Height)

   #----- Identify CanVec files to process
   UrbanX::CANVECFindFiles

   #----- Finds CanVec files, rasterize and flattens all CanVec layers, applies buffer on some elements
   UrbanX::Sandwich $Coverage

   #----- Vector building height processing - done only if data exists over the city
   if { $Param(BuildingsShapefile)!="" } {
#      UrbanX::BuildingHeights2Raster $Coverage    ;# Rasterizes building heights
      # We ignore 3DBuildings2Sandwich until we find a way to generate TEB parameters accordingly
      #UrbanX::3DBuildings2Sandwich $Coverage       ;# Overwrites Sandwich by adding 3D buildings data
   }

   #----- Creates the fields and building vicinity output using spatial buffers
# BUG SPATIAL BUFFERS MAKE IT CRASH
#   UrbanX::ChampsBuffers $Coverage

   #----- StatCan Census data processing
   UrbanX::PopDens2Builtup $Coverage     ;# Calculates the population density
   # Next line is useless for the data we have coz dwellings are not at the DA level, see wiki
   #UrbanX::Dwellings2Builtup $Coverage    ;# Calculates dwellings density

   #----- Calculates building heights from SRTM-DEM minus CDED - UNUSED
   #UrbanX::HeightGain $Coverage
   #UrbanX::BuildingHeight $Coverage

   #------EOSD Vegetation - ignore if LCC2000V is used
   #   UrbanX::EOSDvegetation $Coverage
   #------ Process LCC2000V vegetation
   UrbanX::LCC2000V $Coverage

   #----- Applies LUT to all processing results to generate TEB classes
   UrbanX::Priorities2TEB $Coverage

   #----- Computes TEB geometric parameters over on a smaller raster, second arguement is the aggregation spatial resolution in meters
#   UrbanX::TEBGeoParams $Coverage 100

   #----- Optional vegetation mask to smooth the edges - NOT REQUIRED ANYMORE?
   #UrbanX::VegeMask

   #----- Computing TEB parameters on the FSTD target grid
   UrbanX::TEB2FSTD $Grid
   GeoPhysX::DominantVege $Grid ;# Adding DominantVG "VG IP1=0"

   #----- Deleting all UrbanX temporary files
   UrbanX::DeleteTempFiles $Coverage

   GenX::Log INFO "End of processing $Coverage with UrbanX"

# This one is too big:
# GenPhysX.tcl -urban MONTREAL -gridfile mtl_geophy_URB_548x419.std -result MONTREAL
# This one is generally ok (in terms of memory requirements)
# GenPhysX.tcl -urban MONTREAL -gridfile smaller_grid_MTL.std -result MONTREAL -verbose 3
# GenPhysX.tcl -urban MONTREAL -gridfile mtl_1grid.std -result MTL1GRIDFILE -verbose 3
}