Elasticsearch in a small [OpenWrt](http://openwrt.org) container. For development use only.

## Quickstart

Without arguments, the container starts the ElasticSearch server:

```
docker run -d --name elastic mcreations/openwrt-elastic
```

## Configuration Details

The volume `/data` can be passed from outside of Docker container with `-v` switch.
The ports can be opened  with `-p` switch.

This is a sample command line with custom parameters:

```
docker run -d --name elastic1 \
       -e CLUSTER_NAME=my-cluster \
       -e NODE_NAME=my-first-node \
       -v /share/elastic:/data \
       -p 127.0.0.1:9200:9200 -p 127.0.0.1:9300:9300 \
       mcreations/elasticsearch
```
## Additional Configuration Values

To add configuration values to the configuration file
(`config/elasticsearch.yml`), you have to specify environment
variables with specific names, which are automatically parsed during
startup.

A variable specified as `docker ... -e ESOPT_http__cors__allow___origin=\"*\"`
is translated to the following entry in `elasticsearch.yml`:

```
http.cors.allow-origin: "*"
```

which means that the prefix `ESOPT_` is removed, `__` is replaced by
`.`, and `___` is replaced by `-`.

## Templates Import Configuration

This image is capable of importing
[index templates](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html)
which are applied to indices when they are created.

All templates should be in json format. Their name will be deduced
from the `template` attribute in their json definition after
eliminating `*` symbols.

All imported json files will be moved into the `./imported` folder
after importing.

There are two ways for importing templates into ES.

### Internal templates

Internal templates are read from `/etc/elastic/templates` which is
empty in this image, so you can safely extend this image and use `ADD`
in your Dockerfile to add the templates.

### External templates

External templates are read from the `/data/templates` directory which
can be mounted from outside. All files with extension `.json` are
explected to be ES template JSON files.

The external templates will be imported after importing the internal
templates.

For the complete details of the configuration, please see

- [start-elastic.sh](https://github.com/m-creations/docker-openwrt-elastic/blob/master/image/root/start-elastic.sh)


### Errors
 
Building an image from this repository, and creating a container from that, returns a few errors: 

```
... wait until http://localhost:9200 coming up to create templates and indices ...
shell-init: error retrieving current directory: getcwd: cannot access parent directories: Inappropriate ioctl for device
shell-init: error retrieving current directory: getcwd: cannot access parent directories: Inappropriate ioctl for device
chdir: error retrieving current directory: getcwd: cannot access parent directories: No child processes
```

but the containers from this image work despite these errors. Please
open an issue if it doesn't work in your setting!

