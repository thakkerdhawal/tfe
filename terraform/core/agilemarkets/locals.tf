locals  {
  # overwrites default tag values or add new tag  
  #for application specific resources
  agilemarkets_tags = {
     "Owner"          = "Lee Rushforth" 
     "Business Unit"  = "Global CFT Currencies Client Sales Technology"
  }

  bondsyndicate_tags = {
     "Owner"          = "Andrew Higgins"
     "Business Unit"  = "Fixed Income Technology"
  }

  currencypay_tags = {
     "Owner"          = "Ben McConnell"
     "Business Unit"  = "Global CFT Currencies Client Sales Technology"
  }

  fxmp_tags = {
     "Owner"          = "Ben McConnell"
     "Business Unit"  = "Global CFT Currencies Client Sales Technology"
  }

  #for shared resources 
  apigw_tags = { 
     "Owner"          = "Lee Rushforth, Andrew Higgins, Ben McConnell" 
     "Business Unit"  = "Global CFT Currencies Client Sales Technology, Fixed Income Technology"
  }

  apache_tags = { 
     "Owner"          = "Lee Rushforth, Andrew Higgins" 
     "Business Unit"  = "Global CFT Currencies Client Sales Technology, Fixed Income Technology"
  }
  
}
