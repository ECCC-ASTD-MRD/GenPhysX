#===============================================================================
# Environnement Canada
# Centre Meteorologique Canadian
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project     : Geophysical field generator for GEM-MACH et AURAMS
# File        : BioGenX.tcl
# Creation    : 19 decembre 2008 Louis-Philippe Crevier - AQMAS
# Revision    : $Id$
# Description : Code generant les champs geophysiques et les emissions biogeniques
#               pour GEM-MACH et AURAMS
#
# Remarques : - Does not work on pollux
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
   variable Param
   variable Const

   set Param(Version)   0.9

   set Param(FieldList) [list ISOP MONO VOC  NO   ISOW MONW VOCW NOW  LAI AREA VCHK ]
   set Param(NameList)  [list ESIO ESMO ESVO ESNO EWIO EWMO EWVO EWNO LAI AREA VCHK ]
   set Param(TypeList)  [list C    C    C    C    C    C    C    C    C   X    X    ]
   set Param(FileOut)   [list OUT  OUT  OUT  OUT  OUT  OUT  OUT  OUT  OUT AUX  AUX  ]

   set Param(DoNotUseBELD3) False
   set Param(Interp)        AVERAGE

   set Param(ToleranceVCHK) 0.0001

   #----- Type de LULC et fractions
   set Param(LuTypes)   { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 }
   set Param(CoFracs)   { 1.0 1.0 1.0 1.0 1.0 0.25 0.25 0.0 0.25 0.25 0.25 0.0 0.0 0.0 0.5 }
   set Param(CoFracs26) { 0 0 0 1.0 1.0 1.0 1.0 1.0 1.0 0.25 0.25 0.25 0.25 0.25 0.25 0.25 0.25 0.25 0.25 0.25 0.5 0.25 0.25 0.0 1.0 0.25 }

   #----- Paths to emission factor files
   set Path(Factors)      $GenX::Path(BELD3)/Factors
   set Path(BELD3Factors) beld3_beis3v13_ef.dat
   set Path(VFFactors)    vf_beis3v13_ef.dat

   #----- Constants
                                  ;# Facteur de conversion d'equivalent carbone ...
   set Const(C2io)   1.133333     ;#  ... en isoprene
   set Const(C2mono) 1.133333     ;#  ... en monoterpene
   set Const(C2ovoc) 1.233333     ;#  ... en compose organique volatil
   set Const(C2no)   2.142857     ;#  ... en oxyde d'azote
   set Const(Mug2g)  0.000001     ;# micro-gram to gram conversion factor
   set Const(H2s)    0.0002777778 ;# Hour to seconds conversion factor
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
   variable Param

   GenX::Procs
   GenX::Log INFO "Generating 15 category land-use classification"

   #----- Recuperation du champ VF
   if { [catch { fstdfield read BGXVF GPXOUTFILE -1 "" -1 -1 -1 "" "VF" } ] } {
      GenX::Log ERROR "Calculating 15 category LULC requires use of -vege option"
      exit 1
   }
   fstdfield readcube BGXVF

   #----- Creer le champ LUAU pour la deposition seche
   fstdfield create BGXLU [fstdfield define $Grid -NI] [fstdfield define $Grid -NJ] [llength $Param(LuTypes)]
   GenX::GridClear BGXLU 0.0

   GenX::GridCopy BGXVF BGXLU

   fstdfield define BGXLU -IP2 0 -IP3 0 -NOMVAR LU15
   fstdfield stats BGXLU -levels $Param(LuTypes) -leveltype UNDEFINED

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

   fstdfield define BGXLU -ETIKET LULC-GRAHM -TYPVAR "C"
   fstdfield write BGXLU GPXAUXFILE -32 True $GenX::Param(Compress)

   fstdfield free BGXLU BGXCFRAC BGXTFRAC
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::TransportFraction
# Creation : 8 janvier 2009 - Louis-Philippe Crevier - AQMAS
#
# Description : Generer les transportable fractions por les fugitive dust
#
# Parametres :
#              Grid : ID de la grille cible
#
# Retour : --
#
# Remarques :
#
#-------------------------------------------------------------------------------
 proc BioGenX::TransportableFractions { Grid } {

   BioGenX::LULC_15Classes $Grid
   BioGenX::TrFractions_15Classes $Grid
   BioGenX::TrFractions_26Classes $Grid

}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::TrFractions_15Classes
# Creation : 8 janvier 2009 - Louis-Philippe Crevier - AQMAS
#
# Description : Generer les transportable fractions por les fugitive dust
#
# Parametres :
#              Grid : ID de la grille cible
#
# Retour : --
#
# Remarques :
#
#-------------------------------------------------------------------------------
proc BioGenX::TrFractions_15Classes { Grid } {
   variable Param

   GenX::Procs
   GenX::Log INFO "Generating 15-category transportable fractions"

   #----- Initialisation des champs
   GenX::GridClear $Grid 0.0
   fstdfield copy  BGXCFRAC $Grid

   #----- Recuperation du champ LULC
   if { [catch { fstdfield read BGXLU GPXAUXFILE -1 "" -1 -1 -1 "" "LU15" } ] } {
      GenX::Log ERROR "Calculating 15-category Transport fraction requires call to BioGenX::LULC_15Classes"
      exit 1
   }
   fstdfield readcube BGXLU

   for { set i 0 } { $i < [ llength $BioGenX::Param(LuTypes) ] } { incr i } {
      eval vexpr BGXCFRAC BGXCFRAC + BGXLU()()($i) * [ lindex $BioGenX::Param(CoFracs) $i ]
   }
   vexpr BGXTFRAC 1.0 - BGXCFRAC

   fstdfield define BGXTFRAC -NOMVAR TFRC -ETIKET "TR FRAC 15" -TYPVAR "C"
   fstdfield write BGXTFRAC GPXAUXFILE -32 True $GenX::Param(Compress)

   fstdfield free BGXTFRAC BGXCFRAC BGXLU
}
#-------------------------------------------------------------------------------
# Nom      : BioGenX::TrFractions_26Classes
# Creation : 8 janvier 2009 - Louis-Philippe Crevier - AQMAS
#
# Description : Generer les transportable fractions por les fugitive dust
#
# Parametres :
#              Grid : ID de la grille cible
#
# Retour : --
#
# Remarques :
#
#-------------------------------------------------------------------------------
proc BioGenX::TrFractions_26Classes { Grid } {
   variable Param

   GenX::Procs
   GenX::Log INFO "Generating 26-category transportable fractions"

   #----- Initialisation des champs
   GenX::GridClear $Grid 0.0
   fstdfield copy  BGXCFRAC $Grid

   #----- Recuperation du champ VF
   if { [catch { fstdfield read BGXVF GPXOUTFILE -1 "" -1 -1 -1 "" "VF" } ] } {
      GenX::Log ERROR "Calculating 26-category Transport fraction requires use of -vege and -check options."
      exit 1
   }
   fstdfield readcube BGXVF

   for { set i 0 } { $i < [ llength $BioGenX::Param(CoFracs26) ] } { incr i } {
      eval vexpr BGXCFRAC BGXCFRAC + BGXVF()()($i) * [ lindex $BioGenX::Param(CoFracs26) $i ]
   }
   vexpr BGXTFRAC 1.0 - BGXCFRAC

   fstdfield define BGXTFRAC -NOMVAR TFRC -ETIKET "TR FRAC 26" -TYPVAR "C"
   fstdfield write BGXTFRAC GPXAUXFILE -32 True $GenX::Param(Compress)

   fstdfield free BGXTFRAC BGXCFRAC BGXVF
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
# Remarques :
#
#-------------------------------------------------------------------------------
proc BioGenX::LocateGrid { Grid } {
   variable Param
   variable Const

   GenX::Log DEBUG "Identifying which datasets to use for biogenic emissions"

   #----- BELD3
   set BioGenX::Param(datasets) {}

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
      lappend BioGenX::Param(datasets) "BELD3"
      set BioGenX::Param(X0) [ lindex $intersect 0 ]
      set BioGenX::Param(Y0) [ lindex $intersect 1 ]
      set BioGenX::Param(X1) [ lindex $intersect 2 ]
      set BioGenX::Param(Y1) [ lindex $intersect 3 ]
   } else {
      GenX::Log DEBUG "BELD3 :Grille cible hors de la grille BELD3."
      set BioGenX::Param(DoNotUseBELD3) True
   }

   if { ( !$iswithin && $intersectswith ) || !$iswithin } {
      lappend BioGenX::Param(datasets) "VF"
      GenX::Log DEBUG "Grille cible hors (en tout ou en partie) de la zone BELD3."
   }

   #----- Liberation de l'espace memoire utilise
   gdalband free PC_VEG
   gdalfile close BELD3($file)

   GenX::Log DEBUG "$BioGenX::Param(datasets) dataset(s) required to cover this grid. "

   return $BioGenX::Param(datasets)
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::ReadEmissfacFile
# Creation : 8 mai 2007 - Louis-Philippe Crevier - AQMAS
#
# Description : Lecture d'un fichier de facteurs d'emission
#
# Parametres : EmissfacFile : Path du fichier de facteur d'�ission
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
   fstdfield write BGXST GPXOUTFILE -12 True $GenX::Param(Compress)
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
   variable Param
   variable Const

   GenX::Procs
   GenX::Log DEBUG "Calculate biogenic emissions"

   #----- Initialisation des champs
   GenX::GridClear $Grid 0.0
   foreach field $BioGenX::Param(FieldList) {
      fstdfield copy BGX$field $Grid
   }
   fstdfield copy BGXRMS $Grid
   GenX::GridClear BGXRMS 0.0

   #----- Calculer les emissions pour chaque banque de donnee
   foreach landuse $GenX::Param(Biogenic) {
      switch $landuse {
         "VF"   { BioGenX::CalcEmissionsVF   $Grid }
         "BELD" { BioGenX::CalcEmissionsBELD $Grid }
      }
   }

   #----- Save output
   foreach field $BioGenX::Param(FieldList) varname $BioGenX::Param(NameList) season $BioGenX::Param(NameList) fichier $BioGenX::Param(FileOut) {
      fstdfield define BGX$field -ETIKET "EMISSIONS" -TYPVAR $season -NOMVAR $varname -IP1 0
      fstdfield write BGX$field GPX${fichier}FILE -32 True $GenX::Param(Compress)
   }
   #----- Save merge mask for different databases
   fstdfield define BGXRMS -NOMVAR BRMS -IP1 1200
   fstdfield write BGXRMS GPXAUXFILE -32 True $GenX::Param(Compress)

   #----- Free output fields
   foreach field $BioGenX::Param(FieldList) {
      fstdfield free BGX$field
   }
   fstdfield free BGXRMS
}

#-------------------------------------------------------------------------------
# Nom      : BioGenX::CalcEmissionsVF
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
proc BioGenX::CalcEmissionsVF { Grid } {
   variable Param
   variable Const

   GenX::Procs
   GenX::Log INFO "Calculating biogenic emissions using VF fields."

   #----- Ouverture et lecture de chacune des colonnes du
   #----- fichier texte des taux d'emissions dus a la vegetation
   BioGenX::ReadEmissfacFile $BioGenX::Path(Factors)/$BioGenX::Path(VFFactors)

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
   foreach k $GeoPhysX::Param(VegeTypes) {

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
   variable Param
   variable Const

   GenX::Procs
   GenX::Log INFO "Calculating biogenic emissions using BELD3 database ($Param(Interp))."

   #----- Verification de la necessite d'utiliser BELD3
   BioGenX::LocateGrid $Grid
   if {$BioGenX::Param(DoNotUseBELD3)} {
      GenX::Log WARNING "Specified grid does not intersect with BELD3 dataset. Skipping."
      return
   }

   #----- Initialisation des champs
   #----- Nettoyer � 0 le champ Grid pour eviter que les interpolations
   #----- AVERAGE et autres ne moyennent les champs d'une fois a l'autre
   GenX::GridClear $Grid 0.0
   foreach field $Param(FieldList) {
      fstdfield copy BGX$field $Grid
   }

   #----- Ouverture et lecture de chacune des colonnes du
   #----- fichier texte des taux d'emissions dus a la vegetation
   BioGenX::ReadEmissfacFile $BioGenX::Path(Factors)/$BioGenX::Path(BELD3Factors)

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
      eval "gdalband read PC_VEG {{BELD3($file) 1}} $BioGenX::Param(X0) $BioGenX::Param(Y0) $BioGenX::Param(X1) $BioGenX::Param(Y1)"
      gdalband stats PC_VEG -celldim $GenX::Param(Cell)

      #----- Interpolation de la grille LAMBERT a la grille de destination
      fstdfield gridinterp $Grid PC_VEG $Param(Interp) True

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

      #----- Nettoyer � 0 le champ Grid pour eviter que les interpolations
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
   set ecartmax [expr 1.0 + $Param(ToleranceVCHK)]
   set ecartmin [expr 1.0 - $Param(ToleranceVCHK)]
   vexpr BGXRMS ifelse((BGXVCHK >= $ecartmin) && (BGXVCHK <= $ecartmax),1.0,0.0)
}
