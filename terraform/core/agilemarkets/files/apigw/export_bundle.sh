#!/bin/bash
set -e

# Initialization

# Those parameters are hardcoded for now
HOST=lonrs03742.fm.rbsgrp.net
PORT=8443
SSG_USER=ssgconfig

# this is the ID of SecurityServices folder SDP creates
TARGET_PARENT_FOLDER_ID=fb3f1ba1a929b3396bcf3670811314c5

TEMP=/tmp
UPLOAD_URL=https://artifactory-1.dts.fm.rbsgrp.net/artifactory/eComm-public-releases-local/CA/APIGW/AWS/NWM/
OUTPUT_PREFIX=/tmp/002-nwm

trap cleanup EXIT

function usage() {
echo '
  Usage:' "$0" '-V <version> -f <folder,folder>[-g <gateway name>] [-v] [-h]
    -V|--version: version of the bundle
    -g|--gateway: hostname of source API gateway
    -f|--folders: folders to be exported, common separated 
    -h|--help: display this message
    -v|--verbose: display DEBUG messages

  Example:
        ' "$0" '--version 1.1 --gateway lonrs03742.fm.rbsgrp.net --folders "RBSAgile,FXMPApps"
'
}

function logging () {
  [[ -z $LOGFILE ]] && { LOGFILE=$(mktemp $TEMP/$(basename $0)-log.XXXX) ; logging INFO "Creating log file $LOGFILE"; }
  if [[ $VERBOSE == true || ! "$1" == DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" | tee -a $LOGFILE
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}

function cleanup () {
  if [[ -e ${OUTPUT} ]] || [[ -e ${OUTPUT}.gz ]]; then
    echo ""
    logging INFO "Cleaning up exported bundle files"
    rm -f "${OUTPUT}"
    rm -f "${OUTPUT}.gz"
  fi
}

function get_folder_id () {
  local L_FOLDER_NAME=$1
  local L_RESPONSE=$(curl "${CURL_ARG[@]}" --request GET --url https://${HOST}:${PORT}/restman/1.0/folders?name=${L_FOLDER_NAME})
  [[ $(echo "${L_RESPONSE}" | xmllint --xpath "/*[local-name()='List']/*[local-name()='Item']/*[local-name()='Name']/text()" -) != "${L_FOLDER_NAME}" ]] && logging ERROR "Cannot fild folder ${L_FOLDER_NAME}."
  local L_FOLDER_ID=$(echo "$L_RESPONSE" | xmllint --xpath "string(//*[local-name()='Resource']/*[local-name()='Folder']/@id)" -)
  echo "${L_FOLDER_ID}"
}
#
# Process input
#

cd "$(dirname ${BASH_SOURCE[0]})"
if ! OPTS=`getopt -o V:g:f:vh --long version:,gateway:,folders:,help,verbose -- "$@"`; then 
  usage
  logging ERROR "failed to parse inputs"
fi

# extract options and their arguments into variables.
eval set -- "$OPTS"
while true
do
  case "$1" in
    -V|--version)
      VERSION=$2 ; shift 2 ;;
    -g|--gateway)
      GATEWAY=$2 ; shift 2 ;;
    -f|--folders)
      FOLDERS_NAME=$2 ; shift 2 ;;
    -v|--verbose) VERBOSE=true ; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift ; break ;;
    *)
      usage
      logging ERROR "Unknown input."
      exit 1 ;;
  esac
done

[[ -z ${VERSION} || -z ${FOLDERS_NAME} ]] && logging ERROR "Please provide a version number of the exported bundle."

OUTPUT=${OUTPUT_PREFIX}-v${VERSION}-$(date +"%Y%m%d%H%M%S").req.bundle
logging INFO "Export bundle file: ${OUTPUT}"

# create gateway auth token
read -rsp $'\e[96mPlease provide password of username '"${SSG_USER}"$' on '"${HOST}"$':\e[0m' PASSWORD
echo ""
AUTH_TOKEN=$(echo -n "ssgconfig:$PASSWORD" | base64)
CURL_ARG=(--insecure --silent --header 'content-type: application/xml' --header 'cache-control: no-cache' --header "authorization: Basic ${AUTH_TOKEN}")
RESPONSE=$(curl "${CURL_ARG[@]}" --request GET --url https://${HOST}:${PORT}/restman/1.0/clusterProperties?name=$(openssl rand -hex 8))
[[ $(echo "${RESPONSE}" | xmllint --xpath "/*[local-name()='List']/*[local-name()='Name']/text()" -) != "CLUSTER_PROPERTY List" ]] && logging ERROR "Failed to connect to the gateway."

# We can only export folders under SecurityServices at the moment
SOURCE_PARENT_FOLDER_ID=$(get_folder_id "SecurityServices")

# build the list of folders to be exported
logging INFO "Checking the folders to be exported on ${HOST}: ${FOLDERS_NAME} ..."
EXPORT_TARGETS=""
for i in ${FOLDERS_NAME//,/ }
do
  FOLDER_ID=$(get_folder_id "$i")
  EXPORT_TARGETS="${EXPORT_TARGETS}&folder=${FOLDER_ID}"
done

# export
logging INFO "Exporting folders ${FOLDERS_NAME} from ${HOST}..."
curl "${CURL_ARG[@]}" --request GET --url "https://${HOST}:${PORT}/restman/1.0/bundle?defaultAction=NewOrExisting${EXPORT_TARGETS}" > ${OUTPUT}
[[ $(xmllint --xpath "/*[local-name()='Item']/*[local-name()='Name']/text()" ${OUTPUT}) != "Bundle" ]] && logging ERROR "Failed to export folders." || logging INFO "Bundle exported in ${OUTPUT}"

# modify bundle
logging INFO "Prepare the bundle for upload."
## set target folder for import
/usr/bin/sed -i "s/\(<l7:Mapping action=\"NewOrExisting\" srcId=\"$SOURCE_PARENT_FOLDER_ID\" [^ ]\+\) \(type=\"FOLDER\"\)/\1 targetId=\"$TARGET_PARENT_FOLDER_ID\" \2/g" ${OUTPUT}
## do not migrate private key
/usr/bin/sed -i '/<l7:Mapping.*type="SSG_KEY_ENTRY"/ s/NewOrExisting/Ignore/g' ${OUTPUT}
## Reformat XML payload
/usr/bin/sed -i 's#<l7:Bundle>#<l7:Bundle xmlns:l7="http://ns.l7tech.com/2010/04/gateway-management">#g' ${OUTPUT}
/usr/bin/sed -i '2,7d' ${OUTPUT}
/usr/bin/sed -i '$d' ${OUTPUT}
/usr/bin/sed -i '$d' ${OUTPUT}

# compress - original export is about 10MB
logging INFO "Compressing ..."
/usr/bin/gzip -v ${OUTPUT}

# Upload to Artifactory
logging INFO "Upload ${OUTPUT}.gz to ${UPLOAD_URL}. Please provide password of user ${whoami}"
/usr/bin/curl -sk -u $(whoami) --url ${UPLOAD_URL} -T ${OUTPUT}.gz
echo ""
[[ $? == 0 ]] && logging INFO "Completed. Bundle $(basename ${OUTPUT}.gz) is ready."
