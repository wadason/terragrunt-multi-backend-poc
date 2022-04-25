resource "aws_ssm_parameter" "fuga" {
  name  = "fuga"
  type  = "String"
  value = "fuga"
}

data "aws_ssm_parameter" "piyo" {
  name = "piyo"
}

output "get_ssm_piyo" {
  value = data.aws_ssm_parameter.piyo.arn
}
