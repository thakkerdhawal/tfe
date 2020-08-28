# Project Title

Ansible Directory for NWM SNP Refresh

## Prerequisites

- Unix account (if ssh based)
- AWS access (if  AWS based)

__If running on Ansible core__
- Access to lonrs13394/lonrs13395
- SSH key to access EC2 instances located at ~/.ssh/ec2-key.pem
- ~/.ssh directory has 0700 permissions
- Files within ~/.ssh/ directory have 0600 permissions

__If running on Tooling (Ansible Tower)__
- Playbook and dependencies reside on an accessible repository in stash
- Json Schema defined
- Extra Vars file defined
- Target accounts known
- Secret Service/Vault configuration in place
- Target servers accessible from Tooling Tower Servers

## Documentation Standards
- Use documentation and module guides for version 2.6 of Ansible.
- Create a README file for each playbook produced  - it should match the name of the playbook.
- In the README file have a Prerequisites section (i.e. terraform dependencies, what AWS permissions does this playbook require i.e. EC2 read-only?, does it need elevated permissions via ssh?).
- In the README file highlight all extra vars that are optional or required to run the playbook. Either give example values here or populate some defaults in your role within the <role>/defaults/main.yml file. An example of the latter can be found in [roles/awsProxyJump/defaults/main.yml](roles/awsProxyJump/defaults/main.yml)
- In the README file have an example section which shows how to run the playbook along with a valid example (leave out sensitive information). You can see an example of this in the getting started sectionof readme [awsProxyJump.md](playbooks/awsProxyJump.md)

## Variable Standards
Moving forwards, there are a number of variables that will likely be commonly used across playbooks and roles. Use the standards defined here. As a team we all need to update and amend this README.
Where possible use camelcase  for var names i.e. thisIsCamelCase 

This section uses the format... varName - Description - example

* __consulTokenPassword__ - use this when needing to use a Consul Token - <base64 string>
* __awsAccount__ - NWM AWS Account Type (core or shared services) - core
* __awsComponent__ - NWM AWS Component (cleo, fixfw etc) - cleo
* __awsRegion__ - AWS Region to use - eu-west-2
* __awsEnv__ - AWS Environment to use - lab
* __theUser__  The user account that will perform the ssh work on a server i.e. e0000047

Generic list to be grown and improved upon.

__Any vars that contain sensitive information must for now include the word Password at the end as tooling will then automatically encrypt the string and hide the values from the playbook log__

## Handling sensitive information
Refer to [Confluence page here](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/Ansible+Tower+Solution+-+NMW+Feature+Team+Info#AnsibleTowerSolution-NMWFeatureTeamInfo-HashicorpVault) for further background reading

In summary, sensitive credentials that need to be used i.e. for application installs should be stored in Cyberark and passed in as extra vars. The variable name must include Password i.e. consulTokenPassword as this will mask the information in the Tower output.

SSL certificates and other sensitive files cannot be stored on stash or AF. As a result, the string values of these should be passed in as extra vars.


## Getting Started on Ansible CORE (not Tower/Tooling)

1) Checkout this directory via git (if not already done so).
2) Navigate to the directory where you find this README file.
3) Run the [awsProxyJump.yml playbook](playbooks/awsProxyJump.md) to configure ansible.cfg, proxy access via the AWS Bastions for the LAB environment.
4) Either use consul to get the IP of a particular EC2 instance or edit the inventory/hosts file and statically add in your host (see Inventory section below for examples)
5) Run all ansible or ansible-playbook commands from this location so that the local ansible.cfg file with proxy configuration is referenced.

All examples below assume you have completed step 3 above and ansible.cfg, proxy access etc is configured.

- Example of running an Ansible ad-hoc command:
```
pwd
/home/roberdf/tf/nwm_infra_tf_engineering/ansible

roberdf@lonrs13394$ ls -1
ansible.cfg
inventory
playbooks
README.md
roles

roberdf@lonrs13394$ ansible -m ping localhost -u roberdf
SSH password:
127.0.0.1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

- Example of running an ansible-playbook command

```
pwd
/home/roberdf/tf/nwm_infra_tf_engineering/ansible

roberdf@lonrs13394$ ls -1
ansible.cfg
inventory
playbooks
README.md
roles

roberdf@lonrs13394$ ansible-playbook playbooks/generic/gatherOSFacts.yml
ansible-playbook playbooks/generic/gatherOSFacts.yml
SSH password:

PLAY [all] ****************************************************************************************************************************************************************************************************

TASK [Run setup module to gather OS facts] ********************************************************************************************************************************************************************
ok: [127.0.0.1]

TASK [Print out everything that was registered as the itsFacts variable in the previous task using debug] *****************************************************************************************************
ok: [127.0.0.1] => {
    "itsFacts": {
        "ansible_facts": {
}
PLAY RECAP ****************************************************************************************************************************************************************************************************
127.0.0.1                  : ok=2    changed=0    unreachable=0    failed=0
```

## Getting Started on Tooling (Ansible Tower)

[This confluence page](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/User+Guide%3A+How+to+On-board+a+Playbook+to+Tooling) details how  a playbook is on-boarded to Tooling and the necessary requirements.

__These steps assume you have completed all onboarding steps required to run a playbook on Tooling__

All variables should be defined in a local plain text file that will be passed to the DWS client on job invocation. Their value has the same affect as the extra vars in the section above. 

A json schema file will need to be created and downloaded locally to pass to the DWS client on job invocation.

### Running playbook on Tooling ###
Playbooks will be called via the dws client.
Refer to the following links for further information.

- https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/Ansible+Tower+Solution+-+NMW+Feature+Team+Info
- https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/How+to+use+the+DWS+CLI#HowtousetheDWSCLI-Ansible


## Component v Generic Terms
Component = Application component specific, i.e. fixfw or agilemarkets
Generic = Something that could apply across the board, i.e. restarting an EC2 instance

* Don't reinvent the wheel if someone has produced a playbook or role that you can re-use *


## Playbooks
For now, following the current Terraform structure - Place all playbooks within the [playbooks](playbooks) folder. 

- Component specific playbooks should reside within playbooks/componentName/ i.e. playbooks/agilemarkets directory
- Generic playbooks (excluding awsProxyJump.yml/md files) should reside within [playbooks/generic](playbooks/generic) directory
- Playbooks can include multiple roles if desired
- Make the name of the playbook obvious
- Try to make the name of the playbook unique, i.e. fixfw_restartAppServices.yml

## Roles
For now - Place all roles within the [roles](roles) folder. 

- All component specific roles (i.e. roles for fixfw) should be placed in this top-level [roles](roles) folder
- Follow the naming convention specified below for component or generic roles

** Naming Convention for Component Roles **
* componentName_roleName *

Example:

```
fixfw_restartAppServices
```

** Naming Convention for Generic Roles **
* generic_roleName *

Example:

```
generic_restartEc2Instance
```

#### Role Creation
To create a role, use the ansible-galaxy command. This will ensure you get the standard ansible role structure for templates, defaults, vars and testing capabilities.

So using the naming standards above, here is how you would create a new role for vlproxy that cleans up vlproxy files.

```
ansible-galaxy init vlproxy_cleanFiles
```

#### Where to Store Files Role Vs Playbook ####
You can store files within the roles folder within the <roleName>/files/ folder or store them with the playbook in say the playbookDir/files/ folder.

* If a role has a specific purpose and will only be used for that purpose, keep the files in the role.
* If the role would apply to everything, i.e. its a common file - imagine a standard sshd_config for all RHEL7 servers, bung this in the role.
* If the role is very generic and has multiple re-uses, keep the files within the <playbook location>/files dir (expecting the playbook to be more targeted than the role). An example would be a generic file copy role, if it was a simple text file that would be copied to only a few select servers, you'd keep it in the playbook dir as opposed to putting it in the role dir but utilise a generic file copy role (I know we use AF to store files, but hopefully the example helps)


## Inventory

#### Static Inventory
To use static inventory, either edit the inventory/hosts file or create new inventory files within the inventory directory.
You are welcome to create new groups in the inventory as well, as an example:

```
[groupName]
host1
host2
```

Note: inventory changes will not be committed back to SCM (.gitignore in place)

#### Dynamic Inventory
This is not available in Tooling, so is not enabled here (consider using Consul below)

#### Temporary Inventory
You can generate a temporary inventory for the life of a playbook using Consul outputs or variable values as a variable  source and then using the ansible "add_host" feature.

Tooling will require you to specify the connection: local option in your playbook (see below)

Simple Example:
```
- hosts: local
  connection: local
  gather_facts: no
  tasks:
  - name: Lookup EC2 instance in Consul
    uri: 
     url: "https://ecomm.fm.rbsgrp.net/v1/kv/application/nwm/{{ env }}/terraform/core/outputs/<component>/eu-west-2/<component_private_ip>?raw"
      headers:
       X-Consul-Token: "{{ consulToken }}"
     return_content: true
    register: ec2Ip

  - add_host:
     name: "{{ ec2Ip.content }}"
     groups: myGroup

- hosts: myGroup
  gather_facts: true
  remote_user: ec2-user
  tasks:
  - name: Execute a command on the remote system (use debug to see results)
    command: uptime
```

Run the above playbook with command:

```
ansible-playbook playbooks/<playbookName.yml> -e "consulToken=theTokenString"
```

## Group Vars
We are no longer utilising group_vars in NWM. This is due to our directory structure and tooling expecting group_vars to be in the root directory of the repository.

Instead refer to the next section - Vars Files

In future, if there is a need to do this, then tooling should provide the ability to specify an inventory location or this repository will need to be restructured.

## Vars Files
Vars files are just that. Files that exist for a particular application that should be referenced.

Typically there are 2 methods to include vars files in a playbook (and subsequently apply to any roles that are run as part of the playbook).

* __Method 1__ - (preferred) use vars_files [see here](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#defining-variables-in-files)
* __Method 2__ - include_vars, basically as a task stating to import vars from a vars file [see here](https://docs.ansible.com/ansible/latest/modules/include_vars_module.html). A catch of this method is that you cannot defined vars in your playbook headers and use this method to import those values. A pro of this method is that you can conditionally import vars.

To utilise vars files, create a file within the "ansible home" vars_files directory and this file should match the name of your component or group that you define:
- using the add_host module in your playbook.

In terms of naming standards,  your vars file name should either match the name of your component i.e. blackduck, or if there are multiple groups for that component use the following convention:

component_groupName

Method 1 Example:
```
- hosts: vlproxy
  remote_user: "{{ sshUser }}"
  become_user: "{{ theUser }}"
  become: true
  gather_facts: true
  vars_files:
   - ../../vars_files/vlproxy  #relatively reference the path to the file so it will work on Tooling
  tasks:
```

Method 2 Example:
```
- hosts: vlproxy
  remote_user: ec2-user
  become_user: ec2-user
  become: true
  gather_facts: true
  tasks:
  - name: Import vars in vars_file
    include_vars: ../../vars_files/vlproxy
```

## Documentation Standards
- Use documentation and module guides for version 2.6 of Ansible.
- Create a README file for each playbook produced  - it should match the name of the playbook.
- In the README file have a Prerequisites section (i.e. terraform dependencies, what AWS permissions does this playbook require i.e. EC2 read-only?, does it need elevated permissions via ssh?).
- In the README file highlight all extra vars that are optional or required to run the playbook. Either give example values here or populate some defaults in your role within the <role>/defaults/main.yml file
- In the README file have an example section which shows how to run the playbook along with a valid example (leave out sensitive information).

### Further Reading

[Confluence page for tooling with further guidelines on producing Playbooks](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/Ansible+Tower+Solution+-+NMW+Feature+Team+Info)

[Ansible Module Index for v2.6](https://docs.ansible.com/ansible/2.6/modules/modules_by_category.html)

[Ansible Getting started guide](https://docs.ansible.com/ansible/2.6/user_guide/intro_getting_started.html)

[Ansible working with Playbooks](https://docs.ansible.com/ansible/2.6/user_guide/playbooks.html)


## Versioning

Version 0.3

## To Do
