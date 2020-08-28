#!/usr/bin/env python3

import boto3
import os
import json 
import sys
import time 
import datetime

client = boto3.client('logs')
clientfirehose = boto3.client('firehose')
account_id =  boto3.client('sts').get_caller_identity().get('Account')
account_alias = boto3.client('iam').list_account_aliases()['AccountAliases'][0]
region = os.environ["AWS_REGION"]
LOGGROUP_EXPIRY_TIME=(2 * 30 * 24 * 60 * 60) # 2 months old

#check if firehose delivery stream exists
def check_firehose_delivery_stream(firehose_stream_name):
    count = 0

    try:
      while True and count < 8:  
        response = clientfirehose.describe_delivery_stream(DeliveryStreamName=firehose_stream_name)
        if response['DeliveryStreamDescription']:
            delivery_stream_arn = response['DeliveryStreamDescription']['DeliveryStreamARN']
            delivery_stream_status = response['DeliveryStreamDescription']['DeliveryStreamStatus']
            if delivery_stream_status == "CREATING":
               print("check_firehose_delivery_stream: waiting for status to become active")
               time.sleep(20)
               count+=1
            if delivery_stream_status == "ACTIVE":
               print("Info: firehose stream exists in ACTIVE state") 
               return delivery_stream_arn
    except clientfirehose.exceptions.ClientError as e:
      if "ResourceNotFoundException" in str(e):
         print("Info: firehose stream does not exists")
         return None 
      else:
         return str(e)
         sys.exit(1)
    
    if (delivery_stream_status == "CREATING" or delivery_stream_status == "DELETING"):
       print("Error: firehose_delivery_stream_status is stuck in creating or in deleting status: "+ firehose_stream_name)
       sys.exit(1)

def create_firehose_stream(firehose_stream_name):

   role_arn = "arn:aws:iam::"+account_id+":role/kinesis-firehose-role"

   bucket_arn= "arn:aws:s3:::logging-"+account_alias+"-cloudwatch-"+region
   bucket_prefix = firehose_stream_name.rsplit('-', 1)[0]+"/"

   response = clientfirehose.create_delivery_stream(
                     DeliveryStreamName=firehose_stream_name,
                     DeliveryStreamType='DirectPut',
                     ExtendedS3DestinationConfiguration={
                               'RoleARN': role_arn, 
                               'BucketARN': bucket_arn, 
                               'Prefix': bucket_prefix, 
                               'CompressionFormat': "GZIP",
                               'CloudWatchLoggingOptions': {
                                     'Enabled': True,
                                     'LogGroupName': 'firehose-s3-delivery-error-loggroup',
                                     'LogStreamName': 'firehose-s3-delivery-error'
                               }, 
                               'BufferingHints': {
                                     'IntervalInSeconds': 60 
                               },
                               'ProcessingConfiguration': {
                                          'Enabled': True,
                                          'Processors': [
                                              {
                                                  'Type': 'Lambda',
                                                  'Parameters': [
                                                       {
                                                         'ParameterName': 'LambdaArn',
                                                         'ParameterValue': os.environ['cwlogs_processor_arn']
                                                        },
                                                   ]
                                              },
                                           ]                 
                                },
                     }
               )
   return response

#Function only prints the log group we should delete; will delete once we start seeing correct log groups beeing picked up.
def cleanup_unused_logstream(log_group_name, log_group_creationtime):
    # loop through all the loggroups and delete loggroup+firehose when loggroup didnt had an event for last three months.
    logstreams = client.describe_log_streams(logGroupName=log_group_name,orderBy='LastEventTime', descending=True, limit=1)
    if logstreams['logStreams'] and logstreams['logStreams'][0] and 'lastEventTimestamp' in logstreams['logStreams'][0]:
       lasteventime =  logstreams['logStreams'][0]['lastEventTimestamp']
       print("log group creation time: " + time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(log_group_creationtime/1000)))
       print("last event time: "+ time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(lasteventime/1000)))
       # Log group is older than 2 months and it has not got any logs (in log stream ) for last two months
       if (time.time() - (lasteventime/1000) > LOGGROUP_EXPIRY_TIME) and (time.time() - (log_group_creationtime/1000)) > LOGGROUP_EXPIRY_TIME:
          print("we should delete this loggroup: " + log_group_name)
    else:
      # NO logs in loggroup but its older than 2 months
      if (time.time() - (log_group_creationtime/1000)) > LOGGROUP_EXPIRY_TIME:
          print("we should delete this loggroup: " + log_group_name)


# get all pages for a resource
def get_allpages(client, function_name, item_name):
    ret_list = []
    paginator = client.get_paginator((function_name))
    for page in paginator.paginate():
        ret_list += page[item_name]
    return ret_list

def check(event):
    try:
        # describe log groups
        loggroups = get_allpages(client, "describe_log_groups", "logGroups")
    
        for loggroup in loggroups:
           
           log_group_name = loggroup['logGroupName']
           print("\n\n\nLOG GROUP NAME: "+ log_group_name)

           # first cleanup the unused log stream 
           cleanup_unused_logstream(log_group_name, loggroup['creationTime'])
    
           if log_group_name.startswith("/"):
               # for string starting with hypen /aws/lambda/cicd-add-instance-to-mgmt-alb 
               firehose_stream_name = log_group_name[1:].replace("/","-") +"-stream"
           else:
               # for string not starting with hypen oslogs
               firehose_stream_name = log_group_name.replace("/","-") +"-stream"
  
           delivery_stream_arn = check_firehose_delivery_stream(firehose_stream_name)

           #create firehose stream if it does not exists
           if not delivery_stream_arn:
              response = create_firehose_stream(firehose_stream_name)
              #print response 
              delivery_stream_arn = check_firehose_delivery_stream(firehose_stream_name)
          
           #put subscription filter
           filter_name = log_group_name[1:].replace("/","-") +"-filter"
           role_arn = "arn:aws:iam::"+account_id+":role/cloudwatchlogs-to-firehose-role"
           response = client.put_subscription_filter(logGroupName=log_group_name, filterName=filter_name,  filterPattern='', destinationArn=delivery_stream_arn, roleArn=role_arn)
           print("Subscription Filter added")
 
           #set retention policy to loggroup
           response = client.put_retention_policy(logGroupName=log_group_name, retentionInDays=90)
           print("Retention policy added")

        return 1

    except client.exceptions.ClientError as e:
        return  str(e)
        

def lambda_handler(event, context):

    message = check(event)

    return {
        'message': message
        }

# This is only used for local testing
if __name__ == "__main__":
    event = {}
    context = []
    lambda_handler(event, context)
