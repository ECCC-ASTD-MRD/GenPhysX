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
#   GenX::Procs            { }
#   GenX::Log              { Type Message { Head True } }
#   GenX::Submit           { }
#   GenX::MetaData         { }
#   GenX::ParseArgs        { Argv Argc No Multi Cmd }
#   GenX::ParseCommandLine { }
#   GenX::ParseTarget      { } {
#   GenX::Continue         { }
#   GenX::CommandLine      { }
#   GenX::GetNML           { File }
#   GenX::FieldCopy        { InFile OutFile DateV Etiket IP1 IP2 IP3 TV NV }
#   GenX::GridClear        { Grids { Value 0.0 } }
#   GenX::GridLimits       { Grid }
#   GenX::GridCopy         { SourceField DestField }
#   GenX::GridCopyDesc     { Field FileIn FileOut }
#   GenX::GridGet          { }
#   GenX::GridGetFromGEM   { File }
#   GenX::GridGetFromNML   { File }
#   GenX::GridGetFromFile  { File { Copy True } }
#   GenX::CANVECFindFiles  { Lat0 Lon0 Lat1 Lon1 Layers }
#   GenX::SRTMFindFiles    { Lat0 Lon0Lat1 Lon1 }
#   GenX::CDEDFindFiles    { Lat0 Lon0 Lat1 Lon1 { Res 50 } }
#   GenX::EOSDFindFiles    { Lat0 Lon0Lat1 Lon1 }
#   GenX::CacheGet         { File { NoData "" } }
#   GenX::CacheFree        { }
#
#============================================================================

package require TclData
package require MetData

namespace eval GenX { } {
   global env
   variable Settings
   variable Path
   variable Data
   variable Meta
   variable Batch
   variable Log

   set Data(Version)   1.2                   ;#Application version

   set Data(Secs)      [clock seconds]       ;#To calculate execution time
   set Data(Compress)  False                 ;#Compress standard file output
   set Data(TileSize)  1024                  ;#Tile size to use for large dataset
   set Data(Cache)     {}                    ;#Input data cache list
   set Data(CacheMax)  20                    ;#Input data cache max

   set Data(ThreadPoolNb) 0                  ;#Number of threads to use
   set Data(ThreadPoolNo) 0                  ;#Number of current thread
   set Data(ThreadPool)   {}                 ;#List of threads

   set Meta(Procs)     {}                    ;#Metadata procedure registration list
   set Meta(Header)    ""                    ;#Metadata header
   set Meta(Footer)    ""                    ;#Metadata footer
   set Meta(Command)   ""                    ;#Launch command

   set Data(Vege)      ""                    ;#Vegetation data selected
   set Data(Soil)      ""                    ;#Soil type data selected
   set Data(Topo)      ""                    ;#Topography data selected
   set Data(Mask)      ""                    ;#Mask data selected
   set Data(GeoMask)   ""                    ;#Geographical mask data selected
   set Data(Aspect)    ""                    ;#Slope and aspect selected
   set Data(Check)     ""                    ;#Consistency checks
   set Data(Sub)       ""                    ;#Subgrid calculations selected
   set Data(Target)    ""                    ;#Model cible
   set Data(Biogenic)  ""                    ;#Biogenic emissions data selected

   set Data(Diag)      False                 ;#Diagnostics
   set Data(Z0Filter)  False                 ;#Filter roughness length
   set Data(Cell)      1                     ;#Grid cell dimension (1=1D(point 2=2D(area))

   set Data(Topos)     { USGS SRTM CDED250 CDED50 }
   set Data(Aspects)   { SRTM CDED250 CDED50 }
   set Data(Veges)     { USGS GLOBCOVER CCRS EOSD CORINE }
   set Data(Soils)     { USDA AGRC FAO }
   set Data(Masks)     { USGS GLOBCOVER CANVEC }
   set Data(GeoMasks)  { CANADA }
   set Data(Biogenics) { BELD VF }
   set Data(Checks)    { STD }
   set Data(Subs)      { STD }
   set Data(Targets)   { GEMMESO }             ;#Model cible

   set Path(Grid)        gemgrid               ;#GEM grid generator application
   set Path(OutFile)     genphysx              ;#Output file prefix
   set Path(GridFile)    ""                    ;#Grid definition file to use (standard file with >> ^^)
   set Path(NameFile)    ""                    ;#Namelist to use
   set Path(Script)      ""                    ;#User definition script

   set Batch(On)       False                 ;#Activate batch mode (soumet)
   set Batch(Host)     hawa                  ;#Host onto which to submit the job
   set Batch(Queue)    ""                    ;#Queue to use for the job
   set Batch(Mem)      1G                    ;#Memory needed for the job
   set Batch(Time)     7200                  ;#Time needed for the job
   set Batch(CPUs)     1                     ;#Number of CPUs to use for the job
   set Batch(Mail)     ""                    ;#Mail address to send completion info
   set Batch(Submit)   "/usr/local/env/armnlib/scripts/ord_soumet"

   #----- Various database paths

   if  { [info exists env(GENPHYSX_DBASE)] } {
      set Path(DBase) $env(GENPHYSX_DBASE)
   } else {
      set Path(DBase) /data/shared_1_b0/armn
#      set Path(DBase) /cnfs/ops/production/cmoe/geo
   }

   set Path(SandUSDA)  $Path(DBase)/db/sand_usda
   set Path(SandFAO)   $Path(DBase)/db/sand_fao
   set Path(SandAGRC)  $Path(DBase)/db/sand_argc
   set Path(ClayUSDA)  $Path(DBase)/db/clay_usda
   set Path(ClayFAO)   $Path(DBase)/db/clay_fao
   set Path(ClayAGRC)  $Path(DBase)/db/clay_argc
   set Path(TopoUSGS)  $Path(DBase)/db/me_usgs2002
   set Path(MaskUSGS)  $Path(DBase)/db/mg_usgs2002
   set Path(VegeUSGS)  $Path(DBase)/db/vg_usgs2002
   set Path(TopoLow)   $Path(DBase)/db/data_lres
   set Path(Grad)      $Path(DBase)/db/data_grad
   set Path(SRTM)      $Path(DBase)/SRTMv4
   set Path(CDED)      $Path(DBase)/CDED
   set Path(EOSD)      $Path(DBase)/EOSD
   set Path(NTS)       $Path(DBase)/NTS
   set Path(CANVEC)    $Path(DBase)/CanVec
   set Path(CORINE)    $Path(DBase)/CORINE
   set Path(GlobCover) $Path(DBase)/GlobCoverv2
   set Path(CCRS)      $Path(DBase)/CCRS-LC2005/
   set Path(Various)   $Path(DBase)/Various
   set Path(BELD3)     $Path(DBase)/BELD3

   #----- Log related variables

   array set Log { Level 2 MUST -1 ERROR 0 WARNING 1 INFO 2 DEBUG 3 };

   gdalfile error QUIET
}

#----------------------------------------------------------------------------
# Name     : <GenX::ThreadPoolInit>
# Creation : Novembre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Initialize thread pool.
#
# Parameters :
#   <Dir>    : Directory where to source the scripts
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::ThreadPoolInit { Dir } {
   variable Data

   GenX::Log INFO "Initializing thread pool with $Data(ThreadPoolNb) threads"
   for { set n 0 } { $n<$Data(ThreadPoolNb) } { incr n } {
      lappend Data(ThreadPool) [set tid [thread::create -joinable "source $Dir/GenX.tcl; source $Dir/GeoPhysX.tcl; thread::wait" ]]
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::TThreadPoolSend>
# Creation : Novembre 2008 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Sends job to next thread.
#
# Parameters :
#   <args>   : Command to be executed by the thread
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::ThreadPoolSend { args } {
   variable Data

   #----- Get the next thread id
   set Data(ThreadPoolNo) [expr [incr Data(ThreadPoolNo)]>=$Data(ThreadPoolNb)?0:$Data(ThreadPoolNo)]

   #----- Transfer job to next thread
   thread::send -async [lindex $Data(ThreadPool) $Data(ThreadPoolNo)] $args
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
   variable Data
   variable Path
   variable Batch

   upvar #0 argv gargv

   set host [info hostname]
   set rdir /tmp/GenPhysX[pid]_$Data(Secs)
   set rargv ""

   #----- Create job script
   set f [open [set job $env(TMPDIR)/GenPhysX[pid]] w 0755]

   puts $f "#!/bin/ksh\nset -x"
   if { [info exists env(gem_dynversion)] } {
      puts $f ". r.sm.dot gem $env(gem_dynversion)"
   }

   puts $f "\nexport GENPHYSX_DBASE=$Path(DBase)\nexport SPI_PATH=$env(SPI_PATH)\nexport GENPHYSX_PRIORITY=-0"
   puts $f "export GENPHYSX_BATCH=\"$gargv\"\n"
   puts $f "trap \"cd ..; rm -fr $rdir\" 0 1 2 3 6 15 30"

   puts $f "mkdir $rdir"
   puts $f "cd $rdir"

   if { $Path(GridFile)!="" } {
      puts $f "scp $host:[file normalize $Path(GridFile)] ."
      append rargv " -gridfile [file tail $Path(GridFile)]"
   }
   if { $Path(NameFile)!="" } {
      puts $f "scp $host:[file normalize $Path(NameFile)] ."
      append rargv " -nml [file tail $Path(NameFile)]"
   }
   if { $Path(Script)!="" } {
      puts $f "scp $host:[file normalize $Path(Script)] ."
      append rargv " -script [file tail $Path(Script)]"
   }
   if { [file exists $Path(OutFile).fst] } {
      puts $f "scp $host:[file normalize ${Path(OutFile)}.fst] ."
   }
   if { [file exists ${Path(OutFile)}_aux.fst] } {
      puts $f "scp $host:[file normalize ${Path(OutFile)}_aux.fst] ."
   }

   set ldir [file dirname [file normalize $Path(OutFile)]]
   append rargv " -result [file tail $Path(OutFile)]"

   #----- Remove batch flag from arguments
   set idx [lsearch -exact $gargv "-batch"]
   set gargv [lreplace $gargv $idx $idx]

   puts $f "\n[file normalize [info script]] $gargv \\\n   $rargv\n"
   puts $f "scp [file tail $Path(OutFile)]* $host:$ldir\ncd ..\nrm -f -r $rdir"

   if { $Batch(Mail)!="" } {
      puts $f "echo $Path(OutFile) | mail -s \"GenPhysX job done\" $Batch(Mail) "
   }
   close $f

   #----- Launch job script
   if { ![file exists $Batch(Submit)] } {
      puts stderr "Could not find job submission program $Batch(Submit)"
      exit 1
   } else {
      puts stdout "Using $Batch(Submit) to launch job ... "
      set err [catch { exec $Batch(Submit) $job -cpus $Batch(CPUs) -threads 2 -mach $Batch(Host) -t $Batch(Time) -cm $Batch(Mem) 2>@1 } msg]
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
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Procs { } {
   variable Meta

   lappend Meta(Procs) [info level [expr [info level] -1]]
}

#----------------------------------------------------------------------------
# Name     : <GenX::Log>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Display verbose messages.
#
# Parameters :
#  <Type>    : Type de message (ERROR,WARNING,INFO,DEBUG,...)
#  <Message> : Message to display
#  <Head>    : Afficher l'info du stack
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Log { Type Message { Head True } } {
   variable Log

   set head " "

   if { $Log($Type)<=$Log(Level) } {
      if { $Head } {
         set head " [lindex [info level [expr [info level]-1]] 0]: "
      }
      if { $Type=="ERROR" } {
         puts stderr "($Type)$head$Message"
      } else {
         puts "($Type)$head$Message"
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
#
# Return:
#
# Remarks :
#    Metadata includes date-time and version, procedure used, and gem_settings file
#----------------------------------------------------------------------------
proc GenX::MetaData { } {
   global env
   global argv
   variable Data
   variable Meta
   variable Path

   #----- Description of vesion used
   set version "GenX($Data(Version))"
   catch { append version ", GeoPhysX($GeoPhysX::Data(Version))" }
   catch { append version ", BioGenX($BioGenX::Data(Version))" }

   #----- Generation date et parameters used
   set meta "Generated      : [clock format [clock seconds]] on [info hostname] by $env(USER)\n"

   if  { [info exists env(GENPHYSX_BATCH)] } {
      append meta "Call parameters: [info script] $env(GENPHYSX_BATCH)\n"
   } else {
      append meta "Call parameters: [info script] [join $argv " "]\n"
   }
   append meta "SPI API version: $env(SPI_PATH)\nCode base      : $version\n"

   #----- Append script if any
   if { $Path(Script)!="" } {
      append meta "Script used    : $Path(Script)\n"
      set f [open $Path(Script) r]
      while { ![eof $f] } {
         append meta "   [gets $f]\n"
      }
      close $f
   }

   append meta $Meta(Header)
   append meta "Processing used:\n   [join $Meta(Procs) "\n   "]\n"
   if { [file exists $Path(NameFile)] } {
      append meta "\nGEM namelist   : { \n[exec cat $Path(NameFile)]\n }"
   }
   append meta $Meta(Footer)

   #----- Encode everyting
   set fld [MetData::TextCode $meta]
   fstdfield define $fld -NOMVAR META
   fstdfield write $fld GPXOUTFILE 0 True

   #----- Tada ...
   puts "\nExecution time: [expr [clock seconds]-$Data(Secs)]s"
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
#   <Multi>  : Multiplicite des valeurs (0=True,1=1 valeur,2=Multiples valeurs)
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
         if { $Multi==1 } {
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

      if { $No!=$idx } {
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
   variable Data
   variable Path
   variable Batch
   variable Log

   puts stderr "Arguments must be:"
   puts stderr "
   Information parameters:
      \[-help\]     [format "%-30s : This information" ""]
      \[-version\]  [format "%-30s : GenPhysX version" ""]
      \[-verbose\]  [format "%-30s : Trace level (0 none, 1 some, 2 more, 3 debug)" ($Log(Level))]

   Input parameters:
      \[-nml\]      [format "%-30s : GEM namelist definition file" ($Path(NameFile))]
      \[-gridfile\] [format "%-30s : FSTD file to get the grid from if no GEM namelist" ($Path(GridFile))]
      \[-result\]   [format "%-30s : Result filename" ($Path(OutFile))]
      \[-target\]   [format "%-30s : Set necessary flags for target model {$Data(Targets)}" ($Data(Target))]
      \[-script\]   [format "%-30s : User definition script to include" ""]

   Processing parameters:
      Specify databases in order of processing joined by + ex: STRM+USGS

      \[-topo\]     [format "%-30s : Topography method(s) among {$Data(Topos)}" ([join $Data(Topo)])]
      \[-mask\]     [format "%-30s : Mask method, one of {$Data(Masks)}" ([join $Data(Mask)])]
      \[-geomask\]  [format "%-30s : Mask method, one of {$Data(GeoMasks)}" ([join $Data(GeoMask)])]
      \[-vege\]     [format "%-30s : Vegetation method(s) among {$Data(Veges)}" ([join $Data(Vege)])]
      \[-soil\]     [format "%-30s : Soil method(s) among {$Data(Soils)}" ([join $Data(Soil)])]
      \[-aspect\]   [format "%-30s : Slope and aspect method(s) among {$Data(Aspects)}" ([join $Data(Aspect)])]
      \[-biogenic\] [format "%-30s : Biogenic method(s) among {$Data(Biogenics)}" ([join $Data(Biogenic)])]
      \[-check\]    [format "%-30s : Do consistency checks {$Data(Checks)}" ($Data(Check))]
      \[-subgrid\]  [format "%-30s : Calculates sub grid fields {$Data(Subs)}" ($Data(Sub))]
      \[-diag\]     [format "%-30s : Do diagnostics (Not implemented yet)" ""]

   Specific processing parameters:
      \[-z0filter\] [format "%-30s : Apply GEM filter to roughness length" ""]
      \[-celldim\]  [format "%-30s : Grid cell dimension (1=point, 2=area)" ($Data(Cell))]

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

   #----- If we're not in batch mode, ask
   if  { ![info exists env(GENPHYSX_BATCH)] } {
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
   variable Data
   variable Path
   variable Batch

   upvar argc gargc
   upvar argv gargv

   #----- Check if architecture is valid
   if { ![string match -nocase "Linux" [exec uname]] } {
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
         "version"   { puts "$Data(Version)"; exit 0 }
         "verbose"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Log(Level)] }
         "result"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(OutFile)] }
         "target"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Target) $GenX::Data(Targets)]; GenX::ParseTarget; incr flags }
         "gridfile"  { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(GridFile)] }
         "nml"       { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(NameFile)] }
         "dbase"     { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(DBase)] }
         "batch"     { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Batch(On)] }
         "mach"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Host)] }
         "t"         { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Time)] }
         "cm"        { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Mem)] }
         "mail"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Mail)] }
         "topo"      { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Data(Topo) $GenX::Data(Topos)]; incr flags }
         "mask"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Mask) $GenX::Data(Masks)]; incr flags }
         "geomask"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(GeoMask) $GenX::Data(GeoMasks)]; incr flags }
         "vege"      { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Data(Vege) $GenX::Data(Veges)]; incr flags }
         "soil"      { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Data(Soil) $GenX::Data(Soils)]; incr flags }
         "subgrid"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Sub)]; incr flags }
         "aspect"    { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Data(Aspect)]; incr flags }
         "biogenic"  { set i [GenX::ParseArgs $gargv $gargc $i 2 GenX::Data(Biogenic) $GenX::Data(Biogenics)]; incr flags }
         "check"     { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Check)]; incr flags }
         "diag"      { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Data(Diag)] }
         "z0filter"  { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Data(Z0Filter)]; incr flags }
         "celldim"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Cell)] }
         "script"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(Script)] }
         "help"      { GenX::CommandLine ; exit 1 }
         default     { GenX::Log ERROR "Invalid argument [lindex $gargv $i]"; GenX::CommandLine ; exit 1 }
      }
   }

   #----- If no processing is specified, we use the default target
   if { !$flags } {
      set Data(Target) [lindex $GenX::Data(Targets) 0]
      GenX::ParseTarget
      GenX::Log WARNING "No data processing were specified, will use default target $Data(Target)"
      GenX::Continue
   }

   #----- Check for user definitiond
   if { $GenX::Path(Script)!="" } {
      source $Path(Script)
   }

   #----- Check dependencies
   if { $Data(Vege)!="" } {
      if { $Data(Mask)=="" } {
         GenX::Log ERROR "To generate vegetation type fields you need to generate the mask"
         GenX::Continue
      }
   }

   if { $Data(Sub)!="" } {
      if { $Data(Mask)=="" } {
         GenX::Log ERROR "To generate sub-grid post-processed fields you need to generate the mask"
         GenX::Continue
      }
      if { $Data(Topo)=="" } {
         GenX::Log ERROR "To generate sub-grid post-processed fields you need to generate the topography"
         GenX::Continue
      }
   }

   if { $Data(Biogenic)!="" } {
      if { $Data(Vege)=="" } {
            GenX::Log ERROR "To generate biogenic emissions fields you need to generate the vegetation type fields (-vege option)"
            GenX::Continue
      }
      if { $Data(Check)=="" } {
            GenX::Log ERROR "To generate biogenic emissions fields you must use the -check option."
            GenX::Continue
      }
   }

   #----- Check if a filename is included in result filename
   if { [file isdirectory $Path(OutFile)] } {
      append Path(OutFile) genphysx
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
      cd [file dirname [file normalize $Path(OutFile)]]
   }

   catch { file delete $Path(OutFile).fst_gfilemap.txt }
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
   variable Data

   switch $Data(Target) {
      "GEMMESO" { set Data(Topo)     "USGS"
                  set Data(Vege)     "USGS"
                  set Data(Mask)     "USGS"
                  set Data(Soil)     "USDA AGRC FAO"
                  set Data(Check)    "STD"
                  set Data(Sub)      "STD"
                  set Data(Z0Filter) True
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
   variable Data

   foreach field [fstdfield find $FileIn $DateV $Etiket $IP1 $IP2 $IP3 $TV $NV] {
      fstdfield read GPXTMP $FileIn $field
      fstdfield write GPXTMP $FileOut 0 True $GenX::Data(Compress)
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
# Goal     : Get the grid from the first availabel way (standard file,grille or gem settings).
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::GridGet { } {
   variable Path

   if { [file exists $Path(GridFile)] } {
     set grids [GenX::GridGetFromFile $Path(GridFile)]
   } elseif { [file exists $Path(OutFile).fst] } {
     set grids [GenX::GridGetFromFile $Path(OutFile).fst False]
   } elseif { [file exists $Path(NameFile)] } {
     set grids [GenX::GridGetFromGEM $Path(NameFile)]
   } else {
      GenX::Log ERROR "Could not find a grid definition either from a standard file or a namelist"
      exit 1
   }
   return $grids
}

#----------------------------------------------------------------------------
# Name     : <GenX::GridGetFromGEM>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Get the grid from grille (GEM procs).
#
# Parameters :
#  <File>    : Namelist file path
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::GridGetFromGEM { File } {
   variable Path
   global   env

   if { ![info exists env(GEM)] } {
       GenX::Log ERROR "GEM environment not loaded (. r.sm.dot gem x.x.x)"
       exit 1
   }

   GenX::Log INFO "Found GEM version ([file tail $env(GEM)])"

   set grid ""
   catch { set grid [exec which $Path(Grid)] }
   if { $grid=="" } {
      GenX::Log ERROR "Could not find \"$Path(Grid)\". Please make sure GEM environment is loaded first (. r.sm.dot gem x.x.x)"
      exit 1
   }

   if { [file normalize $File]!=[file normalize gem_settings.nml] } {
      exec ln -fs $File gem_settings.nml
   }

   #----- Erase tape1 and gfilemap.txt since gemgrid won't run if they already exist
   catch { file delete -force tape1 gfilemap.txt }
   catch { exec $grid }
   catch { file rename -force gfilemap.txt ${Path(OutFile)}.fst_gfilemap.txt }

   fstdfile open GPXGRIDFILE read tape1

   foreach etiket { "GRDZ" "GRDU" "GRDV" } ip1 { 1200 1199 1198 } {
      fstdfield read TIC GPXGRIDFILE -1 "$etiket" -1 -1 -1 "" ">>"
      fstdfield read TAC GPXGRIDFILE -1 "$etiket" -1 -1 -1 "" "^^"
      fstdfield free GRID
      fstdfield create GRID [fstdfield define TIC -NI] [fstdfield define TAC -NJ] 1 Float32
      fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -GRTYP Z \
         -IG1 [fstdfield define TIC -IP1] -IG2 [fstdfield define TIC -IP2] -IG3 [fstdfield define TIC -IP3] -IP1 $ip1

      fstdfield write TIC  GPXOUTFILE -32 True
      fstdfield write TAC  GPXOUTFILE -32 True

      fstdfield write TIC  GPXAUXFILE -32 True
      fstdfield write TAC  GPXAUXFILE -32 True
      fstdfield write GRID GPXAUXFILE -32 True
   }
   fstdfile close GPXGRIDFILE
   file delete -force tape1

   fstdfield read GRID  GPXAUXFILE -1 "" 1200 -1 -1 "" "GRID"
   fstdfield read GRIDU GPXAUXFILE -1 "" 1199 -1 -1 "" "GRID"
   fstdfield read GRIDV GPXAUXFILE -1 "" 1198 -1 -1 "" "GRID"

   fstdfield free TIC TAC

   return [list GRID GRIDU GRIDV]
}

#----------------------------------------------------------------------------
# Name     : <GenX::GridGetFromNML>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Get the grid from internal procs.
#
# Parameters :
#  <File>    : Namelist file path
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::GridGetFromNML { File } {
   variable Path

   GenX::GetNML $File

   fstdgrid zgrid TIC TAC GenX::Settings
   fstdfield create GRID [fstdfield define TIC -NI] [fstdfield define TAC -NJ] 1 Float32
   fstdfield define GRID -NOMVAR "GRID" -TYPVAR C \
      -GRTYP Z -IG1 [fstdfield define TIC -IP1] -IG2 [fstdfield define TIC -IP2] -IG3 [fstdfield define TIC -IP3] -IP1 1200
   fstdfield define GRID -positional TIC TAC

   fstdfield write TIC GPXOUTFILE -32 True
   fstdfield write TAC GPXOUTFILE -32 True

   fstdfield write TIC  GPXAUXFILE -32 True
   fstdfield write TAC  GPXAUXFILE -32 True
   fstdfield write GRID GPXAUXFILE -32 True

   fstdfield read GRID GPXAUXFILE -1 "" 1200 -1 -1 "" "GRID"
   fstdfield free TIC TAC

   return GRID
}

#----------------------------------------------------------------------------
# Name     : <GenX::GridGetFromFile>
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
proc GenX::GridGetFromFile { File { Copy True } } {

   if { [catch { fstdfile open GPXGRIDFILE read $File } ] } {
      GenX::Log ERROR "Could not open $File."
      exit 1
   }

   #----- Read grid descriptors from source file and write grid field in aux file
   if { $Copy } {
      set ip1 1200
      if { [llength [set tics [fstdfield find GPXGRIDFILE -1 "" -1 -1 -1 "" ">>"]]] } {
         foreach tic $tics {
            fstdfield read TIC GPXGRIDFILE $tic
            fstdfield read TAC GPXGRIDFILE -1 "" [fstdfield define TIC -IP1] [fstdfield define TIC -IP2] [fstdfield define TIC -IP3] "" "^^"
            fstdfield create GRID [fstdfield define TIC -NI] [fstdfield define TAC -NJ] 1 Float32
            fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -GRTYP Z \
               -IG1 [fstdfield define TIC -IP1] -IG2 [fstdfield define TIC -IP2] -IG3 [fstdfield define TIC -IP3] -IP1 $ip1
            incr ip1 -1

            fstdfield write TIC  GPXOUTFILE -32 True
            fstdfield write TAC  GPXOUTFILE -32 True

            fstdfield write TIC  GPXAUXFILE -32 True
            fstdfield write TAC  GPXAUXFILE -32 True
            fstdfield write GRID GPXAUXFILE -32 True
         }
      } else {
         fstdfield read GRID GPXGRIDFILE -1 "" -1 -1 -1 "" ""
         fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -IP1 $ip1
         fstdfield write GRID GPXAUXFILE -32 True
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

   return $grids
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
   variable Data

   if { [lsearch -exact $Data(Cache) $File]==-1 } {
      gdalband read $File [gdalfile open DEMFILE read $File]
      if { $NoData!="" } {
         gdalband stats $File -nodata $NoData
      }
      gdalfile close DEMFILE
      lappend Data(Cache) $File

      if { [llength $Data(Cache)]>$Data(CacheMax) } {
         gdalband free [lindex $Data(Cache) 0]
         set Data(Cache) [lreplace $Data(Cache) 0 0]
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
   variable Data

   foreach band $Data(Cache) {
      gdalband free $band
   }
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
#
# Return:
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
