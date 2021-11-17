// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "outbound_vpc_cidr" {}
variable "EgressPublicAZ1_cidr" {}
variable "EgressPublicAZ2_cidr" {}
variable "EgressPrivateAZ1_cidr" {}
variable "EgressPrivateAZ2_cidr" {}
variable "tags" {}
variable "Prod1_TGW_RT" {
  description = "TGW Attachment ID of Test VPC, enter N/A if you are running this script for the first time"
  type        = string
}

variable "Prod2_TGW_RT" {
  description = "TGW Attachment ID of Dev VPC, enter N/A if you are running this script for the first time"
  type        = string
}

variable "Prod3_TGW_RT" {
  description = "TGW Attachment ID of Prod VPC, enter N/A if you are running this script for the first time"
  type        = string
}

variable "Sandbox_TGW_Attach" {
  description = "TGW Attachment ID of Sandbox VPC, enter N/A if you are running this script for the first time"
  type        = string
}

################################################################################
# List of Availability Zones
################################################################################

data "aws_availability_zones" "AZ" {
  state = "available"
}

################################################################################
# VPC to route the traffic destined to Internet from all the accounts
################################################################################

resource "aws_vpc" "OutboundVPC" {
  cidr_block       = var.outbound_vpc_cidr
  instance_tenancy = "default"
  tags = merge({
    Name = "OutboundVPC"
    flowlog = "all"},
  var.tags)
}

################################################################################
# Public Subnet
################################################################################

resource "aws_subnet" "EgressPublicAZ1" {
  vpc_id            = aws_vpc.OutboundVPC.id
  cidr_block        = var.EgressPublicAZ1_cidr 
  availability_zone = data.aws_availability_zones.AZ.names[0]
  tags = merge({
    Name = "EgressPublicAZ1"},
  var.tags)
}

resource "aws_subnet" "EgressPublicAZ2" {
  vpc_id            = aws_vpc.OutboundVPC.id
  cidr_block        = var.EgressPublicAZ2_cidr
  availability_zone = data.aws_availability_zones.AZ.names[1]
  tags = merge({
    Name = "EgressPublicAZ2"},
  var.tags)
}

################################################################################
# Private Subnet
################################################################################

resource "aws_subnet" "EgressPrivateAZ1" {
  vpc_id            = aws_vpc.OutboundVPC.id
  cidr_block        = var.EgressPrivateAZ1_cidr
  availability_zone = data.aws_availability_zones.AZ.names[0]
  tags = merge({
    Name = "EgressPrivateAZ1"},
  var.tags)
}

resource "aws_subnet" "EgressPrivateAZ2" {
  vpc_id            = aws_vpc.OutboundVPC.id
  cidr_block        = var.EgressPrivateAZ2_cidr
  availability_zone = data.aws_availability_zones.AZ.names[1]
  tags = merge({
    Name = "EgressPrivateAZ2"},
  var.tags)
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "OutboundVPC_IGW" {
  vpc_id = aws_vpc.OutboundVPC.id
  tags = merge({
    Name = "OutboundVPC_IGW"},
  var.tags)
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "NATGW_EIP_AZ1" {
  vpc = true
  tags = merge({
    Name = "NATGW_EIP_AZ1"},
  var.tags)
}

resource "aws_eip" "NATGW_EIP_AZ2" {
  vpc = true
  tags = merge({
    Name = "NATGW_EIP_AZ2"},
  var.tags)
}

resource "aws_nat_gateway" "OutboundVPC_NATGW_AZ1" {
  allocation_id = aws_eip.NATGW_EIP_AZ1.id
  subnet_id     = aws_subnet.EgressPublicAZ1.id
  tags = merge({
    Name = "OutboundVPC_NATGW_AZ1"},
  var.tags)
}

resource "aws_nat_gateway" "OutboundVPC_NATGW_AZ2" {
  allocation_id = aws_eip.NATGW_EIP_AZ2.id
  subnet_id     = aws_subnet.EgressPublicAZ2.id
  tags = merge({
    Name = "OutboundVPC_NATGW_AZ2"},
  var.tags)
}

################################################################################
# Route Table
################################################################################

resource "aws_route_table" "OutboundVPC_Public_RT" {
  vpc_id = aws_vpc.OutboundVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.OutboundVPC_IGW.id
  }

  route {
    cidr_block         = "10.120.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.SharedNetwork_TGW.id
  }

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.OutboundVPC_TGW_Attach
  ]
  tags = merge({
    Name = "OutboundVPC_Public_RT"},
  var.tags)
}

resource "aws_route_table" "OutboundVPC_Private_RT_AZ1" {
  vpc_id = aws_vpc.OutboundVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.OutboundVPC_NATGW_AZ1.id
  }
  tags = merge({
    Name = "OutboundVPC_Private_RT_AZ1"},
  var.tags)
}

resource "aws_route_table" "OutboundVPC_Private_RT_AZ2" {
  vpc_id = aws_vpc.OutboundVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.OutboundVPC_NATGW_AZ2.id
  }
  tags = merge({
    Name = "OutboundVPC_Private_RT_AZ2"},
  var.tags)
}

################################################################################
# Route Table Association
################################################################################

resource "aws_route_table_association" "OutboundVPC_Public_RT_AZ1_Association" {
  subnet_id      = aws_subnet.EgressPublicAZ1.id
  route_table_id = aws_route_table.OutboundVPC_Public_RT.id
}

resource "aws_route_table_association" "OutboundVPC_Public_RT_AZ2_Association" {
  subnet_id      = aws_subnet.EgressPublicAZ2.id
  route_table_id = aws_route_table.OutboundVPC_Public_RT.id
}

resource "aws_route_table_association" "OutboundVPC_Private_RT_AZ1_Association" {
  subnet_id      = aws_subnet.EgressPrivateAZ1.id
  route_table_id = aws_route_table.OutboundVPC_Private_RT_AZ1.id
}

resource "aws_route_table_association" "OutboundVPC_Private_RT_AZ2_Association" {
  subnet_id      = aws_subnet.EgressPrivateAZ2.id
  route_table_id = aws_route_table.OutboundVPC_Private_RT_AZ2.id
}

################################################################################
# Transit Gateway
################################################################################

resource "aws_ec2_transit_gateway" "SharedNetwork_TGW" {
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  tags = merge({
    Name = "SharedNetwork_TGW"},
  var.tags)
}

################################################################################
# Transit Gateway VPC Attachment
################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "OutboundVPC_TGW_Attach" {
  subnet_ids                                      = [aws_subnet.EgressPrivateAZ1.id, aws_subnet.EgressPrivateAZ2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.SharedNetwork_TGW.id
  vpc_id                                          = aws_vpc.OutboundVPC.id
  transit_gateway_default_route_table_association = false
  tags = merge({
    Name = "OutboundVPC_TGW_Attach"},
  var.tags)
}

################################################################################
# Transit Gateway VPN Attachment
################################################################################

resource "aws_customer_gateway" "Customer_Gateway" {
  bgp_asn    = 65000
  ip_address = "1.2.3.4"
  type       = "ipsec.1"
  tags = merge({
    Name = "Customer_Gateway"},
  var.tags)
}

resource "aws_vpn_connection" "VPN" {
  customer_gateway_id = aws_customer_gateway.Customer_Gateway.id
  transit_gateway_id  = aws_ec2_transit_gateway.SharedNetwork_TGW.id
  type                = aws_customer_gateway.Customer_Gateway.type
  tags = merge({
    Name = "VPN"},
  var.tags)
}

################################################################################
# Transit Gateway Route Table
# We are creating one TGW route table for each organizational unit, so that the
# VPCs part of the same OU can communicate with each other
################################################################################

resource "aws_ec2_transit_gateway_route_table" "OutboundVPC_TGW_RT" {
  transit_gateway_id = aws_ec2_transit_gateway.SharedNetwork_TGW.id
  tags = merge({
    Name = "OutboundVPC_TGW_RT"},
  var.tags)
}

resource "aws_ec2_transit_gateway_route_table" "Prod_TGW_RT" {
  transit_gateway_id = aws_ec2_transit_gateway.SharedNetwork_TGW.id
  tags = merge({
    Name = "Prod_TGW_RT"},
  var.tags)
}

resource "aws_ec2_transit_gateway_route_table" "Sandbox_TGW_RT" {
  transit_gateway_id = aws_ec2_transit_gateway.SharedNetwork_TGW.id
  tags = merge({
    Name = "Sandbox_TGW_RT"},
  var.tags)
}

################################################################################
# Transit Gateway Routes
################################################################################

resource "aws_ec2_transit_gateway_route" "Sandbox_TGW_Attach_DefaultRoute" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.OutboundVPC_TGW_Attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Sandbox_TGW_RT.id
}

################################################################################
# Transit Gateway Route Table Association
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "OutboundVPC_TGW_RT_Association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.OutboundVPC_TGW_Attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.OutboundVPC_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_association" "Prod1_TGW_RT_Association" {
  transit_gateway_attachment_id  = var.Prod1_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Prod_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_association" "Prod2_TGW_RT_Association" {
  transit_gateway_attachment_id  = var.Prod2_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Prod_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_association" "Prod3_TGW_RT_Association" {
  transit_gateway_attachment_id  = var.Prod3_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Prod_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_association" "Sandbox_TGW_RT_Association" {
  transit_gateway_attachment_id  = var.Sandbox_TGW_Attach
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Sandbox_TGW_RT.id
}

################################################################################
# Transit Gateway Route Table Propagation
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "Prod1_Propagation_OutboundVPC_TGW_RT" {
  transit_gateway_attachment_id  = var.Prod1_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.OutboundVPC_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "Prod2_Propagation_OutboundVPC_TGW_RT" {
  transit_gateway_attachment_id  = var.Prod2_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.OutboundVPC_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "Prod3_Propagation_OutboundVPC_TGW_RT" {
  transit_gateway_attachment_id  = var.Prod3_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.OutboundVPC_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "Sandbox_Propagation_OutboundVPC_TGW_RT" {
  transit_gateway_attachment_id  = var.Sandbox_TGW_Attach
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.OutboundVPC_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "Prod1_Propagation_Sandbox_TGW_RT" {
  transit_gateway_attachment_id  = var.Prod1_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Sandbox_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "Prod2_Propagation_Sandbox_TGW_RT" {
  transit_gateway_attachment_id  = var.Prod2_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Sandbox_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "Prod3_Propagation_Sandbox_TGW_RT" {
  transit_gateway_attachment_id  = var.Prod3_TGW_RT
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Sandbox_TGW_RT.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "Sandbox_Propagation_Prod_TGW_RT" {
  transit_gateway_attachment_id  = var.Sandbox_TGW_Attach
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.Prod_TGW_RT.id
}

################################################################################
# TGW Attachment Tags
################################################################################

resource "aws_ec2_tag" "Prod1_TGW_RT" {
  resource_id = var.Prod1_TGW_RT
  key         = "Name"
  value       = "Prod1_TGW_RT"
}

resource "aws_ec2_tag" "Prod2_TGW_RT" {
  resource_id = var.Prod2_TGW_RT
  key         = "Name"
  value       = "Prod2_TGW_RT"
}

resource "aws_ec2_tag" "Prod3_TGW_RT" {
  resource_id = var.Prod3_TGW_RT
  key         = "Name"
  value       = "Prod3_TGW_RT"
}

resource "aws_ec2_tag" "Sandbox_TGW_Attach" {
  resource_id = var.Sandbox_TGW_Attach
  key         = "Name"
  value       = "Sandbox_TGW_Attach"
}

################################################################################
# Resource Access Manager
# Sharing the TGW with Prod and Sandbox OUs to attach the VPCs in the account 
# that are part of the respective OUs
################################################################################

resource "aws_ram_resource_share" "Shared_TGW_RAM" {
  name = "Shared_TGW_RAM"
  tags = merge({
    Name = "Shared_TGW_RAM"},
  var.tags)
}

resource "aws_ram_principal_association" "Shared_TGW_RAM_Principal_HealthSystem" {
  principal          = "arn:aws:organizations::012345678910:ou/o-xxxxxxxx/ou-yyyy-zzzzzzz"
  resource_share_arn = aws_ram_resource_share.Shared_TGW_RAM.arn
}

resource "aws_ram_principal_association" "Shared_TGW_RAM_Principal_Sandbox" {
  principal          = "arn:aws:organizations::012345678910:ou/o-xxxxxxxx/ou-yyyy-zzzzzzz"
  resource_share_arn = aws_ram_resource_share.Shared_TGW_RAM.arn
}

resource "aws_ram_resource_association" "Shared_TGW_RAM_Resource" {
  resource_arn       = aws_ec2_transit_gateway.SharedNetwork_TGW.arn
  resource_share_arn = aws_ram_resource_share.Shared_TGW_RAM.arn
}
