# Overview

We take CA provided API Gateway AMI image and apply following customisations:

1. Patching
  * Install accumulated platform security patch
  * Install accumulated software patch
2. Build customisation 
  * Set password expiration time for default OS accounts
  * Extra RPM install
  * Set system timezone to UTC
  * Get configuration templates
    - iptable
    - rsyslog 
    - cron jobs
    - scripts
  * Update java DNS caching TTL: https://comm.support.ca.com/kb/api-gateway-dns-ttl/kb000012118
  * Install CloudWatch Agent for logging and metrics

See [this spreadsheet](https://collab.rbsres01.net/teams/destt-r2bf0f1y/Projects/Team%20Documents/Channels/Channels%20Engineering/SDP/CA-APIGW_v9.3%20build%20analysis.xlsx) for more details.

Note: currently the code only works for eu-west-1 because of eu-west-2 only supports AWS Signature Version 4, which is not yet implemented in our scripts.

# Step 1: Prepare the patch files

In order to patch the Gateway, we put patch files in a private AWS S3 buckets rather than pulling directly from CA. This is because:

* We do not want to rely on internet access at build time 
* We consider S3 is more reliable than CA's FTP server
* Access S3 bucket is more performant than downloading from CA's FTP server over internet
* The data is public 
* The patch file is too large to be hosted internally

While it is possible to manually retrieve patch file from CA and upload into a desinated bucket, we use the following script to do it. 

Prerequisites:
* get the link of patch from [CA Website](https://support.ca.com/us/product-content/recommended-reading/technical-document-index/ca-api-gateway-solutions-and-patches.html)
* the script should be run on a server with AWS CLI installed
* a valid AWS profile with sufficient permission to use S3 service
* the host should have sufficient free diskspace (ideally 4GB+)


  ```
# Note: 
-bash-4.2$ scripts/upload-patch-to-s3.sh -h

  Usage: scripts/upload-patch-to-s3.sh --source <patch file source url> --bucket <bucket> --profile <aws profile name> [--region <aws region>] [--awscli <aws cli>] [--tempdir <temp directory>] [--new] [--verbose [--help] [--keeppackage]
    -s|--source: Required. Source URL of the patch file from CA FTP (ftp://ftp.ca.com/)
    -b|--bucket: Required. Target S3 bucket for storing patches. (nwm-ca-apigw-patches for NWM SNP Refresh project.)
    -p|--profile: Required. AWS profile name in ~/.aws/credential
    -r|--region: Optional. AWS region of the S3 bucket. Default to eu-west-1
    -a|--awscli: Optional. Target S3 endpoint of the bucket. Default to $(which aws)
    -t|--tempdir: Optional. The temporary directory used for files in transit. 4GB freespace is recommended. Default to /var/tmp.
    -n|--new: Optional. Create new bucket if target bucket does not exist. Default behavior is abort.
    -k|--keeppackage: Optional. Keep the downloaded file. Default is to delete.
    -h|--help: display this message
    -v|--verbose: display DEBUG messages

  Example:

 scripts/upload-patch-to-s3.sh \
    --source ftp://ftp.ca.com/pub/API_Management/Gateway/Platform_Patch/v9.x/CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-07-24.L7P \
    --bucket nwm-ca-apigw-patches \
    --profile nwmss_test \
    --region eu-west-1 \
    --tempdir /var/tmp \
    --new \
    --verbose

  ```
Note that software patch are delivered inside a ZIP file, and the script will extract it before uploading to S3. See **Appendix** for more examples.

# Step 2: Execute Packer build

Prerequisites and assumptions:

* Packer binary is available 
* HTTP Proxy access has been setup in environment
* A valid AWS profile with sufficient permission in ~/.aws/credentials
* It needs to be executed on a jump server which has SSH access to the Bastion servers
* Subnet, Instance Profile (for S3 access) and Security Groups required by Packer have been created in target AWS account.
* Filename of the platform and software patch that needs be applied. **Set them to NONE if no patch needs to be applied. Do not leave it empty**.

While most variables can be overwritten, some of them must be set at runtime because they depend on how each individual setup their environment:
*  ```aws_profile```: this is the profile name of target AWS account in your AWS credential file
*  ```bastion_host```: the IP or hostname of the Bastion instance in NWM Shared Services VPC
*  ```ssh_key_profile```: an *absolute* path to the SSH key which has access to Bastion instance
*  ```gateway_version```: the source Gateway version we are going to use. e.g 9.3
*  ```software_patch```: a software patch we need to install. e.g CA_API_Gateway_v9.3.00-CR03.L7P
*  ```platform_patch```: a platform patch we need to install. e.g CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-12-23.L7P
*  ```ami_version```: a customised version identifier

To kick off the build, run packer build command:
```
# AWS_MAX_ATTEMPTS is required as it can take more than 10 mins to encrypt the AMI
AWS_MAX_ATTEMPTS=150 <PACKER_BINARY> build \
  <MANDATORY_VARIABLES>\
  ca_apigateway.json 

# Example with mandatory variables only:
AWS_MAX_ATTEMPTS=150 /usr/local/bin/packer.io build \
  -var "aws_profile=nwmss_test" \
  -var "gateway_version=9.3" \
  -var "software_patch=CA_API_Gateway_v9.3.00-CR03.L7P" \
  -var "platform_patch=CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-12-23.L7P" \
  -var "ami_version=1.0.4" \
  -var "bastion_host=10.8.4.24" \
  -var "ssh_key_file=/home/wangbh/.ssh/shared-services-lab.pem" \
  ca_apigateway.json
```

**The build process could take more than 30 mins depends on the number of patches that needs to be installed.** 

# Appendix

*Patch upload example*

```
$ ./scripts/upload-patch-to-s3.sh --source ftp://ftp.ca.com/pub/API_Management/Gateway/Platform_Patch/v9.x/CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-12-23.L7P --bucket des-ca-apigw-patches --profile des_sandbox --region eu-west-1 --tempdir /var/tmp --verbose
2019-01-15-10:33:17 INFO Creating log file /tmp/upload-patch-to-s3.sh-log.RP3I
2019-01-15-10:33:17 DEBUG checking patch file source url...
2019-01-15-10:33:18 DEBUG patch file source url accessible.
2019-01-15-10:33:18 DEBUG checking AWS credential of the given profile ...
2019-01-15-10:33:19 DEBUG AWS credential verified.
2019-01-15-10:33:19 DEBUG checking target S3 bucket ...
2019-01-15-10:33:20 DEBUG target S3 bucket found.
2019-01-15-10:33:20 INFO Download ftp://ftp.ca.com/pub/API_Management/Gateway/Platform_Patch/v9.x/CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-12-23.L7P to /var/tmp/tmp.6ceuOlc1V1 ...
2019-01-15-10:33:21 DEBUG Package size in bytes: 458305021
2019-01-15-10:33:21 DEBUG Available diskspace in bytes: 3745452032
2019-01-15-10:33:21 DEBUG Start downloading ...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  437M  100  437M    0     0  8737k      0  0:00:51  0:00:51 --:--:-- 8944k
2019-01-15-10:34:13 INFO Package downloaded.
2019-01-15-10:34:13 INFO Uploading patch to S3 bucket.
upload: ../../../../../../../var/tmp/tmp.6ceuOlc1V1/CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-12-23.L7P to s3://des-ca-apigw-patches/CA_API_PlatformUpdate_64bit_v9.X-RHEL-2018-12-23.L7P
2019-01-15-10:34:25 INFO Upload completed.
2019-01-15-10:34:25 INFO Removing all in transit files.
2019-01-15-10:34:25 INFO Completed.

$ ./scripts/upload-patch-to-s3.sh --source ftp://ftp.ca.com/pub/API_Management/Gateway/CR/CA_API_Gateway_v9.3.00-CR03.zip --bucket nwm-ca-apigw-patches --profile nwmss_test --region eu-west-1 --tempdir /var/tmp --verbose
2019-01-16-10:13:33 INFO Creating log file /tmp/upload-patch-to-s3.sh-log.uHeX
2019-01-16-10:13:33 DEBUG checking patch file source url...
2019-01-16-10:13:35 DEBUG patch file source url accessible.
2019-01-16-10:13:35 DEBUG checking AWS credential of the given profile ...
2019-01-16-10:13:36 DEBUG AWS credential verified.
2019-01-16-10:13:36 DEBUG checking target S3 bucket ...
2019-01-16-10:13:37 DEBUG target S3 bucket found.
2019-01-16-10:13:37 INFO Download ftp://ftp.ca.com/pub/API_Management/Gateway/CR/CA_API_Gateway_v9.3.00-CR03.zip to /var/tmp/tmp.HAcdOoldh4 ...
2019-01-16-10:13:38 DEBUG Package size in bytes: 1390825974
2019-01-16-10:13:38 DEBUG Available diskspace in bytes: 4174925824
2019-01-16-10:13:38 DEBUG Start downloading ...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1326M  100 1326M    0     0   579k      0  0:39:02  0:39:02 --:--:--  573k
2019-01-16-10:52:40 INFO Package downloaded.
2019-01-16-10:52:40 INFO Need to extract patch files from package.
2019-01-16-10:52:41 DEBUG Available diskspace in bytes: 2784096256
2019-01-16-10:52:41 DEBUG Start unpacking ...
2019-01-16-10:52:46 INFO Patch file extracted.
2019-01-16-10:52:46 INFO Uploading patch to S3 bucket.
upload: ../../../../../../../var/tmp/tmp.HAcdOoldh4/CA_API_Gateway_v9.3.00-CR03.L7P to s3://nwm-ca-apigw-patches/CA_API_Gateway_v9.3.00-CR03.L7P
2019-01-16-10:53:15 INFO Upload completed.
2019-01-16-10:53:15 INFO Removing all in transit files.
2019-01-16-10:53:15 INFO Completed.
```
