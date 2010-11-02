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

   set Param(Version_UrbanX)   0.2
   set Param(Version_IndustrX)   0.1

   set Param(Resolution) 5       ;# Spatial rez of rasterization and outputs, leave at 5m unless for testing purposes
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
   set Param(Shape)          ""
   set Param(ShapeField)     ""

	#Liste des entités CanVec qui doivent être rasterisées.
   #Ces entités sont classés par ordre décroissant de priorité
   #Note : les entités dont le nom commence par pp_ ne sont pas des entités originant de CanVec, mais plutôt des conséquences du post-traitement.
   #Ces éléments sont inclus dans cette liste pour que leurs valeurs de priorités apparaisent dans la variable Param(Priorities), afin de faire la
   #correspondance avec les valeurs de TEB et de SMOKE.
	set Param(Entities) {
		HD_1140009_2
		FO_1080069_2
		SS_1320019_2
		SS_1320029_2
		SS_1320059_2
		SS_1320039_2
		BS_1370009_2
		pp_BS_1370009_2
		pp_BS_1370009_2
		pp_BS_1370009_2
		pp_BS_1370009_2
		IC_1360039_2
		LX_2070009_2
		LX_2270009_2
		LX_1000089_2
		LX_2500009_2
		LX_1000039_2
		LX_2480009_2
		LX_2200009_2
		LX_2560009_2
		LX_2260009_2
		LX_1000019_2
		LX_2490009_2
		TR_1190009_2
		VE_1240009_2
		LX_1000049_2
		LX_2510009_2
		LX_2400009_2
		IC_1350059_2
		FO_1080059_2
		LX_1000079_2
		FO_1080039_2
		FO_1080049_2
		IC_1350039_2
		IC_1350049_2
		IC_1350029_2
		IC_1350019_2
		EN_1360049_2
		IC_2360009_2
		IC_2110009_2
		IC_1360019_2
		IC_1360029_2
		EN_1360059_2
		HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		pp_HD_1480009_2
		SS_1320049_2
		HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		pp_HD_1460009_2
		HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_HD_1450009_2
		pp_TR_1190009_2
		FO_1080029_1
		HD_1470009_1
		pp_HD_1470009_1
		pp_HD_1470009_1
		pp_HD_1470009_1
		pp_HD_1470009_1
		pp_HD_1470009_1
		HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		pp_HD_1460009_1
		HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		pp_HD_1450009_1
		BS_2310009_1
		LX_1000079_1
		LX_2420009_1
		BS_2240009_1
		pp_BS_2240009_1
		LX_2280009_1
		TR_1020009_1
		TR_1760009_1
		pp_TR_1760009_1
		pp_TR_1760009_1
		EN_1180009_1
		LX_2460009_2
		BS_2080009_2
		BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_BS_2010009_2
		pp_TR_1190009_2
		FO_1080079_0
		IC_1360039_0
		LX_1000029_0
		LX_2030009_0
		LX_2500009_0
		LX_1000039_0
		LX_2480009_0
		LX_2220009_0
		LX_1000019_0
		LX_2490009_0
		LX_2400009_0
		IC_1350039_0
		IC_1350049_0
		IC_2600009_0
		pp_IC_2600009_0
		EN_1360049_0
		EN_1360059_0
		TR_1190009_0
		pp_TR_1190009_0
		LX_1000069_0
		IC_1360029_0
		HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		pp_HD_1460009_0
		HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		pp_HD_1450009_0
		BS_2530009_0
		BS_2440009_0
		BS_2080009_0
		BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		pp_BS_2010009_0
		BS_2000009_0
		EN_2170009_0
		pp_TR_1190009_0
		BS_2060009_0
		pp_BS_2060009_0
		pp_BS_2060009_0
		pp_BS_2060009_0
		pp_TR_1020009_1
		pp_TR_1760009_1
		}

	#LUT of priority values for the CanVec layers to be processed
	#Les valeurs de priorité sont en ordre décroissant, et leur index dans la liste correspond à celui de l'entité qui leur est associée dans Param(Entities)
	set Param(Priorities)           { 224 223 222 221 220 219 218 217 216 215 214 213 212 211 210 209 208 207 206 205 204 203 202 201 200 199 198 197 196 195 194 193 192 191 190 189 188 187 186 185 184 183 182 181 180 179 178 177 176 175 174 173 172 171 170 169 168 167 166 165 164 163 162 161 160 159 158 157 156 155 154 153 152 151 150 149 148 147 146 145 144 143 142 141 140 139 138 137 136 135 134 133 132 131 130 129 128 127 126 125 124 123 122 121 120 119 118 117 116 115 114 113 112 111 110 109 108 107 106 105 104 103 102 101 100 99 98 97 96 95 94 93 92 91 90 89 88 87 86 85 84 83 82 81 80 79 78 77 76 75 74 73 72 71 70 69 68 67 66 65 64 63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 }

	# Layers from CanVec requiring postprocessing
   #Aucun tri particulier nécessaire pour cette liste d'entités
	set Param(LayersPostPro)    {
		BS_1370009_2
		BS_2010009_0
		BS_2010009_2
		BS_2060009_0
		BS_2240009_1
		BS_2310009_1
		EN_1180009_1
		HD_1450009_0
		HD_1450009_1
		HD_1450009_2
		HD_1460009_0
		HD_1460009_1
		HD_1460009_2
		HD_1470009_1
		HD_1480009_2
		IC_2600009_0
		TR_1020009_1
		TR_1190009_0
		TR_1190009_2
		TR_1760009_1 }

   set Param(WaterLayers)      { HD_1480009_2 } ;# Water layers from CanVec

   set Param(BufferLayers)     { BS_2010009_0 TR_1760009_1 } ;# Layers from CanVec required for buffer

	set Param(BufferFuncLayers) { BS_2010009_0 BS_2010009_2 } ;# Layers from CanVec required for buffer func

   set Param(BufferFuncValues) { 1 2 } ;#what's that?

	#TEB Classes for CanVec
	#Ces valeurs sont associées aux entitées CanVec.  Elles doivent être dans le même ordre que Param(Entities) et Param(Priorities), pour l'association de LUT
	set Param(TEBClasses)         {902 820 840 820 840 840 210 220 230 240 250 410 320 820 820 820 520 820 520 520 450 360 520 310 810 120 530 530 840 903 330 830 830 830 830 830 830 320 410 450 410 410 360 901 901 901 901 901 440 901 901 901 901 901 840 901 901 901 830 830 830 830 830 830 830 830 440 440 830 440 440 440 320 320 410 440 440 440 830 901 901 901 901 430 901 901 901 901 830 830 830 830 830 830 830 830 440 440 830 440 440 440 320 320 410 440 440 430 330 520 450 450 350 340 330 320 310 430 120 410 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 100 310 0 410 110 520 820 520 110 530 360 520 530 830 830 830 830 110 360 310 440 110 410 910 910 910 830 830 830 830 830 830 830 830 440 440 830 440 440 440 320 320 410 440 440 420 140 410 110 110 110 110 110 110 110 112 111 112 111 112 112 110 111 110 112 111 110 110 111 110 112 110 420 420 310 420 420 420 420 350 350   } 

   #------TO DELETE : LAYERS BNDT------------------
	#set Param(WaterLayers)      { water_b_a n_canal_a fish_po_a } ;# Water layers from BNDT
	#set Param(BufferLayers)     { bridge_l buildin_p road_l } ;# Layers from BNDT required for buffer
   #set Param(BufferFuncLayers) { } ;# Layers from CanVec required for buffer func
   #set Param(TEBClasses)         { 902 830 830 830 410 440 903 520 520 520 520 820 450 820 820 820 840 820 830 120 530 530 320 410 450 410 320 901 830 360 810 840 440 901 360 410 120 310 440 830 830 450 901 200 901 830 450 430 440 420 430 430 340 100 100 120 320 440 320 320 330 330 410 901 420 110 440 520 420 420 330 330 310 320 350 360 440 830 901 440 320 110 830 530 360 110 420 530 140 110 520 520 110 520 410 110 360 440 330 310 420 420 112 111 110 }  ;# TEB classes for BNDT
   #------FIN DU : TO DELETE---------

	#SMOKE Classes for CanVec
	#Ces valeurs sont associées aux entitées CanVec.  Elles doivent être dans le même ordre que Param(Entities) et Param(Priorities), pour l'association de LUT
	set Param(SMOKEClasses)       { 0 0 0 0 0 0 1 2 3 4 5 43 0 0 30 29 0 28 27 0 0 0 0 22 0 0 0 0 33 0 26 0 0 36 37 34 35 39 40 41 32 31 42 74 73 67 66 71 70 68 69 72 64 65 0 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 23 0 63 61 62 58 59 60 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 26 25 0 0 0 0 0 0 0 0 21 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 24 0 43 0 28 29 0 28 0 0 0 0 36 37 0 38 39 42 22 23 47 31 0 0 0 0 0 0 0 0 0 0 0 57 51 52 51 48 49 50 54 56 55 53 0 0 0 6 16 7 19 19 16 19 8 9 19 10 11 12 19 13 19 19 14 15 16 17 18 19 20 0 0 24 0 44 45 46 0 0 }

   set Param(VegeFilterType) LOWPASS
   set Param(VegeFilterSize) 99

   #fichier contenant les polygones de dissemination area de StatCan, découpés selon l'index NTS 1:50000 et contenant la population ajustée aux nouveaux polygones
	set Param(PopFile2006SMOKE) /data/aqli04/afsulub/StatCan2006/SMOKE_FILLED/da2006-nts_lcc-nad83.shp

   #fichier contenanant 1 polygone pour chaque province ou territoire du Canada
   set Param(ProvincesGeom) /data/aqli04/afsulub/StatCan2006/Provinces_lcc-nad83.shp

   #fichier contenant l'index NTS à l'échelle 1:50000
   set Param(NTSFile) /cnfs/ops/production/cmoe/geo/NTS/decoupage50k_2.shp

	#entité CanVec déterminant la bordure des polygones NTS50K
	set Param(NTSLayer) {LI_1210009_2 }

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::AreaDefine>
# Creation : June 2006 - Alexandre Leroux - CMC/CMOE
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
         set Param(Shape)      /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott-buildings.shp
         set Param(ShapeField) hgt
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
      default {
         set Param(Lon1)   -71.10
         set Param(Lat1)    46.94
         set Param(Lon0)   -71.47
         set Param(Lat0)    46.68
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
   }
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::UTMZoneDefine>
# Creation : date? - Alexandre Leroux - CMC/CMOE
# Revision : October 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : define the UTM Zone
#
# Parameters :
#   <Lat0>    : Lower left latitude
#   <Lon0>    : Lower left longitude
#   <Lat1>    : Top right latitude
#   <Lon1>    : Top right longitude
#   <Res 5>   : Spatial resolution of rasterization and outputs, leave at 5m unless for testing purposes
#		<indexCouverture>		: index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::UTMZoneDefine { Lat0 Lon0 Lat1 Lon1 { Res 5 } indexCouverture } {
   variable Param

   set zone     [expr int(ceil((180 + (($Lon1 + $Lon0)/2))/6))]
   set meridian [expr -((180-($zone*6))+3)]

		eval georef create UTMREF$indexCouverture \
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

   set xy1 [georef unproject UTMREF$indexCouverture $Lat1 $Lon1]
   set xy0 [georef unproject UTMREF$indexCouverture $Lat0 $Lon0]

   set Param(Width)  [expr int(ceil(([lindex $xy1 0] - [lindex $xy0 0])/$Res))]
   set Param(Height) [expr int(ceil(([lindex $xy1 1] - [lindex $xy0 1])/$Res))]

	georef define UTMREF$indexCouverture -transform [list [lindex $xy0 0] $Res 0.000000000000000 [lindex $xy0 1] 0.000000000000000 $Res]

   GenX::Log INFO "UTM zone is $zone, with central meridian at $meridian. Dimension are $Param(Width)x$Param(Height)"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FindNTSSheets>
# Creation : date? - Alexandre Leroux - CMC/CMOE
# Revision : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Find the NTS Sheets that intersect the province polygon
#
# Parameters :
#		<indexCouverture>		: index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::FindNTSSheets {indexCouverture } {

	GenX::Log INFO "Debut de la proc FindNTSSheetsCanVec"

   variable Param

   #ouverture du shapefile index NTS50K
   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $Param(NTSFile)] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }
	GenX::Log DEBUG "On compte [ogrlayer define NTSLAYER50K -nb] tuiles NTS dans le fichier NTS50K"

   #ouverture du shapefile du Canada
   set prov_layer [lindex [ogrfile open SHAPECANADA read $Param(ProvincesGeom)] 0]
   eval ogrlayer read VCANADA $prov_layer
   ogrlayer stats VCANADA -transform UTMREF$indexCouverture
   GenX::Log DEBUG "On compte [ogrlayer define VCANADA -nb] polygones dans le fichier de géométrie canadienne"

	#index de la géométrie de province
	set idxprovince [ogrlayer define VCANADA -featureselect [list [list PR == $Param(ProvinceCode) ] ] ]

	#sélection de la géométrie pour la province sélectionnée
	set geom [ogrlayer define VCANADA -geometry $idxprovince]

	#conversion de NTSLAYER50K en UTMREF.
   ogrlayer stats NTSLAYER50K -transform UTMREF$indexCouverture

	#Présélection des tuiles NTS à l'aide d'un convexhull
	set hull [ogrgeometry stat $geom -convexhull]
	set ntssheets_pre [ogrlayer pick NTSLAYER50K $hull True]

	#ramener NTSLAYER50K à la sélection des fichiers présélectionnés
	ogrlayer define NTSLAYER50K -featureselect [list [list index # $ntssheets_pre]]
	GenX::Log DEBUG "Les [llength $ntssheets_pre] tuiles NTS ayant les ID suivants ont été présélectionnées à l'aide du convex hull : $ntssheets_pre"

	#avertissement sur le temps requis...  
	GenX::Log INFO "Intersection des fichiers NTS présélectionnés avec le polygone de province.  Cette opération peut prendre plusieurs minutes!"

	#sélection, parmi les fichiers NTS présélectionnés, de ceux qui sont en intersection avec la géométrie provinciale
   set Param(NTSIds) [ogrlayer pick NTSLAYER50K $geom True INTERSECT]
   GenX::Log DEBUG "Les [llength $Param(NTSIds)] tuiles NTS ayant les ID suivants sont conservées suite à l'intersection avec la géométrie : $Param(NTSIds)"

	#remplacement des ids des tuiles par le no de feuillet NTS, de format 999A99
	set Param(NTSSheets) { }
   foreach id $Param(NTSIds) {
      set Param(NTSSheets)  [concat $Param(NTSSheets) [ogrlayer define NTSLAYER50K -feature $id IDENTIFIAN] ]
	}
   GenX::Log DEBUG "Les [llength $Param(NTSSheets)] tuiles NTS ayant les no de feuillets suivants sont conservées : $Param(NTSSheets)"

	#nettoyage de mémoire
	ogrfile close SHAPE50K SHAPECANADA
	ogrlayer free NTSLAYER50K VCANADA

	GenX::Log INFO "Fin de la proc FindNTSSheetsCanVec"

return

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::NTSExtent>
# Creation : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :  Finds the extent (lat lon) of one NTS Sheet
#						Finds the extent (xy in UTM) of one NTS Sheets
#						Reset the UTMREF with the appropriate index
#
# Parameters : NTSid : identifiant d'une tuile NTS50K
#   <indexCouverture>    :  index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::NTSExtent { indexCouverture } {

	GenX::Log INFO "Debut de la proc NTSExtent"

   variable Param

   #ouverture du shapefile index NTS50K
   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $Param(NTSFile)] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }

	#NOTE : ON NE TRANSFORME PAS NTSLAYER50K EN UTMREF CAR ON VEUT DES LAT/LON

	#sélection de la tuile NTS correspondant à l'ID passé en input
	set ntsid [lindex $Param(NTSIds) [lsearch -exact $Param(NTSSheets) $indexCouverture ]]
	ogrlayer define NTSLAYER50K -featureselect [list [list index # $ntsid]]

	#trouve les limites lat/lon de la tuile NTS sélectionnée
	set latlon [ogrlayer stats NTSLAYER50K -extent True]

	#affecte les valeurs latlon aux divers paramètres Lon0, Lon1, Lat0, Lat1, avec une marge
	set Param(Lon0) [expr [lindex $latlon 0] + 0.01]
	set Param(Lat0) [expr [lindex $latlon 1] + 0.01]
	set Param(Lon1) [expr [lindex $latlon 2] - 0.01]
	set Param(Lat1) [expr [lindex $latlon 3] - 0.01]

	#recherche du fichier CanVec correspondant au layer NTS
	set Param(CanVecNTSFiles) {}
   set Param(CanVecNTSFiles) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(NTSLayer)]
   #Param(CanVecNTSFiles) contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp
	GenX::Log DEBUG "CanVec NTS50K file : $Param(CanVecNTSFiles)"

	#ouverture du shapefile CanVec index NTS50K
   if { ![ogrlayer is CANVECNTSLAYER] } {
      set canvec_nts_layer [lindex [ogrfile open SHAPECANVECNTSLAYER read $Param(CanVecNTSFiles)] 0]
      eval ogrlayer read CANVECNTSLAYER $canvec_nts_layer
   }

   #test : comptage du nombre de polygones dans le shapefile (devrait être 1)
   GenX::Log DEBUG "On compte [ogrlayer define CANVECNTSLAYER -nb] tuiles NTS dans le fichier CanVec NTS Layer (devrait être 1)"

	#définition du UTMREF pour la zone à traiter
	UTMZoneDefine  $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) 1_$indexCouverture

	#conversion de l'index NTS50K en UTMREF pour obtenir des coordonnées xy
   ogrlayer stats CANVECNTSLAYER -transform UTMREF1_$indexCouverture

	#trouve les limites xy en coordonnées UTM de la tuile NTS sélectionnée
	set xy [ogrlayer stats CANVECNTSLAYER -extent True]

	#affecte les valeurs latlon aux divers paramètres x0, y0, x1, y1
	set Param(x0) [lindex $xy 0]
	set Param(y0) [lindex $xy 1]
	set Param(x1) [lindex $xy 2]
	set Param(y1) [lindex $xy 3]

	#calcul des dimensions xy de la zone
   set Param(Width)  [expr int(ceil(($Param(x1) - $Param(x0))/$Param(Resolution)))]
   set Param(Height) [expr int(ceil(($Param(y1) - $Param(y0))/$Param(Resolution)))]

	#ajustement de la zone UTM et du méridien
   set zone     [expr int(ceil((180 + (($Param(Lon1) + $Param(Lon0))/2))/6))]
   set meridian [expr -((180-($zone*6))+3)]

	#ajustement du UTMREF
	eval georef create UTMREF$indexCouverture \
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
	georef define UTMREF$indexCouverture -transform [list $Param(x0) $Param(Resolution) 0.000000000000000 $Param(y0) 0.000000000000000 $Param(Resolution)]

   GenX::Log INFO "UTM zone is $zone, with central meridian at $meridian. Dimension are $Param(Width)x$Param(Height)"

	#nettoyage de mémoire
	ogrfile close SHAPE50K SHAPECANVECNTSLAYER
	ogrlayer free NTSLAYER50K CANVECNTSLAYER

	GenX::Log INFO "Fin de la proc NTSExtent"
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
#		<indexCouverture>		: index à appliquer à la référence UTMREF
#
# Return: output genphysx_sandwich.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Sandwich { indexCouverture } {
   variable Param
   variable Data

	#add proc to Metadata
   GenX::Procs

   GenX::Log INFO "Debut de la proc for generating Sandwich"

	#création de la raster qui contiendra la LULC
   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef UTMREF$indexCouverture

	#recherche des fichiers CanVec à rasteriser
   GenX::Log INFO "Locating CanVec Files"
   set Param(Files) {}
   set Param(Files) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Entities)]
   #Param(Files) contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp

   set j 0 ;# Increment of VFEATURE2KEEP$j required to re-use the object

   #----- Rasterization of CanVec layers
	GenX::Log INFO "Generating Sandwich"
   foreach file $Param(Files) {
      set entity [string range [file tail $file] 11 22] ;# strip full file path to keep layer name only
      #entity contains an element of the form AA_9999999_9

      set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
      #filename contains an element of the form 999a99_9_9_AA_9999999_9

      set priority [lindex $Param(Priorities) [lsearch -exact $Param(Entities) $entity]]
      #value contains the nth element of the list Param(Priorities), where n is the index of layer in the list Param(Entities)

      ogrfile open SHAPE read $file
      #read the shapefile and stock it in the object SHAPE

      #the following if/else evaluates if the layer requires some post-processing prior to rasterization or if it is rasterized with the general procedure
      if { [lsearch -exact $Param(LayersPostPro) $entity] !=-1} {
         switch $entity {

            BS_1370009_2 {
				#residential areas
				#Lors de la procédure sandwich, l'entité prend entièrement les valeurs suivantes : PRI = 218 ; TEB = 210 ; SMO = 1
				#Lors de la procédure PopDens2Builtup, l'entité est découpée selon les seuils de densité de population suivants :
					#0 <= densité < 2000 : PRI = 218 ; TEB = 210 ; SMO = 1
					#2000 <= densité < 5000 : PRI = 217 ; TEB = 220 ; SMO = 2
					#5000 <= densité < 15000 : PRI = 216 ; TEB = 230 ; SMO = 3
					#15000 <= densité < 25000 : PRI = 215 ; TEB = 240 ; SMO = 4
					#25000 <= densité : PRI = 214 ; TEB = 250 ; SMO = 5
               GenX::Log DEBUG "Post-processing for Residential area, area"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity as VFEATURE2KEEP$j with priority value 218"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 218
            }
            BS_2010009_0 {
					# entity : Building, points
               GenX::Log DEBUG "Post-processing for buildings, points"

					#function = 1 : arena
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 1)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (arena) as VFEATURE2KEEP$j with priority value 32"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 32

					#function = 2 : armoury
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 2)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (armoury) as VFEATURE2KEEP$j with priority value 31"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 31

					#function = 5 : city hall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 5)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (city hall) as VFEATURE2KEEP$j with priority value 30"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 30

					#function = 6 : coast guard station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 6)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (coast guard station) as VFEATURE2KEEP$j with priority value 29"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 29

					#function = 7 : community center
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 7)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (community center) as VFEATURE2KEEP$j with priority value 28"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 28

					#function = 8 : courthouse
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 8)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (courthouse) as VFEATURE2KEEP$j with priority value 27"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 27

					#function = 9 : custom post
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 9)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (custom post) as VFEATURE2KEEP$j with priority value 26"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 26

					#function = 11 : electric power station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 11)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (electric power station) as VFEATURE2KEEP$j with priority value 25"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 25

					#function = 12 : fire station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 12)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fire station) as VFEATURE2KEEP$j with priority value 24"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 24

					#function = 16 : highway service center
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 16)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (highway service center) as VFEATURE2KEEP$j with priority value 23"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 23

					#function = 17 : hospital
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 17)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (hospital) as VFEATURE2KEEP$j with priority value 22"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 22

					#function = 19 : medical center
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 19)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (medical center) as VFEATURE2KEEP$j with priority value 21"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 21

					#function = 20 : municipal hall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 20)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (municipal hall) as VFEATURE2KEEP$j with priority value 20"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 20

					#function = 23 : gas and oil facilities building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 23)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (gas and oil facilities building) as VFEATURE2KEEP$j with priority value 19"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 19

					#function = 25 : parliament building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 25)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (parliament building) as VFEATURE2KEEP$j with priority value 18"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 18

					#function = 26 : police station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 26)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (police station) as VFEATURE2KEEP$j with priority value 17"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 17

					#function = 27 : railway station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 27)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (railway station) as VFEATURE2KEEP$j with priority value 16"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 16

					#function = 29 : satellite-tracking station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 29)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (satellite-tracking station) as VFEATURE2KEEP$j with priority value 15"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 15

					#function = 32 : sportsplex
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 32)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (sportsplex) as VFEATURE2KEEP$j with priority value 14"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 14

					#function = 37 : industrial building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 37)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (industrial building) as VFEATURE2KEEP$j with priority value 13"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 13

					#function = 38 : religious building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 38)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (religious building) as VFEATURE2KEEP$j with priority value 12"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 12

					#function = 39 : penal building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 39)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (penal building) as VFEATURE2KEEP$j with priority value 11"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 11

					#function = 41 : educational building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 41)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (educational building) as VFEATURE2KEEP$j with priority value 10"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 10

					#function = else
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function NOT IN (1,2,5,6,7,8,9,11,12,16,17,19,20,23,25,26,27,29,32,37,38,39,41)"
#					ogrlayer stats VFEATURE2KEEP$j -buffer 0.0000539957 8 ;# 6m x 2 : effectue un buffer autour du point, d'un rayon de 6 mètres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general) as VFEATURE2KEEP$j with priority value 33"
#					GenX::Log INFO "Buffering all point buildings to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 33
            }
            BS_2010009_2 {
					# entity : Building, polygons
               GenX::Log DEBUG "Post-processing for buildings, areas"
					#function = 1 : arena
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (arena) as VFEATURE2KEEP$j with priority value 103"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 103
					#function = 2 : armoury
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (armoury) as VFEATURE2KEEP$j with priority value 102"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 102
					#function = 5 : city hall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (city hall) as VFEATURE2KEEP$j with priority value 101"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 101
					#function = 6 : coast guard station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (coast guard station) as VFEATURE2KEEP$j with priority value 100"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 100
					#function = 7 : community center
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (community center) as VFEATURE2KEEP$j with priority value 99"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 99
					#function = 8 : courthouse
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 8)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (courthouse) as VFEATURE2KEEP$j with priority value 98"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 98
					#function = 9 : custom post
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 9)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (custom post) as VFEATURE2KEEP$j with priority value 97"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 97
					#function = 11 : electric power station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 11)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (electric power station) as VFEATURE2KEEP$j with priority value 96"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 96
					#function = 12 : fire station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 12)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fire station) as VFEATURE2KEEP$j with priority value 95"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 95
					#function = 16 : highway service center
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 16)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (highway service center) as VFEATURE2KEEP$j with priority value 94"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 94
					#function = 17 : hospital
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 17)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (hospital) as VFEATURE2KEEP$j with priority value 93"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 93
					#function = 19 : medical center
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 19)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (medical center) as VFEATURE2KEEP$j with priority value 92"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 92
					#function = 20 : municipal hall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 20)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (municipal hall) as VFEATURE2KEEP$j with priority value 91"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 91
					#function = 23 : gas and oil facilities building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 23)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (gas and oil facilities building) as VFEATURE2KEEP$j with priority value 90"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 90
					#function = 25 : parliament building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 25)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (parliament building) as VFEATURE2KEEP$j with priority value 89"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 89
					#function = 26 : police station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 26)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (police station) as VFEATURE2KEEP$j with priority value 88"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 88
					#function = 27 : railway station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 27)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (railway station) as VFEATURE2KEEP$j with priority value 87"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 87
					#function = 29 : satellite-tracking station
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 29)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (satellite-tracking station) as VFEATURE2KEEP$j with priority value 86"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 86
					#function = 32 : sportsplex
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 32)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (sportsplex) as VFEATURE2KEEP$j with priority value 85"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 85
					#function = 37 : industrial building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 37)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (industrial building) as VFEATURE2KEEP$j with priority value 84"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 84
					#function = 38 : religious building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 38)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (religious building) as VFEATURE2KEEP$j with priority value 83"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 83
					#function = 39 : penal building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 39)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (penal building) as VFEATURE2KEEP$j with priority value 82"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 82
					#function = 41 : educational building
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (function = 41)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (educational building) as VFEATURE2KEEP$j with priority value 81"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 81
					#function = else
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function NOT IN (1,2,5,6,7,8,9,11,12,16,17,19,20,23,25,26,27,29,32,37,38,39,41)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general) as VFEATURE2KEEP$j with priority value 104"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 104
            }
            BS_2060009_0 {
               #entity : Chimney, points
               GenX::Log DEBUG "Post-processing for Chimneys, points"
               #general value for unknown type
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1, 2, 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - general) as VFEATURE2KEEP$j with priority value 6"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 6
               #type = 1 : burner
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - burners) as VFEATURE2KEEP$j with priority value 5"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 5
               #type = 2 : industrial
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - industrial) as VFEATURE2KEEP$j with priority value 4"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 4
               #type = 3 : flare stack
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - flare stack) as VFEATURE2KEEP$j with priority value 3"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 3
            }
            BS_2240009_1 {
               #entity : Wall/fence, line
               GenX::Log DEBUG "Post-processing for Wall / fences, lines"
               #type = 1 : fence
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Wall / fence - fences) as VFEATURE2KEEP$j with priority value 114"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 114
               #type = 2 : wall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Wall / fence - fences) as VFEATURE2KEEP$j with priority value 113"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 113
            }
            BS_2310009_1 {
               #entity : Pipeline (Sewage / liquid waste), line
               GenX::Log DEBUG "Post-processing for Pipelines (Sewage / liquid waste), lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (aboveground sewage pipeline entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            EN_1180009_1 {
               #entity : Pipeline, line
               GenX::Log DEBUG "Post-processing for Pipelines, lines"
               #if relation2ground != 1 (aboveground), exclus; else, valeur générale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (aboveground pipeline entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            HD_1450009_0 {
               # entity : Manmade hydrographic entity [Geobase], point
               GenX::Log DEBUG "Post-processing for Manmade hydrographic entities, points"
               #type = 1 : dam
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 43"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 43
               #type = 1 : dock
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dock manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 42"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 42
               #type = 1 : wharf
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (wharf manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 41"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 41
               #type = 1 : breakwater
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (breakwater manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 44"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 44
               #type = 1 : dike / levee
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dike / levee manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 45"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 45
               #type = 1 : lock gate
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (lock gate manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 37"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 37
               #type = 1 : boat ramp
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (boat ramp manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 40"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 40
               #type = 1 : fish ladder
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 8)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fish ladder manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 38"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 38
               #type = 1 : slip
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 9)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (slip manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 39"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 39
               #type = 1 : breakwater in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (breakwater in the ocean manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 46"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 46
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,2,3,4,5,6,7,8,9,104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 47"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 47
            }
            HD_1450009_1 {
               # entity : Manmade hydrographic entity [Geobase], line
					GenX::Log DEBUG "Post-processing for Manmade hydrographic entities, lines"
               #type = 1 : dam
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 124"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 124
               #type = 1 : dock
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dock manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 123"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 123
               #type = 1 : wharf
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (wharf manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 122"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 122
               #type = 1 : breakwater
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (breakwater manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 125"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 125
               #type = 1 : dike / levee
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dike / levee manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 126"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 126
               #type = 1 : lock gate
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (lock gate manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 118"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 118
               #type = 1 : boat ramp
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (boat ramp manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 121"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 121
               #type = 1 : fish ladder
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 8)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fish ladder manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 119"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 119
               #type = 1 : slip
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 9)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (slip manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 120"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 120
               #type = 1 : breakwater in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (breakwater in the ocean manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 127"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 127
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,2,3,4,5,6,7,8,9,104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 128"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 128
            }
            HD_1450009_2 {
               # entity : Manmade hydrographic entity [Geobase], area
					GenX::Log DEBUG "Post-processing for Manmade hydrographic entities, areas"
               #type = 1 : dam
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 154"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 154
               #type = 1 : dock
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dock manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 153"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 153
               #type = 1 : wharf
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (wharf manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 152"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 152
               #type = 1 : breakwater
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (breakwater manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 155"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 155
               #type = 1 : dike / levee
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dike / levee manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 156"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 156
               #type = 1 : lock gate
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (lock gate manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 148"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 148
               #type = 1 : boat ramp
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (boat ramp manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 151"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 151
               #type = 1 : fish ladder
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 8)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fish ladder manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 149"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 149
               #type = 1 : slip
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 9)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (slip manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 150"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 150
               #type = 1 : breakwater in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (breakwater in the ocean manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 157"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 157
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,2,3,4,5,6,7,8,9,104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general manmade hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 158"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 158
            }
            HD_1460009_0 {
               # entity : Hydrographic obstacle entity [Geobase], point
					GenX::Log DEBUG "Post-processing for Hydrographic obstacle entities, points"
               #type = 1 : fall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fall hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 56"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 56
               #type = 2 : rapids
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rapids hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 57"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 57
               #type = 3 : reef
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (reef hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 53"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 53
               #type = 4 : rocks
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rocks hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 52"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 52
               #type = 5 : disappearing stream
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (disappearing stream hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 48"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 48
               #type = 6 : exposed shipwreck
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (exposed shipwreck hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 50"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 50
               #type = 7 : ford
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (ford hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 49"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 49
               #type = 103 : reef in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 103)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (reef in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 55"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 55
               #type = 104 : rocks in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rocks in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 54"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 54
               #type = 106 : exposed shipwreck in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 106)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (exposed shipwreck in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 51"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 51
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,2,3,4,5,6,7,103,104,106)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 58"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 58
            }
            HD_1460009_1 {
               # entity : Hydrographic obstacle entity [Geobase], line
					GenX::Log DEBUG "Post-processing for Hydrographic obstacle entities, lines"
               #type = 1 : fall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fall hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 137"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 137
               #type = 2 : rapids
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rapids hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 138"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 138
               #type = 3 : reef
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (reef hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 134"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 134
               #type = 4 : rocks
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rocks hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 133"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 133
               #type = 5 : disappearing stream
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (disappearing stream hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 129"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 129
               #type = 6 : exposed shipwreck
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (exposed shipwreck hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 131"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 131
               #type = 7 : ford
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (ford hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 130"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 130
               #type = 103 : reef in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 103)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (reef in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 136"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 136
               #type = 104 : rocks in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rocks in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 135"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 135
               #type = 106 : exposed shipwreck in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 106)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (exposed shipwreck in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 132"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 132
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,2,3,4,5,6,7,103,104,106)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 139"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 139
            }
            HD_1460009_2 {
               # entity : Hydrographic obstacle entity [Geobase], area
					GenX::Log DEBUG "Post-processing for Hydrographic obstacle entities, areas"
               #type = 1 : fall
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (fall hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 167"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 167
               #type = 2 : rapids
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rapids hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 168"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 168
               #type = 3 : reef
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (reef hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 164"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 164
               #type = 4 : rocks
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rocks hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 163"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 163
               #type = 5 : disappearing stream
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (disappearing stream hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 159"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 159
               #type = 6 : exposed shipwreck
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (exposed shipwreck hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 161"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 161
               #type = 7 : ford
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (ford hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 160"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 160
               #type = 103 : reef in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 103)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (reef in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 166"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 166
               #type = 104 : rocks in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 104)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (rocks in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 165"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 165
               #type = 106 : exposed shipwreck in the ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 106)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (exposed shipwreck in the ocean hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 162"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 162
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,2,3,4,5,6,7,103,104,106)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 169"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 169
            }
            HD_1470009_1 {
               # entity : Single line watercourse [Geobase], line
               GenX::Log DEBUG "Post-processing for Single line watercourse, line"
               #definition = 1 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (canal watercourses) as VFEATURE2KEEP$j with priority value 142"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 142
               #definition = 2 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 2)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (conduit watercourses) as VFEATURE2KEEP$j with priority value 141"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 141
               #definition = 3 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (conduit watercourses) as VFEATURE2KEEP$j with priority value 140"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 140
               #definition = 6 : watercourse
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (canal watercourses) as VFEATURE2KEEP$j with priority value 144"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 144
               #definition = 7 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (conduit watercourses) as VFEATURE2KEEP$j with priority value 143"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 143
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,2,3,6,7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 145"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 145
            }
            HD_1480009_2 {
              # entity : Waterbody [Geobase], polygon
               GenX::Log DEBUG "Post-processing for Waterbody, polygon"
               #definition = 1 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (canal waterbodies) as VFEATURE2KEEP$j with priority value 172"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 172
               #definition = 3 : ditch
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (ditch waterbodies) as VFEATURE2KEEP$j with priority value 171"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 171
               #definition = 4 : lake
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (lake waterbodies) as VFEATURE2KEEP$j with priority value 178"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 178
               #definition = 5 : reservoir
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 5)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (reservoir waterbodies) as VFEATURE2KEEP$j with priority value 179"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 179
               #definition = 6 : watercourse
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (watercourse waterbodies) as VFEATURE2KEEP$j with priority value 175"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 175
               #definition = 7 : tidal river
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 7)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (tidal river waterbodies) as VFEATURE2KEEP$j with priority value 174"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 174
               #definition = 8 : liquid waste
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 8)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (liquid waste waterbodies) as VFEATURE2KEEP$j with priority value 176"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 176
               #definition = 9 : pond
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 9)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (pond waterbodies) as VFEATURE2KEEP$j with priority value 177"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 177
               #definition = 10 : side channel
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 10)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (side channel waterbodies) as VFEATURE2KEEP$j with priority value 173"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 173
               #definition = 100 : ocean
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 100)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (ocean waterbodies) as VFEATURE2KEEP$j with priority value 180"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 180
               #general value for unknown types
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE definition NOT IN (1,3,4,5,6,7,8,9,10,100)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general waterbodies) as VFEATURE2KEEP$j with priority value 181"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 181
            }
            IC_2600009_0 {
               # entity : Mining area, point
               GenX::Log DEBUG "Post-processing for Mining area, point"
               #status = 1 : mines opérationnelles
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (status = 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (operational mines) as VFEATURE2KEEP$j with priority value 65"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 65
               #status != 1 : mines non opérationnelles
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (status != 1)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (non operational mines) as VFEATURE2KEEP$j with priority value 66"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 66
            }
            TR_1020009_1 {
               # entity : Railway, line
               GenX::Log DEBUG "Post-processing for Railway, line"
               #support = 3 : bridge
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (support = 3)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (bridge railway) as VFEATURE2KEEP$j with priority value 2"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 2
               #support != 3 ou 4 : not bridge, not tunnel
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE support NOT IN (3,4)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (bridge railway) as VFEATURE2KEEP$j with priority value 111"
					gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 111
            }
            TR_1190009_0 {
					# entity : Runway, point
					GenX::Log DEBUG "Post-processing for Runway, point"
					#type = 1 : airport
					ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1 )"
					GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (airport runway) as VFEATURE2KEEP$j with priority value 62"
					gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 62
					#type = 2 ou 3 : heliport, hospital heliport
					ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type IN (2,3)"
					GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (heliport or hospital heliport runway) as VFEATURE2KEEP$j with priority value 7"
					gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 7
					#type = 4 : water aerodrome
					ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4 )"
					GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (water aerodrome runway) as VFEATURE2KEEP$j with priority value 61"
					gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 61
            }
            TR_1190009_2 {
					# entity : Runway, area
					GenX::Log DEBUG "Post-processing for Runway, areas"
					#type = 1 : airport
					ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1 )"
					GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (airport runway) as VFEATURE2KEEP$j with priority value 201"
					gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 201
					#type = 2 ou 3 : heliport, hospital heliport
					ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type IN (2,3)"
					GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (heliport or hospital heliport runway) as VFEATURE2KEEP$j with priority value 80"
					gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 80
					#type = 4 : water aerodrome
					ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4 )"
					GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (water aerodrome runway) as VFEATURE2KEEP$j with priority value 147"
					gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 147
            }
            TR_1760009_1 {
               # entity : Road segment [Geobase], line
					GenX::Log DEBUG "Post-processing for Road segment, lines"

               #exclusions des structype 5 (tunnel) et 6 (snowshed), association de la valeur générale à tout le reste des routes pavées
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (pavstatus != 2) AND structype NOT IN (5,6)"
#					ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general road segments) as VFEATURE2KEEP$j with priority value 109"
#					GenX::Log INFO "Buffering general road segments to 12m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 109

               #pavstatus = 2 : unpaved : routes non pavées n'étant pas des tunnels ou des snowsheds
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (pavstatus = 2) AND structype NOT IN (5,6)"
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (unpaved road segments) as VFEATURE2KEEP$j with priority value 110"
					#pas de buffer sur les routes non pavées
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 110

               #roadclass in (1,2) : freeway, expressway/highway n'étant pas des tunnels ou des snowsheds
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE roadclass in (1,2) AND structype NOT IN (5,6)"
#					ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (highways road segments) as VFEATURE2KEEP$j with priority value 108"
#					GenX::Log INFO "Buffering highway road segments to 22m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 108

              #structype in (1,2,3,4) : bridge (tous les types de ponts)
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE structype IN (1,2,3,4)"
#					ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
               GenX::Log DEBUG "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (bridge road segments) as VFEATURE2KEEP$j with priority value 1"
#					GenX::Log INFO "Buffering bridge road segments to 22m"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 1
            }
            default {
               #the layer is part of Param(LayersPostPro) but no case has been defined for it
               GenX::Log WARNING "Post-processing for $file not found.  The layer was not rasterized."
            }
         }
         ogrlayer free VFEATURE2KEEP$j
         incr j ;# Increment of VFEATURE2KEEP$j required to re-use the object
      } else {
         #general procedure for rasterization : entities are not part of Param(LayersPostPro)
         eval ogrlayer read LAYER$j SHAPE 0
         GenX::Log DEBUG "Rasterizing [ogrlayer define LAYER$j -nb] features from file $file as LAYER$j with priority value $priority, general procedure"
         gdalband gridinterp RSANDWICH LAYER$j $Param(Mode) $priority
         ogrlayer free LAYER$j
      }
      ogrfile close SHAPE
   }

   #creating the output file
   file delete -force $GenX::Param(OutFile)_sandwich_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich_$indexCouverture.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RSANDWICH

   GenX::Log INFO "The file $GenX::Param(OutFile)_sandwich_$indexCouverture.tif was generated"

	GenX::Log INFO "Fin de UrbanX::SandwichCanVec"

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::ChampsBuffers>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Create the fields and building vicinity output using spatial buffers
#
# Parameters :
#		<indexCouverture>		: index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :  BUG on the buffer generation due to GEOS 3.2.2.  Should be fixed
#           with 3.3.0
#
#----------------------------------------------------------------------------
proc UrbanX::ChampsBuffers {indexCouverture } {

	#add proc to Metadata
   GenX::Procs

   variable Param
   variable Data

   GenX::Log INFO "Buffer zone processing for grass and fields identification"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]

   gdalband create RBUFFER $Param(Width) $Param(Height) 1 Byte
   eval gdalband define RBUFFER -georef UTMREF$indexCouverture
   set i 0
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach layer $Param(BufferFuncLayers) value $Param(BufferFuncValues) {
         set path [glob -nocomplain $path/${sheet}_$layer.shp]
         if { [file exists $path] } {
            set layer2 [lindex [ogrfile open SHAPE read $path] 0]
            eval ogrlayer read LAYER$i $layer2
            if  { $layer=="buildin_a" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM ${sheet}_$layer WHERE function NOT IN (3,4,14,36) "
               ogrlayer stats LAYER$i -buffer 0.00089993 8
            } elseif  { $layer=="buildin_p" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM ${sheet}_$layer WHERE function NOT IN (3,4,14,36) "
               ogrlayer stats LAYER$i -buffer 0.000224982 8
            }
            GenX::Log INFO "Buffering [ogrlayer define LAYER$i -nb] features from ${sheet}_$layer.shp as LAYER$i with buffer value $value"
            gdalband gridinterp RBUFFER LAYER$i $Param(Mode) $value
            ogrlayer free LAYER$i
            ogrfile close SHAPE
         }
      }
      incr i
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
   gdalband free RBUFFER
   gdalband free RSANDWICH
   gdalfile close FSANDWICH

   file delete -force $GenX::Param(OutFile)_champs-only+building-vicinity.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_champs-only+building-vicinity.tif GeoTiff
   gdalband write RBUFFERCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RBUFFERCUT
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::PopDens2Builtup>
# Creation : date? - Alexandre Leroux - CMC/CMOE
# Revision : July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Reclassify the builtup areas with several thresholds related
#            to population density
#
# Parameters :
#		<indexCouverture>		: index à appliquer à la référence UTMREF
#
# Return: output files :
#             genphysx_popdens.tif
#             genphysx_popdens-builtup.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::PopDens2Builtup { indexCouverture } {

	#add proc to Metadata
	GenX::Procs

	GenX::Log INFO "Début de la proc PopDens2BuiltupCanVec"
	variable Param
	
	#récupération de genphysx_sandwich.tif
	GenX::Log DEBUG "Récupération du fichier sandwich"
	gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]

	#récupération du fichier de données socio-économiques
	GenX::Log DEBUG "Récupération du fichier de polygones de DA"
	set layer [lindex [ogrfile open SHAPE read $Param(PopFile2006SMOKE)] 0]
	eval ogrlayer read VPOPDENS $layer

	#----- Selecting only the required StatCan polygons - next is only useful to improve the speed of the layer substraction
	GenX::Log DEBUG "Sélection des polygones de DA appropriés."
	set da_select [ogrlayer pick VPOPDENS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
	ogrlayer define VPOPDENS -featureselect [list [list index # $da_select]]

	#	clear la colonne POP_DENS pour les polygones de DA sélectionnés
	ogrlayer clear VPOPDENS POP_DENS

	#création d'un fichier de rasterization des polygones de DA
	gdalband create RDA $Param(Width) $Param(Height) 1 Int32
	gdalband clear RDA -1
	gdalband define RDA -georef UTMREF$indexCouverture

	#rasterization des polygones de DA
	GenX::Log INFO "Rasterization des polygones de DA sélectionnés."
	gdalband gridinterp RDA VPOPDENS FAST FEATURE_ID

	#comptage des pixels de la residential area pour chaque polygone de DA : increment de la table et buildings generals (ponctuels et surfaciques)
	GenX::Log INFO "Comptage des pixels de la zone résidentielle et des bâtiments sans fonction précisée pour chaque polygone de DA"
	vexpr VPOPDENS.POP_DENS tcount(VPOPDENS.POP_DENS,ifelse (RSANDWICH==218 || RSANDWICH==104 || RSANDWICH==33,RDA,-1))

	#Calcul de la densité de population
	GenX::Log INFO "Calculating population density values"
	GenX::Log INFO "Ajustement de la densité au besoin"
	foreach n $da_select {
		#récupération de la valeur de population
		set pop [ogrlayer define VPOPDENS -feature $n POP_NEW]
		
		#calcul de l'aire de la residential area à l'aide du nombre de pixels comptés précédemment
		set nbrpixels [ogrlayer define VPOPDENS -feature $n POP_DENS]
		set area_pixels [expr ($nbrpixels*25.0/1000000.0)] ;#nbr de pixels * (5m*5m) de résolution / 1000000 m² par km² = area en km²

		#calcul de la densité de population : dentité = pop/aire
		if {$area_pixels != 0} {
			set densite_pixels [expr $pop/$area_pixels]
		} else {
			set densite_pixels 0
		}

		#calcul de l'aire à l'aide de la géométrie
		set geom [ogrlayer define VPOPDENS -geometry $n]
		set area_vect  [expr ([ogrgeometry stats $geom -area]/1000000.0)]

		#calcul de la densité de population : dentité = pop/aire
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
			GenX::Log DEBUG "Ajustement de la densité pour le polygone $n"
		} else {
			set densite_choisie $densite_pixels  
		}
		ogrlayer define VPOPDENS -feature $n POP_DENS $densite_choisie
	}

	unset da_select

	#Conversion de la densité de population en raster
	GenX::Log INFO "Conversion des densités de population en raster"
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
	
	#LES LIGNES SUIVANTES SERONT À REMPLACER PAR LE BLOC IFELSE POUR DIFFÉRENCIER URBANX ET INDUSTRX
	vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<2000),1,RPOPDENSCUT)
	vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=2000 && RPOPDENS<5000)),2,RPOPDENSCUT)
	vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=5000 && RPOPDENS<15000),3,RPOPDENSCUT)
	vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=15000 && RPOPDENS<25000),4,RPOPDENSCUT)
	vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=25000),5,RPOPDENSCUT)

# 	if {$GenX::Param(SMOKE)!="" } {
# 		#seuils de densité de population associés à SMOKE (IndustrX)
# 		GenX::Log INFO "Seuils adaptés à IndustrX"
# 		vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<100),1,RPOPDENSCUT)
# 		vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=100 && RPOPDENS<1000)),2,RPOPDENSCUT)
# 		vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=1000 && RPOPDENS<4000),3,RPOPDENSCUT)
# 		vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=4000),4,RPOPDENSCUT)
# 	} else {
# 		#seuils de densité de population associés à TEB (UrbanX)
# 		GenX::Log INFO "Seuils adaptés à UrbanX"
# 		vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<2000),1,RPOPDENSCUT)
# 		vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=2000 && RPOPDENS<5000)),2,RPOPDENSCUT)
# 		vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=5000 && RPOPDENS<15000),3,RPOPDENSCUT)
# 		vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=15000 && RPOPDENS<25000),4,RPOPDENSCUT)
# 		vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=25000),5,RPOPDENSCUT)
# 	}

	#nettoyage de mémoire
	gdalband free RSANDWICH RPOPDENS RTEMP
	gdalfile close FSANDWICH

	#écriture du fichier genphysx_popdens-builtup.tif
	GenX::Log DEBUG "Génération du fichier résultant du cookiecutting"
	file delete -force $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif
	gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif GeoTiff
	gdalband write RPOPDENSCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
	gdalfile close FILEOUT
	gdalband free RPOPDENSCUT
	GenX::Log INFO "The file $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif was generated"

	#nettoyage de mémoire
	gdalfile close FILEOUT
	gdalband free RPOPDENSCUT

	GenX::Log INFO "Fin de la proc PopDens2BuiltupCanVec"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::HeightGain>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Estimate DEM Height gain based on...
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::HeightGain {indexCouverture } {

	#add proc to Metadata
   GenX::Procs

   variable Param

   GenX::Log INFO "Evaluating height gain"

   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband create RHAUTEURPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURPROJ -georef UTMREF$indexCouverture

   #----- La vérification pourrait être fait dans un proc avec vérification des 4 points de la source
   gdalband read RHAUTEUR [gdalfile open FHAUTEUR read $Param(HeightFile)]
   gdalband stats RHAUTEURPROJ -nodata -9999
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

   file delete -force $GenX::Param(OutFile)_hauteur-champs.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-champs.tif GeoTiff
   gdalband write RHEIGHTCHAMPS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT

   gdalband free RCHAMPS RHEIGHTCHAMPS RHAUTEURPROJ
   gdalfile close FCHAMPS
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::BuildingHeight>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#		<indexCouverture>		: index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::BuildingHeight {indexCouverture } {

	#add proc to Metadata
   GenX::Procs

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
#   gdalband write RHAUTEURCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
#   gdalfile close FILEOUT
   file delete -force $GenX::Param(OutFile)_hauteur-classes.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-classes.tif GeoTiff
   gdalband write RHAUTEURCLASS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalfile close FSANDWICH
   gdalband free RHAUTEURCLASS RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::EOSDvegetation>
# Creation : October 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :  Replaces empty zones or wooded area zones
#						by values from EOSD dataset
#
# Parameters :
#
# Return:
#
# Remarks : SINCE EOSD DOES NOT COVERS CANADA ENTIRELY, AND SINCE OTHER DATA ARE MORE ACCURATE, 
#							THIS PROC WILL BE DELETED AND REPLACED BY LCC2000V
#
#----------------------------------------------------------------------------
proc UrbanX::EOSDvegetation {indexCouverture } {

	#add proc to Metadata
   GenX::Procs

	GenX::Log INFO "Début de la proc EOSDvegetation"

	variable Param

	#lecture du fichier créé précédemment lors de la proc SandwichCanVec
	gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]

	#recherche des fichiers EOSD
	set Param(EOSDFiles) [GenX::EOSDFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)]
	#Param(EOSDFiles) contains one element of the form /cnfs/ops/production/cmoe/geo/EOSD/999A_lc_1/999A_lc_1.tif
	GenX::Log DEBUG "Le fichier EOSD suivant a été trouvé : $Param(EOSDFiles)"

	#read the EOSD file
	gdalband read REOSDTILE [gdalfile open FEOSDTILE read $Param(EOSDFiles)]

	#sélection de la zone EOSD appropriée à l'aide de la sandwich
	GenX::Log INFO "Sélection de la zone appropriée sur la tuile EOSD"
	gdalband copy RMASK RSANDWICH
	vexpr RMASK RMASK << 0
	gdalband gridinterp RMASK REOSDTILE NEAREST

	#conserver les valeurs EOSD lorsque la sandwich est vide ou présente une zone boisée
	GenX::Log INFO "Conserver les valeurs EOSD lorsque la sandwich est vide ou présente une zone boisée"
	vexpr RVEGE ifelse((RSANDWICH==0 || RSANDWICH==200),RMASK, 0)

	#écriture du fichier
	file delete -force $GenX::Param(OutFile)_EOSDVegetation_$indexCouverture.tif
	gdalfile open FILEOUT write $GenX::Param(OutFile)_EOSDVegetation_$indexCouverture.tif GeoTiff
	gdalband write RVEGE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
	gdalfile close FILEOUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDVegetation_$indexCouverture.tif was generated"

	#affectation des valeurs SMOKE
	GenX::Log INFO "Affectation des valeurs SMOKE à certaines classes EOSD"
	gdalband create RVEGESMOKE $Param(Width) $Param(Height) 1 Byte
	gdalband define RVEGESMOKE -georef UTMREF$indexCouverture

	vector dim LUT { FROM TO }
	vector set LUT.FROM { 50 51 52 100 110 120 121 122 200 210 211 212 213 220 221 222 223 230 231 232 233 }
	vector set LUT.TO   { 75 76 77  78  79  80  81  82  83  84  85  86  87  88  89  90  91  92  93  94  95 }
	vexpr RVEGE ifelse((RSANDWICH==0 || RSANDWICH==200),lut(RVEGE,LUT.FROM,LUT.TO),RVEGE)

	#écriture du fichier
	file delete -force $GenX::Param(OutFile)_EOSDSMOKE_$indexCouverture.tif
	gdalfile open FILEOUT write $GenX::Param(OutFile)_EOSDSMOKE_$indexCouverture.tif GeoTiff
	gdalband write RVEGESMOKE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDSMOKE_$indexCouverture.tif was generated"

	#nettoyage de mémoire
 	gdalfile close FSANDWICH FEOSDTILE FILEOUT
 	gdalband free RSANDWICH REOSDTILE RVEGE RVEGESMOKE RTEMP

	GenX::Log INFO "Fin de la proc EOSDvegetation"
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
proc UrbanX::LCC2000V {indexCouverture} {

	#add proc to Metadata
   GenX::Procs

	GenX::Log INFO "Début de la proc LCC2000V"

	variable Param

	GenX::Log INFO "Récupération du fichier sandwich"
	#lecture du fichier créé précédemment lors de la proc SandwichCanVec
	gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]

	#recherche des fichiers LCC2000V
	GenX::Log INFO "Recherche des fichiers LCC2000V"

	#---- NOTE : CE PROCESSUS DEVRAIT SE RETROUVER DIRECTEMENT DANS GENX
	#---- IL SERAIT ALORS REMPLACÉ PAR LES DEUX LIGNES SUIVANTES :
		#	set Param(LCC2000VFiles) [GenX::LCC2000VFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1)]
		#	GenX::Log INFO "Les fichier LCC2000V suivants ont été trouvés : $Param(LCC2000VFiles)"
	#---- LA SÉRIE DES SET LAT/LON SERAIT ALORS SUPPRIMÉE ET LE PATH SERAIT UNIFORMISÉ
	#---- IL FAUT AUSSI VOIR SI L'EMPLACEMENT DE LA BASE DE DONNÉES DOIT ÊTRE MODIFIÉ

	set Lat1 $Param(Lat1)
	set Lon1 $Param(Lon1)
	set Lat0 $Param(Lat0)
	set Lon0 $Param(Lon0)
	set Path(LCC2000V) /data/aqli04/afsulub/lcc2000v_csc2000v/shp_en

	if { ![ogrlayer is NTSLAYER250K] } {
		set nts_layer [lindex [ogrfile open SHAPE250K read $GenX::Path(NTS)/decoupage250k_2.shp] 0]
		eval ogrlayer read NTSLAYER250K $nts_layer
	}

	set files { }
	foreach id [ogrlayer pick NTSLAYER250K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
		set feuillet [ogrlayer define NTSLAYER250K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 2]
      set sl_maj [string toupper [string range $feuillet 3 3]]
		set sl_min [string tolower [string range $feuillet 3 3]]
		if { [llength [set lst [glob -nocomplain $Path(LCC2000V)/${s250}/${sl_min}/*LCC2000-V_${s250}${sl_maj}*.shp]]] } {
			lappend files $lst
		}
	}
	#---- FIN DU BLOC À MIGRER DANS GENX

	GenX::Log DEBUG "Les fichiers LCC2000-V suivants ont été trouvés : $files"
	set Param(LCC2000VFiles) $files  ;#cette ligne devrait être supprimée si le bloc est migré dans GenX
	#Param(LCC2000VFiles) contains a list of elements of the form/data/aqli04/afsulub/lcc2000v_csc2000v/shp_en/999/a/LCC2000-V_999A_1_0.shp

	set j 0 ;# Increment of LAYERLCC2000V$j required to re-use the object

	foreach fichierLCC2000V $Param(LCC2000VFiles) {

		#read the LCC2000V file
		ogrfile open SHAPELCC2000V read $fichierLCC2000V
		eval ogrlayer read LAYERLCC2000V$j SHAPELCC2000V 0

		#sélection de la zone LCC2000-V appropriée à l'aide de la sandwich
		GenX::Log INFO "Sélection de la zone appropriée sur la tuile LCC2000V"
		gdalband copy RMASK RSANDWICH
		vexpr RMASK RMASK << 0

		#rasterization des éléments LCC2000V
		GenX::Log INFO "Rasterizarion des éléments LCC2000V sur la zone à traiter (peut être long...)"
		set t_gridinterp [clock seconds]
		gdalband gridinterp RMASK LAYERLCC2000V$j $Param(Mode) COVTYPE
		GenX::Log DEBUG "Temps total de rasterization : [expr [clock seconds]-$t_gridinterp] secondes"

		#nettoyage de mémiore
		ogrlayer free LAYERLCC2000V$j 
		ogrfile close SHAPELCC2000V

		#préparation à la nouvelle boucle
		incr j ;# Increment of VFEATURE2KEEP$j required to re-use the object
	}

	#nettoyage de mémoire
	gdalfile close FSANDWICH
 	gdalband free RSANDWICH

   #creating the output file : les entités LCC2000V rasterizés
	GenX::Log DEBUG "Génération du fichier de sortie"
   file delete -force $GenX::Param(OutFile)_LCC2000V_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_LCC2000V_$indexCouverture.tif GeoTiff
   gdalband write RMASK FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RMASK

	GenX::Log INFO "Lecture du fichier LCC2000V"
	#lecture du fichier créé précédemment lors de la proc SandwichCanVec
	gdalband read RLCC2000V [gdalfile open FLCC2000V read $GenX::Param(OutFile)_LCC2000V_$indexCouverture.tif]

	#associer aux valeurs LCC2000V des priorités
	GenX::Log INFO "Associer des valeurs de priorités aux données LCC2000V"
	vector create LUT
	vector dim LUT { FROM TO }
	vector set LUT.FROM {0 10 11 12 20 30 31 32 33 34 35 36 37 40 50 51 52 53 80 81 82 83 100 101 102 103 104 110 121 122 123 200 210 211 212 213 220 221 222 223 230 231 232 233 }
	vector set LUT.TO   { 0 0 0 0 0 500 0 0 501 0 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535  }
	vexpr RLCC2000VSMOKE lut(RLCC2000V,LUT.FROM,LUT.TO)
	vector free LUT

	GenX::Log DEBUG "Génération du fichier de sortie"
   #creating the output file
   file delete -force $GenX::Param(OutFile)_LCC2000VSMOKE_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_LCC2000VSMOKE_$indexCouverture.tif GeoTiff
   gdalband write RLCC2000VSMOKE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT

	#nettoyage de mémoire
 	gdalfile close FLCC2000V
 	gdalband free RLCC2000V RLCC2000VSMOKE

	GenX::Log INFO "Fin de la proc LCC2000V"

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Priorities2TEB>
# Creation : date? - Alexandre Leroux - CMC/CMOE
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

	#add proc to Metadata
   GenX::Procs

   variable Param

   GenX::Log INFO "Converting values to TEB classes"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup.tif]
   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(OutFile)_hauteur-classes.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Priorities)
   vector set LUT.TO $Param(TEBClasses)
   vexpr RTEB lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   vexpr RTEB ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RTEB)
   vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
   vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB.tif GeoTiff
   gdalband write RTEB FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   gdalfile close FILEOUT
   gdalfile close FSANDWICH
   gdalfile close FPOPDENSCUT
   gdalfile close FCHAMPS
   gdalfile close FHAUTEURCLASS
   gdalband free RTEB RSANDWICH RPOPDENSCUT RCHAMPS RHAUTEURCLASS
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

	#add proc to Metadata
   GenX::Procs

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

	#add proc to Metadata
   GenX::Procs

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

	#add proc to Metadata
   GenX::Procs

   GenX::Log INFO "Converting TEB raster to RPN"

   gdalband read BAND [gdalfile open FILE read $GenX::Param(OutFile)_TEB.tif]

   UrbanX::CreateFSTDBand GRID BAND

   file delete -force $GenX::Param(OutFile)_TEB.fstd
   fstdfile open 1 write $GenX::Param(OutFile)_TEB.fstd

   fstdfield gridinterp GRID BAND
   fstdfield define GRID -NOMVAR UG
   fstdfield write TIC 1 -32 True
   fstdfield write TAC 1 -32 True
   fstdfield write GRID 1 -16 True

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
proc UrbanX::Shp2Height {indexCouverture } {

	#add proc to Metadata
   GenX::Procs

   variable Param

   if { $Param(Shape)=="" } {
      return
   }
   GenX::Log INFO "Converting $GenX::Param(Urban) building shapefile to raster"

   gdalband create RHAUTEURSHP $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURSHP -georef UTMREF$indexCouverture

   set shp_layer [lindex [ogrfile open SHAPE read $Param(Shape)] 0]
   eval ogrlayer read LAYER $shp_layer
   gdalband gridinterp RHAUTEURSHP LAYER $Param(Mode) $Param(ShapeField)

   ogrlayer free LAYER
   ogrfile close SHAPE

   file delete -force $GenX::Param(OutFile)_shp-height.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_shp-height.tif GeoTiff
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

	#add proc to Metadata
   GenX::Procs

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
# Name     : <UrbanX::Utilitaires>
# Creation : Octobre 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Various functions that are not commonly
#						used in UrbanX process but might be
#						useful before of after the main process
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

	#RÉINITIALISATION D'UN FICHIER DE DA
# 	puts "Utilitaire pour réinitialiser toutes les colonnes SMOKE d'un fichier de polygones de DA"
# 	set fichierDA /data/aqli04/afsulub/StatCan2006/SMOKE_FILLED/da2006-nts_lcc-nad83_PRECISERLENOM.shp
# 	puts "Fichier à traiter : $fichierDA"
# 	puts "Ouverture du fichier..."
# 	set da_layer_smoke [lindex [ogrfile open SHAPEDASMOKE append $fichierDA] 0]
# 	eval ogrlayer read VDASMOKE $da_layer_smoke
# 	puts "Réinitialisation des colonnes"
# 	#	clear les colonnes SMOKE pour les polygones de DA sélectionnés
# 	for {set classeid 1} {$classeid < 96} {incr classeid 1} {
# 		ogrlayer clear VDASMOKE SMOKE$classeid
# 		puts "La colonne $classeid a été réinitialisée"
# 	}
# 	puts "Écriture et fermeture du fichier"
# 	ogrlayer sync VDASMOKE ;# là pcq mode append, pas besoin en mode write, mais le mode write a un bug
# 	ogrlayer free VDASMOKE 
# 	ogrfile close SHAPEDSMOKE  
# 	puts "Les colonnes SMOKE1 à SMOKE$classeid devraient être vides. Vérifier le résultat."
# 	return


	#POUR TROUVER TOUS LES FICHIERS CANVEC DU CANADA POUR UNE ENTITÉ
# 	puts "Utilitaire pour trouver tous les fichiers CanVec du Canada pour une entité"
# 	set Param(FilesCanada) {}
# 	set Param(LayerATrouver) {LX_1000079_2}
# 	puts "Entité à trouver : $Param(LayerATrouver)"
# 	puts "Recherche des fichiers Canvec..."
# 	set Param(FilesCanada) [GenX::CANVECFindFiles 40 -50 88 -150 $Param(LayerATrouver)]
# 	#Param(Files) contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp
# 	set unique_filescanada [lsort -unique $Param(FilesCanada)]
# 	set sort_unique_filescanada [lsort $unique_filescanada]
# 	puts "Liste des fichiers trouvés :"
# 	foreach file $sort_unique_filescanada {
# 		set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
# 		#filename contains an element of the form 999a99_9_9_AA_9999999_9
# 		puts $filename
# 	}
# 	puts "Il y a [llength $sort_unique_filescanada] shapefiles trouvés."
# 	return

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Process>
# Creation : date? - Alexandre Leroux - CMC/CMOE
# Revision : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :
#
# Parameters :
#   <Coverage>   : zone to process {MONTREAL VANCOUVER TORONTO OTTAWA WINNIPEG CALGARY HALIFAX REGINA EDMONTON VICTORIA QUEBEC}
#									   default settings on Quebec City
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Process { Coverage } {

	GenX::Log INFO "Début d'UrbanX"

	variable Param
	variable Meta

	#pour employer un utilitaire, retirer le # des deux lignes suivantes et aller retirer les # associés à l'utilitaire choisi dans la proc UrbanX::Utilitaires
	#UrbanX::Utilitaires
	#	return

	set Usedtool "UrbanX"
	GenX::Log INFO "Coverage = $Coverage"
	GenX::Log INFO "Traitement d'une ville : $Usedtool"

	set t_traitement [clock seconds]

	#----- Get the lat/lon and files parameters associated with the province
	UrbanX::AreaDefine    $Coverage

	#----- Defines the extents of the zone to be process, the UTM Zone and set the initial UTMREF
	UrbanX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) $Coverage

	#----- Finds CanVec files, rasterize and flattens all CanVec layers, applies buffer on some elements
#	UrbanX::Sandwich $Coverage

	#-----La rasterization des hauteurs n'a pas vraiment sa place dans UrbanX... C'est one-shot.
	#UrbanX::Shp2Height $Coverage

	#----- Creates the fields and building vicinity output using spatial buffers
	#UrbanX::ChampsBuffers 0

	#----- Calculates the population density
	UrbanX::PopDens2Builtup $Coverage

	#----- Calculates building heights
	#UrbanX::HeightGain 0
	#UrbanX::BuildingHeight

	# ----------TO MODIFY FOR LCC2000-V DATA INSTEAD OF EOSD
	#EOSD Vegetation
	#	UrbanX::EOSDvegetation $Coverage
	#LCC2000V Vegetation
	#UrbanX::LCC2000V $Coverage
	# ----------END OF : TO MODIFY FOR LCC2000-V DATA INSTEAD OF EOSD 

	#----- Applies LUT to all processing results to generate TEB classes.
	#UrbanX::Priorities2TEB

	#----- Optional outputs:
	#UrbanX::VegeMask
	#UrbanX::TEB2FSTD

	#écriture des métadonnées
	set GenX::Meta(Footer) " Varia : 
	Données CanVec : $GenX::Path(CANVEC)
	Données de Statistique Canada : $Param(PopFile2006SMOKE)
	Données EOSD : $GenX::Path(EOSD)
	Temps total du traitement : [expr [clock seconds]-$t_traitement] secondes"
	GenX::MetaData $GenX::Param(OutFile)_metadata_$Coverage.txt

	#fin de la boucle sur la zone à traiter
	GenX::Log INFO "Fin du traitement de $Coverage avec UrbanX"
	GenX::Log INFO "Fin d'UrbanX.  Retour à GenPhysX"

} ;#fin de la proc process
