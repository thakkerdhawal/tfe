##
##Notes:
# 1. This code is excuted via lambda function, in each region and account (SS and NWM).
# 2. NUMBER_AMI_KEEP refers to number of ami to keep of each type (rhel or apigw) for roll back purpose. 
# 3. EXPIRY_IN_DAYS refers to minimum number of days an ami should have passed before considering for delete.
# 4. Our decomm policy for an ami is:
#       * to make sure an ami is equal to or older than EXPIRY_IN_DAYS 
#       * has minium of NUMBER_AMI_KEEP versions for its type, 
#       * and it is not inuse 
#     before we can consider for delete. 
# 5. We only delete an oldest image during the each run of the script.


##Logic:
# 1. We loop through list of amis we received in response from aws. During loop we collect:
      # a. Oldest ami of each type -  name, count, ImageId and Version for its types.
      # b. List of expired image - is the list of ami ids that meets EXPIRY_IN_DAYS condition but cannot be deleted as there is an older image which is InUse.
# 2. We collect above information in below dictionary:
#
#'''
#oldest_ami_list = [{
#  'Count': 6,
#  'Name': 'nwm-rhel7-ami',
#  'ImageId': 'ami-01316c5c32de0ec00',
#  'Version': 'v1.0.4-b1553794469',
#  'AMIExpired': [{
#    'InUse': 0,
#    'ImageId': 'ami-00968a7f08c1744d6'
#  }, {
#    'InUse': 0,
#    'ImageId': 'ami-01316c5c32de0ec00'
# }, {
#   'InUse': 0,
#   'ImageId': 'ami-04385a22dcfcab0cd'
#  }, {
#   'InUse': 0,
#    'ImageId': 'ami-0d4373e315a4e35a0'
#  }, {
#    'InUse': 0,
#    'ImageId': 'ami-0e17efd9c77689c72'
#  }],
#  'CreationDate': datetime.datetime(2019, 3, 28, 23, 34, 55)
#}, {
#  'Count': 4,
#  'Name': 'des-ca-apigw-ami',
#  'ImageId': 'ami-0fe47744aa67a183b',
#  'Version': 'v1.0.4-b1551029685',
#  'AMIExpired': [{
#    'InUse': 0,
#    'ImageId': 'ami-016279df04ae2d300'
#  }, {
#    'InUse': 1,
#    'ImageId': 'ami-0fe47744aa67a183b'
#  }],
#  'CreationDate': datetime.datetime(2019, 2, 24, 17, 56, 7)
#}]
#'''
# 3. apply_policy function will checks
#           *  if it meets our decomm policy so that we can delete it.
#           *  if we cannot delete the ami as it is in use, then print out WARNING.
#           *  it will print out notice if ami only meets one of the condition "EXPIRY_IN_DAYS or NUMBER_AMI_KEEP".
# 4. Lastly, it print out all the ami which are not oldest but older than EXPIRY_IN_DAYS as WARINING. 



#!/usr/bin/env python3

import boto3
from datetime import datetime
from datetime import timedelta
import dateutil.parser


def print_msg(type, msg):
    print(type + ": " + msg)


EC2 = boto3.client('ec2')
NUMBER_AMI_KEEP = 3
EXPIRY_IN_DAYS = 180
TIME_THRESHOLD = datetime.now() - timedelta(days=EXPIRY_IN_DAYS)


def delete_ami(ami_id):
    ret = EC2.describe_images(ImageIds=[ami_id])

    if INFRA_ENV == "prod":
       print_msg("INFO", "delete_ami: AMID: " + ami_id + " cannot delete as it is in prod environment")
       return False
      
    # deregister_ami
    print_msg("INFO", "delete_ami: AMID: " + ami_id)
    # TODO: will enable once we have enough sample
    # EC2.deregister_image(ImageId=ami_id)

    # delete snapshot
    for snap in ret['Images'][0]['BlockDeviceMappings']:
        if 'Ebs' in snap:
            print_msg("INFO", "delete_ami: SnapID: " + snap['Ebs']['SnapshotId'])
            # TODO: will enable once we have enough sample
            # EC2.delete_snapshot(SnapshotId=snap['Ebs']['SnapshotId'])

    return True
    

def ami_in_use(ami_id):
    # check if ami in use
    #response = EC2.describe_instances( Filters=[{ 'Name': 'image-id', 'Values': ["ami-0ccc38bdfe19fde40"]}])
    response = EC2.describe_instances(Filters=[{'Name': 'image-id', 'Values': [ami_id]}])
    if response["Reservations"]:
        return response["Reservations"]
    else:
        return False


def print_expire_ami(oldest_ami_list):
    for ami in oldest_ami_list:
        for item in ami["AMIExpired"]:
            if item["ImageId"] != ami["ImageId"]:
                if item["InUse"]:
                    print_msg("WARNING", "Image: " + ami["Name"] + ", " + item[
                        "ImageId"] + " is InUse but older than EXPIRY_IN_DAYS: " + str(EXPIRY_IN_DAYS) +
                        ", but cannot be deleted as there might be an image which is older then this image and inUse")
                else:
                    print_msg("WARNING", "Image: " + ami["Name"] + ", " + item[
                        "ImageId"] + " is not InUse and older than EXPIRY_IN_DAYS: " + str(EXPIRY_IN_DAYS)+
                        ", but cannot be deleted as there might be an image which is older then this image and inUse")


def apply_policy(oldest_ami_list):
    # Go through the list of oldest ami and see if it meets policy
    for ami in oldest_ami_list:
        # Older than EXPIRY_IN_DAYS
        if ami["CreationDate"] < TIME_THRESHOLD:
            # But does not have enough number of version for similar type
            if ami["Count"] < NUMBER_AMI_KEEP:
                print_msg("NOTICE", "apply_policy: the AMI: " + ami["Name"] + ", " + ami[
                    "ImageId"] + "does not have enough number of version, so it cannot be deleted")

            # Older than EXPIRY_IN_DAYS and has enough number of version for similar type
            else:
                # check if ami in use, if not delete ami
                ret = ami_in_use(ami["ImageId"])
                if ret:
                    print_msg("WARNING", "apply_policy: AMI: " + ami["Name"] + ", " + ami[
                        "ImageId"] + " is used by instances, so unable to delete")
                    for reservation in ret:
                        for instance in reservation["Instances"]:
                            print_msg("NOTICE", "apply_policy: AMI " + ami["Name"] + ", " + ami[
                                "ImageId"] + " used by InstanceId: " +
                                      instance["InstanceId"] + " in State: " + instance["State"]["Name"])
                else:
                    print_msg("INFO", "apply_policy: Delete the AMI: " + ami["Name"] +", " + ami[
                        "ImageId"] + " which meets our policy and is not used by any instance")
                    delete_ami(ami["ImageId"])
        # ami does not meet time threshold but has version more than NUMBER_AMI_KEEP
        elif ami["Count"] >= NUMBER_AMI_KEEP:
            print_msg("NOTICE", "apply_policy: the AMI: " + ami["Name"] + ", " + ami[
                "ImageId"] + " does not meet time threshold but has count of " + str(
                ami["Count"]) + " versions which is  more than or equal to NUMBER_AMI_KEEP " + str(NUMBER_AMI_KEEP))
    return


def return_tag_value(image,tagkey):
    if "Tags" in image:
        for tag in image["Tags"]:
            if tagkey == tag["Key"].lower():
               return tag["Value"]
    else: 
        return None


def check(event):
    oldest_ami_list = []
    match_found = 0

    try:
        # list aminame, id  and date time
        print_msg("INFO", "check event")
        response = EC2.describe_images(Owners=['self', ], )
        # print response["Images"][0]["Tags"]
        for image in response["Images"]:
            # convert miltary timezone to UTC
            utc_CreationDate = dateutil.parser.parse(image["CreationDate"])
            # remove timezone from CreationDate
            utc_CreationDate = utc_CreationDate.replace(tzinfo=None)
            # print "Image Name: " +  image["Name"] + ", Image Id: " +  image["ImageId"]  + ", Image State: "+ image["State"] + ", Image CreationDate: " + str(utc_CreationDate)
            image_tagname = return_tag_value(image, "name")
            image_tagversion =  return_tag_value(image, "version")
            if image_tagname == None:
               print_msg("NOTICE", "check: AMI: "+  image["Name"] + ", " + image["ImageId"] + " does not have Name tag so we will not process this ami")
               continue
            match_found = 0  # reset
            for ami in oldest_ami_list:
                # if image found in list:
                if ami["Name"] == image_tagname:
                    # print "match found: " + image_tagname
                    match_found = 1
                    # increase count
                    ami["Count"] = ami["Count"] + 1
                    # if image is older than ami-id in list then update ami-id and creation date
                    if ami["CreationDate"] > utc_CreationDate:
                        ami["CreationDate"] = utc_CreationDate
                        ami["ImageId"] = image["ImageId"]
                        ami["Version"] = image_tagversion

            if match_found == 0:
                # print "match not found: "+ image_tagname
                # add image id, creation date and set count to 1.
                new_image = {"Name": image_tagname, "ImageId": image["ImageId"], "CreationDate": utc_CreationDate,
                             "Count": 1, "Version": image_tagversion, "AMIExpired": []}
                oldest_ami_list.append(new_image)

            # add all the images which are older than TIME_THRESHOLD and set it to 1 if in use or 0 if not in use.
            if utc_CreationDate < TIME_THRESHOLD:
                for ami in oldest_ami_list:
                    if ami["Name"] == image_tagname:
                        ret = ami_in_use(image["ImageId"])
                        if ret:
                            ami["AMIExpired"].append({"ImageId": image["ImageId"], "InUse": 1})
                        else:
                            ami["AMIExpired"].append({"ImageId": image["ImageId"], "InUse": 0})

        apply_policy(oldest_ami_list)
        print_expire_ami(oldest_ami_list)
        return "Purge script executed sucessfully!"

    except EC2.exceptions.ClientError as e:
        return str(e)


def lambda_handler(event, context):
    global INFRA_ENV
    #Get env name from function name
    INFRA_ENV = context.function_name.split("-",1)[0]
    message = check(event)

    return {
        'message': message
    }


# This is only used for local testing
if __name__ == "__main__":
    event = {}
    context = []
    lambda_handler(event, context)
