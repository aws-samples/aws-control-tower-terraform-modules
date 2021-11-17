// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Backend configuration to save the state file to the bucket and key defined below.
# The account number is that of the master account.

terraform {
  required_version = "=0.15.3"
  backend "s3" {
    region         = "us-east-1"
    bucket         = "terraform-state-012345678910"
    key            = "tf-iac/sandbox/terraform/state"
    dynamodb_table = "terraform-state-012345678910"
    encrypt        = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  assume_role {
    # Automation Role in Shared Services/Network account
    #role_arn     = var.workspace_iam_roles[terraform.workspace]
    role_arn = var.automation_role
    external_id = "terraform"
    session_name = "terraform"
  }
}

provider "aws" {
    alias = "member"
    region = var.region
    assume_role {
    # Automation Role in Shared Services/Network account
    #role_arn     = var.workspace_iam_roles[terraform.workspace]
    role_arn = var.automation_role
    external_id = "terraform"
    session_name = "terraform"
  }
}

# Retrieves the transit gateway id shared to the state file during the last terraform apply of the Network Account

# data "terraform_remote_state" "SharedNetwork_TGW" {
#   backend = "s3"
#   config = {
#     region = "us-east-1"
#     bucket = "terraform-state-012345678910"
#     key    = "tf-iac/network/terraform/state"
#   }
# }

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default = {
    environment = "production"
    ou          = "sandbox"
    region      = "us-east-1"
    owner       = "COMPANY"
  confidentiality = "restricted" }
}

################################################################################
# Enables Security Hub
################################################################################
resource "aws_securityhub_account" "shaccepter" {
  provider = aws.member
}

################################################################################
# Security Hub Invite accepter
################################################################################

resource "aws_securityhub_invite_accepter" "shaccepter" {
  provider   = aws.member
  depends_on = [aws_securityhub_account.shaccepter]
  master_id  = var.master_account_id
}

################################################################################
# Enables GuardDuty
################################################################################
resource "aws_guardduty_detector" "gdaccepter" {
  provider                     = aws.member
  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency
}


################################################################################
# Guard Duty Invite accepter
################################################################################

resource "aws_guardduty_invite_accepter" "gdaccepter" {
  provider          = aws.member
  detector_id       = aws_guardduty_detector.gdaccepter.id
  master_account_id = var.master_account_id
}

module "config" {
  source = "../../modules/config"
}

# Creates a VPC

resource "aws_vpc" "sandbox-vpc" {
  cidr_block       = var.cidr_block.0.sandbox-vpc
  instance_tenancy = "default"
  tags = merge({
    Name = "sandbox-vpc"
    flowlog = "all" },
  var.tags)
}

# Creates app subnet security groups

resource "aws_security_group" "app_subnet_security_group" {
  vpc_id      = aws_vpc.sandbox-vpc.id
  description = "Security group for app subnets in a VPC"
  tags = merge({
    Name = "app_subnet_security_group" },
  var.tags)
}

# Creates db subnet security groups

resource "aws_security_group" "db_subnet_security_group" {
  vpc_id      = aws_vpc.sandbox-vpc.id
  description = "Security group for db subnets in a VPC"
  tags = merge({
    Name = "db_subnet_security_group" },
  var.tags)
}

# Get all subnets created in sandbox vpc

data "aws_security_group" "app_subnet_security_group" {
  id = aws_security_group.app_subnet_security_group.id
}

data "aws_security_group" "db_subnet_security_group" {
  id = aws_security_group.db_subnet_security_group.id
}

# Creates app subnets

resource "aws_subnet" "app_subnet_1" {
  vpc_id            = aws_vpc.sandbox-vpc.id
  cidr_block        = var.cidr_block.0.app_subnet_1
  availability_zone = var.az.0.az1
  tags = merge({
    Name = "app_subnet_1" },
  var.tags)
  depends_on = [
    aws_vpc.sandbox-vpc
  ]
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id            = aws_vpc.sandbox-vpc.id
  cidr_block        = var.cidr_block.0.app_subnet_2
  availability_zone = var.az.0.az2
  tags = merge({
    Name = "app_subnet_2" },
  var.tags)
  depends_on = [
    aws_vpc.sandbox-vpc
  ]
}

resource "aws_subnet" "app_subnet_3" {
  vpc_id            = aws_vpc.sandbox-vpc.id
  cidr_block        = var.cidr_block.0.app_subnet_3
  availability_zone = var.az.0.az3
  tags = merge({
    Name = "app_subnet_3" },
  var.tags)
  depends_on = [
    aws_vpc.sandbox-vpc
  ]
}

# Creates db subnets

resource "aws_subnet" "db_subnet_1" {
  vpc_id            = aws_vpc.sandbox-vpc.id
  cidr_block        = var.cidr_block.0.db_subnet_1
  availability_zone = var.az.0.az1
  tags = merge({
    Name = "db_subnet_1" },
  var.tags)
  depends_on = [
    aws_vpc.sandbox-vpc
  ]
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = aws_vpc.sandbox-vpc.id
  cidr_block        = var.cidr_block.0.db_subnet_2
  availability_zone = var.az.0.az2
  tags = merge({
    Name = "db_subnet_2" },
  var.tags)
  depends_on = [
    aws_vpc.sandbox-vpc
  ]
}

resource "aws_subnet" "db_subnet_3" {
  vpc_id     = aws_vpc.sandbox-vpc.id
  cidr_block = var.cidr_block.0.db_subnet_3

  availability_zone = var.az.0.az3
  tags = merge({
    Name = "db_subnet_3" },
  var.tags)
  depends_on = [
    aws_vpc.sandbox-vpc
  ]
}

# Creates a Transit Gateway Attachment to the VPC

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_VPC_attachment" {
  subnet_ids = [
    aws_subnet.app_subnet_1.id,
    aws_subnet.app_subnet_2.id,
    aws_subnet.app_subnet_3.id
  ]
  transit_gateway_id = "tgw-xxxxxxxxxxxxxxxxx"
  #transit_gateway_id                              = data.terraform_remote_state.SharedNetwork_TGW.outputs.transit_gateway_id
  vpc_id                                          = aws_vpc.sandbox-vpc.id
  transit_gateway_default_route_table_association = false
  tags = merge({
    Name = "TGW_VPC_attachment" },
  var.tags)
  lifecycle {
  ignore_changes = [
   transit_gateway_default_route_table_association
 ]
 }
}

# Creates a route table for the App Subnets

resource "aws_route_table" "AppSubnetRT" {
  vpc_id = aws_vpc.sandbox-vpc.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = "tgw-xxxxxxxxxxxxxxxxx"
    #transit_gateway_id = data.terraform_remote_state.SharedNetwork_TGW.outputs.transit_gateway_id
  }
  tags = merge({
    Name = "OutboundVPC_Public_RT" },
  var.tags)
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.TGW_VPC_attachment
  ]
}

# Creates a route table for the DB Subnets

resource "aws_route_table" "DBSubnetRT" {
  vpc_id = aws_vpc.sandbox-vpc.id
  tags = merge({
    Name = "OutboundVPC_Private_RT_AZ1" },
  var.tags)
}

# Associates all App and DB Subnets to their respective route table

resource "aws_route_table_association" "AppSubnet1_RTAssociation" {
  subnet_id      = aws_subnet.app_subnet_1.id
  route_table_id = aws_route_table.AppSubnetRT.id
}

resource "aws_route_table_association" "AppSubnet2_RTAssociation" {
  subnet_id      = aws_subnet.app_subnet_2.id
  route_table_id = aws_route_table.AppSubnetRT.id
}

resource "aws_route_table_association" "AppSubnet3_RTAssociation" {
  subnet_id      = aws_subnet.app_subnet_3.id
  route_table_id = aws_route_table.AppSubnetRT.id
}

resource "aws_route_table_association" "DBSubnet1_RTAssociation" {
  subnet_id      = aws_subnet.db_subnet_1.id
  route_table_id = aws_route_table.DBSubnetRT.id
}

resource "aws_route_table_association" "DBSubnet2_RTAssociation" {
  subnet_id      = aws_subnet.db_subnet_2.id
  route_table_id = aws_route_table.DBSubnetRT.id
}

resource "aws_route_table_association" "DBSubnet3_RTAssociation" {
  subnet_id      = aws_subnet.db_subnet_3.id
  route_table_id = aws_route_table.DBSubnetRT.id
}
