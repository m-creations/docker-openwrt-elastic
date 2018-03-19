#!/bin/bash

function shut_down() {
    echo "Shutting down"
    kill -TERM $pid 2>/dev/null
}

trap "shut_down" SIGKILL SIGTERM SIGHUP SIGINT EXIT

export DEFAULT_ES_URL="http://localhost:9200"
############################################
# Base Functions' Declaration
###########################################
function wait_until_service_comes_up() {
  local es_url=$1
  local is_up=NO
  local wait_time=30

  echo "... wait until $es_url comes up (for $wait_time seconds) to create templates and indices ..."

  max_wait=$((SECONDS+$wait_time))

  while [ $SECONDS -lt $max_wait ]; do
    HTTP_CODE=$(curl -sL -w "%{http_code}\\n"  --connect-timeout 1 -o /dev/null -H "Content-Type: application/json" -XGET "$es_url")
    if [ 200 -eq $HTTP_CODE ]; then
      echo "ES service on $es_url is up ..."
      is_up=YES
      break
    elif [ 000 -eq $HTTP_CODE ]; then
      sleep 5
      echo "... wait until $es_url comes up to create templates ..."
    else
      sleep 5
      echo "... wait until $es_url comes up to create templates (HttpCode is ${HTTP_CODE}) ..."
    fi
  done

  if [ $is_up == "NO" ] ; then
    echo "Elasticsearch did not start within $wait_time seconds!"
  fi
}

############################################
function extract_template_name(){
    local template_file=$1
    echo $(grep -o '"template".*:.*".*"' "${template_file}" | sed 's/^.*://g' | sed 's/\s*["|*]*\s*//g')
#    echo $(grep -o '"template".*:.*".*"' "$1" | grep -o ":.*$" | grep -o '".*"' |cut  -d'"' -f 2) |cut  -d'*' -f 2)
}

############################################
function check_template_exists(){
  local es_url=$1 template_name=$2
  HTTP_CODE=$(curl -sL -w "%{http_code}\\n"  --connect-timeout 10 -o /dev/null -XGET "${es_url}/_template/${template_name}")
  if [ 200 -eq $HTTP_CODE ]; then
    #0=true
    return 0
  else
    echo "$template_name template does not exist on ES."
    #1=false
    return 1
  fi
}

############################################
function creare_template(){
  local es_url=$1 template_name=$2 template_file=$3 template_folder=$4
  HTTP_CODE=$(curl -sL -w "%{http_code}\\n" --connect-timeout 30 -d "@${template_file}" -XPUT "${es_url}/_template/${template_name}" -H "Content-Type: application/json" -o /dev/null)
  if [ 200 -eq $HTTP_CODE ]; then
    echo "Template $template_name created successfully on ES."
    mv -f $template_file ${template_folder}/imported/
    #0=true
    return 0
  else
    echo "Create template $template_name failed with HTTP code: $HTTP_CODE"
    #1=false
    return 1
  fi
}

############################################
function create_templates() {
  local es_url=$1 templates_folder=$2
  echo "---------------------------------------------"
  echo "Creating templates json files inside $templates_folder folder ..."
  echo "---------------------------------------------"
  for template_file in ${templates_folder}/*.json; do
    echo "Processing template in file $template_file ..."
    TEMPLATE_NAME=$(extract_template_name "$template_file")
    if check_template_exists "$es_url" "$TEMPLATE_NAME" ; then
      echo "Template '$TEMPLATE_NAME' already exists";
    else
      echo "Creating $TEMPLATE_NAME template from file $template_file on ES..."
      creare_template "$es_url" "$TEMPLATE_NAME" "$template_file" "$templates_folder"
    fi
    echo "---------------------------------------------"
  done
}

############################################
function check_index_exists(){
  local es_url=$1 index_name=$2
  HTTP_CODE=$(curl -sL -w "%{http_code}\\n"  --connect-timeout 10 -o /dev/null -XHEAD "${es_url}/${index_name}")
  if [ 200 -eq $HTTP_CODE ]; then
    echo "$index_name index already exists"
    #0=true
    return 0
  else
    echo "$index_name does not exist on ES."
    #1=false
    return 1
  fi
}

############################################
function create_index(){
  local es_url=$1 index_name=$2 create_index_data
    create_index_data="{
      \"settings\" : {
          \"number_of_shards\" : ${ELASTIC_NUMBER_OF_SHARDS},
          \"number_of_replicas\" : ${ELASTIC_NUMBER_OF_REPLICAS}
      }
    }"
  HTTP_CODE=$(curl -sL -w "%{http_code}\\n" --connect-timeout 30 -XPUT --data "$create_index_data" "${es_url}/${index_name}"  -o /dev/null)
  if [[ ( 200 -eq $HTTP_CODE ) || ( 201 -eq $HTTP_CODE ) ]]; then
    echo "$index_name index created successfully on ES."
    #0=true
    return 0
  else
    echo "Create index $index_name failed with HTTP code: $HTTP_CODE"
    #1=false
    return 1
  fi
}


############################################
# Main Section of Script
###########################################
mkdir -p /data/elasticsearch
chown -R $ELASTIC_USER:$ELASTIC_GROUP /data
mkdir -p ${EXTERNAL_TEMPLATES_DIR}/imported

exec /usr/bin/su -p -l ${ELASTIC_USER} --shell /bin/bash -c ${ELASTIC_HOME}/bin/elasticsearch &

pid=$!
echo "Process ID of ES : $pid"

# wait until ES comes up
wait_until_service_comes_up "$DEFAULT_ES_URL"
############### Check if any internal templates exists #############################
ls -1 ${INTERNAL_TEMPLATES_DIR}/*.json > /dev/null 2>&1
if [ "$?" = "0" ]; then
  echo "#--------------------------------------------"
  echo "Checking internal templates to import ..."
  create_templates "$DEFAULT_ES_URL" ${INTERNAL_TEMPLATES_DIR}
  echo "Creating internal templates on ES Done."
  echo "---------------------------------------------#"
fi

############### Check if any external templates exist #############################
ls -1 ${EXTERNAL_TEMPLATES_DIR}/*.json > /dev/null 2>&1
if [ "$?" = "0" ]; then
  echo "#--------------------------------------------"
  echo "Checking external templates to import ..."
  create_templates "$DEFAULT_ES_URL" ${EXTERNAL_TEMPLATES_DIR}
  echo "Creating external templates on ES Done."
  echo "---------------------------------------------#"
fi

if [ ! -z "$INDEX_NAMES" ]; then
IFS=',' read -a indices_array <<< "$INDEX_NAMES"
echo "#--------------------------------------------"
echo "Creating indices ..."
echo "---------------------------------------------"
for i in "${indices_array[@]}"
do
   echo "Creating index $i ... "
   check_index_exists "$DEFAULT_ES_URL" "$i"
   indexExists=$?
   if [ $indexExists -ne 0 ]; then
     create_index "$DEFAULT_ES_URL" "$i"
   fi
   echo "---------------------------------------------"
done
echo "Creating indices done."
echo "--------------------------------------------#"
else
echo "No index to create."
fi

# Did we create any indices? If yes, set their merge thread count to 1
# as we are not interested in multi-threaded merging
if [ ! -z $i ] ; then
    curl -d@- -H "Content-Type: application/json" -XPUT 'http://localhost:9200/_all/_settings?preserve_existing=true' <<EOF
    {
      "index.merge.scheduler.max_thread_count" : "1"
    }
EOF
fi

wait
