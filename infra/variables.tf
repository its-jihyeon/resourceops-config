variable "project" { default = "team2-project" }
variable "github_org" { type = string }
variable "github_repo" { type = string }
variable "allowed_ips" {
  type        = list(string)
  description = "SSH 허용할 IP 목록"
}
# variables.tf
variable "ecr_repositories" {
  type        = list(string)
  description = "생성할 ECR Repository 이름 목록"
  default     = ["team2-backend"]
}
