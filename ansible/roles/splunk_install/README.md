splunk_install
=========

This role can be used to install Splunk on target server. The roles has to main tasks:

- install.yaml: this installs Splunk binary and only runs when "first_run" is true. This is meant for a fresh install and not for upgrade.
- configure.yaml: this performs configuration of Splunk instance.

Requirements
------------

* A playbook which can call this role
* It is assumed that the remote user specified in the playbook will be the user that connects to the server via ssh and has permissions to utilise sudo to start Splunk at boot time
* SSH access to the target server(s)
* Splunk installer package has been uploaded to the target server.

Role Variables
--------------

This role requires a number of variables to be populated to run. Without the mandatory variables being defined the role will fail to execute.

The below list uses the following format: varName_ - _description_ -  _Sample_ _value_

#### Mandatory Vars ####
* __splunkRole_- the type of splunk instance, e.g splunk_web or splunk_fwd.
* __adminPassword__ - the initial password for admin user. Must be provided for first time install.
* __splunkCert__ - content of server certificate. 
* __splunkCertPassword__ - password of server certificate. 

#### Optional Vars ####
* __first_run__ - this will trigger the install task and deploy the binary. Default to true
* __destDir__ - where Splunk should be installed. Default to /ecomm
* __splunkHome__ - the splunk directory. Default to "{{ destDir }}/splunk"
* __splunkExec__- the splunk executable. Default to "{{ splunkHome }}/bin/splunk"
* __splunkCertPath__- the splunk certificate file. Default to "$SPLUNK_HOME/etc/auth/{{ splunkCertFile }}"
* __splunkCACertPath__- the splunk CA certificate file. Default to "$SPLUNK_HOME/etc/auth/{{ splunkCACertFile }}"
* __splunkUser__ - the user name of Splunk installation. Default to ansible_user. This is also the runtime account.
* __splunkGroup__ - the group name of Splunk installation. Default to ansible_user.
* __enableWebGui__ - whether to enable GUI access. Default to false.
* __splunkHttpPort__ - HTTPS port for GUI access. Default to 8443.
* __splunkMgmtPort__ - HTTPS port for GUI access. Default to 8443.
* __splunkConfig__ - configuration files to be deployed. No default.
* __splunkCertNameToCheck__ - used for verifying SSL certificate. No default.
* __splunkOutputServers__ - target output servers for forwarder. No default

Dependencies
------------
N/A

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```
- include_role:
    name: splunk_install
  vars:
    splunkRole: splunk_web
    splunkConfig: files/etc
    first_run: false
```

