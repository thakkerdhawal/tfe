# apache_setup.yml

Ansible playbook to deploy apache instance on AWS EC2 instances

## Overview

EC2 instances are provisioned in NWM Core VPC, and this playbook will perform the following actions:

- extract the target instances IP from Consul and add to inventory
- download apache core build  package from Artifactory and upload to target hosts (role: generic_afServerFileCopy)
- deploys apache instance and configuration on target hosts (role: apache_deploy)


## Prerequisites

Consul access token is required to read KV. It can either be defined in environment var **CONSUL_HTTP_TOKEN** or pass into the playbook as extra var **consulTokenPassword**

## Variables Used

The following vars must be passed into the playook as extra vars:
- awsEnv
- awsRegion
- apacheInstanceName

The following vars are required by the roles and have been defined in vars_files/apache. They can also be passed into the playbook as extra vars to overwrite default values:


# role var - apache_deploy

- theUser
- afUrl
- afFile
- destFilePath
- packageLocation
- apacheUser: ec2-user
- apacheGroup: ec2-user
- apacheUpdateFlag: True


# apachePort 

apachePort is dynamically calculated but one can overwrite the value by settting as extra vars.
Note, apachePort is calculated from httpd-ssl.conf file on target host, using Listen statement.
By default selinux allows 8443 port.

## Optional Variables
- targetHosts: Set this variable when you want to run apache_deploy role on specific targeted hosts rather than all the hosts in a group. This is used in terraform to run apache_deploy role on targeted host (as we may not rebuild all the hosts in a given awsRegion).
Example:
$ ansible-playbook playbooks/apache/apache_setup.yml -e "awsEnv=lab" -e "awsRegion=eu-west-2" -e "apacheInstanceName=agilemarkets" -e "targetHosts=['10.10.1.1']"


## Getting Started


Example:
```
$ export CONSUL_HTTP_TOKEN=XXXX
$  ansible-playbook playbooks/apache/apache_setup.yml -e "awsEnv=lab" -e "awsRegion=eu-west-2" -e "apacheInstanceName=agilemarkets"
 [WARNING]: Unable to parse /home/thakwal/workspace/nwm_infra_tf_engineering/ansible/inventory as an inventory source

 [WARNING]: No inventory was parsed, only implicit localhost is available

 [WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'


PLAY [localhost] **********************************************************************************************************************************************************************************************************************************************************************************

TASK [check for consul token] *********************************************************************************************************************************************************************************************************************************************************************
ok: [localhost]

TASK [fail] ***************************************************************************************************************************************************************************************************************************************************************************************
skipping: [localhost]

TASK [debug] **************************************************************************************************************************************************************************************************************************************************************************************
skipping: [localhost]

TASK [lookup apache instance in Consul for awsRegion eu-west-2] **************************************************************************************************************************************************************************************************************************************
ok: [localhost]

TASK [Add hosts to apache group] ******************************************************************************************************************************************************************************************************************************************************************
changed: [localhost] => (item=10.8.2.126)

PLAY [apache] *************************************************************************************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************************************************************************************************************************************************************************
ok: [10.8.2.126]

TASK [generic_afServerFileCopy : Create local 'files' directory (if it doesn't exist) at location "/home/thakwal/workspace/nwm_infra_tf_engineering/ansible/playbooks/apache/files/"] *************************************************************************************************************
ok: [10.8.2.126 -> localhost]

TASK [generic_afServerFileCopy : Auth Required - get target file info] ****************************************************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [generic_afServerFileCopy : Auth Not Required - get target file info] ************************************************************************************************************************************************************************************************************************
ok: [10.8.2.126 -> localhost]

TASK [generic_afServerFileCopy : Print sha1sum of AF file if verbosity is 2 or greater] ***********************************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [generic_afServerFileCopy : Auth Required - Download single file from Artifactory to local Ansible server in the "/home/thakwal/workspace/nwm_infra_tf_engineering/ansible/playbooks/apache/files/" directory, so Ansible can later copy it to the target host(s)] ***************************
skipping: [10.8.2.126]

TASK [generic_afServerFileCopy : Auth Not Required - Download single file from Artifactory to local Ansible server in the "/home/thakwal/workspace/nwm_infra_tf_engineering/ansible/playbooks/apache/files/" directory, so Ansible can later copy it to the target host(s)] ***********************
changed: [10.8.2.126 -> localhost]

TASK [generic_afServerFileCopy : Copy locally downloaded file to remote host(s)] ******************************************************************************************************************************************************************************************************************
ok: [10.8.2.126]

TASK [generic_afServerFileCopy : Remove locally downloaded AF file as part of playbook cleanup] ***************************************************************************************************************************************************************************************************
changed: [10.8.2.126 -> localhost]

TASK [apache_deploy : Check for existing apache instance: agilemarkets] ***************************************************************************************************************************************************************************************************************************
ok: [10.8.2.126]

TASK [apache_deploy : Stop run if apache instance already exists and apacheUpdateFlag is set to False] ********************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [apache_deploy : Check if Apache is running] *************************************************************************************************************************************************************************************************************************************************
fatal: [10.8.2.126]: FAILED! => {"changed": false, "cmd": "ps aux | grep agilemarkets | grep -v grep", "delta": "0:00:00.028129", "end": "2019-02-06 10:55:34.942170", "msg": "non-zero return code", "rc": 1, "start": "2019-02-06 10:55:34.914041", "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
...ignoring

TASK [apache_deploy : Get existing service path to stop build prior to update] ********************************************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [apache_deploy : Stop running build prior to update] *****************************************************************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [apache_deploy : Create apache instance directory] *******************************************************************************************************************************************************************************************************************************************
changed: [10.8.2.126]

TASK [apache_deploy : Unpack apache archive] ******************************************************************************************************************************************************************************************************************************************************
changed: [10.8.2.126]

TASK [apache_deploy : Check if httpd-ssl.conf is available in instance config] ********************************************************************************************************************************************************************************************************************
ok: [10.8.2.126 -> localhost]

TASK [apache_deploy : Grab ports from httpd-ssl.conf for selinux config] **************************************************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [apache_deploy : Set apachePort] *************************************************************************************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [apache_deploy : Set apacheExec  and apacheConf Path] ****************************************************************************************************************************************************************************************************************************************
ok: [10.8.2.126]

TASK [apache_deploy : Copy apache instance: agilemarkets config directory] ************************************************************************************************************************************************************************************************************************
changed: [10.8.2.126]

TASK [apache_deploy : Update SElinux policy to allow apache to listen on tcp ports] ***************************************************************************************************************************************************************************************************************
skipping: [10.8.2.126]

TASK [apache_deploy : Apply SELinux file context to apache instance dir /opt/app/ecomm/Web/agilemarkets] ******************************************************************************************************************************************************************************************
changed: [10.8.2.126]

TASK [apache_deploy : Start apache instance] ******************************************************************************************************************************************************************************************************************************************************
changed: [10.8.2.126]

PLAY RECAP ****************************************************************************************************************************************************************************************************************************************************************************************
10.8.2.126                 : ok=15   changed=7    unreachable=0    failed=0
localhost                  : ok=3    changed=1    unreachable=0    failed=0

