;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                            ;
; PROGRAM: create_anoms_3dim                                 ;
; PROGRAM DESCRIPTION: This program reads in 3-dimensional   ;
;    data (time x lat x lon), calculates long-term means and ;
;    anomalies of those means.                               ;
; INPUT: 3D data in netcdf format                            ;
; OUTPUT: Netcdf file of long-term meanis and anomalies of   ;
;         target variable data.                              ;
; DATE: July 15, 2017                                        ;
;                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin

;;;; Some constants
 
 dir="/work/koyama_sice/anoms/"
 vtxt="my_model.my_var_running_mean_data_Sep-Nov_"
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

;;;; Array declarations

;; Data arrays

; Weekly running mean for each day from Sep 4-Nov 27
 varrunmean=new((/nyrs,ndys-6,nS_N,nW_E/),"float")
; Name 1st and 2nd dimensions of varrunmean
 varrunmean!0="years"
 varrunmean!1="days"

; Average weekly running mean for each day (e.g. 35 years of average weekly running means for all 9/4, 9/5, etc.)
 varavgrunmean=new((/ndys-6,nS_N,nW_E/),"float")
 varavgrunmean!0="days"

; Anomaly of the running means (final product)
 varrunmeananom=new((/nyrs,ndys-6,nS_N,nW_E/),"float")
 varrunmeananom!0="years"
 varrunmeananom!1="days"
 varrunmeananom!2="nS_N"
 varrunmeananom!3="nW_E"

;; Dates arrays

; Dates of all of the data
 datedata=new((/nyrs,ndys/),"integer")
; Dates of just the running mean data
 runmeandatedata=new((/nyrs,ndys-6/),"integer")
; Dates of just the long term means for each day
 ltmdatedata=new(ndys-6,"integer")

;;;;

;;;;
; Begin program
;;;;

;;;; OPEN DATA FILES, GRAB target variable DATA, PUT THOSE DATA IN AN ARRAY

; Loop through years
 do y=byr,eyr

; dys is a counter that keeps track of the number of days in each year
   dys=0

; Loop through months (Sep-Nov)
     do m=0,2
       ycalc=y

; Loop through each day in the month
       ycalc@calendar = cal_attr
       edy=days_in_month(ycalc,months(m))
       do d=1, edy

; Create the date string, put it in an array for output
         date=ycalc*10000+months(m)*100+d
         datedata(y-byr,dys)=date

         dys=dys+1
       end do   ; d
     end do   ; y
  
; Filename
   fili=systemfunc("cd " + dir + " ; ls " + vtxt + y + nc)
   fn=addfile(dir+fili,"r")

; Grab the target variable data for this day
   varrunmean(y-byr,:,:,:)=fn->my_var

   if (y.eq.byr) then 
     lat2d=fn->lat2d
     lon2d=fn->lon2d
   end if
 end do

;;;; END READ AND GRAB DATA

;;;; START PROCESS DATA
; Create running mean data
 do y=0,nyrs-1
    do d=3,ndys-4
       runmeandatedata(y,d-3)=datedata(y,d)
    end do
 end do

 runmeandatedata!0="years"
 runmeandatedata!1="days"

; Create the average running mean for each day (i.e. use the running means for all Sep 4 to 
; create an average for that day)
 do x=0,ndys-7
    varrunmeantemp=varrunmean(:,x,:,:)
    varavgrunmean(x,:,:)=dim_avg_n_Wrap(varrunmeantemp,0)
    yrt=runmeandatedata(0,x)/10000
    ltmdatedata(x)=runmeandatedata(0,x)-(yrt*10000)
    delete(yrt)
 end do

; Finally, create the anomalies
 do y=0,nyrs-1
    do d=0,ndys-7
       varrunmeananom(y,d,:,:)=varrunmean(y,d,:,:)-varavgrunmean(d,:,:)
   end do
 end do

;;;; END PROCESS RUNNING MEAN ANOMALY DATA

; Global attributes
 fileAtt = True
 fileAtt@creation_date = systemfunc("date")
 fileAtt@institution = "University of Colorado at Boulder - CIRES"
 fileAtt@created_by = "Tomoko Koyama - tomoko.koyama@colorado.edu"
 fileAtt@program = "This file was created using the NCL script: create_anoms_3dim.ncl"
 fileAtt@notes = "This file contains  my_var long term running mean data for September 4- November 27, my_byr-my_eyr"

; Write the long term data for each day
 fnlt = "my_model.my_var_long_term_running_mean_data_Sep-Nov.nc"
 fout_lt=addfile(dir+fnlt,"c")

 fileattdef(fout_lt,fileAtt)

 fout_lt->my_in_var=varavgrunmean
 fout_lt->date=ltmdatedata
 fout_lt->lat2d=lat2d
 fout_lt->lon2d=lon2d

 delete(fileAtt@notes)

; Write the running mean output data
 do y=byr,eyr
    indi=y-byr

; Write the running mean anomaly output data
    fout_anm=addfile(dir+"my_model.my_var_running_mean_anomaly_data_Sep-Nov_"+y+".nc","c")

    fileAtt@notes = "This file contains  my_var running mean anomaly data for September 4- November 27, my_byr-my_eyr"
    fileattdef(fout_anm,fileAtt)

    fout_anm->my_in_var=varrunmeananom(indi,:,:,:)
    fout_anm->date=runmeandatedata(indi,:)
    fout_anm->lat2d=lat2d
    fout_anm->lon2d=lon2d
    
    delete(fileAtt@notes)

 end do

end
