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
# Description: Classification automatisée, principalement à partir de
#              données CanVec 1:50000, StatCan (population) et LCC2000V
#              pour alimenter le modèle SMOKE
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#============================================================================

namespace eval IndustrX { } {
   variable Param
   variable Const
	variable Meta
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
#				 genphysx_smoke.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Priorities2SMOKE {indexCouverture } {

	#add proc to Metadata
   GenX::Procs
   GenX::Log INFO "Début de la proc Priorities2SMOKE"

   variable Param

   GenX::Log INFO "Converting values to SMOKE classes"

	#lecture des fichiers créés précédemment lors des procs SandwichCanVec et PopDens2BuiltupCanVec
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$indexCouverture.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup_$indexCouverture.tif]
#   gdalband read RLCC2000VSMOKE [gdalfile open FLCC2000VSMOKE read $GenX::Param(OutFile)_LCC2000VSMOKE_$indexCouverture.tif]

puts "A"

	#passage des valeurs de priorités (sandwich) aux valeurs smoke dans RSMOKE
   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $UrbanX::Param(Priorities)
   vector set LUT.TO $UrbanX::Param(SMOKEClasses)
   vexpr RSMOKE lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

puts "B"

	#modification pour inclure la densité de population 
   vexpr RSMOKE ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RSMOKE)

	#modification pour inclure la végétation LCC2000V
#   vexpr RSMOKE ifelse(RSMOKE==0 || RSMOKE==200,RLCC2000VSMOKE,RSMOKE)

puts "C"

	#écriture du fichier de sortie
   file delete -force $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif GeoTiff
   gdalband write RSMOKE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

puts "D"

   GenX::Log INFO "The file $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif was generated"

   gdalfile close FILEOUT FSANDWICH FPOPDENSCUT ;#FLCC2000VSMOKE
   gdalband free RSMOKE RSANDWICH RPOPDENSCUT ;#RLCC2000VSMOKE

puts "E"

   GenX::Log INFO "Fin de la proc Priorities2SMOKE"
}

#----------------------------------------------------------------------------
# Name     : <IndustrX::SMOKE2DA>
# Creation : August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Proceed to the counting of pixels associated to
#						each SMOKE class for each DA polygon in the
#						selected NTS Sheet
#
# Parameters :
#		<indexCouverture>		: index à appliquer à la référence UTMREF
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::SMOKE2DA {indexCouverture } {

	#add proc to Metadata
   GenX::Procs
   GenX::Log INFO "Début de la proc SMOKE2DA"

   variable Param

	#NOTE : le fichier des polygones de DA à modifier avec les valeurs SMOKE
	#est ouvert et fermé dans le main, et non dans cette proc.

	#ouverture du fichier SMOKE.tif
	gdalband read RSMOKE [gdalfile open FSMOKE read $GenX::Param(OutFile)_SMOKE_$indexCouverture.tif]

	#sélection des polygones de DA ayant la valeur indexCouverture dans le champ SNRC
	set da_select [ogrlayer define VDASMOKE -featureselect [list [list SNRC == $indexCouverture]] ]
	GenX::Log DEBUG "Les [llength $da_select] polygones de dissemination area ayant les ID suivants ont été conservés : $da_select"

	#	clear les colonnes SMOKE pour les polygones de DA sélectionnés
	for {set classeid 1} {$classeid < 96} {incr classeid 1} {
		ogrlayer clear VDASMOKE SMOKE$classeid
	}

	#création d'un fichier de rasterization des polygones de DA
	gdalband create RDA $UrbanX::Param(Width) $UrbanX::Param(Height) 1 Int32
	gdalband clear RDA -1
	gdalband define RDA -georef UTMREF$indexCouverture

	#rasterization des polygones de DA
	gdalband gridinterp RDA VDASMOKE FAST FEATURE_ID

	GenX::Log INFO "Comptage des pixels de chaque classe SMOKE pour chaque polygone de DA"
   for {set classeid 1} {$classeid < 96} {incr classeid 1} {

		#enregistrement du temps nécessaire pour faire le traitement de la classe i
		set t [clock seconds]

		#comptage des pixels de chaque classe smoke pour chaque polygone de DA : increment de la table
		vexpr VDASMOKE.SMOKE$classeid tcount(VDASMOKE.SMOKE$classeid,ifelse (RSMOKE==$classeid,RDA,-1))

		#affichage du temps requis pour traiter la classe i
		GenX::Log DEBUG "Classe $classeid traitée en [expr [clock seconds]-$t] secondes"
	}

   ogrlayer sync VDASMOKE ;# là pcq utilisation du mode append, pas besoin en mode write, mais le mode write a un bug

	#nettoyage de mémoire
	gdalband free RSMOKE RDA
	gdalfile close FSMOKE

	GenX::Log INFO "Fin de la proc SMOKE2DA"
}


#----------------------------------------------------------------------------
# Name     : <IndustrX::Process>
# Creation : Octobre 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :
#
# Parameters :
#   <Coverage>   : zone to process {TN PEI NS NB QC ON MN SK AB BC YK TNO NV}
#		   default settings on Quebec City, from UrbanX
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc IndustrX::Process { Coverage } {

	GenX::Log INFO "Début d'IndustrX"

	variable Param

	set Usedtool "IndustrX"
	GenX::Log INFO "Coverage = $Coverage"
	GenX::Log INFO "Traitement d'une province : $Usedtool"

	#mesure du temps de traitement de la zone entière
	set t_traitement [clock seconds]

	#----- Get the lat/lon and pr code parameters associated with the province
	UrbanX::AreaDefine    $Coverage
	#----- Defines the general  extents of the zone to be process, the central UTM zone and set the initial UTMREF
	UrbanX::UTMZoneDefine $UrbanX::Param(Lat0) $UrbanX::Param(Lon0) $UrbanX::Param(Lat1) $UrbanX::Param(Lon1) $UrbanX::Param(Resolution) 0

	#----- Ffinds all NTS Sheets that intersect with the province polygon
	UrbanX::FindNTSSheets 0
	# au terme de cette proc, on a
		#Param(NTSIds) : liste des ids des feuillets NTS : format 9999
		#Param(NTSSheets) : liste des nos de feuillets NTS : format 999A99

return

	#ouverture du fichier de polygones de DA à modifier avec les valeurs SMOKE
	if { ![ogrlayer is VDASMOKE] } {
		set Param(PopFile2006SMOKE_Province) /data/aqli04/afsulub/StatCan2006/SMOKE_FILLED/da2006-nts_lcc-nad83_$Coverage.shp
		set da_layer_smoke [lindex [ogrfile open SHAPEDASMOKE append $Param(PopFile2006SMOKE_Province)] 0]
		#set da_layer_smoke [lindex [ogrfile open SHAPEDASMOKE append $UrbanX::Param(PopFile2006SMOKE)] 0]
		eval ogrlayer read VDASMOKE $da_layer_smoke
		GenX::Log DEBUG "On compte [ogrlayer define VDASMOKE -nb] polygones dans le fichier des dissemination areas à modifier"
	}

# # 	#TO DELETE : FEUILLETS TESTS DE PERFORMANCES
#  	set Param(NTSIds) {3012}
#  	set Param(NTSSheets) {"21I16"}
#  	puts "Feuillet test $Param(NTSIds) $Param(NTSSheets)"
# # 	#FIN DU TO DELETE : FEUILLETS TESTS DE PERFORMANCES

	#préparation à l'incrémentation sur les feuillets NTS 
	set nbrfeuillets [llength $UrbanX::Param(NTSSheets) ] 
	set i 1
	puts "_______________________________________________________________________________________________________________________________"

	#----- Process for each NTS Sheets that were previously selected
	foreach feuillet $UrbanX::Param(NTSSheets) {

		#Si le traitement d'une province a déjà été partiellement effectué, écrire l'index de feuillet où reprendre le traitement.  Default à 1
		if {$i < 354} {
			GenX::Log INFO "Feuillet $i sur $nbrfeuillets"
			GenX::Log INFO "Feuillet déjà traité"
			puts "__________________________________________________________________________________________________________________________"
			incr i

		} else {
			#calcul du temps de traitement d'un feuillet NTS
			set t_feuillet [clock seconds]

			GenX::Log INFO "Feuillet $i sur $nbrfeuillets"

			GenX::Log INFO "Traitement de la tuile NTS ayant le numéro de feuillet $feuillet"

			#----- Finds the extents of the zone (NTS Sheet) to be process
			UrbanX::NTSExtent $feuillet
			GenX::Log INFO "La latitude de la tuile va de $UrbanX::Param(Lat0) à $UrbanX::Param(Lat1)"
			GenX::Log INFO "La longitude de la tuile va de $UrbanX::Param(Lon0) à $UrbanX::Param(Lon1)"
			GenX::Log INFO "Les coordonnées UTM de la tuile sur l'axe X  vont de $UrbanX::Param(x0) à $UrbanX::Param(x1)"
			GenX::Log INFO "Les coordonnées UTM de la tuile sur l'axe Y  vont de $UrbanX::Param(y0) à $UrbanX::Param(y1)"

			#----- Finds CanVec files, rasterize and flattens all CanVec layers, applies buffer on some elements
			set UrbanX::Param(t_Sandwich) 0
			if { ![file exists $GenX::Param(OutFile)_sandwich_$feuillet.tif] } {
				UrbanX::Sandwich $feuillet
			} else {
				GenX::Log INFO "Le fichier $GenX::Param(OutFile)_sandwich_$feuillet.tif existe déjà."
			}

			#----------TO MODIFY FOR CANVEC LAYERS
	# 		#----- Creates the fields and building vicinity output using spatial buffers
	# 		UrbanX::ChampsBuffers $m
			#----------END OF : TO MODIFY FOR CANVEC LAYERS

	# 		#LCC2000V Vegetation
	# 		if { ![file exists $GenX::Param(OutFile)_LCC2000V_$feuillet.tif] || ![file exists $GenX::Param(OutFile)_LCC2000VSMOKE_$feuillet.tif] } {
	# 			UrbanX::LCC2000V $feuillet
	# 		} else {
	# 			GenX::Log INFO "Les fichiers $GenX::Param(OutFile)_LCC2000V_$feuillet.tif et $GenX::Param(OutFile)_LCC2000VSMOKE_$feuillet.tif existent déjà."
	# 		}

			#----- Calculates the population density and split the residential areas according to population density thresholds
			set UrbanX::Param(t_PopDens2Builtup) 0
			if { ![file exists $GenX::Param(OutFile)_popdens_$feuillet.tif] || ![file exists $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif] } {
				UrbanX::PopDens2Builtup $feuillet
			} else {
				GenX::Log INFO "Les fichiers $GenX::Param(OutFile)_popdens_$feuillet.tif et $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif existent déjà."
			}

			#----- Applies LUT to all processing results to generate SMOKE classes and sets the values in the DA shapefile
			set Param(t_Priorities2SMOKE) 0
			set Param(t_SMOKE2DA) 0
			if { ![file exists $GenX::Param(OutFile)_SMOKE_$feuillet.tif] } {
				#----- Applies LUT to all processing results to generate SMOKE classes
				UrbanX::Priorities2SMOKE  $feuillet
				#----- Counts the SMOKE values and write the results in the dissemination area shapefile
				UrbanX::SMOKE2DA $feuillet
			} else {
				GenX::Log INFO "Le fichier $GenX::Param(OutFile)_SMOKE_$feuillet.tif existe déjà."
			}

			#suppression des produits intermédiaires
			file delete -force $GenX::Param(OutFile)_sandwich_$feuillet.tif
			GenX::Log INFO "The file $GenX::Param(OutFile)_sandwich_$feuillet.tif was deleted"
			file delete -force $GenX::Param(OutFile)_popdens_$feuillet.tif
			GenX::Log INFO "The file $GenX::Param(OutFile)_popdens_$feuillet.tif was deleted"
			file delete -force $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif
			GenX::Log INFO "The file $GenX::Param(OutFile)_popdens-builtup_$feuillet.tif was deleted"
			file delete -force $GenX::Param(OutFile)_EOSDVegetation_$feuillet.tif
			GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDVegetation_$feuillet.tif was generated"
			file delete -force $GenX::Param(OutFile)_EOSDSMOKE_$feuillet.tif
			GenX::Log INFO "The file $GenX::Param(OutFile)_EOSDSMOKE_$feuillet.tif was generated"
			file delete -force $GenX::Param(OutFile)_SMOKE_$feuillet.tif
			GenX::Log INFO "The file $GenX::Param(OutFile)_SMOKE_$feuillet.tif was deleted"
	# 
			#affichage du temps de traitement du feuillet
			GenX::Log DEBUG "Feuillet $feuillet traité en [expr [clock seconds]-$t_feuillet] secondes"

			#préparation à la nouvelle incrémentation
			puts "__________________________________________________________________________________________________________________________"
			incr i

		} ;#fin du traitement du feuillet (boucle else)
	} ;# fin du foreach feuillet
 
	#fermeture du fichier de polygones de DA à modifier avec les valeurs SMOKE
	#ogrfile close SHAPEDSMOKE  ;#ne pas le mettre, vu un bogue avec le mode append
	ogrlayer free VDASMOKE  

	#écriture des métadonnées
	set GenX::Meta(Footer) " Varia : 
	Données CanVec : $GenX::Path(CANVEC)
	Données de Statistique Canada : $Param(PopFile2006SMOKE_Province)
	Données EOSD : $GenX::Path(EOSD)
	Temps total du traitement : [expr [clock seconds]-$t_traitement] secondes
	Nombre de feuillets NTS traités : [expr ($i-1)] / $nbrfeuillets"
	GenX::MetaData $GenX::Param(OutFile)_metadata_$Coverage.txt

	#fin de la boucle sur la zone à traiter
	GenX::Log INFO "Fin du traitement de $Coverage avec IndustrX"
	GenX::Log INFO "Fin d'IndustrX.  Retour à GenPhysX"

 } ;# fin de la proc Process