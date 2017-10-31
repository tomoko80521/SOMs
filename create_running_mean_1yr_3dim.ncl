;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                            ;
; PROGRAM: create_running_mean_1yr_3dim                      ;
; PROGRAM DESCRIPTION: This program reads in 3-dimensional   ;
;    data (time x lat x lon), creates running weekly means   ;
;    from Sep - Aug.					     ;
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
      if (cal_attr .eq. "noleap") then
        bday = iday+365
      end if
      if (cal_attr .eq. "360_day") then
        bday = iday+360
      end if
      if (cal_attr .eq. "gregorian") then
        if isleapyear(byr+1) then
          bday = iday+366
        else
          bday = iday+365
        end if
      end if
    end if   ; iday
 
    ;---------------------------------------------------------------------- 
    do iyr=0,nyrs-1

      if (iday0 .gt. 0 ) then
        tyr = iyr + byr
      else
        tyr = iyr + byr +1
      end if    
      tyr@calendar	= cal_attr

    ; Number of days from Sep. 1 to the last day of Aug. (next year)
      if (cal_attr .eq. "noleap") then
        ndys = 365
      end if
      if (cal_attr .eq. "360_day") then
        ndys = 360
      end if
      if (cal_attr .eq. "gregorian") then
        if isleapyear(tyr+1) then
           ndys = 366
        else
           ndys = 365
        end if
      end if

; Data arrays
      ; daily data
      vardata = new((/ndys,nS_N,nW_E/),"float")

      ; weekly running mean for each day from Sep. 4 - Aug. 28
      varrunmean = new((/ndys-6,nS_N,nW_E/),"float")

; Dates arrays

      datedata 	= new(ndys,"integer")
      runmeandatedata 	= new((ndys-6),"integer")

;###
      if (cal_attr .ne. "gregorian") then
        dates_yr1 = new(ndys,"integer")
        dates_yr2 = new(ndys,"integer")
      else
        if isleapyear(tyr) then
          dates_yr1 = new(366,"integer")
        else
          dates_yr1 = new(365,"integer")
        end if      
        if isleapyear(tyr+1) then
          dates_yr2 = new(366,"integer")
        else
          dates_yr2 = new(365,"integer")
        end if      
      end if

      jdy = 0
      do while (jdy .lt. dimsizes(dates_yr1)) 
        dates_yr1(jdy) = tyr*10000 + monthday(tyr,jdy+1) 
        jdy = jdy + 1
      end do
      
      jdy = 0
      do while (jdy .lt. dimsizes(dates_yr2)) 
        dates_yr2(jdy) = (tyr+1)*10000 + monthday((tyr+1),jdy+1) 
        jdy = jdy + 1
      end do

     ; Assign dates
      if (cal_attr .eq. "noleap")
        datedata(0:121) = dates_yr1(243:364)
        datedata(122:364) = dates_yr2(0:242)
      end if

      if (cal_attr .eq. "360_day")
        datedata(0:119) = dates_yr1(240:359)
        datedata(120:359) = dates_yr2(0:239)
      end if

      if (cal_attr .eq. "gregorian")
        datedata(0:121) = dates_yr1((dimsizes(dates_yr1)-122):(dimsizes(dates_yr1)-1))
        datedata(122:(dimsizes(dates_yr2)-1)) = dates_yr2(0:(dimsizes(dates_yr2)-123))
      end if

      delete( dates_yr1 )
      delete( dates_yr2 )
 
;### 

;===================================================================================
; Store data extracted from the previous file
      if (ifil .gt. 0 .and. iyr .eq. 0 ) then

        if ( cal_attr .eq. "gregorian")
          delete( ndys )
          if isleapyear(tyr-1) then
            ndys = 366
          else
            ndys = 365
          end if
        end if

        predata = new((/ndys,nS_N,nW_E/),"float")
        predata(0:rdys-1,:,:) = (/varleft(0:rdys-1,:,:)/) 
        predata(rdys:ndys-1,:,:) = (/var(0:(ndys-1-rdys),:,:)/)

        predatedata	= new(ndys,"integer")
        prerunmeandatedata	= new((ndys-6),"integer")
;###
        if (cal_attr .ne. "gregorian") then
          dates_yr1 = new(ndys,"integer")
          dates_yr2 = new(ndys,"integer")
          predatedata	= new(ndys,"integer")
          prerunmeandatedata	= new((ndys-6),"integer")
        else
          if isleapyear(tyr-1) then
            dates_yr1 = new(366,"integer")
          else
            dates_yr1 = new(365,"integer")
          end if      
          if isleapyear(tyr) then
            dates_yr2 	= new(366,"integer")
            predatedata	= new(366,"integer")
            prerunmeandatedata	= new(360,"integer")
          else
            dates_yr2 = new(365,"integer")
            predatedata	= new(365,"integer")
            prerunmeandatedata	= new(359,"integer")
          end if      
        end if

        jdy = 0
        do while (jdy .lt. dimsizes(dates_yr1)) 
          dates_yr1(jdy) = (tyr-1)*10000 + monthday(tyr-1,jdy+1) 
          jdy = jdy + 1
        end do
      
        jdy = 0
        do while (jdy .lt. dimsizes(dates_yr2)) 
          dates_yr2(jdy) = tyr*10000 + monthday(tyr,jdy+1) 
          jdy = jdy + 1
        end do

     ; Assign dates
        if (cal_attr .eq. "noleap")
          predatedata(0:121) = dates_yr1(243:364)
          predatedata(122:364) = dates_yr2(0:242)
        end if

        if (cal_attr .eq. "360_day")
          predatedata(0:119) = dates_yr1(240:359)
          predatedata(120:359) = dates_yr2(0:239)
        end if

        if (cal_attr .eq. "gregorian")
          predatedata(0:121) = dates_yr1((dimsizes(dates_yr1)-122):(dimsizes(dates_yr1)-1))
          predatedata(122:(dimsizes(dates_yr2)-1)) = dates_yr1(0:(dimsizes(dates_yr2)-123))
        end if

        delete( dates_yr1 )
        delete( dates_yr2 )
;### 

        do d = 3, ndys-4
          prerunmeandatedata(d-3) = (/predatedata(d)/)               ;<=== output
          vartemp = new((/7,nS_N,nW_E/),"float")
          vartemp = (/predata(d-3:d+3,:,:)/)
          varrunmean(d-3,:,:) = dim_avg_n_Wrap(vartemp,0)    ;<=== output
          delete( vartemp )
        end do

        print( "year :" + (tyr-1) )

        ; Output
        system("rm -f "+outdir+"my_model.my_var_running_mean_data_Sep_Aug_"+(tyr-1)+".nc")
        fout = addfile(outdir+"my_model.my_var_running_mean_data_Sep_Aug_"+(tyr-1)+".nc","c")

	prerunmeandatedata@calendar = cal_attr
	prerunmeandatedata!0 = "dates"
	fileattdef(fout,fileAtt)

        varrunmean!0	= "days"
        varrunmean!1	= "nS_N"
        varrunmean!2	= "nW_E"

        varrunmean@_FillValue = var@_FillValue
        varrunmean@missing_value = var@missing_value

        ;printVarSummary(varrunmean)
	fout->my_var	= varrunmean
	fout->date	= prerunmeandatedata
	fout->lat2d	= lat
	fout->lon2d	= lon

	; Clean-up
        delete( predata )
        delete( varleft )
        delete( predatedata )
        delete( prerunmeandatedata )

      end if   ; ifil

;===================================================================================

      eday = bday+ndys-1
  
      ; Skip the data processing when one file has only one-year length
      if (eday .lt. nt) then 
      vardata(0:ndys-1,:,:) = (/var(bday:eday,:,:)/)

      do d = 3, ndys-4
          runmeandatedata(d-3) = (/datedata(d)/)                ;<=== output
          vartemp = new((/7,nS_N,nW_E/),"float")
          vartemp = (/vardata(d-3:d+3,:,:)/)
          varrunmean(d-3,:,:) = dim_avg_n_Wrap(vartemp,0)     ;<=== output
          delete( vartemp )
      end do

      runmeandatedata!0 = "dates"
 
      print( "year :" +tyr )

      ; Output
      system("rm -f "+outdir+"my_model.my_var_running_mean_data_Sep_Aug_"+tyr+".nc")
      fout = addfile(outdir+"my_model.my_var_running_mean_data_Sep_Aug_"+tyr+".nc","c")

      runmeandatedata@calendar = cal_attr
      fileattdef(fout,fileAtt)

      varrunmean!0	= "days"
      varrunmean!1	= "nS_N"
      varrunmean!2	= "nW_E"

      varrunmean@_FillValue = var@_FillValue
      varrunmean@missing_value = var@missing_value

      ;printVarSummary(varrunmean)
      fout->my_var	= varrunmean
      fout->date	= runmeandatedata
      fout->lat2d	= lat
      fout->lon2d	= lon

      bday = eday+1

      end if

      ;=============
      ; Store the "leftover" data
      if (bday+ndys-1 .gt. nt ) then
        rdys = nt-bday
        varleft= new((/rdys,nS_N,nW_E/),"float")
        varleft(0:rdys-1,:,:) = (/var(bday:nt-1,:,:)/)
        break
      end if
      ;=============

      delete( ndys )
      delete( vardata )
      delete( varrunmean )
      delete( datedata )
      delete( runmeandatedata )

    end do   ; iyr
    ;---------------------------------------------------------------------- 

    ; Clean-up
    delete( var )
    ;delete( datedata )
    ;delete( runmeandatedata )

  end do

end
