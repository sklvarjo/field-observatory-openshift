from datetime import datetime, timedelta, timezone
import json
import logging
from logging.handlers import RotatingFileHandler
import os
import sys

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

allowed_source_type = "fmi_weather_station"

def do_fmi_meteo_fetch(id, config_path):
  """! Calls the download and process functionality
  @param id FO id for the site
  @param config_path Where the configuration is
  """
  print(f"{id}, {config_path}")

def convert_str_to_dt(str):
  """! Convers the string to timezone aware datetime
       example string: "2023-12-31T00:00:00.000000Z"
  @param daily Do we only get daily aggregates

  @return timezone aware datetime
  """
  return datetime.fromisoformat(str.replace("Z", "+00:00"))

def main():
  """! Main reads the sites from configuration and checks if the correct
       data source exists and then checks if there is still a need to fetch
       the data. 
  """
  with open("testdata/sites.geojson", 'r') as f:
    data = json.load(f)
    #print(json.dumps(data, indent=4))

  features = data["features"]
  for feature in features:
    properties = feature["properties"]
    data_sources = properties["data_sources"]
    for ds in data_sources:
      if ds['source_type'] in allowed_source_type:
        #print(f"Site: {properties['site']}({properties['id']}), Data end: {properties['data_end']}, config: {ds['source_config_file']}")
        if properties['data_end'] == None:
          #print("Do, has not been marked as ended")
          do_fmi_meteo_fetch(properties['id'], ds['source_config_file'])
        else:
          dend = convert_str_to_dt(properties['data_end'])
          now = datetime.now().replace(tzinfo=timezone(offset=timedelta()))
          #print(f"DEND: {dend}, NOW: {now}")
          if dend > now:
            #print("Do time is in future")
            do_fmi_meteo_fetch(properties['id'], ds['source_config_file'])
          else:
            #print("NOT DOING ENDED")
            continue

if __name__ == "__main__":
  logger.info(f"Started")
  main()
  logger.info(f"Stopped")
