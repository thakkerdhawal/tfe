# Overview

This is Terraform templates for setting up Route53 Glue Zones for an AWS account

# Dependency on other Terraform workspaces

N/A

# Note

1. Since Route53 resources are account wide, this is not region specific and should only have one workspace per **AWS account**. While technically this can be executed against any region, we have chosen eu-west-2 to be the region that holds the state file, and it is hardcoded in the templates.  
2. Returns the Delegated Name Servers that should be used as the NS records when delegating from the Parent DNS Zone. See this following confluence page for further info: https://confluence.dts.fm.rbsgrp.net/display/ECMINFPR/AE+-+Products+-+AWS+-+NatWestMarkets+-+Terraform+-+Prerequisites#AE-Products-AWS-NatWestMarkets-Terraform-Prerequisites-R53Domain(Mitchell,Warwick(Digital&EngineeringServices))

