#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : GenX.tcl
# Creation   : Septembre 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Description: Definitions of global fonctions needed by the generator
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#   GenX::Procs            { }
#   GenX::Trace            { Message { Level 1 } }
#   GenX::Submit           { }
#   GenX::MetaData         { { Header "" } { Extra "" } }
#   GenX::ParseArgs        { Argv Argc No Multi Cmd }
#   GenX::ParseCommandLine { }
#   GenX::CommandLine      { }
#   GenX::GetNML           { File }
#   GenX::FieldCopy        { InFile OutFile DateV Etiket IP1 IP2 IP3 TV NV }
#   GenX::GridClear        { Grids { Value 0.0 } }
#   GenX::GridLimits       { Grid }
#   GenX::GridCopy         { Field FileIn FileOut }
#   GenX::GridGet          { }
#   GenX::GridGetFromGEM   { File }
#   GenX::GridGetFromNML   { File }
#   GenX::GridGetFromFile  { File }
#   GenX::CANVECFindFiles  { Lat0 Lon0 Lat1 Lon1 Layers }
#   GenX::SRTMFindFiles    { Lat0 Lon0Lat1 Lon1 }
#   GenX::DNECFindFiles    { Lat0 Lon0 Lat1 Lon1 { Res 50 } }
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
   variable Batch

   set Data(Version)   0.16                  ;#Application version

   set Data(Verbose)   1                     ;#Level of verbose
   set Data(Compress)  False                 ;#Compress standard file output
   set Data(TileSize)  1024                  ;#Tile size to use for large dataset
   set Data(Cache)     {}                    ;#Input data cache list
   set Data(CacheMax)  20                    ;#Input data cache max
   set Data(Procs)     {}                    ;#Procedure registration list

   set Data(Vege)      USGS                  ;#Vegetation data selected
   set Data(Soil)      USDA                  ;#Soit type data selected
   set Data(Topo)      USGS                  ;#Topography data selected
   set Data(Mask)      USGS                  ;#Mask data selected
   set Data(Post)      True                  ;#Post selected
   set Data(Aspect)    False                 ;#Slope and aspect selected

   set Data(Topos)     { NONE USGS SRTM DNEC50 DNEC250 }
   set Data(Veges)     { NONE USGS EOSD CORINE }
   set Data(Soils)     { NONE USDA }
   set Data(Masks)     { NONE USGS CANVEC }

   set Path(Work)        ""                    ;#Working directory
   set Path(Grid)        gemgrid               ;#GEM grid generator application
   set Path(OutFile)     genphysx              ;#Output file prefix
   set Path(GridFile)    ""                    ;#Grid definition file to use (standard file with >> ^^)
   set Path(NameFile)    ""                    ;#Namelist to use
   set Path(ModelTarget) ""                    ;#Model cible

   set Batch(On)       False                 ;#Activate batch mode (soumet)
   set Batch(Host)     [info hostname]       ;#Host onto which to submit the job
   set Batch(Mem)      500                   ;#Memory needed for the job
   set Batch(Time)     7200                  ;#Time needed for the job
   set Batch(Mail)     ""                    ;#Mail address to send completion info

   #----- Various database paths

   if  { [info exists env(GENPHYSXDB_BASE)] } {
      set Path(DBase) $env(GENPHYSXDB_BASE)
   } else {
      set Path(DBase) /data/dormrb04/genphysx/data
   }

   set Path(Topo)  db/me_usgs2002
   set Path(Vege)  db/vg_usgs2002
   set Path(Mask)  db/mg_usgs2002
   set Path(Sand)  { db/sand_usda db/sand_fao db/sand_argc }
   set Path(Clay)  { db/clay_usda db/clay_fao db/clay_argc }
   set Path(TopoL) data_lres
   set Path(TopoD) data_hres
   set Path(Gxy)   data_grad

   set Path(SRTM)    /data/cmod8/afseeer/SRTMv4
   set Path(DNEC)    /data/cmod8/afseeer/DNEC
   set Path(EOSD)    /data/cmod8/afseeer/EOSD
   set Path(NTS)     /data/cmod8/afseeer/NTS
   set Path(CANVEC)  /data/cmod8/afseeer/CanVec
   set Path(CORINE)  /data/cmod8/afseeer/CORINE
   set Path(Various) /data/cmod8/afseeer/Various

   gdalfile error QUIET
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
   set env(GENPHYSXDB_BASE) $Path(DBase)

   if { ![file isdirectory $Path(Work)] } {
      puts stderr "GenX::Submit: (Error) You have to specify a valid working directory"
      exit 1
   }

   set job $env(TMPDIR)/GenX[pid]
   set f [open $job w]
   puts $f "#!/bin/ksh\nset -x"
   if { [info exists env(gem_dynversion)] } {
      puts $f ". r.sm.dot gem $env(gem_dynversion)"
   }
   puts $f "export SPI_PATH=$env(SPI_PATH)\nexport GENPHYSXDB_BASE=$env(GENPHYSXDB_BASE)\n[info script] $gargv -batch 0"

   if { $Batch(Mail)!="" } {
      puts $f "mail -s \"GenPhysX job done\" $Batch(Mail) < $job"
   }
   puts $f "rm -f $job"
   close $f

   exec chmod 755 $job
   exec soumet $job -mach $Batch(Host) -cpus 2 -t $Batch(Time) -cm $Batch(Mem)M
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
   variable Data

   lappend Data(Procs) [info level [expr [info level] -1]]
}

#----------------------------------------------------------------------------
# Name     : <GenX::Trace>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Display verbose messages.
#
# Parameters :
#  <Message> : Message to display
#  <Level>   : Verbose level
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Trace { Message { Level 1 } } {
   variable Data

   if { $Level<=$Data(Verbose) } {
      puts $Message
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::MetaData>
# Creation : Novembre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : Record metadata info in a standard RPN Field.
#
# Parameters :
#   <Header> : String to add itn the metadata header (ex: extensio version info)
#   <Extra>  : Extra info to add
#
# Return:
#
# Remarks :
#    Metadata includes date-time and version, procedure used, and gem_settings file
#----------------------------------------------------------------------------
proc GenX::MetaData { { Header "" } { Extra "" } } {
   global env
   variable Data
   variable Path

   #----- Description des versions utilisees

   set version "[info script] and GenX($Data(Version))"
   catch { append version ", GeoPhysX($GeoPhysX::Data(Version))" }
   catch { append version ", BioGenX($BioGenX::Data(Version))" }

   set meta "Generated      : [clock format [clock seconds]] on [info hostname] by $env(USER)\nCode base      : $version\n"
   append meta $Header
   append meta "Processing used:\n   [join $Data(Procs) "\n   "]\n"
   if { [file exists $Path(NameFile)] } {
      append meta "\nGEM namelist   : { \n[exec cat $Path(NameFile)]\n }"
   }
   append meta $Extra

   set fld [MetData::TextCode $meta]
   fstdfield define $fld -NOMVAR META
   fstdfield write $fld GPXOUTFILE 0 True
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

      #----- Parcourir les arguments du token specifie
      while { ([string is double [lindex $Argv $No]] || [string index [lindex $Argv $No] 0]!="-") && $No<$Argc } {
         #----- Check for argument validity
         set v [lindex $Argv $No]
         if { [llength $Values] && [lsearch -exact $Values $v]==-1 } {
            puts stderr "(Error) Invalid value for parameter [lindex $Argv [expr $No-1]], must be one of { $Values }"
            exit 1;

         }
         if { $Multi==1 } {
            set var $v
         } else {
            lappend var $v
         }
         incr No
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

   puts stderr "Arguments must be:"
   puts stderr "
   Information parameters:
      \[-help\]     [format "%-30s : This information" ""]
      \[-version\]  [format "%-30s : GenPhysX version" ""]

   Input parameters:
      \[-verbose\]  [format "%-30s : Trace level (0 none,1 some ,2 more)" ($Data(Verbose))]
      \[-nml\]      [format "%-30s : GEM namelist definition file" ($Path(NameFile))]
      \[-gridfile\] [format "%-30s : FSTD file to get the grid from if no GEM namelist" ($Path(GridFile))]
      \[-result\]   [format "%-30s : Result filename" ($Path(OutFile))]
      \[-workdir\]  [format "%-30s : Working directory" ($Path(Work))]
      \[-target\]   [format "%-30s : Model target (GEM, GEM-MACH, ...)" ($Path(ModelTarget))]

   Processing parameters:
      \[-topo\]     [format "%-30s : Topography method {$Data(Topos)}" ($Data(Topo))]
      \[-mask\]     [format "%-30s : Mask method {$Data(Masks)}" ($Data(Mask))]
      \[-vege\]     [format "%-30s : Vegetation method {$Data(Veges)}" ($Data(Vege))]
      \[-soil\]     [format "%-30s : Soil method {$Data(Soils)}" ($Data(Soil))]
      \[-aspect\]   [format "%-30s : Calculates aspect and slope" ""]

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

   if { !$gargc } {
      GenX::CommandLine
      exit 1
   }

   #----- Parse arguments
   for { set i 0 } { $i < $gargc } { incr i } {
      switch -exact [string trimleft [lindex $gargv $i] "-"] {
         "version"   { puts "$Data(Version)"; exit 0 }
         "verbose"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Verbose)] }
         "result"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(OutFile)] }
         "target"    { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(ModelTarget)] }
         "gridfile"  { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(GridFile)] }
         "workdir"   { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(Work)] }
         "nml"       { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(NameFile)] }
         "dbase"     { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Path(DBase)] }
         "batch"     { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Batch(On)] }
         "mach"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Host)] }
         "t"         { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Time)] }
         "cm"        { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Mem)] }
         "mail"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Batch(Mail)] }
         "topo"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Topo) $GenX::Data(Topos)] }
         "mask"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Mask) $GenX::Data(Masks)] }
         "vege"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Vege) $GenX::Data(Veges)] }
         "soil"      { set i [GenX::ParseArgs $gargv $gargc $i 1 GenX::Data(Soil) $GenX::Data(Soils)] }
         "post"      { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Data(Post)] }
         "aspect"    { set i [GenX::ParseArgs $gargv $gargc $i 0 GenX::Data(Aspect)] }
         default     { GenX::CommandLine ; exit 1 }
      }
   }

   #----- If batch mode enabled, submit the job and exit
   if { $Batch(On) } {
      GenX::Submit
   }

   #----- Go to work directory
   if { $Path(Work)!="" } {
      cd $Path(Work)
   }

   set Path(OutFile) [file rootname $Path(OutFile)]
   catch { file delete $Path(OutFile)_gfilemap.txt }
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

   if { ![file exists $File] } {
      GenX::Trace "GenX::GetNML: (Warning) Could not read the namelist" 0
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
   GenX::Trace "GenX::GetNML: Read the following settings:" 2
   if { $GenX::Data(Verbose)>=2 } {
      parray GenX::Settings
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
      GenX::GridCopy GPXTMP $FileIn $FileOut
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

#----------------------------------------------------------------------------
# Name     : <GenX::GridCopy>
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
proc GenX::GridCopy { Field FileIn FileOut } {

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
   } elseif { [file exists $Path(NameFile)] } {
     set grids [GenX::GridGetFromGEM $Path(NameFile)]
   } else {
      puts stderr "GenX::GridGet: (Error) Could not find a grid definition either from a standard file or a namelist"
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

   GenX::Trace "GenX::GridGetFromGEM: Found GEM version ([file tail $env(GEM)])"

   set grid ""
   catch { set grid [exec which $Path(Grid)] }
   if { $grid=="" } {
      puts stderr "GenX::GridGetFromGEM: (Error) Could not find \"$Path(Grid)\". Please load a GEM environment first (. r.sm.dot gem x.x.x)"
      exit 1
   }

   if { $File!="gem_settings.nml" } {
      exec ln -fs $File gem_settings.nml
   }

   #----- Erase tape1 and gfilemap.txt since gemgrid won't run if they already exist
   catch { file delete -force tape1 gfilemap.txt }
   catch { exec $grid }
   catch { file rename -force gfilemap.txt ${Path(OutFile)}_gfilemap.txt }

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

      fstdfield write TIC  GPXSECFILE -32 True
      fstdfield write TAC  GPXSECFILE -32 True
      fstdfield write GRID GPXSECFILE -32 True
   }
   fstdfile close GPXGRIDFILE
   file delete -force tape1

   fstdfield read GRID  GPXSECFILE -1 "" 1200 -1 -1 "" "GRID"
   fstdfield read GRIDU GPXSECFILE -1 "" 1199 -1 -1 "" "GRID"
   fstdfield read GRIDV GPXSECFILE -1 "" 1198 -1 -1 "" "GRID"

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

   fstdfield write TIC  GPXSECFILE -32 True
   fstdfield write TAC  GPXSECFILE -32 True
   fstdfield write GRID GPXSECFILE -32 True

   fstdfield read GRID GPXSECFILE -1 "" 1200 -1 -1 "" "GRID"
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
proc GenX::GridGetFromFile { File } {

   if { [catch { fstdfile open GPXGRIDFILE read $File } ] } {
      puts stderr "GenX::GridGetFromFile: (Error) Could not open $File."
      exit 1
   }

   set ip1 1200
   if { [llength [set tics [fstdfield find GPXGRIDFILE -1 "" -1 -1 -1 "" ">>"]]] } {
      foreach tic [fstdfield find GPXGRIDFILE -1 "" -1 -1 -1 "" ">>"] {
         fstdfield read TIC GPXGRIDFILE $tic
         fstdfield read TAC GPXGRIDFILE -1 "" [fstdfield define TIC -IP1] [fstdfield define TIC -IP2] [fstdfield define TIC -IP3] "" "^^"
         fstdfield create GRID [fstdfield define TIC -NI] [fstdfield define TAC -NJ] 1 Float32
         fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -GRTYP Z \
            -IG1 [fstdfield define TIC -IP1] -IG2 [fstdfield define TIC -IP2] -IG3 [fstdfield define TIC -IP3] -IP1 $ip1
         incr ip1 -1

         fstdfield write TIC  GPXOUTFILE -32 True
         fstdfield write TAC  GPXOUTFILE -32 True

         fstdfield write TIC  GPXSECFILE -32 True
         fstdfield write TAC  GPXSECFILE -32 True
         fstdfield write GRID GPXSECFILE -32 True
      }
   } else {
      fstdfield read GRID GPXGRIDFILE -1 "" -1 -1 -1 "" ""
      fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -IP1 $ip1
      fstdfield write GRID GPXSECFILE -32 True
   }
   fstdfile close GPXGRIDFILE

   fstdfield read GRID GPXSECFILE -1 "" 1200 -1 -1 "" "GRID"
   catch { fstdfield read GRIDU GPXSECFILE -1 "" 1199 -1 -1 "" "GRID" }
   catch { fstdfield read GRIDV GPXSECFILE -1 "" 1198 -1 -1 "" "GRID" }

   return GRID
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
      set nts_layer [lindex [ogrfile open SHAPE50K read $Path(NTS)/50kindex.shp] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }
   set ids [ogrlayer pick NTSLAYER50K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True]

   set files { }
   foreach id $ids {
      set feuillet [ogrlayer define NTSLAYER50K -feature $id snrc]
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
# Name     : <GenX::DNECFindFiles>
# Creation : Novembre 2007 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Get the DNEC data filenames covering an area.
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
proc GenX::DNECFindFiles { Lat0 Lon0 Lat1 Lon1 { Res 50 } } {
   variable Path

   if { $Res!=50 && $Res!=250 } {
      puts stderr "GenX::DNECFindFiles: (Error) Wrong resolution, must be 50 or 250."
      exit 1
   }
   if { ![ogrlayer is NTSLAYER${Res}K] } {
      set nts_layer [lindex [ogrfile open SHAPE${Res}K read $Path(NTS)/${Res}kindex.shp] 0]
      eval ogrlayer read NTSLAYER${Res}K $nts_layer
   }

   #----- Pour les 250k : /data/cmod8/afseeer/DNEC/045/h/045h/045h_0100_deme.tif +west
   #----- Pour les 50k  : /data/cmod8/afseeer/DNEC/031/h/031h01/031h01_0101_deme.tif +west
   set files { }
   foreach id [ogrlayer pick NTSLAYER${Res}K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set feuillet [ogrlayer define NTSLAYER${Res}K -feature $id snrc]
      set s250 [string range $feuillet 0 2]
      set sl   [string tolower [string range $feuillet 3 3]]
      set s50  [string range $feuillet 4 5]

      if { $Res==50 } {
         set path $Path(DNEC)/$s250/$sl/$s250$sl$s50
      } else {
         set path $Path(DNEC)/$s250/$sl/$s250$sl
      }

      if { [llength [set lst [glob -nocomplain $path/*e.tif]]] } {
         lappend files $lst
      }
      if { [llength [set lst [glob -nocomplain $path/*w.tif]]] } {
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
      set nts_layer [lindex [ogrfile open SHAPE250K read $Path(NTS)/250kindex.shp] 0]
      eval ogrlayer read NTSLAYER250K $nts_layer
   }

   set files { }
   foreach id [ogrlayer pick NTSLAYER250K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set feuillet [ogrlayer define NTSLAYER250K -feature $id snrc]
      set s250 [string range $feuillet 0 3]
      if { [file exists [set path $Path(EOSD)/${s250}_lc_1/${s250}_lc_1.tif]] } {
         lappend files $path
      }
   }
   return $files
}
