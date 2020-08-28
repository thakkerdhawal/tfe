import boto3
import os

def lambda_handler(event, context):
  s3 = boto3.resource('s3')

  print("Copying logs")
  for record in event['Records']:
    if "target_prefix" in os.environ:
      dest_key = os.environ['target_prefix'] + "/" + record['s3']['object']['key']
    else:
      dest_key = record['s3']['object']['key']
    
    print("Src: " + record['s3']['bucket']['name'] + ":" + record['s3']['object']['key'] + " Dest: " + os.environ['target_bucket'] + ":" + dest_key)
    copy_source = {
      'Bucket': record['s3']['bucket']['name'],
      'Key': record['s3']['object']['key']
    }
    dest_bucket = s3.Bucket(os.environ['target_bucket'])
    extra_args = {
      'ACL': 'bucket-owner-full-control'
    }
    dest_bucket.copy(copy_source, dest_key, extra_args)

