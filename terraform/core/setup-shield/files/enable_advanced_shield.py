import boto3
import time
import os

shield = boto3.client('shield', region_name='us-east-1')
r53 = boto3.client('route53')
cf = boto3.client('cloudfront')

account_id = boto3.client('sts').get_caller_identity().get('Account')

def check_shield_status():
    resp = shield.get_subscription_state()
    print(resp['SubscriptionState'])
    return resp['SubscriptionState']


def enable_advanced_shield():
    shield.create_subscription()


def enable_drt_access():
    access = shield.describe_drt_access()
    drt_role = 'arn:aws:iam::' + account_id + ':role/aws-shield-drt-access'
    if 'RoleArn' not in access or access['RoleArn'] != drt_role:
        print("Associating DRT Access Role", drt_role)
        shield.associate_drt_role(RoleArn=drt_role)


def enable_drt_bucket_access():
    access = shield.describe_drt_access()
    bucket_list = list()
    remove = list()
    if 'shield_drt_buckets' in os.environ and os.environ['shield_drt_buckets']:
        bucket_list = os.environ['shield_drt_buckets'].split(",")
    if 'LogBucketList' in access:
        add = list(set(bucket_list) - set(access['LogBucketList']))
        remove = list(set(access['LogBucketList']) - set(bucket_list))
    else:
        add = bucket_list
    if remove:
        for b in remove:
            print("Disassociating DRT access for bucket", b)
            shield.disassociate_drt_log_bucket(LogBucket=b)
    if add:
        for b in add:
            print("Associating DRT access for bucket", b)
            shield.associate_drt_log_bucket(LogBucket=b)


def update_emails():
   emails = list()
   if "shield_notification_email" in os.environ and os.environ['shield_notification_email']:
      for email in os.environ['shield_notification_email'].split(","):
          emails.append({ 'EmailAddress': email })
          print("Adding", email, "to Shield Advanced notification email list")
   shield.update_emergency_contact_settings(EmergencyContactList=emails)

def get_list_of_albs(regions):
    alb_list = {}

    for reg in regions:
        alb = boto3.client('elbv2', region_name=reg)
        elb_arn = 'arn:aws:elasticloadbalancing:' + reg + ':' + \
            account_id + ':loadbalancer/app/'

        albs = alb.describe_load_balancers()

        if albs:
            for a in albs['LoadBalancers']:
                if a['Type'] == 'application':
                    alb_list[a['LoadBalancerName']] = a['LoadBalancerArn']
    return alb_list


def get_list_of_elbs(regions):
    elb_list = {}

    for reg in regions:
        elb = boto3.client('elb', region_name=reg)
        elb_arn = 'arn:aws:elasticloadbalancing:' + reg + ':' + \
            account_id + ':loadbalancer/'

        elbs = elb.describe_load_balancers()
        if elbs:
            for e in elbs['LoadBalancerDescriptions']:
                elb_name = e['LoadBalancerName']
                full_arn = elb_arn + elb_name
                elb_list[elb_name] = full_arn
    return elb_list


def get_route53_zones():
    zones = {}
    resp = r53.list_hosted_zones()

    if resp:
        for zone in resp['HostedZones']:
            zone_id = zone['Id'].lstrip('/')
            zone_name = zone['Name']
            arn = 'arn:aws:route53:::' + zone_id
            zones[zone_name] = arn
    return zones


def get_cloudfront_distros():
    distros = {}
    resp = cf.list_distributions()

    if resp and 'Items' in resp['DistributionList']:
        for distro in resp['DistributionList']['Items']:
            distro_id = distro['Id'].lstrip('/')
            distro_arn = distro['ARN']
            distros[distro_id] = distro_arn
    return distros


def get_list_of_eips(regions):
    eips = {}

    for reg in regions:
        ec2 = boto3.client('ec2', region_name=reg)
        resp = ec2.describe_addresses()
        if resp['Addresses']:
            for r in resp['Addresses']:
                arn = 'arn:aws:ec2:' + reg + ':' + account_id + \
                    ':eip-allocation/' + r['AllocationId']
                eips[r['AllocationId']] = arn
            
    return eips


def list_protections():
    ids = {}
    paginator = shield.get_paginator('list_protections')

    for response in paginator.paginate():
        for r in response['Protections']:
            id = r['Id']
            arn = r['ResourceArn']
            ids[id] = arn
    return ids


def create_protected_resources(existing_resources, resources):
    if resources:
        for k, v in resources.items():
            if v not in existing_resources.values():
                print("Creating protection for", k, "with arn", v)
                shield.create_protection(
                    Name=k,
                    ResourceArn=v
                )
    else:
        print('No resources found')


def remove_protected_resources(existing_resources, albs, elbs, r53, eips, cf):
    if existing_resources:
        for item_id, arn in existing_resources.items():
            a, w, restype, region, accid, resid = arn.split(":")
   
            del_item=False 
            if restype == "cloudfront":
                if arn not in cf.values():
                    del_item=True
            elif restype == "ec2":
                if arn not in eips.values():
                    del_item=True
            elif restype == "elasticloadbalancing":
                if arn not in albs.values() and arn not in elbs.values():
                    del_item=True
            elif restype == "route53":
                if arn not in r53.values():
                    del_item=True
            else:
                print("Unknown resource type protected")
            if del_item:
                print("Deleting protection for", item_id, "with arn", arn)
                shield.delete_protection(ProtectionId=item_id)


def lambda_handler(event, context):
    status = check_shield_status()
    if status == "INACTIVE":
        print("Enabling Adanced Shield")
        enable_advanced_shield()
        time.sleep(10)
    print('Updating DRT Access if required')
    enable_drt_access()
    enable_drt_bucket_access()
    print('Updating Emergency Email addresses')
    update_emails()

    # protect resources
    existing_resources = list_protections()
    print('Creating protected resources for ALBs')
    albs = get_list_of_albs(['eu-west-1', 'eu-west-2'])
    create_protected_resources(existing_resources, albs)
    print('Creating protected resources for ELBs')
    elbs = get_list_of_elbs(['eu-west-1', 'eu-west-2'])
    create_protected_resources(existing_resources, elbs)
    print('Creating protected resources for R53')
    r53 = get_route53_zones()
    create_protected_resources(existing_resources, r53)
    print('Creating protected resources for EIPs')
    eips = get_list_of_eips(['eu-west-1', 'eu-west-2']) 
    create_protected_resources(existing_resources, eips)
    print('Creating protected resources for Cloudfront Distros')
    cf = get_cloudfront_distros()
    create_protected_resources(existing_resources, cf)
    print('Remove protection for deleted resources')
    remove_protected_resources(existing_resources, albs, elbs, r53, eips, cf)
    print('Finished enabling Advanced Shield')
