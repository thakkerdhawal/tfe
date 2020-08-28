#!/usr/bin/env python

import json
import base64
import sys
import re
import os
import subprocess
import time
import filecmp
import pprint
import platform
import requests


class tcolors:
  NOTICE = '\033[95m'
  INFO = '\t\033[92m'
  WARNING = '\t\033[93m'
  ERROR = '\t\033[91m'
  ENDC = '\033[0m'

def print_msg (type,msg):
  print getattr(tcolors,type).expandtabs(4) + type + ": " + msg.expandtabs(4) + tcolors.ENDC
 
def help():
    print_msg("INFO"," Examples to run checkin.py script\n\
		Diff data between consul and var file: ./checkin.py cicd_variables_core_common.json\n\
		Import to consul: ./checkin.py cicd_variables_core_common.json import\n\
		Delete keys from consul that does not exists in git var file: ./checkin.py cicd_variables_core_common.json delete")
 
def validate_token():
    try:
        r = requests.get('https://ecomm.fm.rbsgrp.net:443/v1/acl/info/' + os.environ["CONSUL_HTTP_TOKEN"])
    except requests.exceptions.RequestException as e:
        print_msg("ERROR","unable to get the token's ACL. Please check your environment variable CONSUL_HTTP_TOKEN")
        print e
        sys.exit(1)
    target_path = "application/nwm/" + os.path.basename(os.path.splitext(inputfile)[0]).replace('_', '/')
    try:
        target_acl_path =  re.search("(.*\/variables\/\w+(?:-\w+\/))|(.*\/variables\/\w*\/)", target_path).group(0)  # look for  shared-services or core
    except AttributeError:
        print_msg("ERROR", "unable to parse ACL path from the input file. Please varify the filename.")
        sys.exit(1)
    try:
        re.search(("key " + "\"" + target_acl_path + "\"" + " { policy = \"write\" }"), r.json()[0]["Rules"]).group(0)
    except AttributeError:
        print_msg("ERROR", "unable to find a matching ACL. Please check your environment variable CONSUL_HTTP_TOKEN")
        sys.exit(1)


def encode(inputfile):
    f = open(inputfile, "r")
    codedlist = []
    data = json.load(f)
    for kv in data:
        for item in kv:
            if item == "value":
                # print("%s: %s " % (item, p[item]))
                kv[item] = base64.b64encode(kv[item].encode('utf-8'))
                # print p[item]
                codedlist.append(kv)

    return json.dumps(codedlist, indent=8, separators=(',', ': '), sort_keys=True)


def pulldata(consulpath):
    token = os.environ["CONSUL_HTTP_TOKEN"]
    #bashcmd = "/usr/local/bin/consul kv export -http-addr=https://ecomm.fm.rbsgrp.net:443 -token=" + token + " application/nwm/terraform/" + consulpath
    bashcmd = "/usr/local/bin/consul kv export -http-addr=https://ecomm.fm.rbsgrp.net:443 -token=" + token + " application/nwm/" + consulpath
    output = subprocess.check_output(['bash', '-c', bashcmd])
    return output

def deletekey(key):
    output = []
    token = os.environ["CONSUL_HTTP_TOKEN"]
    bashcmd = "/usr/local/bin/consul kv delete -http-addr=https://ecomm.fm.rbsgrp.net:443 -token=" + token + " " + key
    output = subprocess.check_output(['bash', '-c', bashcmd])
    return output

def importdata(importfile):
    output = []
    token = os.environ["CONSUL_HTTP_TOKEN"]
    bashcmd = "echo '" + importfile + "' | /usr/local/bin/consul kv import -http-addr=https://ecomm.fm.rbsgrp.net:443 -token=" + token + " -"
    output = subprocess.check_output(['bash', '-c', bashcmd])
    return output


def b64decode(value):
    return base64.b64decode(value.encode('utf-8'))


def check_match(itemlist, key):
    for i in xrange(len(itemlist)):
        if itemlist[i]['key'] == key:
            return itemlist[i]

    return False


def diff_data(gitver, consulver, flag_delete=False):
    gitver = json.loads(gitver)
    consulver = json.loads(consulver)

    new_items = []
    del_items = []
    ret = 0
    # Parse items in encode for update and new items
    for i in xrange(len(gitver)):
        # check if the key exists in consul
        ret_pull_item = check_match(consulver, gitver[i]['key'])
        if ret_pull_item:  # key exists, check if there is any change in value
            if gitver[i]['value'] != ret_pull_item['value']:
                if ret == 0: print_msg("NOTICE", "Items to be updated:\n")
                print_msg("INFO", "Key %s \n\t\t from: %s \n\t\t to: %s" % (ret_pull_item['key'], b64decode(ret_pull_item['value']), b64decode(gitver[i]['value'])))
                ret = 1
        else:  # key didnt exist in consul, add it as new item
            new_items.append(gitver[i])

    # Parse items in Pull for delete items
    for i in xrange(len(consulver)):
        # check if the key exists in encode
        ret_encode_item = check_match(gitver, consulver[i]['key'])
        if not ret_encode_item:
            del_items.append(consulver[i])

    if new_items:
        print ""
        print_msg("NOTICE", "New items to be created: " + str(len(new_items)) + "\n")
        for item in new_items:
            print_msg("INFO","Key %s = %s" % (item['key'], b64decode(item['value'])))

    if del_items:
        print ""
        print_msg("NOTICE", "Items to be deleted : " + str(len(del_items)) + "\n")
        for item in del_items:
            if flag_delete:
               deletekey(item['key'])
            print_msg("INFO", "Key %s = %s" % (item['key'], b64decode(item['value'])))

    if not new_items and not del_items and ret == 0:
        print ""
        print_msg("NOTICE", "Encoded version and pull version are same\n")
    
    return ret


def print_dic(dic):
    for item in dic:
            print_msg("INFO", "Key "+ item['key'] + " = " + (item['value']))

#returns keys that are missing in dic2 but are present in dic1
def sub_dic(dic1, dic2):
    notfound_items = []
    for i in xrange(len(dic1)):
        # check if the key exists in consul
        #key = srcj[i]['key'].replace(file_env, env)
        ret_pull_item = check_match(dic2, dic1[i]['key'])
        if not ret_pull_item:
            notfound_items.append(dic1[i])

    return notfound_items

def diff_keys(inputfile):
    file_name = os.path.basename(inputfile)
    file_path = os.path.dirname(inputfile)
    file_env = file_name.split('_')[0]
    postfix_filename = "_".join(file_name.split('_')[1:])

    expected_envs = ['cicd','lab', 'nonprod', 'prod']
    ret = 1
    itema = []
    itemb = []
    parsed_envs = []
    verifywith_envs = list(set(expected_envs) - set(file_env.split(',')))

    print ""
    print_msg("NOTICE", "Checking for consistency:\n")
    for env in verifywith_envs:
        path_filename = os.path.join(file_path, env + "_" + postfix_filename)
        if os.path.isfile(path_filename):
            parsed_envs.append(env)
            dest = open(path_filename, "r")
            src = open(inputfile, "r")
            destj = json.load(dest)
            srcj = json.load(src)

            #substract src - dest
            srcpathupdatej = json.loads(json.dumps(srcj).replace(file_env,env))
            itema = sub_dic(srcpathupdatej, destj)
            if itema:
              print_msg("WARNING", "Keys not found in environment "+env+" but found in "+file_env+" : " + str(len(itema)))
              print_dic(itema)
            #substract dest - src
            destpathupdatej = json.loads(json.dumps(destj).replace(env,file_env))
            itemb = sub_dic(destpathupdatej,srcj)
            if itemb:
              print_msg("WARNING", "Keys not found in environment "+file_env+" but found in "+env+": " + str(len(itemb)))
              print_dic(itemb)
            if len(itema) == 0 and len(itemb) == 0:
              ret = 0
              print_msg("INFO", "No differences in Keys found for the environment(s) " + env)
        else:
            print_msg("WARNING", "Env " + env + " file does not exists - " + path_filename)
    print_msg("INFO", "Environment(s) checked - " + str(parsed_envs))
    print ""
    return ret


def diff_consulpath(inputfile, consulpath):
    print_msg("NOTICE", "Checking consul path :\n")
    f = open(inputfile, "r")
    codedlist = []
    data = json.load(f)
    ret = 0
    for kv in data:
        for attribute, value in kv.iteritems():
            if attribute == "key":
                if consulpath not in value:
                    print_msg("ERROR", "Consul path does not match for key: " + value)
                    ret = 1
    if ret == 0:
        print_msg("INFO", "No differences in Consul path \n")

    return ret

def parseinput():
    token = ""

    if platform.python_version() < "2.7.5":
        print platform.python_version()
        print_msg("ERROR", "atleast need python 2.7.5 version")
        sys.exit(0)

    if len(sys.argv) <= 1:
        # print "ERROR: atleast one argument is required "
        print_msg("ERROR", "atleast one argument is required")
        help()
        sys.exit(0)

    if "CONSUL_HTTP_TOKEN" in os.environ:
        token = os.environ["CONSUL_HTTP_TOKEN"]

    if not token:
        print_msg("ERROR", "CONSUL_HTTP_TOKEN environment variable not set")
        sys.exit(0)

    if not sys.argv[1]:  # file to encode
        print_msg("ERROR", "filename to encode is not set")
        sys.exit(0)


if __name__ == "__main__":

    parseinput()
    inputfile = sys.argv[1]
    encodegitver = encode(inputfile)
    file_name = os.path.splitext(inputfile)[0]
    consulpath = os.path.basename(file_name).replace('_', '/')

    validate_token()

    if len(sys.argv) >= 3:
        flag = sys.argv[2]
        if flag == "import":
            ret = importdata(encodegitver)
            if not ret:
                print_msg("ERROR", "import failed\n" + str(ret))
                sys.exit(1)
            else:
                print_msg("INFO", "import success\n" + str(ret))
                sys.exit(0)
        elif flag == "delete":
            encodeconsulver = pulldata(consulpath)
            ret = diff_data(encodegitver, encodeconsulver, flag_delete=True)
            sys.exit(0)

        print_msg("ERROR", "unknown input argument")
        sys.exit(1)

    encodeconsulver = pulldata(consulpath)

    retdata = diff_data(encodegitver, encodeconsulver)
    retkey = diff_keys(inputfile)
    retconsulpath = diff_consulpath(inputfile, consulpath)
    if not retdata and not retkey and not retconsulpath:
        print_msg("NOTICE", "Run with import flag to execute changes: ./checkin.py " + inputfile + " import")
