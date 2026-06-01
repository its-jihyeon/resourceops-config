variable "project" {
  description = "리소스 이름 prefix"
  type        = string
}

variable "vpc_id" {
  description = "Bastion을 배치할 VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Bastion 배치할 퍼블릭 서브넷 ID"
  type        = string
}

variable "allowed_ips" {
  description = "SSH 허용할 IP 목록"
  type        = list(string)
}

variable "instance_type" {
  description = "Bastion EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS 콘솔에서 발급한 EC2 Key Pair 이름"
  type        = string
  default     = "team2-key"
}
