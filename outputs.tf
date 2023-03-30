output "ec2_instance_id" {
  description = "The instance ID(s)"
  value       = aws_instance.ec2_instance.*.id
}

output "device_name" {
  description = "Additional device name(s) attached"
  value       = aws_volume_attachment.data-volume-attachment.*.device_name
}

output "attached_volume" {
  description = "Additional volume ID(s) attached"
  value       = aws_volume_attachment.data-volume-attachment.*.volume_id
}

output "private_ip" {
  description = "Instance private IP"
  value       = aws_instance.ec2_instance.*.private_ip
}

output "iam_role_id" {
  description = "The ID of the iam role created for the ec2 instances"
  value       = alks_iamrole.ec2_role.id
}

output "iam_role_arn" {
  description = "The ARN of the iam role created for the ec2 instances"
  value       = alks_iamrole.ec2_role.arn
}

output "iam_role_name" {
  description = "The name of the iam role created for the ec2 instances"
  value       = alks_iamrole.ec2_role.name
}
