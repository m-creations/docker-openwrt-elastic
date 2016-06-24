#!/bin/bash

############################################
# Base Functions' Declaration
###########################################
function wait_until_service_comes_up() {
  local es_url=$1
  echo "... wait until $es_url comming up to create templates ..."
  while true; do
    HTTP_CODE=$(curl -sL -w "%{http_code}\\n"  --connect-timeout 1 -o /dev/null -XGET "$es_url")
    if [ 200 -eq $HTTP_CODE ]; then
      echo "ES service on $es_url is up ..."
      break
    elif [ 000 -eq $HTTP_CODE ]; then
      sleep 1
      echo "... wait until $es_url comming up to create templates ..."
    else
      sleep 1
      echo "... wait until $es_url comming up to create templates (HttpCode is ${HTTP_CODE}) ..."      
    fi
  done
}

############################################
function extract_template_name(){
    local template_file=$1
    echo $(grep -o '"template".*:.*".*"' "${template_file}" | sed 's/^.*://g' | sed 's/\s*["|*]*\s*//g')
#    echo $(grep -o '"template".*:.*".*"' "$1" | grep -o ":.*$" | grep -o '".*"' |cut  -d'"' -f 2) |cut  -d'*' -f 2)
}

############################################
function check_template_exits(){
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
    if check_template_exits "$es_url" "$TEMPLATE_NAME" ; then
      echo "Template '$TEMPLATE_NAME' already exists";
    else
      echo "Creating $TEMPLATE_NAME template from file $template_file on ES..."
      creare_template "$es_url" "$TEMPLATE_NAME" "$template_file" "$templates_folder"
    fi
    echo "---------------------------------------------"
  done  
}

############################################
# Main Secion of Script
###########################################
mkdir -p /data/elasticsearch
chown -R $ELASTIC_USER:$ELASTIC_GROUP /data
mkdir -p ${EXTERNAL_TEMPLATES_DIR}/imported

exec /usr/bin/su -p -l ${ELASTIC_USER} --shell /bin/bash -c ${ELASTIC_HOME}/bin/elasticsearch &

pid=$!
echo "Process ID of ES : $pid"
wait_until_service_comes_up "http://localhost:9200"
############### Check if any internal templates exists #############################
ls -1 ${INTERNAL_TEMPLATES_DIR}/*.json > /dev/null 2>&1
if [ "$?" = "0" ]; then
  echo "#--------------------------------------------"  
  echo "Checking internal templates to import ..."  
  create_templates "http://localhost:9200" ${INTERNAL_TEMPLATES_DIR}
  echo "Creating internal templates on ES Done."
  echo "---------------------------------------------#"
fi

############### Check if any external templates exists #############################
ls -1 ${EXTERNAL_TEMPLATES_DIR}/*.json > /dev/null 2>&1
if [ "$?" = "0" ]; then
  echo "#--------------------------------------------"  
  echo "Checking external templates to import ..."  
  create_templates "http://localhost:9200" ${EXTERNAL_TEMPLATES_DIR}
  echo "Creating external templates on ES Done."
  echo "---------------------------------------------#"
fi

wait
