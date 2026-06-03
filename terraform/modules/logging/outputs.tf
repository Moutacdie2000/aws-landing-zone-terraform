# =============================================================================
# Outputs du module logging
# =============================================================================

output "log_bucket_id" {
  description = "Nom du bucket S3 de logs centralisés."
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_arn" {
  description = "ARN du bucket S3 de logs centralisés."
  value       = aws_s3_bucket.logs.arn
}

output "kms_key_arn" {
  description = "ARN de la clé KMS de chiffrement des logs."
  value       = aws_kms_key.logs.arn
}

output "kms_key_alias" {
  description = "Alias de la clé KMS de chiffrement des logs."
  value       = aws_kms_alias.logs.name
}

output "cloudtrail_arn" {
  description = "ARN de l'org-trail CloudTrail."
  value       = aws_cloudtrail.org.arn
}

output "config_recorder_name" {
  description = "Nom de l'enregistreur AWS Config."
  value       = aws_config_configuration_recorder.this.name
}

output "config_role_arn" {
  description = "ARN du rôle IAM utilisé par AWS Config."
  value       = aws_iam_role.config.arn
}
