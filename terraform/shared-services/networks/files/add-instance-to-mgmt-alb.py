#!/usr/bin/env python3

import boto3
import os
import json 

client = boto3.client('elbv2')


def check(event):
    flag_add = True
    try:
        # describe target group
        target_describe = client.describe_target_groups(Names=[event['targetgroup_Name'], ])
        #print("route table" + json.dumps(target_describe))
        targetgroup_ARN = target_describe["TargetGroups"][0]["TargetGroupArn"]

        targets  = client.describe_target_health(TargetGroupArn=targetgroup_ARN)

        # Remove unhealthy or unavail state targets 
        for target in targets["TargetHealthDescriptions"]:
          state = target["TargetHealth"]["State"]
          instance_IP = target["Target"]["Id"]
     
          if state in ["unhealthy","unavail"]:
             print(" Will be removed, in state: " + state +", instance IP: "+ instance_IP)
             response = client.deregister_targets(TargetGroupArn=targetgroup_ARN, Targets=[{'Id': instance_IP},])
          if instance_IP == event['instance_IP']:
            print("Target: "+instance_IP+", already exists in state: " +state)
            response ="Target: "+instance_IP+", already exists in state: " +state
            flag_add = False
         
        # add target to target group
        if flag_add:
           response = client.register_targets(TargetGroupArn=targetgroup_ARN, Targets=[{'Id': event['instance_IP'],'AvailabilityZone': 'all'},])
           print(response)
         
        return response 

    except client.exceptions.ClientError as e:
        return str(e)

def lambda_handler(event, context):

    message = check(event)

    return {
        'message': message
        }

# This is only used for local testing
if __name__ == "__main__":
    event = {"targetgroup_Name": "lab-apigw-mgmt-1-tg","instance_IP": "10.8.100.100"} 
    context = []
    lambda_handler(event, context)
