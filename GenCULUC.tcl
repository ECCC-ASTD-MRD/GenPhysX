#!/bin/sh
# the next line restarts using tclsh \
exec nice ${GENPHYSX_PRIORITY:=-19} ${SPI_PATH:=/users/dor/afsr/ops/eer_SPI-7.5.1}/tclsh "$0" "$@"

#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : CULUC product generator
# File       : GenCULUC.tcl
# Creation   : April 2012 - Alexandre Leroux - CMC/CMOE
# Revision   : $Id: UrbanX.tcl 668 2012-02-08 19:40:58Z afsmvan $
# Description: Generates the missing CULUC GeoTIFFs by launching several UrbanX.tcl instances
#
#
# Remarks  :
#               Full documentation found on https://wiki.cmc.ec.gc.ca/wiki/UrbanX and subpages
#
# Functions :
#
#============================================================================

#----- Setting GENPHYSX_HOME required by UrbanX.tcl
set GENPHYSX_HOME [info script]
while { ![catch { set GENPHYSX_HOME [file normalize [file link $GENPHYSX_HOME]] }] } {}
set GENPHYSX_HOME [file dirname $GENPHYSX_HOME]

source $GENPHYSX_HOME/GenX.tcl         ;# for common variables required by UrbanX.tcl such as Param(SMOKE)
source $GENPHYSX_HOME/UrbanX.tcl       ;# for common variables between UrbanX and GenCULUC

package require Logger

namespace eval GenCULUC { } {
   variable Param

   set Param(CULUCVersion)      $UrbanX::Param(CULUCVersion)

   if { [info exists env(CULUC_PATH)] } {
      set Param(CULUCPath)      $env(CULUC_PATH)/CULUC
   } else {
      set Param(CULUCPath)      "/cnfs/dev/cmdd/afsm/lib/geo/CULUC/$Param(CULUCVersion)" ;# Path to the permanent CULUC repository
   } 

   # Used since GenX requires a gridfile for UrbanX at the moment, the grid is unused
   set Param(GridFile)              "/cnfs/dev/cmdd/afsm/lib/geo/CULUC/grid.std"

   # Cities to compute in priority - see also http://en.wikipedia.org/wiki/List_of_the_100_largest_urban_areas_in_Canada_by_population
   set Param(Cities)      { Toronto Montreal Vancouver Ottawa Calgary Halifax QuebecCity Windsor Hamilton Winnipeg Edmonton Kitchener Victoria Regina Saskatoon Saint-John Fredericton London Sherbrooke NiagaraFalls Barrie Abbotsford Chilliwack Kelowna }

   # NTS sheets for urban areas
   set Param(NTSToronto)        { 030m11 030m12 030m13 030m14 030m15 }
   set Param(NTSMontreal)       { 031h05 031h06 031h11 031h12 }
   set Param(NTSVancouver)      { 092g02 092g03 092g06 092g07 }
   set Param(NTSOttawa)         { 031g05 031g12 }
   set Param(NTSCalgary)        { 082o01 082p04 082i13 082j16 }
   set Param(NTSHalifax)        { 011d11 011d12 011d13 }
   set Param(NTSQuebecCity)     { 021l14 021l11 }
   set Param(NTSWindsor)        { 040j06 040j07 040j03 040j02 }
   set Param(NTSHamilton)       { 030m05 030m04 040p01 }
   set Param(NTSWinnipeg)       { 062h14  062h15 }
   set Param(NTSEdmonton)       { 083h05 083h06 083h11 083h12 }
   set Param(NTSKitchener)      { 040p08 040p09 040p07 040p10 }
   set Param(NTSVictoria)       { 092b06 092b05 092b11 }
   set Param(NTSRegina)         { 072i07 072i10 }
   set Param(NTSSaskatoon)      { 073b02 }
   set Param(NTSSaint-John)     { 021g08 021g01 021h05 }
   set Param(NTSFredericton)    { 021g15 }
   set Param(NTSLondon)         { 040i14 040p03 }
   set Param(NTSSherbrooke)     { 021e05 031h08 }
   set Param(NTSNiagaraFalls)   { 030m03 030l14 }
   set Param(NTSBarrie)         { 031d05 }
   set Param(NTSAbbotsford)     { 092g01 }
   set Param(NTSChilliwack)     { 092h04 }
   set Param(NTSKelowna)        { 082e14 082e13 }

}


#----------------------------------------------------------------------------
# Name     : <GenCULUC::Process>
# Creation : 2012 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Process all CULUC NTS sheets, starting with majors cities then 
#            all the rest
#
# Parameters : none
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenCULUC::Process { } {
   variable Param

   Log::Print INFO "Beginning of GenCULUC"
   Log::Print INFO "Generating CULUC files for CULUC version $Param(CULUCVersion)"

   Log::Print INFO "Launching UrbanX for urban areas"
   foreach city $Param(Cities) {
      foreach ntssheet $Param(NTS$city) {
         GenCULUC::LaunchUrbanX $ntssheet $city
      }
   }

   Log::Print INFO "Launching UrbanX for the rest of Canada"
   set city "the rest of Canada"

   # find all nts sheets from sql list or elsewhere
   #foreach ntssheet run urbanx

   # obtain list of all NTS sheets within the delimited north america area
   set Param(NTSSheets) [UrbanX::FindNTSSheets 41.0 -141.0 84.0 -53.0]
   Log::Print INFO "Total: [llength $Param(NTSSheets)] sheets to process"
   foreach ntssheet $Param(NTSSheets) {
      GenCULUC::LaunchUrbanX $ntssheet
   }

   # Deleting temp files
   file delete -force temp_CULUC_tmp

   Log::Print INFO "End of GenCULUC"
}

#----------------------------------------------------------------------------
# Name     : <GenCULUC::LaunchUrbanX>
# Creation : 2012 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Generate a NTS sheet image
#
# Parameters :
#     Ntssheet    nts sheet identifier
#     City        optional for info display only
#
# Return:
#
# Remarks :
#
#     a .lock file will appears in the directory where the .tif file would be when generated
#     to allow multiple processes to work concurrently on diffent sheet.
#     also a .done will appear at the end of processing even if process failed to generate
#     the image (empty sheet)
#
#----------------------------------------------------------------------------
proc GenCULUC::LaunchUrbanX { Ntssheet {City ""} } {
   variable Param
   global   GENPHYSX_HOME
   global   TMPDIR

   # Needed for the path of existing CULUC files
   set s250 [string range $Ntssheet 0 2]
   set sl   [string tolower [string range $Ntssheet 3 3]]
   set s50  [string range $Ntssheet 4 5]

   set outdir   $Param(CULUCPath)/$s250/$sl
   set lockfile $outdir/CULUC_${Ntssheet}_v$Param(CULUCVersion).lock
   set donefile $outdir/CULUC_${Ntssheet}_v$Param(CULUCVersion).done
   # Checking if CULUC has already been generated for the NTS sheet
   if { ![file isdir "$outdir"] } {
      file mkdir  "$outdir"
   } else {
      if { [file exists $lockfile] } {
         Log::Print INFO "CULUC_${Ntssheet}_$Param(CULUCVersion) is being computed"
         return
      }
      if { [file exists $donefile] } {
         Log::Print INFO "CULUC_${Ntssheet}_$Param(CULUCVersion) has been processed"
         return
      }
   }


   if { [file exists $outdir/CULUC_${Ntssheet}_v$Param(CULUCVersion).tif] } {
      Log::Print INFO "CULUC_${Ntssheet}_$Param(CULUCVersion) already exists and won't be computed"
   } else {
      if { [file exists $lockfile] } {
         Log::Print INFO "CULUC_${Ntssheet}_$Param(CULUCVersion) is being computed"
         return
      }
      exec touch $lockfile
      if { [string compare $City ""] != 0 } {
         Log::Print INFO "Launching UrbanX over $Ntssheet for $City"
      } else {
         Log::Print INFO "Launching UrbanX over $Ntssheet"
      }
      set starttime [clock seconds]
      set err [catch { exec $GENPHYSX_HOME/GenPhysX.tcl -urban $Ntssheet -gridfile $Param(GridFile) -result $TMPDIR/temp_CULUC 2>@1 } msg]
      if { $err } {
         Log::Print ERROR "Could not launch GenPhysX, error message:\n\n\t$msg"
         Log::End 1
      }
      if { [file exists $outdir/CULUC_${Ntssheet}_v$Param(CULUCVersion).tif] } {
         Log::Print INFO "CULUC for $Ntssheet completed in [expr ([clock seconds]-$starttime)/60.0] minutes"
      } else {
         exec touch $donefile
      }
      Log::Print INFO "Not creating the metadata file... this will need to be done!"
      if { [file exist $lockfile] } {
         if { [catch "exec rm $lockfile" errmsg] } {
            Log::Print INFO $errmsg
         }
      }
   }
}

set TMPDIR [lindex $argv 0]
if { ![file isdir $TMPDIR] } {
   file mkdir $TMPDIR
}
# This is the main
GenCULUC::Process

# cleanup
exec rm -rf $TMPDIR
