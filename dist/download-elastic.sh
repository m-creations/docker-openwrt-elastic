#!/bin/bash
# Download and place elastictomcat packs in this dist/ directory to avoid multiple times download.
ELASTIC_VERSION="5.5.0"
ELASTIC_REPO_BASE="https://artifacts.elastic.co/downloads/elasticsearch"
ELASTIC_ARTIFACT_NAME="elasticsearch-${ELASTIC_VERSION}"
ELASTIC_FILE="${ELASTIC_ARTIFACT_NAME}.tar.gz"
ELASTIC_DOWNLOAD_URL="${ELASTIC_REPO_BASE}/${ELASTIC_FILE}"

# download tar.gz 
wget -c "${ELASTIC_DOWNLOAD_URL}"

# download sha1 of above file
wget "${ELASTIC_DOWNLOAD_URL}.sha1"

# the sha1 according to elastic.co: 
SUM=$(cat "${ELASTIC_FILE}.sha1")

# extract hash from sha1sum, because this is how elastic.co stores the sha1 file (!)
newsum=$(cut -d ' ' -f 1 <<< $(sha1sum $ELASTIC_FILE))

if [ "$SUM" = "$newsum" ]
then echo "SHA1SUM OK"
else echo "SHA1SUM FAILED!!!" 
     exit 1
fi

rm "${ELASTIC_FILE}.sha1"
