from datetime import datetime, timedelta, timezone
import json
import logging
from logging.handlers import RotatingFileHandler
import os
import sys

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

# MAIN VARIABLES
allowed_source_type = "fmi_weather_station"
main_configuration_file_path = "testdata/sites.geojson"

###
def do_fmi_meteo_fetch(id, config_path):
  """! Calls the download and process functionality
  @param id FO id for the site
  @param config_path Where the configuration is
  """
  logger.info(f"Handling {id}, {config_path}")
  if not os.path.isfile(config_path):
    logger.warning(f"Given configuration file does not EXIST")
  else:
    logger.info("READ_CONFIG")

###
def convert_str_to_dt(str):
  """! Convers the string to timezone aware datetime
       example string: "2023-12-31T00:00:00.000000Z"
  @param daily Do we only get daily aggregates

  @return timezone aware datetime
  """
  return datetime.fromisoformat(str.replace("Z", "+00:00"))

###
def main():
  """! Main reads the sites from configuration and checks if the correct
       data source exists and then checks if there is still a need to fetch
       the data.
  """
  if not os.path.isfile(main_configuration_file_path):
    logger.error(f"The main configuration file is not there ({main_configuration_file_path})")
  else:
    with open(main_configuration_file_path, 'r') as f:
      data = json.load(f)

    features = data["features"]
    for feature in features:
      properties = feature["properties"]
      data_sources = properties["data_sources"]
      for ds in data_sources:
        if ds['source_type'] in allowed_source_type:
          if properties['data_end'] == None:
            # Do, has not been marked as ended
            do_fmi_meteo_fetch(properties['id'], ds['source_config_file'])
          else:
            dend = convert_str_to_dt(properties['data_end'])
            now = datetime.now().replace(tzinfo=timezone(offset=timedelta()))
            if dend > now:
              # End time in future, doing
              do_fmi_meteo_fetch(properties['id'], ds['source_config_file'])
            else:
              # End time past, skip
              continue

###
if __name__ == "__main__":
  logger.info(f"Started")
  main()
  logger.info(f"Stopped")
