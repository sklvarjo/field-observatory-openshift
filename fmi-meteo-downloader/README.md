## Local build and pushing the image to openshift integrated repository

Podman would also work and in some cases it is a wiser option. 
Docker allows you to create things that are not allowed in openshift but for this project it does not matter.

    $ docker build -t fmi-meteo-downloader -f fmi-meteo-downloader.Dockerfile . 

Get the registry info.

    $ oc registry info --public
    default-route-openshift-image-registry.apps.ock.fmi.fi

Well this is same for everyone, so really not necessary now but here for completeness sake.


    $ docker login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.ock.fmi.fi

This may ask about a passphrase in a GUI. It is for a key that you do not remember doing. 
You can find it by "gpg --list-secret-keys". 
It is the local keyring's master key and the passhrase is your local machines local password.

    $ docker tag fmi-meteo-downloader default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fmi-meteo-downloader

**NOTE:** Changed the style of reference to the image, this might not be valid anymore. Every time you build a new image remember to tag the image again as the tag will still point to the old IMAGE ID after the build.
**NOTE:** Usually it is needed to delete the deployment from openshift and create it again to get the new image to get loaded as that also points to the last IMAGE ID.

    $ docker push default-route-openshift-image-registry.apps.ock.fmi.fi/field-observatory/fmi-meteo-downloader

**NOTE:** Changed the style of reference to the image, this might not be valid anymore. YOU HAVE TO CHANGE THE IMAGESTREAMS LOOKUP POLICY TO TRUE BY HAND IN CONSOLE. **Only after first push**
Administrator side -> builds -> ImageStreams -> hatakkaj-receiver -> YAML -> "spec: lookupPolicy: local: true" -> save
or run this in oc
    $ oc patch is fmi-meteo-downloader -p '{"spec": {"lookupPolicy": {"local": true}}}'

### Deploy on Openshift

Upload the cronjob

    $ oc apply -f fmi-meteo-downloader-cronjob.yml

**NOTE:** Use "oc replace -f-" instead of "oc create -f-" when making changes. Easier than removing and creating again.

See below the running outside of a container section for the command line switches, these can be used in the cronjob yaml's 
args section to change the behaviour of the script. 

**NOTE:** If just changing runtime might be easier to run 

    $ oc patch cronjob fmi-meteo-downloader-cronjob -p '{"spec": {"schedule": "1 */1 * * *"}}'

**NOTE:** suspending a cronjob
    $ oc patch cronjob fmi-meteo-downloader-cronjob -p '{"spec" : {"suspend" : true }}'

## Other information

### Init of conf files

There is a file called src/init_configs.py that will create the site configuration files and modify the sites file to
include the data source for fmimeteo. **!READ IT FIRST!** and use with caution.

### requirements

    $ pip3 install requests python-dateutil

### Running outside of a container

The path points by default to /data/field-observatory and config path to 
/data/field-observatory/field-observatory/field-observatory_sites.geojson, but it can be changed to something else.

    $ python3 src/main.py -di -b /tmp -c /tmp/config.json

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

