data "aws_ami" "alpine" {
  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

resource "aws_instance" "ec2_lab05" {
  ami                    = data.aws_ami.alpine.id
  instance_type          = var.instance_type
  user_data              = file("${path.module}/user-data.sh")
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.security_group.id]

  tags = {
    Name = var.instance_name
  }
}