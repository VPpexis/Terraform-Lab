data "aws_ami" "alpine" {
  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

resource "aws_instance" "example_lab4" {
  ami           = data.aws_ami.alpine.id
  instance_type = var.instance_type
  user_data     = file("${path.module}/user-data.sh")

  tags = {
    Name = var.instance_name
  }
}