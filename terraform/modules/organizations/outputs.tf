# =============================================================================
# Outputs du module organizations
# =============================================================================

output "organization_id" {
  description = "Identifiant de l'organisation AWS (o-xxxxxxxxxx)."
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "ARN de l'organisation AWS."
  value       = aws_organizations_organization.this.arn
}

output "organization_root_id" {
  description = "Identifiant de la racine de l'organisation (r-xxxx)."
  value       = aws_organizations_organization.this.roots[0].id
}

output "management_account_id" {
  description = "Identifiant du compte de gestion (master)."
  value       = aws_organizations_organization.this.master_account_id
}

output "ou_ids" {
  description = "Identifiants des unités organisationnelles, indexés par nom."
  value = {
    security          = aws_organizations_organizational_unit.security.id
    workloads         = aws_organizations_organizational_unit.workloads.id
    workloads_prod    = aws_organizations_organizational_unit.workloads_prod.id
    workloads_nonprod = aws_organizations_organizational_unit.workloads_nonprod.id
    sandbox           = aws_organizations_organizational_unit.sandbox.id
  }
}

output "account_ids" {
  description = "Identifiants des comptes membres, indexés par nom logique."
  value = {
    log_archive       = aws_organizations_account.log_archive.id
    security_audit    = aws_organizations_account.security_audit.id
    workloads_prod    = aws_organizations_account.workloads_prod.id
    workloads_nonprod = aws_organizations_account.workloads_nonprod.id
    sandbox           = aws_organizations_account.sandbox.id
  }
}

output "log_archive_account_id" {
  description = "Identifiant du compte log-archive (destination des logs)."
  value       = aws_organizations_account.log_archive.id
}

output "security_audit_account_id" {
  description = "Identifiant du compte security-audit (administrateur délégué)."
  value       = aws_organizations_account.security_audit.id
}
