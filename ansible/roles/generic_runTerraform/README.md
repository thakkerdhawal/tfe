Role Name
------------

**generic_runTerraform**

This role provides the capability to run Terraform commands via Ansible Core or Tower.

Due to using Ansible 2.6 on tooling, the native Terraform module for Ansible cannot be utilised as we are using workspaces.
Workspaces are supported as of Ansible v2.7. As a result, the Terraform binary will be called directly.

It loosely mimics what the existing TF wrapper script performs, so it will perform the following actions
* init 
* select workspace
* plan
* apply
* destroy
* refresh
* ad-hoc commands that require an aws profile and a credentials file i.e. terraform state list

Requirements
------------

There are a number of requirements to run this role.

* You have working, approved TF code
* You have a valid Consul Token
* You will run this on either a jumphost or on tooling
 
__If running on Ansible core__
* The boto, boto3 and botocore packages have been installed via pip (may not be a hard requirement, but is recommended)
* You have valid Active AWS credentials defined as a profile in ~/.aws/credentials 
* The Terraform binary will be located at /usr/local/bin/terraform
* The Ansible directory and Terraform directory are in the same repository and the Ansible code can reference the Terraform code via the value of the devTfCodeDir variable set in the [defaults/main.yml](defaults/main.yml) file.

__If running on Tooling (Ansible Tower)__
* Temporary AWS creds will be generated based on the DES channel and environment that you define when running the playbook via the DWS client. These temporary credentials will be accessible via environment vars.
* The Ansible directory and Terraform directory are in the same repository and the Ansible code can reference the Terraform code via the value of the toolingTfCodeDir variable set in the [defaults/main.yml](defaults/main.yml) file.
* Extra vars need to be created in a text file on your local file system and this file will need to be passed to the dws client as an argument on job invocation.
* All extra vars will need to be defined in a JSON schema for validation purposes.
* Whilst optional vars can now be used, in this role, "when" conditions have instead been used. These conditions perform an action or a read if a var if its value is not set to false, as per the code snippet below.
```
when: tfCmd|lower != 'false'
```

Role Variables
--------------
When using Tower, the "{{ playbook_dir }}" variable is key to being able to reference files or objects using a relative path. This is a built in special var that can be referenced as it provides the working directory of the playbook (i.e. playbooks/generic/)

### Var Defaults ###
A number of default vars have been defined in [defaults/main.yml](defaults/main.yml)
Refer to that file for information on what defaults have been set (take note of the default vars and what you do/don't need to change).


### Extra Vars ###
The following extra vars can be passed in this role.

The below list uses the following format: varName_ - description - Sample value

#### Mandatory Extra Vars ####

* __consulTokenPassword__ - A Consul Token with read permission to the target key path - n/a
* __awsEnv__ - NWM AWS Environment Name - lab
* __awsAccount__- NWM AWS Account Type (core or shared services) - core
* __awsComponent__ - NWM AWS Component (cleo, fixfw etc) - cleo
* __awsRegion__ - AWS Region - eu-west-2
* __awsProfile__ - AWS Creds Profile Name (to match whats in your aws credentials file). If running on Tooling, this defaults to TOOLING (aws creds handled by an auto-generated template file)
* __tooling__ is this being run on tooling env (true - default) or dev jumphost env (false) - false
* __tfAction__ - Variable that defines whether you perform a TF Apply (apply) or Destroy (destroy). If not, set this to _false_ (default) - apply 
* __tfCmd__ - tf ad-hoc command to run (default set to false - 'state list'
* __tfPlan__- Do you want to perform a TF Plan (true or false - default is true) - true
* __mailTo__ - Email address to send tf plan output files to - david.roberts@natwestmarkets.com
* __maiMe__ - Do you want this to email the TF Plan (default = false). Only enable this if enabling a TF Plan - true


#### Additional Vars that can be modified (defaults are set) ####

* __afFile__ - Full Web URL to the Terraform providers on Artefactory
* __awsCredFile__ - Tooling credential file location (defaults to {{ playbook_dir }}/awsCredentials for Tooling, uses ~/.aws/credentials on jumphosts ) - "{{ playbook_dir }}/awsCredentials"
* __debugMe__ - Enable printing of certain information, i.e. env vars - true
* __devTfCodeDir__ - relative path to working TF Code Directory on jumphost environment - "{{ playbook_dir }}/../../../terraform/{{ awsAccount | lower }}/{{ awsComponent | lower}}"
* __devTfPluginsDir__ - path to where TF plugins can be found on the jumphost (ansible core) environment - /usr/local/bin/.terraform/plugins/linux_amd64
* __tfCodeDir__ - do not change directly, this inherits the value of toolingTfCodeDir or devTfCodeDir based on logic in the role.
* __tfBinary__ - full path to the TF binary - /usr/local/bin/terraform
* __toolingTfCodeDir__ - relative path to working TF Code Directory on tooling environment (TBC) - "{{ playbook_dir }}/../../terraform/{{ awsAccount | lower }}/{{ awsComponent | lower}}"
* __wsName__ - name of the Terraform workspace, this is taken from "{{ awsEnv|lower }}_{{ awsAccount|lower }}_{{ awsComponent|lower }}_{{ awsRegion|lower }}" - lab_core_cleo_eu-west-2


## Templated files - Tooling Only
This playbook utilises jinja2 templating and dynamically creates files on the target hosts based on env vars and vars captured by ansible as well as extra vars passed into this playbook

The files are located within the [templates](templates) directory
- awsCreds.j2 - When running on the tooling environment, this will create the {{ playbook_dir }}/awsCredentials file to provide AWS access to Terraform. It will take the temporary AWS credentials from environment variables and populate them in this temporary file. The statements used to achieve this are:

* aws_access_key: "{{ lookup('env','AWS_ACCESS_KEY_ID') }}"
* aws_secret_key: "{{ lookup('env','AWS_SECRET_ACCESS_KEY') }}"
* aws_session_token: "{{ lookup('env','AWS_SECURITY_TOKEN') }}"

This allows Terraform to authenticate against AWS using a profile name and a credentials file, in the same manner that we currently run Terraform without Ansible. The default profile name is set to TOOLING and this is included in the template file.

To avoid any authentication conflicts, on the Terraform-specific tasks, it will also "unset" the values of the variables:
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY
* AWS_SECURITY_TOKEN

During testing, it was found that if you do not unset the variables in the TF tasks, authentication will fail.

## Getting Started on Ansible CORE (not Tower/Tooling)
------------

Before running anything, work out what it is you want to do. Do you want the playbook to perform a simple TF Init, a TF Plan, a TF Apply/Destory or a TF-Adhoc command or a combination of these.

This section will give a simple example of how to do any of these.

The role will read in the values of awsEnv, awsAccount, awsComponent and awsRegion and use this to calculate the correct TF workspace. 
The var wsName defined in [defaults/main.yml](defaults/main.yml) demonstrates this.


### Performing a simple TF Init ###

The playbook will ALWAYS perform a TF Init as this is required to perform any of the subsequent commands. Having it perform an init is useful to verify that you can access Consul, list and automatically select the correct workspace.

To perform a simple TF Init from the jumphosts, run the following command:
```
ansible-playbook playbooks/generic/runTerraform.yml -e "consulTokenPassword=<consulToken> awsComponent=<value> awsAccount=<value> awsEnv=<value> awsRegion=<value> tfPlan=false tooling=false awsProfile=<value>"
```

### Performing a TF Plan ###
To perform a TF Plan from the jumphosts, as well as email yourself a copy of the tf plan files run the following command:

```
ansible-playbook playbooks/generic/runTerraform.yml -e "consulTokenPassword=<consulToken> awsComponent=<value> awsAccount=<value> awsEnv=<value> awsRegion=<value> awsProfile=<value> tfPlan=true mailMe=true mailTo=<email address> tooling=false"
```

### Performing a TF Apply ###

To perform a TF Apply (and skip running TF Plan) from the jumphosts run the following command:

```
ansible-playbook playbooks/generic/runTerraform.yml -e "consulTokenPassword=<consulToken> awsComponent=<value> awsAccount=<value> awsEnv=<value> awsRegion=<value> awsProfile=<value> tfPlan=false tfAction=apply tooling=false"
```

### Performing a TF Destroy ###

To perform a TF Destroy (and skip running TF Plan) from the jumphosts run the following command:

```
ansible-playbook playbooks/generic/runTerraform.yml -e "consulTokenPassword=<consulToken> awsComponent=<value> awsAccount=<value> awsEnv=<value> awsRegion=<value> awsProfile=<value> tfPlan=false tfAction=destroy tooling=false"
```


### Performing a TF Ad Hoc Command ###
The TF Ad Hoc command only works with options where the aws_profile and credential_file to be passed as arguments i.e. terraform state list -aws_profile="<value>" -credential_file="<value>. This logic is handled by the playbook, this note is more ensuring that your argument requires credentials to work (much like the current wrapper script).

To perform a TF AdHoc command from the jumphosts, run the following command:
(This example shows performing a 'state list' command)

```
ansible-playbook playbooks/generic/runTerraform.yml -e "consulTokenPassword=<consulToken> awsComponent=<value> awsAccount=<value> awsEnv=<value> awsRegion=<value> awsProfile=<value> tfPlan=false tfCmd='state list' tooling=false"
```

### Performing a TF Plan, Apply and AdHoc Command ###
This example shows how you could run a TF plan, mail yourself the output as well as perform a TF apply and then a TF AdHoc command

```
ansible-playbook playbooks/generic/runTerraform.yml -e "consulTokenPassword=<consulToken> awsComponent=<value> awsAccount=<value> awsEnv=<value> awsRegion=<value> awsProfile=<value> tfPlan=true mailMe=true mailTo=david.roberts@natwestmarkets.com tfAction=apply tfCmd='state list' tooling=false"
```


## Getting Started on Tooling (Ansible Tower)
------------

[This confluence page](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/User+Guide%3A+How+to+On-board+a+Playbook+or+Playbook+Repository+to+Tooling) details how  a playbook is on-boarded to Tooling and the necessary requirements.

__These steps assume you have completed all onboarding steps required to run a playbook on Tooling__

Before running anything, work out what it is you want to do. Do you want the playbook to perform a simple TF Init, a TF Plan, a TF Apply/Destory or a TF-Adhoc command or a combination of these.

This section will give a simple example of how to do any of these.

The role will read in the values of awsEnv, awsAccount, awsComponent and awsRegion and use this to calculate the correct TF workspace. 
The var wsName defined in [defaults/main.yml](defaults/main.yml) demonstrates this.

All variables should be defined in a plain text file that will be passed to the DWS client on job invocation.
The values of some variables in the file determine what actions will be taken when the playbook is run, i.e. a terraform apply.

As a minimum, the vars file should resemble something like the below:
```
awsComponent=cleo
awsAccount=core
awsEnv=lab
awsRegion=eu-west-2
tfPlan=false
mailMe=false
mailTo=david.roberts@natwestmarkets.com
tfAction=false
tfCmd=false
tooling=true
debugMe=false
consulTokenPassword="some-Value"
```
The json schema file required to run this via Tooling can be found [here](../../playbooks/generic/runTerraform.json)

### Performing a simple TF Init ###

The playbook will ALWAYS perform a TF Init as this is required to perform any of the subsequent commands. Having it perform an init is useful to verify that you can access Consul, list and automatically select the correct workspace.

To perform a simple TF Init from the jumphosts, ensure the vars are populated correctly in the tfextravars.txt file. tfPlan, mailMe, tfAction, tfCmd should all be set to false. tooling should always be set to true.

```
awsComponent=cleo
awsAccount=core
awsEnv=lab
awsRegion=eu-west-2
tfPlan=false
mailMe=false
mailTo=david.roberts@natwestmarkets.com
tfAction=false
tfCmd=false
tooling=true
debugMe=false
consulTokenPassword="some-Value"
```


Run the following dws client command:
```
.\dws.exe ansible operation action --channel NWMCORE --environment dev --role operator --extravarsfile tfextravars.txt --surveyfile runTerraform.json --credentialtype AWS --playbookpath ansible/playbooks/generic/runTerraform.yml --scmbranch development --scmprojectkey DEP --scmrepo nwm_infra_tf_engineering
```

### Performing a TF Plan ###
To perform a TF Plan from tooling, as well as email yourself a copy of the tf plan files ensure your tfextravars.txt file resembles something like:

```
awsComponent=cleo
awsAccount=core
awsEnv=lab
awsRegion=eu-west-2
tfPlan=true
mailMe=true
mailTo=david.roberts@natwestmarkets.com
tfAction=false
tfCmd=false
tooling=true
debugMe=false
consulTokenPassword="some-Value"
```

Run the following dws client command:
```
.\dws.exe ansible operation action --channel NWMCORE --environment dev --role operator --extravarsfile tfextravars.txt --surveyfile runTerraform.json --credentialtype AWS --playbookpath ansible/playbooks/generic/runTerraform.yml --scmbranch development --scmprojectkey DEP --scmrepo nwm_infra_tf_engineering
```

### Performing a TF Apply ###

To perform a TF Apply (and skip running TF Plan) from tooling, ensure your tfextravars.txt file resembles something like:
```
awsComponent=cleo
awsAccount=core
awsEnv=lab
awsRegion=eu-west-2
tfPlan=false
mailMe=false
mailTo=david.roberts@natwestmarkets.com
tfAction=apply
tfCmd=false
tooling=true
debugMe=false
consulTokenPassword="some-Value"
```

Run the following dws client command:
```
.\dws.exe ansible operation action --channel NWMCORE --environment dev --role operator --extravarsfile tfextravars.txt --surveyfile runTerraform.json --credentialtype AWS --playbookpath ansible/playbooks/generic/runTerraform.yml --scmbranch development --scmprojectkey DEP --scmrepo nwm_infra_tf_engineering
```

### Performing a TF Destroy ###

To perform a TF Destroy (and skip running TF Plan) from tooling, ensure your tfextravars.txt file resembles something like:
```
awsComponent=cleo
awsAccount=core
awsEnv=lab
awsRegion=eu-west-2
tfPlan=false
mailMe=false
mailTo=david.roberts@natwestmarkets.com
tfAction=destroy
tfCmd=false
tooling=true
debugMe=false
consulTokenPassword="some-Value"
```

Run the following dws client command:
```
.\dws.exe ansible operation action --channel NWMCORE --environment dev --role operator --extravarsfile tfextravars.txt --surveyfile runTerraform.json --credentialtype AWS --playbookpath ansible/playbooks/generic/runTerraform.yml --scmbranch development --scmprojectkey DEP --scmrepo nwm_infra_tf_engineering
```

### Performing a TF Ad Hoc Command ###
The TF Ad Hoc command only works with options where the aws_profile and credential_file to be passed as arguments i.e. terraform state list -aws_profile="<value>" -credential_file="<value>". This logic is handled by the playbook.

To perform a TF AdHoc command from tooling, ensure your tfextravars.txt file resembles something like:
(This example shows performing a 'state list' command)

```
awsComponent=cleo
awsAccount=core
awsEnv=lab
awsRegion=eu-west-2
tfPlan=false
mailMe=false
mailTo=david.roberts@natwestmarkets.com
tfAction=false
tfCmd=state list
tooling=true
debugMe=false
consulTokenPassword="some-value"
```

Run the following dws client command:
```
.\dws.exe ansible operation action --channel NWMCORE --environment dev --role operator --extravarsfile tfextravars.txt --surveyfile runTerraform.json --credentialtype AWS --playbookpath ansible/playbooks/generic/runTerraform.yml --scmbranch development --scmprojectkey DEP --scmrepo nwm_infra_tf_engineering
```

### Performing a TF Plan, Apply and AdHoc Command ###
This example shows how you could run a TF plan, mail yourself the output as well as perform a TF apply and then a TF AdHoc command

Ensure your tfextravars.txt file resembles something like:
```
awsComponent=cleo
awsAccount=core
awsEnv=lab
awsRegion=eu-west-2
tfPlan=true
mailMe=true
mailTo=david.roberts@natwestmarkets.com
tfAction=apply
tfCmd=state list
tooling=true
debugMe=false
consulTokenPassword="some-value"
```

Run the following dws client command:
```
.\dws.exe ansible operation action --channel NWMCORE --environment dev --role operator --extravarsfile tfextravars.txt --surveyfile runTerraform.json --credentialtype AWS --playbookpath ansible/playbooks/generic/runTerraform.yml --scmbranch development --scmprojectkey DEP --scmrepo nwm_infra_tf_engineering
```

### How to view playbook output ###
Upon job invocation on the DWS client, a cluster id and job id will be displayed. Capture these and then use the below command to view the playbook output (full tower output).
```
.\dws.exe ansible get operationstatus --channel NWMCORE --id <jobid> --clusterid <clusterid> --stdout

.\dws.exe ansible get operationstatus --channel NWMCORE --id 743 --clusterid 2 --stdout
```

Example Playbook
----------------

To include this role in a playbook, use the following syntax:
```
    - hosts: localhost
      connection: local
      gather_facts: true
      environment:
       CONSUL_HTTP_TOKEN: "{{ consulTokenPassword }}"
       no_proxy: artifactory-1.dts.fm.rbsgrp.net,ecomm.fm.rbsgrp.net
      roles:
       - ../../roles/generic_runTerraform #relative path to role from playbook directory
```

Author Information
------------------
Initially Created by David Roberts - david.roberts@natwestmarkets.com


Version
------------------
0.2

