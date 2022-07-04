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
#   GenX::Procs              { args }
#   GenX::Submit             { }
#   GenX::MetaData           { Grid }
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
#   GenX::NHNFindFiles       { Lat0 Lon0 Lat1 Lon1 }
#   GenX::LCC2000VFindFiles  { Lat0 Lon0 Lat1 Lon1 }
#   GenX::UTMZoneDefine      { Lat0 Lon0 Lat1 Lon1 { Res 5 } { Name "" } }
#
#============================================================================

package require TclData
package require TclGeoPhy
package require TclSystem
package require MetData
package require Logger

set Log::Param(SPI)       8.0.0
set Log::Param(Level)     INFO

namespace eval GenX { } {
   global env
   variable Settings
   variable Path
   variable Param
   variable Meta
   variable Batch

   set Param(Version)      2.6.0               ;#Application version
   set Param(VersionState) ""                  ;#Application state
   
   set Param(Secs)      [clock seconds]        ;#To calculate execution time
   set Param(TileSize)  1024                   ;#Tile size to use for large dataset
   set Param(Cache)     {}                     ;#Input data cache list
   set Param(CacheMax)  20                     ;#Input data cache max

   set Param(Vege)       ""                    ;#Vegetation data selected
   set Param(Soil)       ""                    ;#Soil type data selected
   set Param(SoilDBRK)   ""                    ;#Soil depth to bed rock selected, "" will default to GSRS
   set Param(Topo)       ""                    ;#Topography data selected
   set Param(Mask)       ""                    ;#Mask data selected
   set Param(GeoMask)    ""                    ;#Geographical mask data selected
   set Param(Aspect)     ""                    ;#Slope and aspect selected
   set Param(Check)      ""                    ;#Consistency checks
   set Param(Sub)        ""                    ;#Subgrid calculations selected
   set Param(Target)     ""                    ;#Model cible
   set Param(Biogenic)   ""                    ;#Biogenic emissions data selected
   set Param(Hydro)      ""                    ;#Hydrographic data
   set Param(Urban)      ""                    ;#Urban coverage
   set Param(SMOKE)      ""                    ;#SMOKE emissions
   set Param(SMOKEIndex) 1                     ;#SMOKE restart index
   set Param(Hydraulic)  False                 ;#Soil Hydraulic parameters enabled
   set Param(MEFilter)   ""                 ;#Topo filter selected
   set Param(EGMGH)      ""                    ;#Earth Gravitational Model Geoid Height
   set Param(Bathy)      ""                    ;#Bathymetry
   set Param(MEFilterForZ0) "STD"              ;#Topo filter selected for Z0
   set Param(Vege2Mask) False                  ;#Generate Mask from Vege
   set Param(UseVegeLUT) False                 ;#Enable use of CSV LUT for vegetation

   set Param(Diag)      False                 ;#Diagnostics
   set Param(Z0Filter)  False                 ;#Filter roughness length
   set Param(Z0NoTopo)  ""                    ;#No topography + z0vg  for roughness length
   set Param(Z0Topo)    ""                    ;#With topography for roughness length
   set Param(Compress)  False                 ;#Compress standard file output
   set Param(TopoStag)  False                 ;#Treat mulitple grids as staggered topography
   set Param(NBits)     32                    ;#Compress standard file output
   set Param(Cell)      1                     ;#Grid cell dimension (1=1D(point 2=2D(area))
   set Param(Script)    ""                    ;#User definition script
   set Param(Process)   ""                    ;#Current processing id
   set Param(OutFile)   genphysx              ;#Output file prefix
   set Param(GridFile)  ""                    ;#Grid definition file to use (standard file with >> ^^)
   set Param(NML)       ""                    ;#GEM namelist
   set Param(Datyp)     5                     ;#Default DATYP to use for output fields
   set Param(CappedNBits)  24                 ;# Legacy limited nbits used for MG, VF and soil
   set Param(Interpolation)  ""               ;#Interpolation mode to use by default
   set Param(ETIKET)    "GENPHYSX"            ;#Default ETIKET to use for output fields

   set Param(Topos)     { USGS SRTM SRTM30 SRTM90 CDED250 CDED50 ASTERGDEM GTOPO30 GMTED30 GMTED15 GMTED75 CDEM }
   set Param(Aspects)   { SRTM SRTM30 SRTM90 CDED250 CDED50 CDEM GTOPO30 USGS GMTED30 GMTED15 GMTED75 }
   set Param(Veges)     { USGS GLC2000 GLOBCOVER CCRS EOSD LCC2000V CORINE MCD12Q1 AAFC CCI_LC CCILC2015-ECO2017 CCILC2015-1 CCILC2015 CCILC2010 USGS_R NALCMS }
   set Param(Soils)     { USDA AGRC FAO HWSD JPL BNU CANSIS SLC SOILGRIDS }
   set Param(SoilDBRKs) { GSRS }
   set Param(Masks)     { USNAVY USGS GLC2000 GLOBCOVER CANVEC MCD12Q1 CCI_LC CCILC2015-ECO2017 CCILC2015-1 CCILC2015 CCILC2010 USGS_R AAFC NALCMS OSM }
   set Param(GeoMasks)  { CANADA }
   set Param(Biogenics) { BELD VF }
   set Param(Hydros)    { NHN NHD HSRN DCW }
   set Param(Urbans)    { True HALIFAX QUEBEC MONTREAL OTTAWA TORONTO REGINA WINNIPEG CALGARY EDMONTON VANCOUVER VICTORIA }
   set Param(SMOKES)    { TN PEI NS NB QC ON MN SK AB BC YK TNO NV }
   set Param(Checks)    { STD }
   set Param(Subs)      { LEGACY STD SPLIT }
   set Param(MEFilters) { STD LPASS }
   set Param(Z0NoTopos) { STD CANOPY CANOPY_LT }
   set Param(Z0Topos)   { STD LEGACY }
   set Param(CropZ0)    0.0                  ;# if set to non-zero, Crop Z0 should be used when crop fraction higher
   set Param(Targets)   { LEGACY GEMMESO GEM4.4 GDPS-5.1 AURAMS RELWS-1.0 }   ;#Model cible
   set Param(EGMGHs)    { EGM96 EGM2008 }
   set Param(Bathys)    { CHS NCEI GEBCO HYDROLAKES }
   set Param(Interpolations) { LINEAR NEAREST CUBIC AVERAGE }

   set Param(FallbackMask)    ""             ;#used if Path(FallbackMask) not used
   set Param(SRTM3)     False
   set Param(AddHydroLakesToMask)   False    ; #add HydroLakes Lakes fraction to OSM Mask

   set Batch(On)       False                 ;#Activate batch mode (soumet)
   set Batch(Host)     ppp4                  ;#Host onto which to submit the job
   set Batch(Queue)    ""                    ;#Queue to use for the job
   set Batch(Mem)      8G                    ;#Memory needed for the job
   set Batch(CPU)      1                     ;#CPU needed for the job
   set Batch(Time)     7200                  ;#Time needed for the job
   set Batch(Mail)     ""                    ;#Mail address to send completion info
   set Batch(Submit)   ord_soumet
   set Batch(Path)     "\$TMPDIR/GenPhysX\$\$"

   #----- Various database paths
   set Param(DBase)          "/space/hall3/sitestore/eccc/cmd/s/slib800/geo"
   set Param(DBaseeccc-ppp3) "/space/hall3/sitestore/eccc/cmd/s/slib800/geo"
   set Param(DBaseeccc-ppp4) "/space/hall4/sitestore/eccc/cmd/s/slib800/geo"
   set Param(DBaseeccc-ppp5) "/space/hall5/sitestore/eccc/cmd/s/slib800/geo"
   set Param(DBaseeccc-ppp6) "/space/hall6/sitestore/eccc/cmd/s/slib800/geo"
   catch { set Param(DBase) $Param(DBase$env(ORDENV_TRUEHOST)) }
   
   if { ![file isdirectory $Param(DBase)] } {
      set Param(DBase)    "/fs/cetus3/fs3/cmd/s/afsm/lib/geo"
   }

   if  { [info exists env(GENPHYSX_DBASE)] } {
      set Param(DBase) $env(GENPHYSX_DBASE)
   }

   set Path(SandUSDA)   RPN/sand_usda
   set Path(SandFAO)    RPN/sand_fao
   set Path(SandAGRC)   RPN/sand_argc
   set Path(ClayUSDA)   RPN/clay_usda
   set Path(ClayFAO)    RPN/clay_fao
   set Path(ClayAGRC)   RPN/clay_argc
   set Path(TopoUSGS)   RPN/me_usgs2002
   set Path(MaskUSGS)   RPN/mg_usgs2002
   set Path(MaskUSNavy) RPN/mg_usnavy
   set Path(VegeUSGS)   RPN/vg_usgs2002
   set Path(TopoLow)    RPN/data_lres
   set Path(Grad)       RPN/data_grad
   set Path(HWSD)       HWSD
   set Path(SRTM)       SRTM
   set Path(SRTM30)     SRTM30
   set Path(SRTM90)     SRTMv4
   set Path(CDED)       CDED
   set Path(CDEM)       CDEM
   set Path(ASTERGDEM)  ASTER-GDEM
   set Path(GTOPO30)    GTOPO30
   set Path(GMTED2010)  GMTED2010
   set Path(EOSD)       EOSD
   set Path(AAFC_CROP)  AAFC/Crop
   set Path(BNDT)       BNDT
   set Path(NTS)        NTS
   set Path(CANVEC)     CanVec
   set Path(CORINE)     CORINE
   set Path(GlobCover)  GlobCover
   set Path(GLC2000)    GLC2000_USGS
   set Path(CCRS)       CCRS-LC2005
   set Path(Various)    Various
   set Path(BELD3)      BELD3
   set Path(LCC2000V)   LCC2000V
   set Path(JPL)        JPL
   set Path(NHN)        NHN
   set Path(NHD)        NHD
   set Path(DCW)        DCW
   set Path(HSRN)       USGS_HydroSHEDS/River_Network
   set Path(USGS_R)     USGS_GLCC
   set Path(GLAS)       SimardPinto
   set Path(GSRS)       GSRS
   set Path(CanadaProv) Various
   set Path(BNU)        BNU
   set Path(CANSIS)     CANSIS
   set Path(MODIS_IGBP) MODIS/MCD12Q1/IGBP
   set Path(CCI_LC)     ESA_CCI_LC
   set Path(CCILC2015-1)  ESA_CCI_LC/2015-1
   set Path(CCILC2015-ECO2017)  ESA_CCI_LC/2015-ECO2017
   set Path(CCILC2015)  ESA_CCI_LC/2015
   set Path(CCILC2010)  ESA_CCI_LC/2010
   set Path(CCILC_LUT_CSV)    ""
   set Path(NALCMS)     NALCMS
   set Path(SLC)        SLC
   set Path(SOILGRIDS)  SoilGrids
   set Path(EGM2008)    NGA/EGM2008
   set Path(EGM96)      NGA/EGM96
   set Path(CHS)        CHS/bathymetry
   set Path(NCEI)       NOAA/NCEI/bathymetry
   set Path(GEBCO)      GEBCO_2014
   set Path(HYDROLAKES) HydroSHEDS/Misc/HydroLakes/HydroLAKES_polys_v10-tiled
   set Path(GREATLAKES) HydroSHEDS/Misc/HydroLakes/great_lakes_shp
   set Path(OSM)        OSM/data

   set Path(StatCan)    $Param(DBase)/StatCan2006
   set Path(FallbackMask)    ""               ;# file containing MG to complete CANVEC
   set Path(SkipList)        ""

   #----- Allow overloading of user defined Table using a line per entry form which is easier to read
   #----- For example, see:  /data/cmdd/afsm/lib/geo/AAFC/Crop_2014/TO_CCRN.txt 
   set Path(AAFC2RPN)    ""
   set Path(AAFC_FILES)  ""


   #----- Metadata related variables
   set Meta(Procs)     {}                     ;#Metadata procedure registration list
   set Meta(Databases) {}                     ;#Databases used
   set Meta(Header)    ""                     ;#Metadata header
   set Meta(Footer)    ""                     ;#Metadata footer
   set Meta(Command)   ""                     ;#Launch command

   #----- GEM related variables
   set Settings(GRD_TYP_S)            GU
   set Settings(TOPO_DGFMS_L)         True
   set Settings(TOPO_DGFMX_L)         True
   set Settings(TOPO_FILMX_L)         True
   set Settings(TOPO_CLIP_ORO_L)      False
   set Settings(TOPO_ZREF_ZV_RATIO_C) False
   set Settings(TOPO_VEGE_RUGV)       {}      ; #list of 26 vegetation roughness
   set Settings(TOPO_RUGV_ZVG2)       False
   set Settings(TOPO_RUGV_MG)         False
   set Settings(TOPO_ZV_MIN_THRESHOLD)   0.0003

   set Param(TOPO_ZVG2_TYPE)               {}

   set Settings(LPASSFLT_RC_DELTAX)         3.0
   set Settings(LPASSFLT_P)                 20
   set Settings(LPASSFLT_MASK_OPERATOR)     0
   set Settings(LPASSFLT_MASK_THRESHOLD)    100.0
   set Settings(LPASSFLT_APPLY_MINMAX)      True
   
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
	variable Opt

   set Param(TMPDIR) $Param(OutFile)_tmp$Param(Process)
   set Log::Param(Process) $Param(Process)
   if { $Param(Sub)=="SPLIT" }  { set GeoPhysX::Opt(SubSplit) True }

   # Opt(LegacyMode) enabled will trigger data area averaging for USGS topography
   if { $Param(Sub)=="LEGACY" } { 
      set GeoPhysX::Opt(LegacyMode) True 
   }

   #----- Land-water mask
   if { $Param(Mask)!="" } {
      GeoPhysX::AverageMask $Grid
   }

   #----- Vegetation type
   if { $Param(Vege)!="" } {
      GeoPhysX::AverageVege $Grid
   }

   #----- Topography
   if { $Param(Topo)!="" } {
      GeoPhysX::AverageTopo $Grid
   }
   
   #----- Bathymetry
   if { $Param(Bathy)!="" } {
      GeoPhysX::AverageBathymetry $Grid
   }

   #----- Consistency checks for mask vs vege
   if { $Param(Vege)!=$Param(Mask) || $Param(UseVegeLUT) } {
      GeoPhysX::CheckMaskVegeConsistency
   }

   #----- If staggered topograhy is enabled and this is not the first grid, exit
   if { $Param(TopoStag) && $Param(Process)!="" && $Param(Process)!=0 } {
      return
   }

   #----- Slope and Aspect
   if { $Param(Aspect)!="" } {
      GeoPhysX::AverageAspect $Grid
   }

   #----- Land-water mask
   if { $Param(GeoMask)!="" } {
      GeoPhysX::AverageGeoMask $Grid
   }


   #----- Soil type
   if { $Param(Soil)!="" } {
      GeoPhysX::AverageSoil $Grid
   }

   #----- depth to bedrock
   if { $Param(SoilDBRK)!="" } {
      GeoPhysX::AverageGSRS_DBRK $Grid
   }

   #----- Vegetation canopy height
   if { $GenX::Param(Sub)!="LEGACY" } {
      if { $GenX::Param(Z0NoTopo) == "CANOPY" } {
         GeoPhysX::AverageGLAS $Grid
      } elseif { ($GenX::Param(Z0NoTopo) == "CANOPY_LT") || ($GenX::Param(TOPO_ZVG2_TYPE) == "CANOPY_LT") } {
         GeoPhysX::AverageGLAS_Z0 $Grid
      }
   }

   #----- Hydraulic
   if { $Param(Hydraulic) } {
      GeoPhysX::AverageSoilHydraulic $Grid
   }

   #----- Consistency checks
   switch $Param(Check) {
      "STD" { GeoPhysX::CheckConsistencyStandard }
   }

   #----- Consistency checks similar to Genesis
   if { $GeoPhysX::Opt(LegacyMode) } {
      GeoPhysX::CheckLegacyVG
   }


   #----- Sub grid calculations
   switch $Param(Sub) {
      "STD" {
         GeoPhysX::AverageTopoLow  $Grid
         GeoPhysX::AverageGradient $Grid
         GeoPhysX::SubCorrectionFactor
         GeoPhysX::SubLaunchingHeight
         GeoPhysX::SubY789
         GeoPhysX::SubRoughnessLength
         GeoPhysX::SubTopoFilter
      }
      "SPLIT" {
         GeoPhysX::SubLaunchingHeightSplit
         GeoPhysX::SubY789Split
         GeoPhysX::SubRoughnessLength
         GeoPhysX::SubTopoFilter
      }
      "LEGACY" {
         if { $Param(Z0Topo) == "STD" } {
            GeoPhysX::AverageTopoLow  $Grid
            GeoPhysX::SubCorrectionFactor
            GeoPhysX::SubRoughnessLength
         }
         GeoPhysX::SubTopoFilter
      }
   }

   if { ($Param(Z0Topo) == "LEGACY")||($Param(Sub) == "LEGACY") } {
      GeoPhysX::LegacySub $Grid
   }

   #----- Biogenic emissions calculations
   if { $Param(Biogenic)!="" } {
      BioGenX::CalcEmissions  $Grid
      BioGenX::TransportableFractions $Grid

      if { [ string equal $Param(Target) "AURAMS" ] } {
         BioGenX::AURAMSBiogFromVF $Grid
      }
   }

   #-----Hydrologic parameters
   if { $Param(Hydro)!="" } {
      HydroX::DrainDensity $Grid
   }

   #----- Urban parameters
   if { $Param(Urban)!="" } {
      UrbanX::Process $Param(Urban) $Grid
      #UrbanPhysX::Cover $Grid
   }

   #----- SMOKE parameters
   if { $Param(SMOKE)!="" } {
      IndustrX::Process $Param(SMOKE)
   }

   #----- Diagnostics of output fields
   if { $Param(Diag) } {
      GeoPhysX::Diag
   }

   #----- Earth Gravitional Model
   if { $Param(EGMGH)!="" } {
      GeoPhysX::AverageGeoidHeight $Grid
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

   if { [catch {set host $env(ORDENV_TRUEHOST) }] } {
      if { [catch {set host $env(TRUE_HOST) }] } {
         set host $Batch(Host)
      }
   }
   set rargv ""
   set rem   0

   #----- Check if local dir is reachable
   set ldir [set tmpdir [file dirname [file normalize $Param(OutFile)]]]
   if { [catch { exec ssh $Batch(Host) ls $ldir }] } {
      set tmpdir $Batch(Path)
      set rem    1
      Log::Print INFO "Output path not reachable form batch host, will run instead in $Batch(Host):$tmpdir"
   }

   #----- Create job script
   set f [open [set job $env(TMPDIR)/GenPhysX[pid]] w 0755]

   #----- Extract needed domain
   set domain [join [lrange [split [lsearch -inline -glob [split $env(PATH) :] "*/SPI/*"] /] 0 end-2] /]

   puts $f "#!/bin/bash\nset -x\n"
   puts $f ". ssmuse-sh -x $domain"
   puts $f "\nexport GENPHYSX_PRIORITY=-0"
   puts $f "export GENPHYSX_BATCH=\"$gargv\"\n"
   puts $f "tmpdir=$tmpdir"

   if { $rem } {
      puts $f "trap \"cd ..; rm -fr \$tmpdir\" 0 1 2 3 6 15 30"
      puts $f "mkdir -p \$tmpdir"
   }
   puts $f "cd \$tmpdir"

   if { [info exist env(GENPHYSX_PROFILE)] } {
      if { [file exist $env(GENPHYSX_PROFILE)] } {
         puts $f "sscp $host:[file normalize $env(GENPHYSX_PROFILE)] ."
         puts $f "source [file tail $env(GENPHYSX_PROFILE)]"
      }
   }

   if { $Param(GridFile)!="" } {
      if { $rem } {
         puts $f "sscp $host:[file normalize $Param(GridFile)] ."
         append rargv " -gridfile [file tail $Param(GridFile)]"
      }
   }

   if { $Param(Script)!="" } {
      if { $rem } {
         puts $f "sscp $host:[file normalize $Param(Script)] ."
         append rargv " -param [file tail $Param(Script)]"
      }
   }
   
   if { [file exists $Param(OutFile).fst] && $rem } {
      puts $f "sscp $host:[file normalize ${Param(OutFile)}.fst] ."
   }
   if { [file exists ${Param(OutFile)}_aux.fst] && $rem } {
      puts $f "sscp $host:[file normalize ${Param(OutFile)}_aux.fst] ."
   }
   if { $rem } {
      append rargv " -result [file tail $Param(OutFile)]"
   }

   #----- Remove batch flag from arguments
   set idx [lsearch -exact $gargv "-batch"]
   set gargv [lreplace $gargv $idx $idx]

   puts $f "GenPhysX $gargv \\\n   $rargv\n"

   if { $rem } {
      puts $f "sscp -r [file tail $Param(OutFile)]* $host:$ldir\ncd ..\nrm -f -r \$tmpdir"
   }

   if { $Batch(Mail)!="" } {
      puts $f "echo $Param(OutFile) | mail -s \"GenPhysX job done\" $Batch(Mail) "
   }
   close $f

   #----- Launch job script
   Log::Print INFO "Using $Batch(Submit) to launch job ... "
   set err [catch { exec $Batch(Submit) $job -waste 100 -mach $Batch(Host) -t $Batch(Time) -cm $Batch(Mem) -cpus $Batch(CPU) 2>@1 } msg]
   if { $err } {
      Log::Print ERROR "Could not launch job ($job) on $Batch(Host)\n\n\t$msg"
      Log::End 1
   } else {
      Log::Print INFO "Job ($job) launched on $Batch(Host) ... "
   }

#   file delete -force $job
   Log::End 0
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
   catch { append version ", HydroX($HydroX::Param(Version))" }
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
      append meta "User param used: $Param(Script)\n"
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

   #----- Append databases paths
   if { [llength $Meta(Databases)] } {
      append meta "Databases used :\n"
      foreach data $Meta(Databases) {
         catch { append meta [format "   %-10s: %s\n" $data $Param(DBase)/$Path($data)] }
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
      -help     [format "%-25s : This information" ""]
      -version  [format "%-25s : GenPhysX version" ""]
      -verbose  [format "%-34s : Trace level (ERROR,WARNING,INFO,DEBUG,EXTRA,1-4)" (${::APP_COLOR_GREEN}$Log::Param(Level)${::APP_COLOR_RESET})] 

   Input parameters:
      -gridfile [format "%-34s : FSTD file to get the grid from if no GEM namelist" (${::APP_COLOR_GREEN}$Param(GridFile)${::APP_COLOR_RESET})]
      -result   [format "%-34s : Result filename" (${::APP_COLOR_GREEN}$Param(OutFile)${::APP_COLOR_RESET})]
      -target   [format "%-34s : Set necessary flags for target model {$Param(Targets)}" (${::APP_COLOR_GREEN}$Param(Target)${::APP_COLOR_RESET})]
      -dbase    [format "%-34s : Databases path" (${::APP_COLOR_GREEN}$Param(DBase)${::APP_COLOR_RESET})]
      -param    [format "%-34s : User parameter definition to include" (${::APP_COLOR_GREEN}$Param(Script)${::APP_COLOR_RESET})]

   Processing parameters:
      Specify databases in order of processing joined by + ex: STRM+USGS

      -topo     [format "%-34s : Topography method(s) among {$Param(Topos)}" (${::APP_COLOR_GREEN}[join $Param(Topo)]${::APP_COLOR_RESET})]
      -mask     [format "%-34s : Mask method, one of {$Param(Masks)}" (${::APP_COLOR_GREEN}[join $Param(Mask)]${::APP_COLOR_RESET})]
      -geomask  [format "%-34s : Mask method, one of {$Param(GeoMasks)}" (${::APP_COLOR_GREEN}[join $Param(GeoMask)]${::APP_COLOR_RESET})]
      -vege     [format "%-34s : Vegetation method(s) among {$Param(Veges)}" (${::APP_COLOR_GREEN}[join $Param(Vege)]${::APP_COLOR_RESET})]
      -soil     [format "%-34s : Soil method(s) among {$Param(Soils)}" (${::APP_COLOR_GREEN}[join $Param(Soil)]${::APP_COLOR_RESET})]
      -dbrk     [format "%-34s : Soil depth to bed rock among {$Param(SoilDBRKs)}" (${::APP_COLOR_GREEN}[join $Param(SoilDBRK)]${::APP_COLOR_RESET})]
      -aspect   [format "%-34s : Slope and aspect method(s) among {$Param(Aspects)}" (${::APP_COLOR_GREEN}[join $Param(Aspect)]${::APP_COLOR_RESET})]
      -biogenic [format "%-34s : Biogenic method(s) among {$Param(Biogenics)}" (${::APP_COLOR_GREEN}[join $Param(Biogenic)]${::APP_COLOR_RESET})]
      -hydro    [format "%-34s : Hydrographic method(s) among {$Param(Hydros)}" (${::APP_COLOR_GREEN}[join $Param(Hydro)]${::APP_COLOR_RESET})]
      -urban    [format "%-34s : Urban coverage {$Param(Urbans)}" (${::APP_COLOR_GREEN}[join $Param(Urban)]${::APP_COLOR_RESET})]
      -smoke    [format "%-34s : SMOKE emissions {$Param(SMOKE)}" (${::APP_COLOR_GREEN}[join $Param(SMOKE)]${::APP_COLOR_RESET})]
      -rindex   [format "%-34s : SMOKE restart index (default 1)" (${::APP_COLOR_GREEN}$Param(SMOKEIndex)${::APP_COLOR_RESET})]
      -check    [format "%-34s : Do consistency checks {$Param(Checks)}" (${::APP_COLOR_GREEN}$Param(Check)${::APP_COLOR_RESET})]
      -subgrid  [format "%-34s : Calculates sub grid fields {$Param(Subs)}" (${::APP_COLOR_GREEN}$Param(Sub)${::APP_COLOR_RESET})]
      -z0notopo [format "%-34s : Roughness length Z0 with no topographic contribution {$Param(Z0NoTopos)}" (${::APP_COLOR_GREEN}[join $Param(Z0NoTopo)]${::APP_COLOR_RESET})]
      -z0topo   [format "%-34s : Roughness length Z0 with topographic contribution {$Param(Z0Topos)}" (${::APP_COLOR_GREEN}[join $Param(Z0Topo)]${::APP_COLOR_RESET})]
      -z0crop   [format "%-34s : if set to non-zero, Crop Z0 should be used when crop fraction higher than this value (default 0.0)" (${::APP_COLOR_GREEN}$Param(CropZ0)${::APP_COLOR_RESET})]
      -diag     [format "%-25s : Do diagnostics (Not implemented yet)" ""]
      -egmgh    [format "%-34s : Earth Gravitational Model database to use among {$Param(EGMGHs)}" (${::APP_COLOR_GREEN}[join $Param(EGMGH)]${::APP_COLOR_RESET})]
      -bathy    [format "%-34s : Bathymetry data to use among {$Param(Bathys)}" (${::APP_COLOR_GREEN}[join $Param(Bathy)]${::APP_COLOR_RESET})]

   Specific processing parameters:
      -topostag [format "%-25s : Treat multiple grids as staggered topography grids" ""]
      -z0filter [format "%-25s : Apply GEM filter to roughness length" ""]
      -mefilter [format "%-34s : Select filter for topography field ME {$Param(MEFilters)}" (${::APP_COLOR_GREEN}$Param(MEFilter)${::APP_COLOR_RESET})]
      -celldim  [format "%-34s : Grid cell dimension (1=point, 2=area)" (${::APP_COLOR_GREEN}$Param(Cell)${::APP_COLOR_RESET})]
      -compress [format "%-34s : Compress standard file output" (${::APP_COLOR_GREEN}$Param(Compress)${::APP_COLOR_RESET})]
      -nbits    [format "%-34s : Maximum number of bits to use to save RPN fields" (${::APP_COLOR_GREEN}$Param(NBits)${::APP_COLOR_RESET})]
      -interpol [format "%-25s : Select interpolation mode to use {$Param(Interpolations)}" ""]

   Batch mode parameters (ord_soumet):
      -batch    [format "%-25s : Launch in batch mode" ""]
      -path     [format "%-34s : Remote path if local not accessible" (${::APP_COLOR_GREEN}$Batch(Path)${::APP_COLOR_RESET})]
      -mail     [format "%-34s : EMail address to send completion mail" (${::APP_COLOR_GREEN}$Batch(Mail)${::APP_COLOR_RESET})]
      -mach     [format "%-34s : Machine to run on in batch mode" (${::APP_COLOR_GREEN}$Batch(Host)${::APP_COLOR_RESET})]
      -t        [format "%-34s : Reserved CPU time (s)" (${::APP_COLOR_GREEN}$Batch(Time)${::APP_COLOR_RESET})]
      -cm       [format "%-34s : Reserved RAM (MB)" ${::APP_COLOR_GREEN}($Batch(Mem)${::APP_COLOR_RESET})]
      -cpus     [format "%-34s : Number of CPU" ${::APP_COLOR_GREEN}($Batch(CPU)${::APP_COLOR_RESET})]

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
         Log::End 1
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
      Log::Print ERROR "GenPhysX only runs on Linux"
      Log::End 1
   }

   if { !$gargc } {
      GenX::CommandLine
      Log::End 1
   }

   #----- Parse arguments
   set flags 0
   for { set i 0 } { $i < $gargc } { incr i } {
      switch -exact [string trimleft [lindex $gargv $i] "-"] {
         "version"   { puts "$Param(Version)"; Log::End 0 }
         "verbose"   { set i [Args::Parse $gargv $gargc $i VALUE         Log::Param(Level)] }
         "result"    { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(OutFile)] }
         "target"    { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Target) $GenX::Param(Targets)]; GenX::ParseTarget; incr flags }
         "nml"       { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(NML)]; GenX::GetNML $GenX::Param(NML) }
         "gridfile"  { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(GridFile)] }
         "dbase"     { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(DBase)] }
         "batch"     { set i [Args::Parse $gargv $gargc $i FLAG          GenX::Batch(On)] }
         "mach"      { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Batch(Host)] }
         "t"         { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Batch(Time)] }
         "cm"        { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Batch(Mem)] }
         "cpus"      { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Batch(CPU)] }
         "mail"      { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Batch(Mail)] }
         "topo"      { set i [Args::Parse $gargv $gargc $i LIST          GenX::Param(Topo) $GenX::Param(Topos)]; incr flags }
         "mask"      { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Mask) $GenX::Param(Masks)]; incr flags }
         "geomask"   { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(GeoMask) $GenX::Param(GeoMasks)]; incr flags }
         "vege"      { set i [Args::Parse $gargv $gargc $i LIST          GenX::Param(Vege) $GenX::Param(Veges)]; incr flags }
         "soil"      { set i [Args::Parse $gargv $gargc $i LIST          GenX::Param(Soil) $GenX::Param(Soils)]; incr flags }
         "dbrk"      { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(SoilDBRK) $GenX::Param(SoilDBRKs)]; incr flags }
         "bathy"     { set i [Args::Parse $gargv $gargc $i LIST          GenX::Param(Bathy) $GenX::Param(Bathys)]; incr flags }
         "egmgh"     { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(EGMGH) $GenX::Param(EGMGHs)]; incr flags }
         "subgrid"   { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Sub)]; incr flags }
         "aspect"    { set i [Args::Parse $gargv $gargc $i LIST          GenX::Param(Aspect) $GenX::Param(Aspects)]; incr flags }
         "biogenic"  { set i [Args::Parse $gargv $gargc $i LIST          GenX::Param(Biogenic) $GenX::Param(Biogenics)]; incr flags }
         "hydro"     { set i [Args::Parse $gargv $gargc $i LIST          GenX::Param(Hydro) $GenX::Param(Hydros)]; incr flags }
         "hydraulic" { set i [Args::Parse $gargv $gargc $i FLAG          GenX::Param(Hydraulic)]; incr flags }
         "urban"     { set i [Args::Parse $gargv $gargc $i FLAG_OR_VALUE GenX::Param(Urban) $GenX::Param(Urbans) {???[A-Za-z]??}]; incr flags }
         "smoke"     { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(SMOKE) $GenX::Param(SMOKES)]; incr flags }
         "rindex"    { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(SMOKEIndex)] }
         "check"     { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Check)]; incr flags }
         "diag"      { set i [Args::Parse $gargv $gargc $i FLAG          GenX::Param(Diag)] }
         "topostag"  { set i [Args::Parse $gargv $gargc $i FLAG          GenX::Param(TopoStag)] }
         "mefilter"  { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(MEFilter) $GenX::Param(MEFilters)]; incr flags }
         "z0filter"  { set i [Args::Parse $gargv $gargc $i FLAG          GenX::Param(Z0Filter)]; incr flags }
         "z0notopo"  { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Z0NoTopo) $GenX::Param(Z0NoTopos)]; incr flags }
         "z0topo"    { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Z0Topo)   $GenX::Param(Z0Topos)];   incr flags }
         "z0crop"    { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(CropZ0)] }
         "celldim"   { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Cell)] }
         "compress"  { set i [Args::Parse $gargv $gargc $i FLAG          GenX::Param(Compress)] }
         "nbits"     { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(NBits)] }
         "param"     { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Script)] }
         "process"   { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Process)] }
         "interpol"  { set i [Args::Parse $gargv $gargc $i VALUE         GenX::Param(Interpolation) $GenX::Param(Interpolations)]; incr flags }
         "help"      { GenX::CommandLine ; Log:::End 0 }
         default     { Log::Print ERROR "Invalid argument [lindex $gargv $i]"; GenX::CommandLine ; Log::End 1 }
      }
   }

   #----- If no grid is specified
   if { ![file readable $Param(GridFile)] } {
      Log::Print ERROR "No valid gridfile specified"
      Log::End 1
   }

   #----- If no processing is specified, we use the default target
   if { !$flags } {
      set Param(Target) [lindex $GenX::Param(Targets) 0]
      GenX::ParseTarget
      Log::Print WARNING "No data processing were specified, will use default target $Param(Target)"
      GenX::Continue
   }

   #----- Validate Param(Z0NoTopo) vs Param(Z0Topo)
   if { $GenX::Param(Z0NoTopo)!="" } {
      if { $GenX::Param(Z0Topo)!="" } {
         Log::Print WARNING "Cannot set both Param(Z0NoTopo) and Param(Z0Topo), will use Param(Z0NoTopo) only"
         set GenX::Param(Z0Topo)  ""
      }
   } else {
      if { $GenX::Param(Z0Topo)=="" } {
         switch $Param(Sub) {
            "LEGACY" {
               set GenX::Param(Z0Topo)  "LEGACY"
            }
            default {
               set GenX::Param(Z0Topo)  "STD"
            }
         }
      }
   }

   #---- when MEFilter is specified, if subgrid is not set then set it to STD
   if { $Param(MEFilter)!="" }  { 
      if { $Param(Sub)=="" }  { set GenX::Param(Sub) "STD" }
   }

   #----- Check for user definitiond
   if { $GenX::Param(Script)!="" } {
      source $Param(Script)
   }

   #----- check for user CappedNBits, if equal 24(default), reset it as min(NBits,24)
   if { $Param(CappedNBits)==24 } {
      set Param(CappedNBits)  [expr $GenX::Param(NBits)<24?$GenX::Param(NBits):24]
   } else {
   #----- CappedNBits limited to 24 if DATYP==1
      if { $Param(Datyp)==1 && $Param(CappedNBits) > 24 } {
         Log::Print WARNING "DATYP=1 cannot have CappedNBits>24, may use DATYP=5 instead"
      }
   }
   Log::Print DEBUG "NBits=$Param(NBits)"
   Log::Print DEBUG "Datyp=$Param(Datyp)"
   Log::Print DEBUG "Capped NBits=$Param(CappedNBits)"

   #----- Check dependencies
   if { $Param(Vege)!="" } {
      if { $Param(Mask)=="" } {
         set  Param(Vege2Mask)  True
         Log::Print INFO "Will be using vegetation VF1 and VF3 fields to generate the mask"
      }
   }

   if { $Param(Sub)=="STD" } {
      if { $Param(Mask)=="" && $Param(Vege2Mask)==False } {
         Log::Print ERROR "To generate sub-grid post-processed fields you need to generate the mask"
         GenX::Continue
      }
      if { $Param(Topo)=="" } {
         Log::Print ERROR "To generate sub-grid post-processed fields you need to generate the topography"
         GenX::Continue
      }
   }

   if { $Param(Biogenic)!="" } {
      if { $Param(Vege)=="" } {
            Log::Print ERROR "To generate biogenic emissions fields you need to generate the vegetation type fields (-vege option)"
            GenX::Continue
      }
      if { $Param(Check)=="" } {
            Log::Print ERROR "To generate biogenic emissions fields you must use the -check option."
            GenX::Continue
      }
   }

   if { $Param(Hydro)!="" } {
      if { $Param(Mask)=="" && $Param(Vege2Mask)==False } {
         Log::Print ERROR "To generate hydrographic type fields you need to generate the mask"
         GenX::Continue
      }
   }

   #----- Check if a filename is included in result filename
   if { [file isdirectory $Param(OutFile)] } {
      append Param(OutFile) genphysx
   }
   
   set Param(GridFile) [file normalize $Param(GridFile)]

   #----- If batch mode enabled, submit the job and exit otherwise, go to result directory
   if { $Batch(On) } {
      GenX::Submit
   } else {
      #----- Check for database accessibility
      if { ![file readable $Param(DBase)] } {
         Log::Print ERROR "Invalid database directory ($Param(DBase))"
         Log::End 1
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
   variable Settings

   switch $Param(Target) {
      "AURAMS"  { set Param(Topo)     "USGS"
                  set Param(Vege)     "USGS"
                  set Param(Mask)     "USGS"
                  set Param(Soil)     "USDA AGRC FAO"
                  set Param(Check)    "STD"
                  set Param(Sub)      ""
                  set Param(Z0Filter) False
                  set Param(Compress) False
                  set Param(TopoStag) True
                  set Param(Cell)     2

                  set Settings(TOPO_DGFMS_L) True
                  set Settings(TOPO_DGFMX_L) True
                  set Settings(TOPO_FILMX_L) True
                }

      "LEGACY"  { set Param(Topo)     "USGS"
                  set Param(Vege)     "USGS"
                  set Param(Mask)     "USGS"
                  set Param(Soil)     "USDA AGRC FAO"
                  set Param(Check)    "STD"
                  set Param(Sub)      "LEGACY"
                  set Param(Z0Filter) False
                  set Param(Compress) False
                  set Param(TopoStag) True

                  set Settings(TOPO_DGFMS_L) True
                  set Settings(TOPO_DGFMX_L) True
                  set Settings(TOPO_FILMX_L) True
               }
      "GEMMESO" { set Param(Topo)     "USGS"
                  set Param(Vege)     "USGS"
                  set Param(Mask)     "USGS"
                  set Param(Soil)     "USDA AGRC FAO"
                  set Param(Check)    "STD"
                  set Param(Sub)      "STD"
                  set Param(Z0Filter) True
                  set Param(Compress) False

                  set Settings(TOPO_DGFMS_L) True
                  set Settings(TOPO_DGFMX_L) True
                  set Settings(TOPO_FILMX_L) True
                }
      "GEM4.4"  { set Param(Topo)     "GTOPO30"
                  set Param(Vege)     "GLC2000"
                  set Param(Mask)     "GLC2000"
                  set Param(Soil)     "JPL"
                  set Param(Check)    "STD"
                  set Param(Sub)      "STD"
                  set Param(Z0Filter) True
                  set Param(Compress) False
                  set Param(Cell)     2

                  set Settings(TOPO_DGFMS_L) True
                  set Settings(TOPO_DGFMX_L) True
                  set Settings(TOPO_FILMX_L) True
                }
      "GDPS-5.1" { set Param(Topo)     "USGS"
                   set Param(Vege)     "USGS_R"
                   set Param(Mask)     "USGS_R"
                   set Param(Soil)     "USDA AGRC FAO"
                   set Param(Check)    "STD"
                   set Param(Sub)      "LEGACY"
                   set Param(Z0Filter) False
                   set Param(Compress) False
                   set Param(Cell)     1

                   set Settings(TOPO_DGFMS_L) True
                   set Settings(TOPO_DGFMX_L) True
                   set Settings(TOPO_FILMX_L) True
                   set Settings(TOPO_CLIP_ORO_L) False
                }
      "RELWS-1.0" { set Param(Topo)     "CDED250 SRTM"
                    set Param(Vege)     "CCI_LC"
                    set Param(Mask)     "CCI_LC"
                    set Param(Soil)     "BNU"
                    set Param(Check)    "STD"
                    set Param(Sub)      "STD"
                    set Param(Z0Filter) True
                    set Param(Z0NoTopo) CANOPY
                    set Param(Compress) False
                    set Param(Cell)     2

                    set Settings(GRD_TYP_S)    LU
                    set Settings(TOPO_DGFMS_L) True
                    set Settings(TOPO_DGFMX_L) True
                    set Settings(TOPO_FILMX_L) True
                    set Settings(TOPO_CLIP_ORO_L) False
                    set Const(z0minUr)  0.01
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
      Log::Print WARNING "Could not read the namelist"
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

   if { Log::Param(Level)=="DEBUG" || Log::Param(Level)=="EXTRA" } {
      Log::Print DEBUG "Read the following settings:" True GenX::Settings
      Log::Print DEBUG "Using GeoPhysX constants:"    True GeoPhysX::Const
      Log::Print DEBUG "Using BioGenX constants:"     True BioGenX::Const
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
# Name     : <GenX::CreateTypedField>
# Creation : Octobre 2007 - J.P. Gauthier - CMC/CMOE
#
# Goal     : create a new field of Grid in a difference type
#
# Parameters :
#  <NewId>   : a new id for field to create
#  <Grid>    : a grid that the new field is based on
#  <Type>    : type of the new field
#  <DefValue> : default value to set
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::CreateTypedField { NewId Grid Type {DefValue 0.0} } {
   set ni [fstdfield define $Grid -NI]
   set nj [fstdfield define $Grid -NJ]
   set nk [fstdfield define $Grid -NK]
   fstdfield create $NewId $ni $nj $nk $Type
   fstdfield copyhead $NewId $Grid
   fstdfield define $NewId -georef [fstdfield define $Grid -georef]
   fstdfield stats $NewId -nodata $DefValue
   fstdfield clear $NewId
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
   variable Settings

   set grids {}

   if { $File=="" } {
      return $grids
   }

   if { ![file exists $File] } {
      Log::Print ERROR "Grid description file does not exists: $File"
      Log::End 1
   }

   if { [catch { fstdfile open GPXGRIDFILE read $File } ] } {
      Log::Print ERROR "Could not open Grid description file: $File"
      Log::End 1
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
               Log::Print WARNING "Found duplicate grid (IP1=$ip1 IP2=$ip2 IP3=$ip3), will not process it"
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
         fstdfield clear GRID 0.0
         fstdfield define GRID -NOMVAR "GRID" -TYPVAR C -IP1 $tip1 -DATYP 1
         fstdfield write GRID GPXAUXFILE -16 True $GenX::Param(Compress)
      }
   }
   fstdfield free GRID TIC TAC

   #----- Read every grids available
   set i 0
   set grids { }
   foreach grid [fstdfield find GPXAUXFILE -1 "" -1 -1 -1 "" "GRID"] {
      fstdfield read GRID$i GPXAUXFILE $grid
      lappend grids GRID$i
      incr i
   }
   fstdfile close GPXGRIDFILE
   
   #----- Check for global (wrap-around) girds for filter settings
   if { [lsearch -exact [georef define [fstdfield define [lindex $grids 0] -georef] -type] WRAP]!=-1 } {
      set Settings(GRD_TYP_S) GU
   } else {
      set Settings(GRD_TYP_S) LU
   }

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
   variable Param

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

         if { [llength [set lst [glob -nocomplain [format "$Param(DBase)/$Path(ASTERGDEM)/UNIT_%s%02i%s%03i/*_dem.tif" $y $la $x $lo]]]] } {
            set files [concat $files $lst]
         }
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::CANVECFindFiles>
# Creation : Novembre 2007 - Jean-Philippe Gauthier - CMC/CMOE
#            June 2014 - Vanh Souvanlasy - CMC/CMDS
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
   variable Param

   # obtain CanVec database version using regexp
   set  file [file readlink  $Param(DBase)/$Path(CANVEC)]
   regexp {([A-z]+)-([0-9]+\.[0-9]+)}  $file bidon dbname version
   Log::Print INFO "CanVec database version: $version"

   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $Param(DBase)/$Path(NTS)/decoupage50k_2.shp] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }

   set ids [ogrlayer pick NTSLAYER50K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True]

   set files { }
   foreach id $ids {
      set feuillet [ogrlayer define NTSLAYER50K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 2]
      set sl   [string tolower [string range $feuillet 3 3]]
      set s50  [string range $feuillet 4 5]

      # Path structure for CanVec-9.0 or later no longer grouped files in a directory $s250$sl$s50
      # therefore, a filter is necessary when listing files in glob
      if { $version >= 9.0 } {
         set path $Param(DBase)/$Path(CANVEC)/$s250/$sl
         set filter  "$s250$sl$s50"
      } else {
         set path $Param(DBase)/$Path(CANVEC)/$s250/$sl/$s250$sl$s50
         set filter  ""
      }

      foreach layer $Layers {
         if { [llength [set lst [glob -nocomplain $path/$filter*$layer*.shp]]] } {
            Log::Print DEBUG "Found file: $lst"
            set files [concat $files $lst]
         }
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::SRTMFindFiles>
# Creation : Novembre 2007 - Alexandre Leroux - CMC/CMOE
#            Feb 2016 - Vanh Souvanlasy - CMC/CMDS
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
   variable Param

   if { [GenX::SRTMuseVersion3] == False } {
      Log::Print DEBUG "Using Old SRTM 3 arcsec database"

      set files { }
      set lonmax [expr int(ceil((180.0 + $Lon1)/5))]
      set latmax [expr int(ceil(24-((60.0 + $Lat0)/5)))]

      for { set lat [expr int(ceil(24-((60.0 + $Lat1)/5)))]} { $lat<=$latmax } { incr lat } {
         for { set lon [expr int(ceil((180.0 + $Lon0)/5))] } { $lon<=$lonmax } { incr lon } {
            if { [file exists [set path [format "$Param(DBase)/$Path(SRTM90)/srtm_%02i_%02i.TIF" $lon $lat]]] } {
               lappend files $path
            }
         }
      }
   } else {
      Log::Print DEBUG "Using new SRTM 1 arcsec database"
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
   
            if { [llength [set lst [glob -nocomplain [format "$Param(DBase)/$Path(SRTM30)/UNIT_%s%02i%s%03i/*.TIF" $y $la $x $lo]]]] } {
               set files [concat $files $lst]
            }
         }
      }
   }

   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::SRTMuseVersion3>
# Creation : Mar 2016 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Determine if we are using version 3 of SRTM
#
# Parameters :
#
# Return:
#   <Bool>  : T
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::SRTMuseVersion3 {} {
   variable Path
   variable Param

   if { $GenX::Param(SRTM3) } {
      return True
   }

# see if we are using new granules subdirectories or old SRTMv4 directory
   if { [string compare [file type $Param(DBase)/$Path(SRTM)] "link"] == 0 } {
      set  file [file readlink  $Param(DBase)/$Path(SRTM)]
   } else {
      set file $Path(SRTM)
   }
   if { [string compare [file tail $file] "granules"] == 0 } {
      set  GenX::Param(SRTM3)   True
      Log::Print DEBUG "Using SRTM version 3"
      return True
   } else {
      return False
   }
}

#----------------------------------------------------------------------------
# Name     : <GenX::SRTMsetSelection>
# Creation : Fev 2019 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : set SRTM parameters according to database selection
#
# Parameters : list of topo databases used
#
# Return:
#   <bool>
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::SRTMsetSelection { Topo } {

   if { [lsearch -exact $Topo SRTM]!=-1 } {
      # this will set  GenX::Param(SRTM3) to true if default is version 3
      GenX::SRTMuseVersion3
      return True
   }
   #----- check if SRTM30 or SRTM90 is specified
   if { [lsearch -exact $Topo SRTM30]!=-1 } {
      set  GenX::Param(SRTM3)   True
      return True
   }
   if { [lsearch -exact $Topo SRTM90]!=-1 } {
      set  GenX::Param(SRTM3)   False
      return True
   }
   return False
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
   variable Param

   if { $Res!=50 && $Res!=250 } {
      Log::Print ERROR "Wrong resolution, must be 50 or 250."
      Log::End 1
   }
   if { ![ogrlayer is NTSLAYER${Res}K] } {
      set nts_layer [lindex [ogrfile open SHAPE${Res}K read $Param(DBase)/$Path(NTS)/decoupage${Res}k_2.shp] 0]
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
         set path $Param(DBase)/$Path(CDED)/$s250/$sl/$s250$sl$s50
      } else {
         set path $Param(DBase)/$Path(CDED)/$s250/$sl/$s250$sl
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
# Name     : <GenX::CDEMFindFiles>
# Creation : March 2015 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Get the CDEM data filenames covering an area.
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
proc GenX::CDEMFindFiles { Lat0 Lon0 Lat1 Lon1 } {
   variable Path
   variable Param

# CDEM tiles configuration are same as the NTS 250, se we will use that as search table
   set Res  250

   if { ![ogrlayer is NTSLAYER${Res}K] } {
      set nts_layer [lindex [ogrfile open SHAPE${Res}K read $Param(DBase)/$Path(NTS)/decoupage${Res}k_2.shp] 0]
      eval ogrlayer read NTSLAYER${Res}K $nts_layer
   }

   set files { }
   foreach id [ogrlayer pick NTSLAYER${Res}K [list $Lat0 $Lon0 $Lat1 $Lon0 $Lat1 $Lon1 $Lat0 $Lon1 $Lat0 $Lon0] True] {
      set feuillet [ogrlayer define NTSLAYER${Res}K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 2]
      set sl   [string tolower [string range $feuillet 3 3]]
      set path $Param(DBase)/$Path(CDEM)/$s250

      set  SL  [string toupper $sl]
      set file  $path/cdem_dem_$s250$SL.tif
      if { [llength [set lst [glob -nocomplain $file]]] } {
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
   variable Param

   if { ![ogrlayer is NTSLAYER250K] } {
      set nts_layer [lindex [ogrfile open SHAPE250K read $Param(DBase)/$Path(NTS)/decoupage250k_2.shp] 0]
      eval ogrlayer read NTSLAYER250K $nts_layer
   }

   set files { }
   foreach id [ogrlayer pick NTSLAYER250K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set feuillet [ogrlayer define NTSLAYER250K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 3]
      if { [file exists [set path $Param(DBase)/$Path(EOSD)/${s250}_lc_1/${s250}_lc_1.tif]] } {
         lappend files $path
      }
   }
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::NHNFindFiles>
# Creation : August 2011 - J.P. Gauthier - CMC/CMOE
# Revision : October 2014 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Get the NHN data filenames covering an area.
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
proc GenX::NHNFindFiles { Lat0 Lon0 Lat1 Lon1 } {
   variable Path
   variable Param

   if { ![ogrlayer is NHNLAYER] } {
      set nhn_layer [lindex [ogrfile open NHNINDEX read $Param(DBase)/$Path(NHN)/index/NHN_INDEX_07_INDEX_WORKUNIT_LIMIT_2.shp] 0]
      eval ogrlayer read NHNLAYER $nhn_layer
   }

   array unset  Feuillets
#
# For NHN prior to 2013 update: 
#    All datasetnam that have 000 ending, reject other dataset of same 
#    wscssda because they are older partial overlapping duplicates.
#    If 000 not present, keep all other dataset of same wscssda
#
   set files { }
   foreach id [ogrlayer pick NHNLAYER [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set feuillet [ogrlayer define NHNLAYER -feature $id DATASETNAM]
      set wscmda [ogrlayer define NHNLAYER -feature $id WSCMDA]
      set wscssda [ogrlayer define NHNLAYER -feature $id WSCSSDA]
      if { [llength [set path [glob -nocomplain $Param(DBase)/$Path(NHN)/shp_fr/$wscmda/RHN_${feuillet}_*.shp]]] == 0 } {
         continue
      }
      if { [info exist Feuillets($wscssda)] } {
         set  dset  [string range $Feuillets($wscssda) 4 6]
         set  dset2 [string range $feuillet 4 6]
         if { [string compare $dset2 000] == 0 } {
            set  Feuillets($wscssda)  $feuillet
         } else {
            if { [llength $Feuillets($wscssda)] == 1 } {
               if { [string compare $dset 000] == 0 } {
               } else {
                  lappend Feuillets($wscssda) $feuillet
               }
            } else {
              if { [lsearch Feuillets($wscssda) $feuillet] < 0 } {
                  lappend Feuillets($wscssda) $feuillet
              }
            }
         }
      } else {
         set  Feuillets($wscssda)  $feuillet
      }
   }

   foreach wscssda [array names Feuillets] {
      foreach feuillet $Feuillets($wscssda) {
         set wscmda  [string range $feuillet 0 1]
         if { [llength [set path [glob -nocomplain $Param(DBase)/$Path(NHN)/shp_fr/$wscmda/RHN_${feuillet}_*.shp]]] > 0 } {
            lappend files $Param(DBase)/$Path(NHN)/shp_fr/$wscmda/RHN_${feuillet}
         }
      }
   }

   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::NHDFindFiles>
# Creation : Februrary 2014 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Get the NHD data filenames covering an area.
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
proc GenX::NHDFindFiles { Lat0 Lon0 Lat1 Lon1 } {
   variable Path
   variable Param

   set nhd_dir  $Param(DBase)/$Path(NHD)/flowlines

   if { ![ogrlayer is NHDLAYER] } {
      set nhd_layer [lindex [ogrfile open NHDINDEX read $nhd_dir/Index/NHD_LinearWater_Index.shp] 0]
      eval ogrlayer read NHDLAYER $nhd_layer
   }

   set files { }
   foreach id [ogrlayer pick NHDLAYER [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set file [ogrlayer define NHDLAYER -feature $id IDX_PATH]
      lappend files $nhd_dir/$file
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
   variable Param

   if { ![ogrlayer is NTSLAYER250K] } {
      set nts_layer [lindex [ogrfile open SHAPE250K read $Param(DBase)/$Path(NTS)/decoupage250k_2.shp] 0]
      eval ogrlayer read NTSLAYER250K $nts_layer
   }

   set files { }
   foreach id [ogrlayer pick NTSLAYER250K [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set feuillet [ogrlayer define NTSLAYER250K -feature $id IDENTIFIAN]
      set s250 [string range $feuillet 0 2]
      set maj  [string toupper [string range $feuillet 0 3]]

      if { [llength [set path [glob -nocomplain $Param(DBase)/$Path(LCC2000V)/${s250}/*LCC2000-V_${maj}*.shp]]] } {
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

   Log::Print DEBUG "UTM zone is $zone, with central meridian at $meridian and dimension $Param(Width)x$Param(Height)"

   return $Name
}

#----------------------------------------------------------------------------
# Name     : <GenX::Create_GridGeometry>
# Creation : Novembre 2012 - Vanh Souvanlasy
#
# Goal     : create a fine polygon that surround the grid extent,
#            not just the 4 corners
#
# Parameters :
#   <Grid>   : Grid
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Create_GridGeometry { Grid poly } {

   set limits [georef limit [fstdfield define $Grid -georef]]
   set lat0 [lindex $limits 0]
   set lon0 [lindex $limits 1]
   set lat1 [lindex $limits 2]
   set lon1 [lindex $limits 3]
  
   set ni  [fstdfield define $Grid -NI]
   set nj  [fstdfield define $Grid -NJ]

   set ni1  [expr $ni-0.5]
   set nj1  [expr $nj-0.5]

   set ring  $poly.ring
   ogrgeometry free $ring
   ogrgeometry free $poly
   ogrgeometry create $poly "Polygon"
   ogrgeometry create $ring "Linear Ring"
   ogrgeometry define $ring -points {}

   set j  0
   for {set i 0} { $i <= $ni } { incr i } {
      set pi [expr $i - 0.5]
      set pj [expr $j - 0.5]
      set ll  [fstdfield stats $Grid -project $pi $pj]
      ogrgeometry define $ring -addpoint [lindex $ll 1] [lindex $ll 0]
   }
   set i  [expr $ni-1]
   for {set j 1} { $j <= $nj } { incr j } {
      set pi [expr $i + 0.5]
      set pj [expr $j - 0.5]
      set ll  [fstdfield stats $Grid -project $pi $pj]
      ogrgeometry define $ring -addpoint [lindex $ll 1] [lindex $ll 0]
   }
   set j  [expr $nj-1]
   for {set i [expr $ni-1]} { $i >= 0 } { incr i -1 } {
      set pi [expr $i - 0.5]
      set pj [expr $j + 0.5]
      set ll  [fstdfield stats $Grid -project $pi $pj]
      ogrgeometry define $ring -addpoint [lindex $ll 1] [lindex $ll 0]
   }
   set i  0
   for {set j [expr $nj-1]} { $j >= 0 } { incr j -1 } {
      set pi [expr $i - 0.5]
      set pj [expr $j - 0.5]
      set ll  [fstdfield stats $Grid -project $pi $pj]
      ogrgeometry define $ring -addpoint [lindex $ll 1] [lindex $ll 0]
   }
   ogrgeometry define $poly -geometry False $ring
}

#----------------------------------------------------------------------------
# Name     : <GenX::FindFiles>
# Creation : February 2015 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Find file intersecting the grid area
#
# Parameters :
#  <Grid>    : grid upon which to test
#
# Return:
#   <files>  : List of files intersecting with the area
#
# Remarks :   
#
#----------------------------------------------------------------------------
proc GenX::FindFiles { indexfile Grid } {
   variable Param

   set  files {}
   set  rejected {}
   if { ![file exist $indexfile] } {
      Log::Print INFO "Index file not found: $indexfile"
      return $files
   }

   set poly  $Grid.poly
   GenX::Create_GridGeometry $Grid $poly
   set NI  [fstdfield define $Grid -NI]
   set NJ  [fstdfield define $Grid -NJ]
   set layer [lindex [ogrfile open UTSINDEXFILE read $indexfile] 0]
   eval ogrlayer read SHPINDEXLAYER $layer

   set nb [ogrlayer define SHPINDEXLAYER -nb]

   set cnt   0
   for { set id 0 } { $id< $nb } { incr id } {
      set path [ogrlayer define SHPINDEXLAYER -feature $id IDX_PATH]
      set Geom [ogrlayer define SHPINDEXLAYER -geometry $id]
      set  geom [ogrgeometry define $Geom -geometry]
      if { [GeomIntersectGrid $Grid $geom] || 
           [ogrgeometry stats $Geom -intersect $poly] } {
         Log::Print DEBUG "Will use file: $path"
         lappend files $path
         incr cnt
      } else {
         Log::Print DEBUG "Skip file: $path"
         lappend rejected $path
      }
   }
   ogrfile close UTSINDEXFILE

   Log::Print DEBUG "Using $cnt of $nb files"

   ogrgeometry free $poly
   return $files
}

#----------------------------------------------------------------------------
# Name     : <GenX::GeomIntersectGrid>
# Creation : February 2015 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Test if geometry intersect with grid
#
# Parameters :
#  <geom>    : geometry containing latlon points
#  <Grid>    : grid upon which to test
#
# Return:
#   <files>  : List of files intersecting with the area
#
# Remarks :   
#
#----------------------------------------------------------------------------
proc GenX::GeomIntersectGrid { Grid geom } {

   set NI  [fstdfield define $Grid -NI]
   set NJ  [fstdfield define $Grid -NJ]
   set  i  0
   foreach  ll [ogrgeometry define $geom -points] {
       set LatLon($i) $ll
       if {$i == 1} {
          set xy0 [fstdfield stats $Grid -unproject $LatLon(1) $LatLon(0)]
          set x [lindex $xy0 0]
          set y [lindex $xy0 1]
          if { ($x <= ($NI+1))&&($x >= 0) } {
             if { ($y <= ($NJ+1))&&($y >= 0) } {
                Log::Print DEBUG "$LatLon(1) $LatLon(0) : ($x $y) : $NI $NJ"
                return 1
             }
          }
       }
       set i  [expr 1-$i]
   }

   return 0
}

#----------------------------------------------------------------------------
# Name     : <GenX::Load_CCRN_Table>
# Creation : March 2015 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Load a Data Class to CCRN (RPN) Correspondance Table
#
# Parameters :
#  <filename>    : file containing a table
#
# Return:
#   <files>  : List of correspondance table
#
# Remarks :   
#
#----------------------------------------------------------------------------
proc  GenX::Load_CCRN_Table { filename } {

   if { ![file exist $filename] } {
      return {}
   }

   Log::Print INFO "Loading correspondance file: $filename"
   set  from {}
   set  to   {}

   set   n    0
   set   f  [open $filename r]
   while { ![eof $f] } {
      gets $f  line
      set head  [string range $line 0 0]
      if { [string compare $head "#"] == 0 } {
         continue
      }
      if { [scan $line  "%d %d %s"  class ccrn comment] >= 2 } {
         lappend  from $class
         lappend  to   $ccrn
         incr  n
      }
   }

   close $f

   Log::Print INFO "Got: $from $to"
   return [list $from $to]
}

#----------------------------------------------------------------------------
# Name     : <GenX::Load_CSV_Vector>
# Creation : Feb 2019 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Load a Data Class to Splitted CCRN fraction Correspondance Table
#
# Parameters :
#  <filename>    : file containing a table
#
# Return:
#   <vector>  : Vector of correspondance table
#
# Remarks :   
#
#----------------------------------------------------------------------------
proc  GenX::Load_CSV_Vector { filename {vectorid ""} } {

   if { ![file exist $filename] } {
      return {}
   }

   if { [string compare $vectorid ""] == 0 } {
      set  vectorid CSVLUT$filename
   }
   vector create $vectorid

   set   f  [open $filename r]

   # getting the first line as dimension of the vector
   # skip all comment lines if any
#   gets $f headline ;# Setting the dimension of the vector
   while { ![eof $f] } {
      gets $f line
      # skip all comment lines
      set head  [string range $line 0 0]
      if { [string compare $head "#"] == 0 } {
         continue
      }
      set headline $line
      break
   }
#   gets $f headline ;# Setting the dimension of the vector
   set attribs [split $headline ,]
   vector dim $vectorid $attribs

   while { ![eof $f] } {
      gets $f line
      # skip all comment lines
      set head  [string range $line 0 0]
      if { [string compare $head "#"] == 0 } {
         continue
      }
      if { $line!="" } {
         set tuple [split $line ,]
         vector append $vectorid $tuple
      }
   }
   close $f
   return $vectorid
}

#----------------------------------------------------------------------------
# Name     : <GenX::Get_GDFile_Reso>
# Creation : October 2017 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Estimate a GDAL File resolution
#
# Parameters :
#  <gdfile>    : GDAL File handle
#
# Return:
#   <reso>  : resolution in degree
#
# Remarks :   
#
#----------------------------------------------------------------------------
proc GenX::Get_GDFile_Reso { gdfile } {

# use center of tile to calculate latitude and longitude difference between 2 points
   set i   [expr int([gdalfile width $gdfile]/2)]
   set j   [expr int([gdalfile height $gdfile]/2)]
   set ll1  [gdalfile project $gdfile $i $j]
   set ll2  [gdalfile project $gdfile [expr $i+1] [expr $j+1]]
   set la0 [lindex $ll1 0]
   set la1 [lindex $ll2 0]
   set lo0 [lindex $ll1 1]
   set lo1 [lindex $ll2 1]

   set dlat  [expr abs($la0 - $la1)]
   set dlon  [expr abs($lo0 - $lo1)]
   if { $dlat > $dlon } {
      set reso $dlat
   } else {
      set reso $dlon
   }
   return $reso
}

#----------------------------------------------------------------------------
# Name     : <GenX::Get_Grid_Reso>
# Creation : October 2017 - Vanh Souvanlasy - CMC/CMDS
#
# Goal     : Estimate a Grid resolution
#
# Parameters :
#  <Grid>    : grid upon which to test
#
# Return:
#   <reso>  : resolution in degree
#
# Remarks :   
#
#----------------------------------------------------------------------------
proc GenX::Get_Grid_Reso { Grid } {

# use center of grid to calculate latitude and longitude difference between 2 grid points
   set i   [expr int([fstdfield define $Grid -NI]/2)]
   set j   [expr int([fstdfield define $Grid -NJ]/2)]
   set ll1  [fstdfield stats $Grid -project $i $j]
   set ll2  [fstdfield stats $Grid -project [expr $i+1] [expr $j+1]]

   set la0  [lindex $ll1 0]
   set la1  [lindex $ll2 0]
   set lo0  [lindex $ll1 1]
   set lo1  [lindex $ll2 1]

   set dlat  [expr abs($la0 - $la1)]
   set dlon  [expr abs($lo0 - $lo1)]

# return the coarser one
   if { $dlat > $dlon } {
      set reso $dlat
   } else {
      set reso $dlon
   }
   return $reso
}

#----------------------------------------------------------------------------
# Name     : <GenX::Fetch_Shpfile_Index>
# Creation : Novembre 2012 - Vanh Souvanlasy
#
# Goal     : create a fine polygon that surround every grid point
#            not just the 4 corners
#
# Parameters :
#   <indexfile>   : Grid
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc GenX::Fetch_Shpfile_Index { indexfile Lat0 Lon0 Lat1 Lon1 } {

   set layer [lindex [ogrfile open INDEXFILE read $indexfile] 0]
   eval ogrlayer read INDEXLAYER $layer

# there is something wrong with intersect routine
#   foreach id [ogrlayer pick INDEXLAYER POLY 1 INTERSECT]
   set files {}
   foreach id [ogrlayer pick INDEXLAYER [list $Lat1 $Lon1 $Lat1 $Lon0 $Lat0 $Lon0 $Lat0 $Lon1 $Lat1 $Lon1] True] {
      set geom [ogrlayer define INDEXLAYER -geometry $id]
         set file [ogrlayer define INDEXLAYER -feature $id IDX_PREFIX]
         lappend files $file
   }
   ogrfile close INDEXFILE

   ogrlayer free INDEXLAYER
   return $files
}

