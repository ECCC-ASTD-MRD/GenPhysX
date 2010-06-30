#!/bin/sh
# the next line restarts using tclsh \
exec ~afsr005/eer_SPI-7.4.0/tclsh "$0" "$@"
# Previous line uses 7.4.0 and ignores existing SPI_PATH - next line uses existing SPI_PATH if any
#exec ${SPI_PATH:=~afsr005/eer_SPI-7.4.0}/tclsh "$0" "$@"
package require TclData

# remove next line?
#load ~afsr005/eer_SPI-7.3.1/Shared/$env(ARCH)/libTkViewport.so TclData


#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Projet     : CRTI - Canyon Urbain II
# Fichier    : UrbanX.tcl
# Creation   : Janvier 2006- Alexandre Leroux / J.P. Gauthier - CMC/CMOE
# Description: Classification urbaine automatisée, principalement à partir de
#              données CanVec 1:50000, StatCan (population) et bâtiments 3D
#              pour alimenter le modèle TEB
# Parametres :
#
# Retour:
#
# Remarques  :
#
# Modifications :
#   Nom         : -
#   Date        : -
#   Description : -
#
#============================================================================

namespace eval UrbanX { } {
   variable Data
   set Data(UrbanX_version)  v0.1  ;# date = 2009-10-06
   set Data(Zone_name) [lindex $::argv 0]
   #set Data(Zone_name) mtl          ;# values: van, mtl, mtl-small, tor (missing hauteurs), ott (missing hauteurs), win (missing hauteurs), cal (missing hauteurs), hal (missing hauteurs), reg (missing hauteurs), edm (missing hauteurs), vic (missing hauteurs), que (missing hauteurs)

   set Data(Res) 5                  ;# Spatial rez of rasterization and outputs, leave at 5m unless for testing purposes
   set Data(Mode) FAST              ;# Rasterization mode: INCLUDED or FAST - fast is... much much faster!
   set Data(Files)   { pe_snow_a dry_riv_a embankm_a cut_a so_depo_a dam_a sand_a cemeter_a bo_gard_a zoo_a picnic_a park_sp_a am_park_a campgro_a golf_dr_a golf_co_a peat_cu_a stockya_a mininga_a fort_a ruins_a exhib_g_a oil_fac_a auto_wr_a lu_yard_a slip_a drivein_a water_b_a rock_le_a trans_s_a vegetat_a wetland_a li_depo_a fish_po_a lookout_a tank_a stadium_a runway_a breakwa_l esker_l dyke_le_l seawall_l n_canal_a builtup_a water_c_l ford_l wall_fe_l pipelin_l dam_l haz_air_l conveyo_l conduit_l railway_l pp_buildin_a pp_buildin_a buildin_a wharf_l lock_ga_l pp_sports_t_l pp_sports_t_a sport_t_l sport_t_a so_depo_p n_canal_l haz_air_p marina_p dam_p trail_l wind_de_p crane_l li_road_l pp_road_l pp_road_l road_l bridge_l footbri_l lock_ga_p ford_p pp_seapl_b_p seapl_b_p boat_ra_p pp_mininga_p mininga_p hi_site_p lookout_p oil_fac_p p_anten_p ruins_p silo_p campgro_p camp_p picnic_p drivein_p cemeter_p tank_p ski_cen_p trans_s_p li_depo_p pp_runway_a+p runway_p chimney_p tower_p pp_buildin_p pp_buildin_p buildin_p } ;# NTDB layers to be processed
   set Data(Values)  { 990 970 940 930 920 910 900 890 885 880 875 870 865 860 852 850 840 830 820 810 800 790 780 775 770 765 760 750 740 710 700 690 680 675 670 665 660 650 645 640 630 620 610 605 590 580 570 550 400 350 330 320 310 302 301 300 290 280 271 271 270 270 260 250 248 244 242 240 230 225 220 212 211 210 205 200 190 185 181 180 170 161 160 150 140 130 120 110 100 95 90 85 80 70 65 60 50 45 41 40 35 30 22 21 20 } ;# LUT of values for the NTDB layers to be processed

#---- Autres variables importantes crees ailleurs:
# Data(Excluded) dans Sandwich
# Data(TEB_values) dans Values2TEB
# Data(Width) dans DefineZone
# Data(Height) dans DefineZone
# Data(X0) dans DefineZone
# Data(Y0) dans DefineZone
# Data(Sheet_names$i) dans FindPaths
# Data(Paths$i) dans FindPaths
# Data(Nombre_feuillets) dans FindPaths
# Data(HeightGain) dans HeightGain
}

proc UrbanX::AreaParameters { } {
# Set the lat long bounding box for the city specified at launch
   variable Data
   set Data(HeightGain) 0 ;# default value if proc HeightGain is not ran
   if { $Data(Zone_name) == "van" } {
      set Data(maxlon)   -122.50
      set Data(maxlat)    49.40
      set Data(minlon)   -123.30
      set Data(minlat)    49.01
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong_wmask
   } elseif { $Data(Zone_name) == "mtl" } {
      set Data(maxlon)   -73.35
      set Data(maxlat)    45.70
      set Data(minlon)   -73.98
      set Data(minlat)    45.30
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped_wmask
   } elseif { $Data(Zone_name) == "mtl-small" } {
      set Data(maxlon)   -73.70 ;# small pour tests
      set Data(maxlat)    45.52 ;# small pour tests
      set Data(minlon)   -73.72 ;# small pour tests
      set Data(minlat)    45.44 ;# small pour tests
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "tor" } {
      set Data(maxlon)   -79.12
      set Data(maxlat)    43.92
      set Data(minlon)   -79.85
      set Data(minlat)    43.49
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "ott" } {
      set Data(maxlon)   -75.56
      set Data(maxlat)    45.52
      set Data(minlon)   -75.87
      set Data(minlat)    45.30
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
   } elseif { $Data(Zone_name) == "win" } {
      set Data(maxlon)   -96.95
      set Data(maxlat)    49.98
      set Data(minlon)   -97.34
      set Data(minlat)    49.75
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "cal" } {
      set Data(maxlon)   -113.90
      set Data(maxlat)    51.18
      set Data(minlon)   -114.28
      set Data(minlat)    50.87
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "hal" } {
      set Data(maxlon)   -63.36
      set Data(maxlat)    44.83
      set Data(minlon)   -63.80
      set Data(minlat)    44.56
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "reg" } {
      set Data(maxlon)   -104.50
      set Data(maxlat)    50.54
      set Data(minlon)   -104.72
      set Data(minlat)    50.38
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "edm" } {
      set Data(maxlon)   -113.19
      set Data(maxlat)    53.70
      set Data(minlon)   -113.73
      set Data(minlat)    53.38
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "vic" } {
      set Data(maxlon)   -123.22
      set Data(maxlat)    48.55
      set Data(minlon)   -123.54
      set Data(minlat)    48.39
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } elseif { $Data(Zone_name) == "que" } {
      set Data(maxlon)   -71.10
      set Data(maxlat)    46.94
      set Data(minlon)   -71.47
      set Data(minlat)    46.68
      set Data(Hauteur_file) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
      set Data(Hauteur_file_wmask) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
   } else {
      puts "* *ALERT* AREA $Data(Zone_name) NOT DEFINED *"
   }
}

proc UrbanX::FindZoneUTM { } {
# Find the UTM zone for the city
   variable Data
   puts "UrbanX Version $Data(UrbanX_version)"
   # Calcul de la zone UTM selon le centre de la zone de traitement
   set Data(Zone_UTM) [expr int(ceil((180 + (($Data(maxlon) + $Data(minlon))/2))/6))]
   set Data(Central_meridian) [expr -((180 - ($Data(Zone_UTM)*6)) +3)]
   puts "Area name: $Data(Zone_name), UTM zone: $Data(Zone_UTM), Central meridian: $Data(Central_meridian), Resolution: $Data(Res) m, Rasterization mode: $Data(Mode)"
}

proc UrbanX::DefineZone { } {
   variable Data
# Create geographic reference and set output size parameters

##### THESE ARE THE OLD WAY TO DO IT ---- ERASE!
#   georef create UTMREF
#   eval georef define UTMREF -projection \{PROJCS\[\"NAD83 UTM, Zone $Data(Zone_UTM) North, Meter\",GEOGCS\[\"NAD83\",DATUM\[\"North_American_Datum_1983\",SPHEROID\[\"GRS 1980\",6378137,298.257222101\]\],PRIMEM\[\"Greenwich\",0\],UNIT\[\"degree\",0.0174532925199433\]\],PROJECTION\[\"Transverse_Mercator\"\],PARAMETER\[\"latitude_of_origin\",0\],PARAMETER\[\"central_meridian\",$Data(Central_meridian)\],PARAMETER\[\"scale_factor\",0.9996\],PARAMETER\[\"false_easting\",500000\],PARAMETER\[\"false_northing\",0\],UNIT\[\"Meter\",1\]\]\}

   eval georef create UTMREF \
      \{PROJCS\[\"WGS_1984_UTM_Zone_$Data(Zone_UTM)N\",\
         GEOGCS\[\"GCS_WGS_1984\",\
            DATUM\[\"D_WGS_1984\",\
               SPHEROID\[\"WGS_1984\",6378137.0,298.257223563\]\],\
            PRIMEM\[\"Greenwich\",0.0\],\
            UNIT\[\"Degree\",0.0174532925199433\]\],\
         PROJECTION\[\"Transverse_Mercator\"\],\
         PARAMETER\[\"False_Easting\",500000.0\],\
         PARAMETER\[\"False_Northing\",0.0\],\
         PARAMETER\[\"Central_Meridian\",$Data(Central_meridian)\],\
         PARAMETER\[\"Scale_Factor\",0.9996\],\
         PARAMETER\[\"Latitude_Of_Origin\",0.0\],\
         UNIT\[\"Meter\",1.0\]\]\}
   set xy [georef unproject UTMREF $Data(maxlat) $Data(maxlon)]
   set xy2 [georef unproject UTMREF $Data(minlat) $Data(minlon)]
   set Data(Width) [expr int(ceil(([lindex $xy 0] - [lindex $xy2 0])/$Data(Res)))]
   set Data(Height) [expr int(ceil(([lindex $xy 1] - [lindex $xy2 1])/$Data(Res)))]
   set Data(X0) [lindex $xy2 0]
   set Data(Y0) [lindex $xy 1]
   puts "Processing zone with Width = $Data(Width), Height = $Data(Height)"
   puts "Processing zone with upper-left corner: X0 = $Data(X0), Y0 = $Data(Y0)"
}

proc UrbanX::FindNTSSheets { } {
# Find the NTS sheets for the area of interest
   variable Data
   set Data(NTS_index) /cnfs/ops/production/cmoe/geo/NTS/50kindex.shp
   set nts_layer [lindex [ogrfile open SHAPE read $Data(NTS_index)] 0]
   eval ogrlayer read NTSLAYER $nts_layer
   # next line includes about 200m buffers to account for off-zone buffers which would influence results
   set Data(Sheets_id) [ogrlayer pick NTSLAYER [list [expr ($Data(maxlat)+0.001)] [expr ($Data(maxlon)+0.001)] [expr ($Data(maxlat)+0.001)] [expr ($Data(minlon)-0.001)] [expr ($Data(minlat)-0.001)] [expr ($Data(minlon)-0.001)] [expr ($Data(minlat)-0.001)] [expr ($Data(maxlon)+0.001)] [expr ($Data(maxlat)+0.001)] [expr ($Data(maxlon)+0.001)]] True]
   foreach indexnts $Data(Sheets_id) {
      lappend Data(Sheets) [ogrlayer define NTSLAYER -feature $indexnts snrc]
   }
   ogrlayer free NTSLAYER
   ogrfile close SHAPE
}

proc UrbanX::FindPaths { } {
# Sets the NTDB files paths
   variable Data
   set j 0
   set i 0
   foreach file $Data(Sheets) {
      set file [string tolower $file]
      set Data(Path$i)    /data/cmoex7/afsralx/canyon-urbain/global_data/bndt-geonet/$file/
      if { [file exists $Data(Path$i)] } {
         set path [glob -nocomplain $Data(Path$i)/*_nts_lim_l.shp]
         set Data(Sheet_names$i)   [lindex [split [file tail $path] _] 0]
         puts "NTS Sheet to process: $Data(Sheet_names$i)"
         incr i
      } else {
         incr j
         puts "\033\[01;31m** WARNING ** NTS SHEET $file MISSING ** RESULTS WILL BE INCOMPLETE\033\[0m"
#         puts "** WARNING ** NTS SHEET $file MISSING ** RESULTS WILL BE INCOMPLETE"
      }
   }
   set Data(Nombre_feuillets) $i
   puts "Total number of NTS Sheets included in the processing: $Data(Nombre_feuillets)"
   if { $j > 0 } {
      puts "\n******* THERE ARE $j NTS SHEETS MISSING ** RESULTS WILL BE INCOMPLETE *******\n"
   }
}

proc UrbanX::SandwichBNDT { } {
# Rasterize and flatten all NTDB layers
   variable Data
   puts "\nGenerating Sandwich"
   set Data(Excluded) { a_cable_l barrier_p cave_en_p contour_l crane_p cross_p cut_lin_l dis_str_p disc_pt_p elev_pt_p ferry_r_l haz_nav_p highw_e_p nav_aid_p nts_lim_l oil_fie_p pond_pa_l shrine_p ski_jum_p spring_p toponym_p trans_l_l tunnel_l turntab_p u_reser_p u_reser_a valve_p wat_dis_a wat_dis_l wat_dis_p well_p } ;# Layers ignored for rasterization

   gdalband create RSANDWICH $Data(Width) $Data(Height) 1 UInt16
   eval gdalband define RSANDWICH -georef UTMREF
   gdalband define RSANDWICH -transform [list $Data(X0) $Data(Res) 0.000000000000000 $Data(Y0) 0.000000000000000 -$Data(Res)]

   # Vérification des shapefiles présents afin de ne pas en manquer un hors-liste
   for { set i 0 } { $i < $Data(Nombre_feuillets) } {  incr i } {
      set shp_filenames [glob -nocomplain -tails -directory $Data(Path$i) *.shp]
      foreach file $shp_filenames {
         set file [string range [file rootname [file tail $file]] 7 end]
         if { [lsearch -exact $Data(Files) $file]==-1 } {
            if { [lsearch -exact $Data(Excluded) $file]==-1 } {
               puts "\n\033\[01;31m*** WARNING *** FILE NAMED '$Data(Sheet_names$i)_$file.shp' HAS NO PRIORITY VALUE AND WON'T BE PROCESSED ****\033\[0m\n"
            }
         }
      }
   }

   # Rasterization of NTDB layers
   set Data(LayersPostPro) { mininga_p railway_l road_l runway_a runway_p sport_t_l buildin_p buildin_a } ;# layers requiring postprocessing
   set j 0
   for { set i 0 } { $i < $Data(Nombre_feuillets) } { incr i } {
      foreach file $Data(Files) value $Data(Values) {
         set path [glob -nocomplain $Data(Path$i)/$Data(Sheet_names$i)_$file.shp]
         if { [file exists $path] } {
            set layer [lindex [ogrfile open SHAPE read $path] 0]
            if { [lsearch -exact $Data(LayersPostPro) $file]!=-1 } {
               if  { $file=="mininga_p" } {
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (type != 2) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file $Data(Sheet_names$i)_$file.shp as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
                  # mine souterraine ponctuelle convertie en batiment :
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (type = 2) "
                  puts "Converting and rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] selected features (underground mines) from $Data(Sheet_names$i)_$file.shp to priority value 161"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 161
               } elseif  { $file=="railway_l" } {
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (rel_ground != 2) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features (excluding railway bridges and tunnels) from file $Data(Sheet_names$i)_$file.shp as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
               } elseif  { $file=="runway_a" || $file=="runway_p" } {
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (surface != 2) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file $Data(Sheet_names$i)_$file.shp as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
                  # unpaved runway converted to priority 41
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (surface = 2) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved runways) from $Data(Sheet_names$i)_$file.shp to priority value 41"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 41
               } elseif  { $file=="sport_t_l" || $file=="sport_t_a" } {
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (type != 1) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file $Data(Sheet_names$i)_$file.shp as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
                  # paved sports tracks converted to priority 271
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (type = 1) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (paved sports tracks) from $Data(Sheet_names$i)_$file.shp to priority value 271"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 271
               } elseif  { $file=="seapl_b_p" } {
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (type != 1) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file $Data(Sheet_names$i)_$file.shp as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
                  # seaplane base mouillage converted to priority 181
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (type = 1) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (seaplane base mouillage) from $Data(Sheet_names$i)_$file.shp to priority value 181"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 181
               } elseif  { $file=="road_l" } {
                  # rasterize non-bridge and non-tunnel roads (and non-dam)
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (support != 2) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file $Data(Sheet_names$i)_$file.shp (surface roads) as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
                  # unpaved roads converted to priority 212
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (support != 2) AND (surface = 2) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved surface roads) from $Data(Sheet_names$i)_$file.shp to priority value 212"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 212
                  # highways converted to priority 211
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (support != 2) AND (classifica = 1) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (surface highways) from $Data(Sheet_names$i)_$file.shp to priority value 211"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 211
               } elseif  { $file=="buildin_p" } {
                  # divide building types: general, industrial-commercial, day-night 24/7
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file $Data(Sheet_names$i)_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
                  # industrial-commercial buildings converted to priority 21
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from $Data(Sheet_names$i)_$file.shp to priority value 21"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 21
                  # day-night 24/7 buildings converted to priority 22
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (function IN (9,12,17,19,26,39,40)) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from $Data(Sheet_names$i)_$file.shp to priority value 22"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 22
               } elseif  { $file=="buildin_a" } {
                  # divide building types: general, industrial-commercial, day-night 24/7
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
                  puts "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file $Data(Sheet_names$i)_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) $value
                  # industrial-commercial buildings converted to priority 301
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from $Data(Sheet_names$i)_$file.shp to priority value 301"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 301
                  # day-night 24/7 buildings converted to priority 302
                  ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$file WHERE (function IN (9,12,17,19,26,39,40)) "
                  puts "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from $Data(Sheet_names$i)_$file.shp to priority value 302"
                  gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Data(Mode) 302
               } else {
                  puts "** *BUG* Post-processing for $file not found **"
               }
               ogrlayer free VFEATURE2KEEP$j
               incr j
            } else {
               eval ogrlayer read LAYER$j $layer
               puts "Rasterizing [ogrlayer define LAYER$j -nb] features from file $Data(Sheet_names$i)_$file.shp as LAYER$j with priority value $value"
               gdalband gridinterp RSANDWICH LAYER$j $Data(Mode) $value
               ogrlayer free LAYER$j
            }
            ogrfile close SHAPE
         }
      }
   }
   puts "Writing results to $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RSANDWICH
}

proc UrbanX::ScaleBuffers { } {
# Buffers on selected point and line features
   variable Data
   set Data(Buffer_layers)   { bridge_l buildin_p road_l }
   puts "\nBuffers for scale representation at resolution <= 5m ($Data(Buffer_layers))"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif]
   gdalband create RBUFFERS $Data(Width) $Data(Height) 1 UInt16
   eval gdalband define RBUFFERS -georef [gdalband define RSANDWICH -georef]
   set i 0
   set j 0
   foreach sheet $Data(Sheets) {
      foreach layer $Data(Buffer_layers) {
         set path [glob -nocomplain $Data(Path$i)$Data(Sheet_names$i)_$layer.shp]
         if { [file exists $path] } {
            set value [lindex $Data(Values) [lsearch -exact $Data(Files) $layer]]
            set layer2 [lindex [ogrfile open SHAPE read $path] 0]
            eval ogrlayer read LAYER$j $layer2
            # 1m = 0.000008999280057595392 degre
puts stderr $layer
set layer bug
puts "ATTENTION - BUFFERS IGNORÉS"
            if  { $layer=="buildin_p" }  {
               ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$layer WHERE function != 4 "
               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
               puts "Buffering point buildings (except Cabine) to 12m: [ogrlayer define LAYER$j -nb] features from $Data(Sheet_names$i)_$layer.shp as LAYER$j with buffer value $value"
               gdalband gridinterp RBUFFERS LAYER$j $Data(Mode) $value
            } elseif  { $layer=="road_l" }  {
               ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$layer WHERE (support != 2) AND (surface != 2) "
               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
               puts "Buffering surface paved roads to 12m: [ogrlayer define LAYER$j -nb] features from $Data(Sheet_names$i)_$layer.shp as LAYER$j with buffer value $value"
               gdalband gridinterp RBUFFERS LAYER$j $Data(Mode) $value
               ogrlayer free LAYER$j ;# CES TROIS PROCHAINES LIGNES SONT-ELLES NÉCESSAIRES ??
               incr j
               eval ogrlayer read LAYER$j $layer2
               ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$layer WHERE (support != 2) AND (classifica = 1) "
               ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
               puts "Buffering surface highways to 22m: [ogrlayer define LAYER$j -nb] features from $Data(Sheet_names$i)_$layer.shp as LAYER$j with buffer value 211"
               gdalband gridinterp RBUFFERS LAYER$j $Data(Mode) 211
            } elseif  { $layer=="bridge_l" }  {
#puts stderr 777
               #ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM $Data(Sheet_names$i)_$layer " #; that one was already commented
# La prochaine ligne ne devrait pas être commenté... à mettre à jour en janvier avec le nouveau GEOS et GDAL
#               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2, comme pour les routes
#puts stderr 888

               puts "Buffering point bridges to 12m: [ogrlayer define LAYER$j -nb] features from $Data(Sheet_names$i)_$layer.shp as LAYER$j with buffer value $value"
               gdalband gridinterp RBUFFERS LAYER$j $Data(Mode) $value
            } else {
               puts "\n** *BUG* Buffer processing for $layer not found **\n"
            }
            ogrlayer free LAYER$j
            ogrfile close SHAPE
            incr j
         }
      }
      incr i
   }
   puts "OVERWRITING Sandwich with scale representation buffers ($Data(Buffer_layers))"

   vector create VCALCU
   vector set VCALCU { 0 605 610 690 700 750 870 } ;#these are priority values which may be overwritten by the buffer
   vexpr RSANDWICH ifelse(((in(RSANDWICH, VCALCU) || RSANDWICH>=920) && RBUFFERS!=0),RBUFFERS,RSANDWICH)

   puts "OVERWRITING results to $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RBUFFERS
   gdalband free RSANDWICH
   gdalfile close FSANDWICH
}

proc UrbanX::ChampsBuffers { } {
# Create the fields and building vicinity output using spatial buffers
   variable Data
   puts "\nBuffer zone processing for grass and fields identification"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif]
   set Data(Buffer_function)   { buildin_p buildin_a }
   set Data(Buffer_function_values)   { 1 2 }
   gdalband create RBUFFER $Data(Width) $Data(Height) 1 Byte
   eval gdalband define RBUFFER -georef [gdalband define RSANDWICH -georef]
   set i 0
   foreach sheet $Data(Sheets) {
      foreach layer $Data(Buffer_function) value $Data(Buffer_function_values) {
         set path [glob -nocomplain $Data(Path$i)$Data(Sheet_names$i)_$layer.shp]
         if { [file exists $path] } {
            set layer2 [lindex [ogrfile open SHAPE read $path] 0]
            eval ogrlayer read LAYER$i $layer2
            if  { $layer=="buildin_a" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM $Data(Sheet_names$i)_$layer WHERE function NOT IN (3,4,14,36) "
puts "BUFFERS DON'T WORK ANYMORE"
# un-comment next line
#               ogrlayer stats LAYER$i -buffer 0.00089993 8
            } elseif  { $layer=="buildin_p" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM $Data(Sheet_names$i)_$layer WHERE function NOT IN (3,4,14,36) "
puts "BUFFERS DON'T WORK ANYMORE"
# un-comment next line
#               ogrlayer stats LAYER$i -buffer 0.000224982 8
            }
            puts "Buffering [ogrlayer define LAYER$i -nb] features from $Data(Sheet_names$i)_$layer.shp as LAYER$i with buffer value $value"
            gdalband gridinterp RBUFFER LAYER$i $Data(Mode) $value
            ogrlayer free LAYER$i
            ogrfile close SHAPE
         }
      }
      incr i
   }
   puts "Cookie cutting grass and fields buffers and setting grass and fields and building vicinity values"
   gdalband create RBUFFERCUT $Data(Width) $Data(Height) 1 UInt16
   gdalband define RBUFFERCUT -georef [gdalband define RSANDWICH -georef]
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER==0)),820,RBUFFERCUT)
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER!=0)),510,RBUFFERCUT)

   #----- On sauvegarde le tout - Next 5 lines are commented since writing results to file is unrequired
   #puts "Writing results to $Data(Zone_name)_champs_buf100ma+25mp_$Data(Res)m_$Data(UrbanX_version).tif"
   #file delete -force ./$Data(Zone_name)_champs_buf100ma+25mp_$Data(Res)m_$Data(UrbanX_version).tif
   #gdalfile open FILEOUT write ./$Data(Zone_name)_champs_buf100ma+25mp_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   #gdalband write RBUFFER FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   #gdalfile close FILEOUT
   gdalband free RBUFFER
   gdalband free RSANDWICH
   gdalfile close FSANDWICH

   puts "Writing results to $Data(Zone_name)_champs-only+building-vicinity_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_champs-only+building-vicinity_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_champs-only+building-vicinity_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RBUFFERCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RBUFFERCUT
}

proc UrbanX::PopDens2Builtup { } {
   variable Data
   set Data(Pop_file) /data/cmoex7/afsralx/canyon-urbain/global_data/statcan/traitements/da2001ca_socio_eco.shp
   set Data(Water_layers) { water_b_a n_canal_a fish_po_a }
   puts "\nProcessing population density using file: $Data(Pop_file)"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif]
   set layer [lindex [ogrfile open SHAPE read $Data(Pop_file)] 0]
   eval ogrlayer read VPOPDENS $layer

   # Selecting only the required polygons - next is only useful to improve the speed of the layer substraction
   set features [ogrlayer pick VPOPDENS [list $Data(maxlat) $Data(maxlon) $Data(maxlat) $Data(minlon) $Data(minlat) $Data(minlon) $Data(minlat) $Data(maxlon) $Data(maxlat) $Data(maxlon)] True]
   ogrlayer define VPOPDENS -featureselect [list [list index # $features]]


   puts "Cropping population shapefile and substracting water ($Data(Water_layers))"
   # Both layers must have the same projection!
   for { set i 0 } { $i < $Data(Nombre_feuillets) } { incr i } {
      foreach layer $Data(Water_layers) {
         set path [glob -nocomplain $Data(Path$i)$Data(Sheet_names$i)_$layer.shp]
         if { [file exists $path] } {
            set water_layer [lindex [ogrfile open SHAPE2 read $path] 0]
            eval ogrlayer read VWATER $water_layer
            ogrlayer stats VPOPDENS -difference VWATER
            ogrfile close SHAPE2
            ogrlayer free VWATER
         }
      }
   }

   puts "Calculating population density values"
# next line crashes most of the time
   ogrlayer stats VPOPDENS -transform UTMREF
   foreach n $features {
      set pop   [ogrlayer define VPOPDENS -feature $n TOTPOPUL]
      set geom [ogrlayer define VPOPDENS -geometry $n]
      #ogrgeometry stats $geom -transform UTMREF
      set area  [expr ([ogrgeometry stats $geom -area]/1000000.0)]
      ogrlayer define VPOPDENS -feature $n POP_DENS [expr $area==0.0?0.0:($pop/$area)]
      if {[expr $area==0.0?0.0:($pop/$area)] > 10000000 || [expr $area==0.0?0.0:($pop/$area)] < 0 } {
         set dens [expr $area==0.0?0.0:($pop/$area)]
         puts "\n\033\[01;31m** POTENTIAL ERROR** n=$n, pop=$pop, area=$area, dens=$dens\n\033\[0m"
      }
   }
   unset features
   gdalband create RPOPDENS $Data(Width) $Data(Height) 1 Float32
   eval gdalband define RPOPDENS -georef [gdalband define RSANDWICH -georef]
   gdalband gridinterp RPOPDENS VPOPDENS $Data(Mode) POP_DENS
   puts "Writing results to $Data(Zone_name)_popdens_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_popdens_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_popdens_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RPOPDENS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   ogrlayer free VPOPDENS
   ogrfile close SHAPE

   #puts "Write results to $Data(Zone_name)_popdens_$Data(UrbanX_version).shp"
   #file delete -force ./$Data(Zone_name)_popdens_$Data(UrbanX_version).shp
   #ogrfile open VPOPDENSFILE write ./$Data(Zone_name)_popdens_$Data(UrbanX_version).shp "ESRI Shapefile"
   #ogrlayer write VPOPDENS VPOPDENSFILE
   #ogrfile close VPOPDENSFILE

   puts "Cookie cutting population density and setting TEB values"
   gdalband create RPOPDENSCUT $Data(Width) $Data(Height) 1 Byte
   gdalband define RPOPDENSCUT -georef [gdalband define RSANDWICH -georef]
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


   puts "Writing results to $Data(Zone_name)_popdens-builtup_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_popdens-builtup_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_popdens-builtup_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RPOPDENSCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RPOPDENSCUT
}

proc UrbanX::HeightGain { } {
# Estimate DEM height gain based on...
   variable Data
   puts "\nEvaluating height gain"
   gdalband read RCHAMPS [gdalfile open FCHAMPS read $Data(Zone_name)_champs-only+building-vicinity_$Data(Res)m_$Data(UrbanX_version).tif]
   gdalband create RHAUTEURPROJ $Data(Width) $Data(Height) 1 Float32
   gdalband define RHAUTEURPROJ -georef [gdalband define RCHAMPS -georef]
   # La vérification pourrait être fait dans un proc avec vérification des 4 points de la source
   gdalband read RHAUTEUR [gdalfile open FHAUTEUR read $Data(Hauteur_file)]
   gdalband stats RHAUTEURPROJ -nodata -9999
   gdalband gridinterp RHAUTEURPROJ RHAUTEUR
   gdalband free RHAUTEUR
   gdalfile close FHAUTEUR
   set min [gdalband stats RHAUTEURPROJ -min]
   if { [lindex $min 0] == -9999 } {
      puts "\n\033\[01;31m** WARNING ** Heights does NOT overlap entirely the area ** Average won't be good.\nAbsent values are set to 0.\033\[0m\n"
      #puts "\n** WARNING ** Heights does NOT overlap entirely the area ** Average won't be good.\nAbsent values are set to 0.\n"
      vexpr RHAUTEURPROJ ifelse(RHAUTEURPROJ==-9999,0,RHAUTEURPROJ)
   }
   vexpr RHEIGHTCHAMPS ifelse(RCHAMPS==820,RHAUTEURPROJ,0)
   gdalband free RHAUTEURPROJ

   # Average est calculé (pour le moment) que pour les valeurs != 0 dans le code en C
   # Pour avec les 0: set Data(HeightGain) [vexpr XX savg(RHEIGHTCHAMPS)]
   gdalband stats RHEIGHTCHAMPS -nodata 0
   set Data(HeightGain) [gdalband stats RHEIGHTCHAMPS -avg]
   puts "Average gain calculated over defined areas = $Data(HeightGain)"
   if {($Data(HeightGain)>=10 || $Data(HeightGain)<=-10) || $Data(HeightGain)==0 } {
      puts "\n\033\[01;31m** ** WARNING ** Strange value for Data(HeightGain): $Data(HeightGain) **\033\[0m\n"
      #puts "\n** ** WARNING ** Strange value for Data(HeightGain): $Data(HeightGain) **\n"
   }
   puts "Writing results to $Data(Zone_name)_hauteur-champs_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_hauteur-champs_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_hauteur-champs_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RHEIGHTCHAMPS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT

   gdalband free RCHAMPS
   gdalfile close FCHAMPS
   gdalband free RHEIGHTCHAMPS
}

proc UrbanX::BuildingHeight { } {
   variable Data
   puts "\nCookie cutting building heights and adding gain"
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif]
   gdalband read RHAUTEURWMASK [gdalfile open FHAUTEUR read $Data(Hauteur_file_wmask)]

   # Ces deux lignes sont inutiles car le vexpr va créer RHAUTEURCLASS
#   gdalband create RHAUTEURCLASS $Data(Width) $Data(Height) 1 UInt16
#   gdalband define RHAUTEURCLASS -georef [gdalband define RSANDWICH -georef]
   gdalband create RHAUTEURWMASKPROJ $Data(Width) $Data(Height) 1 Float32
   gdalband define RHAUTEURWMASKPROJ -georef [gdalband define RSANDWICH -georef]

   gdalband gridinterp RHAUTEURWMASKPROJ RHAUTEURWMASK
   gdalband free RHAUTEURWMASK
   gdalfile close FHAUTEUR
   vexpr RHAUTEURWMASKPROJ RHAUTEURWMASKPROJ+$Data(HeightGain)

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

#   puts "Writing results to $Data(Zone_name)_hauteur-builtup+building_$Data(Res)m_$Data(UrbanX_version).tif"
#   file delete -force ./$Data(Zone_name)_hauteur-builtup+building_$Data(Res)m_$Data(UrbanX_version).tif
#   gdalfile open FILEOUT write ./$Data(Zone_name)_hauteur-builtup+building_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
#   gdalband write RHAUTEURCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
#   gdalfile close FILEOUT
   puts "Writing results to $Data(Zone_name)_hauteur-classes_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_hauteur-classes_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_hauteur-classes_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RHAUTEURCLASS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RHAUTEURCLASS
   gdalband free RSANDWICH
   gdalfile close FSANDWICH
}

proc UrbanX::Values2TEB { } {
# Applies LUT to all processing results to generate TEB classes
   variable Data
   puts "\nFlattening all raster layers with TEB values"
   set Data(TEB_values) { 902 830 830 830 410 440 903 520 520 520 520 820 450 820 820 820 840 820 830 120 530 530 320 410 450 410 320 901 830 360 810 840 440 901 360 410 120 310 440 830 830 450 901 200 901 830 450 430 440 420 430 430 340 100 100 120 320 440 320 320 330 330 410 901 420 110 440 520 420 420 330 330 310 320 350 360 440 830 901 440 320 110 830 530 360 110 420 530 140 110 520 520 110 520 410 110 360 440 330 310 420 420 112 111 110 }
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $Data(Zone_name)_popdens-builtup_$Data(Res)m_$Data(UrbanX_version).tif]
   gdalband read RCHAMPS [gdalfile open FCHAMPS read $Data(Zone_name)_champs-only+building-vicinity_$Data(Res)m_$Data(UrbanX_version).tif]
   gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $Data(Zone_name)_hauteur-classes_$Data(Res)m_$Data(UrbanX_version).tif]
   # Ces deux lignes sont inutiles car le vexpr va créer RTEB
#   gdalband create RTEB $Data(Width) $Data(Height) 1 UInt16
#   gdalband define RTEB -georef [gdalband define RSANDWICH -georef]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Data(Values)
   vector set LUT.TO $Data(TEB_values)
   vexpr RTEB lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   vexpr RTEB ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RTEB)
   vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
   vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RTEB)

   puts "Writing results to $Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RTEB FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RTEB
   gdalband free RSANDWICH
   gdalfile close FSANDWICH
   gdalband free RPOPDENSCUT
   gdalfile close FPOPDENSCUT
   gdalband free RCHAMPS
   gdalfile close FCHAMPS
   gdalband free RHAUTEURCLASS
   gdalfile close FHAUTEURCLASS
}

proc UrbanX::VegeMask { } {
# Generate and apply vegetation mask
   variable Data
   puts "\nGenerating vegetation mask"
   gdalband read RTEB [gdalfile open FTEB read $Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).tif]

   vexpr RTEBWMASK ifelse(RTEB>800,100,0)

   set Data(VegeFilterType) lp
   set Data(VegeFilterSize) 99

   set fileRTEBfilter $Data(Zone_name)_vegemask-$Data(VegeFilterType)$Data(VegeFilterSize)_$Data(Res)m_$Data(UrbanX_version).tif
   if { ![file exists $fileRTEBfilter] } {
      if { $Data(VegeFilterSize) > 20 } {
         puts "Generating this $Data(VegeFilterType)$Data(VegeFilterSize) vegetation mask may require hours to process"
      }
      vector create FILTER [UrbanX::FilterGen $Data(VegeFilterType) $Data(VegeFilterSize)]
      # Le nodata sert à simuler l'application d'un mask au filtre qui suit
      #puts [gdalband is RTEBMASK] ;# retourne 1 si la bande existe...
      vexpr RTEBWMASK ifelse(RTEB==901,901,RTEBWMASK)
      gdalband stats RTEBWMASK -nodata 901
      vexpr VEGEMASK fkernel(RTEBWMASK,FILTER)
#      vexpr VEGEMASK fcentile(RTEBWMASK,3,0.5) ;# fcentile is fmedian, fmax, fmin à la fois
      puts "Writing results to $fileRTEBfilter"
      file delete -force ./$fileRTEBfilter
      gdalfile open FILEOUT write ./$fileRTEBfilter GeoTiff
      gdalband write VEGEMASK FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
      gdalfile close FILEOUT
   } else {
      puts "Using previously computed filtered data $fileRTEBfilter"
      gdalband read VEGEMASK [gdalfile open FVEGEMASK read ./$fileRTEBfilter]
   }

   # Seuil sur le filtre et rajout des non-nature et de l'eau
   vexpr RTEBWMASK ifelse((VEGEMASK>85 && RTEB>800 && RTEB!=901),0,RTEB)
   puts "Writing results to $Data(Zone_name)_TEB-wVegeMask_$Data(Res)m_$Data(UrbanX_version).tif"
   file delete -force ./$Data(Zone_name)_TEB-wVegeMask_$Data(Res)m_$Data(UrbanX_version).tif
   gdalfile open FILEOUT write ./$Data(Zone_name)_TEB-wVegeMask_$Data(Res)m_$Data(UrbanX_version).tif GeoTiff
   gdalband write RTEBWMASK FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RTEBWMASK
   gdalband free VEGEMASK
}

proc UrbanX::CreatefstdBand { Name Band } {
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
      set ll [gdalband stats $Band -gridpoint 0 $j ];# [[expr $NJ-$j-1]]
      fstdfield stats TAC -gridvalue 0 $j [lindex $ll 0]
   }

   fstdfield create $Name $NI $NJ $NK Int32
   fstdfield define $Name -GRTYP Z
   fstdfield define $Name -DEET 0 -NPAS 0 -IP1 0 -IP2 0 -IP3 0 -ETIKET $Name -NOMVAR GRID -TYPVAR X -IG1 0 -IG2 0 -IG3 0 -IG4 0
}

proc UrbanX::TEB2fstd { } {
   variable Data
   puts "\nConverting TEB raster to .fstd"
   gdalband read BAND [gdalfile open FILE read ./$Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).tif]
   UrbanX::CreatefstdBand GRID BAND
   fstdfield define GRID -NOMVAR UG
   file delete -force ./$Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).fstd
   fstdfile open 1 write $Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).fstd
   fstdfield write TIC 1 -32 True
   fstdfield write TAC 1 -32 True
   fstdfield write GRID 1 -16 True
   fstdfile close 1
   fstdfile open 1 write $Data(Zone_name)_TEB_$Data(Res)m_$Data(UrbanX_version).fstd
   fstdfield read GRID 1 -1 "" -1 -1 -1 "" UG
   fstdfield gridinterp GRID BAND
   fstdfield write GRID 1 -16 True
   fstdfile close 1
}

proc UrbanX::Shp2Height { } {
   variable Data
   puts "\nConverting $Data(Zone_name) building shapefile to raster"
   if { $Data(Zone_name) == "ott" } {
      set shp_file /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott-buildings.shp
   }
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $Data(Zone_name)_sandwich_$Data(Res)m_$Data(UrbanX_version).tif]
   gdalband create RHAUTEURSHP $Data(Width) $Data(Height) 1 Float32
   gdalband define RHAUTEURSHP -georef [gdalband define RSANDWICH -georef]
   gdalband free RSANDWICH
   gdalfile close FSANDWICH

   set shp_layer [lindex [ogrfile open SHAPE read $shp_file] 0]
   eval ogrlayer read LAYER $shp_layer
   gdalband gridinterp RHAUTEURSHP LAYER $Data(Mode) hgt

   ogrlayer free LAYER
   ogrfile close SHAPE

   puts "Writing results to /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif"
   file delete -force /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
   gdalfile open FILEOUT write /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif GeoTiff
   gdalband write RHAUTEURSHP FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RHAUTEURSHP
}

proc UrbanX::FilterGen { Type Size } {

   # Est-ce cette proc maintenant dans le 'main code' de JP?
   # Il manque les filtres median, directionel, lp/hp gaussien, Sobel/Roberts, FFT
   if { $Size%2 == 0 } {
      set Size [expr ($Size -1)]
      puts "\n\033\[01;31m*** ERROR: Filter size must be an odd number ***\n*** Generated filter kernel will NOT be good ***\nNew filter size decreased to $Size\033\[0m\n"
   }

   set kernel { }

   switch $Type {
      "lp" {
         for { set i 0 } { $i < $Size } {  incr i } {
            set line { }
            for { set j 0 } { $j < $Size } {  incr j } {
               lappend line 1
            }
            lappend kernel $line
         }
      }

      "hp" {
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
   if { $Type == "lp" && $Size >= 5 } {
      puts "Filter type: $Type, size: $Size"
   } else {
      puts "Filter type: $Type, size: $Size, resulting kernel: $kernel"
   }
   return $kernel
}

#------------------------ MAIN ------------------------
puts "\n***** UrbanX BEGIN *****"

UrbanX::AreaParameters           ;# Sets lat-long bounding box for city
UrbanX::FindZoneUTM              ;# Finds UTM zone for city
UrbanX::DefineZone               ;# Create geographic reference and set output size parameters
UrbanX::FindNTSSheets            ;# Identify NTS sheets for the city
UrbanX::FindPaths                ;# Sets the NTDB files paths

UrbanX::SandwichBNDT            ;# Rasterize and flattens all NTDB layers
if { ($UrbanX::Data(Res) <= 5) && ($UrbanX::Data(Mode) == "FAST") } {
#   UrbanX::ScaleBuffers
}
if { $UrbanX::Data(Zone_name) == "ott"} {
## La rasterization des hauteurs n'a pas vraiment d'affaire dans UrbanX... C'est one-shot.
##   UrbanX::Shp2Height
}
#UrbanX::ChampsBuffers            ;# Create the fields and building vicinity output using spatial buffers
UrbanX::PopDens2Builtup
#UrbanX::HeightGain               ;# Requires UrbanX::ChampsBuffers to have run
#UrbanX::BuildingHeight ;# This proc requires UrbanX::PopDens2Builtup and must be used in conjunction with the previous one otherwise $Data(HeightGain) won't be defined

#UrbanX::Values2TEB               ;# Applies LUT to all processing results to generate TEB classes. Requires UrbanX::PopDens2Builtup.

## Optional outputs:
UrbanX::VegeMask                 ;# Generate and apply vegetation mask
##UrbanX::TEB2fstd                 ;# CAN'T WORK WITH FILES OVER 128 MEGS (e.g. MTL, VAN, TOR)

puts "\n***** UrbanX END *****\n"