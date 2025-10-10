# this script is called by auto_fx script

# Olli Niemitalo and Istem agreed to invoke this once a day (using 0000 version) to reduce traffic

############
# this script fetches and processes ECMWF 15-day forecast for (many but not all) FO sites
# plus, reformats it for Qvidja in PEcAn format, so that it can be used in Basgra fx
#
# also:
# as a prototype for a side-project it also prepares drivers in PEcAn format for Viikki and ICOS NRT sites
# but unlike Qvidja, these are not being used in a fx-pipeline yet 
# so, everyday we generate unnecessary *.nc files for these sites under /data/istem/ICOS/data/***/ECMWF/
# maybe it's time to comment that part out but leaving it in place for now as a generalization

rm(list=ls(all=TRUE))


# 50 perturbed forecasts
library(lubridate)
sys_cmd <- "wget -P /data/ECMWF/ https://lake.fmi.fi/routines-data/input2istem/"
now_is <- as.POSIXlt(Sys.time(), tz = "UTC") #Sys.time()
file_get <- TRUE

if(hour(now_is) >= 8 & hour(now_is) < 20){
  # 00 run finishes at 8am UTC, latest file is 0000 today
  hour_is <- "0000"
  fc_filename <- paste0("fc",year(now_is), sprintf("%02d", month(now_is)), sprintf("%02d", day(now_is)), hour_is, ".csv")
  if(file.exists(paste0("/data/ECMWF/", fc_filename))) file_get <- FALSE
}else if(hour(now_is) >= 20 & hour(now_is) < 24){
  # 12 run finishes at 8pm UTC, latest file is 1200 today
  # we don't use this version anymore
  hour_is <- "1200"
  fc_filename <- paste0("fc",year(now_is), sprintf("%02d", month(now_is)), sprintf("%02d", day(now_is)), hour_is, ".csv")
  if(file.exists(paste0("/data/ECMWF/", fc_filename))) file_get <- FALSE
}else{
  # between 00 and 08, latest file is 1200 yesterday
  # we don't use this version anymore
  hour_is <- "1200"
  fc_filename <- paste0("fc",year(now_is), sprintf("%02d", month(now_is)), sprintf("%02d", day(now_is)-1), hour_is, ".csv")
  if(file.exists(paste0("/data/ECMWF/", fc_filename))) file_get <- FALSE
}

# the file becomes available on lake.fmi.fi sometime after noon everyday
# but sometimes it's late, best to run this script towards the end of the day, e.g. my cronjob runs at 5pm
# note that you don't want to run it much later in the day because then script fetches the 1200 file
# updating the script to only look for the 0000 file is always an option
if(file_get){
  ee <- system(paste0(sys_cmd, fc_filename))
}else{
  ee <- 8
}


if(!file.exists(paste0("/data/ECMWF/", fc_filename))){
  stop()
}else if(file.size(paste0("/data/ECMWF/", fc_filename)) < 180000000){
  # this is not a great check but if the file is too small it's probably corrupt
  stop()
}

sites <- read.csv("/data/istem/32fieldobs_ecmwf_sites.csv", header=TRUE)

# these are actually non-crop NRT sites from a previous side-project
# need to open a ticket to add new IRISCC cropland NRT sites: BE-Lon, DE-Geb, DE-RuS, FR-Gri, IT-BCi
icos_sites <- read.csv("/data/istem/ICOS/ICOS_NRT_Sites.csv") 

sitesx <- rbind(cbind(sites$Name, sites$lat, sites$lon),
                cbind(c(icos_sites$Sitename), c(icos_sites$Latitude), c(icos_sites$Longitude)))
colnames(sitesx) <- c("Name", "lat", "lon")
sites <- sitesx
sites <- as.data.frame(sites)
sites$lat <- as.numeric(sites$lat)
sites$lon <- as.numeric(sites$lon)

# not doing anything with Kumpula and Hahkiala
sites <- sites[-c(31,32),] # better not to hardcode these indices

# where should the PEcAn files be written to
# only for Qvidja fx
input_dir <- "/data/dbfiles/"

# TODO: query site IDs from DB, only for Qvidja for now
prefix_qfx <- "ECMWF_ENS_CF_site_1-26766"

outfolder <- paste0(input_dir, prefix_qfx, "/")

if (!file.exists(outfolder)) {
  dir.create(outfolder)
}
overwrite <- TRUE

#######################################

#if(ee !=0){
# if(FALSE){
#   
#   ## NOTE THIS BIT IS NEVER RUN, WAS ONLY DEVELOPING, OVERLAP IS TAKEN CARE OF BY OLLI NIEMITALO
#   
#   ### TODO: Make sure previous forecast is up if something went wrong with retrieving the new file
#   ### or if we just need to trim it on FO
#   for(i in seq_along(sites$site)){
#     sitename <- sites$Name[i]
#     #read
#     fc <- read.csv(paste0("/data/field-observatory/ui-data/", sitename, "/ecmwf_forecast/ecmwf_forecast.csv"))
#     
#     # undo obfuscation, otherwise you're trimming from the end (we've reversed)
#     
#     #trim
#     these_dates <- parse_date_time(fc$Date,"ymdHMS")
#     write_this  <- fc[these_dates > now_is,]
#     
#     #overwrite
#     write.csv(write_this, 
#               file= paste0("/data/field-observatory/ui-data/", sitename, "/ecmwf_forecast/ecmwf_forecast.csv"),
#               na = "", row.names = FALSE, quote = FALSE)
#     
#     #ping
#     uptime <- lubridate::format_ISO8601(file.info(paste0("/data/field-observatory/ui-data/",
#                                                          sitename, "/ecmwf_forecast/ecmwf_forecast.csv"))$mtime)
#     
#     py_tmp <- paste0("python /home/users/nevalaio/python/fieldobs/FMIDatasyncPython.py --path=",
#                      sitename, "/ecmwf_forecast/ecmwf_forecast.csv",
#                      "  --datetime=", uptime,
#                      ".0000000Z  --delete=no")
#     
#     system(py_tmp, wait=TRUE)
#   }
# }else{

#rest

#######################################

fc <- read.csv(paste0("/data/ECMWF/", fc_filename), header=TRUE)

if(hour(fc$origintime[1]) == 0){ # it will always be this now that we agree to work with this file only
  # whole day
  daily_ind <- c(1, rep(1:15, each=8))
}else if(hour(fc$origintime[1]) == 12){
  # mid-day
  daily_ind <- c(1, rep(1:16, each=8))
  daily_ind <- daily_ind[5:125]
}else{
  stop("SOMETHING WRONG")
}


# "T-K": 2t - 2 meter temperature https://apps.ecmwf.int/codes/grib/param-db/?id=167
# "RR-KGM2": tp - total precipitation https://apps.ecmwf.int/codes/grib/param-db/?id=228
# "U-MS": 10u - 10 metre U wind component https://apps.ecmwf.int/codes/grib/param-db/?id=165
# "V-MS": 10v - 10 metre V wind component https://apps.ecmwf.int/codes/grib/param-db/?id=166
# "RH-PRCNT": r - Relative humidity https://apps.ecmwf.int/codes/grib/param-db/?id=157
# "P-PA": sp - Surface pressure https://apps.ecmwf.int/codes/grib/param-db/?id=134
# 
# "RADGLOA-JM2" - ssrd - Surface solar radiation downwards https://apps.ecmwf.int/codes/grib/param-db/?id=169
# "RADLWA-JM2"  - strd - Surface thermal radiation downwards https://apps.ecmwf.int/codes/grib/param-db/?id=175

# q - Specific humidity https://apps.ecmwf.int/codes/grib/param-db/?id=133

# some lat/lon difference between mine and STUs
mytoler <- 0.00001

param_names <- unique(fc$param_name)
ens_members <- 1:50 # or unique(fc$forecast_type_value)

# i <- 21 for Qvidja
for(i in 1:41){ # or seq_along(sites$Name)
  sitename <- sites$Name[i]
  sub_site <- fc[abs(fc$longitude - sites$lon[i]) < mytoler & abs(fc$latitude - sites$lat[i]) < mytoler,] 
  if(length(unique(sub_site$longitude)) > 1 | length(unique(sub_site$latitude)) > 1){
    #something is wrong
    stop()
  }
  par_list <- vector("list", length(param_names)) 
  #loop over param_names
  for(pr in seq_along(param_names)){
    pname <- param_names[pr]
    sub_par <- sub_site[sub_site$param_name == pname,]
    # collect each ensemble
    ens_list <- lapply(ens_members, function(x){
      sub_ens <- sub_par[sub_par$forecast_type_value == x,]
      allsplit <- strsplit(sub_ens$forecast_period, ":")
      hourno <- as.numeric(as.character(do.call("rbind",allsplit)[,1]))
      ordered_sub_ens <- sub_ens[order(hourno),]
      return(ordered_sub_ens)
    })
    par_list[[pr]] <- ens_list
  }
  
  
  #################################################################################################################################
  #################################################################################################################################  
  #################################################################################################################################
  # calculate fractiles, obfuscate and write for FO
  
  # "T-K" : temperature (deg C)
  temp_ens_list <- par_list[[which(param_names == "T-K")]]
  temp_ens <- sapply(temp_ens_list,"[[", which(colnames(temp_ens_list[[1]]) == "value"))
  temp_qtl <- apply(temp_ens, 1, quantile, c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm=TRUE)
  temp_qtl <- udunits2::ud.convert(temp_qtl, "K", "degC")
  rownames(temp_qtl) <- c("Temperature_F010", "Temperature_F025", "Temperature_F050", 
                          "Temperature_F075", "Temperature_F090")
  #boxplot(temp_qtl, main =i)
  
  # "RR-M" : precipitation to (mm/hour) and (mm/30min)
  pre_ens_list <- par_list[[which(param_names == "RR-M")]]
  pre_ens <- sapply(pre_ens_list,"[[", which(colnames(pre_ens_list[[1]]) == "value"))
  pre_ens <- t(pre_ens)
  foo <- sapply(1:nrow(pre_ens), function(x){
    pre_ens[x,!is.na(pre_ens[x,])] <- c(pre_ens[x,1], diff(pre_ens[x,!is.na(pre_ens[x,])]))
    pre_ens[x,] <- udunits2::ud.convert(pre_ens[x,], "m", "mm")
    pre_ens[x,][pre_ens[x,] < 0] <- 0 # shouldn't be negative, probably some rounding problem
    pre_ens[x,seq(3,49, by=2)] <- tapply(pre_ens[x,1:49], c(2, rep(seq(2,49, by=2), each=2)), sum)
    pre_ens[x,c(1,seq(2,49, by=2))] <- NA
    return(pre_ens[x,])
  }) # mm 
  
  #boxplot(t(foo)*1000*60*60)
  prec_qtl <- apply(foo, 1, quantile,c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm=TRUE)
  
  # mm / 6 hr
  TotalPrecipitation_integrationTime <- c(rep(-1000*60*60*6, 121)) #in miliseconds
  
  #prec_qtl[, 62:121] <- prec_qtl[, 62:121] * 2
  rownames(prec_qtl) <- c("TotalPrecipitation_F010", "TotalPrecipitation_F025", "TotalPrecipitation_F050", 
                          "TotalPrecipitation_F075", "TotalPrecipitation_F090")
  #boxplot(prec_qtl, main =i)
  
  # "RH-PRCNT" : Relative Humidty (%)
  rh_ens_list <- par_list[[which(param_names == "RH-PRCNT")]]
  rh_ens <- sapply(rh_ens_list,"[[", which(colnames(rh_ens_list[[1]]) == "value"))
  
  #more often than not RH fx has a problem
  if(sum(is.na(rh_ens)) > 2500){ #1887 normal
    zzz<-  sapply(seq_len(ncol(rh_ens)), function(x){
      interp <- spline(temp_ens[,x],n=length(temp_ens[,1]),method = "periodic")
      tmpi <- interp$y
      interp <- spline(tmpi,rh_ens[,x],length(temp_ens[,1]),method = "periodic")
      rhi <- interp$y
      rhi[rhi >100] <- 100
      rhi[rhi <  0] <- 0
      rhi[is.na(temp_ens[,x])] <- NA
      rhi[!is.na(rh_ens[,x])] <- rh_ens[!is.na(rh_ens[,x]),x]
      return(rhi)
    })
    rh_ens <- zzz 
  }
  
  rh_qtl <- apply(rh_ens, 1, quantile,c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm=TRUE)
  rownames(rh_qtl) <- c("RelativeHumidity_F010", "RelativeHumidity_F025", "RelativeHumidity_F050", 
                        "RelativeHumidity_F075", "RelativeHumidity_F090")
  #boxplot(rh_qtl, main =i)
  
  # "RADGLOA-JM2" : JM2 -> "W m-2" -> "mol m-2 s-1"  MJ m-2 day-1 PAR
  rg_ens_list <- par_list[[which(param_names == "RADGLOA-JM2")]]
  rg_ens <- sapply(rg_ens_list,"[[", which(colnames(rg_ens_list[[1]]) == "value"))
  rg_ens <- t(rg_ens)
  
  bar <- sapply(1:nrow(rg_ens), function(x){
    rg_ens[x,!is.na(rg_ens[x,])] <- c(rg_ens[x,2], diff(rg_ens[x,!is.na(rg_ens[x,])]))
    rg_ens[x,][rg_ens[x,] < 0] <- 0
    rg_ens[x, 1:49]   <- rg_ens[x, 1:49]   / (3*60*60)
    rg_ens[x, 50:121] <- rg_ens[x, 50:121] / (6*60*60)
    return(rg_ens[x,])
  }) # W m-2
  rg_qtl <- apply(bar, 1, quantile,c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm=TRUE)
  
  if(sitename %in% c("qvidja", "ruukki", "haltiala", "viikki", c(icos_sites$Sitename))){ # umol m-2 s-1 
    #umol  #PAR
    par_qtl <- rg_qtl * 4.56 * 0.5
    #par_qtl[, 62:121] <- par_qtl[, 62:121] * 2
    PAR_integrationTime <- c(rep(-1000*60*60*3, 49), rep(-1000*60*60*6, 72)) #in miliseconds
    
    rownames(par_qtl) <- c("PAR_umol_F010", "PAR_umol_F025", "PAR_umol_F050", "PAR_umol_F075", "PAR_umol_F090")
    
  }else{ # MJ m-2 day-1
    #MJ       #day     #PAR
    #par_qtl <- rg_qtl * 1e-6 * (24*60*60) * 0.5 
    
    #MJ   #PAR
    par_qtl <- rg_qtl * 1e-6 * 0.5 
    par_qtl[, 1:49] <- par_qtl[, 1:49] * (3*60*60) 
    par_qtl[, 50:121] <- par_qtl[, 50:121] * (6*60*60) #every second is NA, otherwise I could multiply everything by 3
    PAR_integrationTime <- c(rep(-1000*60*60*24, 121)) #in miliseconds
    
    #this sum is necessary just get compatible per day values
    for(ncip in 1:nrow(par_qtl)){
      per_day <- tapply(par_qtl[ncip,], daily_ind, sum, na.rm=TRUE)
      rep_par <- c(per_day[1], rep(per_day, each=8))
      easy_na <- c(NA, rep(c(rep(NA,7), 0), 15))
      par_qtl[ncip,] <- rep_par+easy_na
      # if(daily_ind[length(daily_ind)]==15){
      #   par_qtl[ncip,] <- c(per_day[1], rep(per_day, each=8))
      # }else{
      #   willcrop <- c(per_day[1], rep(per_day, each=8))
      #   par_qtl[ncip,] <- willcrop[5:125]
      # }
    }
    rownames(par_qtl) <- c("PAR_MJ_F010", "PAR_MJ_F025", "PAR_MJ_F050", "PAR_MJ_F075", "PAR_MJ_F090")
  }
  
  #boxplot(par_qtl, main =i)
  
  # per Olli's request we are having a slightly different structure for different variables
  # temperature and relative humidity go together
  fx_df <- as.data.frame(t(temp_qtl))
  origin_dt <- as.POSIXct(strptime(par_list[[1]][[1]]$origintime[1], "%Y-%m-%d %H:%M:%S"), tz="UTC") 
  allsplit  <- strsplit(par_list[[1]][[1]]$forecast_period, ":")
  hourno <- as.numeric(as.character(do.call("rbind",allsplit)[,1]))
  Date <- origin_dt + hourno*60*60
  #Date <- paste0(lubridate::format_ISO8601(lubridate::ymd_hms(Date)), ".000000Z")
  Date <- paste0(lubridate::format_ISO8601(Date), ".000000Z")
  
  
  fx_df <- cbind(Date, fx_df, 
                 as.data.frame(t(rh_qtl)))
  
  filter_allNAs <- function(thedf, integtime=NULL){
    #Filter all NA rows per request by Olli Niemitalo
    rmv_ind <- c()
    for(rci in 1:nrow(thedf)){
      if(all(is.na(thedf[rci, -1]))) rmv_ind <- c(rmv_ind, rci)
    }
    thedf <- thedf[-rmv_ind,]
    
    if(!is.null(integtime)) integtime <- integtime[-rmv_ind]
    return(list(thedf=thedf, integtime=integtime))
  }
  
  fx_df <- filter_allNAs(fx_df)$thedf
  
  pre_df <- cbind(Date, as.data.frame(t(prec_qtl)))
  res <- filter_allNAs(pre_df, TotalPrecipitation_integrationTime)
  pre_df <- res$thedf
  TotalPrecipitation_integrationTime <- res$integtime
  colnames(pre_df)[1] <- "Date_TotalPrecipitation"
  
  par_df <- cbind(Date, as.data.frame(t(par_qtl)))
  res <- filter_allNAs(par_df, PAR_integrationTime)
  par_df <- res$thedf
  PAR_integrationTime <- res$integtime
  if(sitename %in% c("qvidja", "ruukki", "haltiala", "viikki", c(icos_sites$Sitename))){
    colnames(par_df)[1] <- "Date_PAR_umol"
  }else{
    colnames(par_df)[1] <- "Date_PAR_MJ"
  }
  
  
  obfuscating <- function(thedf){
    thename <- colnames(thedf)[1]
    #reverse
    thedf <- as.data.frame(cbind(thedf[, 1], apply(thedf[, 2:ncol(thedf)],2,rev)))
    #cumsum
    for(nci in 2:ncol(thedf)){
      thedf[!is.na(thedf[, nci]), nci] <- cumsum(as.numeric(thedf[, nci]))
    }
    colnames(thedf)[1] <- thename
    return(thedf)
  }
  
  # just a hack for small gaps in relative humidity
  if(sum(is.na(fx_df$RelativeHumidity_F010)) < 13 & sum(is.na(fx_df$RelativeHumidity_F010)) > 1){
    indx <- which(is.na(fx_df$RelativeHumidity_F010))
    fx_df$RelativeHumidity_F010[is.na(fx_df$RelativeHumidity_F010)] <- mean(c(fx_df$RelativeHumidity_F010[indx[1]-1],
                                                                              fx_df$RelativeHumidity_F010[indx[length(indx)]+1]))
    fx_df$RelativeHumidity_F025[is.na(fx_df$RelativeHumidity_F025)] <- mean(c(fx_df$RelativeHumidity_F025[indx[1]-1],
                                                                              fx_df$RelativeHumidity_F025[indx[length(indx)]+1]))
    fx_df$RelativeHumidity_F050[is.na(fx_df$RelativeHumidity_F050)] <- mean(c(fx_df$RelativeHumidity_F050[indx[1]-1],
                                                                              fx_df$RelativeHumidity_F050[indx[length(indx)]+1]))
    fx_df$RelativeHumidity_F075[is.na(fx_df$RelativeHumidity_F075)] <- mean(c(fx_df$RelativeHumidity_F075[indx[1]-1],
                                                                              fx_df$RelativeHumidity_F075[indx[length(indx)]+1]))
    fx_df$RelativeHumidity_F090[is.na(fx_df$RelativeHumidity_F090)] <- mean(c(fx_df$RelativeHumidity_F090[indx[1]-1],
                                                                              fx_df$RelativeHumidity_F090[indx[length(indx)]+1]))
  }
  if(is.na(fx_df$RelativeHumidity_F010[1])){ # a small hack, if first val is missing
    if(!is.na(fx_df$RelativeHumidity_F010[2])){
      fx_df$RelativeHumidity_F010[1] <- fx_df$RelativeHumidity_F010[2]
      fx_df$RelativeHumidity_F025[1] <- fx_df$RelativeHumidity_F025[2]
      fx_df$RelativeHumidity_F050[1] <- fx_df$RelativeHumidity_F050[2]
      fx_df$RelativeHumidity_F075[1] <- fx_df$RelativeHumidity_F075[2]
      fx_df$RelativeHumidity_F090[1] <- fx_df$RelativeHumidity_F090[2]
    }
  }
  
  fx_df <- obfuscating(fx_df)
  
  pre_df <- obfuscating(pre_df)
  pre_df$TotalPrecipitation_integrationTime <- TotalPrecipitation_integrationTime
  
  par_df <- obfuscating(par_df)
  if(sitename %in% c("qvidja", "ruukki", "haltiala", "viikki",c(icos_sites$Sitename))){
    par_df$PAR_umol_integrationTime <- PAR_integrationTime
  }else{
    par_df$PAR_MJ_integrationTime <- PAR_integrationTime
  }
  
  completing_wNAs <- function(thedf, this_nrow){
    n_nrow <- this_nrow - nrow(thedf) 
    c_mat <- matrix(NA, nrow=n_nrow, ncol=ncol(thedf))
    colnames(c_mat) <- colnames(thedf)
    thedf <- rbind(thedf, c_mat)
    return(thedf)
  }
  pre_df <- completing_wNAs(pre_df, nrow(fx_df))
  par_df <- completing_wNAs(par_df, nrow(fx_df))
  
  # obfuscate, only the mid keep date and integration time cols in original
  # reverse
  write_this <- as.data.frame(cbind(fx_df, pre_df, par_df))
  
  
  # if(!(sitename %in% c("qvidja", "ruukki"))){
  #   write_this <- write_this[,-(ncol(write_this))]
  # }
  
  if(!(sitename %in% c(icos_sites$Sitename))){
    write.csv(write_this, 
              file= paste0("/data/field-observatory/ui-data/", sitename, "/ecmwf_forecast/ecmwf_15day_forecast.csv"),
              na = "", row.names = FALSE, quote = FALSE)
  }
  
  
  # LET GENERIC AZURE PING TAKE CARE OF THIS, PING NEEDS TO COME AFTER BUCKET SYNC
  # uptime <- lubridate::format_ISO8601(file.info(paste0("/data/field-observatory/ui-data/",
  #                                                      sitename, "/ecmwf_forecast/ecmwf_forecast.csv"))$mtime)
  # 
  # py_tmp <- paste0("python /home/users/nevalaio/python/fieldobs/FMIDatasyncPython.py --path=",
  #                  sitename, "/ecmwf_forecast/ecmwf_forecast.csv",
  #                  "  --datetime=", uptime,
  #                  ".0000000Z  --delete=no")
  # 
  # system(py_tmp, wait=TRUE)
  # Sys.sleep(0.5)
  
  
  ################################################################################################################################
  ################################################################################################################################
  ################################################################################################################################
  # DO SOMETHING ELSE WITH THE ORIGINALS
  # e.g. write out to ECMWF directories as netcdf, insert DB?
  
  foo <- sapply(1:nrow(pre_ens), function(x){
    pre_ens[x,!is.na(pre_ens[x,])] <- c(pre_ens[x,1], diff(pre_ens[x,!is.na(pre_ens[x,])]))
    pre_ens[x,] <- udunits2::ud.convert(pre_ens[x,], "m", "mm")
    pre_ens[x,][pre_ens[x,] < 0] <- 0 # shouldn't be negative, probably some rounding problem
    return(pre_ens[x,])
  }) # mm 
  
  bar <- sapply(1:nrow(rg_ens), function(x){
    rg_ens[x,!is.na(rg_ens[x,])] <- c(rg_ens[x,2], diff(rg_ens[x,!is.na(rg_ens[x,])]))
    rg_ens[x,][rg_ens[x,] < 0] <- 0
    return(rg_ens[x,])
  }) 
  
  # u-component
  u_ens_list <- par_list[[which(param_names == "U-MS")]]
  u_ens <- sapply(u_ens_list,"[[", which(colnames(u_ens_list[[1]]) == "value"))
  
  # v-component
  v_ens_list <- par_list[[which(param_names == "V-MS")]]
  v_ens <- sapply(v_ens_list,"[[", which(colnames(v_ens_list[[1]]) == "value"))
  
  #Surface pressure
  pres_ens_list <- par_list[[which(param_names == "P-PA")]]
  pres_ens <- sapply(pres_ens_list,"[[", which(colnames(pres_ens_list[[1]]) == "value"))
  
  every2 <- rep(1:60, each=2)
  
  if(sitename %in% c("qvidja", "viikki", c(icos_sites$Sitename))){
    # like said at the beginning, we are writing netcdf files for all of these sites
    # but only for Qvidja we actually use them downstream
    
    # TODO: create s FO-sitegroup in BETYdb
    
    ## create lat lon time dimensions
    latdim  <- ncdf4::ncdim_def(name = "latitude", "degrees_north", as.double(sites$lat[i]))
    londim  <- ncdf4::ncdim_def(name = "longitude", "degrees_east", as.double(sites$lon[i]))
    timedim <- ncdf4::ncdim_def("time", paste0("days since ", origin_dt-24*60*60, sep = ""), 
                                seq_len(sum(!is.na(write_this$Date_TotalPrecipitation)))/4) # writing 6 hrly
    
    fxstartdate <- substr(write_this$Date_TotalPrecipitation[1],1,10)
    fxenddate   <- substr(write_this$Date_TotalPrecipitation[sum(!is.na(write_this$Date_TotalPrecipitation))-1],1,10) # -1 because it goes next day's 0000
    
    xytdim <- list(londim, latdim, timedim)
    
    # in Willow Creek fx example, each ensemble member is in their own directory/file
    # e.g. NOAA_GEFS_CF_gapfill_site_0-676, then NOAA_GEFS.1 NOAA_GEFS.2 NOAA_GEFS.3 ....
    # each file is saved? should I overwrite? 
    # NOAA_GEFS.Willow Creek (US-WCr).9.2020-04-23.2020-05-09.nc
    qvimet_paths <- rep(NA,50)
    for(ens_i in 1:50){
      
      prefix_folder <- paste0("ECMWF_ENS.", ens_i)
      
      
      if(sitename == "qvidja"){
        if (!file.exists(file.path(outfolder, prefix_folder))) {
          dir.create(file.path(outfolder, prefix_folder))
        }
        prefix_fl <- "ECMWF_ENS-Qvidja"
        # create the filename
        new.file <- paste0(outfolder, "/", prefix_folder, "/", prefix_fl, ".", ens_i, ".", fxstartdate, "-", fxenddate, ".nc")
      }else{
        if (!file.exists(file.path("/data/istem/ICOS/data",sitename, "ECMWF",prefix_folder))) {
          dir.create(file.path("/data/istem/ICOS/data/", sitename,"ECMWF", prefix_folder))
        }
        prefix_fl <- paste0("ECMWF_ENS-", sitename)
        new.file <- paste0("/data/istem/ICOS/data/",sitename, "/ECMWF/", prefix_folder, "/", prefix_fl, ".", ens_i, ".", fxstartdate, "-", fxenddate, ".nc")
        
      }
      
      qvimet_paths[ens_i] <- new.file
      if(!overwrite & file.exists(new.file)){
        next()
      }
      
      ## "T-K" => air_temperature (K) 
      air_temperature <- temp_ens[-1, ens_i]
      # 6hrly means take mean every subsequent pair
      air_temperature <- tapply(air_temperature, every2, mean, na.rm = TRUE)
      airT.var <- ncdf4::ncvar_def(name = "air_temperature", units = "K", dim = xytdim)
      nc <- ncdf4::nc_create(new.file, vars = airT.var)  #create netCDF file
      ncdf4::ncvar_put(nc, varid = airT.var, vals = air_temperature)
      
      # mm/6hr => precipitation_flux (kg m-2 s-1)
      precipitation_flux <- foo[-1, ens_i]
      daily_precip <- tapply(precipitation_flux, rep(1:15, each=8), sum, na.rm = TRUE)
      # rain a little every 6 hours
      precipitation_flux <- rep(daily_precip/4, each=4)
      precipitation_flux <- precipitation_flux / (60*60*6)
      precip.var <- ncdf4::ncvar_def(name = "precipitation_flux", units = "kg m-2 s-1", dim = xytdim)
      nc <- ncdf4::ncvar_add(nc = nc, v = precip.var, verbose = FALSE)
      ncdf4::ncvar_put(nc, varid = precip.var, vals = precipitation_flux)
      
      # "RH-PRCNT" : Relative Humidty (%)
      relative_humidity <- rh_ens[-1, ens_i]
      relative_humidity <- tapply(relative_humidity, every2, mean, na.rm = TRUE)
      RH.var <- ncdf4::ncvar_def(name = "relative_humidity", units = "%", dim = xytdim)
      nc <- ncdf4::ncvar_add(nc = nc, v = RH.var, verbose = FALSE)
      ncdf4::ncvar_put(nc, varid = RH.var, vals = relative_humidity)
      
      # surface_downwelling_shortwave_flux_in_air (W m-2)
      surface_downwelling_shortwave_flux_in_air <- bar[-1, ens_i]
      surface_downwelling_shortwave_flux_in_air <- tapply(surface_downwelling_shortwave_flux_in_air, every2, sum, na.rm = TRUE)
      surface_downwelling_shortwave_flux_in_air <- surface_downwelling_shortwave_flux_in_air / (6*60*60)
      Rg.var <- ncdf4::ncvar_def(name = "surface_downwelling_shortwave_flux_in_air", units = "W m-2", dim = xytdim)
      nc <- ncdf4::ncvar_add(nc = nc, v = Rg.var, verbose = FALSE)
      ncdf4::ncvar_put(nc, varid = Rg.var, vals = surface_downwelling_shortwave_flux_in_air)
      
      # eastward_wind
      eastward_wind <- u_ens[-1, ens_i]
      eastward_wind <- tapply(eastward_wind, every2, mean, na.rm = TRUE)
      U.var <- ncdf4::ncvar_def(name = "eastward_wind", units = "m s-1", dim = xytdim)
      nc <- ncdf4::ncvar_add(nc = nc, v = U.var, verbose = FALSE)
      ncdf4::ncvar_put(nc, varid = U.var, vals = eastward_wind)
      
      # northward_wind
      northward_wind <- v_ens[-1, ens_i]
      northward_wind <- tapply(northward_wind, every2, mean, na.rm = TRUE)
      V.var <- ncdf4::ncvar_def(name = "northward_wind", units = "m s-1", dim = xytdim)
      nc <- ncdf4::ncvar_add(nc = nc, v = V.var, verbose = FALSE)
      ncdf4::ncvar_put(nc, varid = V.var, vals = northward_wind)
      
      # air_pressure (Pa)
      air_pressure <- pres_ens[-1, ens_i]
      air_pressure <- tapply(air_pressure, every2, mean, na.rm = TRUE)
      Pres.var <- ncdf4::ncvar_def(name = "air_pressure", units = "Pa", dim = xytdim)
      nc <- ncdf4::ncvar_add(nc = nc, v = Pres.var, verbose = FALSE)
      ncdf4::ncvar_put(nc, varid = Pres.var, vals = air_pressure)
      
      ncdf4::nc_close(nc)
    }  # For now for Qvidja only
    
    # stupid hack-fix: of course qvimet_paths are overwritten for others sites after i>21
    if(sitename %in% "qvidja"){
      real_qvimet_paths <- qvimet_paths
    }
    
  }
}#loop over sites


# this is used by basgra forecasting script (auto_fx)
qvimet_paths <-  real_qvimet_paths

