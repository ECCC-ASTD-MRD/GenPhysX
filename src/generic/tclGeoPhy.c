/*=========================================================
 * Environnement Canada
 * Centre Meteorologique Canadien
 * 2100 Trans-Canadienne
 * Dorval, Quebec
 *
 * Projet       : Lecture et traitements de divers fichiers de donnees
 * Fichier      : tclGeoPhy.c
 * Creation     : Aout 2013 - J.P. Gauthier
 *
 * Description  : Fonctions de calculs pour champs géophysiques.
 *
 * Remarques    :
 *   
 * License      :
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation,
 *    version 2.1 of the License.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the
 *    Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 *    Boston, MA 02111-1307, USA.
 *
 *=========================================================
 */

#include "GeoPhy.h"

static int GeoPhy_Cmd(ClientData clientData,Tcl_Interp *Interp,int Objc,Tcl_Obj *CONST Objv[]);

/*--------------------------------------------------------------------------------------------------------------
 * Nom          : <TclgeoPhy_Init>
 * Creation     : Fevrier 2003 J.P. Gauthier
 *
 * But          : Initialisation des commandes Tcl pour utilisation des fonctions geophysiques
 *
 * Parametres   :
 *   <Interp>   : Interpreteur Tcl
 *
 * Retour       : Code de retour Tcl
 *
 * Remarques    :
 *
 *---------------------------------------------------------------------------------------------------------------
*/
int Tclgeophy_Init(Tcl_Interp *Interp) {

   if (Tcl_PkgProvide(Interp,"TclGeoPhy",PACKAGE_VERSION) != TCL_OK) {
      return(TCL_ERROR);
   }

   Tcl_CreateObjCommand(Interp,"geophy",GeoPhy_Cmd,(ClientData)NULL,(Tcl_CmdDeleteProc *)NULL);

   return(TCL_OK);
}

/*----------------------------------------------------------------------------
 * Nom      : <System_Cmd>
 * Creation : Mai 2009 - J.P. Gauthier - CMC/CMOE
 *
 * But      : Appel des commandes relies aux appels system.
 *
 * Parametres     :
 *  <clientData>  : Donnees du module.
 *  <Interp>      : Interpreteur TCL.
 *  <Objc>        : Nombre d'arguments
 *  <Objv>        : Liste des arguments
 *
 * Retour:
 *  <TCL_...> : Code d'erreur de TCL.
 *
 * Remarques :
 *
 *----------------------------------------------------------------------------
*/

static int GeoPhy_Cmd(ClientData clientData,Tcl_Interp *Interp,int Objc,Tcl_Obj *CONST Objv[]){

   int   idx;
   TData  *topo,*vege,*zz,*lh,*dh,*hx2,*hy2,*hxy;
   
   static CONST char *sopt[] = { "zfilter","subgrid_legacy","lpass_filter", NULL };
   enum               opt { ZFILTER,SUBGRID_LEGACY,LPASS_FILTER };

   Tcl_ResetResult(Interp);

   if (Objc<2) {
      Tcl_WrongNumArgs(Interp,1,Objv,"command ?arg arg ...?");
      return(TCL_ERROR);
   }

   if (Tcl_GetIndexFromObj(Interp,Objv[1],sopt,"command",0,&idx)!=TCL_OK) {
      return(TCL_ERROR);
   }

   switch ((enum opt)idx) {
      case ZFILTER:
         if(Objc!=4) {
            Tcl_WrongNumArgs(Interp,2,Objv,"field settings");
            return(TCL_ERROR);
         }
         topo=Data_Get(Tcl_GetString(Objv[2]));
         
         return(GeoPhy_ZFilterTopo(Interp,topo,Objv[3]));
         break;

      case SUBGRID_LEGACY:
         if(Objc<10) {
            Tcl_WrongNumArgs(Interp,2,Objv,"topo vege zz lh dh hx2 hy2 hxy ?settings?");
            return(TCL_ERROR);
         }
         topo=Data_Get(Tcl_GetString(Objv[2]));
         vege=Data_Get(Tcl_GetString(Objv[3]));
         zz=Data_Get(Tcl_GetString(Objv[4]));
         lh=Data_Get(Tcl_GetString(Objv[5]));
         dh=Data_Get(Tcl_GetString(Objv[6]));
         hx2=Data_Get(Tcl_GetString(Objv[7]));
         hy2=Data_Get(Tcl_GetString(Objv[8]));
         hxy=Data_Get(Tcl_GetString(Objv[9]));
         
         if(Objc==11)
            return(GeoPhy_SubGridLegacy(Interp,topo,vege,zz,lh,dh,hx2,hy2,hxy,Objv[10]));
         else
            return(GeoPhy_SubGridLegacy(Interp,topo,vege,zz,lh,dh,hx2,hy2,hxy,NULL));
         break;

      case LPASS_FILTER:
         if((Objc!=4)&&(Objc!=5)) {
            Tcl_WrongNumArgs(Interp,2,Objv,"me_field settings ?mask_field?");
            return(TCL_ERROR);
         } else {
            TData *mask=NULL;
            topo=Data_Get(Tcl_GetString(Objv[2]));
            if (Objc == 5)
               mask=Data_Get(Tcl_GetString(Objv[4]));
            return(GeoPhy_LPassFilter(Interp,topo,Objv[3],mask));
         }
         break;
   }
   return(TCL_OK);
}
