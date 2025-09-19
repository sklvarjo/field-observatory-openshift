rm(list=ls(all=TRUE))

source("local_utils.R")

#json_data <- jsonlite::fromJSON("/data/sites.geojson", simplifyVector = FALSE)
#
## The features are stored as a list/data frame inside
#features <- json_data$features
#
## Loop through features
#for (i in features) {
#  props <- i$properties
#    for (s in props$data_sources) {
#    if (s$source_type == "icos") {
#      cat("  ID:", props$id, "\n")
#      cat("  source type:", s$source_type, "\n")
#      cat("    file:", s$source_config_file, "\n")
#      icos <- jsonlite::fromJSON(s$source_config_file)
#      cat("     - Site:", icos$icos_site_id, "\n")
#      cat("     - DL path:", icos$download_path, "\n")
#      cat("     - UI path:", icos$ui_path, "\n\n")
#    }
#  }
#}

sites <- c("BE-Lon", "DE-Geb", "DE-RuS", "FR-Gri", "IT-BCi")
uinames <- c("lonzee", "gebesee", "selhausen", "grignon", "cioffi")

for(site_i in seq_along(sites)){
  sitename <- sites[site_i]
  uiname <- uinames[site_i]
  
  outfolder <- paste0("/data/ICOS/", sitename, "/data")
  
  product <- "NRT"
  overwrite = TRUE
  
  # Sys.setenv(http_proxy = "http://wwwcache.fmi.fi:8080")
  # Sys.setenv(https_proxy = "http://wwwcache.fmi.fi:8080")
  
  download_file_flag <- TRUE
  extract_file_flag <- TRUE
  sitename <- sub(".* \\((.*)\\)", "\\1", sitename)
  
  output_file_name <- paste0("ICOSETC_", sitename, "_METEO_NRT.csv")
  
  zip_file_name <- paste0(outfolder, "/ICOSETC_", sitename, "_METEO_NRT.zip")
  nrtfluxes_zip_file_name <- paste0(outfolder, "/ICOSETC_", sitename, "_FLUXES_NRT.zip")
  
  data_type <- "http://meta.icos-cp.eu/resources/cpmeta/etcNrtMeteo"
  
  # NRT flux and meteo files are separate, but download flux file already now?
  nrtfluxes_data_type <- "http://meta.icos-cp.eu/resources/cpmeta/etcNrtFluxes"
  
  file_name <- paste0("ICOSETC_", sitename, "_METEO_NRT")
  
  nrtfluxes_file_name <- paste0("ICOSETC_", sitename, "_FLUXES_NRT")
  
  # ICOS SPARQL end point
  url <- "https://meta.icos-cp.eu/sparql?type=JSON"
 
  print("SPARQL")
  
  # RDF query to find out the information about the data set using the site name
  body <- "
  prefix cpmeta: <http://meta.icos-cp.eu/ontologies/cpmeta/>
  prefix prov: <http://www.w3.org/ns/prov#>
  select ?dobj ?spec ?timeStart ?timeEnd
  where {
  	VALUES ?spec {<data_type>}
  	?dobj cpmeta:hasObjectSpec ?spec .
  	VALUES ?station {<http://meta.icos-cp.eu/resources/stations/ES_sitename>}
  			?dobj cpmeta:wasAcquiredBy/prov:wasAssociatedWith ?station .
  ?dobj cpmeta:hasStartTime | (cpmeta:wasAcquiredBy / prov:startedAtTime) ?timeStart .
  ?dobj cpmeta:hasEndTime | (cpmeta:wasAcquiredBy / prov:endedAtTime) ?timeEnd .
  	FILTER NOT EXISTS {[] cpmeta:isNextVersionOf ?dobj}
  }
  "
  body <- gsub("sitename", sitename, body)
  
  nrtfluxes_body <- gsub("data_type", nrtfluxes_data_type, body)
  nrtfluxes_response <- httr::POST(url, body = nrtfluxes_body)
  nrtfluxes_response <- httr::content(nrtfluxes_response, as = "text")
  nrtfluxes_response <- jsonlite::fromJSON(nrtfluxes_response)
  nrt_ind <- which.max(as.Date(nrtfluxes_response$results$bindings$timeEnd$value)) # latest
  nrtfluxes_dataset_url <- nrtfluxes_response$results$bindings$dobj$value[nrt_ind]
  
  print("SPARQL done")

  body <- gsub("data_type", data_type, body)

  response <- httr::POST(url, body = body)
  response <- httr::content(response, as = "text")
  response <- jsonlite::fromJSON(response)
  
  nrt_ind <- which.max(as.Date(response$results$bindings$timeEnd$value))
  response$results$bindings <- response$results$bindings[nrt_ind, , drop=FALSE]
  
  dataset_url <- response$results$bindings$dobj$value
  
  dataset_start_date <-
    lubridate::as_datetime(
      strptime(response$results$bindings$timeStart$value, format = "%Y-%m-%dT%H:%M:%S")
    )
  dataset_end_date <-
    lubridate::as_datetime(
      strptime(response$results$bindings$timeEnd$value, format = "%Y-%m-%dT%H:%M:%S")
    )
  
  dataset_id <- sub(".*/", "", dataset_url)

  print("Download")

  # construct the download URL
  download_url <-
    paste0('https://data.icos-cp.eu/licence_accept?ids=%5B%22',
           dataset_id,
           '%22%5D')

  # Download the zip file
  file <-
    httr::GET(url = download_url,
              httr::write_disk(zip_file_name,
                               overwrite = TRUE),
              httr::progress())
  
  nrtfluxes_dataset_id <- sub(".*/", "", nrtfluxes_dataset_url)
  nrtfluxes_download_url <- paste0('https://data.icos-cp.eu/licence_accept?ids=%5B%22', nrtfluxes_dataset_id, '%22%5D')
  nrtfluxes_file <- httr::GET(url = nrtfluxes_download_url, httr::write_disk(nrtfluxes_zip_file_name,overwrite = TRUE), httr::progress())

  print("Extract")
  
  # extract only the hourly data file
  zipped_csv_name <-
    grep(
      paste0('*', file_name),
      utils::unzip(zip_file_name, list = TRUE)$Name,
      ignore.case = TRUE,
      value = TRUE
    )
  utils::unzip(zip_file_name,
               files = zipped_csv_name,
               junkpaths = TRUE,
               exdir = outfolder)
  
  
  nrtfluxes_zipped_csv_name <- grep(paste0('*', nrtfluxes_file_name),
                                    utils::unzip(nrtfluxes_zip_file_name, list = TRUE)$Name,
                                    ignore.case = TRUE,
                                    value = TRUE)
  utils::unzip(nrtfluxes_zip_file_name,
               files = nrtfluxes_zipped_csv_name,
               junkpaths = TRUE,
               exdir = outfolder)

  ############### Process for FO
  icossite_csv <- utils::read.csv(file.path(outfolder, zipped_csv_name))
  fo_var_map <- data.frame(fo_name=c("LongwaveDown", "LongwaveUp", "PAR", "ShortwaveDown", "ShortwaveUp", "TemperatureAir"),
                           icos_name=c("LW_IN", "LW_OUT", "PPFD_IN", "SW_IN", "SW_OUT", "TA"))
  all_dates <- lubridate::ymd_hm(icossite_csv$TIMESTAMP_START)
  all_years <- lubridate::year(all_dates)
  all_months <- lubridate::month(all_dates)
  these_years <- unique(all_years)
  for(i in seq_along(these_years)){
    year <- these_years[i]
    this_yr_months <- unique(all_months[all_years == year])
    for(mnth in this_yr_months){
      
      fo_file_name <- paste0("/data/field-observatory/ui-data/", uiname, "/meteo/",year, "-", sprintf("%02d", mnth), ".csv")
      
      # no need to reproduce previous years' months everytime
      # whole current year might still be useful?
      if(year != these_years[length(these_years)] & file.exists(fo_file_name)) next()
      
      PeriodStartUTC0   <- icossite_csv$TIMESTAMP_START[all_years == year & all_months == mnth]
      Precipitation     <- icossite_csv$P[all_years == year & all_months == mnth]
      # lonzee had some weird values for which we are filtering out, probably OK for other sites
      Precipitation[Precipitation > 37] <- NA 
      LongwaveDown      <- icossite_csv$LW_IN[all_years == year & all_months == mnth]
      LongwaveUp        <- icossite_csv$LW_OUT[all_years == year & all_months == mnth]
      NetRadiation      <- icossite_csv$NETRAD[all_years == year & all_months == mnth]
      PAR               <- icossite_csv$PPFD_IN[all_years == year & all_months == mnth]
      RelativeHumidity  <- icossite_csv$RH[all_years == year & all_months == mnth]
      ShortwaveDown     <- icossite_csv$SW_IN[all_years == year & all_months == mnth]
      ShortwaveUp       <- icossite_csv$SW_OUT[all_years == year & all_months == mnth]
      TemperatureAir    <- icossite_csv$TA[all_years == year & all_months == mnth]
      
      PeriodStartUTC0 <- paste0(substr(PeriodStartUTC0,1,4),"-", substr(PeriodStartUTC0,5,6), "-",substr(PeriodStartUTC0,7,8), "T",
                                substr(PeriodStartUTC0,9,10), ":", substr(PeriodStartUTC0,11,12), ":00.000000Z")
      all_dat <- cbind(PeriodStartUTC0, Precipitation, LongwaveDown, LongwaveUp, NetRadiation, PAR, RelativeHumidity, ShortwaveDown, ShortwaveUp, TemperatureAir)
      all_dat[all_dat == "-9999"] <- ""
      all_dat[is.na(all_dat)] <- ""
      write.csv(all_dat, file=fo_file_name, row.names = FALSE, quote = FALSE)
    }
  }
  
  icossite_csv <- utils::read.csv(file.path(outfolder, nrtfluxes_zipped_csv_name))
  all_dates <- lubridate::ymd_hm(icossite_csv$TIMESTAMP_START)
  all_years <- lubridate::year(all_dates)
  all_months <- lubridate::month(all_dates)
  these_years <- unique(all_years)
  for(i in seq_along(these_years)){
    year <- these_years[i]
    this_yr_months <- unique(all_months[all_years == year])
    for(mnth in this_yr_months){
      
      fo_file_name <- paste0("/data/field-observatory/ui-data/", uiname,"/ec/flux/",year, "-", sprintf("%02d", mnth), ".csv")
      
      # no need to reproduce previous years' months everytime
      if(year != these_years[length(these_years)] & file.exists(fo_file_name)) next()
      
      PeriodStartUTC0   <- icossite_csv$TIMESTAMP_START[all_years == year & all_months == mnth]
      CO2flux           <- icossite_csv$NEE[all_years == year & all_months == mnth]
      CO2flux[CO2flux==-9999] <- NA
      CO2flux <- local.convert(CO2flux,"umol C m-2 s-1","kg C m-2 s-1")
      CO2flux <- udunits2::ud.convert(CO2flux,"kg","mg")
      LatentHeatFlux   <- icossite_csv$LE[all_years == year & all_months == mnth]
      LatentHeatFlux[LatentHeatFlux==-9999] <- NA
      CO2flux_filtered <- CO2flux
      PeriodStartUTC0 <- paste0(substr(PeriodStartUTC0,1,4),"-", substr(PeriodStartUTC0,5,6), "-",substr(PeriodStartUTC0,7,8), "T",
                                substr(PeriodStartUTC0,9,10), ":", substr(PeriodStartUTC0,11,12), ":00.000000Z")
      PeriodEndUTC0 <- PeriodStartUTC0
      all_dat <- cbind(PeriodEndUTC0, CO2flux_filtered, LatentHeatFlux)
      all_dat[all_dat == "-9999"] <- ""
      all_dat[is.na(all_dat)] <- ""
      write.csv(all_dat, file=fo_file_name, row.names = FALSE, quote = FALSE)
    }
  }
  
} # end of loop over sites
