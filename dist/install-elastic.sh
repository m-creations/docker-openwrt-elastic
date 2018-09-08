#!/bin/sh

# This script fully installs elasticsearch into a docker container from mcreations/openwrt-java:8.
# All environment variables should be set in the Dockerfile.

set -ex

# install necessary packages

opkg update
opkg install shadow-groupadd shadow-useradd shadow-su curl coreutils-sha512sum coreutils-mktemp

# create user

mkdir -p ${INTERNAL_TEMPLATES_DIR}/imported
mkdir -p /home $ELASTIC_HOME /data
usr/sbin/useradd -d /home/$ELASTIC_USER -m -s /bin/bash -U $ELASTIC_USER
cp /root/.bashrc /home/$ELASTIC_USER

echo 'alias hostname="echo $HOSTNAME"' >> /etc/profile

# download elasticsearch and sha512 file

cd tmp

wget --progress=dot:giga -c "${ELASTIC_DOWNLOAD_URL}"
wget "${ELASTIC_DOWNLOAD_URL}.sha512"

# check sha512

sha512sum -c "/tmp/${ELASTIC_FILE}.sha512"

# install elasticsearch

tar -C /tmp -xvzf "/tmp/${ELASTIC_ARTIFACT_NAME}.tar.gz"

mv -f /tmp/${ELASTIC_ARTIFACT_NAME}/* ${ELASTIC_HOME}/
sed -i '1s/$/\nalias hostname="echo $HOSTNAME"/' ${ELASTIC_HOME}/bin/elasticsearch

# clean up

rm /tmp/opkg-lists/*
opkg remove shadow-groupadd shadow-useraddy

# make and chown elastic directories

cd "${ELASTIC_HOME}"

for path in \
	    ./logs \
	    ./config \
	    ./config/scripts \
            ./config/templates \
            ./config/tokenfilter \
            ./config/tokenfilter/stop
do
  mkdir -p "$path"
  chown -R $ELASTIC_USER:$ELASTIC_GROUP "$path"
done

cp -rf ${INTERNAL_CONFIG_DIR}/*.yml ./config/
chown -R $ELASTIC_USER:$ELASTIC_GROUP $ELASTIC_HOME

# fix the missing 'hostname' command
cat <<EOF> /usr/bin/hostname
#!/bin/sh

echo $HOSTNAME

EOF
chmod a+x /usr/bin/hostname

# fix the wrong mktemp usage in elasticsearch-env
sed -i -e 's/mktemp -d -t elasticsearch/mktemp -d -t "elasticsearch.XXXXXXXX"/' /opt/elastic/bin/elasticsearch-env
