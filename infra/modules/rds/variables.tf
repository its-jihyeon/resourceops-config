variable "project" {}
variable "vpc_id" {}
variable "db_subnet_ids" { type = list(string) }
variable "eks_node_security_group_id" {}
