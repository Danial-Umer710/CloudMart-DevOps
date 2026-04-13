output "server_public_ip" {
  value = aws_instance.cloudmart_web.public_ip
}
