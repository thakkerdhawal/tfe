#!/usr/bin/env python

from botocore.vendored import requests
import json
import os
import sys
import time
import ast
import socket
url = 'https://' + os.environ['netcool_ip'] + "/netcool-prod"

default_headers = {
    #Note: Authorization and Postman-Token is hard coded, similar to what CTO has done as per System Management instruction.
    'Authorization': 'Basic dGl2b2xpOm5ldGNvb2w=',
    'Cache-Control': 'no-cache',
    'Content-Type': 'application/json',
    'Postman-Token': '3efbcebe-eb49-4124-a36f-66cca47124c8'
}

default_payload = {
    'AlertGroup': 'DES-Prod-CCT-eCommerce',
    'AlertKey': 'cwkeydefault',
    'Application': 'cwappdefault',
    'EventId': '0001',
    'Instance': 'cwinstancedefault',
    'Node': 'cwnodedefault',
    'Agent': 'cwagent',
    'Service': 'cwservicedefault',
    'Severity': '2',
    'Summary': 'Alert summary',
    'Component': 'cwcompdefault',
    'NodeAlias': 'cwapinodedefault'
}


def merge_payload_dicts(func_default_payload, func_inbound_payload):
    func_merged_dic = func_default_payload.copy()
    func_merged_dic.update(func_inbound_payload)
    return func_merged_dic


def process_sns_cw_alert(func_sns_event_record):
    cw_alarm_name = func_sns_event_record.get('AlarmName')
    aws_account_id = func_sns_event_record.get('AWSAccountId')

    # Assess the CW alarm name to build out the netcool fields
    if len(cw_alarm_name.split("-")) == 8:
        # The alarm has followed the naming convention to reach the CloudOps team
        cw_group = "DES-Prod-CCT-eCommerce"
        cw_app, cw_env, cw_instpre, cw_instpost, cw_comp, cw_metric, \
        cw_status, cw_agent = cw_alarm_name.split("-")
    elif len(cw_alarm_name.split("-")) == 9:
        cw_group, cw_app, cw_env, cw_instpre, cw_instpost, cw_comp,\
        cw_metric, cw_status, cw_agent = cw_alarm_name.split("-")
        cw_group = cw_group.replace("_", "-")
    else:
        cw_group = "DES-Prod-CCT-eCommerce"
        cw_app = "cloudwatch"
        cw_env = aws_account_id
        cw_instpre = "na"
        cw_instpost = cw_alarm_name
        cw_comp = "cloudwatch"
        cw_metric = "alarmname"
        cw_status = "unexpected"
        cw_agent = "cwalarm"

    if cw_instpre == "na":
        cw_instance = cw_instpost
    else:
        cw_instance = cw_instpre + "-" + cw_instpost

    cw_summary = "Alarm for " + cw_group + " in AWS account " + cw_env + " " + aws_account_id + \
                 " for " + cw_comp + " with ID " + cw_instance + " triggered by " + \
                 cw_metric + " " + cw_status

    func_json_payload = {
        'AlertGroup': cw_group,
        'AlertKey': cw_metric + cw_status,
        'Application': cw_app,
        'Instance': cw_instance,
        'Node': cw_instance,
        'Agent': cw_agent,
        'Service': cw_app,
        'Component': cw_comp,
        'Summary': cw_summary,
        'EventId': '0001',
        'Severity': '2',
        'NodeAlias': os.environ['netcool_ip']
    }
    return func_json_payload


def post_to_netcool(func_headers, func_payload):
    print "Message to post:"
    print json.dumps(func_payload)
    response = requests.post(url, data=json.dumps(func_payload), headers=func_headers, verify=False)
    return response


def clean_unicode_to_json(func_message_in):
    # CloudWatch has a bad habit of sending invalid nulls instead of None which invalidates the json
    func_message_in = func_message_in.replace(u"null,", u"None,")
    # Convert from unicode to string / json
    return_message = ast.literal_eval(func_message_in)
    return return_message


def lambda_handler(event, context):
    print event
    inbound_payload = ""
    if 'Records' in event:
        for record in event['Records']:
            if 'aws:sns' == record['EventSource'] and record['Sns']['Message']:
                sns_msg = record['Sns']['Message']
                if isinstance(sns_msg, unicode):
                    sns_msg = clean_unicode_to_json(sns_msg)
                else:
                    # Assume that its already a valid and clean dic
                    sns_msg = sns_msg
                if 'AlarmName' in sns_msg:
                    # Then this is a CW alert via SNS and we need to extract the
                    # appropriate fields to hit Netcool
                    inbound_payload = process_sns_cw_alert(sns_msg)
                else:
                    # Then this is a non CW SNS message and we will assume the
                    # JSON structure of the message matches what Netcool requires
                    inbound_payload = sns_msg
    else:
        # If its not an SNS message then lets assume its raw json in the required
        # format with the Netcool fields
        if isinstance(event, unicode):
            inbound_payload = clean_unicode_to_json(event)
        else:
            inbound_payload = event

    # Merge the data passed to the function with the default values to make sure all required fields populated
    full_payload = merge_payload_dicts(default_payload, inbound_payload)

    # Now post the message
    post_response = post_to_netcool(default_headers, full_payload)
    print "Message posted and response was:"
    print(post_response.status_code, post_response.reason)
