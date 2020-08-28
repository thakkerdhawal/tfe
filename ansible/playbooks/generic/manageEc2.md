manageEc2.yml 

Ansible playbook to stop, start or restart EC2 instances on AWS via the boto (python) library which gives Ansible access to the AWS API.

## Overview
 
This playbook exists to allow operators to stop, start or restart a single EC2 instance on AWS.
EC2 instances should be created or destroyed via Terraform.

Note: if required, the playbook can be modified to support modifying multiple EC2 instances at once.

## Prerequisites

You will run this on either a jumphost or on tooling
 
__If running on Ansible core__
* The boto, boto3 and botocore packages have been installed via pip (may not be a hard requirement, but is recommended)
* You have valid Active AWS credentials defined as a profile in ~/.aws/credentials 

__If running on Tooling (Ansible Tower)__
* If running on Tooling (Tower), AWS creds will be provided by the DES channel that you define when running the playbook and will be accessible via environment vars
* All extra vars are defined in the Tooling JSON schema (cannot have optional vars)

## Variables Used

The following extra vars can be passed in this role.

The below list uses the following format: varName_ - description - Sample value

#### Mandatory Vars

* __awsEnv__ - NWM AWS Environment Name - lab
* __awsRegion__ - AWS Region - eu-west-2
* __ec2Name__ - The value of the Name Tag in AWS for the instance - lab-vlproxy-1
* __ec2State__ -  the allowedState [ restarted, running, stopped]
* __tooling__ -  is this being run on tooling env (true - default) or dev jumphost env (false) - false

#### Additional Vars
* __awsProfile__ - This is mandatory on the jumphosts, but not on tooling. AWS Creds Profile Name (to match whats in your aws credentials file). - PROFILE_CORE


## Getting Started
Before running anything:
* Know the tag Name of the instance that you with to modify
* Know if you are running this via tooling or via the dev jumphosts
* Know what action you want to perform on the EC2 instance
* Know the AWS region that the instance runs in

### Non-Tooling Specific Requirements
* Ensure you have configured your environment with the [playbooks/awsProxyJump.md](playbooks/awsProxyJump.md) playbook
* Ensure you have configured your AD credentials and a profile is present in your ~/.aws/credentials file


## Playbook Examples

### Run the playbook on the Dev Jumphosts (lonrs13394/13395)

```
ansible-playbook playbooks/generic/manageEc2.yml -e "awsRegion=eu-west-2 awsProfile=PROFILE_CORE tooling=False ec2State=restarted ec2Name=lab-vlproxy-1"
```

### Run the playbook on Tooling
- tbc

you will need to pass the tooling=true extra var


