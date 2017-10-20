;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                            ;
; PROGRAM: composite_anoms_3dim_4x2                          ;
; PROGRAM DESCRIPTION: This program reads in 3-dimensional   ;
;    running mean anomaly data and creats composite values   ;
;    corresponding to each node of 3x2 SOM map.              ;
; INPUT: 3D data in netcdf format                            ;
; OUTPUT: Netcdf file of composite target variable data      ;
; DATE: October 15, 2017                                     ;
;                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;;;; Some constants

 nx = 4
 ny = 2
 node = nx*ny
 dir="/work/koyama_sice/anoms/"
 vtxt="my_model.my_var_running_mean_anomaly_data_Sep-Nov_"
 nc=".nc"
 cal_attr="my_attr"

;;;; Values for declaring arrays

; Index array for x and y
 nS_N=180
 nW_E=180

; Beginning and end years to process
 byr=my_byr
 eyr=my_eyr

; Months to process
 months = (/9,10,11/)
 byr@calendar = cal_attr

;;;;;;;;;;;;; SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE ;;;;;;;;;;;;;;;;;

; Calculate array sizes

 nyrs=eyr-byr+1

 ndys=0
 iday=0
 do m=0,2
   ndys=ndys+days_in_month(byr,months(m))
 end do
 nds=ndys-6

;;;; Array declarations

;; Data arrays
; Anomaly of the running means (input)
 var_in=new((/nyrs*nds,nS_N,nW_E/),"float")

;; Output array
 var_out=new((/node,nS_N,nW_E/),"float")

;;;;

;; Read each node's information
 lstdir	="/work/koyama_sice/list_dates4maps/"
 lstfili= lstdir+"map_dates_"+"my_model"+"_"+nx+"x"+ny+".csv"

 lines	= asciiread(lstfili, -1, "string")
 delim	= ","
 field_names	= str_split(lines(0),delim)
 ncol	= dimsizes(field_names)
 nrow 	= dimsizes(lines)-1
 fields	= new((/ncol,nrow/),string)
 do nl=0, ncol-1
   fields(nl,:)	= str_get_field(lines(1:),nl+1,delim)
 end do
 line	= tointeger(fields(0,:))   	; line number (start from 1)
 id	= fields(1,:)			; node's identifier
					; a - (0,0), b - (0,1)
					; c - (1,0), d - (1,1)
					; e - (2,0), f - (2,1)
					; g - (3,0), h - (3,1)

;; Arrays for each node 
 var_a	= new((/num(id.eq."a"),nS_N,nW_E/),"float")
 var_b	= new((/num(id.eq."b"),nS_N,nW_E/),"float")
 var_c	= new((/num(id.eq."c"),nS_N,nW_E/),"float")
 var_d	= new((/num(id.eq."d"),nS_N,nW_E/),"float")
 var_e	= new((/num(id.eq."e"),nS_N,nW_E/),"float")
 var_f	= new((/num(id.eq."f"),nS_N,nW_E/),"float")
 var_g	= new((/num(id.eq."g"),nS_N,nW_E/),"float")
 var_h	= new((/num(id.eq."h"),nS_N,nW_E/),"float")

;;;;
; Begin program
;;;;

;;;; OPEN DATA FILES, GRAB target variable DATA, PUT THOSE DATA IN AN ARRAY

; Loop through years
 do y=byr,eyr

; Filename
   fili=systemfunc("cd " + dir + " ; ls " + vtxt + y + nc)
   fn=addfile(dir+fili,"r")
; Grab the target variable data for this day
   start=(y-byr)*nds
   last=(y-byr+1)*nds-1
   var_in(start:last,:,:)=fn->my_var(0:nds-1,:,:)

   if (y.eq.byr) then 
     lat2d=fn->lat2d
     lon2d=fn->lon2d
   end if
 end do

;;;; END READ AND GRAB DATA

;;;; START PROCESS DATA

 i_a = 0
 i_b = 0
 i_c = 0
 i_d = 0
 i_e = 0
 i_f = 0
 i_g = 0
 i_h = 0

 do iline=0,nrow-1

   ; (0,0) node
   if (id(iline).eq."a") then
     var_a(i_a,:,:) = var_in(line(iline)-1,:,:)
     i_a = i_a+1
   end if

   ; (0,1) node
   if (id(iline).eq."b") then
     var_b(i_b,:,:) = var_in(line(iline)-1,:,:)
     i_b = i_b+1
   end if

   ; (1,0) node
   if (id(iline).eq."c") then
     var_c(i_c,:,:) = var_in(line(iline)-1,:,:)
     i_c = i_c+1
   end if

   ; (1,1) node
   if (id(iline).eq."d") then
     var_d(i_d,:,:) = var_in(line(iline)-1,:,:)
     i_d = i_d+1
   end if

   ; (2,0) node
   if (id(iline).eq."e") then
     var_e(i_e,:,:) = var_in(line(iline)-1,:,:)
     i_e = i_e+1
   end if

   ; (2,1) node
   if (id(iline).eq."f") then
     var_f(i_f,:,:) = var_in(line(iline)-1,:,:)
     i_f = i_f+1
   end if

   ; (3,0) node
   if (id(iline).eq."g") then
     var_g(i_g,:,:) = var_in(line(iline)-1,:,:)
     i_g = i_g+1
   end if

   ; (3,1) node
   if (id(iline).eq."h") then
     var_h(i_h,:,:) = var_in(line(iline)-1,:,:)
     i_h = i_h+1
   end if

 end do

 var_out(0,:,:) = dim_avg_n_Wrap(var_a,0)
 var_out(1,:,:) = dim_avg_n_Wrap(var_b,0)
 var_out(2,:,:) = dim_avg_n_Wrap(var_c,0)
 var_out(3,:,:) = dim_avg_n_Wrap(var_d,0)
 var_out(4,:,:) = dim_avg_n_Wrap(var_e,0)
 var_out(5,:,:) = dim_avg_n_Wrap(var_f,0)
 var_out(6,:,:) = dim_avg_n_Wrap(var_g,0)
 var_out(7,:,:) = dim_avg_n_Wrap(var_h,0)

 var_out!0="node"
 var_out!1="nS_N"
 var_out!2="nW_E"

;;;; END PROCESS RUNNING MEAN ANOMALY DATA

; Global attributes
 fileAtt = True
 fileAtt@creation_date = systemfunc("date")
 fileAtt@institution = "University of Colorado at Boulder - CIRES"
 fileAtt@created_by = "Tomoko Koyama - tomoko.koyama@colorado.edu"
 fileAtt@program = "This file was created using the NCL script: composite_anoms_3dim_4x2.ncl"
 fileAtt@notes = "This file contains composite my_var values corresponding to each node for September 4- November 27, my_byr-my_eyr"

; Write the long term data for each day
 outdir = "/work/koyama_sice/composites/"
 filo = "my_model.my_var_composite_4x2.nc"
 system("rm -f "+outdir+filo)
 fout=addfile(outdir+filo,"c")

 fileattdef(fout,fileAtt)

 fout->my_var=var_out
 fout->lat2d=lat2d
 fout->lon2d=lon2d

end
