locals {
  shield_drt_buckets="${local.environment == "prod" ? "logging-nwmprod-waf-eu-west-1,logging-nwmprod-waf-eu-west-2,logging-nwmssprod-waf-eu-west-1,logging-nwmssprod-waf-eu-west-2,logging-nwmnonprod-waf-eu-west-1,logging-nwmnonprod-waf-eu-west-2" : "logging-nwmtest-waf-eu-west-1,logging-nwmtest-waf-eu-west-2,logging-nwmsstest-waf-eu-west-1,logging-nwmsstest-waf-eu-west-2"}"
}

