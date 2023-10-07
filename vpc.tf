provider "aws" {
  region = "us-east-1"
  profile = "Ayo"
}

# Create a VPC named "awesome" with CIDR 10.0.0.0/16
resource "aws_vpc" "awesome" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "awesome"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "awesome_igw" {
  vpc_id = aws_vpc.awesome.id
}

# Create two public subnets
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.awesome.id
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
}

# Create two private subnets
resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.awesome.id
  cidr_block        = element(["10.0.3.0/24", "10.0.4.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
}

# Create two database subnets
resource "aws_subnet" "db_subnet" {
  count             = 2
  vpc_id            = aws_vpc.awesome.id
  cidr_block        = element(["10.0.5.0/24", "10.0.6.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = 2
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.awesome.id
}

# Create private route table
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.awesome.id
}

# Create routes for public route table
resource "aws_route" "public_route" {
  count                  = 2
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.awesome_igw.id
}

# Create routes for private route tables
resource "aws_route" "private_route" {
  count                  = 2
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
