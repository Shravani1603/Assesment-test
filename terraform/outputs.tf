output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.directus_server.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.directus_server.id
}

output "directus_url" {
  description = "URL to access Directus"
  value       = "http://${aws_instance.directus_server.public_ip}:8055"
}

output "private_key_pem" {
  description = "Private SSH key for server access (sensitive)"
  value       = tls_private_key.directus_key.private_key_pem
  sensitive   = true
}

output "public_key_openssh" {
  description = "Public SSH key"
  value       = tls_private_key.directus_key.public_key_openssh
}
