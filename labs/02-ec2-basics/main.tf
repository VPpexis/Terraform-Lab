data "aws_ami" "alpine" {
  filter {
    name   = "image-id"
    values = ["ami-alpine"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.alpine.id
  instance_type = "t2.micro"

  tags = {
    name = "Testing Instance"
  }
}

