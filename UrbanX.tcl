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

   # Liste des entités CanVec qui doivent être rasterisées.
   # Ces entités sont classés par ordre décroissant de priorité
   # Note : les entités dont le nom commence par pp_ ne sont pas des entités originant de CanVec, mais plutôt des conséquences du post-traitement. Ces éléments sont inclus dans cette liste pour que leurs valeurs de priorités apparaisent dans la variable Param(Priorities), afin de faire la correspondance avec les valeurs de TEB et de SMOKE.
   set Param(Entities) { HD_1140009_2 FO_1080069_2 SS_1320019_2 SS_1320029_2 SS_1320059_2 SS_1320039_2 BS_1370009_2 pp_BS_1370009_2 pp_BS_1370009_2 pp_BS_1370009_2 pp_BS_1370009_2 IC_1360039_2 LX_2070009_2 LX_2270009_2 LX_1000089_2 LX_2500009_2 LX_1000039_2 LX_2480009_2 LX_2200009_2 LX_2560009_2 LX_2260009_2 LX_1000019_2 LX_2490009_2 TR_1190009_2 VE_1240009_2 LX_1000049_2 LX_2510009_2 LX_2400009_2 IC_1350059_2 FO_1080059_2 LX_1000079_2 FO_1080039_2 FO_1080049_2 IC_1350039_2 IC_1350049_2 IC_1350029_2 IC_1350019_2 EN_1360049_2 IC_2360009_2 IC_2110009_2 IC_1360019_2 IC_1360029_2 EN_1360059_2 HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 pp_HD_1480009_2 SS_1320049_2 HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 pp_HD_1460009_2 HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_HD_1450009_2 pp_TR_1190009_2 FO_1080029_1 HD_1470009_1 pp_HD_1470009_1 pp_HD_1470009_1 pp_HD_1470009_1 pp_HD_1470009_1 pp_HD_1470009_1 HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 pp_HD_1460009_1 HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 pp_HD_1450009_1 BS_2310009_1 LX_1000079_1 LX_2420009_1 BS_2240009_1 pp_BS_2240009_1 LX_2280009_1 TR_1020009_1 TR_1760009_1 pp_TR_1760009_1 pp_TR_1760009_1 EN_1180009_1 LX_2460009_2 BS_2080009_2 BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_BS_2010009_2 pp_TR_1190009_2 FO_1080079_0 IC_1360039_0 LX_1000029_0 LX_2030009_0 LX_2500009_0 LX_1000039_0 LX_2480009_0 LX_2220009_0 LX_1000019_0 LX_2490009_0 LX_2400009_0 IC_1350039_0 IC_1350049_0 IC_2600009_0 pp_IC_2600009_0 EN_1360049_0 EN_1360059_0 TR_1190009_0 pp_TR_1190009_0 LX_1000069_0 IC_1360029_0 HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 pp_HD_1460009_0 HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 pp_HD_1450009_0 BS_2530009_0 BS_2440009_0 BS_2080009_0 BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 pp_BS_2010009_0 BS_2000009_0 EN_2170009_0 pp_TR_1190009_0 BS_2060009_0 pp_BS_2060009_0 pp_BS_2060009_0 pp_BS_2060009_0 pp_TR_1020009_1 pp_TR_1760009_1 }

   #LUT of priority values for the CanVec layers to be processed
   #Les valeurs de priorité sont en ordre décroissant, et leur index dans la liste correspond à celui de l'entité qui leur est associée dans Param(Entities)
   set Param(Priorities)           { 224 223 222 221 220 219 218 217 216 215 214 213 212 211 210 209 208 207 206 205 204 203 202 201 200 199 198 197 196 195 194 193 192 191 190 189 188 187 186 185 184 183 182 181 180 179 178 177 176 175 174 173 172 171 170 169 168 167 166 165 164 163 162 161 160 159 158 157 156 155 154 153 152 151 150 149 148 147 146 145 144 143 142 141 140 139 138 137 136 135 134 133 132 131 130 129 128 127 126 125 124 123 122 121 120 119 118 117 116 115 114 113 112 111 110 109 108 107 106 105 104 103 102 101 100 99 98 97 96 95 94 93 92 91 90 89 88 87 86 85 84 83 82 81 80 79 78 77 76 75 74 73 72 71 70 69 68 67 66 65 64 63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 }

   # Layers from CanVec requiring postprocessing - aucun tri particulier nécessaire pour cette liste d'entités
   set Param(LayersPostPro)    { BS_1370009_2 BS_2010009_0 BS_2010009_2 BS_2060009_0 BS_2240009_1 BS_2310009_1 EN_1180009_1 HD_1450009_0 HD_1450009_1 HD_1450009_2 HD_1460009_0 HD_1460009_1 HD_1460009_2 HD_1470009_1 HD_1480009_2 IC_2600009_0 TR_1020009_1 TR_1190009_0 TR_1190009_2 TR_1760009_1 }

   set Param(WaterLayers)      { HD_1480009_2 } ;# Water layers from CanVec

   set Param(BufferLayers)     { BS_2010009_0 TR_1760009_1 } ;# Layers from CanVec required for buffer

   # TEB Classes for CanVec. Ces valeurs sont associées aux entitées CanVec. Elles doivent être dans le même ordre que Param(Entities) et Param(Priorities), pour l'association de LUT. La source des valeurs est le fichier UrbanX-LUT.xls
   set Param(TEBClasses)         { 902 820 840 820 840 840 210 220 230 240 250 410 320 820 820 820 520 820 520 520 450 360 520 310 810 120 530 530 840 903 330 830 830 830 830 830 830 320 410 450 410 410 360 901 901 901 901 901 440 901 901 901 901 901 840 901 901 901 830 830 830 830 830 830 830 830 440 440 830 440 440 440 320 320 410 440 440 440 830 901 901 901 901 430 901 901 901 901 830 830 830 830 830 830 830 830 440 440 830 440 440 440 320 320 410 440 440 430 330 520 450 450 350 340 330 320 310 430 120 410 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 310 0 410 110 520 820 520 110 530 360 520 530 830 830 830 830 110 360 310 440 110 410 910 910 910 830 830 830 830 830 830 830 830 440 440 830 440 440 440 320 320 410 440 440 420 140 410 110 110 110 110 110 110 110 112 111 112 111 112 112 110 111 110 112 111 110 110 111 110 112 110 420 420 310 420 420 420 420 350 350 }

   # SMOKE Classes for CanVec
   # Ces valeurs sont associées aux entitées CanVec.  Elles doivent être dans le même ordre que Param(Entities) et Param(Priorities), pour l'association de LUT
   set Param(SMOKEClasses)       { 0 0 0 0 0 0 1 2 3 4 5 43 0 0 30 29 0 28 27 0 0 0 0 22 0 0 0 0 33 0 26 0 0 36 37 34 35 39 40 41 32 31 42 74 73 67 66 71 70 68 69 72 64 65 0 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 23 0 63 61 62 58 59 60 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 26 25 0 0 0 0 0 0 0 0 21 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 24 0 43 0 28 29 0 28 0 0 0 0 36 37 0 38 39 42 22 23 47 31 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 0 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 0 0 24 0 44 45 46 0 0 }

   set Param(VegeFilterType) LOWPASS
   set Param(VegeFilterSize) 99

# NOTE : les paths des fichiers suivants devront être modifiés lorsqu'il aura été décidé où ces fichiers seront localisés
   # Fichier contenant les polygones de dissemination area de StatCan, découpés selon l'index NTS 1:50000 et contenant la population ajustée aux nouveaux polygones
   # NOTE : ce fichier ne sert que dans la proc UrbanX::PopDens2Builtup.  Il n'a pas besoin de contenir les champs SMOKEi.  Toutefois, il doit être découpé selon l'index NTS 50K.
   set Param(PopFile2006SMOKE) $GenX::Path(StatCan)/SMOKE_FILLED/da2006-nts_lcc-nad83.shp
   # Pour IndustrX seulement : fichier contenant 1 polygone pour chaque province ou territoire du Canada
   set Param(ProvincesGeom) $GenX::Path(StatCan)/Provinces_lcc-nad83.shp

   # Fichier contenant l'index NTS à l'échelle 1:50000
   # Attention : s'assurer qu'il s'agit bien de l'index ayant servi au découpage du fichier PopFile2006SMOKE
   set Param(NTSFile) $GenX::Path(NTS)/decoupage50k_2.shp

   #entité CanVec déterminant la bordure des polygones NTS 50K
   set Param(NTSLayer) { LI_1210009_2 }

   # Vector 1: LCC2000 classes, vector 2: SMOKE LUT by Lucie in October 2010, vector 3: UrbanX LUT by Alex in February 2011
   # For the UrbanX LUT, values given are those of the ISBA LUT on the wiki at LCC2000-V/Classes PLUS 700
   set Const(LCC2000LUT) {
      { 0 10 11 12 20  30  31 32  33 34  35  36  37  40  50  51  52  53  80  81  82  83 100 101 102 103 104 110 121 122 123 200 210 211 212 213 220 221 222 223 230 231 232 233 }
      { 0  0  0  0  0 500   0  0 501  0 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 }
      { 0  0  0  0  0   0 702  0   0  0 724 724 724 722 726 711 711 722 723 723 723 723 713 722 714 722 722 714 715 715 715 725 704 704 704 704 707 707 707 707 725 725 725 725 } }
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
proc UrbanX::AreaDefine { Coverage } {
   variable Param

# Param(HeightFile) and Param(HeightMaskFile) will need to be removed or updated
   switch $Coverage {
      "VANCOUVER" {
         set Param(Lon1)   -122.50
         set Param(Lat1)    49.40
         set Param(Lon0)   -123.30
         set Param(Lat0)    49.01
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong_wmask
      }
      "MONTREAL" {
         set Param(Lon1)   -73.35
         set Param(Lat1)    45.70
         set Param(Lon0)   -73.98
         set Param(Lat0)    45.30
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped_wmask
      }
      "TORONTO" {
         set Param(Lon1)   -79.12
         set Param(Lat1)    43.92
         set Param(Lon0)   -79.85
         set Param(Lat0)    43.49
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "OTTAWA" {
         set Param(Lon1)   -75.56
         set Param(Lat1)    45.52
         set Param(Lon0)   -75.87
         set Param(Lat0)    45.30
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
         set Param(BuildingsShapefile)      /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott-buildings.shp
         set Param(BuildingsHgtField) hgt
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
   GenX::Log INFO "Locating CanVec Files, extent considered: lower-left = $Param(Lat0), $Param(Lon0) top-right = $Param(Lat1), $Param(Lon1)"
   GenX::Log DEBUG "Param(Entities): $Param(Entities)"
   set Param(Files) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Entities)]
   GenX::Log DEBUG "CanVec Files: $Param(Files)"
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
   GenX::Log INFO "Beginning of procedure"

   #création de la raster qui contiendra la LULC
   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef UTMREF$indexCouverture

   #----- Rasterization of CanVec layers
   foreach file $Param(Files) {
      set entity [string range [file tail $file] 11 22] ;# strip full file path to keep layer name only
      # entity contains an element of the form AA_9999999_9
      set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
      # filename contains an element of the form 999a99_9_9_AA_9999999_9
      set priority [lindex $Param(Priorities) [lsearch -exact $Param(Entities) $entity]]

      puts stderr ---------------------------....$priority.....
      # value contains the nth element of the list Param(Priorities), where n is the index of layer in the list Param(Entities)
      ogrfile open SHAPE read $file

      # The following if/else evaluates if the layer requires some post-processing prior to rasterization or if it is rasterized with the general procedure
      if { [lsearch -exact $Param(LayersPostPro) $entity] !=-1 } {

         switch $entity {
            BS_1370009_2 {
            # Residential areas
            # Lors de la procédure sandwich, l'entité prend entièrement les valeurs suivantes : PRI = 218 ; TEB = 210 ; SMO = 1
            # Lors de la procédure PopDens2Builtup, l'entité est découpée selon des seuils de densité de population
               GenX::Log DEBUG "Post-processing for Residential area, area"
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (function = $func)"
#                  ogrlayer stats FEATURES -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE function NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (function = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE function NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }
            }
            BS_2310009_1 {
               #entity : Pipeline (Sewage / liquid waste), line
               GenX::Log DEBUG "Post-processing for Pipelines (sewage / liquid waste), lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (aboveground sewage pipeline entity) as FEATURES with priority value $priority"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
            }
            EN_1180009_1 {
               #entity : Pipeline, line
               GenX::Log DEBUG "Post-processing for Pipelines, lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = 1)"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (definition = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE definition NOT IN ([join $funcs ,])"
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
                  ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (definition = $func)"
                  GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity ($type) as FEATURES with priority value $val"
                  gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $val
               }

               # else
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE definition NOT IN ([join $funcs ,])"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general) as FEATURES with priority value 181"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 181
            }
            IC_2600009_0 {
               # entity : Mining area, point
               GenX::Log DEBUG "Post-processing for Mining area, point"
               #status = 1 : mines opérationnelles
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (status = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (operational mines) as FEATURES with priority value 65"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 65
               #status != 1 : mines non opérationnelles
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (status != 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (non operational mines) as FEATURES with priority value 66"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 66
            }
            TR_1020009_1 {
               # entity : Railway, line
               GenX::Log DEBUG "Post-processing for Railway, line"
               #support = 3 : bridge
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (support = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge railway) as FEATURES with priority value 2"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 2
               #support != 3 ou 4 : not bridge, not tunnel
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE support NOT IN (3,4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge railway) as FEATURES with priority value 111"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 111
            }
            TR_1190009_0 {
               # entity : Runway, point
               GenX::Log DEBUG "Post-processing for Runway, point"
               #type = 1 : airport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = 1 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (airport runway) as FEATURES with priority value 62"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 62
               #type = 2 ou 3 : heliport, hospital heliport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type IN (2,3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (heliport or hospital heliport runway) as FEATURES with priority value 7"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 7
               #type = 4 : water aerodrome
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = 4 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (water aerodrome runway) as FEATURES with priority value 61"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 61
            }
            TR_1190009_2 {
               # entity : Runway, area
               GenX::Log DEBUG "Post-processing for Runway, areas"
               #type = 1 : airport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = 1 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (airport runway) as FEATURES with priority value 201"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 201
               #type = 2 ou 3 : heliport, hospital heliport
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE type IN (2,3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (heliport or hospital heliport runway) as FEATURES with priority value 80"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 80
               #type = 4 : water aerodrome
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (type = 4 )"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (water aerodrome runway) as FEATURES with priority value 147"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 147
            }
            TR_1760009_1 {
               # entity : Road segment [Geobase], line
               GenX::Log DEBUG "Post-processing for Road segment, lines"

               #exclusions des structype 5 (tunnel) et 6 (snowshed), association de la valeur générale à tout le reste des routes pavées
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (pavstatus != 2) AND structype NOT IN (5,6)"
#               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (general road segments) as FEATURES with priority value 109"
#               GenX::Log INFO "Buffering general road segments to 12m"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 109

               #pavstatus = 2 : unpaved : routes non pavées n'étant pas des tunnels ou des snowsheds
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE (pavstatus = 2) AND structype NOT IN (5,6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (unpaved road segments) as FEATURES with priority value 110"
               #pas de buffer sur les routes non pavées
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 110

               #roadclass in (1,2) : freeway, expressway/highway n'étant pas des tunnels ou des snowsheds
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE roadclass in (1,2) AND structype NOT IN (5,6)"
#               ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (highways road segments) as FEATURES with priority value 108"
#               GenX::Log INFO "Buffering highway road segments to 22m"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 108

              #structype in (1,2,3,4) : bridge (tous les types de ponts)
               ogrlayer sqlselect FEATURES SHAPE "SELECT * FROM $filename WHERE structype IN (1,2,3,4)"
#               ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
               GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from layer $entity (bridge road segments) as FEATURES with priority value 1"
#               GenX::Log INFO "Buffering bridge road segments to 22m"
               gdalband gridinterp RSANDWICH FEATURES $Param(Mode) 1
            }
            default {
               #the layer is part of Param(LayersPostPro) but no case has been defined for it
               GenX::Log WARNING "Post-processing for $file not found.  The layer was not rasterized."
            }
         }
      } else {

         #general procedure for rasterization: entities that are not part of Param(LayersPostPro)
         eval ogrlayer read FEATURES SHAPE 0
         GenX::Log DEBUG "Rasterizing [ogrlayer define FEATURES -nb] features from file $file as FEATURES with priority value $priority, general procedure"
         gdalband gridinterp RSANDWICH FEATURES $Param(Mode) $priority
      }

      ogrlayer free FEATURES
      ogrfile close SHAPE
   }

   #creating the output file
   file delete -force $GenX::Param(OutFile)_sandwich_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich_$indexCouverture.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   gdalfile close FILEOUT
   gdalband free RSANDWICH

   GenX::Log INFO "The file $GenX::Param(OutFile)_sandwich_$indexCouverture.tif was generated"
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
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]

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
            ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM $filename WHERE function NOT IN (3,4,14,36) "
# Bug in spatial buffers
#            ogrlayer stats LAYER$i -buffer 0.000224982 8
            }
            BS_2010009_2 {
            GenX::Log DEBUG "Buffering 2D buildings"
            set priority 667 ;# VALUE TO UPDATE
# need updating this sqlselect
            ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM $filename WHERE function NOT IN (3,4,14,36) "
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
   #gdalband write RBUFFER FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   #gdalfile close FILEOUT

   file delete -force $GenX::Param(OutFile)_champs-only+building-vicinity_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_champs-only+building-vicinity_$indexCouverture.tif GeoTiff
   gdalband write RBUFFERCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

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
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::PopDens2Builtup { indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log DEBUG "Beginning of procedure: PopDens2BuiltupCanVec"
   variable Param

   #récupération de genphysx_sandwich.tif
   GenX::Log DEBUG "Reading Sandwich file"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]

   #récupération du fichier de données socio-économiques
   GenX::Log DEBUG "Open and read the Canada-wide dissemination area polygons file."
   set layer [lindex [ogrfile open SHAPE read $Param(PopFile2006SMOKE)] 0]
   eval ogrlayer read VPOPDENS $layer

   #----- Selecting only the required StatCan polygons - next is only useful to improve the speed of the layer substraction
   GenX::Log DEBUG "Select the appropriate dissemination area polygons."
   set da_select [ogrlayer pick VPOPDENS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   ogrlayer define VPOPDENS -featureselect [list [list index # $da_select]]

   #   clear la colonne POP_DENS pour les polygones de DA sélectionnés
   ogrlayer clear VPOPDENS POP_DENS

   #création d'un fichier de rasterization des polygones de DA
   gdalband create RDA $Param(Width) $Param(Height) 1 Int32
   gdalband clear RDA -1
   gdalband define RDA -georef UTMREF$indexCouverture

   #rasterization des polygones de DA
   GenX::Log DEBUG "Rasterize the selected dissemination area polygons."
   gdalband gridinterp RDA VPOPDENS FAST FEATURE_ID

   #comptage des pixels de la residential area pour chaque polygone de DA : increment de la table et buildings generals (ponctuels et surfaciques)
   GenX::Log DEBUG "Counting pixels for residential areas and general function buildings for each dissemination area polygon."
   vexpr VPOPDENS.POP_DENS tcount(VPOPDENS.POP_DENS,ifelse (RSANDWICH==218 || RSANDWICH==104 || RSANDWICH==33,RDA,-1))

   #Calcul de la densité de population
   GenX::Log INFO "Calculating population density values and adjustments if required"
   foreach n $da_select {
      #récupération de la valeur de population
      set pop [ogrlayer define VPOPDENS -feature $n POP_NEW]
      #calcul de l'aire de la residential area à l'aide du nombre de pixels comptés précédemment
      set nbrpixels [ogrlayer define VPOPDENS -feature $n POP_DENS]
      set area_pixels [expr ($nbrpixels*25.0/1000000.0)] ;#nbr de pixels * (5m*5m) de résolution / 1000000 m² par km² = area en km²
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
      ogrlayer define VPOPDENS -feature $n POP_DENS $densite_choisie
   }

   unset da_select

   #Conversion de la densité de population en raster
   GenX::Log DEBUG "Conversion of population density in a raster file."
   gdalband create RPOPDENS $Param(Width) $Param(Height) 1 Float32
   eval gdalband define RPOPDENS -georef UTMREF$indexCouverture
   gdalband gridinterp RPOPDENS VPOPDENS $Param(Mode) POP_DENS

   #écriture du fichier genphysx_popdens.tif contenant la densité de population
   file delete -force $GenX::Param(OutFile)_popdens_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens_$indexCouverture.tif GeoTiff
   gdalband write RPOPDENS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_popdens_$indexCouverture.tif was generated"

   #nettoyage de mémoire
   gdalfile close FILEOUT
   ogrlayer free VPOPDENS
   ogrfile close SHAPE
   gdalband free RDA

   #Cookie cutting population density and setting SMOKE/TEB values
   GenX::Log INFO "Cookie cutting population density and setting SMOKE/TEB values"
   gdalband create RPOPDENSCUT $Param(Width) $Param(Height) 1 Byte
   gdalband define RPOPDENSCUT -georef UTMREF$indexCouverture
   vexpr RTEMP RSANDWICH==218

   if {$GenX::Param(SMOKE)!="" } {
      #seuils de densité de population associés à SMOKE (IndustrX)
      GenX::Log INFO "Applying thresholds for IndustrX"
      vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<100),1,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=100 && RPOPDENS<1000)),2,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=1000 && RPOPDENS<4000),3,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=4000),4,RPOPDENSCUT)
   } else {
      #seuils de densité de population associés à TEB (UrbanX)
      GenX::Log INFO "Applying thresholds for UrbanX"
      vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<2000),210,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=2000 && RPOPDENS<5000)),220,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=5000 && RPOPDENS<15000),230,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=15000 && RPOPDENS<25000),240,RPOPDENSCUT)
      vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=25000),250,RPOPDENSCUT)
   }

   #écriture du fichier genphysx_popdens-builtup.tif
   GenX::Log DEBUG "Generating output file, result of cookie cutting"
   file delete -force $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif GeoTiff
   gdalband write RPOPDENSCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif was generated"

   gdalfile close FSANDWICH FILEOUT
   gdalband free RSANDWICH RPOPDENS RTEMP RPOPDENSCUT
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

   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity_$indexCouverture.tif]
   gdalband create RHAUTEURPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURPROJ -georef UTMREF$indexCouverture
   gdalband stats RHAUTEURPROJ -nodata -9999

   #----- La vérification pourrait être fait dans un proc avec vérification des 4 points de la source
   gdalband read RHAUTEUR [gdalfile open FHAUTEUR read $Param(HeightFile)]
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

   file delete -force $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif GeoTiff
   gdalband write RHEIGHTCHAMPS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif was generated"

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
proc UrbanX::BuildingHeight {indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Cookie cutting building heights and adding gain"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]
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
#   gdalband write RHAUTEURCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
#   gdalfile close FILEOUT
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif GeoTiff
   gdalband write RHAUTEURCLASS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif was generated"

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
proc UrbanX::EOSDvegetation {indexCouverture } {
# THIS PROC COULD PROBABLY BE DELETED - NOT USED BY SMOKE OR TEB
   variable Param
   variable Const
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log INFO "Beginning of procedure"

   #lecture du fichier créé précédemment lors de la proc SandwichCanVec
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]

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
   file delete -force $GenX::Param(OutFile)_EOSDVegetation_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_EOSDVegetation_$indexCouverture.tif GeoTiff
   gdalband write RVEGE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDVegetation_$indexCouverture.tif was generated"

   #affectation des valeurs SMOKE
   GenX::Log INFO "Converting EOSD classes into SMOKE/TEB values"
   gdalband create RVEGESMOKE $Param(Width) $Param(Height) 1 Byte
   gdalband define RVEGESMOKE -georef UTMREF$indexCouverture

   vector create FROMEOSD [lindex $Const(EOSD2SMOKE) 0]
   vector create TOSMOKE  [lindex $Const(EOSD2SMOKE) 1]
   vexpr RVEGE ifelse((RSANDWICH==0 || RSANDWICH==200),lut(RVEGE,FROMEOSD,TOSMOKE),RVEGE)
   vector free FROMEOSD TOSMOKE

   #écriture du fichier
   file delete -force $GenX::Param(OutFile)_EOSDSMOKE_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_EOSDSMOKE_$indexCouverture.tif GeoTiff
   gdalband write RVEGESMOKE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDSMOKE_$indexCouverture.tif was generated"

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
   GenX::Log INFO "Beginning of procedure"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]
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

   file delete -force $GenX::Param(OutFile)_LCC2000V-LUT_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_LCC2000V-LUT_$indexCouverture.tif GeoTiff
   gdalband write RLCC2000VSMOKE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_LCC2000V-LUT_$indexCouverture.tif was generated"
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

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif]
   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity_$indexCouverture.tif]
   gdalband read RLCC2000V [gdalfile open FLCC2000V read $GenX::Param(OutFile)_LCC2000V-LUT_$indexCouverture.tif]
   gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Priorities)
   vector set LUT.TO $Param(TEBClasses)
   vexpr RTEB lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   vexpr RTEB ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RTEB)
   vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
#   vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RTEB)
# 3D buildings output is missing...
   vexpr RTEB ifelse((RLCC2000V!=0 && (RTEB==0 || RTEB==810 || RTEB==820 || RTEB==840)),RLCC2000V,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB_$indexCouverture.tif GeoTiff
   gdalband write RTEB FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_TEB_$indexCouverture.tif was generated"

   gdalfile close FILEOUT FSANDWICH FPOPDENSCUT FCHAMPS FHAUTEURCLASS FLCC2000V
   gdalband free RTEB RSANDWICH RPOPDENSCUT RCHAMPS RHAUTEURCLASS RLCC2000V
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::VegeMask>
# Creation : date? - Alexandre Leroux - CMC/CMOE
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
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param
   GenX::Log INFO "Generating vegetation mask"

   gdalband read RTEB [gdalfile open FTEB read $GenX::Param(OutFile)_TEB_$indexCouverture.tif]

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
      gdalband write VEGEMASK FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
      gdalfile close FILEOUT
   } else {
      GenX::Log INFO "Using previously computed filtered data $fileRTEBfilter"
      gdalband read VEGEMASK [gdalfile open FVEGEMASK read ./$fileRTEBfilter]
   }

   #----- Seuil sur le filtre et rajout des non-nature et de l'eau
   vexpr RTEBWMASK ifelse((VEGEMASK>85 && RTEB>800 && RTEB!=901),0,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB-wVegeMask.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB-wVegeMask.tif GeoTiff
   gdalband write RTEBWMASK FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   gdalfile close FILEOUT
   gdalband free RTEBWMASK VEGEMASK
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::CreateFSTDBand>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#   <Name>   :
#   <Band>   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::CreateFSTDBand { Name Band } {
   GenX::Procs ;# Adding the proc to the metadata log

   set NI [gdalband configure $Band -width]  ; # Number of X-grid points.
   set NJ [gdalband configure $Band -height] ; # Number of Y-grid points.
   set NK 1                                  ; # Number of Z-grid points.

   #----- Create and define tictic and tactac grid coordinates.
   fstdfield create TIC $NI 1 1
   fstdfield create TAC 1 $NJ 1
   fstdfield define TIC -GRTYP L 0 0 1.0 1.0
   fstdfield define TAC -GRTYP L 0 0 1.0 1.0
   fstdfield define TIC -DEET 0 -NPAS 0 -IP1 0 -IP2 0 -IP3 0 -ETIKET $Name -NOMVAR ">>"  -TYPVAR X
   fstdfield define TAC -DEET 0 -NPAS 0 -IP1 0 -IP2 0 -IP3 0 -ETIKET $Name -NOMVAR "^^"  -TYPVAR X
   fstdfield configure TIC -interpdegree NEAREST
   fstdfield configure TAC -interpdegree NEAREST

   #----- Compute tictic grid coordinates.
   for { set i 0 } { $i < $NI } { incr i } {
      set ll [gdalband stats $Band -gridpoint $i 0]
      set lon [lindex $ll 1]
      set lon [expr $lon<0?$lon+360:$lon]
      fstdfield stats TIC -gridvalue $i 0 $lon
   }

   #----- Compute tactac grid coordinates.
   for { set j 0 } { $j< $NJ } { incr j } {
      set ll [gdalband stats $Band -gridpoint 0 $j ]
      fstdfield stats TAC -gridvalue 0 $j [lindex $ll 0]
   }

   fstdfield create $Name $NI $NJ $NK Int32
   fstdfield define $Name -DEET 0 -NPAS 0 -IP1 0 -IP2 0 -IP3 0 -ETIKET $Name -NOMVAR GRID -TYPVAR X -IG1 0 -IG2 0 -IG3 0 -IG4 0 -GRTYP Z
   fstdfield define $Name -positional TIC TAC
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::TEB2FSTD>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#
# Return:
#
# Remarks : Can't work with files over 128 MEGS (e.g. MTL, VAN, TOR)
#
#----------------------------------------------------------------------------
proc UrbanX::TEB2FSTD { } {
   GenX::Procs ;# Adding the proc to the metadata log
   GenX::Log INFO "Converting TEB raster to RPN"

   gdalband read BAND [gdalfile open FILE read $GenX::Param(OutFile)_TEB_$indexCouverture.tif]

   UrbanX::CreateFSTDBand GRID BAND

   file delete -force $GenX::Param(OutFile)_TEB.fstd
   fstdfile open 1 write $GenX::Param(OutFile)_TEB.fstd

   fstdfield gridinterp GRID BAND
   fstdfield define GRID -NOMVAR UG
   fstdfield write TIC 1 -32 True
   fstdfield write TAC 1 -32 True
   fstdfield write GRID 1 -16 True $GenX::Param(Compress)

   fstdfile close 1
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Shp2Height>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Shp2Height { indexCouverture } {
   GenX::Procs ;# Adding the proc to the metadata log
   variable Param

   if { $Param(BuildingsShapefile)=="" } {
      return
   }
   GenX::Log INFO "Converting $GenX::Param(Urban) building shapefile to raster"

   gdalband create RHAUTEURSHP $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURSHP -georef UTMREF$indexCouverture

   set shp_layer [lindex [ogrfile open SHAPE read $Param(BuildingsShapefile)] 0]
   eval ogrlayer read LAYER $shp_layer
   gdalband gridinterp RHAUTEURSHP LAYER $Param(Mode) $Param(BuildingsHgtField)

   ogrlayer free LAYER
   ogrfile close SHAPE

   file delete -force $GenX::Param(OutFile)_shp-height_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_shp-height_$indexCouverture.tif GeoTiff
   gdalband write RHAUTEURSHP FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   gdalfile close FILEOUT
   gdalband free RHAUTEURSHP
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
proc UrbanX::DeleteTempFiles {indexCouverture} {
   GenX::Log INFO "Deleting all temporary files"

   file delete -force $GenX::Param(OutFile)_LCC2000V-LUT_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_EOSDSMOKE_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_EOSDVegetation_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_popdens_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_champs-only+building-vicinity_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_sandwich_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_shp-height_$indexCouverture.tif
   file delete -force $GenX::Param(OutFile)_hauteur-classes_$indexCouverture.tif
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
proc UrbanX::Process { Coverage } {

   GenX::Procs CANVEC StatCan EOSD
   GenX::Log INFO "Beginning of UrbanX"

   variable Param
   variable Meta

   # pour employer un utilitaire, retirer le # des deux lignes suivantes et aller retirer les # associés à l'utilitaire choisi dans la proc UrbanX::Utilitaires
   # UrbanX::Utilitaires
   # return

   GenX::Log INFO "Coverage = $Coverage"

   #----- Get the lat/lon and files parameters associated with the city or province
   UrbanX::AreaDefine    $Coverage
   #----- Defines the extents of the zone to be process, the UTM Zone and set the initial UTMREF
   GenX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) UTMREF$Coverage
   set UrbanX::Param(Width) $GenX::Param(Width)
   set UrbanX::Param(Height) $GenX::Param(Height)

   #----- Identify CanVec files to process
   UrbanX::CANVECFindFiles

   #----- Finds CanVec files, rasterize and flattens all CanVec layers, applies buffer on some elements
   UrbanX::Sandwich $Coverage

   #-----La rasterization des hauteurs n'a pas vraiment sa place dans UrbanX... C'est one-shot.
   UrbanX::Shp2Height $Coverage

   #----- Creates the fields and building vicinity output using spatial buffers
# BUG SPATIAL BUFFERS MAKE IT CRASH
   UrbanX::ChampsBuffers $Coverage

   #----- Calculates the population density
   UrbanX::PopDens2Builtup $Coverage

   #----- Calculates building heights
   UrbanX::HeightGain $Coverage
   UrbanX::BuildingHeight $Coverage

   #------EOSD Vegetation - ignore if LCC2000V is used
   #   UrbanX::EOSDvegetation $Coverage
   #------ Process LCC2000V vegetation
   UrbanX::LCC2000V $Coverage

   #----- Applies LUT to all processing results to generate TEB classes
   UrbanX::Priorities2TEB $Coverage

   #----- Optional outputs:
   #UrbanX::VegeMask
   #UrbanX::TEB2FSTD

#   UrbanX::DeleteTempFiles $Coverage

   GenX::Log INFO "End of processing $Coverage with UrbanX"
}