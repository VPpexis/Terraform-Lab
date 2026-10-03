variable "instance_type" {
  type        = string
  description = "EC2 instance type for alpine server"
  default     = "t2.micro"
}

variable "instance_name" {
  type    = string
}

variable "ami_id" {
  type    = string
  default = "ami-alpine"
}