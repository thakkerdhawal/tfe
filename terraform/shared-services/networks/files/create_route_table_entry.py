#!/usr/bin/env python3

import boto3
import os
import json 

EC2 = boto3.client('ec2')

def check(event):

    try:
        #Using peering ID get vpc ID and its environment tag. 
        peering_info = EC2.describe_vpc_peering_connections(VpcPeeringConnectionIds=[event['peering_Id']])
        if peering_info:
             vpcId = peering_info["VpcPeeringConnections"][0]["RequesterVpcInfo"]["VpcId"]
             #vpcId = peering_info["VpcPeeringConnections"][0]["AccepterVpcInfo"]["VpcId"]
        vpc_info = EC2.describe_vpcs(VpcIds=[vpcId])
        #print("vpc_info" + json.dumps(vpc_info))
        for item in vpc_info["Vpcs"][0]["Tags"]:
             if item["Key"].lower() == "environment": 
               vpc_env = item["Value"].lower()
     
        #Retrict routes to vpcid
        route_tables = EC2.describe_route_tables( Filters=[
         {
            'Name': 'vpc-id',
            'Values': [
                vpcId,
            ]
         },
         ], )

        #only interested in intra route table
        route_table_name= vpc_env+"-vpc-intra-"+os.environ['AWS_REGION']

        for route in route_tables['RouteTables']:
             #print("route table" + json.dumps(route))
             for tags in route['Tags']:
                 if tags["Key"] == 'Name' and tags["Value"].lower() == route_table_name.lower():
                    route_table_id = route['RouteTableId']
        
        print("Route table ID: "+route_table_id+" , for route table name: "+ route_table_name)
        response = EC2.describe_route_tables(
            DryRun=False,
            RouteTableIds=[route_table_id
            ],
        )
        routes = response['RouteTables'][0]['Routes']

        #print("routes: " + json.dumps(routes))
        if not any(d.get('DestinationCidrBlock') == event['cidr'] for d in routes):
            return create(event, route_table_id)

        if any(d.get('DestinationCidrBlock') == event['cidr'] and d['State'] == 'blackhole' for d in routes):
            return replace(event, route_table_id)
        
        if any(d.get('DestinationCidrBlock') == event['cidr'] and d['State'] != 'blackhole' for d in routes):
            return "Route exists to " + event['cidr'] + " in " + route_table_id + "but cannot be replaced as it is not in 'blackhole' state " 

        return "Nothing to do!"

    except EC2.exceptions.ClientError as e:
        return str(e)

def create(event, route_table_id):

    try:
        print("Route doesn't exist; creating")
        response = EC2.create_route(
            DestinationCidrBlock=event['cidr'],
            RouteTableId=route_table_id,
            VpcPeeringConnectionId=event['peering_Id']
        )
        return "Route created to " + event['cidr'] + " in " + route_table_id 

    # This exception should never be triggered as the check function should
    # not allow it if it already exists
    except EC2.exceptions.ClientError as e:
        if "RouteAlreadyExists" in str(e):
            if event['cidr'] in str(e):
                return 'Route already exists, exiting'
        elif "UnauthorizedOperation" in str(e):
            print(str(e))
            return "Unauthorized operation, don't have the permissions"
        else:
            return str(e)

def replace(event, route_table_id):

    try:
        print("Route is a blackhole; replacing")
        response = EC2.replace_route(
            DestinationCidrBlock=event['cidr'],
            RouteTableId=route_table_id,
            VpcPeeringConnectionId=event['peering_Id']
        )
        return "Route replace to " + event['cidr'] + " in " + route_table_id 

    except EC2.exceptions.ClientError as e:
        return str(e)

def lambda_handler(event, context):

    message = check(event)

    return {
        'message': message
        }
