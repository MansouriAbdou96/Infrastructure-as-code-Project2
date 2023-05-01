terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "mytf-infra-bucket"
    key    = "tf-infra/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "VPC" {
  cidr_block           = var.VpcCidr
  enable_dns_hostnames = true

  tags = {
    "Name" = var.EnvironmentName
  }
}

resource "aws_internet_gateway" "InternetGateway" {
  tags = {
    "Name" = var.EnvironmentName
  }
}

resource "aws_internet_gateway_attachment" "InternetGatewayAttachment" {
  internet_gateway_id = aws_internet_gateway.InternetGateway.id
  vpc_id              = aws_vpc.VPC.id
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PublicSubnet1CIDR
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 0)

  tags = {
    "Name" = "${var.EnvironmentName} public subnet (AZ1)"
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PublicSubnet2CIDR
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 1)

  tags = {
    "Name" = "${var.EnvironmentName} public subnet (AZ2)"
  }
}

resource "aws_subnet" "PrivateSubnet1" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PrivateSubnet1CIDR
  map_public_ip_on_launch = false
  availability_zone       = element(data.aws_availability_zones.available.names, 0)

  tags = {
    "Name" = "${var.EnvironmentName} private subnet (AZ1)"
  }
}

resource "aws_subnet" "PrivateSubnet2" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = var.PrivateSubnet2CIDR
  map_public_ip_on_launch = false
  availability_zone       = element(data.aws_availability_zones.available.names, 1)

  tags = {
    "Name" = "${var.EnvironmentName} private subnet (AZ2)"
  }
}

resource "aws_eip" "NatGateway1EIP" {
  depends_on = [
    aws_internet_gateway_attachment.InternetGatewayAttachment
  ]
  vpc = true
}

resource "aws_eip" "NatGateway2EIP" {
  depends_on = [
    aws_internet_gateway_attachment.InternetGatewayAttachment
  ]
  vpc = true
}

resource "aws_nat_gateway" "NatGateway1" {
  allocation_id = aws_eip.NatGateway1EIP.allocation_id
  subnet_id     = aws_subnet.PublicSubnet1.id
}

resource "aws_nat_gateway" "NatGateway2" {
  allocation_id = aws_eip.NatGateway2EIP.allocation_id
  subnet_id     = aws_subnet.PublicSubnet2.id
}

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.VPC.id
  tags = {
    "Name" = "${var.EnvironmentName} Public Routes"
  }
}

resource "aws_route" "DefaultPublicRoute" {
  depends_on = [
    aws_internet_gateway_attachment.InternetGatewayAttachment
  ]

  route_table_id         = aws_route_table.PublicRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.InternetGateway.id
}

resource "aws_route_table_association" "PuSubnet1RTA" {
  route_table_id = aws_route_table.PublicRouteTable.id
  subnet_id      = aws_subnet.PublicSubnet1.id
}

resource "aws_route_table_association" "PuSubnet2RTA" {
  route_table_id = aws_route_table.PublicRouteTable.id
  subnet_id      = aws_subnet.PublicSubnet2.id
}

resource "aws_route_table" "PrivateRouteT1" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    "Name" = "${var.EnvironmentName} Private Routes (AZ1)"
  }
}

resource "aws_route" "DefaultPrivateR1" {
  route_table_id         = aws_route_table.PrivateRouteT1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NatGateway1.id
}

resource "aws_route_table_association" "PrSubnet1RTA" {
  route_table_id = aws_route_table.PrivateRouteT1.id
  subnet_id      = aws_subnet.PrivateSubnet1.id
}

resource "aws_route_table" "PrivateRouteT2" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    "Name" = "${var.EnvironmentName} Private Routes (AZ2)"
  }
}

resource "aws_route" "DefaultPrivateR2" {
  route_table_id         = aws_route_table.PrivateRouteT2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NatGateway2.id
}

resource "aws_route_table_association" "PrSubnet2RTA" {
  route_table_id = aws_route_table.PrivateRouteT2.id
  subnet_id      = aws_subnet.PrivateSubnet2.id
}

