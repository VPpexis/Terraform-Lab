resource "aws_vpc" "main" {
  cidr_block = var.vpc_ip

  tags = {
    Name = "Lab05 VPC"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_ip

  tags = {
    Name = "Lab05 Subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Lab5 Internet Gateway"
  }
}

resource "aws_route_table" "name" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Lab05 Route Table"
  }
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.name.id
}

resource "aws_security_group" "security_group" {
  name        = "allow_http"
  description = "allow http port 8080"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Lab05 Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  to_port           = 8080
  from_port         = 8080
}