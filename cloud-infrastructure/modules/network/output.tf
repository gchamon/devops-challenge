output "vpc" {
  value = aws_vpc.this
}

output "subnets" {
  value = {
    production = [
      aws_subnet.production_a,
      aws_subnet.production_b
    ]
    staging = [
      aws_subnet.staging_a,
      aws_subnet.staging_b
    ]
    rds = [
      aws_subnet.rds_a,
      aws_subnet.rds_b
    ]
  }
}

output "nat_gateway" {
  value = aws_nat_gateway.this
}

output "internet_gateway" {
  value = aws_internet_gateway.default
}

output "db_subnet_group_rds" {
  value = aws_db_subnet_group.rds
}
