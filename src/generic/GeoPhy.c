/*=========================================================
 * Environnement Canada
 * Centre Meteorologique Canadien
 * 2100 Trans-Canadienne
 * Dorval, Quebec
 *
 * Projet       : Lecture et traitements de divers fichiers de donnees
 * Fichier      : GeoPhy.c
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

/*----------------------------------------------------------------------------
 * Nom      : <GeoPhy_SubTranspose>
 * Creation : Aout 2013 - J.P. Gauthier - CMC/CMOE
 *
 * But      : Interpolate Def data into the subgrid tile
 *
 * Parametres :
 *  <Def>     : Field data definition.
 *  <I>       : Gridpoint i.
 *  <J>       : Gridpoint j.
 *  <Sub>     : Subgrid array (SubSample*SubSample).
 *
 * Retour:
 *  <...>     : 0:Fail 1:Ok  
 *
 * Remarques :
 *    - Uses TclGeoEER TDef structure
 *----------------------------------------------------------------------------
*/
int GeoPhy_SubTranspose(TData *Topo,int I,int J,float *Sub) {
   
   int   i,j,idx;
   double di,dj,d,val,val1;
   
   idx=0;
   d=1.0/(Topo->Def->SubSample-1);

   for(j=0;j<Topo->Def->SubSample;j++) {
      dj=(double)J-0.5+d*j;
      if (dj<=-0.5) dj=-0.499;
      if (dj>=(double)Topo->Def->NJ-0.501) dj=Topo->Def->NJ-0.501;
      
      for(i=0;i<Topo->Def->SubSample;i++,idx++) {
         di=(double)I-0.5+d*i;
         if (di<=-0.5) di=-0.499;
         if (di>=(double)Topo->Def->NI-0.501) di=Topo->Def->NI-0.501;
         
         Topo->GRef->Value(Topo->GRef,Topo->Def,'L',0,di,dj,0,&val,&val1);
         Sub[idx] = val;         
     }
   }
   
   return(1);
}

/*----------------------------------------------------------------------------
 * Nom      : <GGeoPhy_GridPointResolution>
 * Creation : Aout 2013 - J.P. Gauthier - CMC/CMOE
 *
 * But      : Get teh grid resolutiopn in X and Y in meters
 *
 * Parametres :
 *  <Ref>     : Georeference definition.
 *  <Def>     : Field data definition.
 *  <I>       : Gridpoint i.
 *  <J>       : Gridpoint j.
 *  <DX>      : X resolution in meters.
 *  <DY>      : Y resolution in meters.
 *
 * Retour:
 *  <...>     : 0:Fail 1:Ok  
 *
 * Remarques :
 *    - We use the middle of the grid cell as a goo distance approximation
 *      instead of usgin the average/max of each side
 *----------------------------------------------------------------------------
*/
int GeoPhy_GridPointResolution(TGeoRef *Ref,TDef *Def,int I,int J,double *DX,double *DY) {
   
   float  di[4],dj[4],dlat[4],dlon[4];
   double dx[4],dy[4];
   
   I+=1.0;J+=1.0;
   di[0]=I-0.5; dj[0]=J;
   di[1]=I+0.5; dj[1]=J;
   di[2]=I;     dj[2]=J-0.5;
   di[3]=I;     dj[3]=J+0.5;

   // Reproject gridpoint length coordinates as segments crossing center of cell
   c_gdllfxy(Ref->Ids[0],dlat,dlon,di,dj,4);
   dx[0]=DEG2RAD(dlon[0]); dy[0]=DEG2RAD(dlat[0]);
   dx[1]=DEG2RAD(dlon[1]); dy[1]=DEG2RAD(dlat[1]);

   dx[2]=DEG2RAD(dlon[2]); dy[2]=DEG2RAD(dlat[2]);
   dx[3]=DEG2RAD(dlon[3]); dy[3]=DEG2RAD(dlat[3]);

   // Get distance in meters
   *DX=DIST(0.0,dy[0],dx[0],dy[1],dx[1]);
   *DY=DIST(0.0,dy[2],dx[2],dy[3],dx[3]);

   // If x distance is null, we crossed the pole
   if (*DX==0.0)
      *DX=(M_PI*(*DY))/Def->NI;
   
   return(1);
}

/*----------------------------------------------------------------------------
 * Nom      : <GeoPhy_LegacyAsh>
 * Creation : Aout 2013 - J.P. Gauthier - CMC/CMOE
 *
 * But      : Calcul de la longueur de rugosite et pentes sous-maille.
 *
 * Parametres :
 *  <H>       : HAUTEUR DES ECHELLES NON RESOLUES.
 *  <HTOT>    : VALEUR DE H.
 *  <ASTOT>   : VALEUR DE A/S. 
 *  <NI>      : NOMBRE DE POINTS EN I DE LA GRILLE CIBLE.
 *  <NJ>      : NOMBRE DE POINTS EN J DE LA GRILLE CIBLE.
 *  <DX>      : RESOLUTION EN X DE LA GRILLE CIBLE.
 *  <DY>      : RESOLUTION EN Y DE LA GRILLE CIBLE.
 *  <VAR>     : VALEUR DE LA VARIANCE DES ECHELLES NON-RESOLUES.
 *  <HX2>     : PENTE EN X AU CARRE DES ECHELLES NON-RESOLUES.
 *  <HY2>     : PENTE EN Y AU CARRE DES ECHELLES NON-RESOLUES.
 *  <HXY>     : PRODUIT DES PENTES EN X ET EN Y DES ECHELLES  NON-RESOLUES.
 *
 * Retour:
 *  <...> : 
 *
 * Remarques :
 *    - Fonction extraite de genesis et creee par Judy St-James en 1998 
 *      et revisee en 2001
 *----------------------------------------------------------------------------
*/
int GeoPhy_LegacyAsh(TDef *Topo,float *H,float DX,float DY,float *HTOT,float *ASTOT,float *VAR,float *HX2,float *HY2, float *HXY) {

   float dhdx,dhdx2,dhdy,dhdy2,dhdxdy,hy,hx,sasx,sasy,avgh,varh,sumh,hh,ll;
   float sdx,sdy,dx,dy,dm;
   int   s,i,j,l,tm,icheq,ssquare,ni,idx,idxe;
   int   tmp[SUB_SIZE],idm[SUB_SIZE];
   
   s       = Topo->SubSample-1;
   ssquare = Topo->SubSample*Topo->SubSample;
   sdx      = DX/s;
   sdy      = DY/s;

   varh=avgh=sasx=sasy=hy=hx=dhdx=dhdx2=dhdy=dhdy2=dhdxdy=0.0f;

   // Parcours de la grille fine en x de j=1 a f1
   idx=0;
   ni=Topo->SubSample;
   
   for(j=0;j<Topo->SubSample;j++) {

      icheq = 0;
      tm = 0;
      idx=j*ni;
      
      for(i=0;i<Topo->SubSample-1;i++,idx++) {

         // Calcul du terme A/S en direction des x.
         sasx += fabsf(H[idx+1]-H[idx]);

         // Calcul de la moyenne des echelles non-resolues
         avgh += H[idx];

         // Calcul des pentes en x et en y des echelles non-resolues.
         // Methode de differenciation de second ordre (Leapfrog).
         if (j==0) {
            dhdy  = (H[idx+ni]-H[idx])/sdy;
         } else if (j==s) {
            dhdy = (H[idx]-H[idx-ni])/sdy;
         } else {
            dhdy = (H[idx+ni]-H[idx-ni])/(2.0*sdy);
         }

         if (i==0) {
            dhdx = (H[idx+1]-H[idx])/sdx;
         } else {
            dhdx = (H[idx+1]-H[idx-1])/(2.0*sdx);
         }
         
         dhdy2  += (dhdy*dhdy);
         dhdx2  += (dhdx*dhdx);
         dhdxdy += (dhdx*dhdy);               

         // Recherche des MAX et des MIN en direction des x.     
         if (H[idx+1]==H[idx]) {
            tmp[i+1] = 3;

            if (icheq==0) {
               tmp[i] = 3;
               icheq = 1;
               continue;
            }

         } else if (H[idx+1] > H[idx]) {
            tmp[i+1] = 2;

            if (icheq==0) {
               idm[++tm] = i;
               tmp[i] = 1;
               icheq = 1;
               continue;
            }

         } else {
            tmp[i+1] = 1;

            if (icheq==0) {
               idm[++tm] = i;
               tmp[i] = 2;
               icheq = 1;
               continue;
            }
         }

         if (tmp[i]>2) {
            if (tmp[i+1]==1) {
               idm[++tm] = i;
            } else if (tmp[i+1]==2) {
               idm[++tm] = i;
            }
         } else if (tmp[i+1]>tmp[i]) {        
            if (tmp[i+1]==3) {
               idm[++tm] = i;
            } else {
               idm[++tm] = i;
            }
         } else if (tmp[i+1]<tmp[i]) {
            idm[++tm] = i;                     
         }
      }

      // Calcul des pentes en x et en y des echelles non-resolues a la frontiere i=Topo->SubSample-1
      idxe=j*ni+ni-1;
      dhdx   = (H[idxe]-H[idxe-1])/sdx;

      if (j==0) {
         dhdy = (H[idxe+ni]-H[idxe])/sdy;
      } else if (j==s) {
         dhdy = (H[idxe]-H[idxe-ni])/sdy;
      } else {
         dhdy = (H[idxe+ni]-H[idxe-ni])/(2.0*sdy);
      }

      dhdy2  += (dhdy*dhdy);
      dhdx2  += (dhdx*dhdx);
      dhdxdy += (dhdx*dhdy);

      // Calcul de la moyenne des echelles non-resolues
      avgh = avgh + H[idxe];

      if (tmp[s]==1) {
         idm[++tm] = s;
      } else if (tmp[s]==2) {
         idm[++tm] = s;
      }

      // Calcul du term h
      hh=ll=0.0f;

      if (tm) {

         for (l=1;l<tm;l++) {
            
            dx = (float)(idm[l+1] - idm[l]);
            sumh = fabsf((H[j*ni+idm[l+1]] - H[j*ni+idm[l]])*dx*sdx);
            hh += sumh;
            ll += dx;
         }

         hh /= (ll*sdx);
         hy += hh;

      } else {
         hy = 0.0;
      }
   }

   // Moyenne des pentes des echelles non-resolues
   *HX2 = dhdx2/ssquare;
   *HY2 = dhdy2/ssquare;
   *HXY = dhdxdy/ssquare;
   hy  = hy/Topo->SubSample;

   sasx = sasx/(DX*Topo->SubSample);

   // Calcul de la moyenne des echelles non-resolues
   avgh = avgh/(ssquare);
   
   // Calcul du terme A/S en direction des y
   for(i=0;i<ni;i++) {

      icheq = 0;
      tm    = 0;

      for(j=0;j<ni-1;j++) {
         idx=j*ni+i;

         sasy+=fabsf(H[idx+ni] - H[idx]);

         // Calcul de la variance des echelles non-resolues
         dm=H[idx]-avgh;
         varh += (dm*dm)/ssquare;
         
         // Recherche des MAX et des MIN en direction des y.
         if (H[idx+ni] == H[idx]) {

            tmp[j+1] = 3;

            if (icheq==0) {
               tmp[j] = 3;
               icheq = 1;
               continue;
            }

         } else if (H[idx+ni]>H[idx]) {

            tmp[j+1] = 2;

            if (icheq==0) {
               idm[++tm]=j;
               tmp[j]= 1;
               icheq = 1;
               continue;
            }
         } else {

            tmp[j+1] = 1;

            if (icheq==0) {
               idm[++tm] = j;
               tmp[j]= 2;
               icheq = 1;
               continue;
            }
         }


         if (tmp[j]>2) {
            if (tmp[j+1]==1) {
               idm[++tm]= j;
            } else if  (tmp[j+1]==2) {
               idm[++tm]= j;
            }
         } else if (tmp[j+1]>tmp[j]) {           
            if (tmp[j+1]==3) {
               idm[++tm]= j;
            } else {
               idm[++tm]= j;
            }
         } else if (tmp[j+1]<tmp[j]) {
               idm[++tm]= j;
         }
      }

      // Calcul de la variance des echelles non-resolues
      idxe=(ni-1)*ni+i;
      dm=H[idxe]-avgh;
      varh += (dm*dm)/ssquare;

      if (tmp[s]==1) {
         idm[++tm]= s;
      } else if (tmp[s]==2) {
         idm[++tm]= s;
      }

      // Calcul du term h
      hh=ll=0.0f;

      if (tm) {

         for (l=1;l<tm;l++) {

            dy = (float)(idm[l+1] - idm[l]);
            sumh = fabsf(H[idm[l+1]*ni+i] - H[idm[l]*ni+i])*dy*sdy;
            hh += sumh;
            ll += dy;
         }

         hh /= (ll*sdy);
         hx += hh;
      } else {
         hx = 0.0f;
      }
   }

   hx    /= Topo->SubSample;         
   sasy  /= (DY*Topo->SubSample);
   *HTOT  = (hx + hy)/2.0f;
   *ASTOT = (sasx + sasy)/2.0f;

   // Calcul de la variance des echelles non-resolues
   *VAR = sqrtf(varh); 

   return(1);
}

/*----------------------------------------------------------------------------
 * Nom      : <GeoPhy_SubGridLegacy>
 * Creation : Aout 2013 - J.P. Gauthier - CMC/CMOE
 *
 * But      : Calcul de la longueur de rugosite scalaire donnée par Grant et Mason.
 *
 * Parametres :
 *  <Interp>  : Interpreteur TCL.
 *  <Topo>    : Topographie cible.
 *  <Vege>    : Végétation cible
 *  <ZZ>      : Longueur de rugosité scalaire cible en X seulement. 
 *  <LH>      : Variance des échelles non résolues.
 *  <DH>      : Biais des échelles non résolues.
 *  <HX2>     : Pentes en X au carré des échelles non-résolues.
 *  <HY2>     : Pentes en Y au carré des échelles non-résolues.
 *  <HXY>     : Produits des pentes en X et Y des échelles non-résolues.
 *
 * Retour:
 *  <...> : 
 *
 * Remarques :
 *    - Fonction extraite de genesis et creee par Judy St-James en 1998 
 *      et revisee en 2001
 *----------------------------------------------------------------------------
*/
int GeoPhy_SubGridLegacy(Tcl_Interp *Interp,TData *Topo,TData *Vege,TData *ZZ,TData *LH,TData *DH,TData *HX2,TData *HY2,TData *HXY) {
 
   int   i,j,idx,ind,s,vg,sub;
   float as,htot,sum,silh;
   float a,b;
   float rugv[]={ 0.001,0.001,0.001,1.5,3.5,1.0,2.0,3.0,0.8,0.05,0.15,0.15,0.02,0.08,0.08,0.08,0.35,0.25,0.1,0.08,1.35,0.01,0.05,0.05,1.5,0.05 };
   float topo[SUB_SIZE*SUB_SIZE];
   double dx,dy;
   float *zz,*lh,*dh,*hx2,*hy2,*hxy;
   
   if (!Topo || !Vege) {
      Tcl_AppendResult(Interp,"Invalid topographic and/or vegetation field",(char*)NULL);
      return(TCL_ERROR);   
   }
   if (!Topo->Def->Sub) {
      Tcl_AppendResult(Interp,"Subgrid topography has not been calculated",(char*)NULL);
      return(TCL_ERROR);   
   }
   
   // Get array pointers
   Def_Pointer(ZZ->Def,0,0,zz);
   Def_Pointer(LH->Def,0,0,lh);
   Def_Pointer(DH->Def,0,0,dh);
   Def_Pointer(HX2->Def,0,0,hx2);
   Def_Pointer(HY2->Def,0,0,hy2);
   Def_Pointer(HXY->Def,0,0,hxy);
   
   idx=0;
   s=Topo->Def->SubSample*Topo->Def->SubSample;
   
   // Loop on topo gridpoint
   for(j=0;j<Topo->Def->NJ;j++) {
      for(i=0;i<Topo->Def->NI;i++,idx++) {

         // Interpolate topo on subgrid
         GeoPhy_SubTranspose(Topo,i,j,topo);
         
         // Get gridpoint resolution (meters)
         GeoPhy_GridPointResolution(Topo->GRef,Topo->Def,i,j,&dx,&dy);
         
         // Calculate height difference 
         sum = 0.0f;
         sub=idx*s;
         for(ind=0;ind<s;ind++,sub++) {

            // If the value is valid
            if (Topo->Def->Sub[sub]!=Topo->Def->NoData) {
               sum += topo[ind] = Topo->Def->Sub[sub]-topo[ind];
            } else {
               topo[ind] = 0.0;
            }
         }
         dh[idx] = sum/s;

         GeoPhy_LegacyAsh(Topo->Def,topo,dx,dy,&htot,&as,&lh[idx],&hx2[idx],&hy2[idx],&hxy[idx]);

         Def_Get(Vege->Def,0,idx,vg);

         htot = FMAX(htot,HMIN);
         silh =  0.5f*CT*as/2.0f;
         b    = logf(htot/(2.0f*rugv[vg-1]));
         b    = (VK*VK)/(b*b);         
         a    = (VK*VK)/(silh + b);
         
         lh[idx] *=2.0f;
         zz[idx] = htot/(2.0f*expf(sqrtf(a)));
      }
   }
   
   return(TCL_OK);
}    

/*----------------------------------------------------------------------------
 * Nom      : <GeoPhy_ZFilterTopo>
 * Creation : Septembre 2007 - J.P. Gauthier - CMC/CMOE
 *
 * But      : Appliquer le filtre GEM
 *
 * Parametres :
 *  <Interp>  : Interpreteur TCL.
 *  <Field>   : Champ a filtrer
 *  <Set>     : Array Tcl du contenue de namelist (gem_settings.nml)
 *
 * Retour:
 *  <TCL_...> : Code d'erreur de TCL.
 *
 * Remarques :
 *   - Extrait du filtre de GEM
 *----------------------------------------------------------------------------
*/
int GeoPhy_ZFilterTopo(Tcl_Interp *Interp,TData *Field,Tcl_Obj *Set) {

   Tcl_Obj *obj;

   float *fld,lcfac,mlr,frco;
   int    idx,i,j,nio,njo,dgfm,cliporo,norm;
   int    digfil=0,tdxfil=0,mapfac=0;
   char   grtyp[2]="GU",lagrd;

   extern void f77name(smp_digt_flt)();
   extern void f77name(smp_2del_flt)();

   if (!Field) {
      Tcl_AppendResult(Interp,"GeoPhy_ZFilterTopo: Invalid topography field",(char*)NULL);
      return(TCL_ERROR);
   }
   GeoRef_Expand(Field->GRef);

   dgfm=5;
   lcfac=2.0;
   mlr=3.0;
   norm=TRUE;
   frco=0.5;
   lagrd=FALSE;
   cliporo=FALSE;

   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"GRD_TYP_S",0x0)))       { grtyp[0]=Tcl_GetString(obj)[0];grtyp[1]=Tcl_GetString(obj)[1]; }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"TOPO_DGFMS_L",0x0)))    { Tcl_GetBooleanFromObj(Interp,obj,&mapfac); }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"TOPO_DGFMX_L",0x0)))    { Tcl_GetBooleanFromObj(Interp,obj,&digfil); }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"TOPO_FILMX_L",0x0)))    { Tcl_GetBooleanFromObj(Interp,obj,&tdxfil); }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"TOPO_CLIP_ORO_L",0x0))) { Tcl_GetBooleanFromObj(Interp,obj,&cliporo); }

   if (!digfil && !tdxfil) {
      return(TCL_OK);
   }

   if ( grtyp[0]=='L' && grtyp[1]=='U' ) {
     lagrd=TRUE;
   }
   grtyp[0]='G';

   nio=lagrd?Field->Def->NI:Field->Def->NI-1;
   njo=Field->Def->NJ;

   fld=(float*)malloc(nio*njo*sizeof(float));
      for(i=0;i<nio;i++) {
         for(j=0;j<njo;j++) {
            idx=j*nio+i;
            Def_Get(Field->Def,0,FIDX2D(Field->Def,i,j),fld[idx]);
         }
      }


   /*Apply digital filter*/
   if (digfil) {
      if (cliporo) {
         for(i=0;i<nio*njo;i++) {
            if (fld[i]<0.0) fld[i]=0.0;
         }
      }
      f77name(smp_digt_flt)(fld,Field->GRef->AX,Field->GRef->AY,&nio,&njo,&lagrd,grtyp,&dgfm,&lcfac,&mlr,&mapfac,&norm);
   }

   /*Apply 2-delta-xy filter*/
   if (tdxfil) {
      if (cliporo) {
         for(i=0;i<nio*njo;i++) {
            if (fld[i]<0.0) fld[i]=0.0;
         }
      }
      f77name(smp_2del_flt)(fld,Field->GRef->AX,Field->GRef->AY,&nio,&njo,&lagrd,grtyp,&frco);
   }

   for(j=0;j<Field->Def->NJ;j++) {
      for(i=0;i<nio;i++) {
         idx=j*nio+i;
         Def_Set(Field->Def,0,FIDX2D(Field->Def,i,j),fld[idx]);
      }
   }
   if (!lagrd) {
      for(j=0;j<Field->Def->NJ;j++) {
         idx=j*nio;
         Def_Set(Field->Def,0,FIDX2D(Field->Def,Field->Def->NI-1,j),fld[idx]);
      }
   }

   free(fld);
   return(TCL_OK);
}


/*----------------------------------------------------------------------------
 * Nom      : <GeoPhy_LPassFilter>
 * Creation : Fevrier 2017 - V. Souvanlasy - CMC/CMDS
 *
 * But      : Appliquer le filtre Low Pass
 *
 * Parametres :
 *  <Interp>  : Interpreteur TCL.
 *  <Field>   : Champ a filtrer
 *  <Mask>    : Champ pour masquer
 *  <Set>     : Array Tcl du contenue de namelist (gem_settings.nml)
 *
 * Retour:
 *  <TCL_...> : Code d'erreur de TCL.
 *
 * Remarques :
 *----------------------------------------------------------------------------
*/
int GeoPhy_LPassFilter(Tcl_Interp *Interp,TData *Field,Tcl_Obj *Set,TData *Mask) {

   Tcl_Obj *obj;
   double   rcD;
   float    rc=3.0;
   double   mask_thresD;
   float    mask_thres=0.01;
   int      mask_op=1;
   int      p=20;
   int      apply_minmaxI;
   char     apply_minmax;
   int      ni, nj;
   float    *fld, *mask=NULL;

   extern   void f77name(lpass_filter) ( void *, void *, int *, int *, float *, int *, int *, float *, char * );

   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"LPASSFLT_RC_DELTAX",0x0)))       { Tcl_GetDoubleFromObj(Interp,obj,&rcD); }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"LPASSFLT_P",0x0)))               { Tcl_GetIntFromObj(Interp,obj,&p); }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"LPASSFLT_MASK_OPERATOR",0x0)))   { Tcl_GetIntFromObj(Interp,obj,&mask_op); }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"LPASSFLT_MASK_THRESHOLD",0x0)))  { Tcl_GetDoubleFromObj(Interp,obj,&mask_thresD); }
   if ((obj=Tcl_GetVar2Ex(Interp,Tcl_GetString(Set),"LPASSFLT_APPLY_MINMAX",0x0)))    { Tcl_GetBooleanFromObj(Interp,obj,&apply_minmaxI); }



   ni = Field->Def->NI;
   nj = Field->Def->NJ;


   apply_minmax = (char)apply_minmaxI;
   mask_thres = mask_thresD;
   rc = rcD;

   Def_Pointer(Field->Def,0,0,fld);
   if (Mask != NULL)
      {
      Def_Pointer(Mask->Def,0,0,mask);
      }
    
   /* disable mask operator if mask field not available */ 
   if (mask == NULL)
      {
      mask_op = 0;
      }

   f77name(lpass_filter) ( fld, mask, &ni, &nj, &rc, &p, &mask_op, &mask_thres, &apply_minmax );

   return TCL_OK;
   }
