# Create an Identity Provider and upload the Metadata file
resource "aws_iam_saml_provider" "saml_provider" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  # IDP name is hardcoded on ADFS side
  name                   = "idp1"
  saml_metadata_document = "${file("./SAML2019.xml")}"
}

# Create a custom policy, DES-PowerUsers-Policy
resource "aws_iam_policy" "des-powerusers-policy" {
  count = "${local.region == "eu-west-2" ? 1 : 0}"
  name        = "DES-PowerUsers-Policy"
  description = "Policy for PowerUsers role"
  policy = "${data.aws_iam_policy_document.des-powerusers-policy.json}"
}

# Create the Administrator Roles
resource "aws_iam_role" "adfs-administrator" {
  count = "${local.region == "eu-west-2" ? length(local.administrator_roles) : 0}"
  name        = "${element(local.administrator_roles, count.index)}"
  description = "Full Administrative Access"
  assume_role_policy = "${data.aws_iam_policy_document.assume-role-with-saml.json}"
  tags = "${merge(local.default_tags, map(
    "Name", "${element(local.administrator_roles, count.index)}"
  ))}"
}

# Attach the permitted AWS policy to Administrator Roles
resource "aws_iam_role_policy_attachment" "adfs-administrator-policy" {
  count = "${local.region == "eu-west-2" ? length(local.aws_managed_policy_for_admin) * length(local.administrator_roles) : 0}"
  policy_arn = "arn:aws:iam::aws:policy/${element(local.aws_managed_policy_for_admin, count.index / length(local.administrator_roles))}"
  role       = "${element(aws_iam_role.adfs-administrator.*.name, count.index % length(local.administrator_roles))}"
}

# Create the ReadOnly Roles
resource "aws_iam_role" "adfs-readonly" {
  count = "${local.region == "eu-west-2" ? length(local.readonly_roles) : 0}"
  name        = "${element(local.readonly_roles, count.index)}"
  description = "Read Only Access"
  assume_role_policy = "${data.aws_iam_policy_document.assume-role-with-saml.json}"
  max_session_duration = 43200 
  tags = "${merge(local.default_tags, map(
    "Name", "${element(local.readonly_roles, count.index)}"
  ))}"
}

# Attach the permitted AWS policy to ReadOnly Roles
resource "aws_iam_role_policy_attachment" "adfs-readonly-policy" {
  count = "${local.region == "eu-west-2" ? length(local.aws_managed_policy_for_readonly) * length(local.readonly_roles) : 0}"
  policy_arn = "arn:aws:iam::aws:policy/${element(local.aws_managed_policy_for_readonly, count.index / length(local.readonly_roles))}"
  role       = "${element(aws_iam_role.adfs-readonly.*.name, count.index % length(local.readonly_roles))}"
}

# Create the PowerUsers Roles
resource "aws_iam_role" "adfs-powerusers" {
  count = "${local.region == "eu-west-2" ? length(local.powerusers_roles) : 0}"
  name        = "${element(local.powerusers_roles, count.index)}"
  description = "Power User access for making changes"
  assume_role_policy = "${data.aws_iam_policy_document.assume-role-with-saml.json}"
  # set maximum session to 1 hour for PROD and 12 hours for other environments
  max_session_duration = "${local.environment == "prod" ? 3600 : 43200}"
  tags = "${merge(local.default_tags, map(
    "Name", "${element(local.powerusers_roles, count.index)}"
  ))}"
}

# Attach the permitted AWS policy to PowerUsers Roles
resource "aws_iam_role_policy_attachment" "adfs-powerusers-policy" {
  count = "${local.region == "eu-west-2" ? length(local.aws_managed_policy_for_powerusers) * length(local.powerusers_roles) : 0}"
  policy_arn = "arn:aws:iam::aws:policy/${element(local.aws_managed_policy_for_powerusers, count.index / length(local.powerusers_roles))}"
  role       = "${element(aws_iam_role.adfs-powerusers.*.name, count.index % length(local.powerusers_roles))}"
}

# Attach the permitted AWS policy to PowerUsers Roles in DEV
# NOTE: this will be changed to == "lab" to lock down "nonprod" before go-live
resource "aws_iam_role_policy_attachment" "adfs-powerusers-policy-dev" {
  count = "${local.region == "eu-west-2" && local.environment != "prod" ? length(local.aws_managed_policy_for_powerusers_dev) * length(local.powerusers_roles) : 0}"
  policy_arn = "arn:aws:iam::aws:policy/${element(local.aws_managed_policy_for_powerusers_dev, count.index / length(local.powerusers_roles))}"
  role       = "${element(aws_iam_role.adfs-powerusers.*.name, count.index % length(local.powerusers_roles))}"
}


# Attach the custom policy to PowerUsers Role.
resource "aws_iam_role_policy_attachment" "adfs-powerusers-custom-policy" {
  count = "${local.region == "eu-west-2" ? length(local.powerusers_roles) : 0}"
  policy_arn = "${aws_iam_policy.des-powerusers-policy.arn}"
  role       = "${element(aws_iam_role.adfs-powerusers.*.name, count.index)}"
}

