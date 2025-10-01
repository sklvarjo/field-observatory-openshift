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
main_configuration_file_path = "testdata/field-observatory_sites.geojson"

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
      ui_properties = properties["ui_properties"]
      if ui_properties['fmisid'] == None:
        print(f"SKIP for {properties['id']}")
      else:
        # check if the fmi_meteo is there or not
        found = 0
        print(f"{properties['id']} ID found {ui_properties['fmisid']}")
        for ds in data_sources:
          print(f" - {ds['source_type']}")
          if ds['source_type'] in allowed_source_type:
             found = 1
        if found == 0:
          # need to be added as did not find fmi_weather_station data source
          print("   - Need to be added")
          c_path = f"/data/field-observatory/config/fmi_meteo/{properties['id']}_fmi_meteo.json"
          tobeadded = {"source_type": "fmi_weather_station", "source_config_file": c_path}
          data_sources.append(tobeadded)

          obs_path = "/data/field-observatory/observations"
          new_conf_file_data = {"fmisid": ui_properties['fmisid'], "observations-path": obs_path, "daily": False}
          with open(f"testdata/fmi_conf/fmi_meteo/{properties['id']}_fmi_meteo.json", 'w') as fc:
            fc.write(json.dumps(new_conf_file_data, indent=4))

  with open("testdata/output.geojson", 'w') as f:
    f.write(json.dumps(data, indent=4))

###
if __name__ == "__main__":
  logger.info(f"Started")
  main()
  logger.info(f"Stopped")
