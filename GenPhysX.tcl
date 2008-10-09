#!/bin/sh
# the next line restarts using tclsh \
exec ${SPI_PATH:=/users/dor/afsr/ops/eer_SPI-7.2.4a}/tclsh "$0" "$@"
#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Generateur de champs geophysiques.
# File       : GenPhysX.tcl
# Creation   : Septembre 2006 - J.P. Gauthier / Ayrton Zadra - CMC/CMOE
# Description: Generer les champs geophysiques necessaires au modeles meteo (GEM)
#
# Parametres   :
#
#      -version        : Generator version
#      -verbose        : Trace level (0 none,1 some ,2 more)
#      -result         : Result filename
#      -dbase          : Database base path
#      -gridfile       : Standard file to get the grid from
#      -workdir        : Working directory
#      -update         : Update results, dot not erase the file if they already exist
#      -nml            : GEM namelist definition file
#      -target         : Model target (GEM, GEM-MACH, ...)
#
#      -batch          : Launch in batch mode or not
#      -mail           : EMail address to send completion mail
#      -mach           : Machine to run on in batch mode
#      -t              : Reserved CPU time (s)
#      -cm             : Reserved RAM (MB)
#
# Retour:
#
# Remarks  :
#   Aucune.
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
fstdfile open GPXSECFILE write $GenX::Path(OutFile)_sec.fst

#----- Get the grid definition

set grid [lindex [set grids [GenX::GridGet]] 0]
GenX::GetNML $GenX::Path(NameFile)

if { $GenX::Data(Topo)!="NONE" } {
   #----- Low and High resolution topograhy averaging method (For scale separation)
   #      This is based on scale separation of the above standard database and
   #      needed for the launching height calculation
   GeoPhysX::AverageTopoLD     $grid L
   GeoPhysX::AverageTopoLD     $grid D

   #-----Standard gradient averaging method
   GeoPhysX::AverageGradient   $grid
}

#----- TOPOGRAPHY
switch $GenX::Data(Topo) {
   "DEFAULT" { GeoPhysX::AverageTopo $grids                            ;#----- Standard topograhy averaging method  }
   "SRTM"    { GeoPhysX::AverageTopoDEM $grid 1 0 $GenX::Data(Aspect)  ;#----- High resolution topography averaging (WORLD=STRMv4 90m, CANADA=DNEC 1:50000(20m) / 1:250000(90m)) }
   "DNEC50"  { GeoPhysX::AverageTopoDEM $grid 0 50 $GenX::Data(Aspect) }
   "DNEC250" { GeoPhysX::AverageTopoDEM $grid 0 250 $GenX::Data(Aspect) }
}

#----- MASK
switch $GenX::Data(Mask) {
   "DEFAULT" { GeoPhysX::AverageMask $grid        ;#----- Standard mask averaging method}
   "CANVEC"  { GeoPhysX::AverageMaskCANVEC $grid  ;#----- High resolution mask averaging over Canada only using CANVEC vectorial data a 1:50000 (Might take long) }
}

#----- VEGETATION
switch $GenX::Data(Vege) {
   "DEFAULT" { GeoPhysX::AverageVege $grid        ;#----- Standard vege averaging method }
   "EOSD"    { GeoPhysX::AverageVegeEOSD $grid    ;#----- EOSD over Canada only vege averaging method }
   "CORINE"  { GeoPhysX::AverageVegeCORINE $grid  ;#----- CORINE over Europe only vege averaging method }
}

#----- SOIL
switch $GenX::Data(Soil) {
   "DEFAULT" { GeoPhysX::AverageSand       $grid  ;#----- Standard sand and clay averaging method
               GeoPhysX::AverageClay       $grid
             }
}

#----- POST_PROCESS
if { $GenX::Data(Post) } {
   GeoPhysX::PostCheckConsistency
   GeoPhysX::PostCorrectionFactor
   GeoPhysX::PostTopoFilter
   GeoPhysX::PostLaunchingHeight
   GeoPhysX::PostY789
   GeoPhysX::PostRoughnessLength
}

GenX::MetaData
fstdfile close GPXOUTFILE
fstdfile close GPXSECFILE
