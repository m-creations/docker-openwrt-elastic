## -*- docker-image-name: "mcreations/openwrt-elastic" -*-

FROM mcreations/openwrt-java:8

MAINTAINER Reza Rahimi <rahimi@m-creations.net>

LABEL version="5.5.0"

ENV ELASTIC_HOME /opt/elastic
ENV INTERNAL_CONFIG_DIR /config
ENV INTERNAL_TEMPLATES_DIR /etc/elastic/templates
ENV EXTERNAL_TEMPLATES_DIR /data/templates
ENV DIST_DIR /mnt/packs

VOLUME /data

RUN mkdir -p /mnt/packs

ADD image/root /
ADD dist/ /mnt/packs

ENV ELASTIC_VERSION 5.5.0
ENV ELASTIC_REPO_BASE https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch
ENV ELASTIC_ARTIFACT_NAME elasticsearch-${ELASTIC_VERSION}
ENV ELASTIC_DOWNLOAD_URL ${ELASTIC_REPO_BASE}/${ELASTIC_VERSION}/${ELASTIC_ARTIFACT_NAME}.tar.gz
ENV ELASTIC_USER="elasticsearch"
ENV ELASTIC_GROUP="$ELASTIC_USER"


# More info: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html#create-index-settings
# Default for number_of_shards is 5
ENV ELASTIC_NUMBER_OF_SHARDS=5
# Default for number_of_replicas is 1 (ie one replica for each primary shard)
ENV ELASTIC_NUMBER_OF_REPLICAS=1

ENV CLUSTER_NAME=elasticsearch
ENV NODE_NAME=node-1

ENV PATH ${ELASTIC_HOME}/bin:$PATH

RUN opkg update && \
    opkg install shadow-groupadd shadow-useradd shadow-su curl && \
    rm /tmp/opkg-lists/* && \
    mkdir -p ${INTERNAL_TEMPLATES_DIR}/imported && \    
    mkdir -p /home $ELASTIC_HOME /data && \
    usr/sbin/useradd -d /home/$ELASTIC_USER -m -s /bin/bash -U $ELASTIC_USER && \
    cp /root/.bashrc /home/$ELASTIC_USER && \
    echo 'alias hostname="echo $HOSTNAME"' >> /etc/profile && \
    ([ -f $DIST_DIR/${ELASTIC_ARTIFACT_NAME}.tar.gz ] ||  wget -O $DIST_DIR/${ELASTIC_ARTIFACT_NAME}.tar.gz --progress=dot:giga ${ELASTIC_DOWNLOAD_URL}) &&\
    tar -C /tmp -xvzf $DIST_DIR/${ELASTIC_ARTIFACT_NAME}.tar.gz && \        
    mv -f /tmp/${ELASTIC_ARTIFACT_NAME}/* ${ELASTIC_HOME}/ && \    
    sed -i '1s/$/\nalias hostname="echo $HOSTNAME"/' ${ELASTIC_HOME}/bin/elasticsearch && \        
    chown -R $ELASTIC_USER:$ELASTIC_GROUP $ELASTIC_HOME && \
    chown -R $ELASTIC_USER:$ELASTIC_GROUP /data && \
    opkg remove shadow-groupadd shadow-useradd

EXPOSE 9200 9300

WORKDIR ${ELASTIC_HOME}

RUN set -ex \
	&& for path in \		
		./logs \
		./config \
		./config/scripts \
        ./config/templates \
        ./config/tokenfilter \
        ./config/tokenfilter/stop \
	; do \
		mkdir -p "$path"; \
		chown -R $ELASTIC_USER:$ELASTIC_GROUP "$path"; \
	done && \
    cp -rf ${INTERNAL_CONFIG_DIR}/*.yml ./config/ && \
	chown -R $ELASTIC_USER:$ELASTIC_GROUP $ELASTIC_HOME

CMD ["/start-elastic.sh"]

