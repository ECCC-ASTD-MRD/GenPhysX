/*=========================================================
 * Environnement Canada
 * Centre Meteorologique Canadien
 * 2100 Trans-Canadienne
 * Dorval, Quebec
 *
 * Projet       : Lecture et traitements de divers fichiers de donnees
 * Fichier      : GeoPhy.h
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

#ifndef _GeoPhy_h
#define _GeoPhy_h

#include "tcl.h"
#include "tclData.h"

#define VK       0.4f         //
#define CT       0.5f         //
#define HMIN     2.7182818f   //
#define SUB_SIZE 256          // Sub-grid maximum resolution

int GeoPhy_LegacyZ0(Tcl_Interp *Interp,TData *Topo,TData *Vege,TData *ZZ,TData *VAR,TData *HMH,TData *HX2,TData *HY2,TData *HXY);
int GeoPhy_ZFilterTopo(Tcl_Interp *Interp,TData *Field,Tcl_Obj *Set);

#endif