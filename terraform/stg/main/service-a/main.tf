resource "aws_ssm_parameter" "piyo" {
  name  = "piyo"
  type  = "String"
  value = "piyo"
}

module "service_a" {
  source = "../../../modules/common/service-a"
}
