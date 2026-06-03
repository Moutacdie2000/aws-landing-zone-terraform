# =============================================================================
# Outputs du module guardduty
# =============================================================================

output "detector_id" {
  description = "Identifiant du détecteur GuardDuty (administrateur délégué)."
  value       = aws_guardduty_detector.this.id
}

output "detector_arn" {
  description = "ARN du détecteur GuardDuty."
  value       = aws_guardduty_detector.this.arn
}

output "member_account_ids" {
  description = "Identifiants des comptes membres enrôlés explicitement."
  value       = [for m in aws_guardduty_member.this : m.account_id]
}
