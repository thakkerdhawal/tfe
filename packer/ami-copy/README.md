# ami-copy.sh

* [ami-copy.sh] -  Copy an ami-image from one account/region to another

# Introduction

AWS AMI is based on EBS snapshot and is region specific. So in order to make sure we are using the same AMI acorss different environment, we need to be able to copy AMI from a "golden" source. There are certain challenge when the AMI is encrypted, see [this blog post](https://aws.amazon.com/blogs/aws/new-cross-account-copying-of-encrypted-ebs-snapshots/) for more details.

 - This script can copy an encrypted AMI from one account or region to another
 - To copy AMI from one region to another within the same account, set the source and destination profile to the same.
 - It only supports copying encrypted AMI at the moment
 - Script logic: 
   - If no source Customer Managed Key (CMK) were provided as input:
     - if the snapshot is encrypted by a CMK, the script will copy this snapshot
     - if the snapshot is encrypted by AWS managed key, the script will generate a temp CMK to generate a temp snapshot for copying. The temp snapshot and key will be deleted afterward.
   - If a source CMK were provided as input:
     - if the snapshot is encrypted by the given CMK, the script will copy this snapshot
     - if the snapshot is not encrypted by the given CMK, the script will generate use the key to generate a temp snapshot for copying. The temp snapshot will be deleted afterward.
   - If no destination CMK were provided as input, the destination snapshot will be encrypted using AWS managed key
   - If a destination CMK were provided as input, the destination snapshot will be encrypted using the provided key

- Below are the permissions need to be granted for an IAM user:
   - On Source Account:
      - ScheduleKeyDeletion for deleting temp source CMK generated
      - CreateGrant to perform  DescribeKey and Decrypt operations and  GenerateDataKeyWithoutPlaintext Permission to get the data key that is encrypted with new temp CMK
   - On Destination Account:
      - CreateGrant to perform  DescribeKey and Decrypt operations 
      - GenerateDataKeyWithoutPlaintext to get the data key that is encrypted with new temp CMK

# Prerequisites

 - Internet access (to access AWS API) is available on the host where this script is executed
 - aws cli must be installed on the host where this script is executed
 - User must have a credentials file in ~/.aws with access to both accounts, and valid profiles setup in the credential file

# Usage

```bash
 Usage: ./ami_copy.sh -p SRC_PROFILE -r SRC_REGION -P DST_PROFILE -R DST_REGION -a AMI_ID [-k SRC_CMK_ID -K DST_CMK_ID]
    -p,               AWS CLI profile name for AMI source account.
    -r,               AWS region for AMI source account.
    -P,               AWS CLI profile name for AMI destination account.
    -R,               AWS region for AMI destination account.
    -a,               ID of AMI to be copied.
    [-k,              Optional: specific KMS Source Customer Managed Key (CMK) ID for snapshot re-encryption in source AWS account.]
    [-K,              Optional: specific KMS Dest Customer Managed Key (CMK) ID for snapshot re-encryption in target AWS account. The default KMS key for EBS volume will be used if omit.]
    [-h,              Show this message.]

    Typical usage:

        ami_copy.sh -p nwmss_test -r eu-west-2 -P nwm_test -R eu-west-1 -a ami-5a9e8eb0
        ami_copy.sh -p nwmss_test -r eu-west-2 -P nwm_test -R eu-west-1 -a ami-5a9e8eb0 -k a580daa2-3063-416a-ae44-9f099c8a51ba

```

# Example output

```bash
$ ./ami_copy.sh -p nwmss_test -r eu-west-2 -P nwm_test -R eu-west-2  -a ami-02509e0763e2b5a4b
Source region: eu-west-2
Source account ID: 897059257821
Destination region: eu-west-2
Destination account ID: 724329805838
Found AMI:  ami-02509e0763e2b5a4b
AMI encryption status:  true
No desination key provided, will use default KMS key.
Found default KMS key for EBS in dest account: 8f4e6777-b2cf-441e-8345-41f02b78f865
Snapshot found: snap-03840bb6187a3ae12
KMS key(s) used on source AMI: de404903-52cc-4841-b3a9-e7b5313a0dc7
Current key de404903-52cc-4841-b3a9-e7b5313a0dc7 is not customer managed. A temporary CMK will be generated.
Temp CMK generated: 0ddd865f-9c34-416c-8ac5-6d6b0c14287d
Waiting for Snapshot snap-0332bb3fe6dbae1e7 copy to complete.  Progress 0%
Waiting for Snapshot snap-0332bb3fe6dbae1e7 copy to complete.  Progress 0%
Waiting for Snapshot snap-0332bb3fe6dbae1e7 copy to complete.  Progress 0%
Waiting for Snapshot snap-0332bb3fe6dbae1e7 copy to complete.  Progress 0%
Snapshot copy completed:  snap-0332bb3fe6dbae1e7
Calling check_perms_on_snapshot again with our new snapshot snap-0332bb3fe6dbae1e7
KMS key(s) used on source AMI: 0ddd865f-9c34-416c-8ac5-6d6b0c14287d
Source CMK 0ddd865f-9c34-416c-8ac5-6d6b0c14287d is currently used by the AMI.
Copying Snapshot to Destination Account-ID 724329805838
Permission added to Snapshot: snap-0332bb3fe6dbae1e7
Destination snapshot is getting created: snap-0452ef95487d1c757
Waiting for Snapshot snap-0452ef95487d1c757 copy to complete.  Progress 0%
Waiting for Snapshot snap-0452ef95487d1c757 copy to complete.  Progress 0%
Waiting for Snapshot snap-0452ef95487d1c757 copy to complete.  Progress 0%
Waiting for Snapshot snap-0452ef95487d1c757 copy to complete.  Progress 0%
Snapshot copy completed:  snap-0452ef95487d1c757
Snapshots snap-0332bb3fe6dbae1e7 copied as snap-0452ef95487d1c757
AMI created succesfully in the destination account: ami-0c15196b742bdc184
Tags added sucessfully
Remove the Temporary Snapshot Created In Source Account As No Longer Needed snap-0332bb3fe6dbae1e7
{
    "KeyId": "arn:aws:kms:eu-west-2:897059257821:key/0ddd865f-9c34-416c-8ac5-6d6b0c14287d",
    "DeletionDate": 1547683200.0
}
Scheduled removal of temp CMK 0ddd865f-9c34-416c-8ac5-6d6b0c14287d
Copy Has Completed Successfully
```


# Future work

 - To support copying of unencrypted AMI
 - Consider create and manage a dedicated CMK

