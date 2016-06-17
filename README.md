Elastic 2.3.1 as a Docker container. For development use only.

## Quickstart
Without arguments, the container starts the Elastic server:

```
docker run -d --name elastic mcreations/openwrt-elastic
```

## Configuration Details
the volume as /data cab be passed from outside of Docker container with -v switch.
The ports can be opened  with -p switch.

This is a sample command line with custom parameters:

```
docker run -d --name elastic1 -v /share/elastic:/data \
       -p 9200:9200 -p 9300:9300 mcreations/openwrt-elastic
```

## Templates Import Configuration
All templates should be in json format. the name of them will come from ```template``` attribute of the json after eliminating * symbols.
All imported json files will move into ./imported folder after importing.

There are two ways for importing templates into ES:

### Internal templates
The internal templates come from ./image/root/etc/elastic/templates/ folder and can be used for importing additional templates after extending an existing Docker.

### External templates
These templates come from /data volume which can mounted from outside by a host folder and it can contain a ./templates folder to import its *.json files as template of ES.

The external templates will be imported with after importing the internal templates.

For the complete details of the configuration, please see

- [start-elastic.sh](https://github.com/m-creations/docker-openwrt-elastic/blob/master/image/root/start-elastic.sh)
