variable "project_name" {}
variable "environment" {}
variable "suffix" {}

variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "bastion_security_group_id" {}

variable "bastion_instance_type" {
}

variable "bastion_ami_id" {}

variable "key_name" {
  default = null
}