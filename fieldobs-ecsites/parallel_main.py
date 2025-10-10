#######################################################
#
# USE WITH CAUTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#######################################################

from datetime import datetime, timedelta, timezone
import json
import logging
from logging.handlers import RotatingFileHandler
import os
import sys
from multiprocessing import Pool
import subprocess

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
allowed_source_type = "ec"
main_configuration_file_path = "testdata/sites.geojson"

def fake_process(site):
  print(site)
  ret = subprocess.run(['python3', 'test.py', site], capture_output = True)
  print(ret)
  return f"{site}: OK"

def main():
  """! Main reads the sites from configuration and checks if the correct
       data source exists and then checks if there is still a need to fetch
       the data.
  """
  sites = []

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
        #print(f" - {ds['source_type']}")
        if ds['source_type'] in allowed_source_type:
          print(f"{properties['id']} \"ec\" found")
          sites.append(properties['id'])

  print(sites)

  with Pool(5) as p:
    print(p.map(fake_process, sites))

###
if __name__ == "__main__":
  logger.info(f"Started")
  main()
  logger.info(f"Stopped")
