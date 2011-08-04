#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : GenX.tcl
# Creation   : Septembre 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Revision   : $Id$
# Description: Definitions of global fonctions needed by the generator
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#   GenX::Procs              { args }
#   GenX::Log                { Type Message { Head True } }
#   GenX::Submit             { }
#   GenX::MetaData           { Grid }
#   GenX::ParseArgs          { Argv Argc No Multi Cmd }
#   GenX::ParseCommandLine   { }
#   GenX::ParseTarget        { } {
#   GenX::Continue           { }
#   GenX::CommandLine        { }
#   GenX::GetNML             { File }
#   GenX::FieldCopy          { InFile OutFile DateV Etiket IP1 IP2 IP3 TV NV }
#   GenX::GridClear          { Grids { Value 0.0 } }
#   GenX::GridLimits         { Grid }
#   GenX::GridCopy           { SourceField DestField }
#   GenX::GridCopyDesc       { Field FileIn FileOut }
#   GenX::GridGet            { File }
#   GenX::CacheGet           { File { NoData "" } }
#   GenX::CacheFree          { }
#   GenX::ASTERGDEMFindFiles { Lat0 Lon0Lat1 Lon1 }
#   GenX::CANVECFindFiles    { Lat0 Lon0 Lat1 Lon1 Layers }
#   GenX::SRTMFindFiles      { Lat0 Lon0Lat1 Lon1 }
#   GenX::CDEDFindFiles      { Lat0 Lon0 Lat1 Lon1 { Res 50 } }
#   GenX::EOSDFindFiles      { Lat0 Lon0Lat1 Lon1 }
#   GenX::LCC2000VFindFiles  { Lat0 Lon0 Lat1 Lon1 }
#   GenX::UTMZoneDefine      { Lat0 Lon0 Lat1 Lon1 { Res 5 } { Name "" } }
#
#============================================================================

package require TclData
package require TclSystem
package require MetData

namespace eval GenX { } {
   global env
   variable Settings
   variable Path
   variable Param
   variable Meta
   variable Batch
   variable Log

   set Param(Version)   1.2                   ;#Application version
   set Param(Secs)      [clock seconds]       ;#To calculate execution time
   set Param(TileSize)  1024                  ;#Tile size to use for large dataset
   set Param(Cache)     {}                    ;#Input data cache list
   set Param(CacheMax)  20                    ;#Input data cache max

   set Param(Vege)       ""                    ;#Vegetation data selected
   set Param(Soil)       ""                    ;#Soil type data selected
   set Param(Topo)       ""                    ;#Topography data selected
   set Param(Mask)       ""                    ;#Mask data selected
   set Param(GeoMask)    ""                    ;#Geographical mask data selected
   set Param(Aspect)     ""                    ;#Slope and aspect selected
   set Param(Check)      ""                    ;#Consistency checks
   set Param(Sub)        ""                    ;#Subgrid calculations selected
   set Param(Target)     ""                    ;#Model cible
   set Param(Biogenic)   ""                    ;#Biogenic emissions data selected
   set Param(Urban)      ""                    ;#Urban coverage
   set Param(SMOKE)      ""                    ;#SMOKE emissions
   set Param(SMOKEIndex) 1                     ;#SMOKE restart index

   set Param(Diag)      False                 ;#Diagnostics
   set Param(Z0Filter)  False                 ;#Filter roughness length
   set Param(Compress)  False                 ;#Compress standard file output
   set Param(NBits)     32                    ;#Compress standard file output
   set Param(Cell)      1                     ;#Grid cell dimension (1=1D(point 2=2D(area))
   set Param(Script)    ""                    ;#User definition script
   set Param(Process)   ""                    ;#Current processing id
   set Param(OutFile)   genphysx              ;#Output file prefix
   set Param(GridFile)  ""                    ;#Grid definition file to use (standard file with >> ^^)
   set Param(NameFile)  ""                    ;#Namelist to use

   set Param(Topos)     { USGS SRTM CDED250 CDED50 ASTERGDEM GTOPO30 }
   set Param(Aspects)   { SRTM CDED250 CDED50 }
   set Param(Veges)     { USGS GLC2000 GLOBCOVER CCRS EOSD LCC2000V CORINE }
   set Param(Soils)     { USDA AGRC FAO HWSD JPL }
   set Param(Masks)     { USGS GLC2000 GLOBCOVER CANVEC }
   set Param(GeoMasks)  { CANADA }
   set Param(Biogenics) { BELD VF }
   set Param(Urbans)    { True HALIFAX QUEBEC MONTREAL OTTAWA TORONTO REGINA WINNIPEG CALGARY EDMONTON VANCOUVER VICTORIA }
   set Param(SMOKES)    { TN PEI NS NB QC ON MN SK AB BC YK TNO NV }
   set Param(Checks)    { STD }
   set Param(Subs)      { STD }
   set Param(Targets)   { GEMMESO }             ;#Model cible

   set Batch(On)       False                 ;#Activate batch mode (soumet)
   set Batch(Host)     hawa                  ;#Host onto which to submit the job
   set Batch(Queue)    ""                    ;#Queue to use for the job
   set Batch(Mem)      2G                    ;#Memory needed for the job
   set Batch(Time)     7200                  ;#Time needed for the job
   set Batch(Mail)     ""                    ;#Mail address to send completion info
   set Batch(Submit)   "/usr/local/env/armnlib/scripts/ord_soumet"

   #----- Various database paths

   if  { [info exists env(GENPHYSX_DBASE)] } {
      set Path(DBase) $env(GENPHYSX_DBASE)
   } else {
      set Path(DBase) /data/shared_1_b0/armn
   }

   set Path(SandUSDA)  $Path(DBase)/RPN/sand_usda
   set Path(SandFAO)   $Path(DBase)/RPN/sand_fao
   set Path(SandAGRC)  $Path(DBase)/RPN/sand_argc
   set Path(ClayUSDA)  $Path(DBase)/RPN/clay_usda
   set Path(ClayFAO)   $Path(DBase)/RPN/clay_fao
   set Path(ClayAGRC)  $Path(DBase)/RPN/clay_argc
   set Path(TopoUSGS)  $Path(DBase)/RPN/me_usgs2002
   set Path(MaskUSGS)  $Path(DBase)/RPN/mg_usgs2002
   set Path(VegeUSGS)  $Path(DBase)/RPN/vg_usgs2002
   set Path(TopoLow)   $Path(DBase)/RPN/data_lres
   set Path(Grad)      $Path(DBase)/RPN/data_grad
   set Path(HWSD)      $Path(DBase)/HWSD
   set Path(SRTM)      $Path(DBase)/SRTMv4
   set Path(CDED)      $Path(DBase)/CDED
   set Path(ASTERGDEM) $Path(DBase)/ASTGTM_V1.1
   set Path(GTOPO30)   $Path(DBase)/GTOPO30
   set Path(EOSD)      $Path(DBase)/EOSD
   set Path(BNDT)      $Path(DBase)/BNDT
   set Path(NTS)       $Path(DBase)/NTS
   set Path(CANVEC)    $Path(DBase)/CanVec
   set Path(CORINE)    $Path(DBase)/CORINE
   set Path(GlobCover) $Path(DBase)/GlobCover
   set Path(GLC2000)   $Path(DBase)/GLC2000_USGS
   set Path(CCRS)      $Path(DBase)/CCRS-LC2005
   set Path(Various)   $Path(DBase)/Various
   set Path(BELD3)     $Path(DBase)/BELD3
   set Path(LCC2000V)  $Path(DBase)/LCC2000V
   set Path(JPL)       $Path(DBase)/JPL

   set Path(StatCan)   /data/aqli04/afsulub/StatCan2006

   #----- Metadata related variables

   set Meta(Procs)     {}                     ;#Metadata procedure registration list
   set Meta(Databases) {}                     ;#Databases used
   set Meta(Header)    ""                     ;#Metadata header
   set Meta(Footer)    ""                     ;#Metadata footer
   set Meta(Command)   ""                     ;#Launch command

   #----- Log related variables

   array set Log { Level INFO MUST -1 ERROR 0 WARNING 1 INFO 2 DEBUG 3 };

   gdalfile error QUIET
}

#----------------------------------------------------------------------------
# Name     : <GenX::Process>
# Creation : Mai 2010 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Launch processing on a grid.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topo
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Process { Grid } {
   variable Param

   #----- Check if we only need to process topo
   if { [fstdfield is $Grid] && [fstdfield define $Grid -IP1]!=1200 } {
      if { $Param(Topo)!="" } {
         GeoPhysX::AverageTopo     $Grid
      }
   } else {
      #----- Topography
      if { $Param(Topo)!="" } {
         GeoPhysX::AverageTopo     $Grid
         GeoPhysX::AverageTopoLow  $Grid
         GeoPhysX::AverageGradient $Grid
      }

      #----- Slope and Aspect
      if { $Param(Aspect)!="" } {
         GeoPhysX::AverageAspect $Grid
      }

      #----- Land-water mask
      if { $Param(Mask)!="" } {
         GeoPhysX::AverageMask $Grid
      }

      #----- Land-water mask
      if { $Param(GeoMask)!="" } {
         GeoPhysX::AverageGeoMask $Grid
      }

      #----- Vegetation type
      if { $Param(Vege)!="" } {
         GeoPhysX::AverageVege $Grid
      }

      #----- Soil type
      if { $Param(Soil)!="" } {
         GeoPhysX::AverageSoil $Grid
      }

      #----- Consistency checks
      switch $Param(Check) {
         "STD" { GeoPhysX::CheckConsistencyStandard }
      }

      #----- Sub grid calculations
      if { $Param(Sub)!="" } {
         GeoPhysX::SubCorrectionFactor
         GeoPhysX::SubTopoFilter
         GeoPhysX::SubLaunchingHeight
         GeoPhysX::SubY789
         GeoPhysX::SubRoughnessLength
      }

      #----- Biogenic emissions calculations
      if { $Param(Biogenic)!="" } {
         BioGenX::CalcEmissions  $Grid
         BioGenX::TransportableFractions $Grid
      }

      #----- Urban parameters
      if { $Param(Urban)!="" } {
         UrbanX::Process $Param(Urban) $Grid
         #UrbanPhysX::Cover $Grid
      }

      if { $Param(SMOKE)!="" } {
         IndustrX::Process $Param(SMOKE)
      }

      #----- Diagnostics of output fields
      if { $Param(Diag) } {
         GeoPhysX::Diag
      }
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::Submit>
# Creation : Decembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Submit the script in batch mode through soumet.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Submit { } {
   global env
   variable Param
   variable Path
   variable Batch

   upvar #0 argv gargv

   set host [info hostname]
   set rdir /tmp/GenPhysX[pid]_$Param(Secs)
   set rargv ""

   #----- Create job script
   set f [open [set job $env(TMPDIR)/GenPhysX[pid]] w 0755]

   puts $f "#!/bin/ksh\nset -x"
   puts $f "\nexport GENPHYSX_DBASE=$Path(DBase)\nexport SPI_PATH=$env(SPI_PATH)\nexport GENPHYSX_PRIORITY=-0"
   puts $f "export GENPHYSX_BATCH=\"$gargv\"\n"
   puts $f "trap \"cd ..; rm -fr $rdir\" 0 1 2 3 6 15 30"

   puts $f "mkdir $rdir"
   puts $f "cd $rdir"

   if { $Param(GridFile)!="" } {
      puts $f "scp $host:[file normalize $Param(GridFile)] ."
      append rargv " -gridfile [file tail $Param(GridFile)]"
   }
   if { $Param(NameFile)!="" } {
      puts $f "scp $host:[file normalize $Param(NameFile)] ."
      append rargv " -nml [file tail $Param(NameFile)]"
   }
   if { $Param(Script)!="" } {
      puts $f "scp $host:[file normalize $Param(Script)] ."
      append rargv " -script [file tail $Param(Script)]"
   }
   if { [file exists $Param(OutFile).fst] } {
      puts $f "scp $host:[file normalize ${Param(OutFile)}.fst] ."
   }
   if { [file exists ${Param(OutFile)}_aux.fst] } {
      puts $f "scp $host:[file normalize ${Param(OutFile)}_aux.fst] ."
   }

   set ldir [file dirname [file normalize $Param(OutFile)]]
   append rargv " -result [file tail $Param(OutFile)]"

   #----- Remove batch flag from arguments
   set idx [lsearch -exact $gargv "-batch"]
   set gargv [lreplace $gargv $idx $idx]

   puts $f "\n[file normalize [info script]] $gargv \\\n   $rargv\n"
   puts $f "scp [file tail $Param(OutFile)]* $host:$ldir\ncd ..\nrm -f -r $rdir"

   if { $Batch(Mail)!="" } {
      puts $f "echo $Param(OutFile) | mail -s \"GenPhysX job done\" $Batch(Mail) "
   }
   close $f

   #----- Launch job script
   if { ![file exists $Batch(Submit)] } {
      puts stderr "Could not find job submission program $Batch(Submit)"
      exit 1
   } else {
      puts stdout "Using $Batch(Submit) to launch job ... "
      set err [catch { exec $Batch(Submit) $job -threads 4 -mach $Batch(Host) -t $Batch(Time) -cm $Batch(Mem) 2>@1 } msg]
      if { $err } {
         puts stdout "Could not launch job ($job) on $Batch(Host)\n\n\t$msg"
      } else {
         puts stdout "Job ($job) launched on $Batch(Host) ... "
      }
   }

#   file delete -force $job
   exit 0
}

#----------------------------------------------------------------------------
# Name     : <GenX::Procs>
# Creation : Decembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     :Creates a list of the procedure used.
#
# Parameters :
#   <args>   : Databases used by the calling proc
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Procs { args } {
   variable Meta

   set Meta(Databases) [lsort -unique [concat $Meta(Databases) $args]]

   set proc [info level [expr [info level] -1]]
   if { [lsearch -exact $Meta(Procs) $proc]==-1 } {
      lappend Meta(Procs) $proc
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::Log>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Display verbose messages.
#
# Parameters :
#  <Type>    : Type de message (-,ERROR,WARNING,INFO,DEBUG,...)
#  <Message> : Message to display
#  <Head>    : Afficher l'info du stack
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Log { Type { Message "" } { Head True } } {
   variable Log
   variable Param

   set head " "
   set proc ""

   if { $Type=="-" } {
      puts "----------------------------------------------------------------------------------------------------"
      return
   }

   if { $Log($Type)<=$Log(Level) } {
      if { $Head && [info level]>1} {
         set head " [lindex [info level [expr [info level]-1]] 0]: "
      }
      if { $Param(Process)!="" } {
         set proc "($Param(Process)) "
      }
      if { $Type=="ERROR" } {
         puts stderr "($Type)$proc$head$Message"
      } else {
         puts "($Type)$proc$head$Message"
      }
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::MetaData>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Record metadata info in a standard RPN Field.
#
# Parameters :
#   <Grid>   : Grid on which to generate the topo
#
# Return:
#
# Remarks :
#    Metadata includes date-time and version, procedure used, and gem_settings file
#----------------------------------------------------------------------------
proc GenX::MetaData { Grid } {
   global env
   global argv
   variable Param
   variable Meta
   variable Path

   #----- Description of vesion used
   set version "GenX($Param(Version))"
   catch { append version ", GeoPhysX($GeoPhysX::Param(Version))" }
   catch { append version ", BioGenX($BioGenX::Param(Version))" }
   catch { append version ", UrbanX($UrbanX::Param(Version))" }
   catch { append version ", IndustrX($IndustrX::Param(Version))" }

   #----- Generation date et parameters used
   set meta "Generated      : [clock format [clock seconds]] on [info hostname] by $env(USER)\nExecution time : [expr [clock seconds]-$Param(Secs)] s\n"

   if  { [info exists env(GENPHYSX_BATCH)] } {
      append meta "Call parameters: [info script] $env(GENPHYSX_BATCH)\n"
   } else {
      append meta "Call parameters: [info script] [join $argv " "]\n"
   }
   append meta "SPI API version: $env(SPI_PATH)\nCode base      : $version\n"

   #----- Append script if any
   if { $Param(Script)!="" } {
      append meta "Script used    : $Param(Script)\n"
      set f [open $Param(Script) r]
      while { ![eof $f] } {
         append meta "   [gets $f]\n"
      }
      close $f
   }

   #----- Append specific header info
   append meta $Meta(Header)

   #----- Append processing used
   append meta "Processing used:\n   [join $Meta(Procs) "\n   "]\n"

   #----- Append NML file if any
   if { [file exists $Param(NameFile)] } {
      append meta "\nGEM namelist   : { \n[exec cat $Param(NameFile)]\n }"
   }

   #----- Append databases paths
   if { [llength $Meta(Databases)] } {
      append meta "Databases used :\n"
      foreach data $Meta(Databases) {
         catch { append meta [format "   %-10s: %s\n" $data $Path($data)] }
      }
   }

   #----- Append specific footer info
   append meta $Meta(Footer)

   #----- Encode everyting into fst record
   if { [fstdfield is $Grid] } {
      set fld [MetData::TextCode $meta]
      fstdfield define $fld -NOMVAR META -IP1 [fstdfield define $Grid -IP1] -IP2 [fstdfield define $Grid -IP2] -IP3 [fstdfield define $Grid -IP3]
      fstdfield write $fld GPXOUTFILE 0 True
   }

   #---- Save as text file
   set f [open $GenX::Param(OutFile)_meta.txt w]
   puts $f $meta
   close $f
}

#----------------------------------------------------------------------------
# Name     : <GenX::ParseArgs>
# Creation : Decembre 2000 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Parcourir les listes d'arguments et lancer les commandes associees
#            aux type de ces arguments.
#
# Parameters :
#   <Argv>   : Liste des arguments
#   <Argc>   : Nombre d'arguments
#   <No>     : Index dans la liste complete des arguments
#   <Multi>  : Multiplicite des valeurs (0=True,1=1 valeur,2=Multiples valeurs, 3=True ou 1 valeur)
#   <Var>    : Variable a a assigner les arguments
#   <Values> : Valid values accepted
#
# Return:
#   <Idx>    : Index apres les arguments traites.
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::ParseArgs { Argv Argc No Multi Var { Values {} } } {

   upvar #0 $Var var

   if { !$Multi } {
      set var True
   } else {

      #----- Garder l'index de depart
      set idx [incr No]
      set var {}

      if { $Multi==3 } {
         set var True
      } else {
         set var {}
      }

      #----- Parcourir les arguments du token specifie
      while { ([string is double [lindex $Argv $No]] || [string index [lindex $Argv $No] 0]!="-") && $No<$Argc } {

         #----- Check for argument validity
         set vs [lindex $Argv $No]
         if { $Multi==2 } {
            set vs [split $vs +]
         }

         if { [llength $Values] } {
            foreach v $vs {
               if { [lsearch -exact $Values $v]==-1 } {
                  GenX::Log ERROR "Invalid value ($v) for parameter [lindex $Argv [expr $No-1]], must be one of { $Values }"
                  exit 1;
               }
            }
         }
         if { $Multi==1 || $Multi==3 } {
            set var $vs
         } else {
            eval lappend var $vs
         }
         incr No
      }

      #----- Verifier le nombre de valeur
      if { $Multi && ![llength $var] }  {
         GenX::Log ERROR "No value specified for parameter [lindex $Argv [expr $No-1]]"
         exit 1;
      }

      if { [string index [lindex $Argv $No] 0]=="-" } {
         incr No -1
      }
   }

   return $No
}

#----------------------------------------------------------------------------
# Name     : <GenX::CommandLine>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Display command line arguments.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::CommandLine { } {
   variable Param
   variable Path
   variable Batch
   variable Log

   puts stderr "Arguments must be:"
   puts stderr "
   Information parameters:
      \[-help\]     [format "%-30s : This information" ""]
      \[-version\]  [format "%-30s : GenPhysX version" ""]
      \[-verbose\]  [format "%-30s : Trace level (0 ERROR, 1 WARNING, 2 INFO, 3 DEBUG)" ($Log(Level))]

   Input parameters:
      \[-nml\]      [format "%-30s : GEM namelist definition file" ($Param(NameFile))]
      \[-gridfile\] [format "%-30s : FSTD file to get the grid from if no GEM namelist" ($Param(GridFile))]
      \[-result\]   [format "%-30s : Result filename" ($Param(OutFile))]
      \[-target\]   [format "%-30s : Set necessary flags for target model {$Param(Targets)}" ($Param(Target))]
      \[-script\]   [format "%-30s : User definition script to include" ""]

   Processing parameters:
      Specify databases in order of processing joined by + ex: STRM+USGS

      \[-topo\]     [format "%-30s : Topography method(s) among {$Param(Topos)}" ([join $Param(Topo)])]
      \[-mask\]     [format "%-30s : Mask method, one of {$Param(Masks)}" ([join $Param(Mask)])]
      \[-geomask\]  [format "%-30s : Mask method, one of {$Param(GeoMasks)}" ([join $Param(GeoMask)])]
      \[-vege\]     [format "%-30s : Vegetation method(s) among {$Param(Veges)}" ([join $Param(Vege)])]
      \[-soil\]     [format "%-30s : Soil method(s) among {$Param(Soils)}" ([join $Param(Soil)])]
      \[-aspect\]   [format "%-30s : Slope and aspect method(s) among {$Param(Aspects)}" ([join $Param(Aspect)])]
      \[-biogenic\] [format "%-30s : Biogenic method(s) among {$Param(Biogenics)}" ([join $Param(Biogenic)])]
      \[-urban\]    [format "%-30s : Urban coverage {$Param(Urbans)}" ([join $Param(Urban)])]
      \[-smoke\]    [format "%-30s : SMOKE emissions {$Param(SMOKE)}" ([join $Param(SMOKE)])]
      \[-rindex\]   [format "%-30s : SMOKE restart index (default 1)" ($Param(SMOKEIndex))]
      \[-check\]    [format "%-30s : Do consistency checks {$Param(Checks)}" ($Param(Check))]
      \[-subgrid\]  [format "%-30s : Calculates sub grid fields {$Param(Subs)}" ($Param(Sub))]
      \[-diag\]     [format "%-30s : Do diagnostics (Not implemented yet)" ""]

   Specific processing parameters:
      \[-z0filter\] [format "%-30s : Apply GEM filter to roughness length" ""]
      \[-celldim\]  [format "%-30s : Grid cell dimension (1=point, 2=area)" ($Param(Cell))]
      \[-compress\] [format "%-30s : Compress standard file output" ($Param(Compress))]
      \[-nbits\]    [format "%-30s : Maximum number of bits to use to save RPN fields" ($Param(NBits))]

   Batch mode parameters:
      \[-batch\]    [format "%-30s : Launch in batch mode" ""]
      \[-mail\]     [format "%-30s : EMail address to send completion mail" ($Batch(Mail))]
      \[-mach\]     [format "%-30s : Machine to run on in batch mode" ($Batch(Host))]
      \[-t\]        [format "%-30s : Reserved CPU time (s)" ($Batch(Time))]
      \[-cm\]       [format "%-30s : Reserved RAM (MB)" ($Batch(Mem))]

   If you have questions, suggestions or problems, send them to:

      genphysx@internallists.ec.gc.ca\n"
}

#----------------------------------------------------------------------------
# Name     : <GenX::Continue>
# Creation : Novembre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Ask for continuation in case of problem.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Continue { } {
   global env
   variable Param

   #----- If we're not in batch mode, ask
   if  { ![info exists env(GENPHYSX_BATCH)] && $Param(Process)=="" } {
      puts stdout "Continue anyway (y or n) ? "
      if { [string toupper [string index [gets stdin] 0]]!="Y" } {
         exit 1
      }
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::ParseCommandLine>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Parse the command line arguments.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::ParseCommandLine { } {
   variable Param
   variable Path
   variable Batch
   variable Log

   upvar argc gargc
   upvar argv gargv

   #----- Check if architecture is valid
   if { [system info -os]!="Linux" } {
      GenX::Log ERROR "GenPhysX only runs on Linux"
      exit 1
   }

   if { !$gargc } {
      GenX::CommandLine
      exit 1
   }

   #----- Parse arguments
   set flags 0
   for { set i 0 } { $i < $gargc } { incr i } {
      switch -exact [string trimleft [lindex $gargv $i] "-"] {
         "version"   { puts "$Param(Version)"; exit 0 }
         "verbose"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Log(Level)] }
         "result"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(OutFile)] }
         "target"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(Target) $GenX::Param(Targets)]; GenX::ParseTarget; incr flags }
         "gridfile"  { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(GridFile)] }
         "nml"       { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(NameFile)] }
         "dbase"     { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(DBase)] }
         "batch"     { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Batch(On)] }
         "mach"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Host)] }
         "t"         { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Time)] }
         "cm"        { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Mem)] }
         "mail"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Mail)] }
         "topo"      { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Param(Topo) $GenX::Param(Topos)]; incr flags }
         "mask"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(Mask) $GenX::Param(Masks)]; incr flags }
         "geomask"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(GeoMask) $GenX::Param(GeoMasks)]; incr flags }
         "vege"      { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Param(Vege) $GenX::Param(Veges)]; incr flags }
         "soil"      { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Param(Soil) $GenX::Param(Soils)]; incr flags }
         "subgrid"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(Sub)]; incr flags }
         "aspect"    { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Param(Aspect)]; incr flags }
         "biogenic"  { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Param(Biogenic) $GenX::Param(Biogenics)]; incr flags }
         "urban"     { set i [GenX::ParseArgs $gargv $gargc $i 3 GenX::Param(Urban) $GenX::Param(Urbans)]; incr flags }
         "smoke"     { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(SMOKE) $GenX::Param(SMOKES)]; incr flags }
         "rindex"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(SMOKEIndex)] }
         "check"     { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(Check)]; incr flags }
         "diag"      { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Param(Diag)] }
         "z0filter"  { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Param(Z0Filter)]; incr flags }
         "celldim"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(Cell)] }
         "compress"  { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Param(Compress)] }
         "nbits"     { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(NBits)] }
         "script"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(Script)] }
         "process"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Param(Process)] }
         "help"      { GenX::CommandLine ; exit 0 }
         default     { GenX::Log ERROR "Invalid argument [lindex $gargv $i]"; GenX::CommandLine ; exit 1 }
      }
   }

   #----- Convert log level string to number if needed
   if { ![string is digit $Log(Level)] } {
      if { [catch { set Log(Level) $Log($Log(Level)) }] } {
         GenX::Log ERROR "Invalid log level $Log(Level)"
         exit 1
      }
   }

   #----- If no processing is specified, we use the default target
   if { !$flags } {
      set Param(Target) [lindex $GenX::Param(Targets) 0]
      GenX::ParseTarget
      GenX::Log WARNING "No data processing were specified, will use default target $Param(Target)"
      GenX::Continue
   }

   #----- Check for user definitiond
   if { $GenX::Param(Script)!="" } {
      source $Param(Script)
   }

   #----- Check dependencies
   if { $Param(Vege)!="" } {
      if { $Param(Mask)=="" } {
         GenX::Log ERROR "To generate vegetation type fields you need to generate the mask"
         GenX::Continue
      }
   }

   if { $Param(Sub)!="" } {
      if { $Param(Mask)=="" } {
         GenX::Log ERROR "To generate sub-grid post-processed fields you need to generate the mask"
         GenX::Continue
      }
      if { $Param(Topo)=="" } {
         GenX::Log ERROR "To generate sub-grid post-processed fields you need to generate the topography"
         GenX::Continue
      }
   }

   if { $Param(Biogenic)!="" } {
      if { $Param(Vege)=="" } {
            GenX::Log ERROR "To generate biogenic emissions fields you need to generate the vegetation type fields (-vege option)"
            GenX::Continue
      }
      if { $Param(Check)=="" } {
            GenX::Log ERROR "To generate biogenic emissions fields you must use the -check option."
            GenX::Continue
      }
   }

   #----- Check if a filename is included in result filename
   if { [file isdirectory $Param(OutFile)] } {
      append Param(OutFile) genphysx
   }

   #----- If batch mode enabled, submit the job and exit otherwise, go to result directory
   if { $Batch(On) } {
      GenX::Submit
   } else {
      #----- Check for database accessibility
      if { ![file readable $Path(DBase)] } {
         GenX::Log ERROR "Invalid database directory ($Path(DBase))"
         exit 1
      }
      cd [file dirname [file normalize $Param(OutFile)]]
   }

   catch { file delete $Param(OutFile).fst_gfilemap.txt }
}

#----------------------------------------------------------------------------
# Name     : <GenX::ParseTarget>
# Creation : Decembre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Select parameters for specific predefined models.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::ParseTarget { } {
   variable Param

   switch $Param(Target) {
      "GEMMESO" { set Param(Topo)     "USGS"
                  set Param(Vege)     "USGS"
                  set Param(Mask)     "USGS"
                  set Param(Soil)     "USDA AGRC FAO"
                  set Param(Check)    "STD"
                  set Param(Sub)      "STD"
                  set Param(Z0Filter) True
                  set Param(Compress) False
                }
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::GetNML>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Reads a GEM settings namelist and puts it in a Tcl array (Settings).
#
# Parameters :
#  <File>    : Namelist file path
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::GetNML { File } {
   variable Settings

   if { $File=="" } {
      return
   }

   if { ![file exists $File] } {
      GenX::Log WARNING "Could not read the namelist"
      return
   }

   set f [open $File r]
   while { ![eof $f] } {
      gets $f line

      #----- Check for block beginning
      set tok [string index [string trimleft $line] 0]
      if { $tok=="&" || $tok=="$" } {
         gets $f line

         #----- While not at a block end
         set char [string index [string trimleft $line] 0]
         while { $char!="/" && $char!="$" && $char!="&" } {

            #----- Insert all settings in Settings array
            foreach item [split $line ,] {
               if { [string trim $item]!="" } {

                  #----- Get the token name if not an array of values
                  if { [llength [set item [split $item =]]]==2 } {
                     set token [string toupper [string trim [lindex $item 0]]]
                  }
                  lappend Settings($token) [string map -nocase { "'" "" ".true." "True" .false. "False" } [string trim [lindex $item end]]]
               }
            }
            gets $f line
            set char [string index [string trimleft $line] 0]
         }
      }
   }

   if { $GenX::Log(Level)>=3 } {
      GenX::Log DEBUG "Read the following settings:"
      parray GenX::Settings

      GenX::Log DEBUG "Using following constants:"
      parray GeoPhysX::Const
      parray BioGenX::Const
   }
   close $f
}

#----------------------------------------------------------------------------
# Name     : <GenX::FieldCopy>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Copy specified fields from on file to another, grid descriptor included.
#
# Parameters :
#  <FileIn>  : File from which to copy
#  <OFileut> : File to which to copy
#  <DateV>   : Validity date
#  <Etiket>  : Etiket
#  <IP1>     : IP1
#  <IP2>     : IP2
#  <IP3>     : IP3
#  <TV>      : TYPVAR
#  <NV>      : NOMVAR
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::FieldCopy { FileIn FileOut DateV Etiket IP1 IP2 IP3 TV NV } {
   variable Param

   foreach field [fstdfield find $FileIn $DateV $Etiket $IP1 $IP2 $IP3 $TV $NV] {
      fstdfield read GPXTMP $FileIn $field
      fstdfield write GPXTMP $FileOut 0 True $GenX::Param(Compress)
      GenX::GridCopyDesc GPXTMP $FileIn $FileOut
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::GridClear>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Set the nodata value and clear the grid to this value (default 0.0).
#
# Parameters :
#  <Grids>   : Fields to clear
#  <Value>   : Value to use to clear the fields (Default 0.0)
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::GridClear { Grids { Value 0.0 } } {

   foreach grid $Grids {
      fstdfield stats $grid -nodata $Value
      fstdfield clear $grid
   }
}

#-------------------------------------------------------------------------------
# Nom      : GenX::GridCopy
# Creation : 8 Mai 2007 - Louis-Philippe Crevier - AQMAS
#
# Description : Copie des parametres de grille d'un champ a un autre
#
# Parametres : SourceField : ID du champ source
#              DestField : ID du champ destination
#
# Retour : --
#
# Remarques : Ne copie pas les champs ^^ et >>
#
#-------------------------------------------------------------------------------
proc GenX::GridCopy { SourceField DestField } {

   set grtyp [fstdfield define $SourceField -GRTYP]

   switch -regexp -- $grtyp {
      N|S|L    { set xgs [ fstdgrid cigaxg $grtyp \
                     [fstdfield define $SourceField -IG1] [fstdfield define $SourceField -IG2] \
                     [fstdfield define $SourceField -IG3] [fstdfield define $SourceField -IG4] ]
                  fstdfield define $DestField -GRTYP $grtyp [lindex $xgs 0] [lindex $xgs 1] [lindex $xgs 2] [lindex $xgs 3]
               }
      default  { fstdfield define $DestField -GRTYP  [fstdfield define $SourceField -GRTYP] \
                     -IG1 [fstdfield define $SourceField -IG1] \
                     -IG2 [fstdfield define $SourceField -IG2] \
                     -IG3 [fstdfield define $SourceField -IG3] \
                     -IG4 [fstdfield define $SourceField -IG4]
               }
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::GridCopyDesc>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Copy the grid descriptor to a new file.
#
# Parameters :
#  <Field>   : Fields from which to get the grid descriptor
#  <InFile>  : File from which to copy
#  <OutFile> : File to which to copy
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::GridCopyDesc { Field FileIn FileOut } {

   switch -regexp -- [fstdfield define $Field -GRTYP] {
      L|N|S    {  }
      default  { fstdfield read GPXTIC $FileIn -1 "" [fstdfield define $Field -IG1] [fstdfield define $Field -IG2] [fstdfield define $Field -IG3] "" ">>"
                 fstdfield read GPXTAC $FileIn -1 "" [fstdfield define $Field -IG1] [fstdfield define $Field -IG2] [fstdfield define $Field -IG3] "" "^^"
                 fstdfield write GPXTIC $FileOut 0 True
                 fstdfield write GPXTAC $FileOut 0 True
               }
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::GridGet>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Get the grid from a standard file.
#
# Parameters :
#  <File>    : Standard file path
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::GridGet { File } {
   variable Param

   set grids {}

   if { $File=="" } {
      return $grids
   }

   if { ![file exists $File] } {
      GenX::Log ERROR "Grid description file does not exists: $File"
      exit 1
   }

   if { [catch { fstdfile open GPXGRIDFILE read $File } ] } {
      GenX::Log ERROR "Could not open Grid description file: $File"
      exit 1
   }

   #----- If the descriptors have'nt been made in grids yet
   if { $Param(Process)=="" } {

      set tip1 1200
      #----- Read grid descriptors from source file and write grid field in aux file
      if { [llength [set tics [fstdfield find GPXGRIDFILE -1 "" -1 -1 -1 "" ">>"]]] } {
         foreach tic $tics {
            fstdfield read TIC GPXGRIDFILE $tic

            set ip1 [fstdfield define TIC -IP1]
            set ip2 [fstdfield define TIC -IP2]
            set ip3 [fstdfield define TIC -IP3]

            #----- Check if there are doubles
            if { [llength [fstdfield find GPXAUXFILE -1 "" $ip1 $ip2 $ip3 "" ">>"]]>1 } {
               GenX::Log WARNING "Found duplicate grid (IP1=$ip1 IP2=$ip2 IP3=$ip3), will not process it"
               continue
            }

            #----- Create a grid field
            fstdfield read TAC GPXGRIDFILE -1 "" $ip1 $ip2 $ip3 "" "^^"
            fstdfield create GRID [fstdfield define TIC -NI] [fstdfield define TAC -NJ] 1 Float32
            fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -GRTYP Z \
               -IG1 $ip1 -IG2 $ip2 -IG3 $ip3 -IP1 $tip1 -IP2 0 -IP3 $ip3
            incr tip1 -1

            #----- Write the grid and descriptors to output files
            fstdfield write TIC  GPXOUTFILE 0 True
            fstdfield write TAC  GPXOUTFILE 0 True

            fstdfield write TIC  GPXAUXFILE 0 True
            fstdfield write TAC  GPXAUXFILE 0 True
            fstdfield write GRID GPXAUXFILE -16 True $GenX::Param(Compress)
         }
      } else {
         #----- Otherwise, use the first field found as output grid
         fstdfield read GRID GPXGRIDFILE -1 "" -1 -1 -1 "" ""
         fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -IP1 $tip1
         fstdfield write GRID GPXAUXFILE -16 True $GenX::Param(Compress)
      }
   }

   #----- Read every grids available
   set i 0
   set grids { }
   foreach grid [fstdfield find GPXAUXFILE -1 "" -1 -1 -1 "" "GRID"] {
      fstdfield read GRID$i GPXAUXFILE $grid
      lappend grids GRID$i
      incr i
   }

   fstdfile close GPXGRIDFILE
   fstdfield free GRID TIC TAC

   #----- Check if we're in a sub-process, if so return only the needed grid
   if { $Param(Process)!="" } {
      return [lindex $grids $Param(Process)]
   } else {
      return $grids
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::CacheGet>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Get the data file from cache or load it into cache while
#            keeping the maximum data file number
#
# Parameters :
#  <File>    : Standard file path
#  <NoData>  : No data value to set
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::CacheGet { File { NoData "" } } {
   variable Param

   if { [lsearch -exact $Param(Cache) $File]==-1 } {
      gdalband read $File [gdalfile open DEMFILE read $File]
      if { $NoData!="" } {
         gdalband stats $File -nodata $NoData
      }
      gdalfile close DEMFILE
      lappend Param(Cache) $File

      if { [llength $Param(Cache)]>$Param(CacheMax) } {
         gdalband free [lindex $Param(Cache) 0]
         set Param(Cache) [lreplace $Param(Cache) 0 0]
      }
   }
   return $File
}

#----------------------------------------------------------------------------
# Name     : <GenX::CacheFree>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Clear the data cache.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::CacheFree { } {
   variable Param

   foreach band $Param(Cache) {
      gdalband free $band
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::ASTERGDEMFindFiles>
# Creation : Novembre 2007 - Gauthier JP - CMC/CMOE
#
# Goal     : Get the ASTER GDEM data filenames covering an area.
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#
# Return:
#   <Files>  : List of files with coverage intersecting with area
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::ASTERGDEMFindFiles { Lat0 Lon0 Lat1 Lon1 } {
   variable Path

   set files { }
   set lon0 [expr int(floor($Lon0/5))*5]
   set lon1 [expr int(ceil($Lon1/5))*5]
   set lat0 [expr int(floor($Lat0/5))*5]
   set lat1 [expr int(ceil($Lat1/5))*5]

   for { set lat $lat0 } { $lat<=$lat1 } { incr lat 5 } {
      for { set lon $lon0 } { $lon<=$lon1 } { incr lon 5 } {

         if { $lat<0 } {
            set y S
         } else {
            set y N
         }
         set la [expr abs($lat)]

         if { $lon<0 } {
            set x W
            set lo [expr abs($lon)]
         } else {
            set x E
            set lo $lon
         }

         if { [llength [set lst [glob -nocomplain [format "$Path(ASTERGDEM)/UNIT_%s%02i%s%03i/*_dem.tif" $y $la $x $lo]]]] } {
            set files [concat $files $lst]
         }
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::CANVECFindFiles>
# Creation : Novembre 2007 - Jean-Philippe Gauthier - CMC/CMOE
#
# Goal     : Get the CANVEC data filenames covering an area.
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#  <Layers>  : Layers to get
#
# Return:
#   <Files>  : List of files with coverage intersecting with area
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::CANVECFindFiles { Lat0 Lon0 Lat1 Lon1 Layers } {
   variable Path

   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $Path(NTS)/decoupage50k_2.shp] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }

   set ids [ogrlayer pick NTSLAYER50K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True]

   set files { }
   foreach id $ids {
      set feuillet [ogrlayer define NTSLAYER50K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 2]
      set sl   [string tolower [string range $feuillet 3 3]]
      set s50  [string range $feuillet 4 5]
      set path $Path(CANVEC)/$s250/$sl/$s250$sl$s50

      foreach layer $Layers {
         if { [llength [set lst [glob -nocomplain $path/*$layer*.shp]]] } {
            set files [concat $files $lst]
         }
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::SRTMFindFiles>
# Creation : Novembre 2007 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Get the SRTM data filenames covering an area.
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#
# Return:
#   <Files>  : List of files with coverage intersecting with area
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::SRTMFindFiles { Lat0 Lon0 Lat1 Lon1 } {
   variable Path

   set files { }
   set lonmax [expr int(ceil((180.0 + $Lon1)/5))]
   set latmax [expr int(ceil(24-((60.0 + $Lat0)/5)))]

   for { set lat [expr int(ceil(24-((60.0 + $Lat1)/5)))]} { $lat<=$latmax } { incr lat } {
      for { set lon [expr int(ceil((180.0 + $Lon0)/5))] } { $lon<=$lonmax } { incr lon } {
         if { [file exists [set path [format "$Path(SRTM)/srtm_%02i_%02i.TIF" $lon $lat]]] } {
            lappend files $path
         }
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::CDEDFindFiles>
# Creation : Novembre 2007 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Get the CDED data filenames covering an area.
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#  <Res>     : Resolution desiree (50 ou 250)
#
# Return:
#   <Files>  : List of files with coverage intersecting with area
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::CDEDFindFiles { Lat0 Lon0 Lat1 Lon1 { Res 50 } } {
   variable Path

   if { $Res!=50 && $Res!=250 } {
      GenX::Log ERROR "Wrong resolution, must be 50 or 250."
      exit 1
   }
   if { ![ogrlayer is NTSLAYER${Res}K] } {
      set nts_layer [lindex [ogrfile open SHAPE${Res}K read $Path(NTS)/decoupage${Res}k_2.shp] 0]
      eval ogrlayer read NTSLAYER${Res}K $nts_layer
   }

   #----- Pour les 250k : /data/cmod8/afseeer/CDED/045/h/045h/045h_0100_deme.tif +west
   #----- Pour les 50k  : /data/cmod8/afseeer/CDED/031/h/031h01/031h01_0101_deme.tif +west
   set files { }
   foreach id [ogrlayer pick NTSLAYER${Res}K [list $Lat0 $Lon0 $Lat1 $Lon0 $Lat1 $Lon1 $Lat0 $Lon1 $Lat0 $Lon0] True] {
      set feuillet [ogrlayer define NTSLAYER${Res}K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 2]
      set sl   [string tolower [string range $feuillet 3 3]]
      set s50  [string range $feuillet 4 5]

      if { $Res==50 } {
         set path $Path(CDED)/$s250/$sl/$s250$sl$s50
      } else {
         set path $Path(CDED)/$s250/$sl/$s250$sl
      }

      if { [llength [set lst [glob -nocomplain $path/*deme*.tif]]] } {
         lappend files $lst
      }
      if { [llength [set lst [glob -nocomplain $path/*demw*.tif]]] } {
         lappend files $lst
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::EOSDFindFiles>
# Creation : Novembre 2007 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Get the EOSD data filenames covering an area.
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#
# Return:
#   <Files>  : List of files with coverage intersecting with area
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::EOSDFindFiles { Lat0 Lon0 Lat1 Lon1 } {
   variable Path

   if { ![ogrlayer is NTSLAYER250K] } {
      set nts_layer [lindex [ogrfile open SHAPE250K read $Path(NTS)/decoupage250k_2.shp] 0]
      eval ogrlayer read NTSLAYER250K $nts_layer
   }

   set files { }
   foreach id [ogrlayer pick NTSLAYER250K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set feuillet [ogrlayer define NTSLAYER250K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 3]
      if { [file exists [set path $Path(EOSD)/${s250}_lc_1/${s250}_lc_1.tif]] } {
         lappend files $path
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::LCC2000VFindFiles>
# Creation : October 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Get the LCC2000V data filenames covering an area.
#
# Parameters :
#  <Lat0>    : Lower left corner latitude
#  <Lon0>    : Lower left corner longitude
#  <Lat1>    : Upper right corner latitude
#  <Lon1>    : Upper right corner longitude
#
# Return:
#   <Files>  : List of files with coverage intersecting with area
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::LCC2000VFindFiles { Lat0 Lon0 Lat1 Lon1 } {
   variable Path

   if { ![ogrlayer is NTSLAYER250K] } {
      set nts_layer [lindex [ogrfile open SHAPE250K read $Path(NTS)/decoupage250k_2.shp] 0]
      eval ogrlayer read NTSLAYER250K $nts_layer
   }

   set files { }
   foreach id [ogrlayer pick NTSLAYER250K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set feuillet [ogrlayer define NTSLAYER250K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 2]
      set maj  [string toupper [string range $feuillet 0 3]]

      if { [llength [set path [glob -nocomplain $Path(LCC2000V)/${s250}/*LCC2000-V_${maj}*.shp]]] } {
         set files [concat $files $path]
      }
   }

   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::UTMZoneDefine>
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
proc GenX::UTMZoneDefine { Lat0 Lon0 Lat1 Lon1 { Res 5 } { Name "" } } {
   variable Param

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

   georef define $Name -transform [list $longmin $Res 0.000000000000000 $latmin 0.000000000000000 $Res]

   GenX::Log DEBUG "UTM zone is $zone, with central meridian at $meridian and dimension $Param(Width)x$Param(Height)"

   return $Name
}
