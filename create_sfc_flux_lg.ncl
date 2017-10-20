;;----------------------------------------------------------------------
;; create_sfc_flux_lg
;;
;; A routine to create surface net heat flux from hfls, hfss, rlus,
;; rsus, rlds, and rsds.
;;
;; 2017-10-09 Tomoko Koyama
;;----------------------------------------------------------------------

;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

rdiri       = "/work/koyama_sice"

model   = "IPSL-CM5A-LR"

begin

    ;; define input files
    srcGridDiri = rdiri + "/" + model
 
;;----------------------------------------------------------------------
;; Get data
;;----------------------------------------------------------------------

    hflsFili = "hfls_day_IPSL-CM5A-LR_rcp85_r1i1p1_20060101-22051231.rgrd.nc"
    hfssFili = "hfss_day_IPSL-CM5A-LR_rcp85_r1i1p1_20060101-22051231.rgrd.nc"
    rlusFili = "rlus_day_IPSL-CM5A-LR_rcp85_r1i1p1_20060101-22051231.rgrd.nc"
    rsusFili = "rsus_day_IPSL-CM5A-LR_rcp85_r1i1p1_20060101-22051231.rgrd.nc"
    rldsFili = "rlds_day_IPSL-CM5A-LR_rcp85_r1i1p1_20060101-22051231.rgrd.nc"
    rsdsFili = "rsds_day_IPSL-CM5A-LR_rcp85_r1i1p1_20060101-22051231.rgrd.nc"

    hflsfile   = addfile( srcGridDiri + "/" + hflsFili, "r" )
    hfssfile   = addfile( srcGridDiri + "/" + hfssFili, "r" )
    rlusfile   = addfile( srcGridDiri + "/" + rlusFili, "r" )
    rsusfile   = addfile( srcGridDiri + "/" + rsusFili, "r" )
    rldsfile   = addfile( srcGridDiri + "/" + rldsFili, "r" )
    rsdsfile   = addfile( srcGridDiri + "/" + rsdsFili, "r" )

    var1    = hflsfile->hfls(:3649,:,:)
    var2    = hfssfile->hfss(:3649,:,:)
    var3    = rlusfile->rlus(:3649,:,:)
    var4    = rsusfile->rsus(:3649,:,:)
    var5    = rldsfile->rlds(:3649,:,:)
    var6    = rsdsfile->rsds(:3649,:,:)

    lat     = hflsfile->lat
    lon     = hflsfile->lon
     
    outvar  = var1 + var2 + var3 + var4 + var5 + var6


    filo = "sfcnf_day_IPSL-CM5A-LR_rcp85_r1i1p1_20060101-20151231.rgrd.nc"
    system("rm -f "+srcGridDiri+filo)

    setfileoption("nc","format","netcdf4")
     
    print( "Output :"+srcGridDiri + "/" + filo)

    fout = addfile( srcGridDiri + "/" + filo,"c")

;---Define the dimension names and their sizes on the file
    dims    	= dimsizes(var1)
    dim_names   = getvardims(var1)
    dim_unlimited = (/ False , False, False /)
    filedimdef(fout,dim_names,dims,dim_unlimited)

;---Define each variable, its type, its dimension names, and its size
    filevardef(fout,"time",typeof(var1&time),"time")
    filevardef(fout,"i",typeof(var1&i),"i")
    filevardef(fout,"j",typeof(var1&j),"j")
    filevardef(fout,"sfcnf",typeof(var1),dim_names)
    filevardef(fout,"lat",typeof(lat),getvardims(lat))
    filevardef(fout,"lon",typeof(lon),getvardims(lon))

;---Define each variable's attributes.
    copy_VarAtts(outvar,var1)
    outvar@comment = "Summation of hfls, hfss, rlus, rsus, rlds, and rsds"
    outvar@original_name = "SFCNETFLX"
    outvar@units         = "W m-2"
    outvar@long_name     = "Surface Net Heat Flux"
    outvar@_FillValue    = 1.e+20
    outvar@missing_value = 1.e+20

    filevarattdef(fout,"time",var1&time)
    filevarattdef(fout,"i",var1&i)
    filevarattdef(fout,"j",var1&j)
    filevarattdef(fout,"sfcnf",outvar)
    filevarattdef(fout,"lat",lat)
    filevarattdef(fout,"lon",lon)

    fAtt		 = True
    fAtt@creation_date = systemfunc ("date")
    fAtt@created_by    = "Tomoko Koyama - tomoko.koyama@colorado.edu"
    fAtt@notes         = "Created with NCL script: create_sfc_flux.ncl"
    fileattdef (fout, fAtt )
;;----------------------------------------------------------------------
;; Write surface net het flux data to file
;;----------------------------------------------------------------------

    fout->sfcnf = (/outvar/)
    fout->lat  = (/lat/)
    fout->lon  = (/lon/)

    ;; Clean up
    delete( lon )
    delete( lat )
    delete( var1 )
    delete( var2 )
    delete( var3 )
    delete( var4 )
    delete( var5 )
    delete( var6 )
    delete( outvar )

    delete( hflsfile )
    delete( hfssfile )
    delete( rlusfile )
    delete( rsusfile )
    delete( rldsfile )
    delete( rsdsfile )
    delete( filo )
    delete( fout )
    
end
