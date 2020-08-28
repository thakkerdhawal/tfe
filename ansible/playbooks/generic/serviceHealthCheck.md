## serviceHealthCheck.yml Playbook ##

This playbook runs through a list of pre-defined health check URLs for a given NatWest Markets new SNP environment. 

The list of health checks are defined in ```vars_files/healthcheck``` by environments, for example:
```
lab:
  # API Gateway status check
  - theUrl: https://www.lab.cloud.agilemarkets.com/check/wsg/local
    theString: "donotcheck"
```
While port check is supported by this playbook, it is usually restricted from internal network against an external target. 

Requirements
------------
* You will run this on either a jumphost or on tooling
* Ensure the Ansible host (jumphost/tower) can talk to that URL or FQDN and port. (most likely via Web Proxy)

Variables Used
--------------

The below list uses the following format: varName_ - description - Sample value

* This does not document vars required by the [generic_healthCheck role](../../roles/generic_healthCheck)
* It documents what vars are required in addition to run this playbook and call that role.

#### Mandatory Vars ####

* __awsEnv__ - the target AWS environment (i.e lab, cicd, nonprod or prod) - lab

#### Optional Vars ####

* __allowFailure__ - to allow the playbook to go through all pre-defined checks regardless of the test result (default to false). This is useful if failure is expected for one or more checks. - true

### Perform health check for lab environment - stop on any failed check ###

```
ansible-playbook  playbooks/generic/serviceHealthCheck.yml -e "awsEnv=lab"
```

### Perform health check for nonprod environment and ignore failed checks ###

Run the following ansible command
```
ansible-playbook  playbooks/generic/serviceHealthCheck.yml -e "awsEnv=nonprod" -e "allowFailure=true"
```

