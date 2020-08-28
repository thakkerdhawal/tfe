## healthCheck.yml Playbook ##

Sample Ansible playbook to compliment the [generic_healthCheck role](../../roles/generic_healthCheck)
Read the documentation there for how to re-use the role.

This playbook purely exists to demonstrate how to run the healthcheck role, though there is no reason why it cannot be used by other processes or cicd to test certain apps.

The playbook shows the use case for:
* Connecting to a host via ssh and running healthchecks from there, i.e. test that an app is up and running on that specific host

Requirements
------------
* You have a valid Consul Token
* You will run this on either a jumphost or on tooling

__If running on Ansible core__
* You have run the [awsProxyJump.yml](../awsProxyJump.yml) playbook
* Extra vars are passed in at the command line

__If running on Tooling (Ansible Tower)__
* If running on Tooling (Tower), temporary AWS creds will be generated based on the DES channel and environment that you define when running the playbook via the DWS client. These temporary credentials will be accessible via environment vars.
* Extra vars need to be created in a text file on your local file system and this file will need to be passed to the dws client as an argument on job invocation.

Variables Used
--------------

The below list uses the following format: varName_ - description - Sample value

* This does not document vars required by the [generic_healthCheck role](../../roles/generic_healthCheck)
* It documents what vars are required in addition to run this playbook and call that role.

#### Mandatory Vars ####

* __consulKeyPath__ - Full endpoint of Consul Key path to the IP addresses - https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/{{ awsEnv }}/terraform/core/outputs/agilemarkets/{{ awsRegion }}/apigw_instances_private_ip?raw
* __consulTokenPassword__ -  Consul Token required to access vlproxy outputs - "11223d1e8-ffff-10ac-1626-bsd1f11622448" (sample) - Mandatory when using consul
* __theUser__ - What account should ansible become to install, configure and own permissions for VLProxy (default value of e0000047 specified in vars_files file)- e0000047

## Getting Started on Ansible CORE (not Tower/Tooling)

Before running anything, work out what it is you want to do. Refer to the options described in the [role README](../../roles/generic_healthCheck)

### Perform a simple port test with a custom delay and timeout ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckHost.yml -e "consulKeyPath=https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/core/outputs/agilemarkets/eu-west-2/apigw_instances_private_ip?raw theDelay=0 theTimeout=10 thePort=22 consulTokenPassword=a01234 theUser=e0000050"
```

### Perform a port test and look for a string in the port response ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckHost.yml -e "consulKeyPath=https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/core/outputs/agilemarkets/eu-west-2/apigw_instances_private_ip?raw thePort=22 theString=OpenSSH consulTokenPassword=a01234 theUser=e0000050"
```

### Perform a URL test with a custom timeout and check for the default 200, 201, 202 status code response ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckHost.yml -e "consulKeyPath=https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/core/outputs/agilemarkets/eu-west-2/apigw_instances_private_ip?raw theTimeout=10 theUrl=http://www.bbc.co.uk/sport:80 consulTokenPassword=a01234 theUser=e0000050"
```

### Perform a URL test and check for a string in the returned content ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckHost.yml -e "consulKeyPath=https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/core/outputs/agilemarkets/eu-est-2/apigw_instances_private_ip?raw theUrl=http://localhost:8080/bla theString=login consulTokenPassword=a01234 theUser=e0000050"
```

## Getting Started on Tooling (Ansible Tower)
tbc.


Author Information
------------------
Initially Created by David Roberts - david.roberts@natwestmarkets.com

Version
------------------
0.1

