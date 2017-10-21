;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                            ;
; PROGRAM: create_running_mean_6mo_3dim               		     ;
; PROGRAM DESCRIPTION: This program reads in 3-dimensional   ;
;    data (time x lat x lon), creates running weekly means.  ;
;                                                            ;
; INPUT: 3D data in netcdf format                            ;
; OUTPUT: Netcdf file of weekly running mean target variable ;
;    data.                                                   ;
; DATE: July 12, 2017                                        ;
;                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;;;; Some constants
 
 dir="/work/koyama_sice/"
 dirlsm="/work/koyama_sice/Land_Mask/"
 outdir="/work/koyama_sice/anoms_6mo/"
 
 dirmodel="my_model/"
 vtxt="my_var"
 nc=".rgrd.nc"
 cal_attr="my_attr"
 more="my_more"

;;;; Values for declaring arrays

; Index array for x and y
 nS_N=180
 nW_E=180

; Beginning and end years to process
 byr=my_byr
 eyr=my_eyr
 bsyr=my_bsyr
 esyr=my_esyr

; Months to process
 months = (/9,10,11,12,1,2/)
 byr@calendar = cal_attr

;;;; OPEN DATA FILES, GRAB target variable DATA

; Filename
 fdir=dir+dirmodel
 fili=systemfunc("cd " + fdir + " ; ls "+ vtxt + "_*" + byr + "*" + eyr + "*" + nc)
 fn=addfile(fdir+fili,"r")

; Find an index of array - year:byr, month:9, day:1 
 temp=str_split_csv(fili(0), "_", 0)
 strs=str_split_csv(temp(0,5), "-", 0)
 date_begin = str_split_by_length(strs(0,0),2)
 dayone = day_of_year(byr,stringtoint(date_begin(2)),stringtoint(date_begin(3))) 
 iday0=day_of_year(byr,9,1)-dayone
 iday=iday0

;;;;;;;;;;;;; SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE ;;;;;;;;;;;;;;;;;

; Calculate array sizes

 if (iday .gt. 0) then
   nyrs=eyr-byr+1       ; Data is stored from January 1st
 else
   nyrs=eyr-byr
 end if
 
 if (more .eq. "no")
   nyrs=nyrs-1
 end if

 ; Obtain the number of days from Nov.1 - Feb. 28/29
 ndys=new((eyr-byr+1),"integer")
 do iyr=byr,eyr
   ii=iyr-byr
   tmp_ndys = 0
   do m=0,5
     if(m.ge.4) then
       ycalc=iyr+1
     else
       ycalc=iyr
     end if
     ycalc@calendar = cal_attr
     tmp_ndys=tmp_ndys+days_in_month(ycalc,months(m))
   end do
   ndys(ii)=tmp_ndys
 end do
;;;;
; Begin program
;;;;

; Read in the land mask and latitude/longitude data

 fnlsm=addfile(dirlsm+"ERAI.LandMask.180x180.org.nc","r")
 lsm=fnlsm->Land_Mask
 lat2d=fnlsm->lat2d
 lon2d=fnlsm->lon2d

;;;; PUT TARGET DATA IN AN ARRAY

 tmp = fn->my_var
 dims = dimsizes(tmp)
 ntim = dims(0)            ; Number of time array



; Loop through years
 idx = 0
 idx_nt = 0
 do iyr=byr,eyr
   ii = iyr-byr
;;;; Array declarations

;; Data arrays

   ; target variable data read in from the daily files
   vardata=new((/nyrs,ndys(ii),nS_N,nW_E/),"float")
   vardata!0="years"
   vardata!1="days"

   ; Weekly running mean for each day from Sep 4-Feb 25
   varrunmean=new((/nyrs,ndys(ii)-6,nS_N,nW_E/),"float")
   ; Name 1st and 2nd dimensions of varrunmean
   varrunmean!0="years"
   varrunmean!1="days"

   ; Average weekly running mean for each day (e.g. 35 years of average weekly running means for all 9/4, 9/5, etc.)
   varavgrunmean=new((/ndys(ii)-6,nS_N,nW_E/),"float")
   varavgrunmean!0="days"

;; Dates arrays

   ; Dates of all of the data
   datedata=new((/nyrs,ndys(ii)/),"integer")
   ; Dates of just the running mean data
   runmeandatedata=new((/nyrs,ndys(ii)-6/),"integer")

;;;;
; dys is a counter that keeps track of the number of days in each year
   dys=0
   
; Loop through months (Sep-Feb)
   if (iday .gt. 0 ) then
     do m=0,5
       if(m.ge.4) then
         ycalc=iyr+1
       else
         ycalc=iyr
       end if

; Loop through each day in the month

       ycalc@calendar = cal_attr
       edy=days_in_month(ycalc,months(m))
       do d=1,edy
; Create the date string, put it in an array for output
         date=ycalc*10000+months(m)*100+d
         datedata(idx,dys)=date
       
; Grab the target variable data for this day

         if (iday.lt.ntim) then
           
           vardata(idx,dys,:,:)=fn->my_var(iday,:,:)       ; From the first file

         else

           if (more.ne."no") then
             fils=systemfunc("cd " + fdir + " ; ls "+ vtxt + "_*" + bsyr + "*" + esyr + "*" + nc)
             fns=addfile(fdir+fils,"r")
             vardata(idx,dys,:,:)=fns->my_var(idx_nt,:,:)    ; From the second file
              idx_nt = idx_nt +1 
           end if            

         end if

         dys=dys+1
         iday=iday+1

       end do   ; d

     end do   ; m
     nxtyr = iyr+1
     iyr@calendar = cal_attr
     nxtyr@calendar = cal_attr
     iday = iday + days_in_month(iyr,12)+ day_of_year(nxtyr,9,1)-1
     idx = idx+1
      
     if (idx.eq.nyrs.and.more.eq."no")
       break
     end if

   else   ; iday

     totdys=0
     do im=0,11
       y@calendar = cal_attr
       totdys=totdys+days_in_month(y,im+1)
     end do   ;im
     iday=iday+totdys

   end if   ; iday
   
;;;; END READ AND GRAB DATA


;;;; START PROCESS DATA

   ; Create running mean data
   do d=3,ndys(ii)-4
     runmeandatedata(ii,d-3)=datedata(ii,d)
     vartemp=new((/7,nS_N,nW_E/),"float")
     vartemp!0="days"
     vartemp=vardata(ii,d-3:d+3,:,:)
     varrunmean(ii,d-3,:,:)=dim_avg_n_Wrap(vartemp,0)
     delete(vartemp)
   end do

   runmeandatedata!0="years"
   runmeandatedata!1="days"

;;;; END PROCESS RUNNING MEAN DATA

; Global attributes
   fileAtt = True
   fileAtt@creation_date = systemfunc("date")
   fileAtt@institution = "University of Colorado at Boulder - CIRES"
   fileAtt@created_by = "Tomoko Koyama - tomoko.koyama@colorado.edu"
   fileAtt@program = "This file was created using the NCL script: create_var_anom_file.ncl"
   fileAtt@notes = "This file contains  my_var long term running mean data for September 4- February 25, my_byr-my_eyr"

; Write the running mean output data
   if (iday0 .gt. 0) then
   
;Data is stored from January 1st in the original output file
     system("rm -f "+outdir+"my_model.my_var_running_mean_data_Sep-Feb_"+iyr+".nc")
     fout=addfile(outdir+"my_model.my_var_running_mean_data_Sep-Feb_"+iyr+".nc","c")
     delete(fileAtt@notes)

     runmeandatedata@calendar = cal_attr
     fileAtt@notes = "This file contains  my_var running mean data for September 4- February 25, my_byr-my_eyr"
     fileattdef(fout,fileAtt)
 
     fout->my_in_var=varrunmean(ii,:,:,:)
     fout->date=runmeandatedata(ii,:)
     fout->lat2d=lat2d
     fout->lon2d=lon2d
   else   ; iday0
;Data is stored from a day in the middle of the year.
     system("rm -f "+outdir+"my_model.my_var_running_mean_data_Sep-Feb_"+iyr+".nc")
     fout=addfile(outdir+"my_model.my_var_running_mean_data_Sep-Nov_"+iyr+".nc","c")
     delete(fileAtt@notes)

     runmeandatedata@calendar = cal_attr
     fileAtt@notes = "This file contains  my_var running mean data for September 4- February 25, my_byr-my_eyr"
     fileattdef(fout,fileAtt)

     fout->my_in_var=varrunmean(ii,:,:,:)
     fout->date=runmeandatedata(ii,:)
     fout->lat2d=lat2d
     fout->lon2d=lon2d

     if (y.eq.(eyr-1) .and. more.eq."no")
       break
     end if

   end if   ;iday0

   delete ( vardata )
   delete ( varrunmean )
   delete ( varavgrunmean )
   delete ( datedata )
   delete ( runmeandatedata )

 end do   ; iyr

end
