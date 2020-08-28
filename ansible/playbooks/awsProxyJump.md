# Project Title

Create dedicated sshconfig file in ~/.ssh/ for "proxyjump" direct access to EC2 instances in AWS.

__Do NOT Run this on Tooling__

## Overview

This playbook will configure proxyJump capability for lab, nonprod, cicd and prod environments. It covers both core and shared-services subnets where applicable (i.e. no nonprod shared-services)

These instructions will help you configure a proxyjump configuration to access the EC2 instances in the AWS lab environment

You will need to run this from either of the NWM SDP jumphosts (lonrs13394 or lonrs13395), but only one or it will cause an issue in your ~/.ssh/known_hosts file

This configuration will match the overall architecture that Tooling is using with Ansible Tower (Tower instances are also on-campus).

## Prerequisites

- Unix account
- Access to lonrs13394/lonrs13395
- ** SSH key to access the Bastion Hosts and EC2 instances located at ~/.ssh/ec2-key.pem **
- ~/.ssh directory has 0700 permissions
- Files within ~/.ssh/ directory have 0600 permissions
- Outputs of the Bastion host IPs are in Consul
- Public and Private subnets for the environment (i.e. lab) and region (i.e. eu-west-1) are defined in Consul

## Variables Used

The following vars are MANDATORY and should be passed as an extra var

- consulTokenPassword - this should be the consul token to access information from Consul.

Note: As an alternative, the above var can be set as an enviroment variable and doesnt need to be passed as an extra var. It can be set via command:
```
export CONSUL_HTTP_TOKEN="the-token-value"
```

The following vars are OPTIONAL and can passed into the playbook as extra vars roles/awsProxyJump/defaults/main.yml

- consulHost
- consulPort

## Created Files
The following files will be created:

 - $HOME_DIR/ssh_config.awsNwm - this file will contain the proxy configuration for the NWM AWS environments. There will be bastion hosts defined as well as the public and private subnets. Regions eu-west-1 and eu-west-2 will be covered.  It assumes that the first 3 octets of any private subnets in the same region are identical, i.e. 10.8.3.*. It will assume that the first 3 octets of any public subnets in the same region are identical, i.e. 10.8.2.*.   It has been noted that in shared services, intra and private subnets share the same first 3 octets, thus duplicates will be commented out in the file.

 - $ANSIBLE_HOME/ansible.cfg - a templated file will be produced that will provide an updated ansible.cfg file which will reference the $HOME_DIR/ssh_config.awsNwm file so that Ansible can utilise the proxy configuration to access the aws environments directly. This will mimic how the Tower Tooling solution works.

 - $ANSIBLE_HOME/inventory/hosts - A templated file will be produced that will configure a hosts inventory file which covers localhost and the correct local connection option


## Getting Started
This assumes you have checked out this code and are attempting to run it on lonrs13394 or lonrs13395 with your normal Unix account (not root)

1) Navigate to the Ansible Home directory (where the inventory,playbooks, roles folders are located) - directory above this file
2) Run command: ansible-playbook playbooks/awsProxyJump.yml -e "consulTokenPassword=<theConsulToken>"
3) If wanting to see a full list of all the subnets captured run the above command with: ansible-playbook playbooks/awsProxyJump.yml -e "consulTokenPassword=<theConsulToken>" -v

Example of a normal run:

The below code demonstrates a successful playbook run

```
ansible-playbook playbooks/awsProxyJump.yml -e "consulTokenPassword=aaf811666d22-10-1121-121121212112"
 [WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'


PLAY [localhost] *******************************************************************************************************************************************************************************************

TASK [../roles/awsProxyJump : check for consul token] ******************************************************************************************************************************************************
skipping: [localhost]

TASK [../roles/awsProxyJump : fail] ************************************************************************************************************************************************************************
skipping: [localhost]

TASK [../roles/awsProxyJump : Get Ips of EU-West-1 bastion hosts from Consul] ******************************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/shared-services/outputs/bastion/eu-west-1/bastion_hosts_private_ips?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/terraform/shared-services/outputs/bastion/eu-west-1/bastion_hosts_private_ips?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/terraform/shared-services/outputs/bastion/eu-west-1/bastion_hosts_private_ips?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : Get Ips of EU-West-2 bastion hosts from Consul] ******************************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/shared-services/outputs/bastion/eu-west-2/bastion_hosts_private_ips?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/terraform/shared-services/outputs/bastion/eu-west-2/bastion_hosts_private_ips?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/terraform/shared-services/outputs/bastion/eu-west-2/bastion_hosts_private_ips?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : Get Intra Subnets of Core EU-West-1 environments] ****************************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/core/eu-west-1/intra_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/nonprod/variables/core/eu-west-1/intra_subnets?raw', u'label': u'nonprod'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/core/eu-west-1/intra_subnets?raw', u'label': u'cicd'})

TASK [../roles/awsProxyJump : Get Public Subnets of Core EU-West-1 environments] ***************************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/core/eu-west-1/public_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/nonprod/variables/core/eu-west-1/public_subnets?raw', u'label': u'nonprod'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/core/eu-west-1/public_subnets?raw', u'label': u'cicd'})

TASK [../roles/awsProxyJump : Get Intra Subnets of Core EU-West-2 environments] ****************************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/core/eu-west-2/intra_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/nonprod/variables/core/eu-west-2/intra_subnets?raw', u'label': u'nonprod'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/core/eu-west-2/intra_subnets?raw', u'label': u'cicd'})

TASK [../roles/awsProxyJump : Get Public Subnets of Core EU-West-2 environments] ***************************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/core/eu-west-2/public_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/nonprod/variables/core/eu-west-2/public_subnets?raw', u'label': u'nonprod'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/core/eu-west-2/public_subnets?raw', u'label': u'cicd'})

TASK [../roles/awsProxyJump : Get Intra Subnets of Shared-Services EU-West-1 environments] *****************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/shared-services/eu-west-1/intra_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/shared-services/eu-west-1/intra_subnets?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/variables/shared-services/eu-west-1/intra_subnets?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : Get Private Subnets of Shared-Services EU-West-1 environments] ***************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/shared-services/eu-west-1/private_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/shared-services/eu-west-1/private_subnets?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/variables/shared-services/eu-west-1/private_subnets?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : Get Public Subnets of Shared-Services EU-West-1 environments] ****************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/shared-services/eu-west-1/public_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/shared-services/eu-west-1/public_subnets?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/variables/shared-services/eu-west-1/public_subnets?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : Get Intra Subnets of Shared-Services EU-West-2 environments] *****************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/shared-services/eu-west-2/intra_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/shared-services/eu-west-2/intra_subnets?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/variables/shared-services/eu-west-2/intra_subnets?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : Get Private Subnets of Shared-Services EU-West-2 environments] ***************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/shared-services/eu-west-2/private_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/shared-services/eu-west-2/private_subnets?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/variables/shared-services/eu-west-2/private_subnets?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : Get Public Subnets of Shared-Services EU-West-2 environments] ****************************************************************************************************************
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/variables/shared-services/eu-west-2/public_subnets?raw', u'label': u'lab'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/cicd/variables/shared-services/eu-west-2/public_subnets?raw', u'label': u'cicd'})
ok: [localhost] => (item={u'url': u'https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/prod/variables/shared-services/eu-west-2/public_subnets?raw', u'label': u'prod'})

TASK [../roles/awsProxyJump : The IPs of EU-West-1 Bastion Hosts are] **************************************************************************************************************************************
skipping: [localhost] => (item=10.8.102.18)
skipping: [localhost] => (item=10.8.110.4)
skipping: [localhost] => (item=10.8.132.22)
skipping: [localhost]

TASK [../roles/awsProxyJump : The IPs of EU-West-2 Bastion Hosts are] **************************************************************************************************************************************
skipping: [localhost] => (item=10.8.104.16)
skipping: [localhost] => (item=10.8.112.18)
skipping: [localhost] => (item=10.8.130.6)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Intra Subnets for Core EU-West-1 are] ************************************************************************************************************************************
skipping: [localhost] => (item=10.8.98.0/27,10.8.98.32/27,10.8.98.64/27)
skipping: [localhost] => (item=10.8.8.0/27,10.8.8.32/27,10.8.8.64/27)
skipping: [localhost] => (item=10.8.106.0/27,10.8.106.32/27,10.8.106.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Public Subnets for Core EU-West-1 are] ***********************************************************************************************************************************
skipping: [localhost] => (item=10.8.99.0/27,10.8.99.32/27,10.8.99.64/27)
skipping: [localhost] => (item=10.8.9.0/27,10.8.9.32/27,10.8.9.64/27)
skipping: [localhost] => (item=10.8.107.0/27,10.8.107.32/27,10.8.107.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Intra Subnets for Core EU-West-2 are] ************************************************************************************************************************************
skipping: [localhost] => (item=10.8.100.0/27,10.8.100.32/27,10.8.100.64/27)
skipping: [localhost] => (item=10.8.6.0/27,10.8.6.32/27,10.8.6.64/27)
skipping: [localhost] => (item=10.8.108.0/27,10.8.108.32/27,10.8.108.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Public Subnets for Core EU-West-2 are] ***********************************************************************************************************************************
skipping: [localhost] => (item=10.8.101.0/27,10.8.101.32/27,10.8.101.64/27)
skipping: [localhost] => (item=10.8.7.0/27,10.8.7.32/27,10.8.7.64/27)
skipping: [localhost] => (item=10.8.109.0/27,10.8.109.32/27,10.8.109.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Intra Subnets for Shared Services EU-West-1 are] *************************************************************************************************************************
skipping: [localhost] => (item=10.8.102.0/27,10.8.102.32/27,10.8.102.64/27)
skipping: [localhost] => (item=10.8.110.0/27,10.8.110.32/27,10.8.110.64/27)
skipping: [localhost] => (item=10.8.132.0/27,10.8.132.32/27,10.8.132.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Private Subnets for Shared Services EU-West-1 are] ***********************************************************************************************************************
skipping: [localhost] => (item=10.8.102.96/28,10.8.102.112/28)
skipping: [localhost] => (item=10.8.110.96/28,10.8.110.112/28)
skipping: [localhost] => (item=10.8.132.96/28,10.8.132.112/28)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Public Subnets for Shared Services EU-West-1 are] ************************************************************************************************************************
skipping: [localhost] => (item=10.8.103.0/27,10.8.103.32/27,10.8.103.64/27)
skipping: [localhost] => (item=10.8.111.0/27,10.8.111.32/27,10.8.111.64/27)
skipping: [localhost] => (item=10.8.133.0/27,10.8.133.32/27,10.8.133.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Intra Subnets for Shared Services EU-West-2 are] *************************************************************************************************************************
skipping: [localhost] => (item=10.8.104.0/27,10.8.104.32/27,10.8.104.64/27)
skipping: [localhost] => (item=10.8.112.0/27,10.8.112.32/27,10.8.112.64/27)
skipping: [localhost] => (item=10.8.130.0/27,10.8.130.32/27,10.8.130.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Private Subnets for Shared Services EU-West-2 are] ***********************************************************************************************************************
skipping: [localhost] => (item=10.8.104.96/28,10.8.104.112/28)
skipping: [localhost] => (item=10.8.112.96/28,10.8.112.112/28)
skipping: [localhost] => (item=10.8.130.96/28,10.8.130.112/28)
skipping: [localhost]

TASK [../roles/awsProxyJump : The Public Subnets for Shared Services EU-West-2 are] ************************************************************************************************************************
skipping: [localhost] => (item=10.8.105.0/27,10.8.105.32/27,10.8.105.64/27)
skipping: [localhost] => (item=10.8.113.0/27,10.8.113.32/27,10.8.113.64/27)
skipping: [localhost] => (item=10.8.131.0/27,10.8.131.32/27,10.8.131.64/27)
skipping: [localhost]

TASK [../roles/awsProxyJump : Produce template file at location $HOME/ssh_config.{{ awsEnv }}-core] ********************************************************************************************************
changed: [localhost]

TASK [../roles/awsProxyJump : Capture absolute path of curent-user home directory (to overcome tilde issue with ssh_args in ansible.cfg)] ******************************************************************
ok: [localhost]

TASK [../roles/awsProxyJump : Create local ansible.cfg file to utilise new sshconfig file] *****************************************************************************************************************
changed: [localhost]

TASK [../roles/awsProxyJump : Create inventory/hosts file to cater for localhost and local_connection] *****************************************************************************************************
ok: [localhost]

PLAY RECAP *************************************************************************************************************************************************************************************************
localhost                  : ok=16   changed=2    unreachable=0    failed=0

```

## Testing

For standard CI/CD processes, a test playbook has been produced within the awsProxyJump role in location awsProxyJump/tests/test.yml.
A simple inventory file also exists in the same location so that it will run it against localhost.

### Further Reading

[Confluence page for tooling with further guidelines on producing Playbooks](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/Ansible+Tower+Solution+-+NMW+Feature+Team+Info)

https://serverfault.com/questions/876903/different-identity-files-when-jumping-through-hosts-and-using-a-single-ssh-confi
https://access.redhat.com/solutions/2891881

## Versioning

Version 0.3

## Authors

* **David Roberts** - david.roberts@natwestmarkets.com

