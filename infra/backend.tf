terraform {
  backend "s3" {
    bucket         = "tfstate-lionkdt5-team2"
    key            = "project2/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "tfstate-lock-team2"
    encrypt        = true
  }
}

