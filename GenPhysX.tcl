#!/bin/sh
# the next line restarts using tclsh \
exec ${SPI_PATH:=/users/dor/afsr/ops/eer_SPI-7.3.0}/tclsh "$0" "$@"
#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Generateur de champs geophysiques.
# File       : GenPhysX.tcl
# Creation   : September 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Description: Generer les champs geophysiques necessaires au modeles meteo (GEM)
#
# Parameters   :
#
#   Information parameters:
#      [-help]                                    : This information
#      [-version]                                 : GenPhysX version
#
#   Input parameters:
#      [-verbose]  (2)                            : Trace level (0 none,1 some ,2 more,3 Debug)
#      [-nml]      (gem_settings)                 : GEM namelist definition file
#      [-gridfile] ()                             : FSTD file to get the grid from if no GEM namelist
#      [-result]   (genphysx)                     : Result filename
#      [-workdir]  ()                             : Working directory
#      [-target]   ()                             : Model target (GEM, GEM-MACH, ...)
#
#   Processing parameters:
#      Specify databases in order of processing, joined by + ex: STRM+USGS
#
#      [-topo]     (USGS)                         : Topography method { NONE USGS SRTM DNEC250 DNEC50 }
#      [-mask]     (USGS)                         : Mask method { NONE USGS CANVEC }
#      [-vege]     (USGS)                         : Vegetation method { NONE USGS EOSD CORINE }
#      [-soil]     (USDA)                         : Soil method { NONE USDA }
#      [-aspect]   (NONE)                         : Calculates aspect and slope { NONE SRTM DNEC250 DNEC50 }
#      [-check]                                   : Do consistency checks
#      [-diag]                                    : Do diagnostics
#
#   Specific processing parameters:
#      [-z0filter]                                : Apply GEM filter to roughness length
#
#   Batch mode parameters:
#      [-batch]                                   : Launch in batch mode
#      [-mail]     ()                             : Email address to send completion mail
#      [-mach]     (goodenough.cmc.ec.gc.ca)      : Machine to run on in batch mode
#      [-t]        (7200)                         : Reserved CPU time (s)
#      [-cm]       (500)                          : Reserved RAM (MB)
#
# Retour:
#
# Remarks  :
#
#============================================================================

#----- Directory where to find processing procs
set dir [info script]
while { ![catch { set dir [file link $dir] }] } {}
set dir [file dirname $dir]

source $dir/GenX.tcl
source $dir/GeoPhysX.tcl

#----- Parse the arguments
GenX::ParseCommandLine

fstdfile open GPXOUTFILE write $GenX::Path(OutFile).fst
fstdfile open GPXAUXFILE write $GenX::Path(OutFile)_aux.fst

#----- Get the grid definition

set grid [lindex [set grids [GenX::GridGet]] 0]
GenX::GetNML $GenX::Path(NameFile)

#----- Topography
if { $GenX::Data(Topo)!="NONE" } {
   GeoPhysX::AverageTopo     $grids
   GeoPhysX::AverageTopoLow  $grid
   GeoPhysX::AverageGradient $grid
}

#----- Slope and Aspect
if { $GenX::Data(Aspect)!="NONE" } {
   GeoPhysX::AverageAspect $grid
}

#----- Land-water mask
switch $GenX::Data(Mask) {
   "USGS"    { GeoPhysX::AverageMaskUSGS   $grid }
   "CANVEC"  { GeoPhysX::AverageMaskCANVEC $grid }
}

#----- Vegetation type
if { $GenX::Data(Vege)!="NONE" } {
   GeoPhysX::AverageVege $grid
}

#----- Soil type
if { $GenX::Data(Soil)!="NONE" } {
   GeoPhysX::AverageSand $grid
   GeoPhysX::AverageClay $grid
}

#----- Consistency checks
switch $GenX::Data(Check) {
   "STD" { GeoPhysX::CheckConsistencyStandard }
}

#----- Sub grid calculations
if { $GenX::Data(Sub)!="NONE" } {
   GeoPhysX::SubCorrectionFactor
   GeoPhysX::SubTopoFilter
   GeoPhysX::SubLaunchingHeight
   GeoPhysX::SubY789
   GeoPhysX::SubRoughnessLength
}

#----- Diagnostics of output fields
if { $GenX::Data(Diag) } {
   GeoPhysX::Diag
}

GenX::MetaData
fstdfile close GPXOUTFILE
fstdfile close GPXAUXFILE
