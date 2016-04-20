#!/bin/bash

set -e

chown -R $ELASTIC_USER:$ELASTIC_GROUP /data

exec su -p -l $ELASTIC_USER  << EOF
${ELASTIC_HOME}/bin/elasticsearch 
EOF