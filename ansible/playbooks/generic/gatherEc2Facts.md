manageEc2.yml 

Generic Ansible playbook to list EC2 instances on AWS via the boto (python) library which gives Ansible access to the AWS API.

## Overview
 
This playbook exists to allow operators to list EC2 instances and the private IP using tags, Consul IP addresses or instance IDs as a filter. Alternatively you can just list all instances in a region.

This playbook was created to demonstrate to others how the Ansible EC2 instance facts module can be referenced. It is more likely that this will be used as a reference playbook for future audit requirements.

Note: This playbook will need tweaking to run on tooling.

## Prerequisites

You will run this on an RBS jumphost i.e. lonrs13394
 
* The boto, boto3 and botocore packages have been installed via pip (may not be a hard requirement, but is recommended)
* You have valid Active AWS credentials defined as a profile in ~/.aws/credentials 
* You have run the [awsProxyJump.yml](../awsProxyJump.yml) playbook

## Variables Used

The following extra vars can be passed in this role.

The below list uses the following format: varName_ - description - Sample value

#### Mandatory Vars

* __awsProfile__ - This is mandatory on the jumphosts, but not on tooling. AWS Creds Profile Name (to match whats in your aws credentials file). - PROFILE_CORE
* __awsRegion__ - AWS Region - eu-west-2

#### Additional/Optional Vars

* __ec2Name__ -  the Name tag value of the EC2 instance
* __consulUrl__ -  The Consul URL of the output entry that holds the IP address of the ec2 instances - https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/core/outputs/cleo/eu-west-2/vlproxy_ingress_private_ips?raw 
* __consulTokenPassword__ - Consul Token required to access outputs in Consul - "11223d1e8-ffff-10ac-1626-bsd1f11622448" (sample)
* __ec2Id__ - instance ID of the EC2 instance to query - 0a7f4aea5078d7b76

## Getting Started
Before running anything:
* Know how you plan to identify an instance
* Know what AWS profile you need to use
* Know the AWS region that the instance runs in

### Non-Tooling Specific Requirements
* Ensure you have configured your environment with the [playbooks/awsProxyJump.md](playbooks/awsProxyJump.md) playbook
* Ensure you have configured your AD credentials and a profile is present in your ~/.aws/credentials file


## Playbook Examples

### Run the playbook on the Dev Jumphosts (lonrs13394/13395) and list all instances in a Region

```
ansible-playbook playbooks/generic/gatherEc2Facts.yml -e "awsRegion=eu-west-2 awsProfile=PROFILE_CORE"

```
### Run the playbook on the Dev Jumphosts (lonrs13394/13395) using a Name tag

```
ansible-playbook playbooks/generic/gatherEc2Facts.yml -e "awsRegion=eu-west-2 awsProfile=PROFILE_CORE ec2Name=lab-vlproxy-1"

```
### Run the playbook on the Dev Jumphosts (lonrs13394/13395) using a Consul URL

```
ansible-playbook playbooks/generic/gatherEc2Facts.yml -e "awsRegion=eu-west-2 awsProfile=PROFILE_CORE consulUrl=https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/lab/terraform/core/outputs/cleo/eu-west-2/vlproxy_ingress_private_ips?raw consulTokenPassword=10101010110-17ab-2323-asasadsaa8"

```
### Run the playbook on the Dev Jumphosts (lonrs13394/13395) using a known EC2 instance ID

```
ansible-playbook playbooks/generic/gatherEc2Facts.yml -e "awsRegion=eu-west-2 awsProfile=PROFILE_CORE ec2Id=i-0a7f4aea5078d7b76"

```

## Author Information
David Roberts - david.roberts@natwestmarkets.com

## Version Information
0.1


