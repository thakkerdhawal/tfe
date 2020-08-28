#!/bin/bash
set -e

# set umask for file creation reasonably open
umask 022
# location of log
LOGFILE=/var/log/packer-build-hardening.log
> $LOGFILE
EXTRA_RPMS="unzip firewalld scap-security-guide selinux-policy-devel"
CONFIG=/home/ec2-user/config

# log events to a file and the screen
function log_event() {
  echo "$1" | tee -a $LOGFILE
}

# install oscap and run the remediation applying C2S profile
function install_and_remediate_oscap() {
  log_event  "Applying C2S Security Profile"
  oscap xccdf eval --remediate --profile xccdf_org.ssgproject.content_profile_C2S --results /var/tmp/remediate-results-c2s.xml /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml | tee -a /var/tmp/install_and_remediate_oscap.log
}

function post_remediate_report_oscap() {
  log_event  "Create a post remediation report"
  oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_C2S --results /var/tmp/post-remediate-results-c2s.xml /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml | tee -a /var/tmp/post_remediate_report_oscap.log
}

# update /etc/fstab with tmpfs and bind mount of /var/tmp
# make a dynamic tmpfs restrict size based upon amount of mem on the host
#
function mount_tmp() {
  log_event "Adding /tmp and /var/tmp to fstab and setting nodev, noexec mount options"
  # /tmp is 1st
  grep -q "tmpfs[ ]*/tmp[ ]*tmpfs[ ]*size=1024m,rw,nodev,noexec,nosuid[ ]*0[ ]*0" /etc/fstab || echo -e "tmpfs                   /tmp                    tmpfs   size=1024m,rw,nodev,noexec,nosuid 0 0" >> /etc/fstab
  grep -q "/tmp[ ]*/var/tmp[ ]*none[ ]*rw,nodev,noexec,nosuid,bind[ ]*0[ ]*0" /etc/fstab || echo -e "/tmp                    /var/tmp                none    rw,nodev,noexec,nosuid,bind     0 0" >> /etc/fstab
}

function deploy_system_config() {
  log_event "Deploy system configurations"
  # disable IPv6 Networking support
  # set /etc/issue
  # set /etc/chrony.conf
  # setup the hardened /etc/profile for TMOUT and umask
  cp -rv $CONFIG/etc/* /etc
  chmod 644 /etc/profile.d/harden.sh
  # install rbs services
  cp -rv $CONFIG/services/*.service /usr/lib/systemd/system
}

## set noexec on /dev/shm
function set_noexec_shm() {
  log_event "Setting noexec on /dev/shm"
  grep -q "shmfs[ ]*/dev/shm[ ]*tmpfs[ ]*nodev,nosuid,noexec[ ]*0[ ]*0" /etc/fstab || echo -e "\nshmfs   /dev/shm        tmpfs   nodev,nosuid,noexec     0       0"	>> /etc/fstab
}

function disable_firewalld() {
  log_event  "Install but disable firewalld"
  systemctl disable firewalld
}

# install extra packages that don't require config
# or disabling/enabling
function install_extrarpms() {
  log_event "Update RPM packages via yum"
  yum clean all 
  yum -y update
  log_event "Install extra RPM packages via yum"
  yum -y install $EXTRA_RPMS
}

# Ensure auditd Collects Information on Kernel Module Loading and Unloading
# goes in /etc/audit/auditd.conf, /etc/audit/rules.d, /etc/audit/audit.d/modules.rules
# NB the scap remdiation misses the line
# -a always,exit -F arch=b32 -S init_module,delete_module -k modules
# so have added it to both files
function auditd_collects_kernel_module() {
  log_event  "Fix issue with auditd for kermel modules"
  # add the missing line to the /etc/audit/audit.rules file and the /etc/audit/rules.d/modules.rules file
  # grep -q "\-a[ ]*always,exit[ ]*-F[ ]*arch=b32[ ]*-S[ ]*init_module[ ]*-S[ ]*delete_module[ ]*-k[ ]*modules" /etc/audit/audit.rules || echo -e "\n-a always,exit -F arch=b32 -S init_module -S delete_module -k modules" >> /etc/audit/audit.rules 
  grep -q "\-a[ ]*always,exit[ ]*-F[ ]*arch=b64[ ]*-S[ ]*init_module[ ]*-S[ ]*delete_module[ ]*-k[ ]*modules" /etc/audit/rules.d/modules.rules || echo -e "\n-a always,exit -F arch=b64 -S init_module -S delete_module -k modules" >> /etc/audit/rules.d/modules.rules
}

# Update ssh config file
function setup_sshd_config() {
  log_event "Update cryptographic algorithms"
  sed -i '/\/etc\/ssh\/ssh_host_dsa_key/d' /etc/ssh/sshd_config
  sed -i '/\/etc\/ssh\/ssh_host_ecdsa_key/d' /etc/ssh/sshd_config
  sed -i '/^Ciphers/d' /etc/ssh/sshd_config
  sed -i '/^KexAlgorithms/d' /etc/ssh/sshd_config
  sed -i '/^MACs/d' /etc/ssh/sshd_config
  sed -i '/^Host \*/ a \ \ StrictHostKeyChecking no' /etc/ssh/ssh_config
  sed -i '/^Host \*/ a \ \ UserKnownHostsFile \/dev\/null' /etc/ssh/ssh_config
  echo "# RBS restricted cryptographic algorithms" >> /etc/ssh/sshd_config
  echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" >> /etc/ssh/sshd_config
  echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group18-sha512,diffie-hellman-group16-sha512" >> /etc/ssh/sshd_config
  echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config
  
  sed -i '/^#MaxAuthTries/s/^#MaxAuthTries/MaxAuthTries/g' /etc/ssh/sshd_config
  grep -q "^LogLevel[ ]*INFO" /etc/ssh/sshd_config || echo -e "\nLogLevel INFO" >> /etc/ssh/sshd_config

  log_event  "Allow Trusted User CA Key"
  grep -q "^TrustedUserCAKeys" /etc/ssh/sshd_config || echo -ne "\nTrustedUserCAKeys /etc/ssh/vault-trusted-user-ca-key.pem" >> /etc/ssh/sshd_config
  chmod 640 /etc/ssh/vault-trusted-user-ca-key.pem

  # log_event  "Setting Signed Host Certificate"
  # grep -q "^HostCertificate" /etc/ssh/sshd_config || echo -e "\nHostCertificate /etc/ssh/ssh_host_ecdsa_key-cert.pub" >> /etc/ssh/sshd_config
  log_event  "Restart SSH"
  systemctl restart sshd
}


# Install cloudwatch agent
function cloudwatch_agent() {
  log_event "Install and configure cloudwatch agent"
  mkdir /root/cwa
  curl -o /root/cwa/AmazonCloudWatchAgent.zip https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip
  unzip /root/cwa/AmazonCloudWatchAgent.zip -d /root/cwa
  cd /root/cwa; ./install.sh
  cp -vf $CONFIG/amazon-cloudwatch-agent/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc
  chown -R root:e0000000 /opt/aws/amazon-cloudwatch-agent/etc
  chmod -R g+w /opt/aws/amazon-cloudwatch-agent/etc
  systemctl enable amazon-cloudwatch-agent.service
  cd /root
  rm -rf /root/cwa
}

function setup_httpd_context() {
  cd $CONFIG/selinux/jbcs-httpd24-httpd
  make -f /usr/share/selinux/devel/Makefile
  semodule -i jbcs-httpd24-httpd.pp
  setsebool -P httpd_enable_cgi off
  setsebool -P httpd_graceful_shutdown off
  setsebool -P httpd_builtin_scripting off
  setsebool -P httpd_can_network_connect on
  # used by bondsyndicate
  semanage port -a -t http_port_t -p tcp 8444
}

# tidy up 
function tidy_up() {
  log_event  "Tidying Up Keys"
  # remove root authorized_keys
  rm -vrf /root/.ssh
  # remove host keys so they are auto generated for each instance started from this AMI
  rm -vrf /etc/ssh/ssh_host*key*
  rm -vrf $CONFIG
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
  # deploy default sudoer file
  cat $CONFIG/sudo_rule  >> /etc/sudoers
  # lockdown sudoer file
  sed -i '/^#includedir/d' /etc/sudoers
  chattr +i /etc/sudoers
}

# do the ecomm settings
function setup_ecomm_dir() {
  log_event  "Creating and seting permissions on ecomm directory"
  mkdir -p /opt/app/ecomm/Web
  chown -R e0000010:e0000000 /opt/app/ecomm
  chmod -R 1775 /opt/app/ecomm
  if [ ! -L /ecomm ]; then
    ln -s /opt/app/ecomm /ecomm
  fi
}

function setup_aide() {
  log_event "Setup Advanced Intrusion Detection Environment"
  # files expected to change post build
  sed -i '/^\/opt/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/group/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/gshadow/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/passwd/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/shadow/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/hostname/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/udev/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/sudoers\.d/s/^/!/g' /etc/aide.conf
  sed -i '/^\/etc\/ssh\/ssh_config/ a !\/etc\/ssh\/ssh_host_.*' /etc/aide.conf
  sed -i '/^\/etc\/sysconfig\// a !\/etc\/sysconfig\/network-scripts\/ifcfg-.*' /etc/aide.conf
  sed -i '/^\/root\/ / a !\/root\/\.ssh\/' /etc/aide.conf
  sed -i '/^\/root\/ / a !\/root\/\.pki\/' /etc/aide.conf
  aide --init
  mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
}

function remove_ec2_user () {
  # TODO: remove the default ec2-user
  # NOTE: adding e0000000 during integration phase
  usermod -a -G e0000000 ec2-user
}

##########################################################################################################################################
#
## MAIN
#
if [[ $POST_REBOOT == false ]]; then
  install_extrarpms 
  set_noexec_shm
  mount_tmp
  auditd_collects_kernel_module
  install_and_remediate_oscap
  deploy_system_config
  disable_firewalld
  setup_runtime_accounts
  setup_httpd_context
  setup_ecomm_dir
  setup_sshd_config
  cloudwatch_agent
  # reboot to apply changes
  log_event "Build completed. Reboot..."
  reboot
else
  post_remediate_report_oscap
  remove_ec2_user
  setup_aide
  # always at end remove the host and root autohorised keys
  tidy_up
fi
