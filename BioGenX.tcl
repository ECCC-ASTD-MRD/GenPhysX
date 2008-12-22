#===============================================================================
# Environnement Canada
# Centre Meteorologique Canadian
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project     : Geophysical field generator for GEM-MACH et AURAMS
# File        : BioGenX.tcl
# Creation    : 8 mai 2007 Louis-Philippe Crevier - AQMAS
# Revision    : $Id$
# Description : Code generant les champs geophysiques et les emissions biogeniques
#               pour GEM-MACH et AURAMS
#
# Remarques : - Base sur GenPhysX, localisation: ~afsr005/Scripts/Project/GenPhysX/GenPhysX.tcl
#             - Does not work on pollux
#
# Functions :
#
#   BioGenX::LULC_15Classes    { Grid }
#   BioGenX::LocateGrid        { Grid }
#   BioGenX::ReadEmissfacFile  { EmissfacFile }
#   BioGenX::StateField        { Grid }
#   BioGenX::CalcEmissions     { Grid }
#   BioGenX::CalcEmissionsUSGS { Grid }
#   BioGenX::CalcEmissionsBELD { Grid }
#
#===============================================================================

namespace eval BioGenX { } {
   variable Data
   variable Const

   set Data(Version)   0.5

   set Data(FieldList) [list BGXISOP BGXMONO BGXVOC BGXNO BGXISOW BGXMONW BGXVOCW BGXNOW BGXLAI BGXAREA BGXVCHK ]
   set Data(NameList)  [list ESIO    ESMO    ESVO   ESNO  EWIO    EWMO    EWVO    EWNO   LAI    AREA    VCHK ]
   set Data(TypeList)  [list C       C       C      C     C       C       C       C      C      X       X ]

   set Data(DoNotUseBELD3) False
   set Data(Compress)      False
   set Data(Interp)        AVERAGE

   set Data(ToleranceVCHK) 0.0001

   set Data(LuTypes)   { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 }

   set Const(C2io)   1.133333
   set Const(C2mono) 1.133333
   set Const(C2ovoc) 1.233333
   set Const(C2no)   2.142857
   set Const(Mug2g)  0.000001
   set Const(H2s)    0.0002777778
}

#-------------------------------------------------------------------------------
# Nog      : BioGenX::LULC_15Classes
# Creation : 6 aout 2007 - Louis-Philippe Crevier - AQMAS
#
# Description : Generate the 15 LU types
#
# Parametres :
#              Grid : ID de la grille cible
#
# Retour : --
#
# Remarques : --
#
#-------------------------------------------------------------------------------
proc BioGenX::LULC_15Classes { Grid } {
   variable Data

   GenX::Procs
   GenX::Log INFO "Generating 15 category land-use classification"

   #----- Recuperation du champ VF
   if { [catch { fstdfield read BGXVF GPXOUTFILE -1 "" -1 -1 -1 "" "VF" } ] } {
      GenX::Log ERROR "Calculating 15 category LULC requires use of -vege option"
      exit 1
   }
   fstdfield readcube BGXVF

   #----- Creer le champ LUAU pour la deposition seche
   fstdfield create BGXLU [fstdfield define $Grid -NI] [fstdfield define $Grid -NJ] [llength $Data(LuTypes)]
   GenX::GridClear BGXLU 0.0

   GenX::GridCopy BGXVF BGXLU

   fstdfield define BGXLU -IP2 0 -IP3 0 -NOMVAR LU15
   fstdfield stats BGXLU -levels $Data(LuTypes) -leveltype UNDEFINED

   #----- Assigner les 26 champs VF aux 15 categories
   #----- Note: Les indices du slicer vont de 0 a n
   vexpr BGXLU BGXLU()()(0)  = BGXVF()()(3)
   vexpr BGXLU BGXLU()()(1)  = BGXVF()()(4)  + BGXVF()()(7)
   vexpr BGXLU BGXLU()()(2)  = BGXVF()()(5)
   vexpr BGXLU BGXLU()()(3)  = BGXVF()()(6)  + BGXVF()()(8)
   vexpr BGXLU BGXLU()()(4)  = BGXVF()()(25) + BGXVF()()(24)
   vexpr BGXLU BGXLU()()(5)  = BGXVF()()(13) + BGXVF()()(12)
   vexpr BGXLU BGXLU()()(6)  = BGXVF()()(15) + BGXVF()()(16) + BGXVF()()(17) \
                             + BGXVF()()(18) + BGXVF()()(19) + BGXVF()()(14)
   vexpr BGXLU BGXLU()()(7)  = BGXVF()()(23)
   vexpr BGXLU BGXLU()()(8)  = BGXVF()()(21)
   vexpr BGXLU BGXLU()()(9)  = BGXVF()()(10) + BGXVF()()(11) + BGXVF()()(9)
   vexpr BGXLU BGXLU()()(10) = BGXVF()()(22)
   vexpr BGXLU BGXLU()()(11) = BGXVF()()(1)
   vexpr BGXLU BGXLU()()(12) = BGXVF()()(2)
   vexpr BGXLU BGXLU()()(13) = BGXVF()()(0)
   vexpr BGXLU BGXLU()()(14) = BGXVF()()(20)

   fstdfield define BGXLU -ETIKET LULC-GRAHM
   fstdfield write BGXLU GPXAUXFILE -24 True

   fstdfield free BGXLU
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::LocateGrid
# Creation : 8 fevrier 2008 - Louis-Philippe Crevier - AQMAS
#
# Description : Identifier les jeux de donnees a utiliser pour cette grille
#
# Parametres :
#              Grid : ID de la grille cible
#
# Retour : --
#
# Remarques : Priority is given to emissions generated using beld3 data
#
#-------------------------------------------------------------------------------
proc BioGenX::LocateGrid { Grid } {
   variable Data
   variable Const

   GenX::Log DEBUG "Identifying which datasets to use for biogenic emissions"

   #----- BELD3
   set BioGenX::Data(datasets) {}

   #----- Lecture d'une bande de la base de donnees beld3
   set file $GenX::Path(BELD3)/beld3-16.tif
   gdalfile open BELD3($file) read $file
   eval "gdalband read PC_VEG {{BELD3($file) 1}}"

   set iswithin       [georef within    [fstdfield define $Grid -georef] [gdalband define PC_VEG -georef]]
   set intersect      [georef intersect [fstdfield define $Grid -georef] [gdalband define PC_VEG -georef]]
   set intersectswith [ llength $intersect ]

   GenX::Log DEBUG "is fully within BELD3? (Yes if > 0): $iswithin"
   GenX::Log DEBUG "intersects with BELD3? (Yes if > 0): $intersectswith"

   if { $iswithin || $intersectswith } {
      lappend BioGenX::Data(datasets) "BELD3"
      set BioGenX::Data(X0) [ lindex $intersect 0 ]
      set BioGenX::Data(Y0) [ lindex $intersect 1 ]
      set BioGenX::Data(X1) [ lindex $intersect 2 ]
      set BioGenX::Data(Y1) [ lindex $intersect 3 ]
   } else {
      GenX::Log DEBUG "BELD3 :Grille cible hors de la grille BELD3."
      set BioGenX::Data(DoNotUseBELD3) True
   }

   if { ( !$iswithin && $intersectswith ) || !$iswithin } {
      lappend BioGenX::Data(datasets) "VF"
      GenX::Log DEBUG "VF :Grille cible hors (en tout ou en partie) de la grille BELD3."
   }

   #----- Liberation de l'espace memoire utilise
   gdalband free PC_VEG
   gdalfile close BELD3($file)

   GenX::Log DEBUG "Using dataset(s) $BioGenX::Data(datasets)"

   return $BioGenX::Data(datasets)
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::ReadEmissfacFile
# Creation : 8 mai 2007 - Louis-Philippe Crevier - AQMAS
#
# Description : Lecture d'un fichier de facteurs d'emission
#
# Parametres : EmissfacFile : Path du fichier de facteur d'ï¿½ission
#
# Retour : -- (voir Remarques)
#
# Remarques : Utilise upvar pour mettre a jour les variable dans le name space
#             superieur. A faire attention si on deplace ce bout de code
#
#-------------------------------------------------------------------------------
proc BioGenX::ReadEmissfacFile { EmissfacFile } {

   upvar 1 vegtyp vegtyp_l
   upvar 1 leafarea leafarea_l
   upvar 1 leafbio leafbio_l
   upvar 1 winterfact winterfact_l
   upvar 1 leafweight leafweight_l
   upvar 1 ef1 ef1_l
   upvar 1 ef2 ef2_l
   upvar 1 ef3 ef3_l
   upvar 1 ef4 ef4_l

   GenX::Log DEBUG "Emission factor file: $EmissfacFile" False
   catch { append GenX::Meta(Header) "EF file used: $EmissfacFile\n" }

   if { ![file exists $EmissfacFile] } {
      GenX::Log ERROR "Could not find the emission factors file"
      GenX::Log ERROR "Ef File : \[$EmissfacFile\]"
      GenX::Log ERROR "Stopping"
      exit 1
   }

   set filetxt [open $EmissfacFile r ]
   foreach line [split [read $filetxt] \n] {
      set isComment  [string match #* [ lindex $line 0 ]]
      set isNotBlank [string length [ lindex $line 0 ] ]
      set isId [string match "\$Id:" [lindex $line 1]]
      if { ! $isComment && $isNotBlank } {
         set vegid                [ lindex $line 0 ]
         set vegtyp_l($vegid)     [ lindex $line 1 ]
         set leafarea_l($vegid)   [ lindex $line 2 ]
         set leafbio_l($vegid)    [ lindex $line 3 ]
         set winterfact_l($vegid) [ lindex $line 4 ]
         set leafweight_l($vegid) [ lindex $line 5 ]
         set ef1_l($vegid)        [ lindex $line 6 ]
         set ef2_l($vegid)        [ lindex $line 7 ]
         set ef3_l($vegid)        [ lindex $line 8 ]
         set ef4_l($vegid)        [ lindex $line 9 ]
      } elseif { $isId } {
         GenX::Log DEBUG "EF file Id  : [lrange $line 2 end-1 ]" False
         catch { append GenX::Meta(Header) "EF file Id  : [lrange $line 2 end-1 ]\n" }
      }
   }
   close $filetxt
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::StateField
# Creation : 8 mai 2007 - Louis-Philippe Crevier - AQMAS
#
# Description : Cree un champ ST pour AURAMS
#
# Parametres : Grid : Descripteur de grille
#
# Retour : --
#
# Remarques : Creates dummy field for now
#
#-------------------------------------------------------------------------------
proc BioGenX::StateField { Grid } {

   GenX::Procs
   GenX::Log INFO "Generating dummy state field"

   GenX::GridClear $Grid -1.0
   fstdfield copy BGXST $Grid
   fstdfield define BGXST -NOMVAR "ST" -ETIKET "DUMMY"
   fstdfield write BGXST GPXOUTFILE -12 True
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::CalcEmissions
# Creation : 5 decembre 2008 - Louis-Philippe Crevier - AQMAS
#
# Description : Genereation des emissions biogeniques selon la methode
#               de genphysx 1.0
#
# Parametres :
#
# Retour : --
#
# Remarques :
#
#-------------------------------------------------------------------------------
proc BioGenX::CalcEmissions { Grid  } {
   variable Data
   variable Const

   GenX::Procs
   GenX::Log DEBUG "Calculate biogenic emissions"

   #----- Initialisation des champs
   GenX::GridClear $Grid 0.0
   foreach field $BioGenX::Data(FieldList) {
      fstdfield copy $field $Grid
   }
   fstdfield copy BGXRMS $Grid
   GenX::GridClear BGXRMS 0.0

   #----- Calculer les emissions pour chaque banque de donnee
   foreach landuse $GenX::Data(Biogenic) {
      switch $landuse {
         "USGS" { BioGenX::CalcEmissionsUSGS $Grid }
         "BELD" { BioGenX::CalcEmissionsBELD $Grid }
      }
   }

   #----- Save output
   foreach field $BioGenX::Data(FieldList) varname $BioGenX::Data(NameList) season $BioGenX::Data(TypeList) {
      fstdfield define $field -ETIKET "EMISSIONS" -TYPVAR $season -NOMVAR $varname -IP1 0
      fstdfield write $field GPXOUTFILE -32 True $BioGenX::Data(Compress)
   }
   #----- Save RMS
   fstdfield define BGXRMS -NOMVAR BRMS -IP1 1200
   fstdfield write BGXRMS GPXAUXFILE -32 True

   #----- Free output fields
   foreach field $BioGenX::Data(FieldList) {
      fstdfield free $field
   }
   fstdfield free BGXTSK
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::CalcEmissionsUSGS
# Creation : 5 decembre 2008 - Louis-Philippe Crevier - AQMAS
#
# Description : Genereation des emissions biogeniques selon la methode
#               de genphysx 1.0
#
# Parametres : Grid
#
# Retour : --
#
# Remarques :
#
#-------------------------------------------------------------------------------
proc BioGenX::CalcEmissionsUSGS { Grid } {
   variable Data
   variable Const

   GenX::Procs
   GenX::Log INFO "Calculating biogenic emissions using VF fields."

   #----- Ouverture et lecture de chacune des colonnes du
   #----- fichier texte des taux d'emissions dus a la vegetation
   BioGenX::ReadEmissfacFile $GenX::Path(BELD3)/Factors/vf_beis3v13_ef.dat

   #----- Recuperation du champ VF
   if { [catch { fstdfield read BGXVF GPXOUTFILE -1 "" -1 -1 -1 "" "VF" } ] } {
      GenX::Log ERROR "Calculating emissions from USGS DB requires use of -vege option"
      exit 1
   }
   fstdfield readcube BGXVF

   #----- Calcul des superficies des tuiles GEM-MACH (AREA) en m2
   vexpr BGXAREA darea($Grid)

   #----- Multiplier les constantes
   set io_cst [expr $Const(C2io)   * $Const(Mug2g) * $Const(H2s)]
   set mo_cst [expr $Const(C2mono) * $Const(Mug2g) * $Const(H2s)]
   set vo_cst [expr $Const(C2ovoc) * $Const(Mug2g) * $Const(H2s)]
   set no_cst [expr $Const(C2no)   * $Const(Mug2g) * $Const(H2s)]

   #----- Calcul des concentrations finales des emissions biogeniques...
   foreach k $GeoPhysX::Data(VegeTypes) {

      #----- Extraire la fraction dans un champ temporaire
      vexpr BGXTMP BGXVF()()([expr $k-1])

      #----- Masquer la zone a ne pas travailler
      vexpr BGXTMP ifelse(BGXRMS==1.0,0.0,BGXTMP)

      #----- ...pour la saison d'ete
      eval "vexpr BGXISOP BGXISOP+$ef1($k)*BGXTMP*$io_cst*BGXAREA"
      eval "vexpr BGXMONO BGXMONO+$ef2($k)*BGXTMP*$mo_cst*BGXAREA"
      eval "vexpr BGXVOC   BGXVOC+$ef3($k)*BGXTMP*$vo_cst*BGXAREA"
      eval "vexpr BGXNO     BGXNO+$ef4($k)*BGXTMP*$no_cst*BGXAREA"

      #----- ...pour la saison d'hiver
      eval "vexpr BGXISOW BGXISOW+$ef1($k)*BGXTMP*$winterfact($k)*$io_cst*BGXAREA"
      eval "vexpr BGXMONW BGXMONW+$ef2($k)*BGXTMP*$winterfact($k)*$mo_cst*BGXAREA"
      eval "vexpr BGXVOCW BGXVOCW+$ef3($k)*BGXTMP*$winterfact($k)*$vo_cst*BGXAREA"
      eval "vexpr BGXNOW   BGXNOW+$ef4($k)*BGXTMP*$winterfact($k)*$no_cst*BGXAREA"

      #----- Calcul du Leaf Area Index
      eval "vexpr BGXLAI   BGXLAI+BGXTMP*$leafarea($k)"

      #----- Calcul du champ de verification des index
      #----- Le total du champ doit donner 1 partout.
      vexpr BGXVCHK BGXVCHK+BGXTMP
   }

   vexpr BGXAREA ifelse(BGXRMS,0.0,BGXAREA)

   #----- Liberer l'espace memoire des champs temporaires
   fstdfield free BGXTMP
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::CalcEmissionsBELD
# Creation : 5 decembre 2008 - Louis-Philippe Crevier - AQMAS
#
# Description : Genereation des emissions biogeniques selon la methode
#               de genphysx 1.0
#
# Parametres : Grid
#
# Retour : --
#
# Remarques :
#
#-------------------------------------------------------------------------------
proc BioGenX::CalcEmissionsBELD { Grid } {
   variable Data
   variable Const

   GenX::Procs
   GenX::Log INFO "Calculating biogenic emissions using BELD3 database ($Data(Interp))."

   #----- Verification de la necessite d'utiliser BELD3
   BioGenX::LocateGrid $Grid
   if {$BioGenX::Data(DoNotUseBELD3)} {
      GenX::Log WARNING "Specified grid does not intersect with BELD3 dataset. Skipping."
      return
   }

   #----- Initialisation des champs
   #----- Nettoyer à 0 le champ Grid pour eviter que les interpolations
   #----- AVERAGE et autres ne moyennent les champs d'une fois a l'autre
   GenX::GridClear $Grid 0.0
   foreach field $Data(FieldList) {
      fstdfield copy $field $Grid
   }

   #----- Ouverture et lecture de chacune des colonnes du
   #----- fichier texte des taux d'emissions dus a la vegetation
   BioGenX::ReadEmissfacFile $GenX::Path(BELD3)/Factors/beld3_beis3v13_ef.dat

   #----- Calcul des superficies des tuiles GEM-MACH (AREA) en m2
   vexpr BGXAREA darea($Grid)

   #----- Loop over files
   set i 0

   set filelist [glob $GenX::Path(BELD3)/beld3-*.tif]
   set nfiles   [format "%3i" [llength $filelist] ]

   foreach file $filelist {

      set i [expr $i+1]

      set k [string range $file [expr [string last "beld3-" $file ] +6] [expr [string last ".tif" $file] -1]]

      #----- Lecture d'une bande de la base de donnees
      #----- Ne lit que le sous-ensemble de points necessaires au traitement
      set i_out [format "%3i" $i]
      GenX::Log DEBUG "Reading layer $i_out of $nfiles: code [format "%3i" $k] -- $vegtyp($k)" False
      gdalfile open BELD3($file) read $file
      eval "gdalband read PC_VEG {{BELD3($file) 1}} $BioGenX::Data(X0) $BioGenX::Data(Y0) $BioGenX::Data(X1) $BioGenX::Data(Y1)"

      #----- Interpolation de la grille LAMBERT a la grille de destination
      fstdfield gridinterp $Grid PC_VEG $Data(Interp) True

      #----- Liberation de l'espace memoire utilise
      gdalband free PC_VEG
      gdalfile close BELD3($file)

      #----- Calcul des concentrations finales des emissions biogeniques...

      #----- ...pour la saison d'ete
      eval "vexpr BGXISOP BGXISOP+$ef1($k)*$Grid"
      eval "vexpr BGXMONO BGXMONO+$ef2($k)*$Grid"
      eval "vexpr BGXVOC   BGXVOC+$ef3($k)*$Grid"
      eval "vexpr BGXNO     BGXNO+$ef4($k)*$Grid"

      #----- ...pour la saison d'hiver
      eval "vexpr BGXISOW BGXISOW+$ef1($k)*$Grid*$winterfact($k)"
      eval "vexpr BGXMONW BGXMONW+$ef2($k)*$Grid*$winterfact($k)"
      eval "vexpr BGXVOCW BGXVOCW+$ef3($k)*$Grid*$winterfact($k)"
      eval "vexpr BGXNOW   BGXNOW+$ef4($k)*$Grid*$winterfact($k)"

      #----- Calcul du Leaf Area Index
      eval "vexpr BGXLAI   BGXLAI+$Grid*$leafarea($k)"

      #----- Calcul du champ de verification des index
      #----- Le total du champ doit donner 1 partout.
      vexpr BGXVCHK BGXVCHK+$Grid

      #----- Nettoyer à 0 le champ Grid pour eviter que les interpolations
      #----- AVERAGE et autres ne moyennent les champs d'une fois a l'autre
      GenX::GridClear $Grid 0.0
  }

   #----- Fin du calcul des emissions biogeniques
   eval "vexpr BGXISOP BGXISOP*$Const(C2io)*$Const(Mug2g)*$Const(H2s)*BGXAREA"
   eval "vexpr BGXMONO BGXMONO*$Const(C2mono)*$Const(Mug2g)*$Const(H2s)*BGXAREA"
   eval "vexpr BGXVOC   BGXVOC*$Const(C2ovoc)*$Const(Mug2g)*$Const(H2s)*BGXAREA"
   eval "vexpr BGXNO     BGXNO*$Const(C2no)*$Const(Mug2g)*$Const(H2s)*BGXAREA"
   eval "vexpr BGXISOW BGXISOW*$Const(C2io)*$Const(Mug2g)*$Const(H2s)*BGXAREA"
   eval "vexpr BGXMONW BGXMONW*$Const(C2mono)*$Const(Mug2g)*$Const(H2s)*BGXAREA"
   eval "vexpr BGXVOCW BGXVOCW*$Const(C2ovoc)*$Const(Mug2g)*$Const(H2s)*BGXAREA"
   eval "vexpr BGXNOW   BGXNOW*$Const(C2no)*$Const(Mug2g)*$Const(H2s)*BGXAREA"

   #----- Calculate mask for VF-based emissions
   set ecartmax [expr 1.0 + $Data(ToleranceVCHK)]
   set ecartmin [expr 1.0 - $Data(ToleranceVCHK)]
   vexpr BGXRMS ifelse((BGXVCHK >= $ecartmin) && (BGXVCHK <= $ecartmax),1.0,0.0)
}
