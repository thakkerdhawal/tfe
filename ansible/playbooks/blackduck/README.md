## Prerequisites 
- Blackduck appliance has been stood up by Terraform in Shared Services environment

## Configuration of Blackduck appliance - Ansible
- It is assumed that Ansible playbook will be run from the same host as Terraform
- `ansible-playbook playbooks/blackduck/blackduck_config.yml --extra-vars "env=lab blackduck_db_user_pass=xxx blackduck_db_pass=xxx consul_token=xxx"`. 
- This password is the password of the blackduck_user and admin blackduck users of the RDS. Also the consul token for read access to the shared services area of consul
- Defaults to eu-west-2 but if you want to override set a variable region=eu-west-1

## FAQ

