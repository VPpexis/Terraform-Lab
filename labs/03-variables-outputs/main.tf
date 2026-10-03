data "aws_ami" "alpine" {
  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.alpine.id
  instance_type = var.instance_type

  tags = {
    name = var.instance_name
  }
}