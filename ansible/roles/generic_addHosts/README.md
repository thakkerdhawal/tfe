generic_addHosts
=========

In NWM Terraform build, we store the IP addresses (comma separated) of EC2 instance it built in Consul. This role can be used to retrieve IP addresses of certain type of hosts and add them into in-memory inventory, or allowing user to pass target hosts on command line.

Requirements
------------

* A playbook which can call this role
* Valid Consul token defined in environment variable or passed in as extra var
or  
* A list of hosts to pass on command line, in which case the playbook will not perform consul lookup

Role Variables
--------------

This role requires a number of variables to be populated to run. Without the mandatory variables being defined the role will fail to execute.

The below list uses the following format: varName_ - _description_ -  _Sample_ _value_

#### Mandatory Vars ####
* __groupName__ - Group name for the retrieved hosts in inventory - vlproxy
At least one of the following two variables as they are mutually exclusive.
* __consulKeyPath__ - Full endpoint of Consul Key path to the IP addresses - <consulUrl>
* __targetHosts__ - a static list of hosts to target inputted as an extra var.  - 10.8.100.15,10.8.100.16

#### Optional Vars ####
* __consulTokenPassword__ - A Consul Token with read permission to the target key path


Dependencies
------------
N/A

Example Playbook
----------------
The following playbook will do Consul lookup when there is no __targetHosts__ specified, or use user input when targetHosts is defined. For example: ```-e 'targetHosts=["10.8.98.1","10.8.98.2"]'```. 
```
# use hosts data in Consul 
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
  - role: generic_addHosts
    vars:
      consulKeyPath: "https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/{{ awsEnv }}/terraform/core/outputs/agilemarkets/{{ awsRegion }}/apigw_instances_private_ip?raw"
      groupName: apigw
```
