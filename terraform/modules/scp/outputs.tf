# =============================================================================
# Outputs du module scp
# =============================================================================

output "policy_ids" {
  description = "Identifiants des SCP créées, indexés par nom logique."
  value = {
    protect_security_services = aws_organizations_policy.protect_security_services.id
    region_restriction        = aws_organizations_policy.region_restriction.id
    deny_root_user            = aws_organizations_policy.deny_root_user.id
    protect_log_buckets       = aws_organizations_policy.protect_log_buckets.id
  }
}

output "policy_arns" {
  description = "ARN des SCP créées, indexés par nom logique."
  value = {
    protect_security_services = aws_organizations_policy.protect_security_services.arn
    region_restriction        = aws_organizations_policy.region_restriction.arn
    deny_root_user            = aws_organizations_policy.deny_root_user.arn
    protect_log_buckets       = aws_organizations_policy.protect_log_buckets.arn
  }
}
