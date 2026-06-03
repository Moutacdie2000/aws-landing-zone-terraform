# =============================================================================
# Outputs du module iam-identity-center
# =============================================================================

output "instance_arn" {
  description = "ARN de l'instance IAM Identity Center."
  value       = local.instance_arn
}

output "identity_store_id" {
  description = "Identifiant de l'Identity Store associé."
  value       = local.identity_store_id
}

output "permission_set_arns" {
  description = "ARN des permission sets, indexés par nom."
  value = {
    AdministratorAccess = aws_ssoadmin_permission_set.administrator.arn
    ReadOnly            = aws_ssoadmin_permission_set.read_only.arn
    Billing             = aws_ssoadmin_permission_set.billing.arn
  }
}

output "group_ids" {
  description = "Identifiants des groupes Identity Center, indexés par nom."
  value = {
    "platform-admins" = aws_identitystore_group.platform_admins.group_id
    "auditors"        = aws_identitystore_group.auditors.group_id
    "finops"          = aws_identitystore_group.finops.group_id
  }
}
