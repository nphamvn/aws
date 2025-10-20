locals {
  cluster_name = "99-cluster"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private_1" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.0.1.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.0.2.0/24"
  availability_zone_id = data.aws_availability_zones.available.zone_ids[1]

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone_id    = data.aws_availability_zones.available.zone_ids[0]
  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/cluster/99-cluster" : "shared"
    "kubernetes.io/role/elb" : "1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone_id    = data.aws_availability_zones.available.zone_ids[1]
  map_public_ip_on_launch = true
  tags = {
    "kubernetes.io/cluster/99-cluster" : "shared"
    "kubernetes.io/role/elb" : "1"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "public_1_association" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_1.id
}

resource "aws_route_table_association" "public_2_association" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_2.id
}

resource "aws_eip" "nat_1_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1_eip.id
  subnet_id     = aws_subnet.public_1.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }
}

resource "aws_route_table_association" "private_1_association" {
  route_table_id = aws_route_table.private_1.id
  subnet_id      = aws_subnet.private_1.id
}

resource "aws_eip" "nat_2_eip" {
  domain = "vpc"
}
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2_eip.id
  subnet_id     = aws_subnet.public_2.id
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }
}

resource "aws_route_table_association" "private_2_association" {
  route_table_id = aws_route_table.private_2.id
  subnet_id      = aws_subnet.private_2.id
}