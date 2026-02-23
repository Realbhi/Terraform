#creating vpc :

resource "aws_vpc" "trial_vpc" {
  cidr_block = "10.1.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "trial_vpc"
  }
}


# creating subnets

#public subnet at az-1
resource "aws_subnet" "trial_vpc_pub1" {
  vpc_id                  = aws_vpc.trial_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "trial_vpc_pub1"
  }
}

#public subnet at az-2
resource "aws_subnet" "trial_vpc_pub2" {
  vpc_id                  = aws_vpc.trial_vpc.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "trial_vpc_pub2"
  }
}

#private subnet at az-1 :
resource "aws_subnet" "trial_vpc_pvt1" {
  vpc_id            = aws_vpc.trial_vpc.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "trial_vpc_pvt1"
  }
}

#private subnet at az-2 :
resource "aws_subnet" "trial_vpc_pvt2" {
  vpc_id            = aws_vpc.trial_vpc.id
  cidr_block        = "10.1.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "trial_vpc_pvt2"
  }
}

#internet gateway :
resource "aws_internet_gateway" "trial_igw" {
  vpc_id = aws_vpc.trial_vpc.id

  tags = {
    Name = "trial-igw"
  }
}



#Route-table- for public subnet :
resource "aws_route_table" "trial_pub_routetable" {
  vpc_id = aws_vpc.trial_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.trial_igw.id
  }

  tags = {
    Name = "trial_pub_routetable"
  }

}

#Route table association with subnets :
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.trial_vpc_pub1.id
  route_table_id = aws_route_table.trial_pub_routetable.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.trial_vpc_pub2.id
  route_table_id = aws_route_table.trial_pub_routetable.id
}


# Private subnet - Elastic IP -  Nat Gateway - Private Route Table - Route private traffic → Associate Private Route Table

# ElasticIp for NAT ::
resource "aws_eip" "nat_ip" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

#nat gateway
resource "aws_nat_gateway" "nat_way" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.trial_vpc_pub1.id

  tags = {
    Name = "demo-nat"
  }

  depends_on = [aws_internet_gateway.trial_igw]
}



#Route-table- for private subnet :
resource "aws_route_table" "trial_prvt_routetable" {
  vpc_id = aws_vpc.trial_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_way.id
  }

  tags = {
    Name = "trial_prvt_routetable"
  }

}


# subnet association :
resource "aws_route_table_association" "private_Association1" {
  subnet_id      = aws_subnet.trial_vpc_pvt1.id
  route_table_id = aws_route_table.trial_prvt_routetable.id

}

resource "aws_route_table_association" "private_Association2" {
  subnet_id      = aws_subnet.trial_vpc_pvt2.id
  route_table_id = aws_route_table.trial_prvt_routetable.id
}

