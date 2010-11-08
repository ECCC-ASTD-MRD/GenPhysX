#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : IndustrX.tcl
# Creation   : Octobre 2010- Lucie Boucher / Alexandre Leroux / J.P. Gauthier - CMC/AQMAS & CMC/CMOE
# Revision   : $Id$
# Description: Classification automatis�e, principalement � partir de
#              donn�es CanVec 1:50000, StatCan (population) et LCC2000V
#              pour alimenter le mod�le SMOKE
#
# Remarks  :
#   Aucune.
#
# Functions :
#   IndustrX::FindNTSSheets    { indexCouverture }
#   IndustrX::NTSExtent        { indexCouverture }
#   IndustrX::Priorities2SMOKE { indexCouverture }
#   IndustrX::SMOKE2DA         { indexCouverture }
#   IndustrX::Process          { Coverage }
#
#============================================================================

namespace eval IndustrX { } {
   variable Param
   variable Const
   variable Meta

   set Param(Version) 0.1
}

#----------------------------------------------------------------------------
# Name     : <IndustrX::FindNTSSheets>
# Creation : date? - Alexandre Leroux - CMC/CMOE
# Revision : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Find the NTS Sheets that intersect the province polygon
#
# Parameters :
#      <indexCouverture>      : index � appliquer � la r�f�rence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc IndustrX::FindNTSSheets { indexCouverture } {

   GenX::Log INFO "Beginning of procedure : FindNTSSheetsCanVec"

   #ouverture du shapefile index NTS50K
   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $UrbanX::Param(NTSFile)] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }
   GenX::Log DEBUG "There are [ogrlayer define NTSLAYER50K -nb] NTS tiles in the NTS50K file."

   #ouverture du shapefile du Canada
   set prov_layer [lindex [ogrfile open SHAPECANADA read $UrbanX::Param(ProvincesGeom)] 0]
   eval ogrlayer read VCANADA $prov_layer
   ogrlayer stats VCANADA -transform UTMREF$indexCouverture
   GenX::Log DEBUG "There are [ogrlayer define VCANADA -nb] polygons in the canadian territory file."

   #index de la g�om�trie de province
   set idxprovince [ogrlayer define VCANADA -featureselect [list [list PR == $UrbanX::Param(ProvinceCode) ] ] ]

   #s�lection de la g�om�trie pour la province s�lectionn�e
   set geom [ogrlayer define VCANADA -geometry $idxprovince]

   #conversion de NTSLAYER50K en UTMREF.
   ogrlayer stats NTSLAYER50K -transform UTMREF$indexCouverture

   #Pr�s�lection des tuiles NTS � l'aide d'un convexhull
   set hull [ogrgeometry stat $geom -convexhull]
   set ntssheets_pre [ogrlayer pick NTSLAYER50K $hull True]

   #ramener NTSLAYER50K � la s�lection des fichiers pr�s�lectionn�s
   ogrlayer define NTSLAYER50K -featureselect [list [list index # $ntssheets_pre]]
   GenX::Log DEBUG "The [llength $ntssheets_pre] NTS tiles with the following IDs have been pre-selected with a convex hull command : $ntssheets_pre"

   #avertissement sur le temps requis...
   GenX::Log INFO "Intersecting pre-selected NTS tiles with the province polygon.  This operation might takes several minutes..."

   #s�lection, parmi les fichiers NTS pr�s�lectionn�s, de ceux qui sont en intersection avec la g�om�trie provinciale
   set UrbanX::Param(NTSIds) [ogrlayer pick NTSLAYER50K $geom True INTERSECT]
   GenX::Log DEBUG "The [llength $UrbanX::Param(NTSIds)] NTS tiles with the following IDs intersect the province polygon : $UrbanX::Param(NTSIds)"

   #remplacement des ids des tuiles par le no de feuillet NTS, de format 999A99
   set UrbanX::Param(NTSSheets) { }
   foreach id $UrbanX::Param(NTSIds) {
      lappend UrbanX::Param(NTSSheets) [ogrlayer define NTSLAYER50K -feature $id IDENTIFIAN]
   }
   GenX::Log DEBUG "The [llength $UrbanX::Param(NTSSheets)] NTS tiles with the following SNRC identification codes intersect the province polygon : $UrbanX::Param(NTSSheets)"

   #nettoyage de m�moire
   ogrfile close SHAPECANADA SHAPE50K
   ogrlayer free VCANADA NTSLAYER50K

   GenX::Log INFO "End of procedure : FindNTSSheetsCanVec"
}

#----------------------------------------------------------------------------
# Name     : <IndustrX::NTSExtent>
# Creation : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :  Finds the extent (lat lon) of one NTS Sheet
#             Finds the extent (xy in UTM) of one NTS Sheets
#             Reset the UTMREF with the appropriate index
#
# Parameters :
#   <indexCouverture>    :  index � appliquer � la r�f�rence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc IndustrX::NTSExtent { indexCouverture } {

   GenX::Log INFO "Beginning of procedure : NTSExtent"

   #ouverture du shapefile index NTS50K
   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $UrbanX::Param(NTSFile)] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }

   #NOTE : ON NE TRANSFORME PAS NTSLAYER50K EN UTMREF CAR ON VEUT DES LAT/LON

   #s�lection de la tuile NTS correspondant � l'ID pass� en input
   set ntsid [lindex $UrbanX::Param(NTSIds) [lsearch -exact $UrbanX::Param(NTSSheets) $indexCouverture ]]
   ogrlayer define NTSLAYER50K -featureselect [list [list index # $ntsid]]

   #trouve les limites lat/lon de la tuile NTS s�lectionn�e
   set latlon [ogrlayer stats NTSLAYER50K -extent True]

   #affecte les valeurs latlon aux divers param�tres Lon0, Lon1, Lat0, Lat1, avec une marge
   set UrbanX::Param(Lon0) [expr [lindex $latlon 0] + 0.01]
   set UrbanX::Param(Lat0) [expr [lindex $latlon 1] + 0.01]
   set UrbanX::Param(Lon1) [expr [lindex $latlon 2] - 0.01]
   set UrbanX::Param(Lat1) [expr [lindex $latlon 3] - 0.01]

   #recherche du fichier CanVec correspondant au layer NTS
   set ntsfiles [GenX::CANVECFindFiles $UrbanX::Param(Lat0) $UrbanX::Param(Lon0) $UrbanX::Param(Lat1) $UrbanX::Param(Lon1) $UrbanX::Param(NTSLayer)]
   #ntsfiles contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp
   GenX::Log DEBUG "CanVec NTS50K file : $ntsfiles"

   #ouverture du shapefile CanVec index NTS50K
   if { ![ogrlayer is CANVECNTSLAYER] } {
      set canvec_nts_layer [lindex [ogrfile open SHAPECANVECNTSLAYER read $ntsfiles] 0]
      eval ogrlayer read CANVECNTSLAYER $canvec_nts_layer
   }

   #test : comptage du nombre de polygones dans le shapefile (devrait �tre 1)
   GenX::Log DEBUG "There are [ogrlayer define CANVECNTSLAYER -nb] NTS tiles in the CanVec NTS layer file (should be 1)"

   #d�finition du UTMREF pour la zone � traiter
   UrbanX::UTMZoneDefine  $UrbanX::Param(Lat0) $UrbanX::Param(Lon0) $UrbanX::Param(Lat1) $UrbanX::Param(Lon1) $UrbanX::Param(Resolution) 1_$indexCouverture

   #conversion de l'index NTS50K en UTMREF pour obtenir des coordonn�es xy
   ogrlayer stats CANVECNTSLAYER -transform UTMREF1_$indexCouverture

   #trouve les limites xy en coordonn�es UTM de la tuile NTS s�lectionn�e
   set xy [ogrlayer stats CANVECNTSLAYER -extent True]

   #affecte les valeurs latlon aux divers param�tres x0, y0, x1, y1
   set UrbanX::Param(x0) [lindex $xy 0]
   set UrbanX::Param(y0) [lindex $xy 1]
   set UrbanX::Param(x1) [lindex $xy 2]
   set UrbanX::Param(y1) [lindex $xy 3]

   #calcul des dimensions xy de la zone
   set UrbanX::Param(Width)  [expr int(ceil(($UrbanX::Param(x1) - $UrbanX::Param(x0))/$UrbanX::Param(Resolution)))]
   set UrbanX::Param(Height) [expr int(ceil(($UrbanX::Param(y1) - $UrbanX::Param(y0))/$UrbanX::Param(Resolution)))]

   #ajustement de la zone UTM et du m�ridien
   set zone     [expr int(ceil((180 + (($UrbanX::Param(Lon1) + $UrbanX::Param(Lon0))/2))/6))]
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
   georef define UTMREF$indexCouverture -transform [list $UrbanX::Param(x0) $UrbanX::Param(Resolution) 0.000000000000000 $UrbanX::Param(y0) 0.000000000000000 $UrbanX::Param(Resolution)]

   GenX::Log INFO "UTM zone is $zone, with central meridian at $meridian. Dimension are $UrbanX::Param(Width)x$UrbanX::Param(Height)"

   #nettoyage de m�moire
   ogrfile close SHAPECANVECNTSLAYER SHAPE50K
   ogrlayer free CANVECNTSLAYER NTSLAYER50K

   GenX::Log INFO "End of procedure NTSExtent"
}

#----------------------------------------------------------------------------
# Name     : <IndustrX::Priorities2SMOKE>
# Creation : July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Applies LUT to all processing results to generate SMOKE classes
#
# Parameters :
#
# Return: output files :
#             genphysx_smoke.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc IndustrX::Priorities2SMOKE { indexCouverture } {

   #add proc to Metadata
   GenX::Procs
   GenX::Log INFO "Beginning of procedure : Priorities2SMOKE"

   variable Param

   GenX::Log INFO "Converting values to SMOKE classes"

   #lecture des fichiers cr��s pr�c�demment lors des procs SandwichCanVec et PopDens2BuiltupCanVec
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif]
#   gdalband read RLCC2000VSMOKE [gdalfile open FLCC2000VSMOKE read $GenX::Param(OutFile)_LCC2000VSMOKE_$indexCouverture.tif]

   #passage des valeurs de priorit�s (sandwich) aux valeurs smoke dans RSMOKE
   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $UrbanX::Param(Priorities)
   vector set LUT.TO $UrbanX::Param(SMOKEClasses)
   vexpr RSMOKE lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   #modification pour inclure la densit� de population
   vexpr RSMOKE ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RSMOKE)

   #modification pour inclure la v�g�tation LCC2000V
#   vexpr RSMOKE ifelse(RSMOKE==0 || RSMOKE==200,RLCC2000VSMOKE,RSMOKE)

   #�criture du fichier de sortie
   file delete -force $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif GeoTiff
   gdalband write RSMOKE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   GenX::Log INFO "The file $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif was generated"

   gdalfile close FILEOUT FSANDWICH FPOPDENSCUT ;#FLCC2000VSMOKE
   gdalband free RSMOKE RSANDWICH RPOPDENSCUT ;#RLCC2000VSMOKE

   GenX::Log INFO "End of procedure Priorities2SMOKE"
}

#----------------------------------------------------------------------------
# Name     : <IndustrX::SMOKE2DA>
# Creation : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Proceed to the counting of pixels associated to
#                  each SMOKE class for each DA polygon in the
#                  selected NTS Sheet
#
# Parameters :
#      <indexCouverture>      : index � appliquer � la r�f�rence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc IndustrX::SMOKE2DA { indexCouverture } {

   #add proc to Metadata
   GenX::Procs
   GenX::Log INFO "Beginning of procedure SMOKE2DA"

   variable Param

   #NOTE : le fichier des polygones de DA � modifier avec les valeurs SMOKE
   #est ouvert et ferm� dans le main, et non dans cette proc.

   #ouverture du fichier SMOKE.tif
   gdalband read RSMOKE [gdalfile open FSMOKE read $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif]

   #s�lection des polygones de DA ayant la valeur indexCouverture dans le champ SNRC
   set da_select [ogrlayer define VDASMOKE -featureselect [list [list SNRC == $indexCouverture]] ]
   GenX::Log DEBUG "The [llength $da_select] dissemination area polygons with the following IDs were selected : $da_select"

   #   clear les colonnes SMOKE pour les polygones de DA s�lectionn�s
   for {set classeid 1} {$classeid < 96} {incr classeid 1} {
      ogrlayer clear VDASMOKE SMOKE$classeid
   }

   #cr�ation d'un fichier de rasterization des polygones de DA
   gdalband create RDA $UrbanX::Param(Width) $UrbanX::Param(Height) 1 Int32
   gdalband clear RDA -1
   gdalband define RDA -georef UTMREF$indexCouverture

   #rasterization des polygones de DA
   gdalband gridinterp RDA VDASMOKE FAST FEATURE_ID

   GenX::Log INFO "Counting pixels associated to each SMOKE class for each dissemination area polygon"
   for {set classeid 1} {$classeid < 96} {incr classeid 1} {

      #enregistrement du temps n�cessaire pour faire le traitement de la classe i
      set t [clock seconds]

      #comptage des pixels de chaque classe smoke pour chaque polygone de DA : increment de la table
      vexpr VDASMOKE.SMOKE$classeid tcount(VDASMOKE.SMOKE$classeid,ifelse (RSMOKE==$classeid,RDA,-1))

      #affichage du temps requis pour traiter la classe i
      GenX::Log DEBUG "Class $classeid was computed in [expr [clock seconds]-$t] seconds"
   }

   ogrlayer sync VDASMOKE ;# l� pcq utilisation du mode append, pas besoin en mode write, mais le mode write a un bug

   #nettoyage de m�moire
   gdalband free RSMOKE RDA
   gdalfile close FSMOKE

   GenX::Log INFO "End of procedure SMOKE2DA"
}


#----------------------------------------------------------------------------
# Name     : <IndustrX::Process>
# Creation : Octobre 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :
#
# Parameters :
#   <Coverage>   : zone to process {TN PEI NS NB QC ON MN SK AB BC YK TNO NV}
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc IndustrX::Process { Coverage } {

   GenX::Procs CANVEC StatCan EOSD
   GenX::Log INFO "Beginning of IndustrX"

   variable Param

   GenX::Log INFO "Coverage = $Coverage"

   #----- Get the lat/lon and pr code parameters associated with the province
   UrbanX::AreaDefine    $Coverage
   #----- Defines the general  extents of the zone to be process, the central UTM zone and set the initial UTMREF
   UrbanX::UTMZoneDefine $UrbanX::Param(Lat0) $UrbanX::Param(Lon0) $UrbanX::Param(Lat1) $UrbanX::Param(Lon1) $UrbanX::Param(Resolution) 0

   #----- Ffinds all NTS Sheets that intersect with the province polygon
   #note : param�tre "0" pass� � FindNTSSheets simplement pour avoir une valeur d'initialisation.  Lorsque la fonction est rappel�e dans la boucle, plus
   #loin, on lui passe le num�ro de feuillet NTS � traiter
   IndustrX::FindNTSSheets 0
   # au terme de cette proc, on a :
      #Param(NTSIds) : liste des ids des feuillets NTS : format 9999
      #Param(NTSSheets) : liste des nos de feuillets NTS : format 999A99

   #ouverture du fichier de polygones de DA � modifier avec les valeurs SMOKE
   #Ce fichier contient les polygones de DA pour une province, qui ont �t� d�coup�s suivant l'index NTS 50K sp�cifi� dans Param(NTSFile)
   if { ![ogrlayer is VDASMOKE] } {
      foreach file [glob $GenX::Path(StatCan)/SMOKE_FILLED/da2006-nts_lcc-nad83_$Coverage.*] {
         file delete -force [file tail $file]
         file copy $file ./
      }
      set da_layer_smoke [lindex [ogrfile open SHAPEDASMOKE append da2006-nts_lcc-nad83_$Coverage.shp] 0]
      eval ogrlayer read VDASMOKE $da_layer_smoke
      GenX::Log DEBUG "There are [ogrlayer define VDASMOKE -nb] dissemination area polygons in the output file."
   }

#    #Pour traiter une liste sp�cifique de feuillets NTS (tests de performances, une tuile qui a mal �t� trait�e...), entrez la liste des
#    #Feature_ID dans la variable UrbanX::Param(NTSIds) et la liste des identifiants NTS dans UrbanX::Param(NTSSheets)
#     set UrbanX::Param(NTSIds) {3613 3614 3615}
#     set UrbanX::Param(NTSSheets) {"031F10" "031F11" "031F12"}
#     puts "Feuillets � traiter, entr�e manuellement : $UrbanX::Param(NTSIds) $UrbanX::Param(NTSSheets)"

   #pr�paration � l'incr�mentation sur les feuillets NTS
   set nbrfeuillets [llength $UrbanX::Param(NTSSheets) ]
   set i 1 ;#incr�mentation sur les feuillets � traiter
   GenX::Log -

   #----- Process for each NTS Sheets that were previously selected
   foreach feuillet $UrbanX::Param(NTSSheets) {

      #Si le traitement d'une province a d�j� �t� partiellement effectu�, �crire l'index de feuillet o� reprendre le traitement.  Default � 1.
      #L'information se trouve dans le log du traitement pr�c�demment effectu�
      if {$i < 1} {
         GenX::Log INFO "Tile $i of $nbrfeuillets"
         GenX::Log INFO "Tile already processed"
         GenX::Log -
         incr i

      } else {
         #calcul du temps de traitement d'un feuillet NTS
         set t_feuillet [clock seconds]

         GenX::Log INFO "Tile $i of $nbrfeuillets"
         GenX::Log INFO "Traitement de la tuile NTS ayant le num�ro de feuillet $feuillet"
         GenX::Log INFO "Processing NTS tile with the SNRC identification code $feuillet"

         #----- Finds the extents of the zone (NTS Sheet) to be process
         IndustrX::NTSExtent $feuillet
         GenX::Log INFO "Tile's latitude goes from $UrbanX::Param(Lat0) to $UrbanX::Param(Lat1)"
         GenX::Log INFO "Tile's longitude goes from $UrbanX::Param(Lon0) to $UrbanX::Param(Lon1)"
         GenX::Log INFO "Tile's UTM coordinates, on the X axis, go from $UrbanX::Param(x0) to $UrbanX::Param(x1)"
         GenX::Log INFO "ile's UTM coordinates, on the X axis, go from $UrbanX::Param(y0) to $UrbanX::Param(y1)"

         #----- Finds CanVec files, rasterize and flattens all CanVec layers, applies buffer on some elements
         set UrbanX::Param(t_Sandwich) 0
         if { ![file exists $GenX::Param(OutFile)_sandwich_$feuillet.tif] } {
            UrbanX::Sandwich $feuillet
         } else {
            GenX::Log INFO "File $GenX::Param(OutFile)_sandwich_$feuillet.tif already exists."
         }

         #----------TO MODIFY FOR CANVEC LAYERS
#          #----- Creates the fields and building vicinity output using spatial buffers
#          UrbanX::ChampsBuffers $m
         #----------END OF : TO MODIFY FOR CANVEC LAYERS

         #----- Calculates the population density and split the residential areas according to population density thresholds
         set UrbanX::Param(t_PopDens2Builtup) 0
         if { ![file exists $GenX::Param(OutFile)_popdens_$feuillet.tif] || ![file exists $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif] } {
            UrbanX::PopDens2Builtup $feuillet
         } else {
            GenX::Log INFO "Files $GenX::Param(OutFile)_popdens_$feuillet.tif and $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif already exist."
         }

         #----- Applies LUT to all processing results to generate SMOKE classes and sets the values in the DA shapefile
         if { ![file exists $GenX::Param(OutFile)_SMOKE_$feuillet.tif] } {
            #----- Applies LUT to all processing results to generate SMOKE classes
            IndustrX::Priorities2SMOKE  $feuillet
            #----- Counts the SMOKE values and write the results in the dissemination area shapefile
            IndustrX::SMOKE2DA $feuillet
         } else {
            GenX::Log INFO "File $GenX::Param(OutFile)_SMOKE_$feuillet.tif already exist."
         }

         #suppression des produits interm�diaires
         file delete -force $GenX::Param(OutFile)_sandwich_$feuillet.tif
         GenX::Log INFO "File $GenX::Param(OutFile)_sandwich_$feuillet.tif was deleted"
         file delete -force $GenX::Param(OutFile)_popdens_$feuillet.tif
         GenX::Log INFO "File $GenX::Param(OutFile)_popdens_$feuillet.tif was deleted"
         file delete -force $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif
         GenX::Log INFO "File $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif was deleted"
         file delete -force $GenX::Param(OutFile)_EOSDVegetation_$feuillet.tif
         GenX::Log INFO "File $GenX::Param(OutFile)_EOSDVegetation_$feuillet.tif was deleted"
         file delete -force $GenX::Param(OutFile)_EOSDSMOKE_$feuillet.tif
         GenX::Log INFO "File $GenX::Param(OutFile)_EOSDSMOKE_$feuillet.tif was deleted"
         file delete -force $GenX::Param(OutFile)_SMOKE_$feuillet.tif
         GenX::Log INFO "File $GenX::Param(OutFile)_SMOKE_$feuillet.tif was deleted"

         #affichage du temps de traitement du feuillet
         GenX::Log DEBUG "Processing the NTS tile $feuillet took [expr [clock seconds]-$t_feuillet] seconds"

         #pr�paration � la nouvelle incr�mentation
         GenX::Log -
         incr i

      } ;#fin du traitement du feuillet (boucle else)
   } ;# fin du foreach feuillet

   #fermeture du fichier de polygones de DA � modifier avec les valeurs SMOKE
   #ogrfile close SHAPEDSMOKE  ;#ne pas le mettre, vu un bogue avec le mode append
   ogrlayer free VDASMOKE

   #�criture des m�tadonn�es
   append GenX::Meta(Footer) "Miscellaneous         :
	Number of NTS tiles processed : [expr ($i-1)] / $nbrfeuillets\n"

   #fin de la boucle sur la zone � traiter
   GenX::Log INFO "End of processing $Coverage with IndustrX"
}