#!/bin/bash
set -e 

# Initialization
TEMP=${TEMP:-/root}
CONFIG=/root/config
VERBOSE=${VERBOSE:-false}
S3ENDPOINT=https://s3-eu-west-1.amazonaws.com
RPM=${RPM:-"libpcap-1.0.0-6.20091201git117cb5.el6.x86_64.rpm tcpdump-4.0.0-3.20090921gitdf3cb4.1.el6.x86_64.rpm"}
CWA_FILENAME=${CWA_FILENAME:-AmazonCloudWatchAgent.zip}

function logging () {
  [[ -z $LOGFILE ]] && { LOGFILE=$(mktemp $TEMP/$(basename $0)-log.XXXX) ; logging INFO "Creating log file $LOGFILE"; }
  if [[ $VERBOSE == true || ! "$1" == DEBUG ]]; then
    echo "`/bin/date +%F-%T` $*" | tee -a $LOGFILE
  fi

  if [[ "$1" == ERROR ]]; then
    exit 1
  fi
}

function download_from_s3 () {
  [[ ! -z $1 ]] && logging DEBUG "Pulling S3 object: $1" || logging ERROR "Please provide the S3 object to download"
  instance_profile=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/) || logging ERROR "Failed to find IAM profile attached to the instance."
  aws_access_key_id=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep AccessKeyId | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS Access key"
  aws_secret_access_key=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep SecretAccessKey | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS Secret Access key"
  token=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${instance_profile} | grep Token | awk -F \" '{print $4}') || logging ERROR "Failed to get AWS token"
  date=$(date +'%a, %d %b %Y %H:%M:%S %z')
  signature=$(/bin/echo -en "GET\n\n\n${date}\nx-amz-security-token:${token}\n/${1}" | openssl sha1 -hmac ${aws_secret_access_key} -binary | base64)
  authorization="AWS ${aws_access_key_id}:${signature}"
  if curl -Ok -H "Date: ${date}" -H "X-AMZ-Security-Token: ${token}" -H "Authorization: ${authorization}" ${S3ENDPOINT}/${1}; then
    logging DEBUG "File downloaded from S3"
  else
    logging ERROR "Failed to download S3 object: ${S3ENDPOINT}/${1}"
  fi
}

function rpm_download_and_install () {
  logging DEBUG "Downloading ${1}"
  download_from_s3 "${S3BUCKET}/${1}"
  logging DEBUG "Installing $(basename ${1})"
  /bin/rpm -ivh $(basename ${1})
  logging DEBUG "Removing downloaded file $(basename ${1})"
  rm -f $(basename ${1})
}

# Install cloudwatch agent
function install_cloudwatch () {
  [[ ! -d /root/cwa ]] && mkdir /root/cwa && cd $_
  logging DEBUG "Downloading ${1}"
  download_from_s3 "${S3BUCKET}/${1}"
  unzip $(basename ${1})
  logging DEBUG "Installing CloudWatch agent"
  ./install.sh
  cp -f ${CONFIG}/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc
  chown -R root:e0000000 /opt/aws/amazon-cloudwatch-agent/etc
  chmod -R g+w /opt/aws/amazon-cloudwatch-agent/etc
  logging DEBUG "Clean up CloudWatch install."
  cd && rm -rf /root/cwa
}

# Update ssh config file
function setup_ssh() {
  logging INFO "Setting LogLevel to INFO in sshd_config"
  grep -q "^LogLevel[ ]*INFO" /etc/ssh/sshd_config || echo -e "\nLogLevel INFO" >> /etc/ssh/sshd_config

  logging "Update cryptographic algorithms"
  sed -i '/^Ciphers/d' /etc/ssh/sshd_config
  sed -i '/^MACs/d' /etc/ssh/sshd_config
  echo "# RBS restricted cryptographic algorithms" >> /etc/ssh/sshd_config
  echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" >> /etc/ssh/sshd_config
  echo "MACs hmac-sha1,hmac-ripemd160"  >> /etc/ssh/sshd_config

  logging INFO "Allow Trusted User CA Key"
  grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo -e "\nTrustedUserCAKeys /etc/ssh/vault-trusted-user-ca-key.pem" >> /etc/ssh/sshd_config
  chmod 640 /etc/ssh/vault-trusted-user-ca-key.pem

  logging INFO "Restart SSH"
  service sshd restart

  logging INFO "Tidying Up Keys"
  # remove root authorized_keys
  rm -rf /root/.ssh
  rm -rf /home/ec2-user/.ssh
  # remove host keys so they are auto generated for each instance started from this AMI
  rm -rf /etc/ssh/ssh_host*key*
}

function create_group() {
  # Usage: create_group ${grp} ${gid}
  local grp=$1
  local gid=$2
  echo "Creating group $gid ($grp)..."
  [[ -z $(getent group $gid | cut -d: -f3 2>/dev/null) ]]  && /usr/sbin/groupadd -g ${gid} ${grp}
}

function create_user() {
  # Usage: create_user ${usr} ${uid} ${group}
  local usr=$1
  local uid=$2
  local grp=$3
  /usr/sbin/useradd -U -u ${uid} -G ${grp} -s /bin/bash ${usr} > /dev/null 2>&1
  /usr/bin/passwd -x 99999 ${usr}
}

# setup DES Tooling runtime accounts
function setup_runtime_accounts() {
  # create default DES runtime account group
  create_group e0000000 2000
  # create  default privileged accounts
  create_user e0000010 14010 e0000000

  #### TEMP before Tooling integration ####
  create_user ec2-user 14000 e0000000
  cat <<EOF >/etc/cloud/cloud.cfg.d/00_defaults.cfg
#cloud-config
disable_root: 1
system_info:
  default_user:
    name: ec2-user
EOF

  # create  default runtime accounts
  create_user e0000007 14007 e0000000
  # deploy default sudoer file
  cat $CONFIG/sudo_rule  >> /etc/sudoers
  # lockdown sudoer file
  sed -i '/^#includedir/d' /etc/sudoers
  chattr +i /etc/sudoers
}

[[ -z ${S3BUCKET} ]] && { logging ERROR "Missing input. Please set S3BUCKET in environment variable."; }

#
# Starting build customisation
#

logging INFO "Starting API Gateway build customisation."

# Default account password will not expire
logging INFO "Default account password will not expire"
chage -M 99999 ssgconfig
chage -M 99999 root

# Extra RPM install
logging INFO "Install extra RPMs"
for i in ${RPM}
do
  rpm_download_and_install ${i}
done

# Set system timezone to UTC
logging INFO "Set system timezone to UTC"
rm /etc/localtime
ln -s /usr/share/zoneinfo/UTC /etc/localtime 

logging INFO "Deploy default configurations"
# Set default iptable
cp -f ${CONFIG}/iptables /etc/sysconfig/iptables && chmod 644 /etc/sysconfig/iptables
# Install rsyslog template
cp -f ${CONFIG}/rsyslog.conf /etc/rsyslog.conf && chmod 644 /etc/rsyslog.conf
# Setup NTP
cp -f ${CONFIG}/ntp.conf /etc/ntp.conf && chmod 644 /etc/ntp.conf
# Install cron jobs
cp -f ${CONFIG}/*.cron /etc/cron.d && chmod 644 /etc/cron.d/*.cron
# Deploy customised scripts
cp -f ${CONFIG}/*.sh /usr/local/bin && chmod 744 /usr/local/bin/*.sh

# Disable IPv6
logging INFO "Disable IPv6"
chkconfig ip6tables off
sed -i '/net.ipv6.conf.*/d' /etc/sysctl.conf
sed -i '$ a net.ipv6.conf.all.disable_ipv6 = 1' /etc/sysctl.conf
sed -i '$ a net.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf
sed -i 's/^[[:space:]]*::/#::/' /etc/hosts

# Update java DNS caching TTL: https://comm.support.ca.com/kb/api-gateway-dns-ttl/kb000012118
# AWS recommends re-resolving DNS at least every 60 sec
logging INFO "Update java DNS caching TTL"
sed -i '/^default_java_opts="-server "/a default_java_opts="$default_java_opts -Dsun.net.inetaddr.ttl=60"' /opt/SecureSpan/Gateway/runtime/etc/profile.d/ssgruntimedefs.sh


logging INFO "Create DES runtime accounts"
setup_runtime_accounts
# Install CloudWatch Agent for logging and metrics
logging INFO "Install CloudWatch agent"
install_cloudwatch ${CWA_FILENAME}
setup_ssh
