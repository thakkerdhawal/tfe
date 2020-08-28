Playbook Name
------------

**manageR53AliasWeight**

This playbook provides the ability to adjust the weight of Alias 'A' records so that a region for a particular application service can be disabled.
It should only be used against Alias A records that have weighted values and use health checks.

The playbook allows setting the weight of a weighted record to 0 or setting a zeroed value to the weight value used in the working region.
I.e. if eu-west-1 was set to 0 and eu-west-2 was set to 50, when resetting (re-enabling) the weight of the eu-west-1 record, it would be given a weight of 50.

You cannot pass in custom weight values (this is intentional).

The playbook will need further adjustment to work on tooling.

Requirements
------------
* You have a valid Consul Token
* You will run this on either a jumphost or on tooling

__If running on Ansible core__
* The boto, boto3 and botocore packages have been installed via pip (may not be a hard requirement, but is recommended)
* You have valid Active AWS credentials defined as a profile in ~/.aws/credentials 

__If running on Tooling (Ansible Tower)__
* If running on Tooling (Tower), temporary AWS creds will be generated based on the DES channel and environment that you define when running the playbook via the DWS client. These temporary credentials will be accessible via environment vars.
* The ansible route53 module is fully aware of the environment credentials and will authenticate with these, even though you pass an awsProfile (this is handy as we can use the same code for tooling and non-tooling approaches)
* Extra vars need to be created in a text file on your local file system and this file will need to be passed to the dws client as an argument on job invocation.
* All extra vars will need to be are defined in the Tooling JSON schema for validation purposes.
* Optional vars cannot be used, instead a when condition should be set to perform an action or a read if a var if its value is not set to false, as per the code snippet below.


Variables Used
--------------

The below list uses the following format: varName_ - description - Sample value

#### Mandatory Vars ####

* __awsEnv__ - NWM AWS Environment Name - lab
* __awsProfile__ - AWS Creds Profile Name (to match whats in your aws credentials file). 
* __r53Zone__ - The fully qualified  zone name where the DNS record exists - lab.cloud.natwestmarkets.com
* __r53Record__ - The shorform version of the DNS record, so which record you want to modify - filetransfer
* __disableEuWest1__ - Disable the record in eu-west-1 - true
* __disableEuWest2__ - Disable the record in eu-west-2 - false
* __enableEuWest1__ - Enable the record in eu-west-1 - false
* __enableEuWest2__ - Enable the record in eu-west-2 - false


#### Additional Mandatory Vars that can be modified (default should be false) ####

* __debugMe__ - Enable printing of certain debug information - false


## Getting Started on Ansible CORE (not Tower/Tooling)
------------

Before running anything, work out what it is you want to do. 

There are basically 5 Options

* __Option1__ (Default) - Print the current status of the Route 53 Record you have passed in and do not change anything.
* __Option2__ (disableEuWest1) - Set the record that exists for eu-west-1 to have a value of 0
* __Option3__ (disableEuWest2) - Set the record that exists for eu-west-2 to have a value of 0
* __Option4__ (enableEuWest1) - Set the record that exists for eu-west-1 to have the same value of the equivalent weighted record in eu-west-2
* __Option5__ (enableEuWest2) - Set the record that exists for eu-west-2 to have the same value of the equivalent weighted record in eu-west-1

This section will give a simple example of how to do any of these.


### Reading the current configuration ###

From the jumphosts, to get the current status of the records in R53 being targeted, execute the following cmd:

```
ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=<profile> awsEnv=<env> r53Record=<record> r53Zone=<full domain of zone>"
```

Below shows an example command and output.
```
ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=PROFILE_CORE awsEnv=lab r53Record=filetransfer r53Zone=lab.cloud.natwestmarkets.com"

PLAY [localhost] ******************************************************************************************************************************************************************************************************

TASK [Fail when any of awsRegion, awsEnv, r53Record or r53Zone are not defined] ***************************************************************************************************************************************
skipping: [127.0.0.1]

TASK [Get R53 info] ***************************************************************************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'identifier': u'lab-eu-west-1'})
ok: [127.0.0.1] => (item={u'identifier': u'lab-eu-west-2'})

TASK [Print Current R53 info on R53 Record filetransfer.lab.cloud.natwestmarkets.com] *********************************************************************************************************************************
ok: [127.0.0.1] => (item=[u'filetransfer.lab.cloud.natwestmarkets.com.', u'lab-eu-west-1', u'50']) => {
    "msg": [
        "Record is: filetransfer.lab.cloud.natwestmarkets.com.",
        "Weighted Record Unique Identifier is: lab-eu-west-1",
        "The target for this Record is: lab-vlproxy-ingress-nlb-c9ef97aa236f9966.elb.eu-west-1.amazonaws.com.",
        "Current Routing Weight is: 50"
    ]
}
ok: [127.0.0.1] => (item=[u'filetransfer.lab.cloud.natwestmarkets.com.', u'lab-eu-west-2', u'50']) => {
    "msg": [
        "Record is: filetransfer.lab.cloud.natwestmarkets.com.",
        "Weighted Record Unique Identifier is: lab-eu-west-2",
        "The target for this Record is: lab-vlproxy-ingress-nlb-d68c66651e0eab24.elb.eu-west-2.amazonaws.com.",
        "Current Routing Weight is: 50"
    ]
}

TASK [debug] **********************************************************************************************************************************************************************************************************
skipping: [127.0.0.1]

TASK [get HealthCheck info] *******************************************************************************************************************************************************************************************
ok: [127.0.0.1]

TASK [debug] **********************************************************************************************************************************************************************************************************
skipping: [127.0.0.1]

TASK [Create temporary file] ******************************************************************************************************************************************************************************************
ok: [127.0.0.1]

TASK [Copy healthcheck info into temporary file for filtering] ********************************************************************************************************************************************************
ok: [127.0.0.1 -> localhost]

TASK [Use shell command to obtain the Healthcheck ID of eu-west-1 identifier filetransfer.lab.cloud.natwestmarkets.com] ***********************************************************************************************
ok: [127.0.0.1]

TASK [Use shell command to obtain the Healthcheck ID of eu-west-2 identifier filetransfer.lab.cloud.natwestmarkets.com] ***********************************************************************************************
ok: [127.0.0.1]

TASK [debug] **********************************************************************************************************************************************************************************************************
ok: [127.0.0.1] => {
    "msg": [
        "EU-West-1 Healhcheck ID for Record filetransfer.lab.cloud.natwestmarkets.com is d8e4a11e-d4aa-4e9b-8196-e6442df95cd7",
        "EU-West-2 Healhcheck ID for Record filetransfer.lab.cloud.natwestmarkets.com is 1cb852cf-509a-4bdd-825d-e3b5a32d5e5f"
    ]
}

TASK [change weight to 0 for R53 Record filetransfer.lab.cloud.natwestmarkets.com in lab-eu-west-1] *******************************************************************************************************************
skipping: [127.0.0.1]

TASK [change weight to 0 for R53 Record filetransfer.lab.cloud.natwestmarkets.com in lab-eu-west-2] *******************************************************************************************************************
skipping: [127.0.0.1]

TASK [Reset weight for record filetransfer.lab.cloud.natwestmarkets.com in lab-eu-west-1 to value of weighted record in eu-west-2] ************************************************************************************
skipping: [127.0.0.1]

TASK [Reset weight for record filetransfer.lab.cloud.natwestmarkets.com in lab-eu-west-2 to value of weighted record in eu-west-1] ************************************************************************************
skipping: [127.0.0.1]

TASK [Get R53 info] ***************************************************************************************************************************************************************************************************
ok: [127.0.0.1] => (item={u'identifier': u'lab-eu-west-1'})
ok: [127.0.0.1] => (item={u'identifier': u'lab-eu-west-2'})

TASK [Print Current R53 info on R53 Record filetransfer.lab.cloud.natwestmarkets.com] *********************************************************************************************************************************
ok: [127.0.0.1] => (item=[u'filetransfer.lab.cloud.natwestmarkets.com.', u'lab-eu-west-1', u'50']) => {
    "msg": [
        "Record is: filetransfer.lab.cloud.natwestmarkets.com.",
        "Weighted Record Unique Identifier is: lab-eu-west-1",
        "The target for this Record is: lab-vlproxy-ingress-nlb-c9ef97aa236f9966.elb.eu-west-1.amazonaws.com.",
        "Current Routing Weight is: 50"
    ]
}
ok: [127.0.0.1] => (item=[u'filetransfer.lab.cloud.natwestmarkets.com.', u'lab-eu-west-2', u'50']) => {
    "msg": [
        "Record is: filetransfer.lab.cloud.natwestmarkets.com.",
        "Weighted Record Unique Identifier is: lab-eu-west-2",
        "The target for this Record is: lab-vlproxy-ingress-nlb-d68c66651e0eab24.elb.eu-west-2.amazonaws.com.",
        "Current Routing Weight is: 50"
    ]
}

PLAY RECAP ************************************************************************************************************************************************************************************************************
127.0.0.1                  : ok=10   changed=0    unreachable=0    failed=0

```

### Set Record Weight to 0 (Disable) in Eu-West-1 Region ###

From the jumphosts, execute the following cmd:

```
ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=<profile> awsEnv=<env> r53Record=<record> r53Zone=<full domain of zone> disableEuWest1=True"
```


### Set Record Weight to 0 (Disable) in Eu-West-2 Region ###

From the jumphosts, execute the following cmd:

```
ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=<profile> awsEnv=<env> r53Record=<record> r53Zone=<full domain of zone> disableEuWest2=True"
```

### Set Record Weight to Original Value (Enable) in Eu-West-1 Region ###

From the jumphosts, execute the following cmd:

```
ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=<profile> awsEnv=<env> r53Record=<record> r53Zone=<full domain of zone> enableEuWest1=True"
```

### Set Record Weight to Original Value (Enable) in Eu-West-2 Region ###

From the jumphosts, execute the following cmd:

```
ansible-playbook playbooks/generic/manageR53AliasWeight.yml -e "awsProfile=<profile> awsEnv=<env> r53Record=<record> r53Zone=<full domain of zone> enableEuWest2=True"
```


## Getting Started on Tooling (Ansible Tower)
------------

[This confluence page](https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/User+Guide%3A+How+to+On-board+a+Playbook+to+Tooling) details how  a playbook is on-boarded to Tooling and the necessary requirements.

__These steps assume you have completed all onboarding steps required to run a playbook on Tooling__

Before running anything, work out what it is you want to do. Refer to the 5 options defined in the previous section.

This section will give a simple example of how to do this via tooling.

All variables should be defined in a plain text file that will be passed to the DWS client on job invocation. Their value has the same affect as the extra vars in the section above
The values of some variables in the file determine what actions will be taken when the playbook is run, i.e. disable the dns record in eu-west-2

As a minimum, the vars file should resemble something like the below:
```
awsEnv=lab
awsProfile=TOOLING
r53Zone=lab.cloud.natwestmarkets.com
r53Record=filetransfer
disableEuWest1=false
disableEuWest2=false
enableEuWest1=false
enableEuWest2=false
debugMe=false
```

### Run the playbook on Tooling ###

To run the playbook, ensure the vars are populated correctly in the r53extravars.txt file.

Run the following dws client command:
```
.\dws.exe ansible operation action --channel NWMCORE --environment dev --producttype aws --productversion AWS-1.0.0 --action manageR53AliasWeight --role operator --extravarsfile r53extravars.txt
```


Author Information
------------------
Initially Created by David Roberts - david.roberts@natwestmarkets.com


Version
------------------
0.2

