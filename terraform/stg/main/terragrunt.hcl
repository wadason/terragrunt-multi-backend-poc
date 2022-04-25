remote_state {
  backend = "s3"
  config = {
    bucket         = "XXXXXX"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "XXXXXX"
  }
}
