variable "instance_type" {
  type        = string
  description = "EC2 instance type for alpine server"
  default     = "t2.micro"
}

variable "instance_name" {
  type    = string
  default = "lab04-ec2"
}

variable "ami_id" {
  type    = string
  default = "ami-alpine"
}