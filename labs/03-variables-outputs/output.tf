output "instance_id" {
  description = "ID of the Instance"
  value = aws_instance.example.id
}

output "instance_private_i" {
  description = "Private IP of the Instance"
  value = aws_instance.example.private_ip
}