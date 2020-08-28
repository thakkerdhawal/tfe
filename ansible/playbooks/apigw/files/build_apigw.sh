#!/bin/bash
set -e
PASS=$1
C_PASS=m47lToFsLI4x
G_SSG=localhost
G_AUTH_TOKEN=$(echo -n "ssgconfig:$PASS" | base64)
G_CWPS=$1
NODE_PROPERTIES=/root/create-node.properties
LOGFILE=/root/build_apigw.log
> $LOGFILE

function logging () {
  [[ -z $LOGFILE ]] && { LOGFILE=$(mktemp $TEMP/$(basename $0)-log.XXXX) ; logging INFO "Creating log file $LOGFILE"; }
  if [[ $VERBOSE == true || ! "$1" == DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" | tee -a $LOGFILE
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}

function deploy_resource(){
  L_SSG="$1"
  L_AUTH_TOKEN="$2"
  L_RESOURCE="$3"
  L_TEMPLATE_FILE="$4"

  curl --request PUT \
    --url https://${L_SSG}:8443/restman/1.0/${L_RESOURCE} \
    --header 'authorization: Basic '${L_AUTH_TOKEN}'' \
    --header 'cache-control: no-cache' \
    --header 'content-type: application/xml' \
    --data @${L_TEMPLATE_FILE} \
    --insecure
}

logging INFO "Wait for build_bundle files to become available"
timeout 300s /bin/bash -c '
while [[ ! -f /root/build_bundle/license/SSG_APIGW_9.xml ]]
do
  sleep 15
  echo "$(date) Still waiting for build_bundle files ..."
done'

logging INFO "Wait for ip address to become available"
timeout 300s /bin/bash -c '
while [[ "$(curl -sk http://169.254.169.254/latest/meta-data/local-ipv4 -w %{http_code}\\n -o /dev/null)" != "200" ]]
do
  sleep 15
  echo "$(date) Still waiting ..."
done'

logging INFO "Wait for mysql service to become available"
timeout 120s /bin/bash -c '
while ! service mysql status > /dev/null
do
  sleep 15
  echo "$(date) Still waiting ..."
done'

logging INFO "Preparing the node"
mysqladmin -u root -p'7layer' password ${PASS}
sed -i "s/password=.*/password=${PASS}/g" /root/.my.cnf
/opt/SecureSpan/Gateway/config/bin/ssgconfig-headless create -template > ${NODE_PROPERTIES}
sed -i "s/#database.pass=/database.pass=${PASS}/g" ${NODE_PROPERTIES}
sed -i "s/#database.admin.pass=/database.admin.pass=${PASS}/g" ${NODE_PROPERTIES}
sed -i "s/#admin.pass=/admin.pass=${PASS}/g" ${NODE_PROPERTIES}
sed -i "s/#admin.user=/admin.user=ssgconfig/g" ${NODE_PROPERTIES}
sed -i "s/cluster.host=.*/cluster.host=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)/g" ${NODE_PROPERTIES}
sed -i "s/#cluster.pass=/cluster.pass=${C_PASS}/g" ${NODE_PROPERTIES}

logging INFO "Wait for controller service to become available"
timeout 300s /bin/bash -c '
while [[ "$(curl -sk https://localhost:8765 -w %{http_code}\\n -o /dev/null)" != "200" ]]
do
  sleep 15
  echo "$(date) Still waiting ..."
done'

logging INFO "Setup auto provisioning"
mkdir -p /opt/SecureSpan/Gateway/node/default/etc/bootstrap/{license,services}
touch /opt/SecureSpan/Gateway/node/default/etc/bootstrap/services/restman
cp /root/build_bundle/license/SSG_APIGW_9.xml /opt/SecureSpan/Gateway/node/default/etc/bootstrap/license/lic-apigw.xml
mkdir -p /opt/SecureSpan/Gateway/node/default/etc/bootstrap/bundle
cp -R ~/build_bundle/bundles/* /opt/SecureSpan/Gateway/node/default/etc/bootstrap/bundle/
chown -R layer7:gateway /opt/SecureSpan/Gateway/node/default/etc/bootstrap/
find /opt/SecureSpan/Gateway/node/default/etc/bootstrap/ -type d -exec chmod 0770 {} \;
find /opt/SecureSpan/Gateway/node/default/etc/bootstrap/ -type f -exec chmod 0660 {} \;

logging INFO "Creating gateway node"
cat ${NODE_PROPERTIES} | /opt/SecureSpan/Gateway/config/bin/ssgconfig-headless create

logging INFO "Waiting for the gateway process to start."
timeout 300s /bin/bash -c '
while [[ "$(curl -sk https://localhost:8443/ssg/webadmin/ -w %{http_code}\\n -o /dev/null)" != "200" ]]
do
  sleep 15
  echo "$(date) Still waiting ..."
done'

if [[ $? == 0 ]]; then
  logging INFO "OK: gateway started."
else
  logging ERROR "Failed to start the gateway."
fi

logging INFO "Wait for mysql service to become available"
timeout 120s /bin/bash -c '
while ! service mysql status > /dev/null
do
  sleep 15
  echo "$(date) Still waiting ..."
done'

logging INFO "... deploying cwp"
deploy_resource ${G_SSG} ${G_AUTH_TOKEN} clusterProperties/b1aed5f2d521c4565da5a54facfe0283 "/root/build_bundle/base/audit.sink.policy.guid.xml"

logging INFO "Update Gateway Node Name"
echo "update cluster_info set name = '`hostname`';" > /tmp/cluster_name.sql
mysql -u root ssg < /tmp/cluster_name.sql

logging INFO "Update password policy and admin password policy"
mysql -u root ssg < /root/build_bundle/mysql-queries/password-policy.sql

logging "Update service resolution settings"
mysql -u root ssg < /root/build_bundle/mysql-queries/service-resolution.sql

logging INFO "Update Log Sink Definitions"
mysql -u root ssg < /root/build_bundle/mysql-queries/log-sinks_v2.sql

logging INFO "Update Audit Sink settings"
mysql -u root ssg < /root/build_bundle/mysql-queries/audit-sink.sql

service ssg restart
logging INFO "Waiting for the gateway process to restart."
timeout 300s /bin/bash -c '
while [[ "$(curl -sk https://localhost:8443/ssg/webadmin/ -w %{http_code}\\n -o /dev/null)" != "200" ]]
do
  sleep 15
  echo "$(date) Still waiting ..."
done'

if [[ $? == 0 ]]; then
  logging INFO "OK: gateway started."
else
  logging ERROR "Failed to start the gateway."
fi

# cleanup
rm -f /tmp/cluster_name.sql
rm -rf /opt/SecureSpan/Gateway/node/default/etc/bootstrap

# handover to next script
touch /root/ready_for_app_deployment

logging INFO "Completed"
