
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "app-vpc"
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "app-igw1"
  }
}


#Create Nat Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.pub3_subnet.id

  tags = {
    Name = "app_Nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

#create elastic IP
resource "aws_eip" "lb" {
  domain   = "vpc"
}

# List availability zones in region
data "aws_availability_zones" "az_list" {
  state = "available"
}

# pub1 subnet
resource "aws_subnet" "pub1_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub1_subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.az_list.names[0]

  tags   = {
    Name = "pub1_subnet"
  }
}

# pub2 subnet
resource "aws_subnet" "pub2_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub2_subnet_cidr_block
  availability_zone       = data.aws_availability_zones.az_list.names[1]

  tags   = {
    Name = "pub2_subnet"
  }
}

# pub3 subnet
resource "aws_subnet" "pub3_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub3_subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.az_list.names[2]

  tags   = {
    Name = "nat_subnet"
  }
}

# prv1 subnet
resource "aws_subnet" "prv1_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.prv1_subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.az_list.names[0]

  tags   = {
    Name = "prv1_subnet"
  }
}

# prv2 subnet
resource "aws_subnet" "prv2_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.prv1_subnet_cidr_block
  availability_zone       = data.aws_availability_zones.az_list.names[1]

  tags   = {
    Name = "prv2_subnet"
  }
}


# Nat Gateway Subnet Route table
resource "aws_route_table" "nat_routes" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags   = {
    Name = "nat_rt"
  }
}

#Load Balancer
resource "aws_lb" "nlb" {
  for_each = {
    frontend = {
      internal = false
      subnet   = aws_subnet.pub2_subnet.id
    },
    backend = {
      internal = true
      subnet   = aws_subnet.prv2_subnet.id
    }
  }
  name               = "${each.key}-app-nlb"
  internal           = each.value.internal
  load_balancer_type = "network"
  subnets            = [each.value.subnet]
}

# Prv Subnets Route table
resource "aws_route_table" "prv_routes" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags   = {
    Name = "prv_rt"
  }
}

# Pub Subnets Route table
resource "aws_route_table" "pub_routes" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags   = {
    Name = "pub_rt"
  }
}

# Associate pub route table with pub subnets
resource "aws_route_table_association" "pub1_subnet_route" {
  subnet_id      = aws_subnet.pub1_subnet.id
  route_table_id = aws_route_table.pub_routes.id
}
resource "aws_route_table_association" "pub2_subnet_route" {
  subnet_id      = aws_subnet.pub2_subnet.id
  route_table_id = aws_route_table.pub_routes.id
}

# Associate prv route table with prv subnets
resource "aws_route_table_association" "prv1_subnet_route" {
  subnet_id      = aws_subnet.prv1_subnet.id
  route_table_id = aws_route_table.prv_routes.id
}
resource "aws_route_table_association" "prv2_subnet_route" {
  subnet_id      = aws_subnet.prv2_subnet.id
  route_table_id = aws_route_table.prv_routes.id
}

# Associate nat route table with nat subnets
resource "aws_route_table_association" "pub3_subnet_route" {
  subnet_id      = aws_subnet.pub3_subnet.id
  route_table_id = aws_route_table.nat_routes.id
}


