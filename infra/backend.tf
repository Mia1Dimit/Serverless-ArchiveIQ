terraform {
  backend "s3" {
    bucket         = "tfstates-577638377042-eu-west-1-an"
    region         = "eu-west-1"
    dynamodb_table = "tfstates-ddb-tfstatelock"
    encrypt        = true
  }
}
