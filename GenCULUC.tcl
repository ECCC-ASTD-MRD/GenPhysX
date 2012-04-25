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

package require Logger

Log::Print INFO "Beginning of GenCULUC"

set CULUCVersion 0.9.1    ;# this must be in sync with the CULUCVersion in UrbanX
Log::Print INFO "Generating CULUC files for CULUC version $CULUCVersion"

if { [info exists env(CULUC_PATH)] } {
   set CULUCPath $env(CULUC_PATH)/CULUC
} else {
   set CULUCPath       "/cnfs/dev/cmdd/afsm/lib/geo/CULUC/$CULUCVersion/" ;# Path to the permanent CULUC repository
} 


# Cities to compute in priority - see also http://en.wikipedia.org/wiki/List_of_the_100_largest_urban_areas_in_Canada_by_population
set Cities      { Toronto Montreal Vancouver Ottawa Calgary Halifax QuebecCity Windsor Hamilton Winnipeg Edmonton Kitchener Victoria Regina Saskatoon Saint-John Fredericton London Sherbrooke NiagaraFalls Barrie Abbotsford Chilliwack Kelowna }

# NTS sheets for urban areas
set NTS(Toronto)        { 030m11 030m12 030m13 030m14 030m15 }
set NTS(Montreal)       { 031h05 031h06 031h11 031h12 }
set NTS(Vancouver)      { 092g02 092g03 092g06 092g07 }
set NTS(Ottawa)         { 031g05 031g12 }
set NTS(Calgary)        { 082o01 082p04 082i13 082j16 }
set NTS(Halifax)        { 011d11 011d12 011d13 }
set NTS(QuebecCity)     { 021l14 021l11 }
set NTS(Windsor)        { 040j06 040j07 040j03 040j02 }
set NTS(Hamilton)       { 030m05 030m04 040p01 }
set NTS(Winnipeg)       { 062h14  062h15 }
set NTS(Edmonton)       { 083h05 083h06 083h11 083h12 }
set NTS(Kitchener)      { 040p08 040p09 040p07 070p10 }
set NTS(Victoria)       { 092b06 092b05 092b11 }
set NTS(Regina)         { 072i07 072i10 }
set NTS(Saskatoon)      { 073b02 }
set NTS(Saint-John)     { 021g08 021g01 021h05 }
set NTS(Fredericton)    { 021g15 }
set NTS(London)         { 040i14 040p03 }
set NTS(Sherbrooke)     { 021e05 031h08 }
set NTS(NiagaraFalls)   { 030m03 030l14 }
set NTS(Barrie)         { 031d05 }
set NTS(Abbotsford)     { 092g01 }
set NTS(Chilliwack)     { 092h04 }
set Kelowna             { 082e14 082e13 }


# Used since GenX requires a gridfile for UrbanX at the moment, the grid is unused
set Grid "/cnfs/dev/cmdd/afsm/lib/geo/CULUC/grid.std"

# Log::Print INFO "Launching UrbanX for urban areas"  ;# there's no other option at the moment
foreach city $Cities {
   foreach ntssheet $NTS($city) {
      # Needed for the path of existing CULUC files
      set s250 [string range $ntssheet 0 2]
      set sl   [string tolower [string range $ntssheet 3 3]]
      set s50  [string range $ntssheet 4 5]

      # Checking if CULUC has already been generated for the NTS sheet
      if { [file exists $CULUCPath/$s250/$sl/CULUC_{$ntssheet}_v$CULUCVersion.tif] } {
            Log::Print INFO "CULUC_$ntssheet_$CULUCVersion already exists and won't be computed"
      } else {
         Log::Print INFO "Launching UrbanX over $ntssheet for $city"
         set err [catch { exec GenPhysX.tcl -urban $ntssheet -gridfile $Grid -result temp_CULUC 2>@1 } msg]
         if { $err } {
            Log::Print ERROR "Could not launch GenPhysX, error message:\n\n\t$msg"
            Log::End 1
         }
      }
   }
}

# Deleting temp files
file delete -force temp_CULUC_tmp

Log::Print INFO "End of GenCULUC"