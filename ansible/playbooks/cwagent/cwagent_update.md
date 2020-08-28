cwagent_update.yml - Generic Playbook to update cloudwatch agent configuration file on ec2 instance as a one-off task.

Overview
EC2 instances are provisioned in NWM Shared-Services and Core VPC, and this playbook will perform the following actions:
Extract the target instances IP from Consul and add to inventory
Update the CloudWatch agent configuration file as per the vars_files file.
Restart the Cloudwatch agent

Prerequisites

Consul access token is required to read KV. It can either be defined in environment var CONSUL_HTTP_TOKEN or pass into the playbook as extra var consulTokenPassword

Variables Used

The following vars must be passed into the playbook as extra vars, below is example for Bastion ec2 instance cwagent config update.
awsEnv='lab/cicd/prod'
awsRegion='eu-west-1/eu-west-2'
awsAcc='shared-services'
awsComp='bastion'
awsCompPrivIps='bastion_hosts'
groupName=bastion

For Logging -

Update bastion_cwagent vars_files file as below to add the required log file logging.

code snipet :- To enable logging
###### This is a sample Bastion host Logging config ################
cwagent_logging:
  /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log:
      log_group_name: cwagent-logs

For Monitoring -

Update bastion_cwagent vars_files file as below to add the required namespace for your bastion instance monitoring.

code snipet :- To enable monitoring under custom namespace
###### This is sample Bastion host  Monitoring config ################
mon_ec2_namespace: bastion


The dict name for logging needs to be cwagent_logging - Mandatory
The variable name for monitoring has been defined mon_Ec2_namespace - Mandatory
The key which would be your log file path. Note :- log file path is the key and a dict also hence require a ':' at the end.
log_group_name is the Mandatory value name, again as dict, this is to cater mulitple log file's to have the same log group.

Note:- If any other var name is used other than cwagent_logging and log_group_name, role execution would fail.
Also you can disable section of cwagent config file by setting below variables to false in the correct vars_files file.
for e.g.
To disable logging section of cwagent config file set below in vars_files file.Note:-only default Operating system logging would be collected.
update_cwagent_logs: "False"
To disable Monitoring metric section of cwagent file set below in vars_files file.Note:- No monitoring metric would be collected from the instance.
update_cwagent_metrics: "False"

Example: To update Cloudwatch agent for Bastion instances -

Getting Started
 Identify the logs which need to be sent to CloudWatch Logs by the agent, along with the LogGroup Name, for your component.
 Update the vars_files file as mentioned above with the log file path,log group name and namespace.

Example: Update Cloudwatch agent for Bastion instances
$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/cwagent/cwagent_update.yml -e "awsEnv=lab" -e "awsRegion=eu-west-1" -e 'awsAcc=shared-services' -e 'awsComp=bastion' -e 'awsCompPrivIps=bastion_hosts' -e 'groupName=bastion'
