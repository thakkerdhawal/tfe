stream_install
=========

This role can be used to install the config files for Caplin Liberator on target server. 
It performs the following tasks:
* Copies config files to host (Config files are stored with the playbook)
* Configures ports, passwords, java version, topic enabler
* Creates self signed cert if it doesn't exist
* Installs the binary log shipper to s3 script and enables it to be run by crontab at 1 past each hour

Note that the s3 upload script uses a modified 3rd party script from https://github.com/wikiwi/s3-bash4. It's been modified to enable us to specify a storage class (Glacier).

Requirements
------------

* A playbook which can call this role
* It is assumed that the remote user specified in the playbook will be the user that connects to the server via ssh and has permissions to utilise sudo to start the Liberator at boot time
* SSH access to the target server(s)
* Caplin Liberator binaries and Java binaries have been uploaded and installed to the target server.
* For tooling, appropriate channel and access is configured

Role Variables
--------------

This role requires a number of variables to be populated to run. Without the mandatory variables being defined the role will fail to execute.

The below list uses the following format: varName_ - _description_ -  _Sample_ _value_

#### Mandatory Vars ####
* __streamDest__ - the location of the Liberator install. eg. /ecomm/caplin/liberator/stream-agilemarkets/current/
* __streamPortNumbers__ - The port numbers the Liberator will listen on in a comma separated list (usually sourced from consul). eg 4447,25002,18009
* __javaVersion__ - The version of java to use (usually source from consul) eg. 1.8.0_92
* __agilemarketsDnsExternal__ - The possible refer URLs in a comma separated list. The first one will be used for topic enabler. eg www.agilemarkets.com,www5.agilemarkets.com

Dependencies
------------
N/A

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```
- include_role:
    name: stream_install
  vars:
    streamDest: /ecomm/caplin/liberator/stream-agilemarkets/current/
```

