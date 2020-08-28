generic_healthCheck
=========

Simple role that provides the ability to perform basic healthchecks against an endpoint or a url.
The code will always ssh into the target instance to perform these tests.

It is expected that this role will be included in most application install/config playbooks to prove applications are listening/running as expected.

Currently, there are 4 possible tests. It is expected that this list will be extended with time.

### Port Based Tests ###

By default, the port tests will connect to the ip of the primary interface on the server (as opposed to localhost), you can override this using extra vars.
Overriding this would allow you to connect to a remote host altogether, i.e. designate the role to the localhost and specify a remote host and port.

* __Test 1__ - Simple port test, it will connect to the supplied port and check that it is open (it responds)
* __Test 2__ - Port test, it will connect to the supplied port and look for a particular string or regex in the response, i.e. SSH

### URL Based Tests ###

* __Test 3__ - Simple URL test, it will connect to a supplied URL and by default, look for a status code of 200, 201 or 202 (you can overwrite this with extra vars).
* __Test 4__ - URL content test, it will connect to a supplied URL and in the returned content, look for a particular string to check for (it will by default expect a status code of 200, 201, 202)

Requirements
------------

There are a number of requirements to run this role.

* You will run this on either a jumphost or on tooling
* Your playbook will provide the target hosts that this role will connect to
* If connecting to a host with SSH, You will need to enable fact gathering. i.e. gather_facts: true on the playbook that connects to the host 

__If running on Ansible core__
* The boto, boto3 and botocore packages have been installed via pip (may not be a hard requirement, but is recommended)
* You have valid Active AWS credentials defined as a profile in ~/.aws/credentials

__If running on Tooling (Ansible Tower)__
* If running on Tooling (Tower), temporary AWS creds will be generated based on the DES channel and environment that you define when running the playbook via the DWS client. These temporary credentials will be accessible via environment vars.
* Extra vars need to be created in a text file on your local file system and this file will need to be passed to the dws client as an argument on job invocation.

Variables Used
--------------

false values defined in the defaults/main.yml file are linked to when conditionals and functionality.

The below list uses the following format: varName_ - description - Sample value

* __debugMe__ - this will print output of any tests as well as the ip of eth0 (default set to false) - true, false

#### Mandatory Vars for Port Tests ####

* __thePort__ - the port that you wish to connect to - 9022

#### Additional Vars for Port Tests ####

Defaults are set in the [defaults/main.yml] file, however these can be overriden with extra vars

* __theString__ - the string that you wish to search for - OpenSSH
* __theDelay__ - how long to wait before connecting to the port (defaults to 10s) - 5
* __theHost__ - ip or fqdn that you wish to try and connect to (defaults to primary ip of the linux machine) - 10.8.8.6
* __theState__ - state of the port, (defaults to started) - absent, drained, present, __started__, stopped
* __theTimeout__ - how long the probe should run before it times out (default set to 60s) - 60
* __allowFailure__ - allow the play to continue even health check fails - false

#### Mandatory Vars for URL Tests ####

* __theUrl__ - the full URL that you wish to test - http://www.bbc.co.uk


#### Additional Vars for URL Tests ####

* __theString__ - the string that you wish to search for - login
* __theStatusCode__ - what http/https status code are you expecting, (defaults to 200, 201, 202) - 503
* __theTimeout__ - how long the connection request should try before it times out (default set to 60s) - 60


Example Playbook
----------------

To include this role in a playbook, use the following syntax:
```
    - hosts: groupName
      gather_facts: true
      roles:
       - ../../roles/generic_runHealthCheck #relative path to role from playbook directory
```

Author Information
------------------
Initially Created by David Roberts - david.roberts@natwestmarkets.com


Version
------------------
0.1
