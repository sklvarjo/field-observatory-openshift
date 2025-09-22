
Follows the sites geojson's features->properties->data_end. 
Can be in format "2023-12-31T00:00:00.000000Z" or null

### Running outside of a container

The path points by default to /data/field-observatory, but it can be changed to something else.

    $ python3 src/run.py [path]

### Datasource example in sites geojson

    {
      "source_type": "fmi_weather_station",
      "source_config_file": "/data/fmi_conf/mu_fmi.json"
    }

### Configuration file example

- **fmisid** is the weather station id of FMI.
- **observation** folder path.
- **daily** true/false if true fetches also the daily file. Daily file is fetched for sites that do not have some of the parameters in NRT.

    {
      "fmisid": 101104,
      "observations-path": "/data/field-observatory/observations",
      "daily": true
    }

The NRT file contains:
    "Time","CloudAmount","Pressure","PrecipitationAmount","RelativeHumidity","PrecipitationIntensity","SnowDepth","AirTemperature","DewPointTemperature","Visibility","CurrentWeather","WindDirection","WindGust","WindSpeed"
The daily file containes: 
    "time","rrday","snow","tday","tg_pt12h_min","tmax","tmin"

