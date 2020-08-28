# TOKEN needs to have write permission to checkin vars into consul
```
export CONSUL_HTTP_TOKEN=XXXXXXX
```

# Check difference between local data file vs Consul data
```
./checkin.py prod_shared-services_variables_common.json  # by default it will only produce diff 
# Note, filename is used to determine consul path
```

# Checkin the changes to consul with import flag
```
./checkin.py prod_shared-services_variables_common.json  import
```

# Delete keys from consul which does not exists in git var file 
```
./checkin.py prod_shared-services_variables_common.json delete 
```

# Troubleshoot in case we find any odd in later stage
  to verify data matches (after decrypt and encrypt)
```
grep "value\|key" nonprod-core-variables-eu-west-1-20180815155031.json  > 1.txt
grep "value\|key" outputencrypt.json  > 2.txt
diff -w nonprod-core-variables-eu-west-1-20180815155031.json  outputencrypt.json
```

# Usually, we dont need to do below, speak to someone before you perform checkout.py
# We only do this very first time when we dont have vars file for that envionment. 
# Pull data from consul for a given Path, Convert base64 value to Normal string. 
```
./checkout.py nonprod/shared-services/variables/common
will create nonprod_shared-services_variables_common.json

# Valid path example:

nonprod/shared-services/variables/common
nonprod/shared-services/variables/eu-west-1
nonprod/shared-services/variables/eu-west-2
nonprod/core/variables/common
nonprod/core/variables/eu-west-1
nonprod/core/variables/eu-west-2
```

