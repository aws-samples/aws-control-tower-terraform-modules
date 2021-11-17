// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Creates a single health system vpc

variable "region" {
  type = string
}

variable "cidr_block" {
  type = list(object({
    test-dev-prod_vpc = string
    app_subnet_1      = string
    app_subnet_2      = string
    app_subnet_3      = string
    db_subnet_1       = string
    db_subnet_2       = string
    db_subnet_3       = string
  }))
}

variable "az" {
  type = list(object({
    az1 = string
    az2 = string
    az3 = string
  }))
}

variable "transit_gateway_id" {
  type = string
}

# This default tag can be applied to any resource or new tag variables can be created

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default = {
    environment = "production"
    ou          = "Shared Services"
    region      = "us-east-1"
    owner       = "COMPANY"
  confidentiality = "restricted" }
}

resource "aws_vpc" "Test-Dev-Prod" {
  cidr_block       = var.cidr_block.0.test-dev-prod_vpc
  instance_tenancy = "default"
  tags = merge({
    Name = "test-dev-prod_vpc"
    flowlog = "all" },
  var.tags)
}

# Creating app subnet security groups

resource "aws_security_group" "app_subnet_security_group" {
  vpc_id      = aws_vpc.test-dev-prod_vpc.id
  description = "Security group for app subnets in a VPC"
  tags = merge({
    Name = "app_subnet_security_group"},
  var.tags)
}

# Creating db subnet security groups

resource "aws_security_group" "db_subnet_security_group" {
  vpc_id      = aws_vpc.test-dev-prod_vpc.id
  description = "Security group for db subnets in a VPC"
  tags = merge({
    Name = "db_subnet_security_group"},
  var.tags)
}

# Get all subnets created in test-dev-prod vpc

data "aws_security_group" "app_subnet_security_group" {
  id = aws_security_group.app_subnet_security_group.id
}

data "aws_security_group" "db_subnet_security_group" {
  id = aws_security_group.db_subnet_security_group.id
}

# Creating app subnets

resource "aws_subnet" "app_subnet_1" {
  vpc_id            = data.aws_security_group.app_subnet_security_group.vpc_id
  cidr_block        = var.cidr_block.0.app_subnet_1
  availability_zone = var.az.0.az1
  tags = merge({
    Name = "app_subnet_1"},
  var.tags)
  depends_on = [
    aws_vpc.health-system
  ]
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id            = data.aws_security_group.app_subnet_security_group.vpc_id
  cidr_block        = var.cidr_block.0.app_subnet_2
  availability_zone = var.az.0.az2
  tags = merge({
    Name = "app_subnet_2"},
  var.tags)
  depends_on = [
    aws_vpc.health-system
  ]
}

resource "aws_subnet" "app_subnet_3" {
  vpc_id            = data.aws_security_group.app_subnet_security_group.vpc_id
  cidr_block        = var.cidr_block.0.app_subnet_3
  availability_zone = var.az.0.az3
  tags = merge({
    Name = "app_subnet_3"},
  var.tags)
  depends_on = [
    aws_vpc.health-system
  ]
}

# Creating db subnets

resource "aws_subnet" "db_subnet_1" {
  vpc_id            = aws_vpc.health-system.id
  cidr_block        = var.cidr_block.0.db_subnet_1
  availability_zone = var.az.0.az1
  tags = merge({
    Name = "db_subnet_1"},
  var.tags)
  depends_on = [
    aws_vpc.health-system
  ]
}

resource "aws_subnet" "db_subnet_2" {
  vpc_id            = aws_vpc.health-system.id
  cidr_block        = var.cidr_block.0.db_subnet_2
  availability_zone = var.az.0.az2
  tags = merge({
    Name = "db_subnet_2"},
  var.tags)
  depends_on = [
    aws_vpc.health-system
  ]
}

resource "aws_subnet" "db_subnet_3" {
  vpc_id            = aws_vpc.health-system.id
  cidr_block        = var.cidr_block.0.db_subnet_3
  availability_zone = var.az.0.az3
  tags = merge({
    Name = "db_subnet_3"},
  var.tags)
  depends_on = [
    aws_vpc.health-system
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_VPC_attachment" {
  subnet_ids = [
    aws_subnet.app_subnet_1.id,
    aws_subnet.app_subnet_2.id,
    aws_subnet.app_subnet_3.id
  ]
  transit_gateway_id                              = var.transit_gateway_id
  vpc_id                                          = aws_vpc.health-system.id
  transit_gateway_default_route_table_association = false
  tags = merge({
    Name = "TGW_VPC_attachment"},
  var.tags)
  lifecycle {
    ignore_changes = [
      transit_gateway_default_route_table_association
    ]
  }
}

resource "aws_route_table" "AppSubnetRT" {
  vpc_id = aws_vpc.health-system.id
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }
  tags = merge({
    Name = "OutboundVPC_Public_RT"},
  var.tags)
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.TGW_VPC_attachment
  ]
}

resource "aws_route_table" "DBSubnetRT" {
  vpc_id = aws_vpc.health-system.id
  tags = merge({
    Name = "OutboundVPC_Private_RT_AZ1"},
  var.tags)
}

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
