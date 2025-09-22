#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""! @brief Python program to fetch the meteorological data from FMI."""

##
# @section author_run Author(s)
# - Created by varjonen on 09/02/2023
#
# @section notes_run Notes
# - You can give this one command line argument which is the path
#   pointing to /data/field-observatory/
##
import datetime
from dateutil.relativedelta import relativedelta
import logging
from logging.handlers import RotatingFileHandler
import os
import requests
import sys
import time

#Checks if command line argument and if it is a path that can be used
base_dir = "/data/field-observatory/"
if len(sys.argv) > 1:
    base_dir = sys.argv[1]
    if os.path.exists(base_dir) == False:
        sys.exit("Given base path does not exist: {}".format(base_dir))

#basic files
site_file = base_dir + "fieldobs_sites.csv"
site_file_d = base_dir + "fieldobs_daily_fmimeteo_sites.csv"
starttime = "2022-12-01"

url = 'http://smartmet.fmi.fi/timeseries'

#Setup logging
if base_dir == "/data/field-observatory/":
    FORMAT = '[%(levelname)s] %(message)s'
else:
    FORMAT = '%(asctime)-15s - [%(levelname)s] %(message)s'
logger = logging.getLogger("run_datasense_update")
log_level = os.getenv("LOG_LEVEL")
if log_level == None:
    logger.setLevel(logging.INFO)
else:
    if log_level in ("CRITICAL ERROR WARNING INFO DEBUG NOTSET"):
        logger.setLevel(log_level.upper())
    else:
        logger.setLevel(logging.INFO)
formatter = logging.Formatter(FORMAT)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(formatter)
logging.basicConfig(handlers=[handler], format=FORMAT)

def _get_measurements(fmisid, start_t, end_t, daily=False):
    """! This gets the measurements from the smartmet server by using the API
         provided by smartmet plugin timeseries
    @param fmisid FMI site ID
    @param start_time Start time
    @param end_time End time
    @param daily Do we only get daily aggregates

    @return ASCII CSV of the results
    """

    timestep = "data"
    if daily:
        timestep = "1440"
    payload = {
      "fmisid": f"{fmisid}",
      "producer": "observations_fmi",
      "param":  "localtime," \
                "N_MAN," \
                "P_SEA," \
                "R_1H," \
                "RH," \
                "RI_10MIN," \
                "SNOW_AWS," \
                 "T2M," \
                 "TD," \
                 "VIS," \
                 "WAWA," \
                 "WD_10MIN," \
                 "WG_10MIN," \
                 "WS_10MIN",
       "starttime": f"{start_t}",
       "endtime": f"{end_t}",
       "timestep": f"{timestep}",
       "timeformat": "xml",
       "separator": ",",
       "format": "ascii"
     }
    r = requests.get(url, params=payload)
    asciicsv='"Time","CloudAmount","Pressure","PrecipitationAmount","RelativeHumidity",'
    asciicsv=asciicsv+'"PrecipitationIntensity","SnowDepth","AirTemperature","DewPointTemperature",'
    asciicsv=asciicsv+'"Visibility","CurrentWeather","WindDirection","WindGust","WindSpeed"\n'
    asciicsv=asciicsv+f"{r.text}"
    return asciicsv

def _init_path(base, site, daily=False):
    """! Initialize the path string for writing the observation files
    @param base The base directory path.
    @param site Which site it is
    @param daily Are we going to write dailies

    @return the path
    """
    path = f"{base}observations/{site}/fmimeteo/observations"
    if daily:
        path = path + "-daily/"
    else:
        path = path + "/"
    return path

def get_sites_from_conf(conf):
    """! Reads the configuration file and parses an array of site names and fmisids from it
    @param conf Configuration file to read

    @return An array with tuples of sitename and fmisid
    """
    sites = []
    lines = list(open(conf))
    for line in lines:
        if "Name" in line:
            continue
        site = line.split(",")[0]
        fmisid = line.split(",")[7]
        sites.append((site,fmisid))
    return sites

def create_dirs(sites, base, daily=False):
    """! Creates the directories for the sites.
    @param sites The sites array.
    @param base The base directory path.
    @param daily Are the daily observations directories created, defaults to false.
    """
    for i in sites:
        site = i[0]
        path_obs = _init_path(base, site, daily=False)
        path_obs_d = _init_path(base, site, daily=True)
        if os.path.exists(path_obs) == True:
            logger.info(f"Path exists: {path_obs}")
        else:
            logger.info(f"Create path: {path_obs}")
            os.makedirs(path_obs)
        if daily == True:
            if os.path.exists(path_obs_d) == True:
                logger.info(f"Daily path exists: {path_obs_d}")
            else:
                logger.info(f"Create daily path: {path_obs_d}")
                os.makedirs(path_obs_d)

def _loop_and_write(site_dir, fmisid, datetime_start, datetime_end, daily=False):
    """! Initializes the data, i.e. gets the data that creates the first files to the folders.
    @param site_dir Path to write folder.
    @param fmisid FMI site ID.
    @param datetime_start The start time for the data.
    @param datetime_end The end time for the data.
    @param daily Is this run for daily aggregates, defaults to false.
    """
    datetime_iter = datetime_start
    while datetime_end > datetime_iter:
        datetime_iter_end = datetime_iter+relativedelta(months=1)-relativedelta(seconds=1)
        results = _get_measurements(fmisid, \
                                    datetime_iter.strftime("%Y-%m-%dT%H:%M:%S"), \
                                    datetime_iter_end.strftime("%Y-%m-%dT%H:%M:%S"), \
                                    daily=daily)
        path = f"{site_dir}{datetime_iter.year}-{datetime_iter.month}.csv"
        with open(path, 'w') as f:
                f.write(results)
                logger.info(f"Wrote file {path}")
        datetime_iter = datetime_iter+relativedelta(months=1)
        time.sleep(5)

def init_data(sites, base, start, end, daily=False):
    """! Initializes the data, i.e. gets the data that creates the first files to the folders.
    @param sites The sites array.
    @param base The base directory path.
    @param start The start time for the data.
    @param end The end time for the data.
    @param daily Is this run for daily aggregates, defaults to false.
    """
    for i in sites:
        site = i[0]
        fmisid = i[1]
        site_dir = _init_path(base, site, daily=daily)
        marker = ""
        if daily:
            marker = "Daily "
        logger.info(f"{marker}site: {site}, FMIs ID: {fmisid}".capitalize())
        count = len(os.listdir(site_dir))
        if count > 0:
            logger.info(f"{marker}folder has files, skip init...".capitalize())
            continue
        #take the given time and loop around it in complete months
        datetime_start = datetime.datetime.strptime(start, '%Y-%m-%dT%H:%M:%S')
        datetime_end = datetime.datetime.strptime(end, '%Y-%m-%dT%H:%M:%S')
        _loop_and_write(site_dir, fmisid, datetime_start, datetime_end)

def update_data(sites, base, daily=False):
    """! Updates the data, i.e. Looks from the folder the last file and 
         its date and starts from there to today.
    @param sites The sites array.
    @param base The base directory path.
    @param daily Is this run for daily aggregates, defaults to false.
    """
    for i in sites:
        site = i[0]
        fmisid = i[1]
        site_dir = _init_path(base, site, daily=daily)
        marker = ""
        if daily:
            marker = "Daily "
        logger.info(f"{marker}site: {site}, FMI site ID: {fmisid}".capitalize())
        files = sorted(os.listdir(site_dir))
        count = len(files)
        if count == 0:
            logger.error(f"{marker}folder had no files, odd...".capitalize())
            continue
        last_file = files[count-1]
        year = last_file.split("-")[0]
        month = last_file.split("-")[1].split(".")[0]
        logger.info(f"{marker}update starts from {year}/{month}")
        datetime_start = datetime.datetime.strptime(f"{year}-{month}-01T00:00:00", '%Y-%m-%dT%H:%M:%S')
        datetime_end = datetime.datetime.today()
        _loop_and_write(site_dir, fmisid, datetime_start, datetime_end)

def main():
    """! Main program entry."""
    logger.info(f"Base dir {base_dir}")
    logger.info(f"Site file {site_file}")
    logger.info(f"Site file daily {site_file_d}")

    sites = get_sites_from_conf(site_file)
    sites_d = get_sites_from_conf(site_file_d)

    create_dirs(sites=sites, base=base_dir, daily=True)

    start_time = "2022-12-01T00:00:00"
    end_time = "2023-02-10T23:59:59"

    init_data(sites=sites, base=base_dir, start=start_time, end=end_time, daily=False)
    init_data(sites=sites_d, base=base_dir, start=start_time, end=end_time, daily=True)
    update_data(sites=sites, base=base_dir, daily=False)
    update_data(sites=sites_d, base=base_dir, daily=True)

if __name__ == "__main__":
     main()
