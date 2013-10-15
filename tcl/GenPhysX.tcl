#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Generateur de champs geophysiques.
# File       : GenPhysX.tcl
# Creation   : September 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Revision   : $Id$
# Description: Generer les champs geophysiques necessaires au modeles meteo (GEM)
#
#
# Parameters   :
#
#   Information parameters:
#      [-help]                                    : This information
#      [-version]                                 : GenPhysX version
#      [-verbose]  (2)                            : Trace level (0 ERROR,1 WARNING ,2 INFO,3 DEBUG)
#
#   Input parameters:
#      [-nml]      (gem_settings)                 : GEM namelist definition file
#      [-gridfile] ()                             : FSTD file to get the grid from if no GEM namelist
#      [-result]   (genphysx)                     : Result filename
#      [-target]   ()                             : Model target (GEM, GEM-MACH, ...)
#      [-script]   ()                             : User definition script to include
#
#   Processing parameters:
#      Specify databases in order of processing, joined by + ex: STRM+USGS
#
#      [-topo]     ()                             : Topography method { USGS SRTM CDED250 CDED50 ASTERGDEM }
#      [-mask]     ()                             : Mask method { USGS CANVEC }
#      [-geomask]  ()                             : Mask method { USGS CANVEC }
#      [-vege]     ()                             : Vegetation method { USGS EOSD CORINE }
#      [-soil]     ()                             : Soil method { USDA }
#      [-aspect]   ()                             : Calculates aspect and slope { SRTM CDED250 CDED50 ASTERGDEM }
#      [-biogenic] ()                             : Biogenic calculation { BELD USGS }
#      [-urban]    ()                             : Urban coverage
#      [-smoke]    ()                             : SMOKE emissions
#      [-check]                                   : Do consistency checks
#      [-subgrid]                                 : Calculates sub grid fields
#      [-diag]                                    : Do diagnostics
#
#   Specific processing parameters:
#      [-z0filter]                                : Apply GEM filter to roughness length
#      [-celldim]                                 : Grid cell dimension (1=point, 2=area)
#      [-compress]                                : Compress standard file output
#
#   Batch mode parameters:
#      [-batch]                                   : Launch in batch mode
#      [-mail]     ()                             : Email address to send completion mail
#      [-mach]     (hawa)                         : Machine to run on in batch mode
#      [-t]        (7200)                         : Reserved CPU time (s)
#      [-cm]       (500)                          : Reserved RAM (MB)
#
# Retour:
#
# Remarks  :
#   - fix vs genesis:
#       - 425m+ high non-existant island above Columbia in Caribbean sea
#       - Hawaii topo is really bad
#       - First and last overlapping x gridpoint on global grids different
#       - LH extending far into sea
#       - genesis seems to average with an offset toward the east (see -25.14 -70.49 823,288)
#============================================================================

source $env(GENPHYSX_PATH)/tcl/GenX.tcl
source $env(GENPHYSX_PATH)/tcl/GeoPhysX.tcl
source $env(GENPHYSX_PATH)/tcl/BioGenX.tcl
source $env(GENPHYSX_PATH)/tcl/HydroX.tcl
source $env(GENPHYSX_PATH)/tcl/UrbanPhysX.tcl
source $env(GENPHYSX_PATH)/tcl/UrbanX.tcl
source $env(GENPHYSX_PATH)/tcl/IndustrX.tcl

Log::Start GenPhysX $GenX::Param(Version)

#----- Parse the arguments
GenX::ParseCommandLine

#----- Open output files
fstdfile open GPXOUTFILE write $GenX::Param(OutFile)$GenX::Param(Process).fst
fstdfile open GPXAUXFILE write $GenX::Param(OutFile)$GenX::Param(Process)_aux.fst

proc ProcessCheck { Channel } {
   global Param

   if { [eof $Channel] } {
      close $Channel
      incr Param(Process) -1
   } else {
      puts [read -nonewline $Channel]
   }
   if { !$Param(Process) } {
      set Param(Done) True
   }
}

#----- Get grids to process
set grids [GenX::GridGet $GenX::Param(GridFile)]

if { [llength $grids]>1 } {
   #----- If we have more than 1 grid, launch each grid into a sub-process

   set Param(Process) 0
   set Param(Done)    False

   foreach grid $grids {
      Log::Print INFO "Launching processing for grid #$Param(Process)"

      file copy -force $GenX::Param(OutFile).fst $GenX::Param(OutFile)$Param(Process).fst
      file copy -force $GenX::Param(OutFile)_aux.fst $GenX::Param(OutFile)$Param(Process)_aux.fst

      set channel [open "|$env(GENPHYSX_PATH)/bin/GenPhysX $argv -process $Param(Process) 2>@1" r+]
      fconfigure $channel -blocking False -buffering line
      fileevent $channel readable [list ProcessCheck $channel]
      incr Param(Process) 1
   }

   #----- Wait for all of them to finish
   vwait Param(Done)

   #----- Merge results
   Log::Print INFO "Merging results"
   set Param(Process) 0
   foreach grid [lreverse $grids] {
      set err [catch { exec editfst -i 0 -e -s $GenX::Param(OutFile)$Param(Process).fst -d $GenX::Param(OutFile).fst 2>@1 } msg]
      if { $err } {
         Log::Print ERROR "Problems while merging results from grid #$Param(Process):\n\n\t:$msg"
      } else {
         file delete $GenX::Param(OutFile)$Param(Process).fst
      }
      set err [catch { exec editfst -i 0 -e -s $GenX::Param(OutFile)$Param(Process)_aux.fst -d $GenX::Param(OutFile)_aux.fst 2>@1 } msg]
      if { $err } {
         Log::Print ERROR "Problems while merging auxiliary results from grid #$Param(Process):\n\n\t:$msg"
      } else {
         file delete $GenX::Param(OutFile)$Param(Process)_aux.fst
      }
      incr Param(Process) 1
   }
} else {
   GenX::Process $grids
   GenX::MetaData $grids
}

fstdfile close GPXOUTFILE
fstdfile close GPXAUXFILE

#----- Send an email at end of processing when this is not a batch job, in master process
if { !$GenX::Batch(On) && $GenX::Param(Process)=="" && $GenX::Batch(Mail)!="" } {
   set err [catch { exec echo $GenX::Param(OutFile) | mail -s "GenPhysX job done" $GenX::Batch(Mail) } msg]
   if { $err } {
      Log::Print ERROR "Problem sending email:\n\n\t:$msg"
   }
}

Log::End 0