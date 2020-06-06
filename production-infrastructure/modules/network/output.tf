output "vpc" {
  value = aws_vpc.this
}

output "subnet_production_a" {
  value = aws_subnet.production_a
}

output "subnet_production_b" {
  value = aws_subnet.production_b
}

output "subnet_staging_a" {
  value = aws_subnet.staging_a
}

output "subnet_staging_b" {
  value = aws_subnet.staging_b
}

output "subnet_rds_a" {
  value = aws_subnet.rds_a
}

output "subnet_rds_b" {
  value = aws_subnet.rds_b
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
