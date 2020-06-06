
resource "aws_vpc" "this" {
  cidr_block           = "${var.cidr_prefix}.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" = var.vpc_name
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.this.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "production_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "${var.cidr_prefix}.0.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "public_production_a"
  }
}

resource "aws_subnet" "production_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "${var.cidr_prefix}.16.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "public_production_b"
  }
}

resource "aws_subnet" "staging_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "${var.cidr_prefix}.32.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "public_staging_a"
  }
}

resource "aws_subnet" "staging_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "${var.cidr_prefix}.48.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "public_staging_b"
  }
}

resource "aws_subnet" "rds_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "${var.cidr_prefix}.64.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "private_rds_a"
  }
}

resource "aws_subnet" "rds_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "${var.cidr_prefix}.80.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "private_rds_a"
  }
}

resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.production_a.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "rds_a" {
  subnet_id      = aws_subnet.rds_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "rds_b" {
  subnet_id      = aws_subnet.rds_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_db_subnet_group" "rds" {
  name       = "main"
  subnet_ids = [aws_subnet.rds_a.id, aws_subnet.rds_b.id]

  tags = {
    Name = "RDS Subnet Group"
  }
}
