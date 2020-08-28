# auth_adfs.sh

This is a wrapper script for AWS programmatic access using ADFS authentication.

The script will create and maintain profile entries in your aws credential file. Each profile will be mapped to a specific AWS account and role. It will not request new token if the target profile already has an valid token and will not expire in 1200 seconds.

## Pre-requisite

* saml2aws is available on the host running this script
* your account (either FM or EUROPA) has been added to the relevant AD groups (see this[Confluence Page]( https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AWS+SOP%3A+Access+Model+-+DEng+Support+using+ADFS#AWSSOP:AccessModel-DEngSupportusingADFS-RolesandGroups) for more details).
* internet access is available (via proxy) 

## How to use

```
  Usage: ../../../scripts/auth_adfs.sh -p <profile> [-r <role> -t <threshold>]
    -p|--profile: target aws profile. Required.
    -r|--role: the AWS role to assume. Default is ADFS-PowerUsers.
    -t|--threhold: how many seconds the token needs to be valid before refresh. Default is 1200.
    -h|--help: print this message

  Example:
         ../../../scripts/auth_adfs.sh -p nwm_lab
         ../../../scripts/auth_adfs.sh -p nwm_lab -r FMADFS-PowerUsers -t 600
```

Below is an example of setting up a new profile for FMADFS-PowerUsers role in AWS account 897059257821. Not domain "fm" is specified here to use FM account. Europa user does not have to specify domain.

```
# Since ADFS-PowerUsers is the default role, europa user can just run: ./auth_adfs.sh -p example_profile 
$ ./auth_adfs.sh -p example_profile -r FMADFS-PowerUsers -d fm
2019-02-06-15:35:38 INFO Creating log file /tmp/auth_adfs.sh-log.8UgG
2019-02-06-15:35:38 INFO Looking for example_profile in saml2aws configure ...
2019-02-06-15:35:38 WARN No valid matching profile found.
```
For setting up a profile the first time, you need to know which AWS account you are targeting, and the script will generate SAML2AWS configuration (~/.saml2aws) for you:
```
Would you like to setup the profile now? [y/n]y
Please provide the target account number (https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AWS+SOP%3A+Access+Model+-+DEng+Support+using+ADFS): 897059257821

account {
  URL: https://sts.rbs.co.uk/adfs/ls/idpinitiatedsignon.aspx
  Username: fm\wangbh
  Provider: ADFS
  MFA: Auto
  SkipVerify: true
  AmazonWebservicesURN: urn:amazon:webservices
  SessionDuration: 3600
  Profile: saml
  RoleARN: arn:aws:iam::897059257821:role/FMADFS-PowerUsers
}
Configuration saved for IDP account: example_profile
```
The script will then proceed to check and request AWS security token for your target profile. If 
```
2019-02-06-15:35:45 INFO Validating AWS Security Token for example_profile ...
2019-02-06-15:35:45 WARN Cannot find a profile example_profile mapped to role 'FMADFS-PowerUsers'. New token should be requested.
2019-02-06-15:35:45 INFO Requesting new token ...
Using IDP Account example_profile to access ADFS https://sts.rbs.co.uk/adfs/ls/idpinitiatedsignon.aspx
To use saved password just hit enter.
? Username fm\wangbh
? Password ***********

Authenticating as fm\wangbh ...
Selected role: arn:aws:iam::897059257821:role/FMADFS-PowerUsers
Requesting AWS credentials using SAML assertion
Logged in as: arn:aws:sts::897059257821:assumed-role/FMADFS-PowerUsers/Beiming.Wang@rbs.com

Your new access key pair has been stored in the AWS configuration
Note that it will expire at 2019-02-07 03:35:58 +0000 GMT
To use this credential, call the AWS CLI with the --profile option (e.g. aws --profile example_profile ec2 describe-instances).
```
Once have you have the profile setup, you can refresh your token by just specifying the profile name:

```
$ ./auth_adfs.sh -p example_profile
2019-02-06-16:25:13 INFO Creating log file /tmp/auth_adfs.sh-log.SMb4
2019-02-06-16:25:13 INFO Looking for example_profile in saml2aws configure ...
2019-02-06-16:25:13 INFO This profile is currently mapped to role 'FMADFS-PowerUsers'.
2019-02-06-16:25:13 INFO Validating AWS Security Token for example_profile ...
2019-02-06-16:25:13 INFO Found a token valid till 2019-02-07T03:35:58Z
2019-02-06-16:25:13 INFO Token does not need to be refreshed.
```

