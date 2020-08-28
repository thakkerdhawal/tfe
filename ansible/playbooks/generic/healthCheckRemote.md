## healthCheck.yml Playbook ##

Sample Ansible playbook to compliment the [generic_healthCheck role](../../roles/generic_healthCheck)
Read the documentation there for how to re-use the role.

This playbook purely exists to demonstrate how to run the healthcheck role, though there is no reason why it cannot be used by other processes or cicd to test certain apps.

The playbook shows the use case for:
* From the Ansible host (localhost), connect to a remote FQDN/IP/Port or URL and test that an app or service is up and running on that remote host/load-balancer

Requirements
------------
* You will run this on either a jumphost or on tooling
* Ensure the Ansible host (jumphost/tower) can talk to that URL or FQDN and port.

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

#### Mandatory Vars for a Port Check ####

* __theHost__ - FQDN, IP of an endpoint to connect to - myapp.nlb.aws.com
* __thePort__ - Port of the endpoint to connect to - 80


#### Mandatory Vars for a URL Check ####

* __theUrl__ - Full URL to check - http://www.bbc.co.uk:80

## Getting Started on Ansible CORE (not Tower/Tooling)

Before running anything, work out what it is you want to do. Refer to the options described in the [role README](../../roles/generic_healthCheck)

### Perform a simple port test with a custom delay and timeout ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckRemote.yml -e "theDelay=0 theTimeout=10 thePort=22 theHost=myapp.nlb.aws.com"
```

### Perform a port test and look for a string in the port response ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckRemote.yml -e "thePort=8080 theString=MyApp theHost=myapp.nlb.aws.com"
```

### Perform a URL test with a custom timeout and check for the default 200, 201, 202 status code response ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckRemote.yml -e "theTimeout=10 theUrl=http://www.bbc.co.uk/sport:80"
```

### Perform a URL test and check for a string in the returned content with a custom delay and timeout value###

Run the following ansible command
```
ansible-playbook  playbooks/generic/healthCheckRemote.yml -e "theUrl=http://www.bbc.co.uk/sport:80 theString=football theDelay=2 theTimeout=10"
```

## Getting Started on Tooling (Ansible Tower)
tbc.


Author Information
------------------
Initially Created by David Roberts - david.roberts@natwestmarkets.com

Version
------------------
0.1
