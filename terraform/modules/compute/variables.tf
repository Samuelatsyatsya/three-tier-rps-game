variable "project_name" {}
variable "environment" {}
variable "suffix" {}

variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "app_security_group_id" {}
variable "app_target_group_arn" {}

variable "instance_type" {
  default = "t3.micro"
}

variable "instance_types" {
  description = "List of instance types for spot diversification"
  type        = list(string)
}

variable "ami_id" {}

variable "key_name" {
  default = null
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 2
}

variable "desired_capacity" {
  default = 1
}



# Spot instance configuration
variable "on_demand_base_capacity" {
  description = "Minimum number of on-demand instances (always running)"
  type        = number
}

variable "on_demand_percentage" {
  description = "Percentage of on-demand instances beyond base capacity"
  type        = number
}

variable "spot_instance_pools" {
  description = "Number of Spot instance pools to use"
  type        = number
}

# Target tracking configuration
variable "cpu_target_value" {
  description = "CPU utilization percentage to maintain (e.g., 50.0 for 50%)"
  type        = number
}

variable "app_port" {
}

variable "db_endpoint" {}
variable "db_reader_endpoint" {}
variable "db_name" {}

# Add bastion security group reference
variable "bastion_security_group_id" {}