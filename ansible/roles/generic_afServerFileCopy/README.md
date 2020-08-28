Role Name
=========

This role performs a generic file copy from Artifactory to 1 or more remote hosts using ansible. It consists of the following tasks:

- Create local 'files' directory (if it doesn't exist) at location "{{ playbook_dir }}/files/"
- Download single file from Artifactory to local Ansible server in the "{{ playbook_dir }}/files/" directory, so Ansible can later copy it to the target host(s)
- Copy locally downloaded file to remote host(s) in specified location
- Remove locally downloaded AF file as part of playbook cleanup

Requirements
------------

There are a number of requirements to run this role.

- A playbook which can call this role
- It is assumed that the remote user specified in the playbook will be the user that connects to the server via ssh and has permissions to utilise sudo to change file ownership permissions on the copied artifact
- The Ansible server can access Artifactory
- SSH access to the target server(s)
- Sufficient diskspace locally and on the target server to copy the artifact there
- Ensure an artifact (file) exists in Artifactory
- IF applicable, Ensure you have an account that can access the artifact
- IF applicable, Ensure you have an access Token can that access the artifact
- Have the full URL to the artifact in Artifactory
- What user will be used to copy the file onto a target server (via ssh) i.e. ec2-user
- Know the absolute destination of where the artifact should be copied onto the target server
- Know the intended filename of the artifact on the target server
- Know the Ownership of the file (user/group) on the target server
- It is assumed that the remote user specified in the playbook will be the user that connects to the server via ssh and has permissions to utilise sudo to change file ownership permissions on the copied artifact

Role Variables
--------------

This role requires a number of variables to be populated to run. Without the mandatory variables being defined the role will fail to execute.

The below list uses the following format: varName_ - _description_ -  _Sample_ _value_

#### Mandatory Vars ####

* __afUrl__ - Full URL of the artifact in artifactory - https://artifactory-1.dts.fm.rbsgrp.net/artifactory/eComm-private-releases-local/cleo/vlproxy/VLProxy.bin
* __afFile__ - By default it will prepend random and unique number to filename of the artifact - VLProxy.bin
* __destFilePath__ - full path where the file should be copied on the target host, include the filename - /opt/app/ecomm/VLProxy/VLProxy.bin
* __theUser__ - what user owns the artifact once copied to the target host - e047u
* __theGroup__ - what group owns the artifact once copied to the target host - e047u
* __theMode__ - Modal permissions of the artifact once copied to the target host - 0755

#### Optional Vars ####
* __afUser__ - IF required, Username required to access the artifact in AF - roberdf
* __afToken__ - IF required, Token required to access the artifact in AF - CE9koxQavnCVmotAfRsKb5zajr1 (this is a sample)
* __unarchive__ - For archive files (eg .tar.gz extensions). If False (Default) copies file. If True it unarchives the file to the destination

### Default Vars ###
For a few of the vars listed above, some default values have been applied in file [defaults/main.yml] (defaults/main.yml)

theMode: 0755   - default artifact copy modal permissions set to 0755
theGroup: "{{ theUser }}"   - this setting means that by default, the group owner of the artifact will match the value of the user
afFile: "{{ afUrl | basename }}" - this will use the jinja2 basename filter and will by default set the value of afFile to the last part of the AF URL var. I.e... if you had url http://thisisatest.org/filename.txt  the value of afFile would be _filename.txt_

Dependencies
------------
- Ensure the destination directory already exists on your target host prior to running this role, or it will fail to copy the file there.

Tags
------------
Each task in the role has been given a tag so that specific tasks can be selected

The below list uses the following format: _tagvalue_ - task it applies to

- __prereq__ - Create local 'files' directory in playbook location on ansible server if it doesn't exist
- __download__ - Download single artifact from Artifactory to local Ansible server in the "{{ playbook_dir }}/files/" directory
- __copy__ -  Copy artifact from "{{ playbook_dir }}/files/{{ afFile }}" to remote host
- __unarchive__ -  Copy and Unarchive artifact from "{{ playbook_dir }}/files/{{ afFile }}" to remote host
- __cleanup__ -   Remove locally downloaded AF file as part of playbook cleanup
- __afServerFileCopy__ - this will run all tasks in the role, handy for testing as part or a larger playbook


Example Playbook
----------------

Below is a simple example of a playbook that would just run this role

```
    - hosts: servers
      roles:
         - generic_afServerFileCopy
```

Below is an extension of above where you pass in the vars to the role as part of the playbook (rather than use extra vars)

```
    - hosts: servers
      roles:
         - { role: generic_afServerFileCopy, afUrl: "http://test.me/file.txt", destFilePath: "/home/ec2-user/file.txt", theUser: "ec2-user", theMode: "0755" }
```

Below is an example of including this role as a task in a playbook so it will run at a specified time in the playbook

```
    - hosts: servers
      tasks:
      - name: "Create {{ vlproxyHome }} directory for Cleo VLProxy and set expected permissions"
        become: true
        file: path="{{ vlproxyHome }}" state=directory owner="{{ theUser }}" group="{{ theUser }}" mode=0755
        tags:
        - prereq
        - dir

      - name: "Obtain VLProxy Binary from AF and copy it to target server in {{ destFilePath }}"
        include_role:
         name: generic_afServerFileCopy
        tags:
         - afServerFileCopy

```

Below is an example of passing vars into the above example as part of the playbook (rather than use extra vars)

```
    - hosts: servers
      tasks:
      - name: "Create {{ vlproxyHome }} directory for Cleo VLProxy and set expected permissions"
        become: true
        file: path="{{ vlproxyHome }}" state=directory owner="{{ theUser }}" group="{{ theUser }}" mode=0755
        tags:
        - prereq
        - dir

      - name: "Obtain VLProxy Binary from AF and copy it to target server in {{ destFilePath }}"
        include_role:
         name: generic_afServerFileCopy
        vars:
         afUrl: "http://test.me/file.txt"
         destFilePath: /home/ec2-user/file.txt
         theUser: ec2-user
         theMode: 0644
        tags:
         - afServerFileCopy

```

Below is an example of passing in the vars as extra vars as part of a playbook run - note: sensitive vars should always be passed in this way.

```
ansible-playbook playbook/<component>/<playbookName.yml> -e "afUser=roberdf afToken=be8888 afFile=file.txt destFilePath=/home/ec2-user/file.txt theUser=ec2-user theMode=0644"
```


Author Information
------------------

David Roberts - david.roberts@natwestmarkets.com
