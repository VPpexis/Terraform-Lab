output "instance_id" {
  description = "ID of the Instance"
  value       = aws_instance.example_lab4.id
}

output "instance_private_ip" {
  description = "Private IP of the Instance"
  value       = aws_instance.example_lab4.private_ip
}