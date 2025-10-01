

**TODO:**
-

### requirements

    $ pip3 install requests python-dateutil

### Running outside of a container

The path points by default to /data/field-observatory, but it can be changed to something else.

    $ python3 src/run.py -di -b /tmp -c /tmp/config.json
- d = Dryrun
- i = Initialize data
- b = Base path, e.g., /data/field-observatory
- c = Main sites configuration file path, e.g., /data/field-observatory/field-observatory_sites.geojson
- s = Define sleep time between smartmet queries in seconds defaults to 5 seconds
- f = Force the initialization even if there are files in fmimeteo/observation folders

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

### Output files

The NRT file contains columns:

    "Time","CloudAmount","Pressure","PrecipitationAmount","RelativeHumidity","PrecipitationIntensity","SnowDepth","AirTemperature","DewPointTemperature","Visibility","CurrentWeather","WindDirection","WindGust","WindSpeed"

The daily file containes columns: 

    "time","rrday","snow","tday","tg_pt12h_min","tmax","tmin"

The script changes this
    "2025-08-31T23:50:00",8.0,1014.6,NaN,99.0,0.0,-1.0,13.4,13.3,30460.0,0.0,309.0,3.0,1.6
to this
    "2025-08-31T23:50:00.000000Z","8.0","1014.6","NaN","99.0","0.0","-1.0","13.4","13.3","30460.0","0.0","309.0","3.0","1.6"
so the other scripts should not see the difference that the data is fetced via smartmet now and not fmir.

### local testing

    $ python3 src/main.py -b testdata/field-observatory/ -c testdata/output.geojson

