apache_deploy instance 
=========

This role can be used to deploy apache on target server.

Requirements
------------

* A playbook which can call this role
* It is assumed that the remote user specified in the playbook will be the user that connects to the server via ssh and has permissions to utilise sudo to root for now to update SELinux policy to allow http ports
* SSH access to the target server(s)
* Apache archive has been uploaded to the target server.
* Appropriate httpd config files for the apacheInstanceName are available for each env in playbook/apache/files/apacheInstanceName

Role Variables
--------------

This role requires a number of variables to be populated to run.

The below list uses the following format: varName_ - _description_ -  _Sample_ _value_

#### Mandatory Vars #### 
N/A


#### Optional Vars ####
# defaults for apache_deploy role which are pretty much self-explanatory
* packageLocation: "{{ destFilePath }}" 
* apacheUser: ec2-user
* apacheGroup: ec2-user
* apacheUpdateFlag: False 
* destDir: "/opt/app/ecomm/Web/{{ apacheInstanceName }}"

#### apachePort ####
apachePort is dynamically calculated but one can overwrite the value by settting as extra vars.
Note, apachePort is calculated from httpd-ssl.conf file on target host, using Listen statement.
By default selinux allows 8443 port. 

Dependencies
------------
N/A

Example Playbook
----------------

Including an example of how to use your role: 

```
- hosts: apache_servers
  roles:
    - apache_deploy
```


Including an example of how to run playbook, for instance, with variables passed in as parameters is always nice for users too:

```
$ansible-playbook playbooks/apache/apache_setup.yml -e "env=lab" -e "region=eu-west-2" -e "apacheInstanceName=bondsyndicate"
```
