dynamicInventoryDemo.md

Generic Ansible playbook to demonstrate use of Ansible dynamic inventory against AWS using the boto AWS API and ec2.py dynamic inventory script

## Overview
 
This playbook exists to highlight how dynamic inventory could be used in the future.
In this example, it gathers and prints OS facts, creates and deletes a temporary file as well as prints the uptime of the server.

The point here is to demonstate how easy it is to target 1 or multiple ec2 instances in AWS using tag keys and values.

Note: This playbook cannot run on tooling as tooling currently does not support dynamic inventory (though we could probably make it do so using this method)

## Prerequisites

You will run this on an RBS jumphost i.e. lonrs13394
 
* The boto, boto3 and botocore packages have been installed via pip (may not be a hard requirement, but is recommended)
* You have valid Active AWS credentials defined as a profile in ~/.aws/credentials 
* You have run the [awsProxyJump.yml](../awsProxyJump.yml) playbook

### Modified ec2.py and ec2.ini files - for informational purposes only (already performed)

Note: __The below steps have already been performed__, but are documented here for reference.

* You have obtained the ec2.py script [from here](https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.py) and put this within the [inventory folder](../../inventory/)
* You have obtained the ec2.ini script [from here](https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.ini) and put this within the [inventory folder](../../inventory/)
* You have made the following amendments within the ec2.ini file:
1) change regions to regions=auto
2) uncomment hostname_variable = tag_Name (this will list hosts based on their Name tag in AWS as opposed to private ip)
3) amend vpc_destination_variable to vpc_destination_variable = private_ip_address

## Environment Variables
To use dynamic inventory on the jumphosts you need to set the following environment variables.
You can achieve this using the export command i.e..

```
export AWS_REGION=eu-west-2
export AWS_PROFILE=PROFILE_CORE
export ANSIBLE_INVENTORY=~/DIGIENG-13359/ansible/inventory/ec2.py
export EC2_INI_PATH=~/DIGIENG-13359/ansible/inventory/ec2.ini
```

The below list uses the following format: varName_ - description - Sample value

#### Mandatory 
* __AWS_REGION__ - AWS Region - eu-west-2
* __AWS_PROFILE__ - AWS Creds Profile Name (to match whats in your aws credentials file). - PROFILE_CORE

#### More or less Mandatory
* __ANSIBLE_INVENTORY__ - Location of ec2.py file - ~/DIGIENG-13359/ansible/inventory/ec2.py
* __EC2_INI_PATH__ - Location of ec2.ini file - ~/DIGIENG-13359/ansible/inventory/ec2.ini

If not setting the last 2 as environment variables, the ansible.cfg file can be amended to utilise the ec2.py file as the default inventory by amending the inventory line to readme
inventory = ./inventory/ec2.py

## Extra Variables Used

The following extra vars should be passed into this playbook.

The below list uses the following format: varName_ - description - Sample value

#### Mandatory Vars
* __becomeUser__ - which user should you switch to, to run these tasks once ssh'd in as the ec2-user - e0000047 
* __ec2Targets__ - the group or inventory name to target -  tag_Component_cleo (tag key & value) or  lab_vlproxy_1 (name of instance)

#### Additional/Optional Vars

If verbosity is 2 or greater (-vv) it will also print the hostvars that are obtained through the AWS API via the ec2.py script (useful for when conditions and targeting).

## Getting Started
Before running anything:
* Ensure you have followed the pre-requisites listed above
* Know what AWS profile you need to use i.e. PROFILE_CORE
* Know the AWS region that you want to target
* Ensure you have valid (current) AWS credentials in ~/.aws/credentials
* Ensure you have set the environment variables listed above with correct values
* Ensure you have configured your environment with the [playbooks/awsProxyJump.md](playbooks/awsProxyJump.md) playbook
* Check the Dynamic inventory is working and get a list of all available hosts via cmd: 
```
ansible --list-hosts all
```
* Get a list of all available groups via cmd:
```
 ansible localhost -m debug -a 'var=groups'
```
You can target hosts or groups by passing those values in as part of the ec2Targets extra var

Note: Ansible doesn't like hyphens, any hyphens are converted into underscores.

So to target all targets that are a member of security group: core-lab-stream-sg you'd pass in the extra var value: ec2Targets=security_group_core_lab_stream_sg

## Playbook Examples

### Run the playbook on the Dev Jumphosts (lonrs13394/13395)

```
saml2aws login
export AWS_REGION=eu-west-2
export AWS_PROFILE=PROFILE_CORE
export ANSIBLE_INVENTORY=~/DIGIENG-13359/ansible/inventory/ec2.py
export EC2_INI_PATH=~/DIGIENG-13359/ansible/inventory/ec2.ini

ansible-playbook playbooks/generic/dynamicInventoryDemo.yml -e "becomeUser=ec2-user ec2Targets=tag_Component_cleo"
```

## Author Information
David Roberts - david.roberts@natwestmarkets.com

## Version Information
0.1


