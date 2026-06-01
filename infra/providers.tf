provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      team    = "team2"
      project = "resource-opt"
    }
  }
}
