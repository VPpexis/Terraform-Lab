variable "instance_type" {
  type        = string
  description = "EC2 instance type for alpine server"
  default     = "t2.micro"
}

variable "instance_name" {
  type    = string
  default = "EC2 Instance for Lab 05 VPC Networking"
}

variable "ami_id" {
  type    = string
  default = "ami-alpine"
}

variable "vpc_ip" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_ip" {
  type    = string
  default = "10.0.1.0/24"
}