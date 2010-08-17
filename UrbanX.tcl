#============================================================================
# Environnement Canada
# Centre Meteorologique Canadien
# 2121 Trans-Canadienne
# Dorval, Quebec
#
# Project    : Geophysical field generator.
# File       : UrbanX.tcl
# Creation   : Janvier 2006- Alexandre Leroux / J.P. Gauthier - CMC/CMOE
# Revision   : $Id$
# Description: Classification urbaine automatis�e, principalement � partir de
#              donn�es CanVec 1:50000, StatCan (population) et b�timents 3D
#              pour alimenter le mod�le TEB
#
# Remarks  :
#   Aucune.
#
# Functions :
#
#============================================================================

namespace eval UrbanX { } {
   variable Param
   variable Const

   set Param(Version)   0.2

   set Param(Resolution) 5       ;# Spatial rez of rasterization and outputs, leave at 5m unless for testing purposes
   set Param(Buffer)     0.001   ;# Includes about 200m buffers to account for off-zone buffers which would influence results
   set Param(Mode)       FAST    ;# Rasterization mode: INCLUDED or FAST - fast is... much much faster!
   set Param(HeightGain) 0       ;# Default value if proc HeightGain is not ran
   set Param(Width)      0       ;# Largeur du domaine
   set Param(Height)     0       ;# Hauteur du domaine

   set Param(Lon1)           0.0 ;# Top right longitude
   set Param(Lat1)           0.0 ;# Top right latitude
   set Param(Lon0)           0.0 ;# Lower left longitude
   set Param(Lat0)           0.0 ;# Lower Left latitude
   set Param(HeightFile)     ""
   set Param(HeightMaskFile) ""
   set Param(Shape)          ""
   set Param(ShapeField)     ""

   #List of CanVec entities, of general form AA_9999999_9,
      #where AA is the theme code (BS = Building and structures, EN = Energy, FO = Relief and landforms, HD = Hydrography, IC = Industrial and commercial areas, LI = Administrative boundaries, LX = Places of interest, SS = Water saturated soils, TO = Toponymy, TR = Transportation, VE = Vegetation) ,
      #9999999 is a generic code
      #and the last digit indicates the geometry (0 = point, 1 = line, 2 = polygon)
   #with associated parameters :
      #PRI = priority for rasterizarion set within Param(Priorities)
      #TEB = classes for TEB set within Param(TEBClasses)
      #SMO = classes for SMOKE set within Param(SMOKEClasses)
      #Description = indicates what is represented by the entity
      #Traitement = indicates if the entity is regular or particular (excluded, post-pro...)
      #Note = gives information about possible post-processing

      #Entity							Pri		TEB		SMO	Description																							Traitement		Note
      #BS_1250009_0		000	000	000	"Navigation aid, point"																	Excluded			"Ajouter un post-traitement sur aid? (-1=unknown, 1=navigation beacon, 2= navigation light)"
      #BS_1370009_2		605	200	000	"Residential area, polygon"														Regular			"Aucun post-traitement particulier"
      #BS_2000009_0		120	420	000	"Parabolic antenna, point"															Regular			"Ajouter un post-traitement sur type? (1=radar, 2=radio telescope)"
      #BS_2010009_0		020	110	000	"Building, point"																				PostPro				"function in (11, 16, 23, 27, 37) Pri=21 TEB=111 ; function in (9, 12, 17, 19, 26, 39) PRI= 22 TEB= 112; else general"
      #BS_2010009_2		300	120	000	"Building, polygon"																			PostPro				"function in (11, 16, 23, 27, 37) Pri=301 TEB=100 ; function in (9, 12, 17, 19, 26, 39) PRI=302 TEB=100; else general"
      #BS_2060009_0		035	420	000	"Chimney, point"																				PostPro				"if type=1 (burner) PRI=34 TEB=420; if type=2 (industrial) PRI=33 TEB=420; if type =3 (flare stack) PRI=32 TEB=420; else general value"
      #BS_2080009_0		065	410	000	"Tank, point"																						Regular			"Ajouter un post-traitement sur type?(-1=unknown,1=horizontal,2=vertical) Ajouter un post-traitement sur use?(-1=unknown,1=other,2=water)"
      #BS_2080009_2		665	410	000	"Tank, polygon"																				Regular			"Ajouter un post-traitement sur type?(-1=unknown,1=horizontal,2=vertical) Ajouter un post-traitement sur use?(-1=unknown,1=other,2=water)"
      #BS_2120009_0		000	000	000	"Cross, point"																					Excluded			"Aucun post-traitement particulier"
      #BS_2230009_1		000	000	000	"Transmission line, line"																Excluded			"Ajouter un post-traitement sur location? (1=other)  Ajouter un post-traitemen tusr function (1=telephone)"
      #BS_2240009_1		570	450	000	"Wall / fence, line"																			Regular			"Ajouter un post-traitement sur type? (1=fence, 2=wall)"
      #BS_2310009_1		550	430	000	"Pipeline (Sewage / liquid waste), line"								PostPro				"if relation2ground !=1 (aboveground), excluded.  else, general value"
      #BS_2350009_0		000	000	000	"Well, point"																						Excluded			"Ajouter un post-traitement sur type? (-1=unknown, 1=water, 2=petroleum)"
      #BS_2380009_0		000	000	000	"Underground reservoir, point"												Excluded			"Aucun post-traitement particulier"
      #BS_2380009_2		000	000	000	"Underground reservoir, polygon"											Excluded			"Aucun post-traitement particulier"
      #BS_2440009_0		100	140	000	"Silo, point"																						Regular			"Aucun post-traitement particulier"
      #BS_2530009_0		030	420	000	"Tower, point"																					Regular			"Ajouter un post-traitement sur function? (1=communication, 2=control, 3=clearance, 4=fire, 5=lookout)"
      #EN_1120009_1		000	000	000	"Power transmission line, line"													Excluded			"Ajouter un post-traitement sur type? (1=overhead, 2=submarine)"
      #EN_1180009_1		550	430	000	"Pipeline, line"																					PostPro				"if relation2ground !=1 (aboveground), excluded; else, general value.  Ajouter un post-traitement sur product? (-1=unknown, 1=natural gaz, 2=oil, 3=multiuse)"
      #EN_1340009_0		000	000	000	"Valve, point"																					Excluded			"Aucun post-traitement particulier"
      #EN_1360049_0		130	110	000	"Gas and oil facilities, point"														Regular			"Aucun post-traitement particulier"
      #EN_1360049_2		780	320	000	"Gas and oil facilities, polygon"												Regular			"Aucun post-traitement particulier"
      #EN_1360059_0		050	360	000	"Transformer station, point"														Regular			"Aucun post-traitement particulier"
      #EN_1360059_2		710	360	000	"Transformer station, polygon"													Regular			"Aucun post-traitement particulier"
      #EN_2170009_0		230	420	000	"Wind-operated device, point"													Regular			"Aucun post-traitement particulier"
      #FO_1030009_1		000	000	000	"Contour, line"																					Excluded			"Ajouter un post-traitement sur generation? (-1=unknown, 1=collected, 2=derived) Ajouter un post-traitement sur type?" (1=depression, 2=elevation)
      #FO_1080019_2		000	000	000	"Landform, polygon"																		Excluded			"Aucun post-traitement particulier"
      #FO_1080029_1		640	830	000	"Esker, line"																						Regular			"Aucun post-traitement particulier"
      #FO_1080039_2		990	902	000	"Glacial debris undifferentiated, polygon"							Regular			"Aucun post-traitement particulier"
      #FO_1080049_2		999	830	000	"Moraine, polygon"																		Regular			"Aucun post-traitement particulier"
      #FO_1080059_2		990	903	000	"Sand, polygon"																				Regular			"Aucun post-traitement particulier"
      #FO_1080069_2		999	820	000	"Tundra, polygon"																			Regular			"Aucun post-traitement particulier"
      #FO_1080079_0		000	000	000	"Pingo, point"																					Excluded			"Aucun post-traitement particulier"
      #FO_1200009_0		000	000	000	"Elevation point, point"																Excluded			"Ajouter un post-traitement sur type? (1=precise altitude, 2=cartographic spot height, 3=spot height)"
      #FO_2570009_1		000	000	000	"Contour imperial, line"																Excluded			"Ajouter un post-traitement sur generation? (-1=unknown, 1=collected, 2=derived) Ajouter un post-traitement sur type?"
      #FO_2610009_0		000	000	000	"Elevation point imperial, point"												Excluded			"Ajouter un post-traitement sur type? (1=precise altitude, 2=spot height)"
      #HD_1140009_2		991	902	000	"Permanent snow and ice, polygon"										Regular 			"Aucun post-traitement particulier"
      #HD_1450009_0		180	440	000	"Manmade hydrographic entity [Geobase], point"			PostPro				"if type!=8 (exclus fish_la), valeur g�n�rale; if type=7, PRI=170, TEB=320 (boat_ra); if type=1, PRI=242, TEB=440 (dam); if type=6, PRI=190, TEB=440 (lock gate)"
      #HD_1450009_1		610	440	000	"Manmade hydrographic entity [Geobase], line"				PostPro				"if type=1 PRI=400 TEB=440 (dam); if type=3 PRI=290 TEB=320 (wharf); if type=4 PRI=645 TEB=440 (breakwa); if type=5 PRI=630 TEB=830 (dyke & seawall); if type=6 PRI=280 TEB=440 (lock gate); else general"
      #HD_1450009_2		910	440	000	"Manmade hydrographic entity [Geobase], polygon"	PostPro				"if type=1, PRi=911 TEB=440 (dam); if type=9 PRI=765 TEB=410 (slip); else general"
      #HD_1460009_0		185	830	000	"Hydrographic obstacle entity [Geobase], point"			PostPro				"if type=7, valeur generale"
      #HD_1460009_1		580	830	000	"Hydrographic obstacle entity [Geobase], line"				PostPro				"if type=7, valeur generale"
      #HD_1460009_2		740	830	000	"Hydrographic obstacle entity [Geobase], polygon"		PostPro				"if type in (3, 103), valeur g�n�rale"
      #HD_1470009_1		590	901	000	"Single line watercourse [Geobase], line"							PostPro				"if def=1 PRI=250 TEB=901; if def=2 PRI=320 TEB=430 ; if def=6 PRI=590 TEB=901; else general"
      #HD_1480009_2		740   830	000	"Waterbody [Geobase], polygon"											PostPro				"if permanency=2 PRI = 970, TEB=830; if waterdef=1 PRI=610 TEB=440; if waterdef=5 PRI=860 TEB=440; if waterdef=8 PRI=861 TEB=440; else general value"
      #HD_1490009_2		000	000	000	"Island [Geobase], polygon"														Excluded			"Aucun post-traitement particulier"
      #IC_1350019_2		821	830	000	"Pit, polygon"																					Regular			"Aucun post-traitement particulier"
      #IC_1350029_2		822	830	000	"Quarry, polygon"																			Regular			"Aucun post-traitement particulier"
      #IC_1350039_0		163	830	000	"Extraction area, point"																Regular			"Aucun post-traitement particulier"
      #IC_1350039_2		823	830	000	"Extraction area, polygon"															Regular			"Aucun post-traitement particulier"
      #IC_1350049_0		160	830	000	"Mine, point"																						Regular			"Aucun post-traitement particulier"
      #IC_1350049_2		820	830	000	"Mine, polygon"																				Regular			"Aucun post-traitement particulier"
      #IC_1350059_2		840	840	000	"Peat cutting, polygon"																Regular			"Aucun post-traitement particulier"
      #IC_1360019_2		860	440	000	"Domestic waste, polygon"														Regular			"Aucun post-traitement particulier"
      #IC_1360029_0 		045	440	000	"Industrial solid waste, point"													Regular			"Aucun post-traitement particulier"
      #IC_1360029_2		860	440	000	"Industrial solid waste, polygon"												Regular			"Aucun post-traitement particulier"
      #IC_1360039_0		060	400	000	"Industrial and commercial area, point"								Regular			"Aucun post-traitement particulier"
      #IC_1360039_2		600	400	000	"Industrial and commercial area, polygon"						Regular			"Aucun post-traitement particulier"
      #IC_2110009_2		770	450	000	"Lumber yard, polygon"																Regular			"Aucun post-traitement particulier"
      #IC_2360009_2		775	410	000	"Auto wrecker, polygon"																Regular			"Aucun post-traitement particulier"
      #IC_2600009_0		161	830	000	"Mining area, point"																		PostPro				"if type = 1 (underground), PRI = 162, TEB=110; else general"
      #LI_1210009_2		000	000	000	"NTS50K boundary polygon, polygon"									Excluded			"Changement de g�om�trie, de lin�aire (BNDT) � surfacique (CanVec). Ajout d'un post-traitement sur tiling? (1=extended, 2=multiple, 3=simple, 4=theoretical) Ajout d'un post-traitement sur flooded? (1=partly flooded, 2=totally flooded)"
      #LX_1000019_0		140	360	000	"Lookout, point"																				Regular			"Aucun post-traitement particulier"
      #LX_1000019_2		670	360	000	"Lookout, polygon"																		Regular			"Aucun post-traitement particulier"
      #LX_1000029_0		060	110	000	"Ski centre, point"																			Regular			"Aucun post-traitement particulier"
      #LX_1000039_0		070	720	000	"Cemetery, point"																			Regular			"Aucun post-traitement particulier"
      #LX_1000039_2		890	520	000	"Cemetery, polygon"																		Regular			"Aucun post-traitement particulier"
      #LX_1000049_2		810	120	000	"Fort, polygon"																					Regular			"Aucun post-traitement particulier"
      #LX_1000059_0		000	000	000	"Designated area, point"															Excluded			"Aucun post-traitement particulier"
      #LX_1000059_1		000	000	000	"Designated area, line"																Excluded			"Aucun post-traitement particulier"
      #LX_1000059_2		000	000	000	"Designated area, polygon"														Excluded			"Aucun post-traitement particulier"
      #LX_1000069_0		244	110	000	"Marina, point"																					Regular			"Aucun post-traitement particulier"
      #LX_1000079_1		270	330	000	"Sport track / Race track, line"													Regular			"Aucun post-traitement particulier"
      #LX_1000079_2		270	330	000	"Sport track / Race track, polygon"										Regular			"Aucun post-traitement particulier"
      #LX_1000089_2		850	820	000	"Golf course, polygon"																	Regular			"Aucun post-traitement particulier"
      #LX_2030009_0		090	520	000	"Camp, point"																					Regular			"Aucun post-traitement particulier"
      #LX_2070009_0		080	110	000	"Drive-in theatre, point"																Regular			"Aucun post-traitement particulier"
      #LX_2070009_2		760	320	000	"Drive-in theatre, polygon"															Regular			"Aucun post-traitement particulier"
      #LX_2200009_2		885	520	000	"Botanical garden, polygon"														Regular			"Aucun post-traitement particulier"
      #LX_2210009_0		000	000	000	"Shrine, point"																					Excluded			"Aucun post-traitement particulier"
      #LX_2220009_0		150	530	000	"Historical site / Point of interest, point"								Regular			"Aucun post-traitement particulier"
      #LX_2260009_2		865	450	000	"Amusement park, polygon"														Regular			"Aucun post-traitement particulier"
      #LX_2270009_2		870	820	000	"Park / sports field, polygon"														Regular			"Aucun post-traitement particulier"
      #LX_2280009_1		200	360	000	"Footbridge, line"																			Regular			"Aucun post-traitement particulier"
      #LX_2400009_0		110	530	000	"Ruins, point"																					Regular			"Aucun post-traitement particulier"
      #LX_2400009_2		800	530	000	"Ruins, polygon"																				Regular			"Aucun post-traitement particulier"
      #LX_2420009_1		240	520	000	"Trail, line"																							Regular			"Ajouter un post-traitement sur function? (-1=unknown, 1=other, 2-portage)"
      #LX_2460009_2		660	120	000	"Stadium, polygon"																		Regular			"Aucun post-traitement particulier"
      #LX_2480009_0		095	110	000	"Campground, point"																	Regular			"Aucun post-traitement particulier"
      #LX_2480009_2		860	820	000	"Campground, polygon"																Regular			"Aucun post-traitement particulier"
      #LX_2490009_0		085	520	000	"Picnic site, point"																			Regular			"Aucun post-traitement particulier"
      #LX_2490009_2		875	520	000	"Picnic site, polygon"																		Regular			"Aucun post-traitement particulier"
      #LX_2500009_0		852	820	000	"Golf drining range, point"															Regular			"Aucun post-traitement particulier"
      #LX_2500009_2		852	820	000	"Golf drining range, polygon"													Regular			"Aucun post-traitement particulier"
      #LX_2510009_2		790	530	000	"Exhibition ground, polygon"													Regular			"Ajouter un post-traitement sur type? (1=other, 2=fairground)"
      #LX_2560009_2		880	520	000	"Zoo, polygon"																					Regular			"Aucun post-traitement particulier"
      #SS_1320019_2		999	840	000	"Tundra pond, polygon"																Regular			"Aucun post-traitement particulier"
      #SS_1320029_2		999	840	000	"Palsa bog, polygon"																		Regular			"Aucun post-traitement particulier"
      #SS_1320039_2		000	000	000	"Saturated soil, polygon"															Excluded			"Aucun post-traitement particulier"
      #SS_1320049_2		690	840	000	"Wetland, polygon"																		Regular			"Aucun post-traitement particulier"
      #SS_1320059_2		999	840	000	"Sting bog, polygon"																		Regular			"Aucun post-traitement particulier"
      #TO_1580009_0		000	000	000	"Named feature, point"																Excluded			"Aucun post-traitement particulier"
      #TO_1580009_1		000	000	000	"Named feature, line"																	Excluded			"Aucun post-traitement particulier"
      #TO_1580009_2		000	000	000	"Named feature, polygon"															Excluded			"Aucun post-traitement particulier"
      #TR_1020009_1		310	340	000	"Railway, line"																					PostPro				"if support != 4, general (exclusion des tunnels)"
      #TR_1190009_0		040	310	000	"Runway, point"																				PostPro				"if type = 4 (sea) PRI = 181 TEB = 440; else general"
      #TR_1190009_2		650	310	000	"Runway, polygon"																			PostPro				"if type = 4 (sea) PRI = 181 TEB = 440; else general"
      #TR_1750009_1		220	000	000	"Ferry connection segment [Geobase], line"						Regular			"Ajout d'un post-traitement sur road class? (1=freeway, 2=exrpressway/highway, 3=arterial, 4=collector, 5=local/street, 6=local/strata, 7=local/unknown, 8=alleyway/lane, 9=ramp, 10=resource/recreation, 11=rapid transit, 12=service lane, 13=winter)"
      #TR_1760009_1		210	320	000	"Road segment [Geobase], line"												PostPro				"if structure type not in (5,6), general; if structure type in (1,2,3,4) PRI=205 TEB=350 (bridge); if structure type = 7, PRI=242, TEB=440 (dam); if pavement status = 2, PRI=212, TEB=320 (unpaved); if class in (1,2), PRI=211 TEB=320 (freeway, highway)
      #TR_1770009_0		000	000	000	"Junction [Geobase], point"														Excluded			"Ajout d'un post-traitement sur type? (-1=intersection, 2=dead end, 3=ferry, 4=NavProvTer)"
      #TR_1780009_0		000	000	000	"Blocked passage [Geobase], point"										Excluded			"Ajout d'un post-traitement sur type? (-1=unknown, 1=removable, 2=permanently fixed)"
      #TR_1790009_0		000	000	000	"Toll point [Geobase], point"														Excluded			"Ajouter un post-traitement sur type? (-1=unknown, 1-physical toll booth, 2=virtual toll booth, 3=hybrid)"
      #TR_2320009_0		000	000	000	"Turntable, point"																			Excluded			"Aucun post-traitement particulier"
      #VE_1240009_2		700	810	000	"Wooded area, polygon"																Regular			"Ajouter un post-traitement sur type? (1=Extracted, 2=Interpreted, 3=CFS-EOSD, 4=Land Cover Circa 2000 Vector)"
      #VE_2290009_1		000	000	000	"Cut line, line"																					Excluded			"Ajouter un post-traitement sur type? (-1=unknown, 1=firebreak, 2=other)"

	#Liste des entit�s CanVec qui doivent �tre rasteris�es.  
   #Ces entit�s sont class�s par ordre d�croissant de priorit�
   #Note : les entit�s dont le nom commence par pp_ ne sont pas des entit�s originant de CanVec, mais plut�t des cons�quences du post-traitement.
   #Ils sont inclus dans cette liste pour que leurs valeurs de priorit�s apparaisent dans la variable Param(Priorities), afin de faire la
   #correspondance avec les valeurs de TEB et de SMOKE.
   set Param(Entities) {
      SS_1320059_2
      SS_1320029_2
      SS_1320019_2
      FO_1080079_0
      FO_1080069_2
      FO_1080049_2
      HD_1140009_2
      FO_1080059_2
      FO_1080039_2
      pp_HD_1480009_2
      pp_HD_1450009_2
      HD_1450009_2
      LX_1000039_2
      LX_2200009_2
      LX_2560009_2
      LX_2490009_2
      LX_2270009_2
      LX_2260009_2
      pp_HD_1480009_2
      pp_HD_1480009_2
      LX_2480009_2
      IC_1360029_2
      IC_1360019_2
      LX_2500009_2
      LX_2500009_0
      LX_1000089_2
      IC_1350059_2
      IC_1350039_2
      IC_1350029_2
      IC_1350019_2
      IC_1350049_2
      LX_1000049_2
      LX_2400009_2
      pp_HD_1450009_2
      LX_2510009_2
      EN_1360049_2
      IC_2360009_2
      IC_2110009_2
      LX_2070009_2
      HD_1480009_2
      HD_1460009_2
      EN_1360059_2
      VE_1240009_2
      SS_1320049_2
      LX_1000019_2
      BS_2080009_2
      LX_2460009_2
      TR_1190009_2
      pp_HD_1450009_1
      FO_1080029_1
      pp_HD_1450009_1
      pp_HD_1480009_2
      HD_1450009_1
      BS_1370009_2
      IC_1360039_2
      pp_HD_1470009_1
      HD_1470009_1
      HD_1460009_1
      BS_2240009_1
      EN_1180009_1
      BS_2310009_1
      pp_HD_1450009_1
      pp_HD_1470009_1
      TR_1020009_1
      pp_BS_2010009_2
      pp_BS_2010009_2
      BS_2010009_2
      pp_HD_1450009_1
      pp_HD_1450009_1
      LX_1000079_2
      LX_1000079_1
      pp_HD_1470009_1
      LX_1000069_0
      pp_HD_1450009_0
      LX_2420009_1
      EN_2170009_0
      TR_1750009_1
      TR_1760009_1
      LX_2280009_1
      pp_HD_1450009_0
      HD_1460009_0
      pp_TR_1190009_2
      pp_TR_1190009_0
      HD_1450009_0
      pp_HD_1450009_0
      IC_1350039_0
      pp_IC_2600009_0
      IC_2600009_0
      IC_1350049_0
      LX_2220009_0
      LX_1000019_0
      EN_1360049_0
      BS_2000009_0
      LX_2400009_0
      BS_2440009_0
      LX_2480009_0
      LX_2030009_0
      LX_2490009_0
      LX_2070009_0
      LX_1000039_0
      BS_2080009_0
      LX_1000029_0
      IC_1360039_0
      EN_1360059_0
      IC_1360029_0
      TR_1190009_0
      BS_2060009_0
      pp_BS_2060009_0
      pp_BS_2060009_0
      pp_BS_2060009_0
      BS_2530009_0
      pp_BS_2010009_0
      pp_BS_2010009_0
      BS_2010009_0
      }

	#LUT of priority values for the CanVec layers to be processed
	#Les valeurs de priorit� sont en ordre d�croissant, et leur index dans la liste correspond � celui de l'entit� qui leur est associ�e dans Param(Entities)
   set Param(Priorities)           { 999 999 999 999 999 999 991 990 990 970 911 910 890 885 880 875 870 865 861 860 859 858 857 852 852 850 840 823 822 821 820 810 800 795 790 780 775 770 760 740 740 710 700 690 670 665 660 650 645 640 630 610 610 605 600 590 590 580 570 551 550 400 320 310 302 301 300 290 280 271 270 250 244 242 240 230 220 210 200 190 185 181 181 180 170 163 162 161 160 150 140 130 120 110 100 95 90 85 80 70 65 60 60 50 45 40 35 34 33 32 30 22 21 20 }

	# Layers from CanVec ignored for rasterization
   #Aucun tri particulier n�cessaire pour cette liste d'entit�s
   set Param(Excluded) {
      BS_1250009_0
      BS_2120009_0
      BS_2230009_1
      BS_2350009_0
      BS_2380009_0
      BS_2380009_2
      EN_1120009_1
      EN_1340009_0
      FO_1030009_1
      FO_1080019_2
      FO_1080079_0
      FO_1200009_0
      FO_2570009_1
      FO_2610009_0
      HD_1490009_2
      LI_1210009_2
      LX_1000059_0
      LX_1000059_1
      LX_1000059_2
      LX_2210009_0
      SS_1320039_2
      TO_1580009_0
      TO_1580009_1
      TO_1580009_2
      TR_1770009_0
      TR_1780009_0
      TR_1790009_0
      TR_2320009_0
      VE_2290009_1 } 
 
	# Layers from CanVec requiring postprocessing
   #Aucun tri particulier n�cessaire pour cette liste d'entit�s
   set Param(LayersPostPro)    {
      BS_2010009_0
      BS_2010009_2
      BS_2060009_0
      BS_2310009_1
      EN_1180009_1
      HD_1450009_0
      HD_1450009_1
      HD_1450009_2
      HD_1460009_0
      HD_1460009_1
      HD_1460009_2
      HD_1470009_1
      HD_1480009_2
      IC_2600009_0
      TR_1020009_1
      TR_1190009_0
      TR_1190009_2
      TR_1760009_1 } 


   set Param(WaterLayers)      { HD_1480009_2 } ;# Water layers from CanVec

   set Param(BufferLayers)     { BS_2010009_0 TR_1760009_1 } ;# Layers from CanVec required for buffer

   set Param(BufferFuncLayers) { buildin_p buildin_a } ;# Layers from BNDT required for buffer func

   set Param(BufferFuncValues) { 1 2 }

	#TEB Classes for CanVec
   #Ces valeurs sont associ�es aux entit�es CanVec.  Elles doivent �tre dans le m�me ordre que Param(Entities) et Param(Priorities), pour l'association de LUT
   set Param(TEBClasses)         { 840 840 840 820 820 830 902 903 902 830 440 440 520 520 520 520 820 450 440 440 820 440 440 820 820 820 840 830 830 830 830 120 530 410 530 320 410 450 320 830 830 360 810 840 360 410 120 310 440 830 830 440 440 200 400 901 901 830 450 430 430 440 430 340 100 100 120 320 440 330 330 901 110 440 520 420 320 360 440 830 440 440 440 320 830 110 830 830 530 360 110 420 530 140 110 520 520 110 720 410 110 400 360 440 310 420 420 420 420 420 112 111 110 }

	#SMOKE Classes for CanVec
   #Ces valeurs sont associ�es aux entit�es CanVec.  Elles doivent �tre dans le m�me ordre que Param(Entities) et Param(Priorities), pour l'association de LUT
   set Param(SMOKEClasses)       { 0 0 0 0 0 0 0 0 0 1 2 3 0 4 0 0 0 0 5 6 7 8 9 10 11 12 13 14 15 16 17 0 0 18 0 19 20 21 0 22 0 23 0 0 0 0 24 25 26 0 27 28 29 30 31 32 33 0 0 0 0 34 35 0 36 37 38 39 40 41 42 43 44 45 46 0 47 0 0 48 0 49 50 51 52 53 54 55 56 0 0 57 0 0 0 58 59 0 0 0 0 0 60 61 62 63 0 64 65 66 0 67 68 69 }

   #------TO DELETE : LAYERS BNDT------------------
	#set Param(Layers)            { pe_snow_a dry_riv_a embankm_a cut_a so_depo_a dam_a sand_a cemeter_a bo_gard_a zoo_a picnic_a park_sp_a am_park_a campgro_a golf_dr_a golf_co_a peat_cu_a stockya_a mininga_a fort_a ruins_a exhib_g_a oil_fac_a auto_wr_a lu_yard_a slip_a drivein_a water_b_a rock_le_a trans_s_a vegetat_a wetland_a li_depo_a fish_po_a lookout_a tank_a stadium_a runway_a breakwa_l esker_l dyke_le_l seawall_l n_canal_a builtup_a water_c_l ford_l wall_fe_l pipelin_l dam_l haz_air_l conveyo_l conduit_l railway_l pp_buildin_a pp_buildin_a buildin_a wharf_l lock_ga_l pp_sports_t_l pp_sports_t_a sport_t_l sport_t_a so_depo_p n_canal_l haz_air_p marina_p dam_p trail_l wind_de_p crane_l li_road_l pp_road_l pp_road_l road_l bridge_l footbri_l lock_ga_p ford_p pp_seapl_b_p seapl_b_p boat_ra_p pp_mininga_p mininga_p hi_site_p lookout_p oil_fac_p p_anten_p ruins_p silo_p campgro_p camp_p picnic_p drivein_p cemeter_p tank_p ski_cen_p trans_s_p li_depo_p pp_runway_a+p runway_p chimney_p tower_p pp_buildin_p pp_buildin_p buildin_p } ;# NTDB layers to be processed
	#set Param(Priorities)           { 990 970 940 930 920 910 900 890 885 880 875 870 865 860 852 850 840 830 820 810 800 790 780 775 770 765 760 750 740 710 700 690 680 675 670 665 660 650 645 640 630 620 610 605 590 580 570 550 400 350 330 320 310 302 301 300 290 280 271 271 270 270 260 250 248 244 242 240 230 225 220 212 211 210 205 200 190 185 181 180 170 161 160 150 140 130 120 110 100 95 90 85 80 70 65 60 50 45 41 40 35 30 22 21 20 } ;# LUT of priority values for the NTDB layers to be processed   
   #set Param(Excluded)         { a_cable_l barrier_p cave_en_p contour_l crane_p cross_p cut_lin_l dis_str_p disc_pt_p elev_pt_p ferry_r_l haz_nav_p highw_e_p nav_aid_p nts_lim_l oil_fie_p pond_pa_l shrine_p ski_jum_p spring_p toponym_p trans_l_l tunnel_l turntab_p u_reser_p u_reser_a valve_p wat_dis_a wat_dis_l wat_dis_p well_p } ;# Layers from BNDT ignored for rasterization
  #set Param(LayersPostPro)    { mininga_p railway_l road_l runway_a runway_p sport_t_l buildin_p buildin_a } ;# Layers from BNDT requiring postprocessing
	#set Param(WaterLayers)      { water_b_a n_canal_a fish_po_a } ;# Water layers from BNDT
	#set Param(BufferLayers)     { bridge_l buildin_p road_l } ;# Layers from BNDT required for buffer
   #set Param(BufferFuncLayers) { } ;# Layers from CanVec required for buffer func
   #set Param(TEBClasses)         { 902 830 830 830 410 440 903 520 520 520 520 820 450 820 820 820 840 820 830 120 530 530 320 410 450 410 320 901 830 360 810 840 440 901 360 410 120 310 440 830 830 450 901 200 901 830 450 430 440 420 430 430 340 100 100 120 320 440 320 320 330 330 410 901 420 110 440 520 420 420 330 330 310 320 350 360 440 830 901 440 320 110 830 530 360 110 420 530 140 110 520 520 110 520 410 110 360 440 330 310 420 420 112 111 110 }  ;# TEB classes for BNDT
   #------FIN DU : TO DELETE---------

   set Param(VegeFilterType) LOWPASS
   set Param(VegeFilterSize) 99

   #------TO DELETE------------------
   #CE PATH DOIT �TRE MIS � JOUR AVEC LES DONN�ES DE 2006
   #set Param(PopFile) /data/cmoex7/afsralx/canyon-urbain/global_data/statcan/traitements/da2001ca_socio_eco.shp
   #------FIN DU : TO DELETE---------

   #fichier contenant les polygones de dissemination area de StatCan, d�coup�s selon l'index NTS 1:50000 et contenant la population ajust�e aux nouveaux polygones
   set Param(PopFile2006) /data/aqli04/afsulub/StatCan2006/da2006-nts_lcc-nad83.shp

   #fichier contenanant 1 polygone pour chaque province ou territoire du Canada
   set Param(ProvincesGeom) /data/aqli04/afsulub/StatCan2006/Provinces_lcc-nad83.shp

   #fichier contenant l'index NTS � l'�chelle 1:50000
   set Param(NTSFile) /cnfs/ops/production/cmoe/geo/NTS/decoupage50k_2.shp

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::AreaDefine>
# Creation : June 2006 - Alexandre Leroux - CMC/CMOE
#
# Goal     : Define raster coverage based on coverage name
#            Set the lat long bounding box for the city specified at launch
#
# Parameters :
#   <Coverage>   : zone to process {MONTREAL VANCOUVER TORONTO OTTAWA WINNIPEG CALGARY HALIFAX REGINA EDMONTON VICTORIA QUEBEC}
#		   default settings on Quebec
#
# Return:
#
# Remarks : Param(HeightFile) and Param(HeightMaskFile) will need to be removed or updated
#
#----------------------------------------------------------------------------
proc UrbanX::AreaDefine { Coverage } {
   variable Param

# Param(HeightFile) and Param(HeightMaskFile) will need to be removed or updated
   switch $Coverage {
      "VANCOUVER" {
         set Param(Lon1)   -122.50
         set Param(Lat1)    49.40
         set Param(Lon0)   -123.30
         set Param(Lat0)    49.01
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong_wmask
      }
      "MONTREAL" {
         set Param(Lon1)   -73.35
         set Param(Lat1)    45.70
         set Param(Lon0)   -73.98
         set Param(Lat0)    45.30
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/mtl_dnec_-_srtm_utm5m_cropped_wmask
      }
      "TORONTO" {
         set Param(Lon1)   -79.12
         set Param(Lat1)    43.92
         set Param(Lon0)   -79.85
         set Param(Lat0)    43.49
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "OTTAWA" {
         set Param(Lon1)   -75.56
         set Param(Lat1)    45.52
         set Param(Lon0)   -75.87
         set Param(Lat0)    45.30
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott_shp-height.tif
         set Param(Shape)      /data/cmoex7/afsralx/canyon-urbain/global_data/cities/ottawa/ott-buildings.shp
         set Param(ShapeField) hgt
      }
      "WINNIPEG" {
         set Param(Lon1)   -96.95
         set Param(Lat1)    49.98
         set Param(Lon0)   -97.34
         set Param(Lat0)    49.75
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "CALGARY" {
         set Param(Lon1)   -113.90
         set Param(Lat1)    51.18
         set Param(Lon0)   -114.28
         set Param(Lat0)    50.87
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "HALIFAX" {
         set Param(Lon1)   -63.36
         set Param(Lat1)    44.83
         set Param(Lon0)   -63.80
         set Param(Lat0)    44.56
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "REGINA" {
         set Param(Lon1)   -104.50
         set Param(Lat1)    50.54
         set Param(Lon0)   -104.72
         set Param(Lat0)    50.38
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "EDMONTON" {
         set Param(Lon1)   -113.19
         set Param(Lat1)    53.70
         set Param(Lon0)   -113.73
         set Param(Lat0)    53.38
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "VICTORIA" {
         set Param(Lon1)   -123.22
         set Param(Lat1)    48.55
         set Param(Lon0)   -123.54
         set Param(Lat0)    48.39
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "QUEBEC" {
         set Param(Lon1)   -71.10
         set Param(Lat1)    46.94
         set Param(Lon0)   -71.47
         set Param(Lat0)    46.68
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "TEST" {
         set Param(Lon1)   -63.50
         set Param(Lat1)    46.50
         set Param(Lon0)   -64
         set Param(Lat0)    46.25
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
      "IPE" {
         set Param(Lon1)   -61.98
         set Param(Lat1)    47.06
         set Param(Lon0)   -64.42
         set Param(Lat0)    45.94
         set Param(LatCentrale) 46.3
         set Param(LonCentrale) -63.4
         set Param(ProvinceCode) 11 ;# PR code for StatCan
         set Param(ProvincePolygonFile) /data/aqli04/afsulub/StatCan2006/PEI_lcc-nad83.shp
      }
      default {
         set Param(Lon1)   -71.10
         set Param(Lat1)    46.94
         set Param(Lon0)   -71.47
         set Param(Lat0)    46.68
         set Param(HeightFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong ;# TO UPDATE ****
         set Param(HeightMaskFile) /data/cmoex7/afsralx/canyon-urbain/global_data/srtm-dnec/srtm-dnec_van_latlong
      }
   }
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::UTMZoneDefine>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : define the UTM Zone
#
# Parameters :
#   <Lat0>    : Lower left latitude
#   <Lon0>    : Lower left longitude
#   <Lat1>    : Top right latitude
#   <Lon1>    : Top right longitude
#   <Res 5>   : Spatial resolution of rasterization and outputs, leave at 5m unless for testing purposes
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::UTMZoneDefine { Lat0 Lon0 Lat1 Lon1 { Res 5 } indexUTMREF } {
   variable Param

   set zone     [expr int(ceil((180 + (($Lon1 + $Lon0)/2))/6))]
   set meridian [expr -((180-($zone*6))+3)]

		eval georef create UTMREF$indexUTMREF \
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

   set xy1 [georef unproject UTMREF$indexUTMREF $Lat1 $Lon1]
   set xy0 [georef unproject UTMREF$indexUTMREF $Lat0 $Lon0]

   set Param(Width)  [expr int(ceil(([lindex $xy1 0] - [lindex $xy0 0])/$Res))]
   set Param(Height) [expr int(ceil(([lindex $xy1 1] - [lindex $xy0 1])/$Res))]

#	if {$ini == 1} {
		georef define UTMREF$indexUTMREF -transform [list [lindex $xy0 0] $Res 0.000000000000000 [lindex $xy0 1] 0.000000000000000 $Res]
#	}
   
   GenX::Log INFO "UTM zone is $zone, with central meridian at $meridian. Dimension are $Param(Width)x$Param(Height)"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FindNTSSheetsBNDT>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Find the NTS Sheets and paths
#
# Parameters :
#
# Return:
#
# Remarks :  THIS PROC WILL BE DELETED - WON'T BE USED ANYMORE
#
#----------------------------------------------------------------------------
proc UrbanX::FindNTSSheetsBNDT { } {
# THIS PROC WILL BE DELETED - WON'T BE USED ANYMORE
   variable Param
   variable Data

   set missing 0
   set Data(Sheets) {} ;#will contain a list of NTS Sheets, format 999a99
   set Data(Paths)  {} ;#will contain a list of paths, format /data/cmoex7/afsralx/canyon-urbain/global_data/bndt-geonet/999a99
#IS THIS PATH OK?

   set  layers [lindex [ogrfile open SHAPE read $GenX::Path(NTS)/50kindex.shp] 0]
   eval ogrlayer read NTSLAYER $layers

   # Select NTS sheets for the area and consider the buffer distance to account for spatial buffers
   set ids [ogrlayer pick NTSLAYER [list [expr $Param(Lat1)+$Param(Buffer)] [expr $Param(Lon1)+$Param(Buffer)] [expr $Param(Lat1)+$Param(Buffer)] [expr $Param(Lon0)-$Param(Buffer)] [expr $Param(Lat0)-$Param(Buffer)] [expr $Param(Lon0)-$Param(Buffer)] [expr $Param(Lat0)-$Param(Buffer)] [expr $Param(Lon1)+$Param(Buffer)] [expr $Param(Lat1)+$Param(Buffer)] [expr $Param(Lon1)+$Param(Buffer)]] True]
   foreach indexnts $ids {
      set sheet    [string tolower [ogrlayer define NTSLAYER -feature $indexnts snrc]]
      set sheetpath /data/cmoex7/afsralx/canyon-urbain/global_data/bndt-geonet/$sheet
      if { [file exists $sheetpath] } {
         set path [glob -nocomplain $sheetpath/*_nts_lim_l.shp]
         lappend Data(Sheets) [lindex [split [file tail $path] _] 0]
         lappend Data(Paths)  $sheetpath
      } else {
         incr missing
         GenX::Log WARNING "NTS sheet $file missing, results will be incomplete"
      }
   }
   GenX::Log INFO "Total number of NTS Sheets included in the processing: [llength  $Data(Sheets)], NTS Sheets to process: $Data(Sheets)"

   ogrlayer free NTSLAYER
   ogrfile close SHAPE

   if { $missing } {
      GenX::Log INFO WARNING "There are $j NTS sheets missing, results will be incomplete"
      GenX::Continue
   }

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FindNTSSheetsCanVec>
# Creation : August 2010 - Alexandre Leroux - CMC/CMOE
#            August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Find the NTS Sheets that intersect the province polygon
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::FindNTSSheetsCanVec {indexUTMREF } {

	GenX::Log INFO "debut de la proc FindNTSSheetsCanVec"

   variable Param

   #ouverture du shapefile index NTS50K
   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $Param(NTSFile)] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }

   #test � supprimer : comptage du nombre de polygones dans le shapefile (devrait �tre gros +- 20000)
   GenX::Log INFO "On compte [ogrlayer define NTSLAYER50K -nb] tuiles NTS dans le fichier NTS50K"

   #ouverture du shapefile des provinces
   set prov_layer [lindex [ogrfile open SHAPEPROVINCES read $Param(ProvincePolygonFile)] 0]
   eval ogrlayer read VPROVINCE $prov_layer
   ogrlayer stats VPROVINCE -transform UTMREF$indexUTMREF

   #test � supprimer : comptage du nombre de polygones dans le shapefile (devrait �tre 1)
   GenX::Log INFO "On compte [ogrlayer define VPROVINCE -nb] polygones dans le fichier de g�om�trie provinciale"

   #d�finition d'une g�om�trie pour le polygone de province
   set geom [ogrlayer define VPROVINCE -geometry 0]

   #s�lection des fichiers NTS � l'int�rieur de la box de pr�s�lection
   set ntssheets_pre [ogrlayer pick NTSLAYER50K [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   GenX::Log INFO "Les tuiles NTS suivantes sont conserv�es : $ntssheets_pre"

   #ramener l'index � la s�lection des fichiers � l'int�rieur de la box de pr�s�lection
   ogrlayer define NTSLAYER50K -featureselect [list [list index # $ntssheets_pre]]

   #test � supprimer : comptage du nombre de polygones dans la pr�s�lection (devrait �tre 36)
	GenX::Log INFO "On compte [llength $ntssheets_pre] tuiles NTS conserv�es apr�s la pr�s�lection en lat lon"

	#conversion de l'index NTS50K en UTMREF.  ATTENTION: cette conversion doit se faire APR�S la pr�s�lection suivant une bo�te lat/lon, mais AVANT la s�lection avec une g�om�trie UTMREF
   ogrlayer stats NTSLAYER50K -transform UTMREF$indexUTMREF

	#s�lection, parmi les fichiers NTS pr�s�lectionn�s, de ceux qui sont en intersection avec la g�om�trie provinciale
   set Param(NTSSheets) [ogrlayer pick NTSLAYER50K $geom True INTERSECT]
   GenX::Log INFO "Les tuiles NTS suivantes sont conserv�es : $Param(NTSSheets)"

	#test � supprimer : comptage du nombre de polygones conserv�s (devrait �tre 19)
	GenX::Log INFO "On compte [llength $Param(NTSSheets)] tuiles NTS conserv�es suite � l'interesection avec la g�om�trie"

	#nettoyage de m�moire
	ogrfile close SHAPE50K
	ogrfile close SHAPEPROVINCES
	ogrlayer free NTSLAYER50K
	ogrlayer free VPROVINCE

	GenX::Log INFO "fin de la proc FindNTSSheetsCanVec"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::NTSLatLonDefine>
# Creation : August 2010 - Alexandre Leroux - CMC/CMOE
#            August 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     :  Finds the extent (lat lon) of one NTS Sheet
#
# Parameters : NTSid : identifiant d'une tuile NTS50K
#   <NTSid>    : ID of 1 NTS sheet
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::NTSLatLonDefine { NTSid } {

	GenX::Log INFO "debut de la proc NTSLatLonDefine"

   variable Param

   #ouverture du shapefile index NTS50K
   if { ![ogrlayer is NTSLAYER50K] } {
      set nts_layer [lindex [ogrfile open SHAPE50K read $Param(NTSFile)] 0]
      eval ogrlayer read NTSLAYER50K $nts_layer
   }

	#s�lection de la tuile NTS correspondant � l'ID pass� en input
	ogrlayer define NTSLAYER50K -featureselect [list [list index # $NTSid]]

	#NOTE : ON NE TRANSFORME PAS NTSLAYER50K EN UTMREF CAR ON VEUT DES LAT/LON

	#trouve les limites lat/lon de la tuile NTS s�lectionn�e
	set latlon [ogrlayer stats NTSLAYER50K -extent True]

	#affecte les valeurs latlon aux divers param�tres Lon0, Lon1, Lat0, Lat1
	set Param(Lon0) [lindex $latlon 0]
	set Param(Lat0) [lindex $latlon 1]
	set Param(Lon1) [lindex $latlon 2]
	set Param(Lat1) [lindex $latlon 3]

	#nettoyage de m�moire
	ogrfile close SHAPE50K
	ogrlayer free NTSLAYER50K

	GenX::Log INFO "fin de la proc NTSLatLonDefine"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::SandwichBNDT>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Rasterize and flatten all NTDB layers
#
# Parameters :
#
# Return: output genphysx_sandwich.tif
#
# Remarks : THIS PROC WILL BE DELETED.  TO BE REPLACED BY CANVEC DATA
#
#----------------------------------------------------------------------------
proc UrbanX::SandwichBNDT { } {
   variable Param
   variable Data

   GenX::Procs
   GenX::Log INFO "Generating Sandwich"

   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef UTMREF

   #----- V�rification des shapefiles pr�sents afin de ne pas en manquer un hors-liste
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach file [glob -nocomplain -tails -directory $path *.shp] {
         set file [string range [file rootname [file tail $file]] 7 end]
         if { [lsearch -exact $Param(Entities) $file]==-1 && [lsearch -exact $Param(Excluded) $file]==-1 } {
               GenX::Log WARNING "File '${sheet}_$file.shp' has no priority value and won't be processed"
         }
      }
   }

   set j 0

   #----- Rasterization of NTDB layers
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach file $Param(Entities) value $Param(Priorities) {
         if { [file exists $path/${sheet}_$file.shp] } {
            set layer [lindex [ogrfile open SHAPE read $path/${sheet}_$file.shp] 0]
            if { [lsearch -exact Param(LayersPostPro) $file]!=-1 } {
               switch $file {
                  "mininga_p" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- mine souterraine ponctuelle convertie en batiment :
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 2) "
                     GenX::Log INFO "Converting and rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] selected features (underground mines) from ${sheet}_$file.shp to priority value 161"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 161
                  }
                  "railway_l" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (rel_ground != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features (excluding railway bridges and tunnels) from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                  }
                  "runway_a" -
                  "runway_p" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (surface != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- unpaved runway converted to priority 41
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (surface = 2) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved runways) from ${sheet}_$file.shp to priority value 41"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 41
                  }
                  "sport_t_l" -
                  "sport_t_a" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 1) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- paved sports tracks converted to priority 271
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 1) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (paved sports tracks) from ${sheet}_$file.shp to priority value 271"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 271
                  }
                  "seapl_b_p" {
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type != 1) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- seaplane base mouillage converted to priority 181
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (type = 1) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (seaplane base mouillage) from ${sheet}_$file.shp to priority value 181"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 181
                  }
                  "road_l" {
                     #-----rasterize non-bridge and non-tunnel roads (and non-dam)
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (surface roads) as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- unpaved roads converted to priority 212
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) AND (surface = 2) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (unpaved surface roads) from ${sheet}_$file.shp to priority value 212"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 212
                     #----- highways converted to priority 211
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (support != 2) AND (classifica = 1) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (surface highways) from ${sheet}_$file.shp to priority value 211"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 211
                  }
                  "buildin_p" {
                     #----- divide building types: general, industrial-commercial, day-night 24/7
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- industrial-commercial buildings converted to priority 21
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 21"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 21
                     #----- day-night 24/7 buildings converted to priority 22
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (9,12,17,19,26,39,40)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 22"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 22
                  }
                  "buildin_a" {
                     #----- divide building types: general, industrial-commercial, day-night 24/7
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function NOT IN (10,11,14,18,23,31,37)) "
                     GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from file ${sheet}_$file.shp (general buildings) as VFEATURE2KEEP$j with priority value $value"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $value
                     #----- industrial-commercial buildings converted to priority 301
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (11,13,14,16,18,23,27,31,33,35,37)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 301"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 301
                     #----- day-night 24/7 buildings converted to priority 302
                     ogrlayer sqlselect VFEATURE2KEEP$j SHAPE " SELECT * FROM ${sheet}_$file WHERE (function IN (9,12,17,19,26,39,40)) "
                     GenX::Log INFO "Converting [ogrlayer define VFEATURE2KEEP$j -nb] selected features (industrial-commercial buildings) from ${sheet}_$file.shp to priority value 302"
                     gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 302
                  }
                  default {
                     GenX::Log WARNING "Post-processing for $file not found"
                  }
               }
               ogrlayer free VFEATURE2KEEP$j
               incr j
            } else {
               eval ogrlayer read LAYER$j $layer
               GenX::Log INFO "Rasterizing [ogrlayer define LAYER$j -nb] features from file ${sheet}_$file.shp as LAYER$j with priority value $value"
               gdalband gridinterp RSANDWICH LAYER$j $Param(Mode) $value
               ogrlayer free LAYER$j
            }
            ogrfile close SHAPE
         }
      }
   }

   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::SandwichCanVec>
# Creation : July 2010 - Alexandre Leroux - CMC/CMOE
#            July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Finds CanVec Files
#            Rasterize and flatten CanVec layers, either with a general
#            procedure or with some post-processing
#
# Parameters :
#
# Return: output genphysx_sandwich.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::SandwichCanVec { NTSid indexUTMREF } {
   variable Param
   variable Data
#   variable Path

   GenX::Procs
   GenX::Log INFO "Generating Sandwich"

   gdalband create RSANDWICH $Param(Width) $Param(Height) 1 UInt16
   gdalband define RSANDWICH -georef UTMREF$indexUTMREF

   GenX::Log INFO "Locating CanVec Files"

   set Param(Files) {}
   set Param(Files) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Entities)]
   #Param(Files) contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp


   # VEUT-ON REFAIRE CETTE V�RIFICATION ? ELLE SERAIT UTILE - VOIR APRES
   #----- V�rification des shapefiles pr�sents afin de ne pas en manquer un hors-liste
#   foreach sheet $Data(Sheets) path $Data(Paths) {
#      foreach file [glob -nocomplain -tails -directory $path *.shp] {
#         set file [string range [file rootname [file tail $file]] 7 end]
#         if { [lsearch -exact $Param(Entities) $file]==-1 && [lsearch -exact $Param(Excluded) $file]==-1 } {
#               GenX::Log WARNING "File '${sheet}_$file.shp' has no priority value and won't be processed"
#         }
#      }
#   }
# NEW CODE TO FIX
#   foreach file $Param(Files) {
#      set file [string range [file rootname [file tail $file]] 7 end]
#      if { [lsearch -exact $Param(Entities) $file]==-1 && [lsearch -exact $Param(Excluded) $file]==-1 } {
#            GenX::Log WARNING "File '$Param(Files)' has no priority value and won't be processed"
#      }
#   }

   set j 0 ;# Increment of VFEATURE2KEEP$j required to re-use the object

   #----- Rasterization of CanVec layers

   foreach file $Param(Files) {
      set entity [string range [file tail $file] 11 22] ;# strip full file path to keep layer name only
      #entity contains an element of the form AA_9999999_9

      set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
      #filename contains an element of the form 999a99_9_9_AA_9999999_9

      set priority [lindex $Param(Priorities) [lsearch -exact $Param(Entities) $entity]]
      #value contains the nth element of the list Param(Priorities), where n is the index of layer in the list Param(Entities)

      ogrfile open SHAPE read $file
      #read the shapefile and stock it in the object SHAPE

      #the following if/else evaluates if the layer requires some post-processing prior to rasterization or if it is rasterized with the general procedure
      if { [lsearch -exact $Param(LayersPostPro) $entity] !=-1} {
         switch $entity {

            BS_2010009_0 {
               # entity : Building, points
               # function in (11, 16, 23, 27, 37) Pri=21 TEB=111 ; function in (9, 12, 17, 19, 26, 39) PRI= 22 TEB= 112; else general
               GenX::Log INFO "Post-processing for Building, point"
               # function not in (9, 11, 12, 16, 17, 19, 23, 26, 27, 37, 39) : valeur g�n�rale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function NOT IN (9,11,12,16,17,19,23,26,27,37,39)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general buildings) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               # function in (11, 16, 23, 27, 37) : industrial commercial
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function IN (11,16,23,27,37)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (industrial/commercial buildings) as VFEATURE2KEEP$j with priority value 21"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 21
               # function in (9, 12, 17, 19, 26, 39) : day-night 24/7
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function IN (9,12,17,19,26,39)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (day-night 24/7 buildings) as VFEATURE2KEEP$j with priority value 22"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 22
            }
            BS_2010009_2 {
               # entity : Building, polygons
               # function in (11, 16, 23, 27, 37) Pri=301 TEB=100 ; function in (9, 12, 17, 19, 26, 39) PRI=302 TEB=100; else general
               GenX::Log INFO "Post-processing for Building, polygons"
               # function not in (9, 11, 12, 16, 17, 19, 23, 26, 27, 37, 39) : valeur g�n�rale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function NOT IN (9,11,12,16,17,19,23,26,27,37,39)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general buildings) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               # function in (11, 16, 23, 27, 37) : industrial commercial
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function IN (11,16,23,27,37)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (industrial/commercial buildings) as VFEATURE2KEEP$j with priority value 301"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 301
               # function in (9, 12, 17, 19, 26, 39) : day-night 24/7
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE function IN (9,12,17,19,26,39)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (day-night 24/7 buildings) as VFEATURE2KEEP$j with priority value 302"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 302
            }
            BS_2060009_0 {
               #entity : Chimney, points
               #if type=1 (burner) PRI=34 TEB=420; if type=2 (industrial) PRI=33 TEB=420; if type =3 (flare stack) PRI=32 TEB=420; else general value
               #general value for unknown type
               GenX::Log INFO "Post-processing for Chimneys (unknown type), points"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1, 2, 3)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - general) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #type = 1 : burner
               GenX::Log INFO "Post-processing for Chimneys (burners), points"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - burners) as VFEATURE2KEEP$j with priority value 34"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 34
               #type = 2 : industrial
               GenX::Log INFO "Post-processing for Chimneys (industrial), points"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 2)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - industrial) as VFEATURE2KEEP$j with priority value 33"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 33
               #type = 3 : flare stack
               GenX::Log INFO "Post-processing for Chimneys (flare stack), points"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (Chimneys - flare stack) as VFEATURE2KEEP$j with priority value 32"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 32
            }
            BS_2310009_1 {
               #entity : Pipeline (Sewage / liquid waste), line
               #if relation2ground != 1 (aboveground), exclus; else, valeur g�n�rale
               GenX::Log INFO "Post-processing for Pipelines (Sewage / liquid waste), lines"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (aboveground pipeline entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            EN_1180009_1 {
               #entity : Pipelines, lines
               #if relation to ground != 1 (aboveground) exclus; else valeur g�n�rale
               GenX::Log INFO "Post-processing for Pipelines, lines"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (aboveground pipeline entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            HD_1450009_0 {
               # entity : Manmade hydrographic entity [Geobase], point
               # if type!=8 (exclus fish_la), valeur g�n�rale; if type=7, PRI=170, TEB=320 (boat_ra); if type=1, PRI=242, TEB=440 (dam); if type=6, PRI=190, TEB=440 (lock gate)
               GenX::Log INFO "Post-processing for Manmade hydrographic entity, point"
               # type != 8 : valeur g�n�rale (exclusion des fish_ladder)
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type != 8)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general manmade hydrographic entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #type = 7 : boat ramp
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (boat ramps hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 170"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 170
               #type = 1 : dam
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 242"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 242
               #type = 6 : lock gate
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (lock gate hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 190"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 190

            }
            HD_1450009_1 {
               # entity : Manmade hydrographic entity [Geobase], line
               # if type=1 PRI=400 TEB=440 (dam); if type=3 PRI=290 TEB=320 (wharf); if type=4 PRI=645 TEB=440 (breakwa); if type=5 PRI=630 TEB=830 (dyke & seawall); if type=6 PRI=280 TEB=440 (lock gate); else general
               GenX::Log INFO "Post-processing for Manmade hydrographic entity, line"
               # type not in (1, 3, 4, 5, 6) : valeur g�n�rale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,3,4,5,6)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general manmade hydrographic entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #type = 1 : dam
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 400"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 400
               #type = 3 : wharf
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 3)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 290"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 290
               #type = 4 : breakwater
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (breakwater hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 645"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 645
               #type = 5 : dyke / levee
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 5)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dyke/levee hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 630"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 630
               #type = 6 : lock gate
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 6)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 280"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 280
            }
            HD_1450009_2 {
               # entity : Manmade hydrographic entity [Geobase], polygons
               # if type=1, PRi=910 TEB=440 (dam); if type=9 PRI=765 TEB=410 (slip); else general
               GenX::Log INFO "Post-processing for Manmade hydrographic entity, polygons"
               # type not in (1, 9) : valeur g�n�rale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type NOT IN (1,9)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general manmade hydrographic entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #type = 1 : dam
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 910"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 911
               #type = 9 : slip
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 9)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (slip hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value 765"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 765
            }
            HD_1460009_0 {
               # entity : Hydrographic obstacle entity [Geobase], point
               # if type=7, valeur generale
               GenX::Log INFO "Post-processing for Hydrographic obstacle entity, point"
               # type=7, valeur generale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            HD_1460009_1 {
               # entity : Hydrographic obstacle entity [Geobase], line
               # if type=7, valeur generale
               GenX::Log INFO "Post-processing for Hydrographic obstacle entity, line"
               # type=7, valeur generale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 7)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            HD_1460009_2 {
               # entity : Hydrographic obstacle entity [Geobase], polygon
               # if type in (3, 103), valeur g�n�rale
               GenX::Log INFO "Post-processing for Hydrographic obstacle entity, polygon"
               #type in (3, 103) : valeur g�n�rale
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE type IN (3,103)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general hydrographic obstacle entity) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            HD_1470009_1 {
               # entity : Single line watercourse [Geobase], line
               # if def=1 PRI=250 TEB=901; if def=2 PRI=320 TEB=430 ; if def=6 PRI=590 TEB=901; else general
               GenX::Log INFO "Post-processing for Single line watercourse, line"
               #valeur g�n�rale � tout
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general watercourses) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #definition = 1 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (canal watercourses) as VFEATURE2KEEP$j with priority value 250"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 250
               #definition = 2 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 2)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (conduit watercourses) as VFEATURE2KEEP$j with priority value 320"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 320
               #definition = 6 : watercourse
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (canal watercourses) as VFEATURE2KEEP$j with priority value 590"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 590

            }
            HD_1480009_2 {
               # entity : Waterbody [Geobase], polygon
               # if permanency=2 PRI = 970, TEB=830; if waterdef=1 PRI=610 TEB=440; if waterdef=5 PRI=860 TEB=440; if waterdef=8 PRI=860 TEB=440; else general value
               GenX::Log INFO "Post-processing for Waterbody, polygon"
               #valeur g�n�rale � tout
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general waterbodies) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #permanency = 2 : intermittent
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (permanency = 2)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (intermittent waterbodies) as VFEATURE2KEEP$j with priority value 970"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 970
               #definition = 1 : canal
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (canal waterbodies) as VFEATURE2KEEP$j with priority value 610"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 610
               #definition = 5 : reservoir
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 5)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (canal waterbodies) as VFEATURE2KEEP$j with priority value 860"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 860
               #definition = 8 : liquid waste
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (definition = 8)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (liquid waste waterbodies) as VFEATURE2KEEP$j with priority value 860"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 861
            }
            IC_2600009_0 {
               # entity : Mining area, point
               # Si type = 1 (underground), PRI = 161, TEB=110; else general
               GenX::Log INFO "Post-processing for Mining area, point"
               #type != 1 : mines g�n�rales
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type != 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general mines) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #type = 1 : mines underground
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 1)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (underground mines) as VFEATURE2KEEP$j with priority value 162"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 162
            }
            TR_1020009_1 {
               # entity : Railway, line
               # if support != 4, general (exclusion des tunnels)
               GenX::Log INFO "Post-processing for Railway, line"
               #support !=4 : exclusion des tunnels
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (support != 4)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general railway) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
            }
            TR_1190009_0 {
               # entity : Runway, point
               # if type = 4 (sea) PRI = 180 TEB = 440; else general
               GenX::Log INFO "Post-processing for Runway, point"
               #type != 4 : general
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type != 4 )"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general runway) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #type = 4 : sea
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4 )"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general runway) as VFEATURE2KEEP$j with priority value 180"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 180
            }
            TR_1190009_2 {
               # entity : Runway, polygon
               # if type = 4 (sea) PRI = 180 TEB = 440; else general
               GenX::Log INFO "Post-processing for Runway, polygon"
               #type != 4 : general
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type != 4 )"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general runway) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #type = 4 : sea
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (type = 4 )"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general runway) as VFEATURE2KEEP$j with priority value 180"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 180
            }
            TR_1760009_1 {
               # entity : Road segment [Geobase], line
               # if structure type not in (5,6), general; if structure type in (1,2,3,4) PRI=205 TEB=350 (bridge); if structure type = 7, PRI=242, TEB=440 (dam); if pavement status = 2, PRI=212, TEB=320 (unpaved); if class in (1,2), PRI=211 TEB=320 (freeway, highway)
               GenX::Log INFO "Post-processing for Road segment, line"
               #exclusions des structype 5 (tunnel) et 6 (snowshed), association de la valeur g�n�rale � tout le reste
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE structype NOT IN (5,6)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (general road segments) as VFEATURE2KEEP$j with priority value $priority"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) $priority
               #structype in (1,2,3,4) : bridge
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE structype IN (1,2,3,4)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (bridge road segments) as VFEATURE2KEEP$j with priority value 205"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 205
               #structype = 7 : dam
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (structype = 7)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (dam road segments) as VFEATURE2KEEP$j with priority value 242"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 242
               #roadclass in (1,2) : freeway/highway, priority 211
               #ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE roadclass IN (1,2)"
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE roadclass in (1,2)"
#               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (NATRDCLASS == 1,2)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (highways road segments) as VFEATURE2KEEP$j with priority value 201"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 201
               #pavstatus = 2 : unpaved
               ogrlayer sqlselect VFEATURE2KEEP$j SHAPE "SELECT * FROM $filename WHERE (pavstatus = 2)"
               GenX::Log INFO "Rasterizing [ogrlayer define VFEATURE2KEEP$j -nb] features from layer $entity (unpaved road segments) as VFEATURE2KEEP$j with priority value 212"
               gdalband gridinterp RSANDWICH VFEATURE2KEEP$j $Param(Mode) 212
            }
            default {
               #the layer is part of Param(LayersPostPro) but no case has been defined for it
               GenX::Log WARNING "Post-processing for $file not found"
            }
         }
         ogrlayer free VFEATURE2KEEP$j
         incr j ;# Increment of VFEATURE2KEEP$j required to re-use the object
      } else {
         #general procedure for rasterization : entities are not part of Param(LayersPostPro)
         puts "Layer $entity rasterized with general procedure"
         eval ogrlayer read LAYER$j SHAPE 0
         GenX::Log INFO "Rasterizing [ogrlayer define LAYER$j -nb] features from file $file as LAYER$j with priority value $priority"
         gdalband gridinterp RSANDWICH LAYER$j $Param(Mode) $priority
         ogrlayer free LAYER$j
      }
      ogrfile close SHAPE
   }

   #creating the output file
   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich_$NTSid.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RSANDWICH

   GenX::Log INFO "The file $GenX::Param(OutFile)_sandwich_$NTSid.tif was generated"

	GenX::Log INFO "Fin de UrbanX::SandwichCanVec"

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::ScaleBuffersBNDT>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Buffers on selected point and line features
#
# Parameters :
#
# Return: output genphysx_sandwich.tif
#
# Remarks : THIS PROC WILL BE DELETED.  TO BE REPLACED BY CANVEC DATA
#
#----------------------------------------------------------------------------
proc UrbanX::ScaleBuffersBNDT { } {
   variable Param

   if { !$Param(Resolution)<=5 || !$Param(Mode)=="FAST" } {
      return
   }
   GenX::Log INFO "Buffers for scale representation at resolution <= 5m ($Param(BufferLayers))"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband create RBUFFERS $Param(Width) $Param(Height) 1 UInt16
   gdalband define RBUFFERS -georef UTMREF

   set j 0
   foreach sheet $Data(Sheets) {
      foreach layer $Param(BufferLayers) {
         set path [glob -nocomplain $Data(Path$i)${sheet}_$layer.shp]
         if { [file exists $path] } {
            set value [lindex $Param(Priorities) [lsearch -exact $Param(Entities) $layer]]
            set layer2 [lindex [ogrfile open SHAPE read $path] 0]
            eval ogrlayer read LAYER$j $layer2
            # 1m = 0.000008999280057595392 degre

            swicth $layer {
               "buildin_p" {
                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE function != 4 "
                  ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
                  GenX::Log INFO "Buffering point buildings (except Cabine) to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value
               }
               "road_l" {
                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE (support != 2) AND (surface != 2) "
                  ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
                  GenX::Log INFO "Buffering surface paved roads to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value
                  ogrlayer free LAYER$j ;# CES TROIS PROCHAINES LIGNES SONT-ELLES N�CESSAIRES ??
                  incr j
                  eval ogrlayer read LAYER$j $layer2
                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE (support != 2) AND (classifica = 1) "
                  ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
                  GenX::Log INFO "Buffering surface highways to 22m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value 211"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) 211
               }
               "bridge_l" {
   #puts stderr 777
                  #ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer " #; that one was already commented
   # La prochaine ligne ne devrait pas �tre comment�... � mettre � jour en janvier avec le nouveau GEOS et GDAL
   #               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2, comme pour les routes
   #puts stderr 888

                  GenX::Log INFO "Buffering point bridges to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value
               }
               default {
                  GenX::Log WARNING "Buffer processing for $layer not found"
               }
            }
            ogrlayer free LAYER$j
            ogrfile close SHAPE
            incr j
         }
      }
   }
   GenX::Log INFO "Overwriting sandwich with scale representation buffers ($Param(BufferLayers))"

   vector create VCALCU
   vector set VCALCU { 0 605 610 690 700 750 870 } ;#these are priority values which may be overwritten by the buffer
   vexpr RSANDWICH ifelse(((in(RSANDWICH, VCALCU) || RSANDWICH>=920) && RBUFFERS!=0),RBUFFERS,RSANDWICH)

   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RBUFFERS RSANDWICH
   gdalfile close FSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::ScaleBuffersCanVec>
# Creation : July 2010 - Alexandre Leroux - CMC/CMOE
#            July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : This proc loads the tif file generated after the sandwichCanVec proc,
#            applies buffer on specific point and line features, and overwrites the
#            sandwich tif file.
#
# Parameters :
#
# Return: output genphysx_sandwich.tif
#
# Remarks : BUG on the buffer generation due to GEOS 3.2.2.  Should be fixed
#           with 3.3.0
#
#----------------------------------------------------------------------------
# Buffers on selected point and line features
proc UrbanX::ScaleBuffersCanVec {indexUTMREF } {

puts "D�but de la proc ScaleBuffersCanVec"

   variable Param

   if { $Param(Resolution)>5 || $Param(Mode)!="FAST" } {
      puts "Pas de ScaleBuffer: resolution = $Param(Resolution), mode = $Param(Mode)"
      return
   }

   GenX::Log INFO "Buffers for scale representation at resolution <= 5m ($Param(BufferLayers))"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband create RBUFFERS $Param(Width) $Param(Height) 1 UInt16
   gdalband define RBUFFERS -georef UTMREF$indexUTMREF

   set j 0
   set Param(FilesScaleBuffer) {}
   set Param(FilesScaleBuffer) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(BufferLayers)]
   #Param(Files) contains a list of elements of the form /cnfs/ops/production/cmoe/geo/CanVec/999/a/999a99/999a99_1_0_AA_9999999_0.shp

   foreach file $Param(FilesScaleBuffer) {
      set entity [string range [file tail $file] 11 22] ;# strip full file path to keep layer name only
      #entity contains an element of the form AA_9999999_9
      puts $entity
      set filename [string range [file tail $file] 0 22] ;# required by ogrlayer sqlselect
      #filename contains an element of the form 999a99_9_9_AA_9999999_9
      puts $filename
      set priority [lindex $Param(Priorities) [lsearch -exact $Param(Entities) $entity]]
      #value contains the nth element of the list Param(Priorities), where n is the index of layer in the list Param(Entities)
      puts $priority
      ogrfile open SHAPE read $file
      #read the shapefile and stock it in the object SHAPE
      #the following if/else evaluates if the layer requires some post-processing prior to rasterization or if it is rasterized with the general procedure

      if { [lsearch -exact $Param(BufferLayers) $entity] !=-1} {
         switch $entity {
            BS_2010009_0 {
            #bla
            puts "Scalebuffer pour b�timents"
               ogrlayer sqlselect LAYER$j SHAPE "SELECT * FROM $filename" ;#la fonction cabin n'existe plus, donc pas d'exclusion
               puts "�a bogue ici pour cause de segmentation fault sur ogrlayer stats LAYER -buffer"
#               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
               #effectue un buffer autour du point, d'un rayon de 6 m�tres.  Le point occupera donc au minimum 3 pixels X 3 pixels
               GenX::Log INFO "Buffering all point buildings to 12m: [ogrlayer define LAYER$j -nb] features from $filename as LAYER$j with buffer value $priority"
               gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $priority

               #NOTE : PROBL�ME REP�R� :
               #LA PROC INITIALE FAIT LE BUFFER SUR UNE SEULE VALEUR DE PRIORIT�.  OR, LE LAYER A �T� DIVIS� EN 3 �L�MENTS DANS LA SANDWICH, ET CES 3 �L�MENTS
               #ONT DES VALEURS DE PRIORIT� DIFF�RENTES.  IL FAUT DONC REPRENDRE LA DIVISION EFFECTU�E DANS LA SANDWICH POUR EFFECTUER UN BUFFER AVEC LES
               #BONNES VALEURS

            }
            TR_1760009_1 {
            #BLA
            puts "Scalebuffer pour routes"

#                 #ROUTES
#                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE (support != 2) AND (surface != 2) "
#                  ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2
#                  GenX::Log INFO "Buffering surface paved roads to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
#                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value
#                  ogrlayer free LAYER$j ;# CES TROIS PROCHAINES LIGNES SONT-ELLES N�CESSAIRES ??
#                  incr j
#                  eval ogrlayer read LAYER$j $layer2
#                  ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer WHERE (support != 2) AND (classifica = 1) "
#                  ogrlayer stats LAYER$j -buffer 0.0000989921 8 ;# 11m x 2
#                  GenX::Log INFO "Buffering surface highways to 22m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value 211"
#                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) 211
#                 #BRIDGES
#   #puts stderr 777
#                  #ogrlayer sqlselect LAYER$j SHAPE " SELECT * FROM ${sheet}_$layer " #; that one was already commented
#   # La prochaine ligne ne devrait pas �tre comment�... � mettre � jour en janvier avec le nouveau GEOS et GDAL
#   #               ogrlayer stats LAYER$j -buffer 0.0000539957 8 ;# 6m x 2, comme pour les routes
#   #puts stderr 888

#                  GenX::Log INFO "Buffering point bridges to 12m: [ogrlayer define LAYER$j -nb] features from ${sheet}_$layer.shp as LAYER$j with buffer value $value"
#                  gdalband gridinterp RBUFFERS LAYER$j $Param(Mode) $value

            }
            default {
               GenX::Log WARNING "Buffer processing for $layer not found"
            }
         }
         ogrlayer free LAYER$j
         incr j
      }
      ogrfile close SHAPE
   }




   GenX::Log INFO "Overwriting sandwich with scale representation buffers ($Param(BufferLayers))"

   vector create VCALCU
   vector set VCALCU { 0 605 610 690 700 750 870 } ;#these are priority values which may be overwritten by the buffer
   vexpr RSANDWICH ifelse(((in(RSANDWICH, VCALCU) || RSANDWICH>=920) && RBUFFERS!=0),RBUFFERS,RSANDWICH)

   file delete -force $GenX::Param(OutFile)_sandwich.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_sandwich.tif GeoTiff
   gdalband write RSANDWICH FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RBUFFERS RSANDWICH
   gdalfile close FSANDWICH

puts "Fin de la proc ScaleBuffersCanVec"

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::ChampsBuffers>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Create the fields and building vicinity output using spatial buffers
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::ChampsBuffers {indexUTMREF } {
   variable Param
   variable Data

   GenX::Log INFO "Buffer zone processing for grass and fields identification"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]

   gdalband create RBUFFER $Param(Width) $Param(Height) 1 Byte
   eval gdalband define RBUFFER -georef UTMREF$indexUTMREF
   set i 0
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach layer $Param(BufferFuncLayers) value $Param(BufferFuncValues) {
         set path [glob -nocomplain $path/${sheet}_$layer.shp]
         if { [file exists $path] } {
            set layer2 [lindex [ogrfile open SHAPE read $path] 0]
            eval ogrlayer read LAYER$i $layer2
            if  { $layer=="buildin_a" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM ${sheet}_$layer WHERE function NOT IN (3,4,14,36) "
#               ogrlayer stats LAYER$i -buffer 0.00089993 8
            } elseif  { $layer=="buildin_p" }  {
               ogrlayer sqlselect LAYER$i SHAPE " SELECT * FROM ${sheet}_$layer WHERE function NOT IN (3,4,14,36) "
#               ogrlayer stats LAYER$i -buffer 0.000224982 8
            }
            GenX::Log INFO "Buffering [ogrlayer define LAYER$i -nb] features from ${sheet}_$layer.shp as LAYER$i with buffer value $value"
            gdalband gridinterp RBUFFER LAYER$i $Param(Mode) $value
            ogrlayer free LAYER$i
            ogrfile close SHAPE
         }
      }
      incr i
   }
   GenX::Log INFO "Cookie cutting grass and fields buffers and setting grass and fields and building vicinity values"
   gdalband create RBUFFERCUT $Param(Width) $Param(Height) 1 UInt16
   gdalband define RBUFFERCUT -georef UTMREF$indexUTMREF
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER==0)),820,RBUFFERCUT)
   vexpr RBUFFERCUT ifelse(((RSANDWICH==0) && (RBUFFER!=0)),510,RBUFFERCUT)

   #----- On sauvegarde le tout - Next 5 lines are commented since writing results to file is unrequired
   #file delete -force $GenX::Param(OutFile)_champs_buf100ma+25mp.tif
   #gdalfile open FILEOUT write $GenX::Param(OutFile)_champs_buf100ma+25mp.tif GeoTiff
   #gdalband write RBUFFER FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   #gdalfile close FILEOUT
   gdalband free RBUFFER
   gdalband free RSANDWICH
   gdalfile close FSANDWICH

   file delete -force $GenX::Param(OutFile)_champs-only+building-vicinity.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_champs-only+building-vicinity.tif GeoTiff
   gdalband write RBUFFERCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RBUFFERCUT
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::PopDens2BuiltupBNDT>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#
# Return: output file genphysx_popdens-builtup.tif
#
# Remarks : THIS PROC WILL BE DELETED.  TO BE REPLACED BY CANVEC DATA
#
#----------------------------------------------------------------------------
proc UrbanX::PopDens2BuiltupBNDT { } {
   variable Param
   variable Data

   GenX::Log INFO "Processing population density"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   set layer [lindex [ogrfile open SHAPE read $Param(PopFile)] 0]
   eval ogrlayer read VPOPDENS $layer

   #----- Selecting only the required polygons - next is only useful to improve the speed of the layer substraction
   set features [ogrlayer pick VPOPDENS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   ogrlayer define VPOPDENS -featureselect [list [list index # $features]]

   GenX::Log INFO "Cropping population shapefile and substracting water ($Param(WaterLayers))"

   #----- Both layers must have the same projection!
   foreach sheet $Data(Sheets) path $Data(Paths) {
      foreach layer $Param(WaterLayers) {
         set path [glob -nocomplain $path/${sheet}_$layer.shp]
         if { [file exists $path] } {
            set water_layer [lindex [ogrfile open SHAPE2 read $path] 0]
            eval ogrlayer read VWATER $water_layer
            ogrlayer stats VPOPDENS -difference VWATER
            ogrfile close SHAPE2
            ogrlayer free VWATER
         }
      }
   }

   GenX::Log INFO "Calculating population density values"
   ogrlayer stats VPOPDENS -transform UTMREF
   foreach n $features {
      set pop  [ogrlayer define VPOPDENS -feature $n TOTPOPUL]
      set geom [ogrlayer define VPOPDENS -geometry $n]
      #ogrgeometry stats $geom -transform UTMREF
      set area  [expr ([ogrgeometry stats $geom -area]/1000000.0)]
      ogrlayer define VPOPDENS -feature $n POP_DENS [expr $area==0.0?0.0:($pop/$area)]
      if {[expr $area==0.0?0.0:($pop/$area)] > 10000000 || [expr $area==0.0?0.0:($pop/$area)] < 0 } {
         set dens [expr $area==0.0?0.0:($pop/$area)]
         GenX::Log WARNING "Potential problem n=$n, pop=$pop, area=$area, dens=$dens"
      }
   }
   unset features

   gdalband create RPOPDENS $Param(Width) $Param(Height) 1 Float32
   eval gdalband define RPOPDENS -georef UTMREF
   gdalband gridinterp RPOPDENS VPOPDENS $Param(Mode) POP_DENS

   file delete -force $GenX::Param(OutFile)_popdens.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens.tif GeoTiff
   gdalband write RPOPDENS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   ogrlayer free VPOPDENS
   ogrfile close SHAPE

   #file delete -force $GenX::Param(OutFile)_popdens.shp
   #ogrfile open VPOPDENSFILE write $GenX::Param(OutFile)_popdens.shp "ESRI Shapefile"
   #ogrlayer write VPOPDENS VPOPDENSFILE
   #ogrfile close VPOPDENSFILE

   GenX::Log INFO "Cookie cutting population density and setting TEB values"
   gdalband create RPOPDENSCUT $Param(Width) $Param(Height) 1 Byte
   gdalband define RPOPDENSCUT -georef UTMREF
   vexpr RTEMP RSANDWICH==605
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<2000),210,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=2000 && RPOPDENS<5000)),220,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=5000 && RPOPDENS<15000),230,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=15000 && RPOPDENS<25000),240,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=25000),250,RPOPDENSCUT)

   gdalband free RSANDWICH ;# move this above once vexpr works
   gdalfile close FSANDWICH
   gdalband free RPOPDENS
   gdalband free RTEMP

   file delete -force $GenX::Param(OutFile)_popdens-builtup.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens-builtup.tif GeoTiff
   gdalband write RPOPDENSCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RPOPDENSCUT
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::PopDens2BuiltupCanVec>
# Creation : July 2010 - Alexandre Leroux - CMC/CMOE
#            July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Reclassify the builtup areas with several thresholds related
#            to population density
#
# Parameters :
#
# Return: output files :
#             genphysx_popdens.tif
#             genphysx_popdens-builtup.tif
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::PopDens2BuiltupCanVec {NTSid indexUTMREF } {

	GenX::Log INFO "D�but de la proc PopDens2BuiltupCanVec"

   variable Param
   variable Data

   #r�cup�ration de genphysx_sandwich.tif
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$NTSid.tif]

   #r�cup�ration du fichier de donn�es socio-�conomiques
   #set layer [lindex [ogrfile open SHAPE read $Param(PopFile)] 0]
   set layer [lindex [ogrfile open SHAPE read $Param(PopFile2006)] 0]
   eval ogrlayer read VPOPDENS $layer

   #----- Selecting only the required polygons - next is only useful to improve the speed of the layer substraction
   set features [ogrlayer pick VPOPDENS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   ogrlayer define VPOPDENS -featureselect [list [list index # $features]]

   #Subtraction of water zone from VPOPDENS
   GenX::Log INFO "Cropping population shapefile and substracting water ($Param(WaterLayers))"
   set Param(FilesWater) {}
   set Param(FilesWater) [GenX::CANVECFindFiles $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(WaterLayers)]
   foreach file $Param(FilesWater) {
      GenX::Log INFO "Substracting water file $file"
      set water_layer [lindex [ogrfile open SHAPE2 read $file] 0]
      eval ogrlayer read VWATER $water_layer
      ogrlayer stats VPOPDENS -difference VWATER
      ogrfile close SHAPE2
      ogrlayer free VWATER
   }

   #Calcul de la densit� de population
   GenX::Log INFO "Calculating population density values"
   ogrlayer stats VPOPDENS -transform UTMREF$indexUTMREF
   foreach n $features {
      #set pop  [ogrlayer define VPOPDENS -feature $n TOTPOPUL]
      set pop  [ogrlayer define VPOPDENS -feature $n POP_NEW]
      set geom [ogrlayer define VPOPDENS -geometry $n]
      #ogrgeometry stats $geom -transform UTMREF
      set area  [expr ([ogrgeometry stats $geom -area]/1000000.0)]
      ogrlayer define VPOPDENS -feature $n POP_DENS [expr $area==0.0?0.0:($pop/$area)]
      if {[expr $area==0.0?0.0:($pop/$area)] > 10000000 || [expr $area==0.0?0.0:($pop/$area)] < 0 } {
         set dens [expr $area==0.0?0.0:($pop/$area)]
         GenX::Log WARNING "Potential problem n=$n, pop=$pop, area=$area, dens=$dens"
      }
   }
   unset features

   #Conversion de la densit� de population en raster
   gdalband create RPOPDENS $Param(Width) $Param(Height) 1 Float32
   eval gdalband define RPOPDENS -georef UTMREF$indexUTMREF
   gdalband gridinterp RPOPDENS VPOPDENS $Param(Mode) POP_DENS

   #�criture du fichier genphysx_popdens.tif contenant la densit� de population
   file delete -force $GenX::Param(OutFile)_popdens.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens_$NTSid.tif GeoTiff
   gdalband write RPOPDENS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   ogrlayer free VPOPDENS
   ogrfile close SHAPE
   GenX::Log INFO "The file $GenX::Param(OutFile)_popdens_$NTSid.tif was generated"

   #Cookie cutting population density and setting TEB values
   GenX::Log INFO "Cookie cutting population density and setting TEB values"
   gdalband create RPOPDENSCUT $Param(Width) $Param(Height) 1 Byte
   gdalband define RPOPDENSCUT -georef UTMREF$indexUTMREF
   vexpr RTEMP RSANDWICH==605
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS<2000),210,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && (RPOPDENS>=2000 && RPOPDENS<5000)),220,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=5000 && RPOPDENS<15000),230,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=15000 && RPOPDENS<25000),240,RPOPDENSCUT)
   vexpr RPOPDENSCUT ifelse((RTEMP && RPOPDENS>=25000),250,RPOPDENSCUT)

   gdalband free RSANDWICH ;# move this above once vexpr works
   gdalfile close FSANDWICH
   gdalband free RPOPDENS
   gdalband free RTEMP

   #�criture du fichier genphysx_popdens-builtup.tif
   file delete -force $GenX::Param(OutFile)_popdens-builtup.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_popdens-builtup_$NTSid.tif GeoTiff
   gdalband write RPOPDENSCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RPOPDENSCUT
   GenX::Log INFO "The file $GenX::Param(OutFile)_popdens-builtup_$NTSid.tif was generated"

   GenX::Log INFO "Fin de la proc PopDens2BuiltupCanVec"

}

#----------------------------------------------------------------------------
# Name     : <UrbanX::HeightGain>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Estimate DEM Height gain based on...
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::HeightGain { } {
   variable Param

   GenX::Log INFO "Evaluating height gain"

   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband create RHAUTEURPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURPROJ -georef UTMREF$indexUTMREF

   #----- La v�rification pourrait �tre fait dans un proc avec v�rification des 4 points de la source
   gdalband read RHAUTEUR [gdalfile open FHAUTEUR read $Param(HeightFile)]
   gdalband stats RHAUTEURPROJ -nodata -9999
   gdalband gridinterp RHAUTEURPROJ RHAUTEUR
   gdalband free RHAUTEUR
   gdalfile close FHAUTEUR

   set min [gdalband stats RHAUTEURPROJ -min]
   if { [lindex $min 0] == -9999 } {
      GenX::Log WARNING "Heights does not overlap entirely the area, average won't be good, absent values will be set to 0"
      vexpr RHAUTEURPROJ ifelse(RHAUTEURPROJ==-9999,0,RHAUTEURPROJ)
   }
   vexpr RHEIGHTCHAMPS ifelse(RCHAMPS==820,RHAUTEURPROJ,0)

   #----- Average est calcul� (pour le moment) que pour les valeurs != 0 dans le code en C
   #      Pour avec les 0: set Param(HeightGain) [vexpr XX savg(RHEIGHTCHAMPS)]
   gdalband stats RHEIGHTCHAMPS -nodata 0
   set Param(HeightGain) [gdalband stats RHEIGHTCHAMPS -avg]

   GenX::Log INFO "Average gain calculated over defined areas = $Param(HeightGain)"
   if {($Param(HeightGain)>=10 || $Param(HeightGain)<=-10) || $Param(HeightGain)==0 } {
      GenX::Log WARNING "Strange value for Param(HeightGain): $Param(HeightGain)"
   }

   file delete -force $GenX::Param(OutFile)_hauteur-champs.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-champs.tif GeoTiff
   gdalband write RHEIGHTCHAMPS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT

   gdalband free RCHAMPS RHEIGHTCHAMPS RHAUTEURPROJ
   gdalfile close FCHAMPS
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::BuildingHeight>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::BuildingHeight {indexUTMREF } {
   variable Param

   GenX::Log INFO "Cookie cutting building heights and adding gain"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RHAUTEURWMASK [gdalfile open FHAUTEUR read $Param(HeightMaskFile)]

   gdalband create RHAUTEURWMASKPROJ $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURWMASKPROJ -georef UTMREF$indexUTMREF

   gdalband gridinterp RHAUTEURWMASKPROJ RHAUTEURWMASK
   gdalband free RHAUTEURWMASK
   gdalfile close FHAUTEUR
   vexpr RHAUTEURWMASKPROJ RHAUTEURWMASKPROJ+$Param(HeightGain)

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM { 300 600 810 302 301 }
   vector set LUT.TO   { 120 120 120 122 121 }
   vexpr RHAUTEURCLASS lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector set LUT.FROM { 300 600 810 605 302 301 }
   vector set LUT.TO   { 130 130 130 135 132 131 }
   vexpr RHAUTEURCLASS ifelse(RHAUTEURWMASKPROJ>=10,lut(RSANDWICH,LUT.FROM,LUT.TO),RHAUTEURCLASS)
   vector set LUT.TO   { 140 140 140 145 142 141 }
   vexpr RHAUTEURCLASS ifelse(RHAUTEURWMASKPROJ>=20,lut(RSANDWICH,LUT.FROM,LUT.TO),RHAUTEURCLASS)
   vector set LUT.TO   { 150 150 150 155 152 151 }
   vexpr RHAUTEURCLASS ifelse(RHAUTEURWMASKPROJ>=30,lut(RSANDWICH,LUT.FROM,LUT.TO),RHAUTEURCLASS)
   gdalband free RHAUTEURWMASKPROJ
   vector free LUT

#   file delete -force $GenX::Param(OutFile)_hauteur-builtup+building.tif
#   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-builtup+building.tif GeoTiff
#   gdalband write RHAUTEURCUT FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
#   gdalfile close FILEOUT
   file delete -force $GenX::Param(OutFile)_hauteur-classes.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_hauteur-classes.tif GeoTiff
   gdalband write RHAUTEURCLASS FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalfile close FSANDWICH
   gdalband free RHAUTEURCLASS RSANDWICH
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Priorities2TEB>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Applies LUT to all processing results to generate TEB classes
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Priorities2TEB { } {
   variable Param

   GenX::Log INFO "Converting values to TEB classes"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup.tif]
   gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(OutFile)_hauteur-classes.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Priorities)
   vector set LUT.TO $Param(TEBClasses)
   vexpr RTEB lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   vexpr RTEB ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RTEB)
   vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
   vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB.tif GeoTiff
   gdalband write RTEB FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   gdalfile close FILEOUT
   gdalfile close FSANDWICH
   gdalfile close FPOPDENSCUT
   gdalfile close FCHAMPS
   gdalfile close FHAUTEURCLASS
   gdalband free RTEB RSANDWICH RPOPDENSCUT RCHAMPS RHAUTEURCLASS
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Priorities2SMOKE>
# Creation : July 2010 - Alexandre Leroux - CMC/CMOE
#            July 2010 - Lucie Boucher - CMC/AQMAS
#
# Goal     : Applies LUT to all processing results to generate SMOKE classes
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Priorities2SMOKE {NTSid } {
   GenX::Log INFO "D�but de la proc Priorities2SMOKE"

   variable Param

   GenX::Log INFO "Converting values to SMOKE classes"

   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich_$NTSid.tif]
   gdalband read RPOPDENSCUT [gdalfile open FPOPDENSCUT read $GenX::Param(OutFile)_popdens-builtup_$NTSid.tif]
  #gdalband read RCHAMPS [gdalfile open FCHAMPS read $GenX::Param(OutFile)_champs-only+building-vicinity.tif]
   #gdalband read RHAUTEURCLASS [gdalfile open FHAUTEURCLASS read $GenX::Param(OutFile)_hauteur-classes.tif]

   vector create LUT
   vector dim LUT { FROM TO }
   vector set LUT.FROM $Param(Priorities)
   vector set LUT.TO $Param(SMOKEClasses)
   vexpr RSMOKE lut(RSANDWICH,LUT.FROM,LUT.TO)
   vector free LUT

   vexpr RSMOKE ifelse(RPOPDENSCUT!=0,RPOPDENSCUT,RSMOKE)
   #vexpr RTEB ifelse(RHAUTEURCLASS!=0,RHAUTEURCLASS,RTEB)
   #vexpr RTEB ifelse(RCHAMPS!=0,RCHAMPS,RSMOKE)

   file delete -force $GenX::Param(OutFile)_SMOKE.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_SMOKE_$NTSid.tif GeoTiff
   gdalband write RSMOKE FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }

   GenX::Log INFO "The file $GenX::Param(OutFile)_SMOKE_$NTSid.tif was generated"

   gdalfile close FILEOUT
   gdalfile close FSANDWICH
   gdalfile close FPOPDENSCUT
   #gdalfile close FCHAMPS
   #gdalfile close FHAUTEURCLASS
   gdalband free RSMOKE RSANDWICH RPOPDENSCUT ;# RCHAMPS RHAUTEURCLASS

   GenX::Log INFO "Fin de la proc Priorities2SMOKE"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::VegeMask>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     : Generate and apply vegetation mask
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::VegeMask { } {
   variable Param

   GenX::Log INFO "Generating vegetation mask"

   gdalband read RTEB [gdalfile open FTEB read $GenX::Param(OutFile)_TEB.tif]

   vexpr RTEBWMASK ifelse(RTEB>800,100,0)

   set fileRTEBfilter $GenX::Param(OutFile)_vegemask-$Param(VegeFilterType)$Param(VegeFilterSize).tif

   if { ![file exists $fileRTEBfilter] } {
      if { $Param(VegeFilterSize) > 20 } {
         GenX::Log INFO "Generating this $Param(VegeFilterType)$Param(VegeFilterSize) vegetation mask may require hours to process"
      }
      vector create FILTER [UrbanX::FilterGen $Param(VegeFilterType) $Param(VegeFilterSize)]
      #----- Le nodata sert � simuler l'application d'un mask au filtre qui suit
      vexpr RTEBWMASK ifelse(RTEB==901,901,RTEBWMASK)
      gdalband stats RTEBWMASK -nodata 901
      vexpr VEGEMASK fkernel(RTEBWMASK,FILTER)
#      vexpr VEGEMASK fcentile(RTEBWMASK,3,0.5) ;# fcentile is fmedian, fmax, fmin � la fois

      file delete -force $fileRTEBfilter
      gdalfile open FILEOUT write $fileRTEBfilter GeoTiff
      gdalband write VEGEMASK FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
      gdalfile close FILEOUT
   } else {
      GenX::Log INFO "Using previously computed filtered data $fileRTEBfilter"
      gdalband read VEGEMASK [gdalfile open FVEGEMASK read ./$fileRTEBfilter]
   }

   #----- Seuil sur le filtre et rajout des non-nature et de l'eau
   vexpr RTEBWMASK ifelse((VEGEMASK>85 && RTEB>800 && RTEB!=901),0,RTEB)

   file delete -force $GenX::Param(OutFile)_TEB-wVegeMask.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_TEB-wVegeMask.tif GeoTiff
   gdalband write RTEBWMASK FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT

   gdalband free RTEBWMASK VEGEMASK
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::CreateFSTDBand>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#   <Name>   :
#   <Band>   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::CreateFSTDBand { Name Band } {

   set NI [gdalband configure $Band -width]  ; # Number of X-grid points.
   set NJ [gdalband configure $Band -height] ; # Number of Y-grid points.
   set NK 1                                  ; # Number of Z-grid points.

   #----- Create and define tictic and tactac grid coordinates.
   fstdfield create TIC $NI 1 1
   fstdfield create TAC 1 $NJ 1
   fstdfield define TIC -GRTYP L 0 0 1.0 1.0
   fstdfield define TAC -GRTYP L 0 0 1.0 1.0
   fstdfield define TIC -DEET 0 -NPAS 0 -IP1 0 -IP2 0 -IP3 0 -ETIKET $Name -NOMVAR ">>"  -TYPVAR X
   fstdfield define TAC -DEET 0 -NPAS 0 -IP1 0 -IP2 0 -IP3 0 -ETIKET $Name -NOMVAR "^^"  -TYPVAR X
   fstdfield configure TIC -interpdegree NEAREST
   fstdfield configure TAC -interpdegree NEAREST

   #----- Compute tictic grid coordinates.
   for { set i 0 } { $i < $NI } { incr i } {
      set ll [gdalband stats $Band -gridpoint $i 0]
      set lon [lindex $ll 1]
      set lon [expr $lon<0?$lon+360:$lon]
      fstdfield stats TIC -gridvalue $i 0 $lon
   }

   #----- Compute tactac grid coordinates.
   for { set j 0 } { $j< $NJ } { incr j } {
      set ll [gdalband stats $Band -gridpoint 0 $j ]
      fstdfield stats TAC -gridvalue 0 $j [lindex $ll 0]
   }

   fstdfield create $Name $NI $NJ $NK Int32
   fstdfield define $Name -DEET 0 -NPAS 0 -IP1 0 -IP2 0 -IP3 0 -ETIKET $Name -NOMVAR GRID -TYPVAR X -IG1 0 -IG2 0 -IG3 0 -IG4 0 -GRTYP Z
   fstdfield define $Name -positional TIC TAC
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::TEB2FSTD>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#
# Return:
#
# Remarks : Can't work with files over 128 MEGS (e.g. MTL, VAN, TOR)
#
#----------------------------------------------------------------------------
proc UrbanX::TEB2FSTD { } {

   GenX::Log INFO "Converting TEB raster to RPN"

   gdalband read BAND [gdalfile open FILE read $GenX::Param(OutFile)_TEB.tif]

   UrbanX::CreateFSTDBand GRID BAND

   file delete -force $GenX::Param(OutFile)_TEB.fstd
   fstdfile open 1 write $GenX::Param(OutFile)_TEB.fstd

   fstdfield gridinterp GRID BAND
   fstdfield define GRID -NOMVAR UG
   fstdfield write TIC 1 -32 True
   fstdfield write TAC 1 -32 True
   fstdfield write GRID 1 -16 True

   fstdfile close 1
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Shp2Height>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Shp2Height { } {
   variable Param

   if { $Param(Shape)=="" } {
      return
   }
   GenX::Log INFO "Converting $GenX::Param(Urban) building shapefile to raster"

   gdalband create RHAUTEURSHP $Param(Width) $Param(Height) 1 Float32
   gdalband define RHAUTEURSHP -georef UTMREF$indexUTMREF

   set shp_layer [lindex [ogrfile open SHAPE read $Param(Shape)] 0]
   eval ogrlayer read LAYER $shp_layer
   gdalband gridinterp RHAUTEURSHP LAYER $Param(Mode) $Param(ShapeField)

   ogrlayer free LAYER
   ogrfile close SHAPE

   file delete -force $GenX::Param(OutFile)_shp-height.tif
   gdalfile open FILEOUT write $GenX::Param(OutFile)_shp-height.tif GeoTiff
   gdalband write RHAUTEURSHP FILEOUT { COMPRESS=NONE PROFILE=GeoTIFF }
   gdalfile close FILEOUT
   gdalband free RHAUTEURSHP
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::FilterGen>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#   <Type>   :
#   <Size>   :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::FilterGen { Type Size } {

   #----- Est-ce cette proc maintenant dans le 'main code' de JP?
   #      Il manque les filtres median, directionel, lp/hp gaussien, Sobel/Roberts, FFT
   if { $Size%2 == 0 } {
      set Size [expr ($Size -1)]
      GenX::Log WARNING "Filter size must be an odd number, decreasing filter size to $Size"
   }

   set kernel { }

   switch $Type {
      "LOWPASS" {
         for { set i 0 } { $i < $Size } {  incr i } {
            set line { }
            for { set j 0 } { $j < $Size } {  incr j } {
               lappend line 1
            }
            lappend kernel $line
         }
      }

      "HIGHPASS" {
         set mid [expr ($Size/2.0)]
         for { set i 0 } { $i < $Size } {  incr i } {
            set line { }
            for { set j 0 } { $j < $Size } {  incr j } {
               if { ($mid > $i) && ($mid < ($i + 1)) && ($mid > $j) && ($mid < ($j + 1)) } {
                  lappend line [expr ($Size * $Size - 1)]
               } else {
                  lappend line -1
               }
            }
            lappend kernel $line
         }
      }
   }

   return $kernel
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::SMOKE2DA>
# Creation : August 2010 - Alexandre Leroux - CMC/CMOE
#            August 2010 - Lucie Boucher - CMC/CMOE
#
# Goal     : Finds the dissemination area polygons for the target province
#            Proceeds to counting and averaging of SMOKE classes for each
#            DA polygon.
#
# Parameters :
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::SMOKE2DA {indexUTMREF } {

   GenX::Log INFO "D�but de la proc SMOKE2DA"

   variable Param

  # puts "Le code de province est $Param(ProvinceCode)"

   #r�cup�ration du fichier LULC
   #tests avec la sandwich, � remplacer par Param(OutFile)_SMOKE.tif
   gdalband read RSANDWICH [gdalfile open FSANDWICH read $GenX::Param(OutFile)_sandwich.tif]
   gdalband read RSMOKE [gdalfile open FSMOKE read $GenX::Param(OutFile)_SMOKE.tif]

   #r�cup�ration du fichier des polygones de dissemination area pour tout le Canada
   set layer [lindex [ogrfile open SHAPE read $Param(PopFile2006)] 0]
   eval ogrlayer read VDAPOLYGONS $layer

   #r�cup�ration du nom de fichier, utile pour la s�lection par attribut ?  peut-�tre � supprimer
   set statcanfilename [string range [file tail $Param(PopFile2006)] 0 16]
   #statcanfilename contains an element of the form da2006_pop_labour

   #s�lection des polygones situ�s � l'int�rieur de la zone trait�e
   set dapolygons [ogrlayer pick VDAPOLYGONS [list $Param(Lat1) $Param(Lon1) $Param(Lat1) $Param(Lon0) $Param(Lat0) $Param(Lon0) $Param(Lat0) $Param(Lon1) $Param(Lat1) $Param(Lon1)] True]
   #dapolygons contient une liste d'ids de forme 99999, identifiant les polygones de VDAPOLYGONS se trouvant � l'int�rieur de la zone d�finie



   #Les deux lignes suivantes sont � supprimer : test d'interrogation du fichier
   #set maxpop [ogrlayer stats VDAPOLYGONS -max DAPOP2006] ;# ligne � supprimer
   #puts "La population maximale d'un DA sur la zone est $maxpop" ;# ligne � supprimer




   #--------CETTE BOUCLE SERA PROBABLEMENT � RECODER ENTI�RMENT : SOLUTION DE D�PANNAGE
   set Param(PopFile2006_PEI) /data/aqli04/afsulub/StatCan2006/da2006_pei.shp
   set layerpei [lindex [ogrfile open SHAPE read $Param(PopFile2006_PEI)] 0]
   eval ogrlayer read VDAPOLYGONSPEI $layer

   foreach i $Param(SmokeClasses) {
   gdalband create RSMOKEBIN $Param(Width) $Param(Height) 1 Byte
   gdalband define RSMOKEBIN -georef UTMREF$indexUTMREF
   vexpr RSMOKEBIN ifelse((RSMOKE=$i),1,0)

   ogrlayer define VDAPOLYGONSPEI -field cl$i
   ogrlayer interp VDAPOLYGONSPEI RSMOKEBIN cl$i WITHIN 1
   }

   #�criture des valeurs dans le shapefile
   ogrlayer write VDAPOLYGONSPEI $Param(popFile2006_PEI)
   #--------FIN DE LA BOUCLE � RECODER ENTI�REMENT





# CREER UN NOUVEAU FIELD AVEC "ogrlayer define -field" ?
# TESTER AVEC DA2006_PEI only.... �a va etre pas mal plus vite !
#puts "Avant le ogrlayer interp"
#   ogrlayer interp dapolygons RSANDWICH comptage NORMALIZED_CONSERVATIVE 0 final liste ;#g�n�re une segmentation fault
#   ogrlayer interp VDAPOLYGONS RSANDWICH pop_dens WITHIN 1
#puts "Apr�s le ogrlayer interp"
# Attention - ogrlayer write layerid fileid est probablement requis (avec un open avant ?)


   #---------------SCRAP CETTE SECTION -----------

#   set j 0 ;#incr�ment sur le nombre de polygones de la zone trait�e
#   foreach n $dapolygons {
      #test d'interrogation du polygone : les 3 lignes suivantes sont � supprimer
      #set pop [ogrlayer define VDAPOLYGONS -feature $n DAPOP2006] ;# � supprimer
      #puts "La population du polygone $j est $pop" ;# � supprimer

      #boucle if/else ne servant qu'� rouler sur un petit nombre de polygones.
      #supprimer le if/else, ne conserver que le contenu de la partie else
#      if {$j > 2} {
#         return
#      } else {
#         puts "Counts smoke classes in DA polygon $j"

         #------- todo -------------
         #s�lectionner le polygone de VDAPOLYGONS ayant l'id $dapolygons
         #pour chaque classe SMOKE :
            #compter le nombre de pixels de RSANDWICH intersectant le polygone et ayant la valeur de classe SMOKE
            #�crire cette valeur dans le champ de la classe SMOKE pour le polygone s�lectionn�

         #d�finir une g�om�trie pour le polygone
#         set geom [ogrlayer define VDAPOLYGONS -geometry $n]

         #test � supprimer
         #if { [ogrlayer is VDAPOLYGONS] } {
         #   puts "VDAPOLYGONS est un layer"
         #} else {
         #   puts "VDAPOLYGONS n'est pas un layer"
         #}

         #if { [gdalband is RSANDWICH] } {
         #   puts "RSANDWICH est une bande"
         #} else {
         #   puts "RSANDWICH n'est pas une bande"
         #}

         #ogrlayer interp geom RSANDWICH comptage NORMALIZED_CONSERVATIVE 0 final liste ;# g�n�re une segmentation fault

#         puts "L'interpolation ne se fait pas pour cause de segmentation fault; � corriger"
#         incr j ;# � supprimer
#      }

   #---------------FIN : SCRAP CETTE SECTION -----------
#   }


   GenX::Log INFO "Fin de la proc SMOKE2DA"
}

#----------------------------------------------------------------------------
# Name     : <UrbanX::Process>
# Creation : date? - Alexandre Leroux - CMC/CMOE
#
# Goal     :
#
# Parameters :
#   <Coverage>   : zone to process {MONTREAL VANCOUVER TORONTO OTTAWA WINNIPEG CALGARY HALIFAX REGINA EDMONTON VICTORIA QUEBEC}
#		   default settings on Quebec
#
# Return:
#
# Remarks :
#
#----------------------------------------------------------------------------
proc UrbanX::Process { Coverage } {

   GenX::Log INFO "D�but d'UrbanX"

   variable Param

   GenX::Log INFO "Coverage = $Coverage"

   if {$Coverage == "IPE"} {
      GenX::Log INFO "Traitement d'une province : IndustrX"
      UrbanX::AreaDefine    $Coverage
      UrbanX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) 0
      #----- TODO 
      #Finds a list of nts 50k sheets that intersect with province polygon
      UrbanX::FindNTSSheetsCanVec 0;#va avoir besoin du code de province, retourne Param(NTSSheets)
		
		foreach m $Param(NTSSheets) {
			GenX::Log INFO "Traitement de la tuile NTS ayant l'ID $m"

			#----- Finds the extents of the zone to be process
			UrbanX::NTSLatLonDefine $m
			GenX::Log INFO "La latitude de la tuile va de $Param(Lat0) � $Param(Lat1)"
			GenX::Log INFO "La longitude de la tuile va de $Param(Lon0) � $Param(Lon1)"
			#----- Defines the extents of the zone to be process
			UrbanX::UTMZoneDefine  $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) $m

			#----- Finds CanVec files, rasterize and flattens all CanVec layers
			if { ![file exists $GenX::Param(OutFile)_sandwich_$m.tif] } {
				UrbanX::SandwichCanVec $m $m
			} else {
				GenX::Log INFO "Le fichier $GenX::Param(OutFile)_sandwich_$m.tif existe d�j�."
			}

			#----------TO MODIFY FOR CANVEC LAYERS
			#----- Applies buffer to linear and ponctual elements such as buildings and roads
			#UrbanX::ScaleBuffersCanVec $m
			#----- Creates the fields and building vicinity output using spatial buffers
			#UrbanX::ChampsBuffers $m
			#----------END OF : TO MODIFY FOR CANVEC LAYERS

			#----- Calculates the population density
			if { ![file exists $GenX::Param(OutFile)_popdens_$m.tif] || ![file exists $GenX::Param(OutFile)_popdens-builtup_$m.tif] } {
				UrbanX::PopDens2BuiltupCanVec $m $m
			} else {
				GenX::Log INFO "Les fichiers $GenX::Param(OutFile)_popdens_$m.tif et $GenX::Param(OutFile)_popdens-builtup_$m.tif existent d�j�."
			}

			#----- Applies LUT to all processing results to generate SMOKE classes.
			if { ![file exists $GenX::Param(OutFile)_SMOKE_$m.tif] } {
				UrbanX::Priorities2SMOKE  $m
			} else {
				GenX::Log INFO "Le fichier $GenX::Param(OutFile)_SMOKE_$m.tif existe d�j�."
			}

			#----- PROC TO DEVELOP !
			#UrbanX::SMOKE2DA

		}




   } else {
      GenX::Log INFO "Traitement d'une ville : UrbanX"
      #----- Defines the extents of the zone to be process
      UrbanX::AreaDefine    $Coverage
      UrbanX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution) 0
 
      #----- Finds CanVec files, rasterize and flattens all CanVec layers
      UrbanX::SandwichCanVec $Coverage 0

      #----- Applies buffer to linear and ponctual elements such as buildings and roads
      #UrbanX::ScaleBuffersCanVec 0

      #-----La rasterization des hauteurs n'a pas vraiment d'affaire dans UrbanX... C'est one-shot.
      #UrbanX::Shp2Height

      #----- Creates the fields and building vicinity output using spatial buffers
      #UrbanX::ChampsBuffers 0

      #----- Calculates the population density
      UrbanX::PopDens2BuiltupCanVec $Coverage 0

      #----- Calculates building heights
      #UrbanX::HeightGain 0               ;# Requires UrbanX::ChampsBuffers to have run
      #UrbanX::BuildingHeight           ;# This proc requires UrbanX::PopDens2Builtup and must be used in conjunction with the previous one otherwise $Param(HeightGain) won't be defined

      #----- Applies LUT to all processing results to generate TEB classes. Requires UrbanX::PopDens2Builtup.
      #UrbanX::Priorities2TEB

      #----- TO DELETE FROM THE URBANX PROCESSING : JUSTE L� POUR FAIRE DES TESTS SUR DE PETITES ZONES
      #----- Applies LUT to all processing results to generate SMOKE classes.
      UrbanX::Priorities2SMOKE $Coverage
      #UrbanX::SMOKE2DA 0
      #----- FIN DU TO DELETE FROM THE URBANX PROCESSING

      #----- Optional outputs:
      #UrbanX::VegeMask
      #UrbanX::TEB2FSTD
   }


   #------------- MAIN ORIGINAGL, � SUPPRIMER SI ON GARDE LE IF/ELSE SUR COVERAGE ------------

   #----- Defines the extents of the zone to be process
   #UrbanX::AreaDefine    $Coverage
   #UrbanX::UTMZoneDefine $Param(Lat0) $Param(Lon0) $Param(Lat1) $Param(Lon1) $Param(Resolution)
   #UrbanX::FindNTSSheets ;# Useless now since we use GenX::CANVECFindFiles

   #----- Finds CanVec files, rasterize and flattens all CanVec layers
   #UrbanX::SandwichBNDT ;# to be deleted, replaced with UrbanX::SandwichCanVec
   #UrbanX::SandwichCanVec $Coverage

   #----- Applies buffer to linear and ponctual elements such as buildings and roads
   #UrbanX::ScaleBuffersBNDT ;# to be deleted, replaced with UrbanX::ScaleBuffersCanVec
   #UrbanX::ScaleBuffersCanVec

   #-----La rasterization des hauteurs n'a pas vraiment d'affaire dans UrbanX... C'est one-shot.
   #UrbanX::Shp2Height

   #----- Creates the fields and building vicinity output using spatial buffers
   #UrbanX::ChampsBuffers

   #----- Calculates the population density
   #UrbanX::PopDens2BuiltupBNDT ;# to be deleted, replaced with UrbanX::PopDens2BuiltupCanVec
   #UrbanX::PopDens2BuiltupCanVec

   #----- Calculates building heights
   #UrbanX::HeightGain               ;# Requires UrbanX::ChampsBuffers to have run
   #UrbanX::BuildingHeight           ;# This proc requires UrbanX::PopDens2Builtup and must be used in conjunction with the previous one otherwise $Param(HeightGain) won't be defined

   #----- Applies LUT to all processing results to generate TEB classes. Requires UrbanX::PopDens2Builtup.
   #UrbanX::Priorities2TEB

   #----- Applies LUT to all processing results to generate SMOKE classes.
   #UrbanX::Priorities2SMOKE
   #UrbanX::SMOKE2DA

   #----- Optional outputs:
   #UrbanX::VegeMask
   #UrbanX::TEB2FSTD

   #------------- FIN DU MAIN ORIGINAGL, � SUPPRIMER SI ON GARDE LE IF/ELSE SUR COVERAGE ---------

   GenX::Log INFO "Fin d'UrbanX.  Retour � GenPhysX"
}
