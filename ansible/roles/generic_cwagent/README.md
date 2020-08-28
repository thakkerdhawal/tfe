To enable cloudwatch agent to send required logs to cloudwatch logs for your component and enable  monitoring for your component ec2-instances under specified namespace.
Below role need to be included, which would update the cloudwatch agent configuration file with the desired log file and log group name and required monitoring namespace.

Requirements :

Include role - generic_cwagent into your component playbook.
The remote user specified in the playbook will be the user that connects to the server via ssh and should have permissions to utilise sudo.

Role Variables:

For Logging -

Update your components group vars as below to add the required log file logging.

code snipet :- To enable logging

###### This is a Sample Logging config example ################
cwagent_logging:
  /opt/app/ecomm/VLProxy/logs/VLProxyd.out:
      log_group_name: vlproxy_out
  /opt/app/ecomm/VLProxy/logs/VLProxyd.log:
      log_group_name: vlproxy_out
  /opt/app/ecomm/VLProxy/logs/VLProxy.xml:
      log_group_name: vlproxy_xml
#######################################################

Update your components group vars as below to add the required namespace for your instance monitoring.

code snipet :- To enable monitoring under custom namespace

###### This is a Sample custom namespace config example ################

mon_ec2_namespace: "vlproxy"

#######################################################
Namespace is required for monitoring setup and each component can select its own namespace, for e.g.

cleo - vlproxy
apache reverse proxy - apache
apigw - apigw
librator - stream

The dict name for logging needs to be cwagent_logging - Mandatory
The variable name for monitoring namespace has been defined mon_Ec2_namespace - Mandatory
The key which would be your log file path. Note :- log file path is the key and a dict also hence require a ':' at the end.
log_group_name is the Mandatory value name, again as dict, this is to cater mulitple log file's to have the same log group.

Note:- If any other var name is used other than cwagent_logging and log_group_name, role execution would fail.
Also you can disable section of cwagent config file by setting below variables to false in the group vars file.
for e.g. 
To disable logging section of cwagent config file set below in group vars, only default Operating system logging would be collected.
update_cwagent_logs: "False"
To disable Monitoring metric section of cwagent file set below in group vars.Note:- No monitoring metric would be collected from the instance.
update_cwagent_metrics: "False"

Example: To update Cloudwatch agent for Cleo instances -

Prerequisites
generic_cwagent role is included in the Cleo playbook.
group vars for cleo are updated with correct values, as described above.

$ export CONSUL_HTTP_TOKEN=XXXX
$ ansible-playbook playbooks/cleo/vlproxy_installConfig.yml
