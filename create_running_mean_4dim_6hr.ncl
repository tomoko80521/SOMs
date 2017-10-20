;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                            ;
; PROGRAM: create_running_mean_4dim_6hr                      ;
; PROGRAM DESCRIPTION: This program reads in 4-dimensional   ;
;    data (time x level x lat x lon), creates running weekly ;
;    means.                                                  ; 
; INPUT: 4D data in netcdf format                            ;
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
 outdir="/work/koyama_sice/anoms/"
 
 dirmodel="my_model/"
 vtxt="my_var"
 nc=".rgrd.nc"
 cal_attr="my_attr"

;;;; Values for declaring arrays

; Index array for plev
 nlev=4

; Index array for x and y
 nS_N=180
 nW_E=180

; Beginning and end years to process
 byr=my_byr
 eyr=my_eyr

; Months to process
 months = (/9,10,11/)
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
 itime0=4*(day_of_year(byr,9,1)-dayone)-1
 itime=itime0
;;;;;;;;;;;;; SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE ;;;;;;;;;;;;;;;;;

; Calculate array sizes

 if (itime .gt. 0) then
   nyrs=eyr-byr+1       ; Data is stored from January 1st
 else
   nyrs=eyr-byr
 end if

 ndys=0
 do m=0,2
    ndys=ndys+days_in_month(byr,months(m))
 end do

;;;; Array declarations

;; Data arrays

; target variable data read in from the 6-hourly files
 ntime=4*ndys
 vardata=new((/nyrs,ntime,nlev,nS_N,nW_E/),"float")
 vardata!0="years"
 vardata!1="days"

; Weekly running mean for each day from Sep 4-Nov 27
 varrunmean=new((/nyrs,ndys-6,nlev,nS_N,nW_E/),"float")
; Name 1st and 2nd dimensions of varrunmean
 varrunmean!0="years"
 varrunmean!1="days"

; Average weekly running mean for each day (e.g. 35 years of average weekly running means for all 9/4, 9/5, etc.)
 varavgrunmean=new((/ndys-6,nS_N,nW_E/),"float")
 varavgrunmean!0="days"

;; Dates arrays

; Dates of all of the data
 datedata=new((/nyrs,ntime/),"integer")
; Dates of just the running mean data
 runmeandatedata=new((/nyrs,ndys-6/),"integer")

;;;;

;;;;
; Begin program
;;;;

; Read in the land mask and latitude/longitude data

 fnlsm=addfile(dirlsm+"ERAI.LandMask.180x180.org.nc","r")
 lsm=fnlsm->Land_Mask
 lat2d=fnlsm->lat2d
 lon2d=fnlsm->lon2d

;;;; PUT TARGET DATA IN AN ARRAY

; Loop through years
 idx = 0
 do y=byr,eyr

; dys is a counter that keeps track of the number of 4 x days in each year
    dys=0

; Loop through months (Sep-Nov)
    if (itime .gt. 0 ) then
      do m=0,2

        ycalc=y

; Loop through each day in the month

        ycalc@calendar = cal_attr
        edy4=4*days_in_month(ycalc,months(m))

        do d=1,edy4

; Create the date string, put it in an array for output
          date=ycalc*10000+months(m)*100+(d-1)/4+1
          datedata(idx,dys)=date
       
; Grab the target variable data for this day
          vardata(idx,dys,:,:,:)=fn->my_var(itime,:,:,:)

          dys=dys+1
          itime=itime+1
        end do   ; d
      end do   ; m
      nxtyr = y+1
      y@calendar = cal_attr
      nxtyr@calendar = cal_attr
      itime = itime + days_in_month(y,12)+ day_of_year(nxtyr,9,1)-1
      idx = idx+1
    else
      totdys=0
      do im=0,11
        y@calendar = cal_attr
        totdys=totdys+days_in_month(y,im+1)
      end do   ;im
      itime=itime+4*totdys
    end if
   
 end do   ; y

;;;; END READ AND GRAB DATA


;;;; START PROCESS DATA

; Create running mean data
 do y=0,nyrs-1
    qtd = 0
    do d=3,ndys-4
       runmeandatedata(y,d-3)=datedata(y,4*d)
       vartemp=new((/28,nlev,nS_N,nW_E/),"float")
       vartemp!0="days"
       vartemp=vardata(y,4*(d-3):4*(d+3)+3,:,:,:)
       varrunmean(y,d-3,:,:,:)=dim_avg_n_Wrap(vartemp,0)
       delete(vartemp)
    end do
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
 fileAtt@notes = "This file contains  my_var long term running mean data for September 4- November 27, my_byr-my_eyr"

; Write the running mean output data
 if (itime0 .gt. 0) then
;Data is stored from January 1st in the original output file
   do y=byr,eyr
     indi=y-byr
     fout=addfile(outdir+"my_model.my_var_running_mean_data_Sep-Nov_"+y+".nc","c")
     delete(fileAtt@notes)

     runmeandatedata@calendar = cal_attr
     fileAtt@notes = "This file contains  my_var running mean data for September 4- November 27, my_byr-my_eyr"
     fileattdef(fout,fileAtt)

     fout->my_in_var=varrunmean(indi,:,:,:,:)
     fout->date=runmeandatedata(indi,:)
     fout->lat2d=lat2d
     fout->lon2d=lon2d
   end do
 else
;Data is stored from a day in the middle of the year.
   do y=byr+1,eyr
     indi=y-byr-1
     fout=addfile(outdir+"my_model.my_var_running_mean_data_Sep-Nov_"+y+".nc","c")
     delete(fileAtt@notes)

     runmeandatedata@calendar = cal_attr
     fileAtt@notes = "This file contains  my_var running mean data for September 4- November 27, my_byr-my_eyr"
     fileattdef(fout,fileAtt)

     fout->my_in_var=varrunmean(indi,:,:,:,:)
     fout->date=runmeandatedata(indi,:)
     fout->lat2d=lat2d
     fout->lon2d=lon2d
   end do
 end if
end
