# 출력값:
#   - public_ip        : Bastion 퍼블릭 IP (SSH 접속 주소)
#   - instance_id      : EC2 인스턴스 ID
#   - security_group_id: Bastion SG ID (EKS 보안그룹 규칙에 참조)
#   - key_name         : Key Pair 이름
#   - role_arn         : role_arn

output "public_ip" {
  value = aws_instance.bastion.public_ip
}

output "instance_id" {
  value = aws_instance.bastion.id
}

output "security_group_id" {
  value = aws_security_group.bastion.id
}


output "role_arn" {
  value = aws_iam_role.bastion.arn
}

output "key_name" {
  value = aws_key_pair.bastion.key_name
}
