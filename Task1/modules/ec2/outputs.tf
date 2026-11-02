output "instance_ids" {
  description = "Instance Name to EC2 ID."
  value       = { for name, instance in local.all_instances : name => instance.id }
}

output "private_ips" {
  description = "Instance Name to private IP."
  value       = { for name, instance in local.all_instances : name => instance.private_ip }
}
