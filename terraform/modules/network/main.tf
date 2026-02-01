# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project}-vpc"
    Project = var.project
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = element(var.availability_zones, index(var.public_subnet_cidrs, each.value))
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-public-${each.value}"
    Project = var.project
    Type    = "public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = toset(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(var.availability_zones, index(var.private_subnet_cidrs, each.value))

  tags = {
    Name    = "${var.project}-private-${each.value}"
    Project = var.project
    Type    = "private"
  }
}

# Database Subnets
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-database-subnet-${count.index + 1}"
      Tier = "Database"
    }
  )
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name    = "${var.project}-public-rt"
    Project = var.project
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_subnets" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Allocate Elastic IP for NAT
resource "aws_eip" "nat" {

  tags = {
    Name    = "${var.project}-nat-eip"
    Project = var.project
  }
}

# NAT Gateway in the first public subnet
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id = values(aws_subnet.public)[0].id


  tags = {
    Name    = "${var.project}-nat"
    Project = var.project
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name    = "${var.project}-private-rt"
    Project = var.project
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_subnets" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}


# Database Route Table
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-database-rt"
    }
  )
}

# Database Route Table Associations
resource "aws_route_table_association" "database_rat" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}