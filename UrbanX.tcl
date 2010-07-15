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
#              données CanVec 1:50000, StatCan (population) et bâtiments 3D
#              pour alimenter le modèle TEB
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

   set Param(Version)   0.2

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

#TO DELETE, Layers from BNDT
#   set Param(Layers)            { pe_snow_a dry_riv_a embankm_a cut_a so_depo_a dam_a sand_a cemeter_a bo_gard_a zoo_a picnic_a park_sp_a am_park_a campgro_a golf_dr_a golf_co_a peat_cu_a stockya_a mininga_a fort_a ruins_a exhib_g_a oil_fac_a auto_wr_a lu_yard_a slip_a drivein_a water_b_a rock_le_a trans_s_a vegetat_a wetland_a li_depo_a fish_po_a lookout_a tank_a stadium_a runway_a breakwa_l esker_l dyke_le_l seawall_l n_canal_a builtup_a water_c_l ford_l wall_fe_l pipelin_l dam_l haz_air_l conveyo_l conduit_l railway_l pp_buildin_a pp_buildin_a buildin_a wharf_l lock_ga_l pp_sports_t_l pp_sports_t_a sport_t_l sport_t_a so_depo_p n_canal_l haz_air_p marina_p dam_p trail_l wind_de_p crane_l li_road_l pp_road_l pp_road_l road_l bridge_l footbri_l lock_ga_p ford_p pp_seapl_b_p seapl_b_p boat_ra_p pp_mininga_p mininga_p hi_site_p lookout_p oil_fac_p p_anten_p ruins_p silo_p campgro_p camp_p picnic_p drivein_p cemeter_p tank_p ski_cen_p trans_s_p li_depo_p pp_runway_a+p runway_p chimney_p tower_p pp_buildin_p pp_buildin_p buildin_p } ;# NTDB layers to be processed

#List of CanVec layers, general form AA_9999999_9,
#where AA is the theme code (BS = Building and structures, EN = Energy, FO = Relief and landforms, HD - Hydrography, IC = Industrial and commercial areas, LI = Administrative boundaries, LX = Places of interest, SS = Water saturated soils, TO = Toponymy, TR = Transportation, VE = Vegetation) , 
#9999999 a generic code 
#and the last digit indicates the geometry (0 = point, 1 = line, 2 = polygon)
#NOTE : VA-T-ON FAIRE UN TRI SUR CERTAINS ATTRIBUTS? EXEMPLE BS_20100009 = BUILDINGS, MAIS POUR INDUSTRX, ON VEUT LES DIFFÉRENTS TYPES (USINE, HOPITAL, ETC.)
   set Param(Layers) {
      BS_1250009_0 ;# Navigation aid, point
      BS_9999999_9 ;# TO DELETE : test to see if fake layer is kept by GenX::CANVECFindFiles
      #BS_1370009_2 ;# Residential area, polygon
      #BS_2000009_0 ;# Parabolic antenna, point
      #BS_2010009_0 ;# Building, point
      #BS_2010009_2 ;# Building, polygon
      #BS_2060009_0 ;# Chimney, point
      #BS_2080009_0 ;# Tank, point
      #BS_2080009_2 ;# Tank, polygon
      #BS_2120009_0 ;# Cross, point
      #BS_2230009_1 ;# Transmission line, line
      #BS_2240009_1 ;# Wall / fence, line
      #BS_2310009_1 ;# Pipeline (Sewage / liquid waste), line
      #BS_2350009_0 ;# Well, point
      #BS_2380009_0 ;# Underground reservoir, point
      #BS_2380009_2 ;# Underground reservoir, polygon
      #BS_2440009_0 ;# Silo, point
      #BS_2530009_0 ;# Tower, point
      #EN_1120009_1 ;# Power transmission line, line
      #EN_1180009_1 ;# Pipeline, line
      #EN_1340009_0 ;# Valve, point
      #EN_1360049_0 ;# Gas and oil facilities, point
      #EN_1360049_2 ;# Gas and oil facilities, polygon
      #EN_1360059_0 ;# Transformer station, point
      #EN_1360059_2 ;# Transformer station, polygon
      #EN_2170009_0 ;# Wind-operated device, point
      #FO_1030009_1 ;# Contour, line
      #FO_1080019_2 ;# Landform, polygon
      #FO_1080029_1 ;# Esker, line
      #FO_1080038_2 ;# Glacial debris undifferentiated, polygon
      #FO_1080049_2 ;# Moraine, polygon
      #FO_1080059_2 ;# Sand, polygon
      #FO_1080069_2 ;# Tundra, polygon
      #FO_1080079_0 ;# Pingo, point
      #FO_1200009_0 ;# Elevation point, point
      #FO_2570009_1 ;# Contour imperial, line
      #FO_2610009_0 ;# Elevation point imperial, point
      #HD_1140009_2 ;# Permanent snow and ice, polygon
      #HD_1450009_0 ;# Manmade hydrographic entity [Geobase], point
      #HD_1450009_1 ;# Manmade hydrographic entity [Geobase], line
      #HD_1450009_2 ;# Manmade hydrographic entity [Geobase], polygon
      #HD_1460009_0 ;# Hydrographic obstacle entity [Geobase], point
      #HD_1460009_1 ;# Hydrographic obstacle entity [Geobase], line
      #HD_1460009_2 ;# Hydrographic obstacle entity [Geobase], polygon
      #HD_1470009_1 ;# Single line watercourse [Geobase], line
      #HD_1480009_2 ;# Waterbody [Geobase], polygon
      #HD_1490009_2 ;# Island [Geobase], polygon
      #IC_1350019_2 ;# Pit, polygon
      #IC_1350029_2 ;# Quarry, polygon
      #IC_1350039_0 ;# Extraction area, point
      #IC_1350039_2 ;# Extraction area, polygon
      #IC_1350049_0 ;# Mine, point
      #IC_1350049_2 ;# Mine, polygon
      #IC_1350059_2 ;# Peat cutting, polygon
      #IC_1360019_2 ;# Domestic waste, polygon
      #IC_1360029_0 ;# Industrial solid waste, point
      #IC_1360029_2 ;# Industrial solid waste, polygon
      #IC_1360039_0 ;# Industrial and commercial area, point
      #IC_1360039_2 ;# Industrial and commercial area, polygon
      #IC_2110009_2 ;# Lumber yard, polygon
      #IC_2360009_2 ;# Auto wrecker, polygon
      #IC_2600009_0 ;# Mining area, point
      #LI_1210009_2 ;# NTS50K boundary polygon, polygon
      #LX_1000019_0 ;# Lookout, point
      #LX_1000019_2 ;# Lookout, polygon
      #LX_1000029_0 ;# Ski centre, point
      #LX_1000039_0 ;# Cemetery, point
      #LX_1000039_2 ;# Cemetery, polygon
      #LX_1000049_2 ;# Fort, polygon
      #LX_1000059_0 ;# Designated area, point
      #LX_1000059_1 ;# Designated area, line
      #LX_1000059_2 ;# Designated area, polygon
      #LX_1000069_0 ;# Marina, point
      #LX_1000079_1 ;# Sport track / Race track, line
      #LX_1000079_2 ;# Sport track / Race track, polygon
      #LX_1000089_2 ;# Golf course, polygon
      #LX_2030009_0 ;# Camp, point
      #LX_2070009_0 ;# Drive-in theatre, point
      #LX_2070009_2 ;# Drive-in theatre, polygon
      #LX_2200009_2 ;# Botanical garden, polygon
      #LX_2210009_0 ;# Shrine, point
      #LX_2220009_0 ;# Historical site / Point of interest, point
      #LX_2260009_2 ;# Amusement park, polygon
      #LX_2270009_2 ;# Park / sports field, polygon
      #LX_2280009_1 ;# Footbridge, line
      #LX_2400009_0 ;# Ruins, point
      #LX_2400009_2 ;# Ruins, polygon
      #LX_2420009_1 ;# Trail, line
      #LX_2460009_2 ;# Stadium, polygon
      #LX_2480009_0 ;# Campground, point
      #LX_2480009_2 ;# Campground, polygon
      #LX_2490009_0 ;# Picnic site, point
      #LX_2490009_2 ;# Picnic site, polygon
      #LX_2500009_0 ;# Golf drining range, point
      #LX_2500009_2 ;# Golf drining range, polygon 
      #LX_2510009_2 ;# Exhibition ground, polygon
      #LX_2560009_2 ;# Zoo, polygon
      #SS_1320019_2 ;# Tundra pond, polygon
      #SS_1320029_2 ;# Palsa bog, polygon
      #SS_1320039_2 ;# Saturated soil, polygon
      #SS_1320049_2 ;# Wetland, polygon
      #SS_1320059_2 ;# Sting bog, polygon
      #TO_1580009_0 ;# Named feature, point
      #TO_1580009_1 ;# Named feature, line
      #TO_1580009_2 ;# Named feature, polygon
      #TR_1020009_1 ;# Railway, line
      #TR_1190009_0 ;# Runway, point
      #TR_1190009_2 ;# Runway, polygon
      #TR_1750009_1 ;# Ferry connection segment [Geobase], line
      #TR_1760009_1 ;# Road segment [Geobase], line
      #TR_1770009_0 ;# Junction [Geobase], point
      #TR_1780009_0 ;# Blocked passage [Geobase], point
      #TR_1790009_0 ;# Toll point [Geobase], point
      #TR_2320009_0 ;# Turntable, point
      #VE_1240009_2 ;# Wooded area, polygon
      VE_2290009_1 };# Cut line, line

#List of priority valies associated with BNDT Layers, to modifiy for CanVec Layers
   set Param(Values)           { 990 970 940 930 920 910 900 890 885 880 875 870 865 860 852 850 840 830 820 810 800 790 780 775 770 765 760 750 740 710 700 690 680 675 670 665 660 650 645 640 630 620 610 605 590 580 570 550 400 350 330 320 310 302 301 300 290 280 271 271 270 270 260 250 248 244 242 240 230 225 220 212 211 210 205 200 190 185 181 180 170 161 160 150 140 130 120 110 100 95 90 85 80 70 65 60 50 45 41 40 35 30 22 21 20 } ;# LUT of values for the NTDB layers to be processed
   #set Param(Values)           { } ;# LUT of values for the CanVec layers to be processed

#List of specific layers from BNDT, to modify with layers from CanVec.
   set Param(Excluded)         { a_cable_l barrier_p cave_en_p contour_l crane_p cross_p cut_lin_l dis_str_p disc_pt_p elev_pt_p ferry_r_l haz_nav_p highw_e_p nav_aid_p nts_lim_l oil_fie_p pond_pa_l shrine_p ski_jum_p spring_p toponym_p trans_l_l tunnel_l turntab_p u_reser_p u_reser_a valve_p wat_dis_a wat_dis_l wat_dis_p well_p } ;# Layers from BNDT ignored for rasterization
   #set Param(Excluded)         {} ;# Layers from CanVec ignored for rasterization
   set Param(LayersPostPro)    { mininga_p railway_l road_l runway_a runway_p sport_t_l buildin_p buildin_a } ;# Layers from BNDT requiring postprocessing
   #set Param(LayersPostPro)    { } ;# Layers from CanVec requiring postprocessing
   set Param(WaterLayers)      { water_b_a n_canal_a fish_po_a } ;# Water layers from BNDT
   #set Param(WaterLayers)      { water_b_a n_canal_a fish_po_a } ;# Water layers from CanVec
   set Param(BufferLayers)     { bridge_l buildin_p road_l } ;# Layers from BNDT required for buffer
   #set Param(BufferLayers)     { } ;# Layers from CanVec required for buffer
   set Param(BufferFuncLayers) { buildin_p buildin_a } ;# Layers from BNDT required for buffer func
   #set Param(BufferFuncLayers) {BS_2010009_0, BS_2010009_2} ;# Layers from CanVec required for buffer func

   set Param(BufferFuncValues) { 1 2 }
   set Param(TEBValues)         { 902 830 830 830 410 440 903 520 520 520 520 820 450 820 820 820 840 820 830 120 530 530 320 410 450 410 320 901 830 360 810 840 440 901 360 410 120 310 440 830 830 450 901 200 901 830 450 430 440 420 430 430 340 100 100 120 320 440 320 320 330 330 410 901 420 110 440 520 420 420 330 330 310 320 350 360 440 830 901 440 320 110 830 530 360 110 420 530 140 110 520 520 110 520 410 110 360 440 330 310 420 420 112 111 110 }

   #TO ADD : 
   #set Param(SmokeValues) : list of values related to the SMOKE output, for use in UrbanX::Values2Smoke

   set Param(VegeFilterType) LOWPASS
   set Param(VegeFilterSize) 99

   set Param(PopFile) /data/cmoex7/afsralx/canyon-urbain/global_data/statcan/traitements/da2001ca_socio_eco.shp
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::AreaDefine>
# Creation : June 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Define raster coverage based on coverage name
#            Set the lat long bounding box for the city specified at launch
#
# Parameters :
#   <Coverage>   : zone to process {MONTREAL VANCOUVER TORONTO OTTAWA WINNIPEG CALGARY HALIFAX REGINA EDMONTON VICTORIA QUEBEC}
#		   default settings on Quebec
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
#
# Goal     : define the UTM Zone
#
# Parameters :
#   <Lat0>    : Lower left latitude
#   <Lon0>    : Lower left longitude
#   <Lat1>    : Top right latitude
#   <Lon1>    : Top right longitude
#   <Res 5>   : Spatial resolution of rasterization and outputs, leave at 5m unless for testing purposes
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::UTMZoneDefine { Lat0 Lon0 Lat1 Lon1 { Res 5 } } {
   variable Param

   set zone     [expr int(ceil((180 + (($Lon1 + $Lon0)/2))/6))]
   set meridian [expr -((180-($zone*6))+3)]

   eval georef create UTMREF \
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

   set xy1 [georef unproject UTMREF $Lat1 $Lon1]
   set xy0 [georef unproject UTMREF $Lat0 $Lon0]

   set Param(Width)  [expr int(ceil(([lindex $xy1 0] - [lindex $xy0 0])/$Res))]
   set Param(Height) [expr int(ceil(([lindex $xy1 1] - [lindex $xy0 1])/$Res))]

   georef define UTMREF -transform [list [lindex $xy0 0] $Res 0.000000000000000 [lindex $xy0 1] 0.000000000000000 $Res]

   GenX::Log INFO "UTM zone is $zone, with central meridian at $meridian. Dimension are $Param(Width)x$Param(Height)"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FindNTSSheets>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Find the NTS Sheets and paths
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::FindNTSSheets { } {
   variable Param
   variable Data

   set missing 0
   set Data(Sheets) {} ;#will contain a list of NTS Sheets, format 999a99
   set Data(Paths)  {} ;#will contain a list of paths, format /data/cmoex7/afsralx/canyon-urbain/global_data/bndt-geonet/999a99
#IS THIS PATH OK?

   set  layers [lindex [ogrfile open SHAPE read $GenX::Path(NTS)/50kindex.shp] 0]
   eval ogrlayer read NTSLAYER $layers

   # Select NTS sheets for the area and consider the buffer distance to account for spatial buffers
   set ids [ogrlayer pick NTSLAYER [list [expr $Param(Lat1)+$Param(Buffer)] [expr $Param(Lon1)+$Param(Buffer)] [expr $Param(Lat1)+$Param(Buffer)] [expr $Param(Lon0)-$Param(Buffer)] [expr $Param(Lat0)-$Param(Buffer)] [expr $Param(Lon0)-$Param(Buffer)] [expr $Param(Lat0)-$Param(Buffer)] [expr $Param(Lon1)+$Param(Buffer)] [expr $Param(Lat1)+$Param(Buffer)] [expr $Param(Lon1)+$Param(Buffer)]] True]
   foreach indexnts $ids {
      set sheet    [string tolower [ogrlayer define NTSLAYER -feature $indexnts snrc]]
      set sheetpath /data/cmoex7/afsralx/canyon-urbain/global_data/bndt-geonet/$sheet
#      set sheetpath /data/cmoex7/afsralx/canyon-urbain/global_data/bndt-geonet/$sheet
      if { [file exists $sheetpath] } {
         set path [glob -nocomplain $sheetpath/*_nts_lim_l.shp]
         lappend Data(Sheets) [lindex [split [file tail $path] _] 0]
         lappend Data(Paths)  $sheetpath
      } else {
         incr missing
         GenX::Log WARNING "NTS sheet $file missing, results will be incomplete"
      }
   }
   GenX::Log INFO "Total number of NTS Sheets included in the processing: [llength  $Data(Sheets)], NTS Sheets to process: $Data(Sheets)"

   ogrlayer free NTSLAYER
   ogrfile close SHAPE

   if { $missing } {
      GenX::Log INFO WARNING "There are $j NTS sheets missing, results will be incomplete"
      GenX::Continue
   }

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::SandwichBNDT>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Rasterize and flatten all NTDB layers
#
# Parameters :
#
# Return:
#
# Remarks : THIS PROC WILL BE DELETED.  TO BE REPLACED BY CANVEC DATA
#
#----------------------------------------------------------------------------
proc UrbanX::SandwichBNDT { } {
   variable Param
   variable Data

   GenX::Procs
   GenX::Log INFO "Generating Sandwich"

   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef UTMREF

   #----- Vérification des shapefiles présents afin de ne pas en manquer un hors-liste
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach file [glob -nocomplain -tails -directory $path *.shp] {
         set file [string range [file rootname [file tail $file]] 7 end]
         if { [lsearch -exact $Param(Layers) $file]==-1 && [lsearch -exact $Param(Excluded) $file]==-1 } {
               GenX::Log WARNING "File '${sheet}_$file.shp' has no priority value and won't be processed"
         }
      }
   }

   set j 0

   #----- Rasterization of NTDB layers
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach file $Param(Layers) value $Param(Values) {
         if { [file exists $path/${sheet}_$file.shp] } {
            set layer [lindex [ogrfile open SHAPE read $path/${sheet}_$file.shp] 0]
            if { [lsearch -exact Param(LayersPostPro) $file]!=-1 } {
               switch $file {
                  "mininga_p" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- mine souterraine ponctuelle convertie en batiment :
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 2) "
                     GenX::Log INFO "Converting and rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] selected features (underground mines) from ${sheet}_$file.shp to priority value 161"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 161
                  }
                  "railway_l" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (rel_ground != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features (excluding railway bridges and tunnels) from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                  }
                  "runway_a" -
                  "runway_p" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (surface != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- unpaved runway converted to priority 41
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (surface = 2) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved runways) from ${sheet}_$file.shp to priority value 41"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 41
                  }
                  "sport_t_l" -
                  "sport_t_a" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 1) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- paved sports tracks converted to priority 271
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 1) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (paved sports tracks) from ${sheet}_$file.shp to priority value 271"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 271
                  }
                  "seapl_b_p" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 1) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- seaplane base mouillage converted to priority 181
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 1) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (seaplane base mouillage) from ${sheet}_$file.shp to priority value 181"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 181
                  }
                  "road_l" {
                     #-----rasterize non-bridge and non-tunnel roads (and non-dam)
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (surface roads) as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- unpaved roads converted to priority 212
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) AND (surface = 2) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved surface roads) from ${sheet}_$file.shp to priority value 212"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 212
                     #----- highways converted to priority 211
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) AND (classifica = 1) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (surface highways) from ${sheet}_$file.shp to priority value 211"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 211
                  }
                  "buildin_p" {
                     #----- divide building types: general, industrial-commercial, day-night 24/7
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- industrial-commercial buildings converted to priority 21
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 21"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 21
                     #----- day-night 24/7 buildings converted to priority 22
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (9,12,17,19,26,39,40)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 22"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 22
                  }
                  "buildin_a" {
                     #----- divide building types: general, industrial-commercial, day-night 24/7
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- industrial-commercial buildings converted to priority 301
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 301"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 301
                     #----- day-night 24/7 buildings converted to priority 302
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (9,12,17,19,26,39,40)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 302"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 302
                  }
                  default {
                     GenX::Log WARNING "Post-processing for $file not found"
                  }
               }
              ogrlayer free VFEATURE2KEEP$j
              incr j
           } else {
               eval ogrlayer read LAYER$j $layer
               GenX::Log INFO "Rasterizing [ogrlayer define LAYER$j -nb] features from file ${sheet}_$file.shp as LAYER$j with priority value $value"
               gdalband gridinterp RSANDWICH LAYER$j $Param(Mode) $value
               ogrlayer free LAYER$j
            }
            ogrfile close SHAPE
         }
      }
   }

   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::AreaDefine>
# Creation : July 2010 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Finds CanVec Files 
#	     Rasterize and flatten CanVec layers
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::SandwichCanVec { } {
   variable Param
   variable Data

   GenX::Procs
   GenX::Log INFO "Generating Sandwich"

   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef UTMREF

puts "Trying to locate Canvec Files"
   # Identify all CanVec layers paths
   set Param(Files) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Layers)]
   #Param(Files) will contain a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp
   #Should we declare an empty list as we did in UrbanX::FindNTSSheets with set Data(Sheets) {} and set Data(Paths) {} ?
puts "Canvec Files were found"
#to modify with GenX::Log INFO ?

   # VEUT-ON REFAIRE CETTE VÉRIFICATION ? ELLE SERAIT UTILE - VOIR APRES
   #----- Vérification des shapefiles présents afin de ne pas en manquer un hors-liste
#   foreach sheet $Data(Sheets) path $Data(Paths) {
#      foreach file [glob -nocomplain -tails -directory $path *.shp] {
#         set file [string range [file rootname [file tail $file]] 7 end]
#         if { [lsearch -exact $Param(Layers) $file]==-1 && [lsearch -exact $Param(Excluded) $file]==-1 } {
#               GenX::Log WARNING "File '${sheet}_$file.shp' has no priority value and won't be processed"
#         }
#      }
#   }
# NEW CODE TO FIX
#   foreach file $Param(Files) {
#      set file [string range [file rootname [file tail $file]] 7 end]
#      if { [lsearch -exact $Param(Layers) $file]==-1 && [lsearch -exact $Param(Excluded) $file]==-1 } {
#            GenX::Log WARNING "File '$Param(Files)' has no priority value and won't be processed"
#      }
#   }


   set j 0

   #----- Rasterization of CanVec layers


#   #----- LUCIE : tentative de remplacer la boucle BNDT pour traitement des données CanVec
   foreach file $Param(Files) value $Param(Values) { ;# peut-être pas bon, car les values correspondent aux layers, non aux files...
      if { [file exists $file] } { ;#valider la syntaxe :  besoin d'autres paramètres?
         set layer [lindex [ogrfile open SHAPE read $file] 0] ;#valider la syntaxe, les paramètres
         if { [lsearch -exact Param(LayersPostPro) $file]!=-1} {
            puts "test de troisième boucle"
#           switch $file { ;# faire un tail sur le nom de file, car ce dernier contient tout le path???
#              AA_9999999_0 { ;# layer 1 from the list Param(LayersPostPro)
#                 ;# insert procedure
#              }
#              AA_9999999_1 { ;# layer 2 from the list Param(LayersPostPro)
#                 ;# insert procedure
#              }
#              default {
#                 GenX::Log WARNING "Post-processing for $file not found"
#              }
#           } ;# end of the switch procedure
#           ogrlayer free VFEATURE2KEEP$j ;# Nécessaire?
#           incr j ;# Nécessaire?
#        } ;# end of the if procedure
        } else {
          puts "test de troisieme boucle"

#           ;# procedure pour les layers n'étant pas inclus dans Param(LayersPostPro)
#           eval ogrlayer read LAYER$j $layer
#           GenX::Log INFO "Rasterizing [ogrlayer define LAYER$j -nb] features from file $file as LAYER$j with priority value $value"
#           gdalband gridinterp RSANDWICH LAYER$j $Param(Mode) $value
#           ogrlayer free LAYER$j
        } ;# end of the else procedure
         ogrfile close SHAPE
      } ;# end of the if procedure
   }
}
#puts "On est passé au travers de la boucle LUCIE"

#   #----- Rasterization of BNDT layers.  TO DELETE
#   foreach sheet $Data(Sheets) path $Data(Paths) {
#      foreach file $Param(Layers) value $Param(Values) {
#         if { [file exists $path/${sheet}_$file.shp] } {
#            set layer [lindex [ogrfile open SHAPE read $path/${sheet}_$file.shp] 0]
#            if { [lsearch -exact Param(LayersPostPro) $file]!=-1 } {
#               switch $file {
#                  "mininga_p" {
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 2) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                     #----- mine souterraine ponctuelle convertie en batiment :
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 2) "
#                     GenX::Log INFO "Converting and rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] selected features (underground mines) from ${sheet}_$file.shp to priority value 161"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 161
#                  }
#                  "railway_l" {
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (rel_ground != 2) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features (excluding railway bridges and tunnels) from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                  }
#                  "runway_a" -
#                  "runway_p" {
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (surface != 2) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                     #----- unpaved runway converted to priority 41
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (surface = 2) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved runways) from ${sheet}_$file.shp to priority value 41"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 41
#                  }
#                  "sport_t_l" -
#                  "sport_t_a" {
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 1) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                     #----- paved sports tracks converted to priority 271
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 1) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (paved sports tracks) from ${sheet}_$file.shp to priority value 271"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 271
#                  }
#                  "seapl_b_p" {
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 1) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                     #----- seaplane base mouillage converted to priority 181
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 1) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (seaplane base mouillage) from ${sheet}_$file.shp to priority value 181"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 181
#                  }
#                  "road_l" {
#                     #-----rasterize non-bridge and non-tunnel roads (and non-dam)
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (surface roads) as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                     #----- unpaved roads converted to priority 212
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) AND (surface = 2) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved surface roads) from ${sheet}_$file.shp to priority value 212"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 212
#                     #----- highways converted to priority 211
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) AND (classifica = 1) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (surface highways) from ${sheet}_$file.shp to priority value 211"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 211
#                  }
#                  "buildin_p" {
#                     #----- divide building types: general, industrial-commercial, day-night 24/7
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                     #----- industrial-commercial buildings converted to priority 21
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 21"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 21
#                     #----- day-night 24/7 buildings converted to priority 22
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (9,12,17,19,26,39,40)) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 22"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 22
#                  }
#                  "buildin_a" {
#                     #----- divide building types: general, industrial-commercial, day-night 24/7
#                    ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
#                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
#                     #----- industrial-commercial buildings converted to priority 301
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 301"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 301
#                     #----- day-night 24/7 buildings converted to priority 302
#                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (9,12,17,19,26,39,40)) "
#                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 302"
#                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 302
#                  }
#                  default {
#                     GenX::Log WARNING "Post-processing for $file not found"
#                  }
#               }
#              ogrlayer free VFEATURE2KEEP$j
#              incr j
#           } else {
#               eval ogrlayer read LAYER$j $layer
#               GenX::Log INFO "Rasterizing [ogrlayer define LAYER$j -nb] features from file ${sheet}_$file.shp as LAYER$j with priority value $value"
#               gdalband gridinterp RSANDWICH LAYER$j $Param(Mode) $value
#               ogrlayer free LAYER$j
#            }
#            ogrfile close SHAPE
#         }
#      }
#   }

#   file delete -force $GenX::Param(OutFile)_sandwich.tif
#   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
#   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
#   gdalfile close FILEOUT
#   gdalband free RSANDWICH

puts "Fin de UrbanX::SandwichCanVec"

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::ScaleBuffers>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Buffers on selected point and line features
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
# Buffers on selected point and line features
proc UrbanX::ScaleBuffers { } {
   variable Param

   if { !$Param(Resolution)<=5 || !$Param(Mode)=="FAST" } {
      return
   }
   GenX::Log INFO "Buffers for scale representation at resolution <= 5m ($Param(BufferLayers))"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband create RBUFFERS $Param(Width) $Param(Height) 1 UInt16
   gdalband define RBUFFERS -georef UTMREF

   set j 0
   foreach sheet $Data(Sheets) {
      foreach layer $Param(BufferLayers) {
         set path [glob -nocomplain $Data(Path$i)${sheet}_$layer.shp]
         if { [file exists $path] } {
            set value [lindex $Param(Values) [lsearch -exact $Param(Layers) $layer]]
            set layer2 [lindex [ogrfile open SHAPE read $path] 0]
            eval ogrlayer read LAYER$j $layer2
            # 1m = 0.000008999280057595392 degre

            swicth $layer {
               "buildin_p" {
                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE function != 4 "
                  ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
                  GenX::Log INFO "Buffering point buildings (except Cabine) to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value
               }
               "road_l" {
                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE (support != 2) AND (surface != 2) "
                  ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
                  GenX::Log INFO "Buffering surface paved roads to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value
                  ogrlayer free LAYER$j ;# CES TROIS PROCHAINES LIGNES SONT-ELLES NÉCESSAIRES ??
                  incr j
                  eval ogrlayer read LAYER$j $layer2
                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE (support != 2) AND (classifica = 1) "
                  ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
                  GenX::Log INFO "Buffering surface highways to 22m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value 211"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) 211
               }
               "bridge_l" {
   #puts stderr 777
                  #ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer " #; that one was already commented
   # La prochaine ligne ne devrait pas être commenté... à mettre à jour en janvier avec le nouveau GEOS et GDAL
   #               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2, comme pour les routes
   #puts stderr 888

                  GenX::Log INFO "Buffering point bridges to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value
               }
               default {
                  GenX::Log WARNING "Buffer processing for $layer not found"
               }
            }
            ogrlayer free LAYER$j
            ogrfile close SHAPE
            incr j
         }
      }
   }
   GenX::Log INFO "Overwriting sandwich with scale representation buffers ($Param(BufferLayers))"

   vector create VCALCU
   vector set VCALCU { 0 605 610 690 700 750 870 } ;#these are priority values which may be overwritten by the buffer
   vexpr RSANDWICH ifelse(((in(RSANDWICH, VCALCU) || RSANDWICH>=920) && RBUFFERS!=0),RBUFFERS,RSANDWICH)

   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RBUFFERS RSANDWICH
   gdalfile close FSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::ChampsBuffers>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Create the fields and building vicinity output using spatial buffers
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::ChampsBuffers { } {
   variable Param
   variable Data

   GenX::Log INFO "Buffer zone processing for grass and fields identification"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]

   gdalband create RBUFFER $Param(Width) $Param(Height) 1 Byte
   eval gdalband define RBUFFER -georef UTMREF
   set i 0
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach layer $Param(BufferFuncLayers) value $Param(BufferFuncValues) {
         set path [glob -nocomplain $path/${sheet}_$layer.shp]
         if { [file exists $path] } {
            set layer2 [lindex [ogrfile open SHAPE read $path] 0]
            eval ogrlayer read LAYER$i $layer2
            if  { $layer=="buildin_a" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM ${sheet}_$layer WHERE function NOT IN (3,4,14,36) "
#               ogrlayer stats LAYER$i -buffer 0.00089993 8
            } elseif  { $layer=="buildin_p" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM ${sheet}_$layer WHERE function NOT IN (3,4,14,36) "
#               ogrlayer stats LAYER$i -buffer 0.000224982 8
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
   gdalband define RBUFFERCUT -georef UTMREF
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
proc UrbanX::PopDens2Builtup { } {
   variable Param
   variable Data

   GenX::Log INFO "Processing population density"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   set layer [lindex [ogrfile open SHAPE read $Param(PopFile)] 0]
   eval ogrlayer read VPOPDENS $layer

   #----- Selecting only the required polygons - next is only useful to improve the speed of the layer substraction
   set features [ogrlayer pick VPOPDENS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   ogrlayer define VPOPDENS -featureselect [list [list index # $features]]

   GenX::Log INFO "Cropping population shapefile and substracting water ($Param(WaterLayers))"

   #----- Both layers must have the same projection!
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach layer $Param(WaterLayers) {
         set path [glob -nocomplain $path/${sheet}_$layer.shp]
         if { [file exists $path] } {
            set water_layer [lindex [ogrfile open SHAPE2 read $path] 0]
            eval ogrlayer read VWATER $water_layer
            ogrlayer stats VPOPDENS -difference VWATER
            ogrfile close SHAPE2
            ogrlayer free VWATER
         }
      }
   }

   GenX::Log INFO "Calculating population density values"
   ogrlayer stats VPOPDENS -transform UTMREF
   foreach n $features {
      set pop  [ogrlayer define VPOPDENS -feature $n TOTPOPUL]
      set geom [ogrlayer define VPOPDENS -geometry $n]
      #ogrgeometry stats $geom -transform UTMREF
      set area  [expr ([ogrgeometry stats $geom -area]/1000000.0)]
      ogrlayer define VPOPDENS -feature $n POP_DENS [expr $area==0.0?0.0:($pop/$area)]
      if {[expr $area==0.0?0.0:($pop/$area)] > 10000000 || [expr $area==0.0?0.0:($pop/$area)] < 0 } {
         set dens [expr $area==0.0?0.0:($pop/$area)]
         GenX::Log WARNING "Potential problem n=$n, pop=$pop, area=$area, dens=$dens"
      }
   }
   unset features

   gdalband create RPOPDENS $Param(Width) $Param(Height) 1 Float32
   eval gdalband define RPOPDENS -georef UTMREF
   gdalband gridinterp RPOPDENS VPOPDENS $Param(Mode) POP_DENS

   file delete -force $GenX::Param(OutFile)_popdens.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens.tif GeoTiff
   gdalband write RPOPDENS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   ogrlayer free VPOPDENS
   ogrfile close SHAPE

   #file delete -force $GenX::Param(OutFile)_popdens.shp
   #ogrfile open VPOPDENSFILE write $GenX::Param(OutFile)_popdens.shp "ESRI Shapefile"
   #ogrlayer write VPOPDENS VPOPDENSFILE
   #ogrfile close VPOPDENSFILE

   GenX::Log INFO "Cookie cutting population density and setting TEB values"
   gdalband create RPOPDENSCUT $Param(Width) $Param(Height) 1 Byte
   gdalband define RPOPDENSCUT -georef UTMREF
   vexpr RTEMP RSANDWICH==605
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<2000),210,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=2000 && RPOPDENS<5000)),220,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=5000 && RPOPDENS<15000),230,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=15000 && RPOPDENS<25000),240,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=25000),250,RPOPDENSCUT)

   gdalband free RSANDWICH ;# move this above once vexpr works
   gdalfile close FSANDWICH
   gdalband free RPOPDENS
   gdalband free RTEMP

   file delete -force $GenX::Param(OutFile)_popdens-builtup.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens-builtup.tif GeoTiff
   gdalband write RPOPDENSCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RPOPDENSCUT
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
proc UrbanX::HeightGain { } {
   variable Param

   GenX::Log INFO "Evaluating height gain"

   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband create RHAUTEURPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURPROJ -georef UTMREF

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
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::BuildingHeight { } {
   variable Param

   GenX::Log INFO "Cookie cutting building heights and adding gain"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RHAUTEURWMASK [gdalfile open FHAUTEUR read $Param(HeightMaskFile)]

   gdalband create RHAUTEURWMASKPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURWMASKPROJ -georef UTMREF

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
# Name     : <UrbanX::Values2TEB>
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
proc UrbanX::Values2TEB { } {
   variable Param

   GenX::Log INFO "Converting values to TEB classes"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup.tif]
   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(OutFile)_hauteur-classes.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Values)
   vector set LUT.TO $Param(TEBValues)
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
# Name     : <UrbanX::Values2Smoke>
# Creation : July 2010 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Applies LUT to all processing result to generate SMOKE classes
#
# Parameters :
#
# Return:
#
# Remarks : Param(SMOKEValues) n'existe pas encore !  Of course, ça plante.
#
#----------------------------------------------------------------------------
proc UrbanX::Values2Smoke { } {
   variable Param

   GenX::Log INFO "Converting values to TEB classes"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   #gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup.tif]
   #gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   #gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(OutFile)_hauteur-classes.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Values)
   vector set LUT.TO $Param(SMOKEValues) ;#SMOKEValues n'existe pas, of course ça plante
   vexpr RTEB lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   #vexpr RTEB ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RTEB)
   #vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
   #vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB.tif GeoTiff
   gdalband write RTEB FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   gdalfile close FILEOUT
   gdalfile close FSANDWICH
   #gdalfile close FPOPDENSCUT
   #gdalfile close FCHAMPS
   #gdalfile close FHAUTEURCLASS
   gdalband free RTEB RSANDWICH ;#RPOPDENSCUT RCHAMPS RHAUTEURCLASS
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
proc UrbanX::Shp2Height { } {
   variable Param

   if { $Param(Shape)=="" } {
      return
   }
   GenX::Log INFO "Converting $GenX::Param(Urban) building shapefile to raster"

   gdalband create RHAUTEURSHP $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURSHP -georef UTMREF

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
# Name     : <UrbanX::Process>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#   <Coverage>   : zone to process {MONTREAL VANCOUVER TORONTO OTTAWA WINNIPEG CALGARY HALIFAX REGINA EDMONTON VICTORIA QUEBEC}
#		   default settings on Quebec
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Process { Coverage } {
   variable Param

puts "Début d'UrbanX"

   UrbanX::AreaDefine    $Coverage
   UrbanX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution)
   UrbanX::FindNTSSheets ;# Useless now since we use GenX::CANVECFindFiles

   #----- Rasterize and flattens all NTDB layers
   #UrbanX::SandwichBNDT
   UrbanX::SandwichCanVec
   #UrbanX::ScaleBuffers

   #-----La rasterization des hauteurs n'a pas vraiment d'affaire dans UrbanX... C'est one-shot.
   #UrbanX::Shp2Height

   #----- Create the fields and building vicinity output using spatial buffers
   #UrbanX::ChampsBuffers
   #UrbanX::PopDens2Builtup
   #UrbanX::HeightGain               ;# Requires UrbanX::ChampsBuffers to have run
   #UrbanX::BuildingHeight           ;# This proc requires UrbanX::PopDens2Builtup and must be used in conjunction with the previous one otherwise $Param(HeightGain) won't be defined

   #----- Applies LUT to all processing results to generate TEB classes. Requires UrbanX::PopDens2Builtup.
   #UrbanX::Values2TEB
   #UrbanX::Values2Smoke


   #----- Optional outputs:
   #UrbanX::VegeMask
   ##UrbanX::TEB2FSTD

puts "Fin d'UrbanX.  Retour à GenPhysX"
}
