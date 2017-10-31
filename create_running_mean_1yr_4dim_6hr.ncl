;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                            ;
; PROGRAM: create_running_mean_1yr_4dim_6hr                  ;
; PROGRAM DESCRIPTION: This program reads in 4-dimensional   ;
;    data (time x levels x lat x lon), creates running       ;
;    weekly means from Sep - Aug.                            ;
;							     ;
;    This script is specifically for HadGEM2_ES, ta variable ;
;							     ;
; INPUT: 3D data in netcdf format                            ;
; OUTPUT: Netcdf file of weekly running mean target variable ;
;    data.                                                   ;
; DATE: October 28, 2017    T. Koyama                        ;
;                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
  rdiri	= "/work/koyama_sice"
  model = "my_model"
  vtxt	= "my_var"
  nc	= ".rgrd.nc"
  cal_attr	= "my_attr"

; Index array for levels
  nlev = 4

; Index array for x and y
  nS_N=180
  nW_E=180

; Months order (Sep - Aug)
  months = (/9,10,11,12,1,2,3,4,5,6,7,8/)

  print ( " " )
  print ( "# Target model : "+model + " - variable : " + vtxt )
  print ( " " )

  ;; define input files
  fdiri = rdiri + "/" + model

  fili 	= systemfunc("cd " + fdiri + " ; ls "+ vtxt + "_*" + nc) 
  ;fili 	= systemfunc("cd " + fdiri + " ; ls "+ vtxt + "_*20*" + nc) 

  nfil	= dimsizes(fili)
  print ( "--------------------------------------------------------------------------------" )

; Find an index of array - from month:9, day:1
  temp	= str_split_csv(fili(0), "_", 0)
  strs	= str_split_csv(temp(0,5), "-", 0)
  tmp0	= str_split_by_length(strs(0,0),4)
  year_zero	= stringtoint(tmp0(0))
  year_zero@calendar	= cal_attr
  tmp1	= str_split_by_length(tmp0(1),2)
  dayone	= day_of_year(year_zero, stringtoint(tmp1(0)), stringtoint(tmp1(1)))
  
; Calculate number of days from the first day to Sep. 1
  iday0	= day_of_year(year_zero,9,1)-dayone
  iday	= iday0

; The first year of the resulting files
  if (iday .gt. 0) then
    year_begin	= year_zero
  else
    year_begin	= year_zero+1
  end if
  year_begin@calendar	= cal_attr
      
  delete( temp )
  delete( strs )
  delete( tmp0 )
  delete( tmp1 )

;;; Preparation for output

  outdir  = rdiri + "/anoms_12mo/" 

; Global attributes
  fileAtt = True
  fileAtt@creation_date = systemfunc("date")
  fileAtt@institution = "University of Colorado at Boulder - CIRES"
  fileAtt@created_by = "Tomoko Koyama - tomoko.koyama@colorado.edu"
  fileAtt@notes = "This file contains my_var running mean data for September 4 - August 27 (28)."

;;----------------------------------------------------------------------
;; Get data
;;----------------------------------------------------------------------

  do ifil = 0, nfil-1

    print ( "--- File number : "+ (ifil+1) +" ---")
    srcfili	 = fili(ifil)
    fn   = addfile( fdiri + "/" + srcfili, "r" )
    dNames  = getvardims(fn)
    dSizes  = getfiledimsizes(fn)
    nt	= dSizes(0)

    var	= fn->my_var
    lat = fn->lat
    lon = fn->lon

    ; Store data from Sep - Nov
    mo3data = new((/360,nlev,nS_N,nW_E/),"float")
    mo3data(0:359,:,:,:) = (/var(1080:1439,:,:,:)/)
 
    ; Extract the beginning year 
    temp	= str_split_csv(fili(ifil), "_", 0)
    strs	= str_split_csv(temp(0,5), "-", 0)
    tmp0	= str_split_by_length(strs(0,0),4)
    byr	= stringtoint(tmp0(0))

    delete( temp )
    delete( strs )
    delete( tmp0 )

    ; Extract the ending year 
    temp	= str_split_csv(fili(ifil), "_", 0)
    strs 	= str_split_csv(temp(0,5), "-", 0)
    tmp0  	= str_split_csv(strs(0,1), ".", 0)
    tmp1  	= str_split_by_length(tmp0(0,0),4)
    eyr	= stringtoint(tmp1(0))

    delete( temp )
    delete( strs )
    delete( tmp0 )
    delete( tmp1 )

    ; Find numbers of years to process and the first day's data position
    if (iday .gt. 0) then
      nyrs = eyr-byr+1
      bday = iday
    else
      nyrs = eyr-byr
      bday = iday+360
    end if   ; iday
 
    ;---------------------------------------------------------------------- 
    if (iday0 .gt. 0 ) then
      tyr = byr
    else
      tyr = byr +1
    end if    
    tyr@calendar	= cal_attr

    ; Number of days from Sep. 1 to the last day of Aug. (next year)
    ndys = 360

; Data arrays
    ; daily data
    ntime = 4*ndys
    vardata = new((/ntime,nlev,nS_N,nW_E/),"float")

    ; weekly running mean for each day from Sep. 4 - Aug. 28
    varrunmean = new((/ndys-6,nlev,nS_N,nW_E/),"float")

; Dates arrays

    datedata 	= new(ndys,"integer")
    runmeandatedata 	= new((ndys-6),"integer")

;===================================================================================
; Store data extracted from the previous file
    if (ifil .gt. 0) then

      vardata(0:359,:,:,:) = (/varleft(0:359,:,:,:)/) 
      vardata(360:1439,:,:,:) = (/var(0:1079,:,:,:)/)

      do d = 3, ndys-4
        runmeandatedata(d-3) = (/datedata(d)/)               ;<=== output
        vartemp = new((/28,nlev,nS_N,nW_E/),"float")
        vartemp = (/vardata(4*(d-3):4*(d+3)+3,:,:,:)/)
        varrunmean(d-3,:,:,:) = dim_avg_n_Wrap(vartemp,0)    ;<=== output
        delete( vartemp )
      end do

      print( "year :" + (tyr-1) )

      ; Output
      system("rm -f "+outdir+"my_model.my_var_running_mean_data_Sep_Aug_"+(tyr-1)+".nc")
      fout = addfile(outdir+"my_model.my_var_running_mean_data_Sep_Aug_"+(tyr-1)+".nc","c")

      runmeandatedata@calendar = cal_attr
      runmeandatedata!0 = "dates"
      fileattdef(fout,fileAtt)

      varrunmean!0	= "days"
      varrunmean!1	= "nlev"
      varrunmean!2	= "nS_N"
      varrunmean!3	= "nW_E"

      varrunmean@_FillValue = var@_FillValue
      varrunmean@missing_value = var@missing_value

      ;printVarSummary(varrunmean)
      fout->my_var	= varrunmean
      fout->date	= runmeandatedata
      fout->lat2d	= lat
      fout->lon2d	= lon

      ; Clean-up
      delete( varleft )

    end if   ; ifil

;===================================================================================

    ; Store the "leftover" data
    varleft = new((/360,nlev,nS_N,nW_E/),"float")
    varleft = mo3data

    ;=============
    ; Clean-up
    delete( var )
    delete( vardata )
    delete( varrunmean )
    delete( datedata )
    delete( runmeandatedata )

  end do

  delete( ndys )

end
