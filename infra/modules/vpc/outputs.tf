output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_ip" {
  value = aws_eip.nat.public_ip
}

# 기존 출력들 유지...
output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}
