import argparse
from datetime import datetime, timedelta, timezone
from dateutil.relativedelta import relativedelta
import json
import logging
from logging.handlers import RotatingFileHandler
import os
import requests
import sys
import time

# LOGGING RELATED
DEFAULT_DATE_FORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"
#FORMAT = '[%(levelname)s] %(message)s'
FORMAT = '%(asctime)-15s - [%(levelname)s] %(message)s'
logger = logging.getLogger("run_datasense_update")
log_level = os.getenv("LOG_LEVEL")
if log_level == None:
    logger.setLevel(logging.INFO)
formatter = logging.Formatter(FORMAT)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(formatter)
logging.basicConfig(handlers=[handler], format=FORMAT)

#####################################################
# MAIN VARIABLES
#####################################################
allowed_source_type = "fmi_weather_station"
base_path = "/data/field-observatory/"
main_configuration_file_path = "/data/field-observatory/field-observatory_sites.geojson"
url = 'http://smartmet.fmi.fi/timeseries'
init_start_time = "2025-08-01T00:00:00" #"2022-12-01T00:00:00"
#####################################################
#####################################################

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

###
def _create_dir(site, base, daily=False, dryrun=True):
    """! Creates the directories for the site.
    @param site The site id.
    @param base The base directory path.
    @param daily Are the daily observations directories created, defaults to false.
    """
    path_obs = _init_path(base, site, daily=False)
    if os.path.exists(path_obs) == True:
        logger.info(f" - Path exists: {path_obs}")
    else:
        logger.info(f" - Create path: {path_obs}")
        if not dryrun:
            os.makedirs(path_obs)
    if daily == True:
        path_obs_d = _init_path(base, site, daily=True)
        if os.path.exists(path_obs_d) == True:
            logger.info(f" - Daily path exists: {path_obs_d}")
        else:
            logger.info(f" - Create daily path: {path_obs_d}")
            if not dryrun:
                os.makedirs(path_obs_d)

###
def _loop_and_write(site_dir, fmisid, datetime_start, datetime_end, daily=False, dryrun=True, sleeptime=5):
    """! Initializes the data, i.e. gets the data that creates the first files to the folders.
    @param site_dir Path to write folder.
    @param fmisid FMI site ID.
    @param datetime_start The start time for the data.
    @param datetime_end The end time for the data.
    @param daily Is this run for daily aggregates, defaults to false.
    @param dryrun Skip the file writing operations also network operations
    @param sleeptime How long in seconds do we sleep between queries from smartmet
    """
    datetime_iter = datetime_start
    while datetime_end > datetime_iter:
        datetime_iter_end = datetime_iter+relativedelta(months=1)-relativedelta(seconds=1)
        if not dryrun:
            results = _get_measurements(fmisid, \
                                    datetime_iter.strftime("%Y-%m-%dT%H:%M:%S"), \
                                    datetime_iter_end.strftime("%Y-%m-%dT%H:%M:%S"), \
                                    daily=daily)
        path = f"{site_dir}{datetime_iter.year}-{datetime_iter.month}.csv"
        if not dryrun:
            with open(path, 'w') as f:
                f.write(results)
                logger.info(f"  - Wrote file {path}")
        else:
            logger.info(f"  - Would have written (dryrun: {dryrun}) {path}")
        datetime_iter = datetime_iter+relativedelta(months=1)
        time.sleep(sleeptime)

###
def init_data(site, fmisid, base, start, end, daily=False, dryrun=True, sleeptime=5, force=False):
    """! Initializes the data, i.e. gets the data that creates the first files to the folders.
    @param site The site id.
    @param base The base directory path.
    @param start The start time for the data.
    @param end The end time for the data.
    @param daily Is this run for daily aggregates, defaults to false.
    @param dryrun Skip the file writing operations also network operations
    @param sleeptime How long in seconds do we sleep between queries from smartmet
    @param Force the initialization even if fmimeteo/observation folders have files in them
    """
    site_dir = _init_path(base, site, daily=daily)
    marker = ""
    if daily:
        marker = "Daily "
    logger.info(f"  - {marker}site: {site}, FMIs ID: {fmisid}".capitalize())
    if not force:
        count = len(os.listdir(site_dir))
        if count > 0:
            logger.info(f"  - {marker}folder has files, skip init...".capitalize())
            return
    #take the given time and loop around it in complete months
    datetime_start = datetime.strptime(start, '%Y-%m-%dT%H:%M:%S')
    datetime_end = datetime.strptime(end, '%Y-%m-%dT%H:%M:%S')
    _loop_and_write(site_dir, fmisid, datetime_start, datetime_end, daily, dryrun, sleeptime)

###
def update_data(site, fmisid, base, daily=False, dryrun=True, sleeptime=5):
    """! Updates the data, i.e. Looks from the folder the last file and
         its date and starts from there to today.
    @param sites The sites array.
    @param base The base directory path.
    @param daily Is this run for daily aggregates, defaults to false.
    @param dryrun Skip the file writing operations also network operations
    @param sleeptime How long in seconds do we sleep between queries from smartmet
    """
    site_dir = _init_path(base, site, daily=daily)
    marker = ""
    if daily:
        marker = "Daily "
    logger.info(f"  - {marker}site: {site}, FMI site ID: {fmisid}".capitalize())
    files = sorted(os.listdir(site_dir))
    count = len(files)
    if count == 0:
        logger.error(f"  - {marker}folder had no files, odd... maybe init needs to be done".capitalize())
        return
    last_file = files[count-1]
    year = last_file.split("-")[0]
    month = last_file.split("-")[1].split(".")[0]
    logger.info(f"  - {marker}update starts from {year}/{month}")
    datetime_start = datetime.strptime(f"{year}-{month}-01T00:00:00", '%Y-%m-%dT%H:%M:%S')
    datetime_end = datetime.today()
    _loop_and_write(site_dir, fmisid, datetime_start, datetime_end, daily, dryrun, sleeptime)

###
def _get_measurements(fmisid, start_t, end_t, daily=False):
    """! This gets the measurements from the smartmet server by using the API
         provided by smartmet plugin timeseries
    @param fmisid FMI site ID
    @param start_time Start time
    @param end_time End time
    @param daily Do we only get daily aggregates

    @return ASCII CSV of the results
    """
    # Details on how to use this...
    # https://github.com/fmidev/smartmet-plugin-timeseries/blob/master/docs/Using-the-Timeseries-API.md
    # https://github.com/fmidev/docker-smartmetserver/blob/master/smartmetconf/engines/observation.conf
    timestep = "data"
    if daily:
        timestep = "1440"
    payload = {
      "fmisid": f"{fmisid}",
      "producer": "observations_fmi",
      "param":  "time," \
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
       "tz": "UTC",
       "separator": ",",
       "floatfield": "fixed",
       "precision": "double",
       "format": "csv"
     }
    r = requests.get(url, params=payload)
    data = r.text.splitlines(keepends=True)[1:]
    # change time format to have .000000Z
    databack = "".join(data)
    # forgetting " on purpose from next line
    databack = databack.replace(':00"', ':00.000000Z')
    databack = databack.replace(',', '","')
    databack = databack.replace('\n', '"\n')
    asciicsv='"Time","CloudAmount","Pressure","PrecipitationAmount","RelativeHumidity",'
    asciicsv=asciicsv+'"PrecipitationIntensity","SnowDepth","AirTemperature","DewPointTemperature",'
    asciicsv=asciicsv+'"Visibility","CurrentWeather","WindDirection","WindGust","WindSpeed"\n'
    asciicsv=asciicsv+f"{databack}"
    return asciicsv

###
def do_fmi_meteo_fetch(path, id, config_path, initialize_data, dryrun, sleeptime, force):
  """! Calls the download and process functionality
  @param path Base path
  @param id FO id for the site
  @param config_path Where the configuration is for the site given in id
  @param initialize_data Do we initialize the data
  @param dryrun Do we skip writing operations
  @param sleeptime How long in seconds do we sleep between queries from smartmet
  @param Force the initialization even if fmimeteo/observation folders have files in them
  """
  logger.info(f"Current site:: {id}")
  logger.info(f" - Reading config: {config_path}")
  if not os.path.isfile(config_path):
    logger.warning(f" ! Given configuration file does not EXIST")
  else:
    # read config
    data = ""
    with open(config_path, 'r') as f:
      data = json.load(f)
    logger.info(f" - FMISID: {data['fmisid']}, daily: {data['daily']}")
    # Check if output dir is there and if not create it
    _create_dir(id, path, daily = data['daily'],dryrun = dryrun)
    # go fetch with initialize or update
    if initialize_data:
      init_end_time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S") # "2022-12-01T00:00:00"
      logger.info(f" - Initialize the data (from {init_start_time} to {init_end_time}) (Dryrun: {dryrun})")
      if not dryrun:
        init_data(site = id, fmisid = data['fmisid'], base = path, start = init_start_time, end = init_end_time, dryrun = dryrun, sleeptime = sleeptime, force = force)
    else:
      logger.info(f" - Update the data (Dry run: {dryrun})")
      update_data(site = id, fmisid = data['fmisid'], base = path, dryrun = dryrun, sleeptime = sleeptime)

###
def convert_str_to_dt(str):
  """! Converts the string to timezone aware datetime
       example string: "2023-12-31T00:00:00.000000Z"
  @param daily Do we only get daily aggregates

  @return timezone aware datetime
  """
  return datetime.fromisoformat(str.replace("Z", "+00:00"))

###
def main(args):
  """! Main reads the sites from configuration and checks if the correct
       data source exists and then checks if there is still a need to fetch
       the data.
  """

  parser = argparse.ArgumentParser(description="This app is used to get the FMI meteo for FO: ",
                                   formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument("-i", "--initialize", action="store_true", help=f"Do we initialize data from {init_start_time} to now")
  parser.add_argument("-b", "--basepath", type=ascii, help="Define base path, e.g., /data/field-observatory")
  parser.add_argument("-c", "--configpath", type=ascii, help="Define the main configuration path")
  parser.add_argument("-d", "--dryrun", action="store_true", help="Do not write anything")
  parser.add_argument("-s", "--sleeptime", type=int, help="Define sleep time between smartmet queries in seconds defaults to 5 seconds")
  parser.add_argument("-f", "--force", action="store_true", help="Force the initialization even if there are files in fmimeteo/observation folders")

  args = parser.parse_args(args)
  config = vars(args)
  logger.info(config)
  initialize_data = config["initialize"]
  dryrun = config["dryrun"]
  force = config["force"]
  sleeptime = config["sleeptime"]
  if sleeptime == None:
    sleeptime = 5
  logger.info(f"Using {sleeptime} second sleep time between queries")
  path = base_path
  basepath = config["basepath"]
  if basepath != None:
    path = basepath
  cpath = main_configuration_file_path
  configpath = config["configpath"]
  if configpath != None:
    cpath = configpath

  logger.info(f"Using base path: {path}")
  logger.info(f"Using configuration file: {cpath}")

  if not os.path.isfile(main_configuration_file_path):
    logger.error(f"The main configuration file is not there ({cpath})")
  else:
    with open(main_configuration_file_path, 'r') as f:
      data = json.load(f)

    features = data["features"]
    for feature in features:
      properties = feature["properties"]
      data_sources = properties["data_sources"]
      for ds in data_sources:
        #print(f"{properties['id']} and {ds['source_type']}")
        if ds['source_type'] in allowed_source_type:
          if properties['data_end'] == None:
            # Do, has not been marked as ended
            do_fmi_meteo_fetch(path, properties['id'], ds['source_config_file'], initialize_data, dryrun, sleeptime, force)
          else:
            dend = convert_str_to_dt(properties['data_end'])
            now = datetime.now().replace(tzinfo=timezone(offset=timedelta()))
            if dend > now:
              # End time in future, doing
              do_fmi_meteo_fetch(path, properties['id'], ds['source_config_file'], initialize_data, dryrun, sleeptime, force)
            else:
              # End time past, skip
              continue

###
if __name__ == "__main__":
  logger.info(f"Started")
  logger.info("=============")
  main(sys.argv[1:])
  logger.info(f"Stopped")
