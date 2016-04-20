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

For the complete details of the configuration, please see

- [start-elastic.sh](https://github.com/m-creations/docker-openwrt-elastic/blob/master/image/root/start-elastic.sh)
