#!/bin/bash
# This should be replaced by Gateway playbooks when Tooling becomes available
# Usage: apigw_update_cwp.sh <HOSTNAME:PORT> <SSGCONFIG_PASSWORD> <CWP_JSON>
#   create CWP if it doesnot exist
#   update CWP if it exist and has different value 
#   no action CWP if exist and has the same value 


# Initialization
TEMP=/tmp
G_SSG=$1
G_PASS=$2
G_CWPS=$3
G_AUTH_TOKEN=$(echo -n "ssgconfig:$G_PASS" | base64)
G_CURL_ARG=(--insecure --silent --header 'content-type: application/xml' --header 'cache-control: no-cache' --header "authorization: Basic ${G_AUTH_TOKEN}")

function logging () {
  [[ -z $LOGFILE ]] && { LOGFILE=$(mktemp $TEMP/$(basename $0)-log.XXXX) ; logging INFO "Creating log file $LOGFILE"; }
  if [[ $VERBOSE == true || "$1" != DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" | tee -a $LOGFILE
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}

function update_cwp(){
# create CWP if it doesnot exist
# update CWP if it exist and has different value 
# no action CWP if exist and has the same value 
  L_CWP_NAME="$1"
  L_CWP_VALUE="$2"
  L_PAYLOAD=$(cat << EOF
<l7:ClusterProperty xmlns:l7="http://ns.l7tech.com/2010/04/gateway-management">
  <l7:Name>$L_CWP_NAME</l7:Name>
  <l7:Value>$L_CWP_VALUE</l7:Value>
</l7:ClusterProperty>
EOF
)

  # search for the CWP
  L_GET_RESPONSE=$(curl "${G_CURL_ARG[@]}" --request GET --url https://${G_SSG}/restman/1.0/clusterProperties?name=${L_CWP_NAME} 2>/dev/null)
  [[ $(echo "$L_GET_RESPONSE" | xmllint --xpath "//*[local-name()='List']/*[local-name()='Name']/text()" -) != "CLUSTER_PROPERTY List" ]] && logging ERROR "Failed CWP query."

  if [[ $(echo "$L_GET_RESPONSE" | xmllint --xpath "//*[local-name()='Resource']/*[local-name()='ClusterProperty']/*[local-name()='Name']/text()" -) == "$L_CWP_NAME" ]]; then
    logging INFO "CWP [$L_CWP_NAME] - found."
    if [[ $(echo "$L_GET_RESPONSE" | xmllint --xpath "//*[local-name()='Resource']/*[local-name()='ClusterProperty']/*[local-name()='Value']/text()" -) == "$L_CWP_VALUE" ]]; then
      logging INFO "CWP [$L_CWP_NAME] - no changes required."
      echo "Next."
    else
      # Update CWP
      L_CWP_ID=$(echo "$L_GET_RESPONSE" | xmllint --xpath "string(//*[local-name()='Resource']/*[local-name()='ClusterProperty']/@id)" -)
      L_PUT_RESPONSE=$(curl "${G_CURL_ARG[@]}" --request PUT --url https://${G_SSG}/restman/1.0/clusterProperties/${L_CWP_ID} --data "${L_PAYLOAD}") 
      if [[ $(echo "$L_PUT_RESPONSE" | xmllint --xpath "//*[local-name()='Item']/*[local-name()='Name']/text()" -) != "$L_CWP_NAME" ]]; then
        logging ERROR "CWP [$L_CWP_NAME] - failed to update."
      fi
      logging INFO "CWP [$L_CWP_NAME] - updated"
    fi
  else
    # Create CWP
    L_POST_RESPONSE=$(curl "${G_CURL_ARG[@]}" --request POST --url https://${G_SSG}/restman/1.0/clusterProperties --data "${L_PAYLOAD}")
    if [[ $(echo "$L_POST_RESPONSE" | xmllint --xpath "//*[local-name()='Item']/*[local-name()='Name']/text()" -) != "$L_CWP_NAME" ]]; then
      logging ERROR "CWP [$L_CWP_NAME] - failed to create."
      exit 1
    fi
    logging INFO "CWP [$L_CWP_NAME] - created."
 fi 
}

for i in $(echo $G_CWPS | jq -c .[]); do
  logging INFO "Start processing CWP KV $i."
  update_cwp $(echo $i | jq -r .name) $(echo $i | jq -r .value)
done

