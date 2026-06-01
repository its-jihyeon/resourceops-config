output "db_endpoint" {
  description = "RDS 엔드포인트 (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "데이터베이스 이름"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "마스터 유저명"
  value       = aws_db_instance.this.username
}

output "db_secret_arn" {
  description = "Secrets Manager에 저장된 DB 비밀번호 ARN"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
