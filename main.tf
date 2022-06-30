# Brainboard auto-generated file.

resource "aws_vpc" "brainboard_vpc" {
  provider = aws.us-west-2

  enable_dns_hostnames           = true
  enable_classiclink_dns_support = false
  cidr_block                     = "10.10.0.0/16"
}

resource "aws_eip" "brainboard_eip" {
  provider = aws.us-west-2

  vpc = true

  depends_on = [
    aws_internet_gateway.brainboard_gateway,
  ]

  tags = {
    env      = "intern-gdp"
    archUUID = "33b30902-2019-497b-ae34-63c45429981b"
  }
}

resource "aws_internet_gateway" "brainboard_gateway" {
  provider = aws.us-west-2

  vpc_id = aws_vpc.brainboard_vpc.id
}

resource "aws_subnet" "http" {
  provider = aws.us-west-2

  vpc_id            = aws_vpc.brainboard_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "us-west-2a"

  depends_on = [
    aws_internet_gateway.brainboard_gateway,
  ]
}

resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.brainboard_vpc.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "us-west-2b"

  depends_on = [
    aws_internet_gateway.brainboard_gateway,
  ]
}

resource "aws_route_table" "public_route" {
  provider = aws.us-west-2

  vpc_id = aws_vpc.brainboard_vpc.id

  route {
    gateway_id = aws_internet_gateway.brainboard_gateway.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "route_table_http" {
  provider = aws.us-west-2

  subnet_id      = aws_subnet.http.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "route_table_db" {
  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_instance" "http" {
  provider = aws.us-west-2

  subnet_id                   = aws_subnet.http.id
  key_name                    = aws_key_pair.brainboard_key.key_name
  instance_type               = "t2.micro"
  availability_zone           = "us-west-2a"
  associate_public_ip_address = true
  ami                         = "ami-0ddf424f81ddb0720"

  tags = {
    env      = "intern-gdp"
    archUUID = "33b30902-2019-497b-ae34-63c45429981b"
  }

  vpc_security_group_ids = [
    aws_security_group.administration.id,
    aws_security_group.web.id,
  ]
}

resource "aws_instance" "db_instance" {
  subnet_id                   = aws_subnet.db.id
  key_name                    = aws_key_pair.brainboard_key.key_name
  instance_type               = "t2.micro"
  availability_zone           = "us-west-2b"
  associate_public_ip_address = false
  ami                         = "ami-0ddf424f81ddb0720"

  tags = {
    env      = "intern-gdp"
    archUUID = "33b30902-2019-497b-ae34-63c45429981b"
  }

  vpc_security_group_ids = [
    aws_security_group.administration.id,
    aws_security_group.DB.id,
  ]
}

resource "aws_key_pair" "brainboard_key" {
  provider = aws.us-west-2

  public_key = var.public_key
}

resource "aws_security_group" "administration" {
  provider = aws.us-west-2

  vpc_id      = aws_vpc.brainboard_vpc.id
  name        = "administration"
  description = "allow default service for admin"
}

resource "aws_security_group_rule" "brainboard_ssh" {
  provider = aws.us-west-2

  type              = "ingress"
  to_port           = 22
  security_group_id = aws_security_group.administration.id
  protocol          = "tcp"
  from_port         = 22

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "icmp" {
  provider = aws.us-west-2

  type              = "ingress"
  to_port           = 0
  security_group_id = aws_security_group.administration.id
  protocol          = "icmp"
  from_port         = 8

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "public_access" {
  provider = aws.us-west-2

  type              = "egress"
  to_port           = 0
  security_group_id = aws_security_group.administration.id
  protocol          = "-1"
  from_port         = 0

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group" "web" {
  provider = aws.us-west-2

  vpc_id = aws_vpc.brainboard_vpc.id
}

resource "aws_security_group_rule" "http" {
  provider = aws.us-west-2

  type              = "ingress"
  to_port           = 80
  security_group_id = aws_security_group.web.id
  protocol          = "tcp"
  from_port         = 80

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "https" {
  provider = aws.us-west-2

  type              = "ingress"
  to_port           = 443
  security_group_id = aws_security_group.web.id
  protocol          = "tcp"
  from_port         = 443

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "public_access_web" {
  provider = aws.us-west-2

  type              = "ingress"
  to_port           = 0
  security_group_id = aws_security_group.web.id
  protocol          = "-1"
  from_port         = 0

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group" "DB" {
  provider = aws.us-west-2

  vpc_id      = aws_vpc.brainboard_vpc.id
  name        = "db"
  description = "Allow database traffic"
}

resource "aws_security_group_rule" "mysql" {
  provider = aws.us-west-2

  type              = "ingress"
  to_port           = 3306
  security_group_id = aws_security_group.DB.id
  protocol          = "tcp"
  from_port         = 3306

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "public_access_db" {
  provider = aws.us-west-2

  type              = "egress"
  to_port           = 0
  security_group_id = aws_security_group.DB.id
  protocol          = "-1"
  from_port         = 0

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_nat_gateway" "brainboard_nat" {
  provider = aws.us-west-2

  subnet_id     = aws_subnet.http.id
  allocation_id = aws_eip.brainboard_eip.id
}

resource "aws_route_table" "private_rt" {
  provider = aws.us-west-2

  vpc_id = aws_vpc.brainboard_vpc.id

  route {
    nat_gateway_id = aws_nat_gateway.brainboard_nat.id
    cidr_block     = "0.0.0.0/0"
  }
}