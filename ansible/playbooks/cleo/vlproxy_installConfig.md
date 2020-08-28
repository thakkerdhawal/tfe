# Project Title

Prep, Install and Configure VLProxy on an EC2 instance.

## Overview

This playbook exists to allow silent install and configuration of Cleo VLProxy on a RHEL7-based EC2 instance.

To workaround the noexec option on /tmp, this playbook creates a temporary install directory for VLProxy. It cleans out the files upon completion of the install. This is used for install and config.

The playbook performs the following tasks:
- obtain vlproxy serial numbers instances in Consul
- Set vlproxySerialNumbers to the value of vlProxySerials.content
- obtain vlproxy default password in Consul if this is a first time installation
- First-time install - set vlproxyDefaultPassword to the value of vlProxyDefPass.content
- Non first-time install - Set vlproxyDefaultPassword to the value of vlproxyConfigPassword
- Ensure unzip package installed  and any other required packages
- Create {{ vlproxyHome }} directory for Cleo VLProxy and set expected permissions
- Obtain VLProxy Binary from AF and copy it to target server in {{ destFilePath }}
- generic_afServerFileCopy
- Copy over template installation file and set parameters based on vars
- Create tmp location at /opt/app/ecomm/VLProxy/installTmp for the install
- First-time run - perform silent installation of vlproxy
- Copy VLProxy Template File ready for VLProxy configuration
- Check vlproxy systemctl unit file exists
- Stop VLProxy Service via raw sudo command
- Perform silent post-install configuration of vlproxy
- Clean up directories and files that are no longer required
- Enable VLProxy Service via raw sudo command
- Start VLProxy Service via raw sudo command
- Configure Cloud Watch Agent for VLProxy
- Print IP Address of VLProxy
- Wait for 90 seconds and then test VLProxy listening on port 8080 (it can take upto 5 minutes)

## Requirements

* You have a valid Consul Token
* You will run this on either a jumphost or on tooling
* Unix account
- Outputs of the VLProxy host IPs are in Consul
- Vars of the VLProxy serial numbers and default password are in Consul
- The serial numbers MUST match the serial numbers used in Harmony. So UAT vlproxy must match the serial numbersof UAT Harmony or it will not start
- VLProxy Instances provisioned and reachable via ssh
- VLProxy server requires a minimum of 4GB RAM.

__If running on Ansible core__
- you have run the awsProxyJump.yml playbook and have ssh proxy access to the instances in AWS
- ** SSH key to access the Bastion Hosts and EC2 instances located at ~/.ssh/ec2-key.pem **
- ~/.ssh directory has 0700 permissions
- Files within ~/.ssh/ directory have 0600 permissions

__If running on Tooling (Ansible Tower)__
* You will provide the initial ssh account to the DWS client as a role parameter, i.e. --role e0000047.
* Extra vars need to be created in a text file on your local file system and this file will need to be passed to the dws client as an argument on job invocation.
* All extra vars will need to be defined in a JSON schema for validation purposes.

## Variables Used
The playbook uses a number of vars, these are listed below. Any defaults can be found in the [vars_files/vlproxy file](../../vars_files/vlproxy)

The below list uses the following format: _varName_ - _description_ -  _Sample_ _value_ - _mandatory_ or _optional_

#### Mandatory ####
* __consulTokenPassword__ - Consul Token required to access vlproxy outputs - "11223d1e8-ffff-10ac-1626-bsd1f11622448" (sample) - Mandatory when using consul
* __awsEnv__ - NWM AWS Environment Name - lab - Mandatory
* __awsRegion__ - AWS Region to utilise - eu-west-2 - Mandatory
* __vlproxyConfigPassword__ - The password that vlproxy configuration should be set to as part of install and configuration - _s0methingC0mpl3x_ - Mandatory

#### Optional ####
* __vlproxyHome__ - Home directory of vlproxy (where it should be installed) - /opt/app/ecomm/VLProxy - Optional (default value of /opt/app/ecomm/VLProxy specified in vars_files file)
* __vlproxyEnv__ - Not to be confused with awsEnv var. This is the VLProxy environment, by default its set to the value of var awsEnv, but it can be overriden if required - nonprod - optional
* __sshUser__ - What account should ansible  initially connect to the target with via ssh (default value of ec2-user specified in vars_files file)- ec2-user
* __theUser__ - What account should ansible become to install, configure and own permissions for VLProxy (default value of e0000047 specified in vars_files file)- e0000047
* __vlproxyDefaultPassword__ - Manually pass in the default password or current password rather than pull it from consul - _s0methingC0mpl3x_

### Vars required for ansible roles

These vars are used by the playbook which use the generic_afServerFileCopy role to obtain the VLProxy.bin install binary
#### Mandatory ####
#### Optional ####
* __afUser__ - IF required, User to  connect to Artifactory with to retrieve file - roberdf - Optional (not required by default)
* __afToken__ - IF required, Token to supplement user when connecting to Artifactory to retrieve file - 02djsdjsasdasd - Optional (not required by default)
* __afUrl__ - Full URL of the artifact to be obtained from Artifactory -  https://artifactory-1.dts.fm.rbsgrp.net/artifactory/eComm-private-releases-local/cleo/vlproxy/VLProxy.bin - Optional (default specified in vars_files file)
* __afFile__ - the filename of the Artifact - VLProxy.bin - Optional (role uses the basename filter to auto set this based on the URL provided above)
* __destFilePath__ - location to place the downloaded artifact on the target server via ssh - /opt/app/ecomm/VLProxy/ - Optional (default specified in vars_files file)
* __theMode__ - modal permissions of the VLProxy.bin file when downloaded and copied to target host - 0755 - Optional (default specified in vars_files file)
* __theUser__ - already mentioned and configured above.


## Templated files
This playbook utilises jinja2 templating and dynamically creates files on the target hosts based on facts captured by Ansible as well as vars passed into this playbook.

The files are located within the [files](files) directory and are as follows:
- vlproxyInstall.properties.j2 - This will create the vlproxyInstall.properties file (for silent installation) in the {{ vlproxyHome }} location
- vlproxyConfigure.properties.j2 - This will create the vlproxyConfigure.properties file (for post-install config) in the {{ vlproxyHome }} location
- vlproxyd.service.j2 - This will create the systemd unit service file for vlproxyd so that it can run as a service
- vlproxy.sudoers.j2 - Currently disabled in the playbook, however this will create a file for the vlproxy service account in /etc/sudoers.d/ to allow the user to stop/start/restart the VLProxyd service.

## Getting Started on Ansible CORE (not Tower/Tooling)
This assumes you have checked out this code and are attempting to run it on lonrs13394 or lonrs13395 with your normal Unix account (not root)

1) Navigate to the Ansible Home directory (where the ansible.cfg file is located)
2) Run command (note sample values are used here): 
```
ansible-playbook playbooks/cleo/vlproxy_installConfig.yml -e "consulTokenPassword=adsasdasdsas awsEnv=lab awsRegion=eu-west-2 vlproxyConfigPassword=somethingC0mpl3x vlproxyEnv=uat" 
```
3) Upon completion of the playbook, the ip address will be returned confirming what IP to pass to the Cleo Application Support Team to add this vlproxy instance to Cleo Harmony Servers


Example:

The below code demonstrates a successful playbook run when using Consul as an IP Source

```
ansible-playbook playbooks/cleo/vlproxy_installConfig.yml -e "consulTokenPassword=adsasdasdsas awsEnv=lab awsRegion=eu-west-2 vlproxyConfigPassword=somethingC0mpl3x vlproxyEnv=uat" 

PLAY [localhost] **********************************************************************************************************************************************************************************************

TASK [../../roles/generic_addHosts : check for consul token] **************************************************************************************************************************************************
skipping: [127.0.0.1]

TASK [../../roles/generic_addHosts : fail] ********************************************************************************************************************************************************************
skipping: [127.0.0.1]

TASK [../../roles/generic_addHosts : lookup target instances in Consul] ***************************************************************************************************************************************
ok: [127.0.0.1]

TASK [../../roles/generic_addHosts : add hosts to group vlproxy] **********************************************************************************************************************************************
changed: [127.0.0.1] => (item=10.8.100.85)

TASK [../../roles/generic_addHosts : add list of hosts provided on command line to group vlproxy] *************************************************************************************************************
skipping: [127.0.0.1]

PLAY [vlproxy] ************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************************************************************************************
ok: [10.8.100.85]

TASK [Identify if vlproxy has already been installed and configured by existence of VLProxy.properties binary file] *******************************************************************************************
ok: [10.8.100.85]

TASK [debug] **************************************************************************************************************************************************************************************************
ok: [10.8.100.85] => {
    "vlProxyPropsFile": {
        "changed": false,
        "failed": false,
        "stat": {
            "atime": 1558544256.9313092,
            "attr_flags": "",
            "attributes": [],
            "block_size": 4096,
            "blocks": 8,
            "charset": "binary",
            "checksum": "93d18c6dbb5711af4dd301178d898d1c7e6bbb4f",
            "ctime": 1558544249.004149,
            "dev": 66306,
            "device_type": 0,
            "executable": true,
            "exists": true,
            "gid": 14047,
            "gr_name": "e0000047",
            "inode": 25388169,
            "isblk": false,
            "ischr": false,
            "isdir": false,
            "isfifo": false,
            "isgid": false,
            "islnk": false,
            "isreg": true,
            "issock": false,
            "isuid": false,
            "mimetype": "application/octet-stream",
            "mode": "0775",
            "mtime": 1558544249.004149,
            "nlink": 1,
            "path": "/opt/app/ecomm/VLProxy/conf/VLProxy.properties",
            "pw_name": "e0000047",
            "readable": true,
            "rgrp": true,
            "roth": true,
            "rusr": true,
            "size": 760,
            "uid": 14047,
            "version": "18446744072969960758",
            "wgrp": true,
            "woth": false,
            "writeable": true,
            "wusr": true,
            "xgrp": true,
            "xoth": true,
            "xusr": true
        }
    }
}

TASK [obtain vlproxy serial numbers instances in Consul] ******************************************************************************************************************************************************
ok: [10.8.100.85 -> localhost]

TASK [Set vlproxySerialNumbers to the value of vlProxySerials.content] ****************************************************************************************************************************************
ok: [10.8.100.85]

TASK [obtain vlproxy default password in Consul if this is a first time installation] *************************************************************************************************************************
ok: [10.8.100.85]

TASK [First-time install - set vlproxyDefaultPassword to the value of vlProxyDefPass.content] *******************************************************************************************************************
ok: [10.8.100.85]

TASK [Non first-time install - Set vlproxyDefaultPassword to the value of vlproxyConfigPassword] ******************************************************************************************************************
skipping: [10.8.100.85]

TASK [Ensure unzip package installed  and any other required packages] ****************************************************************************************************************************************
ok: [10.8.100.85] => (item=unzip)

TASK [Create /opt/app/ecomm/VLProxy directory for Cleo VLProxy and set expected permissions] ******************************************************************************************************************
changed: [10.8.100.85]

TASK [include_role : generic_afServerFileCopy] ****************************************************************************************************************************************************************

TASK [generic_afServerFileCopy : Create local 'files' directory (if it doesn't exist) at location "/home/roberdf/tf/DIGIENG-16073/ansible/playbooks/cleo/files/"] *********************************************
ok: [10.8.100.85 -> localhost]

TASK [generic_afServerFileCopy : Generate random string to make AF downloaded filename unique] ****************************************************************************************************************
changed: [10.8.100.85 -> localhost]

TASK [generic_afServerFileCopy : Print randomString if verbosity is 2 or greater] *****************************************************************************************************************************
skipping: [10.8.100.85]

TASK [generic_afServerFileCopy : Auth Required - get target file info] ****************************************************************************************************************************************
skipping: [10.8.100.85]

TASK [generic_afServerFileCopy : Auth Not Required - get target file info] ************************************************************************************************************************************
ok: [10.8.100.85 -> localhost]

TASK [generic_afServerFileCopy : Print sha1sum of AF file if verbosity is 2 or greater] ***********************************************************************************************************************
skipping: [10.8.100.85]

TASK [generic_afServerFileCopy : Auth Required - Download single file from Artifactory to local Ansible server in the "/home/roberdf/tf/DIGIENG-16073/ansible/playbooks/cleo/files/" directory, so Ansible can later copy it to the target host(s)] ***
skipping: [10.8.100.85]

TASK [generic_afServerFileCopy : Auth Not Required - Download single file from Artifactory to local Ansible server in the "/home/roberdf/tf/DIGIENG-16073/ansible/playbooks/cleo/files/" directory, so Ansible can later copy it to the target host(s)] ***
changed: [10.8.100.85 -> localhost]

TASK [generic_afServerFileCopy : Copy locally downloaded file to remote host(s)] ******************************************************************************************************************************
ok: [10.8.100.85]

TASK [generic_afServerFileCopy : Copy locally downloaded file to remote host(s) and unarchive] ****************************************************************************************************************
skipping: [10.8.100.85]

TASK [generic_afServerFileCopy : Remove locally downloaded AF file as part of playbook cleanup] ***************************************************************************************************************
changed: [10.8.100.85 -> localhost]

TASK [Copy over template installation file and set parameters based on vars] **********************************************************************************************************************************
changed: [10.8.100.85]

TASK [Create tmp location at /opt/app/ecomm/VLProxy/installTmp for the install] *******************************************************************************************************************************
changed: [10.8.100.85]

TASK [First-time run - perform silent installation of vlproxy] ************************************************************************************************************************************************
ok: [10.8.100.85] => (item=/opt/app/ecomm/VLProxy/VLProxyc.lax)
ok: [10.8.100.85] => (item=/opt/app/ecomm/VLProxy/VLProxyc)
ok: [10.8.100.85] => (item=/opt/app/ecomm/VLProxy/VLProxyd)
ok: [10.8.100.85] => (item=/opt/app/ecomm/VLProxy/jre/bin/java)

TASK [Copy VLProxy Template File ready for VLProxy configuration] *********************************************************************************************************************************************
changed: [10.8.100.85]

TASK [Check vlproxy systemctl unit file exists] ***************************************************************************************************************************************************************
ok: [10.8.100.85]

TASK [Stop VLProxy Service via raw sudo command] **************************************************************************************************************************************************************
changed: [10.8.100.85]

TASK [Perform silent post-install configuration of vlproxy] ***************************************************************************************************************************************************
changed: [10.8.100.85]

TASK [Clean up directories and files that are no longer required] *********************************************************************************************************************************************
changed: [10.8.100.85] => (item=/opt/app/ecomm/VLProxy/vlproxyInstall.properties)
changed: [10.8.100.85] => (item=/opt/app/ecomm/VLProxy/vlproxyConfigure.properties)
changed: [10.8.100.85] => (item=/opt/app/ecomm/VLProxy/installTmp)

TASK [Enable VLProxy Service via raw sudo command] ************************************************************************************************************************************************************
changed: [10.8.100.85]

TASK [Start VLProxy Service via raw sudo command] *************************************************************************************************************************************************************
changed: [10.8.100.85]

TASK [Print IP Address of VLProxy] ****************************************************************************************************************************************************************************
ok: [10.8.100.85] => {
    "msg": "The IP Address of this VLProxy Host to be added to Harmony by the Cleo App Team is 10.8.100.85"
}

TASK [Wait for 90 seconds and then test VLProxy listening on port 8080 (it can take upto 5 minutes)] **********************************************************************************************************
ok: [10.8.100.85]

PLAY RECAP ****************************************************************************************************************************************************************************************************
10.8.100.85                : ok=26   changed=12   unreachable=0    failed=0
127.0.0.1                  : ok=2    changed=1    unreachable=0    failed=0

```

## Getting Started on Tooling (Ansible Tower)

[This confluence page](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/User+Guide%3A+How+to+On-board+a+Playbook+to+Tooling) details how  a playbook is on-boarded to Tooling and the necessary requirements.

__These steps assume you have completed all onboarding steps required to run a playbook on Tooling__

All variables should be defined in a plain text file that will be passed to the DWS client on job invocation. Their value has the same affect as the extra vars in the section above. 

As a minimum, the vars file should resemble something like the below:
```
awsEnv=lab
awsRegion=eu-west-2
sshUser=e0000047
theUser=e0000047
vlproxyConfigPassword=somethingC0mplex!
vlproxyEnv=uat
consulTokenPassword="aaaaaaaa-bbbb-ccccccccccc-dddd"
```

The json schema file can be found [here](./vlproxy_installConfig.json), this will need to be downloaded to your local filesystem and passed in with the --surveyfile option

### Run the playbook on Tooling ###
To run the playbook, ensure the extravars and schemafile are in place.
.\dws.exe ansible operation --channel NWMCORE --environment dev --role e0000047 --extravarsfile cleoextravars.txt --surveyfile cleoSchema.json --credentialtype SSH --playbookpath ansible/playbooks/cleo/vlproxy_installConfig.yml --scmbranch development --scmprojectkey DEP --scmrepo nwm_infra_tf_engineering


### Further Reading

* [Confluence page for tooling with further guidelines on producing Playbooks](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/Ansible+Tower+Solution+-+NMW+Feature+Team+Info)
* [Ansible and Jinj2 Templating](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html)

## Versioning

Version 0.6

## Authors

* **David Roberts** - david.roberts@natwestmarkets.com

